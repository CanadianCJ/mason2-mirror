from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
from typing import Any
import json
import os
import re
import sqlite3
import subprocess
import urllib.error
import urllib.request
import uuid

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

# --- Paths ---------------------------------------------------------

BASE = Path(__file__).resolve().parent.parent
STATE = BASE / "state" / "knowledge"
LOGS = BASE / "logs"
TOOLS = BASE / "tools"
WEB_DIR = Path(__file__).resolve().parent / "web"
STATE_ROOT = BASE / "state"
CONFIG_DIR = BASE / "config"
REPORTS_DIR = BASE / "reports"

PENDING_PATCHES = STATE / "pending_patch_runs.json"
SUGGESTIONS = STATE / "mason_teacher_suggestions.json"
NOTIFICATIONS = STATE / "notifications.jsonl"
MASON_GUARDRAILS = STATE_ROOT / "config" / "mason_guardrails.json"
RISK_POLICY = CONFIG_DIR / "risk_policy.json"
AUTONOMY_POLICY = CONFIG_DIR / "mason_autonomy_policy.json"
SMOKE_TEST_LATEST = REPORTS_DIR / "smoke_test_latest.json"
SECRETS_MASON = CONFIG_DIR / "secrets_mason.json"
CHAT_DIR = STATE / "chat"
CHAT_DB = CHAT_DIR / "chat.db"
CHAT_HISTORY_JSONL = STATE / "chat_history.jsonl"
CHAT_SUMMARY_PATH = STATE / "chat_summary.txt"
BRIDGE_SERVER_SCRIPT = BASE / "bridge" / "mason_bridge_server.py"
APPLY_APPROVED_SCRIPT = TOOLS / "Mason_Apply_ApprovedChanges.ps1"
SMOKE_TEST_SCRIPT = TOOLS / "SmokeTest_Mason2.ps1"
CODEX_WORKORDER_SCRIPT = TOOLS / "Codex_WorkOrder_From_Approvals.ps1"
CODEX_WORKORDER_PATH = REPORTS_DIR / "codex_workorder_latest.txt"
APPROVALS_EXPLAIN_PATH = REPORTS_DIR / "approvals_explain_latest.json"
APPROVALS_APPLY_SUMMARY_PATH = REPORTS_DIR / "approvals_apply_latest.json"

# --- App setup -----------------------------------------------------

app = FastAPI(title="Athena Console")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # local control-surface use
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Helpers -------------------------------------------------------


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def read_json(path: Path, default: Any) -> Any:
    try:
        if path.exists():
            text = path.read_text(encoding="utf-8-sig")
            if text.strip():
                return json.loads(text)
    except Exception as exc:
        print(f"[Athena] Error reading {path}: {exc}")
    return default


def write_json(path: Path, data: Any) -> None:
    ensure_parent(path)
    payload = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
    # utf-8-sig keeps writes BOM-safe for existing consumers.
    path.write_text(payload, encoding="utf-8-sig")


def append_notification(
    *,
    level: str,
    component: str,
    message: str,
    context: dict[str, Any] | None = None,
    timestamp: str | None = None,
) -> dict[str, Any]:
    event = {
        "timestamp": timestamp or utc_now_iso(),
        "level": (level or "info").lower(),
        "component": component or "athena",
        "message": message or "",
        "context": context if isinstance(context, dict) else {},
    }
    ensure_parent(NOTIFICATIONS)
    with NOTIFICATIONS.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(event, ensure_ascii=False) + "\n")
    return event


def read_notifications(limit: int) -> list[dict[str, Any]]:
    if not NOTIFICATIONS.exists():
        return []

    events: list[dict[str, Any]] = []
    try:
        with NOTIFICATIONS.open("r", encoding="utf-8") as handle:
            for line in handle:
                stripped = line.strip()
                if not stripped:
                    continue
                try:
                    parsed = json.loads(stripped)
                except Exception:
                    continue
                if isinstance(parsed, dict):
                    events.append(parsed)
    except Exception as exc:
        print(f"[Athena] Error reading notifications: {exc}")
        return []

    newest_first = list(reversed(events))
    return newest_first[:limit]


def normalize_approvals(data: Any) -> list[dict[str, Any]]:
    if isinstance(data, dict):
        return [data]
    if isinstance(data, list):
        return [item for item in data if isinstance(item, dict)]
    return []


def compact_text(value: Any) -> str:
    return " ".join(str(value or "").replace("\r", "\n").split()).strip()


def normalize_approval_status(value: Any) -> str:
    raw = compact_text(value).lower()
    if not raw:
        return "pending"
    aliases = {
        "approved": "approve",
        "rejected": "reject",
    }
    return aliases.get(raw, raw)


def normalize_component_domain(value: Any) -> str:
    raw = compact_text(value).lower()
    if not raw:
        return "other"
    tokens = set(re.findall(r"[a-z0-9]+", raw))
    for name in ("mason", "athena", "onyx"):
        if (
            raw == name
            or raw.startswith(f"{name}_")
            or raw.startswith(f"{name}-")
            or raw.endswith(f"_{name}")
            or raw.endswith(f"-{name}")
            or name in tokens
        ):
            return name
    return "other"


def get_approval_domain_component(item: dict[str, Any]) -> str:
    for key in ("component_id", "area", "teacher_domain", "component"):
        domain = normalize_component_domain(item.get(key))
        if domain != "other":
            return domain
    return "other"


def short_sentences(text: str, *, max_sentences: int = 2, max_chars: int = 220) -> str:
    cleaned = compact_text(text)
    if not cleaned:
        return ""
    parts = [part.strip() for part in re.split(r"(?<=[.!?])\s+", cleaned) if part.strip()]
    reduced = " ".join(parts[:max_sentences]) if parts else cleaned
    if len(reduced) <= max_chars:
        return reduced
    return reduced[: max_chars - 3].rstrip() + "..."


def extract_short_summary(item: dict[str, Any]) -> str:
    preferred = short_sentences(compact_text(item.get("shortSummary")))
    if preferred:
        return preferred

    description = compact_text(item.get("description"))
    if description:
        marker = re.search(r"why this helps:\s*", description, flags=re.IGNORECASE)
        if marker:
            tail = description[marker.end() :].strip()
            if tail:
                return short_sentences(tail)
        return short_sentences(description)

    operator_summary = short_sentences(item.get("operator_summary") or item.get("operatorSummary"))
    if operator_summary:
        return operator_summary

    title = short_sentences(item.get("title"))
    return title or "No summary available."


def extract_top_actions(item: dict[str, Any], *, max_actions: int = 2) -> list[str]:
    output: list[str] = []
    seen: set[str] = set()

    def push_text(value: Any) -> None:
        if len(output) >= max_actions:
            return
        text = compact_text(value)
        if not text:
            return
        if len(text) > 180:
            text = text[:177].rstrip() + "..."
        if text in seen:
            return
        seen.add(text)
        output.append(text)

    def walk(value: Any) -> None:
        if len(output) >= max_actions or value is None:
            return

        if isinstance(value, list):
            for entry in value:
                walk(entry)
                if len(output) >= max_actions:
                    return
            return

        if isinstance(value, dict):
            preferred_keys = (
                "action",
                "title",
                "description",
                "summary",
                "text",
                "name",
                "command",
                "cmd",
                "change",
                "step",
            )
            found = False
            for key in preferred_keys:
                if key in value:
                    walk(value.get(key))
                    found = True
                    if len(output) >= max_actions:
                        return
            if not found and "id" in value:
                walk(value.get("id"))
            return

        push_text(value)

    for key in (
        "topActions",
        "actions",
        "action_items",
        "proposed_actions",
        "steps",
        "changes",
        "patches",
        "tasks",
        "plan",
    ):
        if key in item:
            walk(item.get(key))
            if len(output) >= max_actions:
                break

    if len(output) < max_actions:
        push_text(item.get("title"))

    if len(output) < max_actions:
        description = compact_text(item.get("description"))
        if description:
            marker = re.search(r"why this helps:\s*", description, flags=re.IGNORECASE)
            lead = description[: marker.start()].strip() if marker else description
            first_sentence = short_sentences(lead, max_sentences=1, max_chars=180)
            if first_sentence:
                push_text(first_sentence)

    return output[:max_actions]


def build_approval_triage_item(item: dict[str, Any]) -> dict[str, Any]:
    domain_component = get_approval_domain_component(item)
    component_id = compact_text(item.get("component_id"))
    area = compact_text(item.get("area"))
    if not component_id and domain_component != "other":
        component_id = domain_component
    if not area and domain_component != "other":
        area = domain_component

    return {
        "id": compact_text(item.get("id")) or "unknown",
        "title": compact_text(item.get("title")) or "Untitled approval",
        "risk_level": risk_label(item.get("risk_level"), default=0),
        "status": normalize_approval_status(item.get("status")),
        "component_id": component_id,
        "area": area,
        "domain_component": domain_component,
        "shortSummary": extract_short_summary(item),
        "topActions": extract_top_actions(item, max_actions=2),
        "created_at": item.get("created_at"),
        "decision_at": item.get("decision_at"),
        "kind": compact_text(item.get("kind")),
    }


def normalize_apply_mode(value: Any, default: str = "R0") -> str:
    raw = str(value or default).strip().upper()
    if raw in {"R0", "R1"}:
        return raw
    return default


def build_missing_executor_explain_payload(*, mode: str) -> dict[str, Any]:
    approvals = get_approvals()
    rows: list[dict[str, Any]] = []
    for item in approvals:
        component = get_approval_domain_component(item)
        status = normalize_approval_status(item.get("status"))
        rows.append(
            {
                "id": compact_text(item.get("id")) or "unknown",
                "status": status,
                "component": component,
                "risk_level": risk_label(item.get("risk_level"), default=0),
                "allowlisted": False,
                "within_risk_gate": False,
                "will_execute": False,
                "blocked_reasons": ["missing_executor"],
            }
        )

    summary = {
        "total_items": len(rows),
        "will_execute_count": 0,
        "blocked_count": len(rows),
    }
    return {
        "ok": False,
        "mode": mode,
        "max_risk_level": mode,
        "require_allowlist": True,
        "approvals": rows,
        "summary": summary,
        "message": f"Missing executor script: {APPLY_APPROVED_SCRIPT}",
    }


def run_powershell_to_log(command: list[str], log_handle) -> int:
    result = subprocess.run(
        command,
        cwd=str(BASE),
        stdout=log_handle,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
    )
    return int(result.returncode)


def run_powershell_capture(command: list[str]) -> tuple[int, str]:
    result = subprocess.run(
        command,
        cwd=str(BASE),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
    )
    return int(result.returncode), result.stdout or ""


def risk_to_int(value: Any, default: int = 0) -> int:
    if isinstance(value, bool):
        level = 1 if value else 0
    elif isinstance(value, (int, float)):
        level = int(value)
    else:
        raw = str(value or "").strip().lower()
        aliases = {
            "r0": 0,
            "0": 0,
            "none": 0,
            "observe_only": 0,
            "read_only": 0,
            "r1": 1,
            "1": 1,
            "low": 1,
            "low_only": 1,
            "r2": 2,
            "2": 2,
            "medium": 2,
            "low_and_medium": 2,
            "r3": 3,
            "3": 3,
            "high": 3,
            "high_scoped": 3,
            "full_stability_plus_scoped_high": 3,
        }
        if raw in aliases:
            level = aliases[raw]
        elif raw.startswith("r") and raw[1:].isdigit():
            level = int(raw[1:])
        elif raw.isdigit():
            level = int(raw)
        else:
            level = default
    return max(0, min(3, level))


def risk_label(value: Any, default: int = 0) -> str:
    return f"R{risk_to_int(value, default=default)}"


def as_bool(value: Any, default: bool = False) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return value != 0
    if isinstance(value, str):
        raw = value.strip().lower()
        if raw in {"1", "true", "yes", "on", "enabled", "pass", "passed"}:
            return True
        if raw in {"0", "false", "no", "off", "disabled", "fail", "failed"}:
            return False
    return default


def normalize_smoke_status(value: Any) -> str:
    raw = str(value or "").strip().upper()
    if raw in {"PASS", "PASSED", "OK", "SUCCESS", "TRUE"}:
        return "PASS"
    if raw in {"FAIL", "FAILED", "ERROR", "FALSE"}:
        return "FAIL"
    return "UNKNOWN"


def resolve_component_levels(
    guardrails_data: Any,
    autonomy_data: Any,
    risk_policy_data: Any,
) -> tuple[dict[str, int], dict[str, str]]:
    components = ("mason", "athena", "onyx")
    levels: dict[str, int] = {}
    sources: dict[str, str] = {}

    for component in components:
        value = None
        source = "default:R0"

        guard_key = f"max_auto_risk_level_for_{component}"
        if isinstance(guardrails_data, dict) and guard_key in guardrails_data:
            value = guardrails_data.get(guard_key)
            source = f"state/config/mason_guardrails.json:{guard_key}"

        if value is None and isinstance(autonomy_data, dict):
            policy_components = autonomy_data.get("components")
            if isinstance(policy_components, dict):
                component_cfg = policy_components.get(component)
                if isinstance(component_cfg, dict) and "max_auto_risk" in component_cfg:
                    value = component_cfg.get("max_auto_risk")
                    source = "config/mason_autonomy_policy.json:components"

        if value is None and isinstance(risk_policy_data, dict):
            areas = risk_policy_data.get("areas")
            if isinstance(areas, dict):
                area_cfg = areas.get(component)
                if isinstance(area_cfg, dict) and "max_auto_risk" in area_cfg:
                    value = area_cfg.get("max_auto_risk")
                    source = "config/risk_policy.json:areas"

        levels[component] = risk_to_int(value, default=0)
        sources[component] = source

    return levels, sources


def build_auto_apply_by_risk(
    component_levels: dict[str, int],
    *,
    high_risk_auto_apply: bool,
) -> dict[str, dict[str, Any]]:
    labels = {
        "mason": "Mason",
        "athena": "Athena",
        "onyx": "Onyx",
    }
    output: dict[str, dict[str, Any]] = {}
    for level in range(4):
        enabled_components = [
            labels[key]
            for key in ("mason", "athena", "onyx")
            if component_levels.get(key, 0) >= level
        ]
        if level == 3 and not high_risk_auto_apply:
            enabled_components = []

        output[f"R{level}"] = {
            "enabled": bool(enabled_components),
            "components": enabled_components,
        }
    return output


def get_last_smoke_test() -> dict[str, Any]:
    report = read_json(SMOKE_TEST_LATEST, default={})
    if isinstance(report, dict) and report:
        status = normalize_smoke_status(report.get("result"))
        if status == "UNKNOWN" and "pass" in report:
            status = "PASS" if as_bool(report.get("pass"), default=False) else "FAIL"
        timestamp = report.get("timestamp") or report.get("ts")
        if timestamp:
            return {
                "status": status,
                "timestamp": str(timestamp),
                "source": "reports/smoke_test_latest.json",
            }

    for event in read_notifications(limit=500):
        if not isinstance(event, dict):
            continue
        context = event.get("context")
        if not isinstance(context, dict):
            continue

        if "smoke_pass" in context:
            status = "PASS" if as_bool(context.get("smoke_pass"), default=False) else "FAIL"
            return {
                "status": status,
                "timestamp": event.get("timestamp"),
                "source": "state/knowledge/notifications.jsonl",
            }

        if "smoke_exit_code" in context:
            try:
                smoke_exit = int(context.get("smoke_exit_code"))
                status = "PASS" if smoke_exit == 0 else "FAIL"
            except Exception:
                status = "UNKNOWN"
            return {
                "status": status,
                "timestamp": event.get("timestamp"),
                "source": "state/knowledge/notifications.jsonl",
            }

    return {
        "status": "UNKNOWN",
        "timestamp": None,
        "source": "unavailable",
    }


def build_capabilities_right_now(
    component_levels: dict[str, int],
    auto_apply_by_risk: dict[str, dict[str, Any]],
    smoke_status: dict[str, Any],
    autonomy_data: Any,
    *,
    high_risk_auto_apply: bool,
) -> list[str]:
    items: list[str] = []
    labels = {
        "mason": "Mason",
        "athena": "Athena",
        "onyx": "Onyx",
    }
    for component in ("mason", "athena", "onyx"):
        items.append(
            f"{labels[component]} auto-apply ceiling is R{component_levels.get(component, 0)}."
        )

    for risk in ("R0", "R1", "R2", "R3"):
        config = auto_apply_by_risk.get(risk, {})
        enabled = as_bool(config.get("enabled"), default=False)
        components = [
            str(item)
            for item in (config.get("components") or [])
            if str(item).strip()
        ]
        if enabled and components:
            items.append(f"{risk} auto-apply is currently enabled for {', '.join(components)}.")
        elif enabled:
            items.append(f"{risk} auto-apply is currently enabled.")
        else:
            items.append(f"{risk} auto-apply is currently disabled.")

    if not high_risk_auto_apply:
        items.append("High-risk (R3) auto-apply is explicitly disabled by policy.")

    executor_script = TOOLS / "Mason_Apply_ApprovedChanges.ps1"
    smoke_script = TOOLS / "SmokeTest_Mason2.ps1"
    items.append(
        "Approved-changes executor script is available."
        if executor_script.exists()
        else "Approved-changes executor script is missing."
    )
    items.append(
        "Smoke test script is available."
        if smoke_script.exists()
        else "Smoke test script is missing."
    )

    smoke_state = str(smoke_status.get("status") or "UNKNOWN")
    smoke_ts = smoke_status.get("timestamp")
    if smoke_ts:
        items.append(f"Last smoke test was {smoke_state} at {smoke_ts}.")
    else:
        items.append("Last smoke test status is unknown because no timestamp was found.")

    if isinstance(autonomy_data, dict):
        component_cfg = autonomy_data.get("components")
        if isinstance(component_cfg, dict):
            for component in ("mason", "athena", "onyx"):
                cfg = component_cfg.get(component)
                if not isinstance(cfg, dict):
                    continue
                allowed: list[str] = []
                if as_bool(cfg.get("allow_code_edits"), default=False):
                    allowed.append("code edits")
                if as_bool(cfg.get("allow_schedule_edits"), default=False):
                    allowed.append("schedule edits")
                if as_bool(cfg.get("allow_pc_maintenance"), default=False):
                    allowed.append("PC maintenance")
                if allowed:
                    items.append(f"{labels[component]} currently allows {', '.join(allowed)}.")

    return items


def build_trust_payload() -> dict[str, Any]:
    guardrails_data = read_json(MASON_GUARDRAILS, default={})
    autonomy_data = read_json(AUTONOMY_POLICY, default={})
    risk_policy_data = read_json(RISK_POLICY, default={})

    component_levels, component_sources = resolve_component_levels(
        guardrails_data=guardrails_data,
        autonomy_data=autonomy_data,
        risk_policy_data=risk_policy_data,
    )

    high_risk_auto_apply = False
    if isinstance(risk_policy_data, dict):
        global_cfg = risk_policy_data.get("global")
        if isinstance(global_cfg, dict):
            high_risk_auto_apply = as_bool(
                global_cfg.get("high_risk_auto_apply"),
                default=False,
            )

    auto_apply_by_risk = build_auto_apply_by_risk(
        component_levels,
        high_risk_auto_apply=high_risk_auto_apply,
    )

    smoke_status = get_last_smoke_test()
    capabilities = build_capabilities_right_now(
        component_levels,
        auto_apply_by_risk,
        smoke_status,
        autonomy_data,
        high_risk_auto_apply=high_risk_auto_apply,
    )

    component_risk_policy = {}
    for key, label in (("mason", "Mason"), ("athena", "Athena"), ("onyx", "Onyx")):
        component_risk_policy[key] = {
            "label": label,
            "risk_policy_level": risk_label(component_levels.get(key, 0), default=0),
            "source": component_sources.get(key, "default:R0"),
        }

    return {
        "generated_at": utc_now_iso(),
        "component_risk_policy": component_risk_policy,
        "auto_apply_by_risk": auto_apply_by_risk,
        "last_smoke_test": smoke_status,
        "capabilities_right_now": capabilities,
    }


def get_chat_db() -> sqlite3.Connection:
    ensure_parent(CHAT_DB)
    conn = sqlite3.connect(str(CHAT_DB))
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS conversations (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            summary TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            conversation_id TEXT NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY(conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
        )
        """
    )
    conn.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_messages_conversation_id_id
        ON messages(conversation_id, id)
        """
    )
    conn.commit()
    return conn


def normalize_conversation_id(raw: Any) -> str:
    value = str(raw or "").strip()
    if not value:
        return ""
    if len(value) > 128:
        value = value[:128]
    return value


def new_conversation_id() -> str:
    return "conv-{ts}-{suffix}".format(
        ts=datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S"),
        suffix=uuid.uuid4().hex[:8],
    )


def short_title_from_message(message: str, max_len: int = 80) -> str:
    text = " ".join(str(message or "").split()).strip()
    if not text:
        return "New conversation"
    if len(text) <= max_len:
        return text
    return text[: max_len - 3].rstrip() + "..."


def load_openai_secret_fields() -> tuple[str | None, str]:
    payload = read_json(SECRETS_MASON, default={})
    if isinstance(payload, dict):
        key = payload.get("openai_api_key")
        if isinstance(key, str) and key.strip():
            model = payload.get("openai_model")
            if not isinstance(model, str) or not model.strip():
                nested = payload.get("openai")
                if isinstance(nested, dict):
                    model = nested.get("model")
            return key.strip(), str(model).strip() if isinstance(model, str) and model.strip() else "gpt-4o-mini"

        nested = payload.get("openai")
        if isinstance(nested, dict):
            key = nested.get("api_key")
            if isinstance(key, str) and key.strip():
                model = nested.get("model")
                return key.strip(), str(model).strip() if isinstance(model, str) and model.strip() else "gpt-4o-mini"

    env_key = str(os.environ.get("OPENAI_API_KEY", "")).strip()
    if env_key:
        return env_key, "gpt-4o-mini"
    return None, "gpt-4o-mini"


def call_openai_chat_completion(messages: list[dict[str, str]]) -> str:
    api_key, model = load_openai_secret_fields()
    if not api_key:
        raise RuntimeError("No OpenAI API key found in config/secrets_mason.json.")

    body = {
        "model": model,
        "messages": messages,
        "temperature": 0.2,
    }
    req = urllib.request.Request(
        "https://api.openai.com/v1/chat/completions",
        data=json.dumps(body).encode("utf-8"),
        method="POST",
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
        },
    )

    try:
        with urllib.request.urlopen(req, timeout=90) as response:
            payload = response.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as exc:
        raise RuntimeError(f"OpenAI request failed (HTTP {exc.code}).") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"OpenAI request failed ({exc.reason}).") from exc

    parsed = json.loads(payload)
    choices = parsed.get("choices")
    if not isinstance(choices, list) or not choices:
        raise RuntimeError("OpenAI returned no choices.")

    message = choices[0].get("message")
    if not isinstance(message, dict):
        raise RuntimeError("OpenAI returned an invalid message payload.")

    content = message.get("content")
    if not isinstance(content, str) or not content.strip():
        raise RuntimeError("OpenAI returned empty assistant content.")
    return content.strip()


def keyword_list_for_recall(text: str, max_keywords: int = 8) -> list[str]:
    stop = {
        "about", "after", "again", "also", "and", "been", "being", "could", "does",
        "from", "have", "just", "like", "make", "more", "need", "only", "please",
        "should", "that", "then", "there", "they", "this", "want", "with", "would",
        "your", "what", "when", "where", "which",
    }
    items: list[str] = []
    seen: set[str] = set()
    for token in re.findall(r"[A-Za-z0-9_]{4,}", text.lower()):
        if token in stop or token in seen:
            continue
        seen.add(token)
        items.append(token)
        if len(items) >= max_keywords:
            break
    return items


def shorten_snippet(text: str, max_len: int = 180) -> str:
    cleaned = " ".join(str(text or "").split()).strip()
    if len(cleaned) <= max_len:
        return cleaned
    return cleaned[: max_len - 3].rstrip() + "..."


def normalize_chat_role(value: Any) -> str:
    role = str(value or "").strip().lower()
    if role in {"assistant", "mason"}:
        return "assistant"
    if role == "system":
        return "system"
    return "user"


def ensure_chat_storage_files() -> None:
    ensure_parent(CHAT_HISTORY_JSONL)
    if not CHAT_HISTORY_JSONL.exists():
        CHAT_HISTORY_JSONL.write_text("", encoding="utf-8")


def read_chat_history_jsonl(limit: int | None = None) -> list[dict[str, Any]]:
    ensure_chat_storage_files()

    rows: list[dict[str, Any]] = []
    try:
        with CHAT_HISTORY_JSONL.open("r", encoding="utf-8") as handle:
            for raw_line in handle:
                line = raw_line.strip()
                if not line:
                    continue
                try:
                    parsed = json.loads(line)
                except Exception:
                    continue
                if not isinstance(parsed, dict):
                    continue

                content = str(parsed.get("content") or "").strip()
                if not content:
                    continue

                created_at = str(
                    parsed.get("created_at")
                    or parsed.get("timestamp")
                    or parsed.get("ts")
                    or ""
                ).strip()
                if not created_at:
                    created_at = utc_now_iso()

                rows.append(
                    {
                        "role": normalize_chat_role(parsed.get("role")),
                        "content": content,
                        "created_at": created_at,
                    }
                )
    except Exception as exc:
        print(f"[Athena] Error reading chat history JSONL: {exc}")
        return []

    if isinstance(limit, int) and limit > 0:
        rows = rows[-int(limit) :]

    for idx, row in enumerate(rows, start=1):
        row["id"] = idx

    return rows


def append_chat_history_entry(
    *,
    role: str,
    content: str,
    source: str = "",
    context: dict[str, Any] | None = None,
) -> dict[str, Any]:
    ensure_chat_storage_files()
    event = {
        "created_at": utc_now_iso(),
        "role": normalize_chat_role(role),
        "content": str(content or "").strip(),
    }
    if source:
        event["source"] = str(source)
    if isinstance(context, dict) and context:
        event["context"] = context

    with CHAT_HISTORY_JSONL.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(event, ensure_ascii=False) + "\n")
    return event


def read_chat_summary_text() -> str:
    if not CHAT_SUMMARY_PATH.exists():
        return ""
    try:
        return CHAT_SUMMARY_PATH.read_text(encoding="utf-8").strip()
    except Exception:
        return ""


def write_chat_summary_text(summary: str) -> None:
    ensure_parent(CHAT_SUMMARY_PATH)
    CHAT_SUMMARY_PATH.write_text(str(summary or "").strip() + "\n", encoding="utf-8")


def build_rolling_chat_summary(history: list[dict[str, Any]]) -> str:
    items = [item for item in history if item.get("role") in {"user", "assistant"}]
    if not items:
        return "No chat history yet."

    user_messages = [item for item in items if item.get("role") == "user"]
    assistant_messages = [item for item in items if item.get("role") == "assistant"]

    lines: list[str] = []
    lines.append(f"Rolling chat summary updated at {utc_now_iso()}.")
    lines.append(f"Total messages: {len(items)} (user={len(user_messages)}, assistant={len(assistant_messages)}).")

    if user_messages:
        lines.append("Recent user topics:")
        for item in user_messages[-8:]:
            snippet = shorten_snippet(str(item.get("content") or ""), max_len=170)
            if snippet:
                lines.append(f"- {snippet}")

    if assistant_messages:
        lines.append("Recent Mason replies:")
        for item in assistant_messages[-6:]:
            snippet = shorten_snippet(str(item.get("content") or ""), max_len=170)
            if snippet:
                lines.append(f"- {snippet}")

    return "\n".join(lines).strip()


def maybe_refresh_chat_summary(history: list[dict[str, Any]]) -> str:
    user_turns = sum(1 for item in history if item.get("role") == "user")
    if user_turns <= 0 or user_turns % 50 != 0:
        return read_chat_summary_text()

    summary = build_rolling_chat_summary(history)
    write_chat_summary_text(summary)
    return summary


def read_repo_bridge_default_port() -> int:
    default_port = 8484
    try:
        if BRIDGE_SERVER_SCRIPT.exists():
            text = BRIDGE_SERVER_SCRIPT.read_text(encoding="utf-8", errors="replace")
            match = re.search(r'MASON_BRIDGE_PORT"\s*,\s*"(\d{2,5})"', text)
            if match:
                value = int(match.group(1))
                if 1 <= value <= 65535:
                    default_port = value
    except Exception:
        pass
    return default_port


def discover_bridge_chat_urls() -> list[str]:
    urls: list[str] = []
    seen: set[str] = set()

    env_url = str(os.environ.get("MASON_BRIDGE_URL", "")).strip()
    if env_url:
        normalized = env_url.rstrip("/")
        if not normalized.endswith("/api/chat"):
            normalized = normalized + "/api/chat"
        if normalized not in seen:
            seen.add(normalized)
            urls.append(normalized)

    candidate_ports: list[int] = []
    env_port = str(os.environ.get("MASON_BRIDGE_PORT", "")).strip()
    if env_port.isdigit():
        value = int(env_port)
        if 1 <= value <= 65535:
            candidate_ports.append(value)

    candidate_ports.append(read_repo_bridge_default_port())
    candidate_ports.append(8484)

    for port in candidate_ports:
        if not (1 <= int(port) <= 65535):
            continue
        url = f"http://127.0.0.1:{int(port)}/api/chat"
        if url in seen:
            continue
        seen.add(url)
        urls.append(url)
    return urls


def http_json_request(
    *,
    url: str,
    method: str,
    payload: dict[str, Any] | None = None,
    timeout: int = 20,
) -> tuple[int, Any]:
    data: bytes | None = None
    headers = {}
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, method=method.upper(), headers=headers)
    with urllib.request.urlopen(req, timeout=timeout) as response:
        body = response.read().decode("utf-8", errors="replace")
        status = int(getattr(response, "status", 200))
    try:
        parsed = json.loads(body) if body else {}
    except Exception:
        parsed = body
    return status, parsed


def build_chat_system_prompt(summary_text: str) -> str:
    base = (
        "You are Mason, the operator-facing assistant for Athena. "
        "Use plain English, be concise, and answer based on the running conversation memory."
    )
    summary = str(summary_text or "").strip()
    if summary:
        return base + "\n\nRolling conversation summary:\n" + summary
    return base


def build_chat_context_messages(history: list[dict[str, Any]], limit: int = 30) -> list[dict[str, str]]:
    out: list[dict[str, str]] = []
    for item in history[-int(limit) :]:
        role = normalize_chat_role(item.get("role"))
        if role not in {"user", "assistant"}:
            continue
        content = str(item.get("content") or "").strip()
        if not content:
            continue
        out.append({"role": role, "content": content})
    return out


def call_bridge_chat_completion(
    *,
    message: str,
    context_messages: list[dict[str, str]],
    summary_text: str,
) -> tuple[str, str]:
    errors: list[str] = []
    payload = {
        "message": message,
        "history": context_messages,
        "system_prompt": build_chat_system_prompt(summary_text),
    }

    for chat_url in discover_bridge_chat_urls():
        base_url = chat_url.rsplit("/api/chat", 1)[0]
        health_url = base_url + "/health"
        try:
            # Prefer bridge only when the repo-discovered bridge looks alive.
            health_status, _ = http_json_request(url=health_url, method="GET", timeout=3)
            if health_status < 200 or health_status >= 300:
                errors.append(f"{chat_url} health status {health_status}")
                continue

            _, parsed = http_json_request(
                url=chat_url,
                method="POST",
                payload=payload,
                timeout=60,
            )
            if isinstance(parsed, dict):
                reply = str(parsed.get("reply") or "").strip()
                if reply:
                    return reply, chat_url
            errors.append(f"{chat_url} returned no reply")
        except Exception as exc:
            errors.append(f"{chat_url} failed ({exc})")
            continue

    raise RuntimeError("Bridge unavailable: " + "; ".join(errors[-3:]))


def generate_chat_reply(
    *,
    message: str,
    recent_history: list[dict[str, Any]],
    summary_text: str,
) -> tuple[str, str, str]:
    context_messages = build_chat_context_messages(recent_history, limit=30)
    if context_messages:
        last_item = context_messages[-1]
        if (
            last_item.get("role") == "user"
            and compact_text(last_item.get("content")) == compact_text(message)
        ):
            context_messages = context_messages[:-1]

    bridge_error = ""
    try:
        reply, source_url = call_bridge_chat_completion(
            message=message,
            context_messages=context_messages,
            summary_text=summary_text,
        )
        return reply, "bridge", source_url
    except Exception as exc:
        bridge_error = str(exc)

    prompt_messages: list[dict[str, str]] = [
        {
            "role": "system",
            "content": build_chat_system_prompt(summary_text),
        }
    ]
    prompt_messages.extend(context_messages)
    prompt_messages.append({"role": "user", "content": message})

    try:
        reply = call_openai_chat_completion(prompt_messages)
        return reply, "openai", ""
    except Exception as exc:
        fallback = (
            "I could not reach Mason brain right now. "
            "Please retry in a moment."
        )
        details = f"bridge_error={bridge_error}; openai_error={exc}"
        return fallback, "fallback", details


def fetch_recent_messages(
    conn: sqlite3.Connection,
    *,
    conversation_id: str,
    limit: int,
) -> list[dict[str, Any]]:
    rows = conn.execute(
        """
        SELECT id, role, content, created_at
        FROM messages
        WHERE conversation_id = ?
        ORDER BY id DESC
        LIMIT ?
        """,
        (conversation_id, int(limit)),
    ).fetchall()
    rows = list(reversed(rows))
    output: list[dict[str, Any]] = []
    for row in rows:
        role = str(row["role"] or "").strip().lower()
        if role not in {"user", "assistant", "system"}:
            role = "user"
        output.append(
            {
                "id": int(row["id"]),
                "role": role,
                "content": str(row["content"] or ""),
                "created_at": str(row["created_at"] or ""),
            }
        )
    return output


def fetch_recalled_snippets(
    conn: sqlite3.Connection,
    *,
    conversation_id: str,
    query_text: str,
    exclude_message_ids: set[int],
    limit: int = 6,
) -> list[str]:
    snippets: list[str] = []
    seen_ids: set[int] = set()
    for kw in keyword_list_for_recall(query_text):
        rows = conn.execute(
            """
            SELECT id, role, content
            FROM messages
            WHERE conversation_id = ?
              AND content LIKE ?
            ORDER BY id DESC
            LIMIT 4
            """,
            (conversation_id, f"%{kw}%"),
        ).fetchall()
        for row in rows:
            row_id = int(row["id"])
            if row_id in seen_ids or row_id in exclude_message_ids:
                continue
            seen_ids.add(row_id)
            role = str(row["role"] or "user").lower()
            snippet = shorten_snippet(str(row["content"] or ""))
            if snippet:
                snippets.append(f"[{role}] {snippet}")
            if len(snippets) >= limit:
                return snippets
    return snippets


def upsert_conversation(
    conn: sqlite3.Connection,
    *,
    conversation_id: str,
    first_message: str,
) -> dict[str, Any]:
    row = conn.execute(
        "SELECT id, title, summary, created_at, updated_at FROM conversations WHERE id = ?",
        (conversation_id,),
    ).fetchone()
    now = utc_now_iso()
    if row is None:
        title = short_title_from_message(first_message)
        summary_seed = shorten_snippet(first_message, max_len=240)
        conn.execute(
            """
            INSERT INTO conversations (id, title, summary, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?)
            """,
            (conversation_id, title, summary_seed, now, now),
        )
        conn.commit()
        return {
            "id": conversation_id,
            "title": title,
            "summary": summary_seed,
            "created_at": now,
            "updated_at": now,
        }

    conn.execute(
        "UPDATE conversations SET updated_at = ? WHERE id = ?",
        (now, conversation_id),
    )
    conn.commit()
    return {
        "id": str(row["id"]),
        "title": str(row["title"] or ""),
        "summary": str(row["summary"] or ""),
        "created_at": str(row["created_at"] or ""),
        "updated_at": now,
    }


def insert_chat_message(
    conn: sqlite3.Connection,
    *,
    conversation_id: str,
    role: str,
    content: str,
) -> int:
    now = utc_now_iso()
    cursor = conn.execute(
        """
        INSERT INTO messages (conversation_id, role, content, created_at)
        VALUES (?, ?, ?, ?)
        """,
        (conversation_id, role, content, now),
    )
    conn.execute(
        "UPDATE conversations SET updated_at = ? WHERE id = ?",
        (now, conversation_id),
    )
    conn.commit()
    return int(cursor.lastrowid)


# --- API: approvals / suggestions ----------------------------------


@app.get("/api/approvals")
def get_approvals():
    """
    Raw approvals / executions list.
    Backed by pending_patch_runs.json written by TeacherQueue + SelfOps.
    """
    data = read_json(PENDING_PATCHES, default=[])
    return normalize_approvals(data)


@app.get("/api/approvals/triage")
def get_approvals_triage():
    """
    Operator-friendly approvals payload with grouped counters and short summaries.
    """
    approvals = get_approvals()
    items: list[dict[str, Any]] = []
    by_domain_component: dict[str, int] = {
        "mason": 0,
        "athena": 0,
        "onyx": 0,
        "other": 0,
    }
    by_risk_level: dict[str, int] = {
        "R0": 0,
        "R1": 0,
        "R2": 0,
        "R3": 0,
    }
    by_status: dict[str, int] = {
        "pending": 0,
        "approve": 0,
        "reject": 0,
        "executed": 0,
    }

    for approval in approvals:
        triage_item = build_approval_triage_item(approval)
        items.append(triage_item)

        component = str(triage_item.get("domain_component", "other"))
        by_domain_component[component] = by_domain_component.get(component, 0) + 1

        risk = str(triage_item.get("risk_level", "R0"))
        by_risk_level[risk] = by_risk_level.get(risk, 0) + 1

        status = str(triage_item.get("status", "pending"))
        by_status[status] = by_status.get(status, 0) + 1

    grouped_counts = {
        "domain_component": by_domain_component,
        "risk_level": by_risk_level,
        "status": by_status,
    }

    return {
        "total": len(items),
        "grouped_counts": grouped_counts,
        "by_component": by_domain_component,
        "by_risk": by_risk_level,
        "by_status": by_status,
        "items": items,
    }


@app.get("/api/approvals/explain")
def get_approvals_explain(mode: str = Query(default="R0")):
    mode_norm = normalize_apply_mode(mode, default="R0")

    if not APPLY_APPROVED_SCRIPT.exists():
        return build_missing_executor_explain_payload(mode=mode_norm)

    try:
        if APPROVALS_EXPLAIN_PATH.exists():
            APPROVALS_EXPLAIN_PATH.unlink()
    except Exception:
        pass

    cmd = [
        "powershell",
        "-NoLogo",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        str(APPLY_APPROVED_SCRIPT),
        "-ExplainJson",
        "-Mode",
        mode_norm,
        "-MaxRiskLevel",
        mode_norm,
        "-RequireAllowlist",
    ]
    exit_code, output = run_powershell_capture(cmd)

    payload = read_json(APPROVALS_EXPLAIN_PATH, default={})
    if not isinstance(payload, dict):
        payload = {}

    approvals_rows = payload.get("approvals")
    if not isinstance(approvals_rows, list):
        approvals_rows = []

    summary_obj = payload.get("summary")
    if not isinstance(summary_obj, dict):
        summary_obj = {
            "total_items": len(approvals_rows),
            "will_execute_count": 0,
            "blocked_count": len(approvals_rows),
        }

    ok = exit_code == 0
    message = ""
    if not ok:
        message = f"Explain command failed with exit code {exit_code}."
        tail_lines = [line for line in output.splitlines() if line.strip()]
        if tail_lines:
            message += f" Last output: {tail_lines[-1]}"

    response = {
        "ok": ok,
        "mode": mode_norm,
        "max_risk_level": str(payload.get("max_risk_level") or mode_norm),
        "require_allowlist": bool(payload.get("require_allowlist", True)),
        "generated_at": str(payload.get("generated_at") or utc_now_iso()),
        "approvals": approvals_rows,
        "summary": summary_obj,
        "exit_code": int(exit_code),
        "path": str(APPROVALS_EXPLAIN_PATH),
    }
    if message:
        response["message"] = message
    return response


@app.get("/api/approvals/summary")
def get_approvals_summary():
    """
    High-level counters for the approvals tab.
    """
    items = get_approvals()
    total = len(items)
    by_status: dict[str, int] = {}
    by_component: dict[str, int] = {}
    by_risk: dict[str, int] = {}

    for item in items:
        status = str(item.get("status", "unknown"))
        comp = str(item.get("component_id", "unknown"))
        risk = str(item.get("risk_level", "R?"))

        by_status[status] = by_status.get(status, 0) + 1
        by_component[comp] = by_component.get(comp, 0) + 1
        by_risk[risk] = by_risk.get(risk, 0) + 1

    return {
        "total": total,
        "by_status": by_status,
        "by_component": by_component,
        "by_risk": by_risk,
    }


@app.get("/api/suggestions")
def get_suggestions():
    """
    Raw teacher suggestions list, from mason_teacher_suggestions.json.
    """
    data = read_json(SUGGESTIONS, default=[])
    return normalize_approvals(data)


@app.get("/api/trust")
def get_trust():
    return build_trust_payload()


@app.get("/api/chat/conversations")
def get_chat_conversations(limit: int = Query(default=200, ge=1, le=1000)):
    conn = get_chat_db()
    try:
        rows = conn.execute(
            """
            SELECT
                c.id,
                c.title,
                c.summary,
                c.created_at,
                c.updated_at,
                (
                    SELECT COUNT(*)
                    FROM messages m
                    WHERE m.conversation_id = c.id
                ) AS message_count,
                (
                    SELECT m.content
                    FROM messages m
                    WHERE m.conversation_id = c.id
                    ORDER BY m.id DESC
                    LIMIT 1
                ) AS last_message,
                (
                    SELECT m.created_at
                    FROM messages m
                    WHERE m.conversation_id = c.id
                    ORDER BY m.id DESC
                    LIMIT 1
                ) AS last_message_at
            FROM conversations c
            ORDER BY c.updated_at DESC
            LIMIT ?
            """,
            (int(limit),),
        ).fetchall()
    finally:
        conn.close()

    conversations: list[dict[str, Any]] = []
    for row in rows:
        conversations.append(
            {
                "id": str(row["id"]),
                "title": str(row["title"] or ""),
                "summary": str(row["summary"] or ""),
                "created_at": str(row["created_at"] or ""),
                "updated_at": str(row["updated_at"] or ""),
                "message_count": int(row["message_count"] or 0),
                "last_message": shorten_snippet(str(row["last_message"] or ""), max_len=160),
                "last_message_at": str(row["last_message_at"] or ""),
            }
        )
    return conversations


@app.get("/api/chat/history")
def get_chat_history(
    limit: int = Query(default=200, ge=1, le=2000),
):
    messages = read_chat_history_jsonl(limit=int(limit))
    return [
        {
            "id": int(item.get("id", 0)),
            "role": normalize_chat_role(item.get("role")),
            "content": str(item.get("content") or ""),
            "created_at": str(item.get("created_at") or ""),
        }
        for item in messages
    ]


@app.post("/api/chat")
def post_chat(payload: dict[str, Any]):
    message = str(payload.get("message", "")).strip()
    if not message:
        return {"ok": False, "message": "Missing message."}

    append_chat_history_entry(role="user", content=message, source="athena_ui")
    recent_history = read_chat_history_jsonl(limit=30)
    summary_text = read_chat_summary_text()

    reply, source, detail = generate_chat_reply(
        message=message,
        recent_history=recent_history,
        summary_text=summary_text,
    )
    append_chat_history_entry(
        role="assistant",
        content=reply,
        source=source,
        context={"detail": detail} if detail else None,
    )

    history_all = read_chat_history_jsonl(limit=None)
    summary_after = maybe_refresh_chat_summary(history_all)
    append_notification(
        level="info",
        component="chat",
        message="Chat message processed.",
        context={
            "ok": True,
            "source": source,
            "history_size": len(history_all),
            "recent_context_count": len(recent_history),
            "summary_loaded": bool(summary_text),
            "summary_updated": bool(summary_after and summary_after != summary_text),
        },
    )
    return {"ok": True, "reply": reply}


@app.post("/api/chat/send")
def post_chat_send(payload: dict[str, Any]):
    # Backward-compat shim for older UI clients.
    # New path is POST /api/chat and all chat memory is global in chat_history.jsonl.
    return post_chat(payload)


@app.post("/api/approvals/decision")
def post_approvals_decision(payload: dict[str, Any]):
    item_id = str(payload.get("id", "")).strip()
    decision = str(payload.get("decision", "")).strip().lower()
    note = payload.get("note")
    if note is None:
        note = payload.get("reason")

    if not item_id:
        return {"ok": False, "message": "Missing id."}
    if decision not in {"approve", "reject"}:
        return {"ok": False, "message": "Decision must be 'approve' or 'reject'."}

    approvals = normalize_approvals(read_json(PENDING_PATCHES, default=[]))
    if not approvals:
        return {"ok": False, "message": "No approvals found."}

    match = None
    for item in approvals:
        if str(item.get("id", "")).strip() == item_id:
            match = item
            break

    if match is None:
        return {"ok": False, "message": f"Approval id not found: {item_id}"}

    now = utc_now_iso()
    match["status"] = decision
    match["decision_at"] = now
    match["decision_by"] = "owner"
    if note is not None and str(note).strip():
        match["note"] = str(note).strip()

    write_json(PENDING_PATCHES, approvals)

    append_notification(
        level="info" if decision == "approve" else "warn",
        component="approvals",
        message=f"Approval decision set to '{decision}' for {item_id}.",
        context={
            "id": item_id,
            "decision": decision,
            "note": match.get("note"),
        },
    )

    return {"ok": True, "id": item_id, "decision": decision}


@app.post("/api/approvals/run")
def post_approvals_run(payload: dict[str, Any] | None = None):
    requested_mode = ""
    if isinstance(payload, dict):
        requested_mode = str(payload.get("mode", "")).strip()
    mode_norm = normalize_apply_mode(requested_mode or "R0", default="R0")
    if requested_mode and mode_norm != requested_mode.upper():
        return {"ok": False, "message": "mode must be 'R0' or 'R1'."}

    LOGS.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_path = LOGS / f"executor_run_{stamp}.log"
    log_path_rel = f"logs\\{log_path.name}"

    executor_ok = False
    smoke_pass = False
    message = ""
    executor_exit = None
    smoke_exit = None
    rollback_exit = None
    applied_count = 0
    skipped_count = 0

    with log_path.open("w", encoding="utf-8") as log_handle:
        log_handle.write(f"[{utc_now_iso()}] /api/approvals/run invoked (mode={mode_norm})\n")

        try:
            if APPROVALS_APPLY_SUMMARY_PATH.exists():
                APPROVALS_APPLY_SUMMARY_PATH.unlink()
                log_handle.write("Cleared previous approvals_apply_latest.json before run.\n")
        except Exception as exc:
            log_handle.write(f"Failed to clear previous apply summary: {exc}\n")

        if APPLY_APPROVED_SCRIPT.exists():
            executor_cmd = [
                "powershell",
                "-NoLogo",
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(APPLY_APPROVED_SCRIPT),
                "-Execute",
                "-Mode",
                mode_norm,
                "-MaxRiskLevel",
                mode_norm,
                "-RequireAllowlist",
            ]
            executor_exit = run_powershell_to_log(executor_cmd, log_handle)
            executor_ok = executor_exit == 0
            log_handle.write(f"Executor exit code: {executor_exit}\n")

            apply_summary = read_json(APPROVALS_APPLY_SUMMARY_PATH, default={})
            if isinstance(apply_summary, dict):
                try:
                    applied_count = int(apply_summary.get("applied_count", 0))
                except Exception:
                    applied_count = 0
                try:
                    skipped_count = int(apply_summary.get("skipped_count", 0))
                except Exception:
                    skipped_count = 0
                log_handle.write(
                    "Apply summary: applied_count={0}, skipped_count={1}, mode={2}\n".format(
                        applied_count,
                        skipped_count,
                        apply_summary.get("mode"),
                    )
                )
        else:
            message = f"Missing executor script: {APPLY_APPROVED_SCRIPT}"
            log_handle.write(message + "\n")

        smoke_cmd = [
            "powershell",
            "-NoLogo",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(SMOKE_TEST_SCRIPT),
        ]
        smoke_exit = run_powershell_to_log(smoke_cmd, log_handle)
        smoke_pass = smoke_exit == 0
        log_handle.write(f"Smoke test exit code: {smoke_exit}\n")

        should_rollback = (executor_exit is not None and executor_exit != 0) or (not smoke_pass)
        if should_rollback and APPLY_APPROVED_SCRIPT.exists():
            log_handle.write("Triggering rollback: Mason_Apply_ApprovedChanges.ps1 -RollbackLatest\n")
            rollback_cmd = [
                "powershell",
                "-NoLogo",
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(APPLY_APPROVED_SCRIPT),
                "-RollbackLatest",
            ]
            rollback_exit = run_powershell_to_log(rollback_cmd, log_handle)
            log_handle.write(f"Rollback exit code: {rollback_exit}\n")

    ok = executor_ok and smoke_pass
    if not message:
        if not executor_ok and APPLY_APPROVED_SCRIPT.exists():
            message = "Executor run failed."
        elif executor_ok and not smoke_pass:
            message = "Executor run completed but smoke test failed."

    append_notification(
        level="info" if ok else "error",
        component="executor",
        message=f"Manual {mode_norm} apply completed." if ok else f"Manual {mode_norm} apply failed.",
        context={
            "ok": ok,
            "mode": mode_norm,
            "smoke_pass": smoke_pass,
            "log_path": log_path_rel,
            "message": message,
            "executor_exit_code": executor_exit,
            "smoke_exit_code": smoke_exit,
            "rollback_exit_code": rollback_exit,
            "risk_level": mode_norm,
            "allowlist_required": True,
            "applied_count": applied_count,
            "skipped_count": skipped_count,
        },
    )

    response = {
        "ok": ok,
        "mode": mode_norm,
        "smoke_pass": smoke_pass,
        "log_path": log_path_rel,
        "applied_count": applied_count,
        "skipped_count": skipped_count,
    }
    if message:
        response["message"] = message
    if rollback_exit is not None:
        response["rollback_exit_code"] = rollback_exit
    return response


@app.post("/api/approvals/workorder")
def post_approvals_workorder(payload: dict[str, Any] | None = None):
    LOGS.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_path = LOGS / f"codex_workorder_{stamp}.log"
    log_path_rel = f"logs\\{log_path.name}"

    max_items = 50
    if isinstance(payload, dict):
        try:
            maybe_items = int(payload.get("max_items", max_items))
            if 1 <= maybe_items <= 500:
                max_items = maybe_items
        except Exception:
            pass

    ok = False
    count = 0
    workorder_path_rel = f"reports\\{CODEX_WORKORDER_PATH.name}"
    message = ""
    run_in_codex = (
        f"Run in Codex from {BASE}: open reports\\codex_workorder_latest.txt and execute that work order."
    )

    with log_path.open("w", encoding="utf-8") as log_handle:
        log_handle.write(f"[{utc_now_iso()}] /api/approvals/workorder invoked\n")

        if not CODEX_WORKORDER_SCRIPT.exists():
            message = f"Missing work-order script: {CODEX_WORKORDER_SCRIPT}"
            log_handle.write(message + "\n")
        else:
            cmd = [
                "powershell",
                "-NoLogo",
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(CODEX_WORKORDER_SCRIPT),
                "-RootDir",
                str(BASE),
                "-MaxItems",
                str(max_items),
            ]
            exit_code, output = run_powershell_capture(cmd)
            log_handle.write(output)
            log_handle.write(f"\nExit code: {exit_code}\n")

            if exit_code != 0:
                message = f"Work-order script failed with exit code {exit_code}."
            else:
                payload_obj: dict[str, Any] = {}
                lines = [line.strip() for line in output.splitlines() if line.strip()]
                candidate = lines[-1] if lines else ""
                if candidate:
                    try:
                        parsed = json.loads(candidate)
                        if isinstance(parsed, dict):
                            payload_obj = parsed
                    except Exception:
                        payload_obj = {}

                ok = bool(payload_obj.get("ok", False))
                try:
                    count = int(payload_obj.get("count", 0))
                except Exception:
                    count = 0
                output_path = payload_obj.get("output_path")
                if isinstance(output_path, str) and output_path.strip():
                    try:
                        path_obj = Path(output_path)
                        if path_obj.is_absolute():
                            workorder_path_rel = str(path_obj.relative_to(BASE))
                        else:
                            workorder_path_rel = output_path.replace("/", "\\")
                    except Exception:
                        workorder_path_rel = output_path.replace("/", "\\")
                if not ok and isinstance(payload_obj.get("message"), str):
                    message = payload_obj["message"]

                if not ok and not message:
                    message = "Work-order generation did not return ok=true."

    append_notification(
        level="info" if ok else "error",
        component="approvals",
        message="Generated Codex Work Order (R1)." if ok else "Failed to generate Codex Work Order (R1).",
        context={
            "what_it_is": "Codex work order generated from approved R1 items",
            "why_it_helps": "Keeps medium-risk changes human-reviewed and deterministic.",
            "risk_level": "R1",
            "run_in_codex": run_in_codex,
            "ok": ok,
            "count": count,
            "workorder_path": workorder_path_rel,
            "log_path": log_path_rel,
            "message": message,
        },
    )

    response = {
        "ok": ok,
        "count": count,
        "workorder_path": workorder_path_rel,
        "log_path": log_path_rel,
        "run_in_codex": run_in_codex,
    }
    if message:
        response["message"] = message
    return response


# --- API: notifications --------------------------------------------


@app.get("/api/notifications")
def get_notifications(limit: int = Query(default=200, ge=1, le=1000)):
    return read_notifications(limit=limit)


@app.post("/api/notify")
def post_notify(payload: dict[str, Any]):
    message = str(payload.get("message", "")).strip()
    if not message:
        return {"ok": False, "message": "Missing message."}

    context = payload.get("context")
    event = append_notification(
        timestamp=payload.get("timestamp"),
        level=str(payload.get("level", "info")),
        component=str(payload.get("component", "athena")),
        message=message,
        context=context if isinstance(context, dict) else {},
    )
    return {"ok": True, "event": event}


# --- Optional: quick Mason health stub -----------------------------


@app.get("/api/health")
def get_health():
    """
    Very simple heartbeat so Athena can show 'Mason is alive'.
    You can expand this later with log timestamps, etc.
    """
    return {"status": "ok"}


app.mount("/", StaticFiles(directory=str(WEB_DIR), html=True), name="static")

# --- Entrypoint ----------------------------------------------------


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        reload=False,
    )
