from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
from typing import Any
import base64
import hashlib
import hmac
import ipaddress
import json
import os
import re
import secrets
import subprocess
import threading
import time
import zipfile
from uuid import uuid4

from fastapi import FastAPI, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field

# --- Paths ---------------------------------------------------------

BASE = Path(__file__).resolve().parent.parent
STATE_ROOT = BASE / "state"
STATE = STATE_ROOT / "knowledge"
REPORTS = BASE / "reports"
KNOWLEDGE_DIR = BASE / "knowledge" / "inbox"
KNOWLEDGE_PENDING_LLM_DIR = BASE / "knowledge" / "pending_llm"
KNOWLEDGE_UPLOADS_DIR = BASE / "knowledge" / "uploads"
ATHENA_STATIC_DIR = Path(__file__).resolve().parent / "static" / "athena"
WEB_DIR = Path(__file__).resolve().parent / "web"
LEGACY_WEB_DIR = Path(__file__).resolve().parent
SECRETS_PATH = BASE / "config" / "secrets_mason.json"
CONFIG_DIR = BASE / "config"
PORTS_PATH = CONFIG_DIR / "ports.json"
COMPONENT_REGISTRY_PATH = CONFIG_DIR / "component_registry.json"
REMOTE_ACCESS_POLICY_PATH = CONFIG_DIR / "remote_access_policy.json"
ATHENA_DEVICE_REGISTRY_PATH = CONFIG_DIR / "athena_device_registry.json"
TEACHER_POLICY_PATH = CONFIG_DIR / "teacher_policy.json"
BUDGET_POLICY_CONFIG_PATH = CONFIG_DIR / "budget_policy.json"
CURRENCY_POLICY_CONFIG_PATH = CONFIG_DIR / "currency_policy.json"
PLATFORM_DIR = BASE / "tools" / "platform"
TOOL_REGISTRY_PATH = CONFIG_DIR / "tool_registry.json"
TIERS_PATH = CONFIG_DIR / "tiers.json"
ADDONS_PATH = CONFIG_DIR / "addons.json"
ONBOARDING_QUESTIONS_PATH = CONFIG_DIR / "onboarding_questions.json"
TOOL_RUNNER_SCRIPT = PLATFORM_DIR / "ToolRunner.ps1"
TOOL_RECOMMEND_SCRIPT = PLATFORM_DIR / "RecommendationEngine.ps1"
TOOL_RUNS_DIR = REPORTS / "tools"
EVENTS_PATH = REPORTS / "events.jsonl"
JOBS_DIR = REPORTS / "jobs"
DOCTOR_REPORT_PATH = REPORTS / "mason2_doctor_report.json"
DOCTOR_QUICK_REPORT_PATH = REPORTS / "mason2_doctor_quick_report.json"
E2E_VERIFY_REPORT_PATH = REPORTS / "mason2_e2e_verify.json"
BUDGET_STATE_PATH = STATE / "budget_state.json"
INGEST_STATUS_PATH = REPORTS / "ingest_autopilot_status.json"
COMPONENT_INVENTORY_PATH = REPORTS / "component_inventory.json"
MASON_CORE_STATUS_PATH = REPORTS / "mason2_core_status.json"
KILLSWITCH_PATH = STATE_ROOT / "killswitch.flag"
PAIRING_FLAG_PATH_DEFAULT = STATE_ROOT / "allow_pairing.flag"
BUILD_STAMP_PATH = REPORTS / "activate_athena_8000_report.json"
TAILSCALE_SERVE_REPORT_PATH = REPORTS / "tailscale_serve_status.json"
KNOWLEDGE_STORE_DIR = BASE / "knowledge" / "store"
KNOWLEDGE_STORE_INDEX_PATH = KNOWLEDGE_STORE_DIR / "index.json"
KNOWLEDGE_STORE_RECORDS_DIR = KNOWLEDGE_STORE_DIR / "records"
KNOWLEDGE_STORE_CHAT_MEMO_PATH = KNOWLEDGE_STORE_DIR / "chat_memo.jsonl"
KNOWLEDGE_PACK_INDEX_PATH = BASE / "docs" / "knowledge_pack" / "index.json"
KNOWLEDGE_PACK_ROADMAP_PATH = BASE / "docs" / "knowledge_pack" / "roadmap.json"

PENDING_PATCHES = STATE / "pending_patch_runs.json"
SUGGESTIONS = STATE / "mason_teacher_suggestions.json"

DEVICE_RATE_STATE: dict[str, list[float]] = {}
NONCE_STATE: dict[str, float] = {}
PAIRING_SESSIONS: dict[str, dict[str, Any]] = {}
TEACHER_CALL_COUNT = 0


def env_int(name: str, default: int) -> int:
    try:
        value = int(str(os.getenv(name, "")).strip())
        return value if value > 0 else default
    except Exception:
        return default


DOCTOR_FULL_TIMEOUT_SECONDS = env_int("MASON_DOCTOR_FULL_TIMEOUT_SECONDS", 600)
DOCTOR_QUICK_TIMEOUT_SECONDS = env_int("MASON_DOCTOR_QUICK_TIMEOUT_SECONDS", 90)
E2E_VERIFY_TIMEOUT_SECONDS = env_int("MASON_E2E_TIMEOUT_SECONDS", 240)

# --- App setup -----------------------------------------------------

app = FastAPI(title="Athena Console")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Models --------------------------------------------------------


class IngestChunkRequest(BaseModel):
    content: str = Field(default="")
    label: str = Field(default="ingest")
    max_chars: int = Field(default=6000, ge=1, le=20000)


class KnowledgeAppendRequest(BaseModel):
    source: str = Field(default="athena")
    kind: str = Field(default="note")
    text: str = Field(default="")
    tags: list[str] = Field(default_factory=list)
    priority: int = Field(default=5, ge=0, le=10)


class ToolRecommendRequest(BaseModel):
    answers: dict[str, Any] = Field(default_factory=dict)


class ToolRunRequest(BaseModel):
    tool_id: str = Field(min_length=1)
    workspace_id: str | None = Field(default=None)
    client_name: str = Field(default="client")
    input: dict[str, Any] = Field(default_factory=dict)


class PairStartRequest(BaseModel):
    device_id: str = Field(default="")
    device_label: str = Field(default="iPhone")


class PairCompleteRequest(BaseModel):
    token: str = Field(min_length=12)
    device_id: str = Field(min_length=3, max_length=64)
    device_label: str = Field(default="iPhone")


class UploadTextRequest(BaseModel):
    source: str = Field(default="athena_upload")
    kind: str = Field(default="upload_text")
    text: str = Field(default="")
    tags: list[str] = Field(default_factory=list)
    priority: int = Field(default=5, ge=0, le=10)


class UploadZipRequest(BaseModel):
    filename: str = Field(default="upload.zip")
    zip_base64: str = Field(default="")
    tags: list[str] = Field(default_factory=list)


class ChatRequest(BaseModel):
    text: str = Field(default="")
    tags: list[str] = Field(default_factory=list)
    priority: int = Field(default=5, ge=0, le=10)


class MirrorRunRequest(BaseModel):
    reason: str = Field(default="manual")


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
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def append_jsonl(path: Path, payload: dict[str, Any]) -> None:
    ensure_parent(path)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(payload, ensure_ascii=False) + "\n")


def normalize_list(value: Any) -> list[Any]:
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def normalize_text(value: Any) -> str:
    return " ".join(str(value or "").replace("\r", "\n").split()).strip()


def redact_secrets(text: str) -> str:
    redacted = text
    redacted = re.sub(r"(?i)\bsk-proj-[A-Za-z0-9_\-]{8,}\b", "[REDACTED_OPENAI_KEY]", redacted)
    redacted = re.sub(r"(?i)\bsk-[A-Za-z0-9_\-]{8,}\b", "[REDACTED_OPENAI_KEY]", redacted)
    redacted = re.sub(r"(?i)\b(?:ghp|gho|ghu|ghs)_[A-Za-z0-9_]{20,}\b", "[REDACTED_GITHUB_TOKEN]", redacted)
    redacted = re.sub(r"(?i)\bgithub_pat_[A-Za-z0-9_]{20,}\b", "[REDACTED_GITHUB_TOKEN]", redacted)
    redacted = re.sub(
        r"(?is)-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----.*?-----END [A-Z0-9 ]*PRIVATE KEY-----",
        "[REDACTED_PRIVATE_KEY_BLOCK]",
        redacted,
    )
    return redacted


def first_sentence_summary(text: str, max_chars: int = 280) -> str:
    cleaned = normalize_text(text)
    if not cleaned:
        return ""
    chunks = [part.strip() for part in re.split(r"(?<=[.!?])\s+", cleaned) if part.strip()]
    summary = " ".join(chunks[:2]) if chunks else cleaned
    if len(summary) <= max_chars:
        return summary
    return summary[: max_chars - 3].rstrip() + "..."


def extract_lines_by_pattern(text: str, patterns: list[str], max_items: int = 8) -> list[str]:
    output: list[str] = []
    seen: set[str] = set()
    lines = [line.strip(" -*\t") for line in text.splitlines() if line.strip()]
    for line in lines:
        lower = line.lower()
        if not any(re.search(pattern, lower) for pattern in patterns):
            continue
        normalized = normalize_text(line)
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        output.append(normalized)
        if len(output) >= max_items:
            break
    return output


def infer_tags(text: str) -> list[str]:
    lower = text.lower()
    rules = {
        "mason": [r"\bmason\b"],
        "athena": [r"\bathena\b"],
        "onyx": [r"\bonyx\b"],
        "budget": [r"\bbudget\b", r"\bcost\b"],
        "ingest": [r"\bingest\b", r"\bchunk\b"],
        "approvals": [r"\bapproval", r"\bapprove\b", r"\breject\b"],
        "security": [r"\bsecurity\b", r"\bsecret\b", r"\btoken\b", r"private key"],
        "roadmap": [r"\broadmap\b", r"\bmilestone\b", r"\bnext step\b"],
    }
    tags: list[str] = []
    for tag, patterns in rules.items():
        if any(re.search(pattern, lower) for pattern in patterns):
            tags.append(tag)
    return tags


def estimate_usage_tokens(text: str) -> dict[str, int]:
    input_tokens = max(1, int((len(text) + 2) / 3))
    output_tokens = max(32, int((input_tokens * 0.2) + 0.5))
    return {"input_tokens": input_tokens, "output_tokens": output_tokens}


def extract_string_list(value: Any, max_items: int) -> list[str]:
    output: list[str] = []
    seen: set[str] = set()
    for entry in normalize_list(value):
        item = normalize_text(entry)
        if not item or item in seen:
            continue
        seen.add(item)
        output.append(item)
        if len(output) >= max_items:
            break
    return output


def extract_json_object(text: str) -> dict[str, Any]:
    if not text:
        return {}
    raw = text.strip()
    if not raw:
        return {}
    try:
        value = json.loads(raw)
        return value if isinstance(value, dict) else {}
    except Exception:
        start = raw.find("{")
        end = raw.rfind("}")
        if start >= 0 and end > start:
            fragment = raw[start : end + 1]
            try:
                value = json.loads(fragment)
                return value if isinstance(value, dict) else {}
            except Exception:
                return {}
    return {}


def load_openai_api_key() -> str:
    env_key = (os.getenv("OPENAI_API_KEY") or "").strip()
    if env_key:
        return env_key

    data = read_json(SECRETS_PATH, default={})
    if isinstance(data, dict):
        direct_key = str(data.get("openai_api_key") or "").strip()
        if direct_key:
            return direct_key
        nested = data.get("openai")
        if isinstance(nested, dict):
            nested_key = str(nested.get("api_key") or "").strip()
            if nested_key:
                return nested_key
    return ""


def normalize_ingest_contract(
    source: dict[str, Any],
    redacted_text: str,
) -> dict[str, Any]:
    summary = normalize_text(source.get("summary", ""))
    if not summary and redacted_text:
        summary = first_sentence_summary(redacted_text)
    if not summary and redacted_text:
        summary = normalize_text(redacted_text[:240])

    decisions = extract_string_list(source.get("decisions"), max_items=8)
    rules = extract_string_list(source.get("rules"), max_items=8)
    done_items = extract_string_list(source.get("done_items"), max_items=10)
    open_items = extract_string_list(source.get("open_items"), max_items=12)
    tags = extract_string_list(source.get("tags"), max_items=12)
    if not tags and redacted_text:
        tags = infer_tags(redacted_text)

    return {
        "summary": summary,
        "decisions": decisions,
        "rules": rules,
        "done_items": done_items,
        "open_items": open_items,
        "tags": tags,
    }


def heuristic_ingest_contract(redacted_text: str) -> dict[str, Any]:
    return normalize_ingest_contract(
        {
            "summary": first_sentence_summary(redacted_text),
            "decisions": extract_lines_by_pattern(
                redacted_text,
                patterns=[r"\bdecision\b", r"\bdecide\b", r"\bchosen\b", r"\bwe will\b"],
                max_items=8,
            ),
            "rules": extract_lines_by_pattern(
                redacted_text,
                patterns=[r"\bmust\b", r"\bshould\b", r"\bnever\b", r"\balways\b", r"\brule\b", r"\bnon-negotiable\b"],
                max_items=8,
            ),
            "done_items": extract_lines_by_pattern(
                redacted_text,
                patterns=[r"^\[x\]", r"\bdone\b", r"\bcompleted\b", r"\bfinished\b"],
                max_items=10,
            ),
            "open_items": extract_lines_by_pattern(
                redacted_text,
                patterns=[r"^\[\s\]", r"\bopen item\b", r"\btodo\b", r"\bnext step\b", r"\baction\b"],
                max_items=12,
            ),
            "tags": infer_tags(redacted_text),
        },
        redacted_text,
    )


def extract_usage_tokens(usage: Any) -> dict[str, int] | None:
    if usage is None:
        return None

    input_tokens: int | None = None
    output_tokens: int | None = None

    if isinstance(usage, dict):
        for key in ("input_tokens", "prompt_tokens"):
            if usage.get(key) is not None:
                try:
                    input_tokens = int(usage.get(key))
                    break
                except Exception:
                    pass
        for key in ("output_tokens", "completion_tokens"):
            if usage.get(key) is not None:
                try:
                    output_tokens = int(usage.get(key))
                    break
                except Exception:
                    pass
    else:
        for key in ("input_tokens", "prompt_tokens"):
            value = getattr(usage, key, None)
            if value is not None:
                try:
                    input_tokens = int(value)
                    break
                except Exception:
                    pass
        for key in ("output_tokens", "completion_tokens"):
            value = getattr(usage, key, None)
            if value is not None:
                try:
                    output_tokens = int(value)
                    break
                except Exception:
                    pass

    if input_tokens is None and output_tokens is None:
        return None
    return {
        "input_tokens": max(0, int(input_tokens or 0)),
        "output_tokens": max(0, int(output_tokens or 0)),
    }


def call_openai_ingest_contract(
    redacted_text: str,
    label: str,
    max_chars: int,
) -> tuple[dict[str, Any] | None, dict[str, int] | None]:
    try:
        from openai import OpenAI
    except Exception:
        return None, None

    client = OpenAI(api_key=load_openai_api_key())
    model_name = os.getenv("MASON_MODEL", "gpt-5.1")
    user_text = redacted_text[:max_chars]

    instruction = (
        "Return strict JSON with keys: summary, decisions, rules, done_items, open_items, tags. "
        "All list fields must be arrays of short strings. No markdown."
    )
    completion = client.chat.completions.create(
        model=model_name,
        temperature=0,
        response_format={"type": "json_object"},
        messages=[
            {
                "role": "system",
                "content": (
                    "You summarize ingest text for automation. "
                    + instruction
                ),
            },
            {
                "role": "user",
                "content": f"label={label}\nmax_chars={max_chars}\ntext:\n{user_text}",
            },
        ],
        timeout=25,
    )

    content_text = ""
    if completion.choices and completion.choices[0].message:
        content_text = completion.choices[0].message.content or ""
    parsed = extract_json_object(content_text)
    contract = normalize_ingest_contract(parsed, redacted_text)
    usage = extract_usage_tokens(getattr(completion, "usage", None))
    return contract, usage


def list_ingest_indexes() -> list[Path]:
    return sorted(
        REPORTS.glob("ingest_index_*.json"),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )


def parse_json_from_output(stdout_text: str) -> dict[str, Any] | None:
    raw = (stdout_text or "").strip()
    if not raw:
        return None

    try:
        value = json.loads(raw)
        return value if isinstance(value, dict) else None
    except Exception:
        pass

    lines = [line.strip() for line in raw.splitlines() if line.strip()]
    for line in reversed(lines):
        try:
            value = json.loads(line)
            if isinstance(value, dict):
                return value
        except Exception:
            continue
    return None


def run_powershell_json(script_path: Path, args: list[str], timeout_sec: int = 90) -> dict[str, Any]:
    if not script_path.exists():
        return {"ok": False, "error": f"missing_script:{script_path}"}

    cmd = [
        "powershell.exe",
        "-NoLogo",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        str(script_path),
    ] + args

    try:
        proc = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout_sec,
            cwd=str(BASE),
        )
    except subprocess.TimeoutExpired:
        return {"ok": False, "error": "script_timeout"}
    except Exception as exc:
        return {"ok": False, "error": f"script_spawn_failed:{type(exc).__name__}"}

    stdout_safe = redact_secrets(proc.stdout or "")
    stderr_safe = redact_secrets(proc.stderr or "")
    parsed = parse_json_from_output(stdout_safe)
    if isinstance(parsed, dict):
        if proc.returncode != 0 and "ok" not in parsed:
            parsed["ok"] = False
            parsed["error"] = parsed.get("error") or f"script_exit_{proc.returncode}"
        return parsed

    if proc.returncode == 0:
        return {"ok": True}
    return {
        "ok": False,
        "error": f"script_exit_{proc.returncode}",
        "stderr": stderr_safe[:800],
    }


def sanitize_tool_catalog_entry(tool: dict[str, Any]) -> dict[str, Any]:
    return {
        "tool_id": str(tool.get("tool_id", "")),
        "version": str(tool.get("version", "")),
        "title": str(tool.get("title", "")),
        "risk_level": str(tool.get("risk_level", "")),
        "budget_class": str(tool.get("budget_class", "")),
        "tags": [str(x) for x in normalize_list(tool.get("tags"))],
        "supported_business_types": [str(x) for x in normalize_list(tool.get("supported_business_types"))],
        "input_schema": tool.get("input_schema", {}),
        "output_schema": tool.get("output_schema", {}),
    }


def safe_resolve_in_repo(path_value: str) -> Path | None:
    if not path_value:
        return None
    candidate = Path(path_value)
    full = candidate if candidate.is_absolute() else (BASE / candidate)
    try:
        resolved = full.resolve()
        base_resolved = BASE.resolve()
        if str(resolved).lower().startswith(str(base_resolved).lower()):
            return resolved
    except Exception:
        return None
    return None


def load_remote_access_policy() -> dict[str, Any]:
    default = {
        "enabled": True,
        "allow_loopback": True,
        "allow_tailnet_cidr": "100.64.0.0/10",
        "allow_additional_cidrs": [],
        "require_signed_requests": True,
        "signed_exempt_paths": [
            "/api/health",
            "/api/version",
            "/api/ingest_chunk",
            "/api/ingest_index",
            "/api/auth/pair/start",
            "/api/auth/pair/complete",
        ],
        "timestamp_skew_seconds": 300,
        "nonce_ttl_seconds": 300,
        "rate_limit_per_minute": 120,
        "pairing_flag_path": str(PAIRING_FLAG_PATH_DEFAULT),
    }
    configured = read_json(REMOTE_ACCESS_POLICY_PATH, default={})
    if isinstance(configured, dict):
        default.update(configured)
    return default


def get_pairing_flag_path(policy: dict[str, Any]) -> Path:
    path_value = str(policy.get("pairing_flag_path") or "").strip()
    if not path_value:
        return PAIRING_FLAG_PATH_DEFAULT
    candidate = safe_resolve_in_repo(path_value)
    return candidate or PAIRING_FLAG_PATH_DEFAULT


def get_client_ip(request: Request) -> str:
    if request.client and request.client.host:
        return str(request.client.host).strip()
    return ""


def is_ip_allowed(ip_text: str, policy: dict[str, Any]) -> bool:
    if not ip_text:
        return True
    if ip_text in {"localhost", "testclient"}:
        return True
    try:
        ip = ipaddress.ip_address(ip_text)
    except Exception:
        return False

    allow_loopback = bool(policy.get("allow_loopback", True))
    if allow_loopback and ip.is_loopback:
        return True

    cidr_values: list[str] = []
    tailnet = str(policy.get("allow_tailnet_cidr") or "").strip()
    if tailnet:
        cidr_values.append(tailnet)
    for entry in normalize_list(policy.get("allow_additional_cidrs")):
        text = str(entry or "").strip()
        if text:
            cidr_values.append(text)

    for cidr in cidr_values:
        try:
            network = ipaddress.ip_network(cidr, strict=False)
            if ip in network:
                return True
        except Exception:
            continue
    return False


def is_signed_exempt_path(path: str, policy: dict[str, Any]) -> bool:
    hard_exempt = {
        "/api/health",
        "/api/version",
        "/api/auth/pair/start",
        "/api/auth/pair/complete",
    }
    if path in hard_exempt:
        return True

    for raw in normalize_list(policy.get("signed_exempt_paths")):
        candidate = str(raw or "").strip()
        if not candidate:
            continue
        if candidate.endswith("*"):
            prefix = candidate[:-1]
            if path.startswith(prefix):
                return True
            continue
        if path == candidate:
            return True
    return False


def load_device_registry() -> dict[str, Any]:
    data = read_json(ATHENA_DEVICE_REGISTRY_PATH, default={"version": 1, "devices": []})
    if not isinstance(data, dict):
        return {"version": 1, "devices": []}
    if "devices" not in data or not isinstance(data.get("devices"), list):
        data["devices"] = []
    if "version" not in data:
        data["version"] = 1
    return data


def save_device_registry(data: dict[str, Any]) -> None:
    write_json(ATHENA_DEVICE_REGISTRY_PATH, data)


def get_device_record(device_id: str) -> dict[str, Any] | None:
    registry = load_device_registry()
    for row in normalize_list(registry.get("devices")):
        if not isinstance(row, dict):
            continue
        if str(row.get("device_id", "")).strip() == device_id:
            return row
    return None


def upsert_device_record(device_id: str, device_label: str, secret_value: str) -> dict[str, Any]:
    registry = load_device_registry()
    devices = [row for row in normalize_list(registry.get("devices")) if isinstance(row, dict)]
    now = utc_now_iso()
    output: dict[str, Any] | None = None
    for row in devices:
        if str(row.get("device_id", "")).strip() == device_id:
            row["device_label"] = device_label
            row["hmac_secret"] = secret_value
            row["last_seen_at"] = now
            row["updated_at"] = now
            output = row
            break
    if output is None:
        output = {
            "device_id": device_id,
            "device_label": device_label,
            "hmac_secret": secret_value,
            "created_at": now,
            "updated_at": now,
            "last_seen_at": now,
            "enabled": True,
        }
        devices.append(output)
    registry["devices"] = devices
    save_device_registry(registry)
    return output


def update_device_last_seen(device_id: str) -> None:
    registry = load_device_registry()
    devices = [row for row in normalize_list(registry.get("devices")) if isinstance(row, dict)]
    updated = False
    now = utc_now_iso()
    for row in devices:
        if str(row.get("device_id", "")).strip() == device_id:
            row["last_seen_at"] = now
            updated = True
            break
    if updated:
        registry["devices"] = devices
        save_device_registry(registry)


def get_device_secret(device_id: str) -> str:
    row = get_device_record(device_id)
    if not row:
        return ""
    if not bool(row.get("enabled", True)):
        return ""
    return str(row.get("hmac_secret") or "").strip()


def cleanup_nonce_state(ttl_seconds: int) -> None:
    now = time.time()
    expired = [nonce for nonce, seen_ts in NONCE_STATE.items() if now - seen_ts > ttl_seconds]
    for nonce in expired:
        NONCE_STATE.pop(nonce, None)


def check_rate_limit(device_id: str, limit_per_minute: int) -> bool:
    if limit_per_minute <= 0:
        return True
    now = time.time()
    history = DEVICE_RATE_STATE.get(device_id, [])
    history = [ts for ts in history if now - ts < 60.0]
    if len(history) >= limit_per_minute:
        DEVICE_RATE_STATE[device_id] = history
        return False
    history.append(now)
    DEVICE_RATE_STATE[device_id] = history
    return True


def constant_time_compare_hex(left: str, right: str) -> bool:
    try:
        return hmac.compare_digest(left.encode("utf-8"), right.encode("utf-8"))
    except Exception:
        return False


def verify_signed_headers(
    request: Request,
    body_bytes: bytes,
    policy: dict[str, Any],
) -> tuple[bool, str, str]:
    device_id = str(request.headers.get("x-mason-device", "")).strip()
    nonce = str(request.headers.get("x-mason-nonce", "")).strip()
    ts_raw = str(request.headers.get("x-mason-timestamp", "")).strip()
    signature = str(request.headers.get("x-mason-signature", "")).strip().lower()

    if not device_id or not nonce or not ts_raw or not signature:
        return False, "missing_signature_headers", ""
    if not re.fullmatch(r"[A-Za-z0-9._-]{3,64}", device_id):
        return False, "invalid_device_id", ""
    if not re.fullmatch(r"[A-Za-z0-9._-]{8,96}", nonce):
        return False, "invalid_nonce", ""
    if not re.fullmatch(r"[0-9a-f]{64}", signature):
        return False, "invalid_signature_format", ""

    try:
        ts = int(ts_raw)
    except Exception:
        return False, "invalid_timestamp", ""

    now = int(time.time())
    skew = int(policy.get("timestamp_skew_seconds", 300) or 300)
    if abs(now - ts) > skew:
        return False, "timestamp_out_of_range", ""

    ttl = int(policy.get("nonce_ttl_seconds", 300) or 300)
    cleanup_nonce_state(ttl)
    if nonce in NONCE_STATE:
        return False, "nonce_replay", ""

    secret_value = get_device_secret(device_id)
    if not secret_value:
        return False, "unknown_device", ""

    body_hash = hashlib.sha256(body_bytes).hexdigest()
    path_with_query = request.url.path + (f"?{request.url.query}" if request.url.query else "")
    sign_payload = "\n".join(
        [
            request.method.upper(),
            path_with_query,
            str(ts),
            nonce,
            body_hash,
        ]
    ).encode("utf-8")
    expected = hmac.new(
        secret_value.encode("utf-8"),
        sign_payload,
        hashlib.sha256,
    ).hexdigest().lower()

    if not constant_time_compare_hex(signature, expected):
        return False, "signature_mismatch", ""

    NONCE_STATE[nonce] = time.time()
    limit = int(policy.get("rate_limit_per_minute", 120) or 120)
    if not check_rate_limit(device_id, limit):
        return False, "rate_limit_exceeded", ""

    update_device_last_seen(device_id)
    return True, "", device_id


def append_event(
    kind: str,
    status: str,
    details: dict[str, Any] | None = None,
    correlation_id: str | None = None,
) -> None:
    payload = {
        "ts_utc": utc_now_iso(),
        "kind": kind,
        "status": status,
        "component": "athena",
        "correlation_id": correlation_id or f"athena-{uuid4().hex[:12]}",
        "details": details or {},
    }
    append_jsonl(EVENTS_PATH, payload)


def append_knowledge_record(
    source: str,
    kind: str,
    text: str,
    tags: list[str] | None = None,
    priority: int = 5,
    event_kind: str | None = None,
) -> dict[str, Any]:
    clean_text = redact_secrets(text or "")
    record = {
        "ts": utc_now_iso(),
        "source": source or "athena",
        "kind": kind or "note",
        "text": clean_text,
        "tags": [str(tag) for tag in (tags or []) if str(tag).strip()],
        "priority": int(priority),
    }
    daily_path = KNOWLEDGE_DIR / f"knowledge_inbox_{datetime.now().strftime('%Y%m%d')}.jsonl"
    latest_path = KNOWLEDGE_DIR / "knowledge_inbox_latest.jsonl"
    append_jsonl(daily_path, record)
    append_jsonl(latest_path, record)
    if event_kind:
        append_event(
            kind=event_kind,
            status="saved",
            details={"source": record["source"], "kind": record["kind"]},
        )
    return {
        "saved": 1,
        "paths": [str(daily_path), str(latest_path)],
    }


def load_component_registry() -> list[dict[str, Any]]:
    raw = read_json(COMPONENT_REGISTRY_PATH, default={"components": []})
    if not isinstance(raw, dict):
        return []
    out: list[dict[str, Any]] = []
    for item in normalize_list(raw.get("components")):
        if isinstance(item, dict):
            out.append(item)
    return out


def find_component(component_id: str) -> dict[str, Any] | None:
    target = (component_id or "").strip().lower()
    if not target:
        return None
    for comp in load_component_registry():
        cid = str(comp.get("id", "")).strip().lower()
        if cid == target:
            return comp
    return None


def read_component_status_sources(component: dict[str, Any]) -> list[dict[str, Any]]:
    snapshots: list[dict[str, Any]] = []
    for source in normalize_list(component.get("status_sources")):
        rel = str(source or "").strip()
        if not rel:
            continue
        resolved = safe_resolve_in_repo(rel)
        if not resolved:
            snapshots.append({"source": rel, "exists": False, "error": "outside_repo"})
            continue
        if not resolved.exists():
            snapshots.append({"source": rel, "exists": False})
            continue
        payload = read_json(resolved, default={})
        snapshots.append(
            {
                "source": rel,
                "exists": True,
                "last_write_utc": datetime.fromtimestamp(resolved.stat().st_mtime, tz=timezone.utc)
                .isoformat()
                .replace("+00:00", "Z"),
                "data": payload if isinstance(payload, (dict, list)) else {},
            }
        )
    return snapshots


def readme_for_component(component: dict[str, Any]) -> dict[str, Any]:
    readme_path = str(component.get("readme_path") or "").strip()
    if not readme_path:
        return {"ok": False, "error": "missing_readme_path"}
    resolved = safe_resolve_in_repo(readme_path)
    if not resolved:
        return {"ok": False, "error": "readme_outside_repo", "path": readme_path}
    if not resolved.exists():
        return {"ok": False, "error": "readme_missing", "path": readme_path}
    try:
        text = resolved.read_text(encoding="utf-8-sig")
    except Exception:
        text = resolved.read_text(encoding="utf-8", errors="ignore")
    return {
        "ok": True,
        "path": readme_path,
        "text": redact_secrets(text)[:50000],
    }


def filter_approvals_for_component(component: dict[str, Any]) -> list[dict[str, Any]]:
    component_id = str(component.get("id", "")).strip().lower()
    filters = component.get("approvals_filters") if isinstance(component.get("approvals_filters"), dict) else {}
    area_prefix = str(filters.get("area_prefix") or "").strip().lower()
    items = get_approvals()
    out: list[dict[str, Any]] = []
    for item in items:
        comp = str(item.get("component_id", "")).strip().lower()
        area = str(item.get("area", "")).strip().lower()
        if comp and comp == component_id:
            out.append(item)
            continue
        if area_prefix and area.startswith(area_prefix):
            out.append(item)
    return out


def load_ports_contract() -> dict[str, Any]:
    data = read_json(PORTS_PATH, default={"ports": {}, "bind_host": "127.0.0.1"})
    if not isinstance(data, dict):
        return {"ports": {}, "bind_host": "127.0.0.1"}
    if "ports" not in data or not isinstance(data.get("ports"), dict):
        data["ports"] = {}
    if "bind_host" not in data:
        data["bind_host"] = "127.0.0.1"
    return data


def current_queue_summary() -> dict[str, Any]:
    pending_llm_count = 0
    if KNOWLEDGE_PENDING_LLM_DIR.exists():
        pending_llm_count = sum(1 for _ in KNOWLEDGE_PENDING_LLM_DIR.rglob("*.json"))
    approvals_total = len(get_approvals())
    return {
        "pending_llm_chunks": pending_llm_count,
        "approvals_total": approvals_total,
    }


def ensure_control_allowed(action: str, allow_when_killswitch: bool = False) -> tuple[bool, str]:
    if KILLSWITCH_PATH.exists() and not allow_when_killswitch:
        return False, "killswitch_enabled"
    return True, ""


def execute_control_script(script_path: Path, args: list[str], timeout_sec: int = 180) -> dict[str, Any]:
    result = run_powershell_json(script_path, args=args, timeout_sec=timeout_sec)
    if isinstance(result, dict):
        return result
    return {"ok": False, "error": "unexpected_script_result"}


def to_repo_relative(path: Path) -> str:
    try:
        return str(path.resolve().relative_to(BASE.resolve())).replace("\\", "/")
    except Exception:
        return str(path)


def save_job_record(job_payload: dict[str, Any]) -> Path:
    JOBS_DIR.mkdir(parents=True, exist_ok=True)
    job_id = str(job_payload.get("job_id", "")).strip()
    if not job_id:
        raise ValueError("missing_job_id")
    job_path = JOBS_DIR / f"{job_id}.json"
    write_json(job_path, job_payload)
    return job_path


def list_job_records(action: str = "") -> list[dict[str, Any]]:
    if not JOBS_DIR.exists():
        return []
    target_action = normalize_text(action).lower()
    rows: list[dict[str, Any]] = []
    for path in sorted(JOBS_DIR.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True):
        row = read_json(path, default={})
        if not isinstance(row, dict):
            continue
        if target_action and normalize_text(row.get("action", "")).lower() != target_action:
            continue
        rows.append(row)
    return rows


def read_job_record(job_id: str) -> dict[str, Any] | None:
    if not re.fullmatch(r"[A-Za-z0-9_.\-]+", job_id or ""):
        return None
    path = JOBS_DIR / f"{job_id}.json"
    data = read_json(path, default=None)
    return data if isinstance(data, dict) else None


def resolve_artifact_path_in_repo(path_value: str) -> Path | None:
    if not path_value:
        return None
    candidate = Path(path_value)
    resolved = candidate if candidate.is_absolute() else (BASE / candidate)
    try:
        resolved = resolved.resolve()
        if str(resolved).lower().startswith(str(BASE.resolve()).lower()):
            return resolved
    except Exception:
        return None
    return None


def build_job_payload(
    *,
    job_id: str,
    action: str,
    requested_by_device: str,
    timeout_seconds: int,
    mode: str | None = None,
    artifacts: dict[str, Any] | None = None,
) -> dict[str, Any]:
    return {
        "job_id": job_id,
        "action": action,
        "mode": mode or None,
        "requested_by_device": requested_by_device or "unknown",
        "started_at_utc": utc_now_iso(),
        "ended_at_utc": None,
        "ok": None,
        "error": None,
        "timeout_seconds": int(max(1, timeout_seconds)),
        "artifacts": artifacts or {},
    }


def _job_event_kind(action: str, phase: str, lifecycle_prefix: str | None = None) -> str:
    if lifecycle_prefix:
        return f"{lifecycle_prefix}_{phase}"
    safe = re.sub(r"[^a-z0-9_]+", "_", normalize_text(action).lower()).strip("_")
    if not safe:
        safe = "job"
    return f"{safe}_{phase}"


def spawn_script_job(
    *,
    action: str,
    requested_by_device: str,
    script_path: Path,
    args: list[str],
    timeout_seconds: int,
    artifacts: dict[str, Any] | None = None,
    mode: str | None = None,
    lifecycle_prefix: str | None = None,
) -> dict[str, Any]:
    JOBS_DIR.mkdir(parents=True, exist_ok=True)
    safe_action = re.sub(r"[^a-z0-9]+", "_", action.lower()).strip("_") or "job"
    job_id = f"{safe_action}_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}_{uuid4().hex[:8]}"
    stdout_path = JOBS_DIR / f"{job_id}_stdout.log"
    stderr_path = JOBS_DIR / f"{job_id}_stderr.log"

    artifact_map = dict(artifacts or {})
    artifact_map["stdout_log"] = to_repo_relative(stdout_path)
    artifact_map["stderr_log"] = to_repo_relative(stderr_path)

    payload = build_job_payload(
        job_id=job_id,
        action=action,
        requested_by_device=requested_by_device,
        timeout_seconds=timeout_seconds,
        mode=mode,
        artifacts=artifact_map,
    )
    save_job_record(payload)

    append_event(
        kind=_job_event_kind(action, "started", lifecycle_prefix=lifecycle_prefix),
        status="queued",
        details={
            "job_id": job_id,
            "action": action,
            "mode": mode or None,
            "requested_by_device": requested_by_device or "unknown",
            "timeout_seconds": int(max(1, timeout_seconds)),
        },
        correlation_id=job_id,
    )

    cmd = [
        "powershell.exe",
        "-NoLogo",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        str(script_path),
    ] + args

    try:
        stdout_handle = stdout_path.open("w", encoding="utf-8")
        stderr_handle = stderr_path.open("w", encoding="utf-8")
        process = subprocess.Popen(
            cmd,
            cwd=str(BASE),
            stdout=stdout_handle,
            stderr=stderr_handle,
            text=True,
        )
    except Exception as exc:
        error_value = f"spawn_failed:{type(exc).__name__}"
        failed_payload = read_job_record(job_id) or payload
        failed_payload.update(
            {
                "ended_at_utc": utc_now_iso(),
                "ok": False,
                "error": error_value,
            }
        )
        save_job_record(failed_payload)
        append_event(
            kind=_job_event_kind(action, "failed", lifecycle_prefix=lifecycle_prefix),
            status="failed",
            details={"job_id": job_id, "action": action, "mode": mode or None, "error": error_value},
            correlation_id=job_id,
        )
        return {
            "ok": False,
            "error": error_value,
            "job_id": job_id,
            "action": action,
            "mode": mode,
            "status": "failed",
            "job_path": to_repo_relative(JOBS_DIR / f"{job_id}.json"),
        }

    append_event(
        kind=_job_event_kind(action, "progress", lifecycle_prefix=lifecycle_prefix),
        status="running",
        details={"job_id": job_id, "action": action, "mode": mode or None, "pid": int(process.pid)},
        correlation_id=job_id,
    )

    def _wait_and_finalize() -> None:
        timed_out = False
        rc = 1
        try:
            rc = process.wait(timeout=max(1, int(timeout_seconds)))
        except subprocess.TimeoutExpired:
            timed_out = True
            try:
                process.kill()
            except Exception:
                pass
            rc = 124
        except Exception:
            rc = 1
        finally:
            try:
                stdout_handle.close()
            except Exception:
                pass
            try:
                stderr_handle.close()
            except Exception:
                pass

        done_payload = read_job_record(job_id) or payload
        ok = (rc == 0) and (not timed_out)
        error_value = ""
        if timed_out:
            error_value = "timeout"
        elif not ok:
            error_value = f"exit_{rc}"

        done_payload.update(
            {
                "ended_at_utc": utc_now_iso(),
                "ok": ok,
                "error": error_value or None,
            }
        )

        artifacts_value = done_payload.get("artifacts", {}) if isinstance(done_payload.get("artifacts"), dict) else {}
        if action == "run_e2e_verify":
            report_path_raw = str(artifacts_value.get("e2e_report", "reports/mason2_e2e_verify.json"))
            resolved_report = resolve_artifact_path_in_repo(report_path_raw)
            if resolved_report and resolved_report.exists():
                report_data = read_json(resolved_report, default={})
                if isinstance(report_data, dict):
                    done_payload["result_status"] = str(report_data.get("overall_status", "") or "")
        if action == "run_doctor":
            report_path_raw = str(
                artifacts_value.get("doctor_report")
                or artifacts_value.get("doctor_quick_report")
                or ""
            )
            resolved_report = resolve_artifact_path_in_repo(report_path_raw) if report_path_raw else None
            if resolved_report and resolved_report.exists():
                report_data = read_json(resolved_report, default={})
                if isinstance(report_data, dict):
                    done_payload["result_status"] = str(
                        report_data.get("overall_result")
                        or report_data.get("overall_status")
                        or ""
                    )

        save_job_record(done_payload)
        append_event(
            kind=_job_event_kind(action, "completed" if ok else "failed", lifecycle_prefix=lifecycle_prefix),
            status="completed" if ok else "failed",
            details={
                "job_id": job_id,
                "action": action,
                "mode": mode or None,
                "ok": ok,
                "error": error_value or None,
                "timed_out": timed_out,
            },
            correlation_id=job_id,
        )

    thread = threading.Thread(target=_wait_and_finalize, name=f"job-{job_id}", daemon=True)
    thread.start()
    return {
        "ok": True,
        "job_id": job_id,
        "action": action,
        "mode": mode,
        "status": "running",
        "timeout_seconds": int(max(1, timeout_seconds)),
        "job_path": to_repo_relative(JOBS_DIR / f"{job_id}.json"),
        "artifacts": artifact_map,
    }


def sanitize_file_name(value: str, fallback: str = "upload.zip") -> str:
    name = re.sub(r"[^A-Za-z0-9._-]+", "_", str(value or fallback)).strip("._")
    if not name:
        name = fallback
    if len(name) > 120:
        name = name[:120]
    return name


def get_server_build_timestamp() -> str:
    try:
        ts = datetime.fromtimestamp(Path(__file__).stat().st_mtime, tz=timezone.utc)
        return ts.isoformat().replace("+00:00", "Z")
    except Exception:
        return utc_now_iso()


def get_git_commit_short() -> str:
    try:
        proc = subprocess.run(
            ["git", "-C", str(BASE), "rev-parse", "--short", "HEAD"],
            capture_output=True,
            text=True,
            timeout=3,
        )
        if proc.returncode == 0:
            return (proc.stdout or "").strip()
    except Exception:
        return ""
    return ""


def normalize_text_for_hash(text: str) -> str:
    redacted = redact_secrets(text or "")
    return " ".join(redacted.lower().split())


def sha256_hex(text: str) -> str:
    return hashlib.sha256((text or "").encode("utf-8")).hexdigest()


def load_teacher_policy() -> dict[str, Any]:
    default = {
        "version": 1,
        "local_first": True,
        "memoize_ingest_by_sha256": True,
        "memoize_chat_by_query": True,
        "confidence_threshold": 0.65,
        "max_teacher_calls_per_run": 50,
    }
    configured = read_json(TEACHER_POLICY_PATH, default={})
    if isinstance(configured, dict):
        default.update(configured)
    return default


def ensure_knowledge_store() -> None:
    KNOWLEDGE_STORE_RECORDS_DIR.mkdir(parents=True, exist_ok=True)
    if not KNOWLEDGE_STORE_INDEX_PATH.exists():
        write_json(
            KNOWLEDGE_STORE_INDEX_PATH,
            {
                "version": 1,
                "updated_at_utc": utc_now_iso(),
                "items": {},
            },
        )


def load_store_index() -> dict[str, Any]:
    ensure_knowledge_store()
    index = read_json(
        KNOWLEDGE_STORE_INDEX_PATH,
        default={"version": 1, "updated_at_utc": utc_now_iso(), "items": {}},
    )
    if not isinstance(index, dict):
        return {"version": 1, "updated_at_utc": utc_now_iso(), "items": {}}
    items = index.get("items")
    if not isinstance(items, dict):
        index["items"] = {}
    return index


def save_store_index(index: dict[str, Any]) -> None:
    index["updated_at_utc"] = utc_now_iso()
    write_json(KNOWLEDGE_STORE_INDEX_PATH, index)


def read_store_record_by_sha(content_sha256: str) -> dict[str, Any] | None:
    index = load_store_index()
    items = index.get("items", {})
    if not isinstance(items, dict):
        return None
    meta = items.get(content_sha256)
    if not isinstance(meta, dict):
        return None
    raw_record_path = str(meta.get("record_path") or "").strip()
    if not raw_record_path:
        return None
    resolved = safe_resolve_in_repo(raw_record_path)
    if not resolved or not resolved.exists():
        return None
    data = read_json(resolved, default=None)
    if isinstance(data, dict):
        return data
    return None


def write_store_record(content_sha256: str, record_payload: dict[str, Any]) -> None:
    ensure_knowledge_store()
    record_file = KNOWLEDGE_STORE_RECORDS_DIR / f"{content_sha256}.json"
    write_json(record_file, record_payload)

    index = load_store_index()
    items = index.get("items", {})
    if not isinstance(items, dict):
        items = {}
        index["items"] = items
    items[content_sha256] = {
        "record_path": str(record_file.relative_to(BASE)).replace("\\", "/"),
        "updated_at_utc": utc_now_iso(),
        "summary": normalize_text(record_payload.get("summary", ""))[:300],
        "tags": [str(x) for x in normalize_list(record_payload.get("tags"))][:20],
    }
    save_store_index(index)


def query_memo_hash(query_text: str) -> str:
    return sha256_hex(normalize_text_for_hash(query_text))


def lookup_chat_memo(query_hash: str) -> dict[str, Any] | None:
    if not KNOWLEDGE_STORE_CHAT_MEMO_PATH.exists():
        return None
    try:
        lines = KNOWLEDGE_STORE_CHAT_MEMO_PATH.read_text(encoding="utf-8", errors="ignore").splitlines()
    except Exception:
        return None
    for line in reversed(lines):
        item = extract_json_object(line)
        if not item:
            continue
        if str(item.get("query_hash", "")).strip() == query_hash:
            return item
    return None


def append_chat_memo(
    query_hash: str,
    query_text: str,
    answer_text: str,
    confidence: float,
    teacher_used: bool,
    sources: list[str],
) -> None:
    ensure_knowledge_store()
    payload = {
        "ts_utc": utc_now_iso(),
        "query_hash": query_hash,
        "query": redact_secrets(query_text or "")[:2000],
        "answer": redact_secrets(answer_text or "")[:20000],
        "confidence": float(max(0.0, min(1.0, confidence))),
        "teacher_used": bool(teacher_used),
        "sources": [str(s) for s in sources][:20],
    }
    append_jsonl(KNOWLEDGE_STORE_CHAT_MEMO_PATH, payload)


def token_set(text: str) -> set[str]:
    return {t for t in re.findall(r"[a-z0-9]{3,}", (text or "").lower())}


def overlap_score(query_tokens: set[str], candidate_text: str) -> float:
    if not query_tokens:
        return 0.0
    candidate_tokens = token_set(candidate_text)
    if not candidate_tokens:
        return 0.0
    overlap = len(query_tokens.intersection(candidate_tokens))
    return overlap / max(1, len(query_tokens))


def build_local_candidates(query_text: str) -> list[dict[str, Any]]:
    candidates: list[dict[str, Any]] = []

    # 1) Knowledge store records
    index = load_store_index()
    items = index.get("items", {})
    if isinstance(items, dict):
        for _, meta in list(items.items())[:600]:
            if not isinstance(meta, dict):
                continue
            record_path = safe_resolve_in_repo(str(meta.get("record_path") or ""))
            if not record_path or not record_path.exists():
                continue
            record = read_json(record_path, default={})
            if not isinstance(record, dict):
                continue
            text = " ".join(
                [
                    normalize_text(record.get("summary", "")),
                    " ".join(extract_string_list(record.get("decisions"), max_items=8)),
                    " ".join(extract_string_list(record.get("rules"), max_items=8)),
                    " ".join(extract_string_list(record.get("open_items"), max_items=12)),
                    " ".join(extract_string_list(record.get("tags"), max_items=12)),
                ]
            ).strip()
            if not text:
                continue
            candidates.append(
                {
                    "source": str(record_path.relative_to(BASE)).replace("\\", "/"),
                    "text": text,
                }
            )

    # 2) Knowledge pack (sanitized)
    pack_index = read_json(KNOWLEDGE_PACK_INDEX_PATH, default={})
    if isinstance(pack_index, dict):
        for row in normalize_list(pack_index.get("records"))[:800]:
            if not isinstance(row, dict):
                continue
            text = " ".join(
                [
                    normalize_text(row.get("summary", "")),
                    " ".join(extract_string_list(row.get("decisions"), max_items=8)),
                    " ".join(extract_string_list(row.get("rules"), max_items=8)),
                    " ".join(extract_string_list(row.get("open_items"), max_items=12)),
                    " ".join(extract_string_list(row.get("tags"), max_items=12)),
                ]
            ).strip()
            if not text:
                continue
            source_name = str(row.get("ingest_index") or "docs/knowledge_pack/index.json")
            candidates.append({"source": source_name, "text": text})

    roadmap = read_json(KNOWLEDGE_PACK_ROADMAP_PATH, default={})
    if roadmap:
        roadmap_text = redact_secrets(json.dumps(roadmap, ensure_ascii=False))
        candidates.append({"source": "docs/knowledge_pack/roadmap.json", "text": roadmap_text[:12000]})

    # 3) Recent reports
    drift_manifest_path = REPORTS / "drift_manifest.json"
    for report_path in [COMPONENT_INVENTORY_PATH, drift_manifest_path, MASON_CORE_STATUS_PATH]:
        report = read_json(report_path, default={})
        if report:
            candidates.append(
                {
                    "source": str(report_path.relative_to(BASE)).replace("\\", "/"),
                    "text": redact_secrets(json.dumps(report, ensure_ascii=False))[:12000],
                }
            )

    indexes = list_ingest_indexes()
    if indexes:
        latest_index = read_json(indexes[0], default={})
        if latest_index:
            candidates.append(
                {
                    "source": str(indexes[0].relative_to(BASE)).replace("\\", "/"),
                    "text": redact_secrets(json.dumps(latest_index, ensure_ascii=False))[:12000],
                }
            )

    return candidates


def local_retrieve_answer(query_text: str) -> dict[str, Any]:
    query = normalize_text(query_text)
    query_tokens = token_set(query)
    if not query:
        return {"answer": "No question text provided.", "confidence": 0.0, "sources": []}

    ranked: list[tuple[float, dict[str, Any]]] = []
    for candidate in build_local_candidates(query):
        score = overlap_score(query_tokens, str(candidate.get("text", "")))
        if score <= 0:
            continue
        ranked.append((score, candidate))

    ranked.sort(key=lambda row: row[0], reverse=True)
    top = ranked[:5]
    if not top:
        return {
            "answer": "No strong local match found in the knowledge store yet.",
            "confidence": 0.0,
            "sources": [],
        }

    lines = []
    used_sources = []
    for score, item in top:
        source = str(item.get("source", "unknown"))
        text = normalize_text(item.get("text", ""))[:320]
        used_sources.append(source)
        lines.append(f"- [{source}] {text}")
    confidence = float(max(0.0, min(1.0, top[0][0])))
    answer = "Local context matches:\n" + "\n".join(lines)
    return {"answer": answer, "confidence": confidence, "sources": used_sources}


def teacher_call_allowed(policy: dict[str, Any]) -> bool:
    global TEACHER_CALL_COUNT
    max_calls = int(policy.get("max_teacher_calls_per_run", 50) or 50)
    if max_calls < 0:
        max_calls = 0
    return TEACHER_CALL_COUNT < max_calls


def call_teacher_for_chat(query_text: str, local_context: dict[str, Any], policy: dict[str, Any]) -> str | None:
    global TEACHER_CALL_COUNT
    if not teacher_call_allowed(policy):
        return None
    api_key = load_openai_api_key()
    if not api_key:
        return None

    try:
        from openai import OpenAI
    except Exception:
        return None

    model_name = os.getenv("MASON_MODEL", "gpt-5.1")
    context_text = normalize_text(local_context.get("answer", ""))[:12000]
    prompt = (
        "You are Athena. Use local context first and answer clearly in plain text. "
        "Do not reveal secrets, keys, or raw private content."
    )
    try:
        client = OpenAI(api_key=api_key)
        completion = client.chat.completions.create(
            model=model_name,
            temperature=0.2,
            messages=[
                {"role": "system", "content": prompt},
                {
                    "role": "user",
                    "content": f"Question:\n{query_text}\n\nLocal context:\n{context_text}",
                },
            ],
            timeout=25,
        )
        if completion.choices and completion.choices[0].message:
            TEACHER_CALL_COUNT += 1
            return redact_secrets(completion.choices[0].message.content or "")
    except Exception:
        return None
    return None


def get_athena_https_url() -> str:
    env_value = normalize_text(os.getenv("ATHENA_HTTPS_URL", ""))
    if env_value.startswith("https://"):
        return env_value

    report = read_json(TAILSCALE_SERVE_REPORT_PATH, default={})
    if isinstance(report, dict):
        for key in ("athena_https_url", "https_url", "url"):
            candidate = normalize_text(report.get(key, ""))
            if candidate.startswith("https://"):
                return candidate

    try:
        proc = subprocess.run(
            ["tailscale", "serve", "status"],
            capture_output=True,
            text=True,
            timeout=4,
        )
        if proc.returncode == 0:
            text = f"{proc.stdout}\n{proc.stderr}"
            matches = re.findall(r"https://[A-Za-z0-9.-]+\.ts\.net(?:/[^\s]*)?", text)
            if matches:
                candidate = matches[0].strip()
                if candidate.endswith("/"):
                    return f"{candidate}athena/"
                if candidate.lower().endswith("/athena"):
                    return f"{candidate}/"
                if candidate.lower().endswith("/athena/"):
                    return candidate
                return f"{candidate}/athena/"
    except Exception:
        return ""

    return ""


def get_runtime_version_info(request: Request | None = None) -> dict[str, Any]:
    policy = load_remote_access_policy()
    activation_report = read_json(BUILD_STAMP_PATH, default={})
    commit_short = get_git_commit_short()
    build_ts = get_server_build_timestamp()
    https_url = ""
    if request is not None:
        try:
            host_header = str(request.headers.get("host", "")).strip()
            forwarded_host = str(request.headers.get("x-forwarded-host", "")).strip()
            forwarded_proto = str(request.headers.get("x-forwarded-proto", "")).strip()
            scheme = (forwarded_proto.split(",")[0].strip() if forwarded_proto else "") or str(request.url.scheme or "")
            host_raw = (forwarded_host.split(",")[0].strip() if forwarded_host else "") or host_header
            host_name = host_raw.split("/")[0].split(":")[0].strip().lower()
            if scheme.lower() == "https" and host_name.endswith(".ts.net"):
                https_url = f"https://{host_name}/athena/"
        except Exception:
            https_url = ""
    if not https_url:
        https_url = get_athena_https_url()

    hint = ""
    if not https_url:
        hint = "HTTPS ts.net URL not detected. Configure Tailscale Serve and reload /api/version from the HTTPS origin."
    return {
        "ok": True,
        "build_timestamp_utc": build_ts,
        "git_commit_short": commit_short or "unknown",
        "build_id": f"{build_ts}|{commit_short or 'unknown'}",
        "signed_requests_required": bool(policy.get("require_signed_requests", True)),
        "tailnet_url": str(activation_report.get("tailnet_url", "")) if isinstance(activation_report, dict) else "",
        "local_url": str(activation_report.get("local_url", "")) if isinstance(activation_report, dict) else "",
        "athena_https_url": https_url,
        "athena_https_hint": hint,
    }


@app.middleware("http")
async def remote_access_guard(request: Request, call_next):
    path = request.url.path or "/"
    if not path.startswith("/api"):
        return await call_next(request)

    policy = load_remote_access_policy()
    if not bool(policy.get("enabled", True)):
        return await call_next(request)

    client_ip = get_client_ip(request)
    if not is_ip_allowed(client_ip, policy):
        return JSONResponse(status_code=403, content={"ok": False, "error": "ip_not_allowed"})

    require_signed = bool(policy.get("require_signed_requests", True))
    if require_signed and not is_signed_exempt_path(path, policy):
        body = await request.body()
        ok, err, device_id = verify_signed_headers(request, body, policy)
        if not ok:
            code = 429 if err == "rate_limit_exceeded" else 401
            append_event(
                kind="auth",
                status="rejected",
                details={"path": path, "reason": err, "ip": client_ip},
            )
            if err == "signature_mismatch":
                return JSONResponse(
                    status_code=code,
                    content={
                        "ok": False,
                        "error": "signature_mismatch",
                        "hint": "Signing must include query string. Refresh Athena and re-pair if needed.",
                    },
                )
            return JSONResponse(status_code=code, content={"ok": False, "error": err})
        request.state.authenticated_device_id = device_id
    return await call_next(request)


# --- API: approvals / suggestions ----------------------------------


@app.get("/api/approvals")
def get_approvals() -> list[dict[str, Any]]:
    data = read_json(PENDING_PATCHES, default=[])
    if isinstance(data, dict):
        data = [data]
    return [item for item in normalize_list(data) if isinstance(item, dict)]


@app.get("/api/approvals/summary")
def get_approvals_summary() -> dict[str, Any]:
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
def get_suggestions() -> list[dict[str, Any]]:
    data = read_json(SUGGESTIONS, default=[])
    if isinstance(data, dict):
        data = [data]
    return [item for item in normalize_list(data) if isinstance(item, dict)]


@app.get("/api/health")
def get_health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/version")
def api_version(request: Request) -> dict[str, Any]:
    return get_runtime_version_info(request=request)


# --- API: auth / cockpit ------------------------------------------


@app.post("/api/auth/pair/start")
def auth_pair_start(payload: PairStartRequest, request: Request) -> dict[str, Any]:
    policy = load_remote_access_policy()
    client_ip = get_client_ip(request)
    local_request = client_ip in {"localhost", "testclient"}
    if client_ip:
        try:
            local_request = ipaddress.ip_address(client_ip).is_loopback
        except Exception:
            local_request = local_request or False
    pairing_flag = get_pairing_flag_path(policy)

    if not local_request and not pairing_flag.exists():
        return JSONResponse(
            status_code=403,
            content={"ok": False, "error": "pairing_not_allowed"},
        )

    requested_device_id = normalize_text(payload.device_id or "")
    if requested_device_id and not re.fullmatch(r"[A-Za-z0-9._-]{3,64}", requested_device_id):
        return JSONResponse(
            status_code=400,
            content={"ok": False, "error": "invalid_device_id"},
        )

    token = secrets.token_urlsafe(32)
    code = secrets.token_hex(3).upper()
    now = time.time()
    ttl_sec = min(600, max(60, int(policy.get("nonce_ttl_seconds", 300) or 300)))
    expires_at = now + ttl_sec
    PAIRING_SESSIONS[token] = {
        "created_at": now,
        "expires_at": expires_at,
        "code": code,
        "requested_device_id": requested_device_id,
        "requested_label": normalize_text(payload.device_label or "iPhone")[:80] or "iPhone",
        "ip": client_ip,
    }
    append_event(
        kind="pairing",
        status="started",
        details={"ip": client_ip, "expires_in_sec": ttl_sec},
    )
    return {
        "ok": True,
        "token": token,
        "pair_code": code,
        "device_id": requested_device_id,
        "expires_at_utc": datetime.fromtimestamp(expires_at, tz=timezone.utc).isoformat().replace("+00:00", "Z"),
    }


@app.post("/api/auth/pair/complete")
def auth_pair_complete(payload: PairCompleteRequest, request: Request) -> dict[str, Any]:
    token = (payload.token or "").strip()
    device_id = (payload.device_id or "").strip()
    device_label = normalize_text(payload.device_label or "iPhone")[:80] or "iPhone"

    if not re.fullmatch(r"[A-Za-z0-9._-]{3,64}", device_id):
        return JSONResponse(status_code=400, content={"ok": False, "error": "invalid_device_id"})

    session = PAIRING_SESSIONS.get(token)
    if not session:
        return JSONResponse(status_code=400, content={"ok": False, "error": "pair_token_invalid"})

    now = time.time()
    if now > float(session.get("expires_at", 0)):
        PAIRING_SESSIONS.pop(token, None)
        return JSONResponse(status_code=400, content={"ok": False, "error": "pair_token_expired"})

    device_secret = secrets.token_urlsafe(48)
    upsert_device_record(device_id=device_id, device_label=device_label, secret_value=device_secret)
    PAIRING_SESSIONS.pop(token, None)
    append_event(
        kind="pairing",
        status="completed",
        details={"device_id": device_id, "ip": get_client_ip(request)},
    )
    return {
        "ok": True,
        "device_id": device_id,
        "device_label": device_label,
        "hmac_secret": device_secret,
        "algorithm": "HMAC-SHA256",
        "signature_headers": [
            "x-mason-device",
            "x-mason-timestamp",
            "x-mason-nonce",
            "x-mason-signature",
        ],
    }


@app.get("/api/status")
def api_status() -> dict[str, Any]:
    inventory = read_json(COMPONENT_INVENTORY_PATH, default={})
    ingest_status = read_json(INGEST_STATUS_PATH, default={})
    budget_state = read_json(BUDGET_STATE_PATH, default={})
    mason_core_status = read_json(MASON_CORE_STATUS_PATH, default={})
    ports = load_ports_contract()
    queues = current_queue_summary()

    return {
        "ok": True,
        "generated_at_utc": utc_now_iso(),
        "ports_contract": ports,
        "queues": queues,
        "budget": budget_state if isinstance(budget_state, dict) else {},
        "ingest": ingest_status if isinstance(ingest_status, dict) else {},
        "inventory_summary": inventory.get("summary", {}) if isinstance(inventory, dict) else {},
        "core_status": mason_core_status.get("overall_status", "") if isinstance(mason_core_status, dict) else "",
        "killswitch_enabled": KILLSWITCH_PATH.exists(),
    }


@app.get("/api/queues")
def api_queues() -> dict[str, Any]:
    queues = current_queue_summary()
    return {
        "ok": True,
        "generated_at_utc": utc_now_iso(),
        **queues,
        "pending_patch_path": str(PENDING_PATCHES),
        "pending_llm_dir": str(KNOWLEDGE_PENDING_LLM_DIR),
    }


@app.get("/api/budget")
def api_budget() -> dict[str, Any]:
    data = read_json(BUDGET_STATE_PATH, default={})
    budget_data = data if isinstance(data, dict) else {}
    budget_policy = read_json(BUDGET_POLICY_CONFIG_PATH, default={})
    currency_policy = read_json(CURRENCY_POLICY_CONFIG_PATH, default={})
    budget_policy_data = budget_policy if isinstance(budget_policy, dict) else {}
    currency_policy_data = currency_policy if isinstance(currency_policy, dict) else {}

    def _num(*keys: str, default: float = 0.0) -> float:
        for key in keys:
            if key not in budget_data:
                continue
            try:
                return float(budget_data.get(key, default))
            except Exception:
                continue
        return float(default)

    fx_rate = _num(
        "fx_rate_usd_to_cad",
        "usd_to_cad_rate",
        default=float(currency_policy_data.get("usd_to_cad_rate", 1.35) or 1.35),
    )
    if fx_rate <= 0.0:
        fx_rate = 1.35

    legacy_limit_usd = _num("weekly_limit_usd", "budget_usd", default=0.0)
    legacy_spent_usd = _num("weekly_spend_usd", "spent_usd", default=0.0)
    legacy_remaining_usd = _num("weekly_remaining_usd", "remaining_usd", default=max(0.0, legacy_limit_usd - legacy_spent_usd))

    policy_budget_cad = 0.0
    try:
        policy_budget_cad = float(budget_policy_data.get("weekly_budget_cad", 0.0) or 0.0)
    except Exception:
        policy_budget_cad = 0.0
    if policy_budget_cad < 0.0:
        policy_budget_cad = 0.0

    budget_limit_cad = _num(
        "weekly_budget_cad",
        "budget_cad",
        "weekly_limit_cad",
        default=(policy_budget_cad if policy_budget_cad > 0.0 else (legacy_limit_usd * fx_rate)),
    )
    spent_cad = _num("weekly_spend_cad", "spent_cad", default=legacy_spent_usd * fx_rate)
    remaining_cad = _num(
        "weekly_remaining_cad",
        "remaining_cad",
        default=(legacy_remaining_usd * fx_rate if policy_budget_cad <= 0.0 else max(0.0, budget_limit_cad - spent_cad)),
    )
    if budget_limit_cad > 0.0:
        remaining_cad = max(0.0, budget_limit_cad - spent_cad)

    spent_usd = _num("weekly_spend_usd", "spent_usd", default=(spent_cad / fx_rate if fx_rate > 0 else 0.0))
    remaining_usd = _num("weekly_remaining_usd", "remaining_usd", default=(remaining_cad / fx_rate if fx_rate > 0 else 0.0))

    locale = str(
        budget_data.get("locale")
        or currency_policy_data.get("locale")
        or "en-CA"
    )
    currency = str(
        budget_data.get("currency")
        or currency_policy_data.get("base_currency")
        or budget_policy_data.get("weekly_budget_currency")
        or "CAD"
    )

    return {
        "ok": True,
        "budget_state_path": str(BUDGET_STATE_PATH),
        "currency": currency,
        "locale": locale,
        "fx_rate_usd_to_cad": round(fx_rate, 8),
        "budget_limit_cad": round(budget_limit_cad, 6),
        "spent_cad": round(spent_cad, 6),
        "budget_remaining_cad": round(remaining_cad, 6),
        "spent_usd": round(spent_usd, 6),
        "budget_remaining_usd": round(remaining_usd, 6),
        "budget": budget_data,
    }


@app.get("/api/events")
def api_events(limit: int = Query(default=50, ge=1, le=1000)) -> dict[str, Any]:
    lines: list[dict[str, Any]] = []
    if EVENTS_PATH.exists():
        raw_lines = EVENTS_PATH.read_text(encoding="utf-8", errors="ignore").splitlines()
        for line in raw_lines[-limit:]:
            item = extract_json_object(line)
            if item:
                lines.append(item)
    return {"ok": True, "count": len(lines), "events": lines}


@app.get("/api/jobs/latest")
def api_jobs_latest(action: str = Query(default="", max_length=64)) -> dict[str, Any]:
    target_action = normalize_text(action).lower()
    rows = list_job_records(action=target_action)
    latest = rows[0] if rows else None
    return {
        "ok": True,
        "action": target_action or None,
        "job": latest,
        "count": len(rows),
    }


@app.get("/api/jobs/logs/{job_id}")
def api_jobs_logs(
    job_id: str,
    stream: str = Query(default="stdout", pattern="^(stdout|stderr)$"),
    tail: int = Query(default=2000, ge=200, le=20000),
) -> dict[str, Any]:
    row = read_job_record(job_id)
    if not row:
        return JSONResponse(status_code=404, content={"ok": False, "error": "job_not_found"})

    artifacts = row.get("artifacts", {}) if isinstance(row.get("artifacts"), dict) else {}
    key = "stdout_log" if stream == "stdout" else "stderr_log"
    log_path_raw = str(artifacts.get(key, "") or "")
    if not log_path_raw:
        return JSONResponse(status_code=404, content={"ok": False, "error": "job_log_not_found"})

    resolved_log = resolve_artifact_path_in_repo(log_path_raw)
    if not resolved_log or not resolved_log.exists():
        return JSONResponse(status_code=404, content={"ok": False, "error": "job_log_not_found"})

    raw = resolved_log.read_text(encoding="utf-8", errors="ignore")
    safe_text = redact_secrets(raw)
    truncated = len(safe_text) > tail
    content = safe_text[-tail:] if truncated else safe_text

    return {
        "ok": True,
        "job_id": job_id,
        "action": row.get("action"),
        "mode": row.get("mode"),
        "stream": stream,
        "log_path": to_repo_relative(resolved_log),
        "tail_chars": int(tail),
        "truncated": bool(truncated),
        "content": content,
    }


@app.get("/api/athena/tabs")
def api_athena_tabs() -> dict[str, Any]:
    components = load_component_registry()
    component_tabs = []
    for comp in components:
        component_tabs.append(
            {
                "component_id": str(comp.get("id", "")),
                "label": str(comp.get("label", comp.get("id", ""))),
                "type": str(comp.get("type", "generic")),
            }
        )
    return {
        "ok": True,
        "global_tabs": ["status", "approvals", "components", "uploads", "chat", "timeline"],
        "components": component_tabs,
    }


@app.get("/api/athena/status/{component_id}")
def api_athena_component_status(component_id: str) -> dict[str, Any]:
    component = find_component(component_id)
    if not component:
        return JSONResponse(status_code=404, content={"ok": False, "error": "component_not_found"})
    return {
        "ok": True,
        "component_id": str(component.get("id", "")),
        "label": str(component.get("label", "")),
        "status_sources": read_component_status_sources(component),
    }


@app.get("/api/athena/approvals/{component_id}")
def api_athena_component_approvals(component_id: str) -> dict[str, Any]:
    component = find_component(component_id)
    if not component:
        return JSONResponse(status_code=404, content={"ok": False, "error": "component_not_found"})
    rows = filter_approvals_for_component(component)
    return {
        "ok": True,
        "component_id": str(component.get("id", "")),
        "count": len(rows),
        "items": rows,
    }


@app.get("/api/athena/readme/{component_id}")
def api_athena_component_readme(component_id: str) -> dict[str, Any]:
    component = find_component(component_id)
    if not component:
        return JSONResponse(status_code=404, content={"ok": False, "error": "component_not_found"})
    readme = readme_for_component(component)
    if not readme.get("ok", False):
        return JSONResponse(status_code=404, content=readme)
    return readme


@app.post("/api/upload_text")
def api_upload_text(payload: UploadTextRequest) -> dict[str, Any]:
    saved = append_knowledge_record(
        source=payload.source,
        kind=payload.kind,
        text=payload.text,
        tags=payload.tags,
        priority=payload.priority,
    )
    append_event(
        kind="upload_text",
        status="saved",
        details={"source": payload.source, "kind": payload.kind},
    )
    return {"ok": True, **saved}


@app.post("/api/upload_zip")
def api_upload_zip(payload: UploadZipRequest) -> dict[str, Any]:
    ensure_parent(KNOWLEDGE_UPLOADS_DIR / ".keep")
    file_name = sanitize_file_name(payload.filename or "upload.zip")
    if not file_name.lower().endswith(".zip"):
        file_name = f"{file_name}.zip"

    zip_bytes = b""
    try:
        zip_bytes = base64.b64decode(payload.zip_base64.encode("utf-8"), validate=True)
    except Exception:
        return JSONResponse(status_code=400, content={"ok": False, "error": "invalid_zip_base64"})
    if len(zip_bytes) == 0:
        return JSONResponse(status_code=400, content={"ok": False, "error": "empty_zip"})
    if len(zip_bytes) > 25 * 1024 * 1024:
        return JSONResponse(status_code=413, content={"ok": False, "error": "zip_too_large"})

    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    target_zip = KNOWLEDGE_UPLOADS_DIR / f"{ts}_{file_name}"
    extract_dir = KNOWLEDGE_UPLOADS_DIR / f"{ts}_{file_name[:-4]}"
    try:
        ensure_parent(target_zip)
        target_zip.write_bytes(zip_bytes)
        with zipfile.ZipFile(target_zip, "r") as zf:
            zf.extractall(extract_dir)
    except Exception as exc:
        try:
            if target_zip.exists():
                target_zip.unlink(missing_ok=True)
        except Exception:
            pass
        return JSONResponse(status_code=400, content={"ok": False, "error": f"zip_extract_failed:{type(exc).__name__}"})

    meta = {
        "saved_at_utc": utc_now_iso(),
        "source": "athena_upload_zip",
        "zip_file": str(target_zip),
        "extract_dir": str(extract_dir),
        "tags": [str(x) for x in payload.tags if str(x).strip()],
    }
    write_json(extract_dir / "_upload_meta.json", meta)
    append_event(
        kind="upload_zip",
        status="saved",
        details={"zip_file": str(target_zip), "extract_dir": str(extract_dir)},
    )
    return {
        "ok": True,
        "zip_file": str(target_zip),
        "extract_dir": str(extract_dir),
    }


@app.post("/api/chat")
def api_chat(payload: ChatRequest) -> dict[str, Any]:
    teacher_policy = load_teacher_policy()
    query_text = normalize_text(payload.text or "")
    if not query_text:
        return JSONResponse(status_code=400, content={"ok": False, "error": "empty_query"})

    query_hash = query_memo_hash(query_text)
    if bool(teacher_policy.get("memoize_chat_by_query", True)):
        memo = lookup_chat_memo(query_hash)
        if isinstance(memo, dict):
            answer_text = normalize_text(memo.get("answer", "")) or "Memoized response available."
            confidence = float(memo.get("confidence", 1.0) or 1.0)
            sources = [str(x) for x in normalize_list(memo.get("sources"))]
            saved = append_knowledge_record(
                source="athena_chat",
                kind="chat",
                text=f"Q: {query_text}\nA: {answer_text}",
                tags=payload.tags,
                priority=payload.priority,
                event_kind="chat_append",
            )
            return {
                "ok": True,
                "answer": answer_text,
                "confidence": max(0.0, min(1.0, confidence)),
                "teacher_used": False,
                "memoized": True,
                "query_hash": query_hash,
                "sources": sources,
                **saved,
            }

    local = local_retrieve_answer(query_text)
    local_conf = float(local.get("confidence", 0.0) or 0.0)
    threshold = float(teacher_policy.get("confidence_threshold", 0.65) or 0.65)
    answer_text = str(local.get("answer", ""))
    sources = [str(x) for x in normalize_list(local.get("sources"))]
    teacher_used = False

    if local_conf < threshold:
        teacher_answer = call_teacher_for_chat(query_text, local_context=local, policy=teacher_policy)
        if teacher_answer:
            teacher_used = True
            answer_text = teacher_answer
            local_conf = max(local_conf, 0.75)

    if bool(teacher_policy.get("memoize_chat_by_query", True)):
        append_chat_memo(
            query_hash=query_hash,
            query_text=query_text,
            answer_text=answer_text,
            confidence=local_conf,
            teacher_used=teacher_used,
            sources=sources,
        )

    saved = append_knowledge_record(
        source="athena_chat",
        kind="chat",
        text=f"Q: {query_text}\nA: {answer_text}",
        tags=payload.tags,
        priority=payload.priority,
        event_kind="chat_append",
    )
    return {
        "ok": True,
        "answer": answer_text,
        "confidence": max(0.0, min(1.0, local_conf)),
        "teacher_used": teacher_used,
        "memoized": False,
        "query_hash": query_hash,
        "sources": sources,
        **saved,
    }


# --- API: control plane -------------------------------------------


def start_doctor_job(requested_by_device: str, mode_value: str) -> dict[str, Any]:
    mode_norm = normalize_text(mode_value).lower() or "full"
    if mode_norm not in {"quick", "full"}:
        return {"ok": False, "error": "invalid_mode", "allowed_modes": ["quick", "full"]}

    if mode_norm == "quick":
        script = BASE / "tools" / "Mason_Doctor_Quick.ps1"
        timeout = DOCTOR_QUICK_TIMEOUT_SECONDS
        artifacts = {
            "doctor_quick_report": "reports/mason2_doctor_quick_report.json",
            "doctor_report": "reports/mason2_doctor_quick_report.json",
        }
    else:
        script = BASE / "tools" / "Mason_Doctor.ps1"
        timeout = DOCTOR_FULL_TIMEOUT_SECONDS
        artifacts = {
            "doctor_report": "reports/mason2_doctor_report.json",
        }

    if not script.exists():
        return {"ok": False, "error": "doctor_script_missing", "mode": mode_norm}

    return spawn_script_job(
        action="run_doctor",
        requested_by_device=requested_by_device,
        script_path=script,
        args=["-RootPath", str(BASE)],
        timeout_seconds=timeout,
        artifacts=artifacts,
        mode=mode_norm,
        lifecycle_prefix="doctor_job",
    )


def start_e2e_verify_job(requested_by_device: str) -> dict[str, Any]:
    script = BASE / "tools" / "Mason_E2E_Verify.ps1"
    if not script.exists():
        return {"ok": False, "error": "e2e_script_missing"}
    return spawn_script_job(
        action="run_e2e_verify",
        requested_by_device=requested_by_device,
        script_path=script,
        args=["-RootPath", str(BASE)],
        timeout_seconds=E2E_VERIFY_TIMEOUT_SECONDS,
        artifacts={"e2e_report": "reports/mason2_e2e_verify.json"},
        mode="full",
        lifecycle_prefix="e2e_verify_job",
    )


@app.post("/api/control/freeze")
def api_control_freeze() -> dict[str, Any]:
    ensure_parent(KILLSWITCH_PATH)
    KILLSWITCH_PATH.write_text(utc_now_iso() + "\n", encoding="utf-8")
    append_event(kind="control", status="freeze", details={})
    return {"ok": True, "killswitch_enabled": True, "path": str(KILLSWITCH_PATH)}


@app.post("/api/control/unfreeze")
def api_control_unfreeze() -> dict[str, Any]:
    # Unfreeze is intentionally allowed even when killswitch exists.
    if KILLSWITCH_PATH.exists():
        KILLSWITCH_PATH.unlink(missing_ok=True)
    append_event(kind="control", status="unfreeze", details={})
    return {"ok": True, "killswitch_enabled": False, "path": str(KILLSWITCH_PATH)}


@app.post("/api/control/run_doctor")
def api_control_run_doctor(
    request: Request,
    mode: str = Query(default="quick", pattern="^(quick|full)$"),
) -> dict[str, Any]:
    allowed, reason = ensure_control_allowed("doctor")
    if not allowed:
        return JSONResponse(status_code=423, content={"ok": False, "error": reason})
    requested_by_device = str(getattr(getattr(request, "state", object()), "authenticated_device_id", "") or "unknown")
    mode_norm = normalize_text(mode).lower() or "quick"
    result = start_doctor_job(requested_by_device=requested_by_device, mode_value=mode_norm)
    if not result.get("ok") and result.get("error") == "invalid_mode":
        return JSONResponse(status_code=400, content=result)
    if result.get("ok"):
        append_event(
            kind="control_doctor",
            status="queued",
            details={
                "job_id": result.get("job_id"),
                "requested_by_device": requested_by_device,
                "mode": mode_norm,
            },
            correlation_id=str(result.get("job_id") or ""),
        )
    else:
        append_event(
            kind="control_doctor",
            status="failed",
            details={
                "error": str(result.get("error") or "unknown"),
                "job_id": result.get("job_id"),
                "mode": mode_norm,
            },
            correlation_id=str(result.get("job_id") or ""),
        )
    return result


@app.post("/api/control/doctor/run")
def api_control_doctor_run_legacy(request: Request) -> dict[str, Any]:
    return api_control_run_doctor(request=request, mode="full")


@app.post("/api/control/run_e2e_verify")
def api_control_run_e2e_verify(request: Request) -> dict[str, Any]:
    allowed, reason = ensure_control_allowed("doctor")
    if not allowed:
        return JSONResponse(status_code=423, content={"ok": False, "error": reason})
    requested_by_device = str(getattr(getattr(request, "state", object()), "authenticated_device_id", "") or "unknown")
    result = start_e2e_verify_job(requested_by_device=requested_by_device)
    if result.get("ok"):
        append_event(
            kind="control_e2e_verify",
            status="queued",
            details={
                "job_id": result.get("job_id"),
                "requested_by_device": requested_by_device,
            },
            correlation_id=str(result.get("job_id") or ""),
        )
    else:
        append_event(
            kind="control_e2e_verify",
            status="failed",
            details={
                "error": str(result.get("error") or "unknown"),
                "job_id": result.get("job_id"),
                "requested_by_device": requested_by_device,
            },
            correlation_id=str(result.get("job_id") or ""),
        )
    return result


@app.post("/api/control/ingest/run")
def api_control_ingest_run() -> dict[str, Any]:
    allowed, reason = ensure_control_allowed("ingest")
    if not allowed:
        return JSONResponse(status_code=423, content={"ok": False, "error": reason})
    script = BASE / "tools" / "ingest" / "Mason_IngestDrop_Once.ps1"
    result = execute_control_script(script, ["-RootPath", str(BASE)], timeout_sec=240)
    append_event(kind="control_ingest", status="completed" if result.get("ok") else "failed", details={"result": result})
    return result


@app.post("/api/control/mirror/run")
def api_control_mirror_run(payload: MirrorRunRequest) -> dict[str, Any]:
    allowed, reason = ensure_control_allowed("mirror")
    if not allowed:
        return JSONResponse(status_code=423, content={"ok": False, "error": reason})
    script = BASE / "tools" / "sync" / "Mason_Mirror_Update.ps1"
    reason_value = normalize_text(payload.reason or "manual").lower() or "manual"
    result = execute_control_script(
        script,
        ["-RootPath", str(BASE), "-Reason", reason_value],
        timeout_sec=300,
    )
    append_event(
        kind="control_mirror",
        status="completed" if result.get("ok") else "failed",
        details={"reason": reason_value},
    )
    return result


@app.post("/api/control/stack/start")
def api_control_stack_start() -> dict[str, Any]:
    allowed, reason = ensure_control_allowed("stack_start")
    if not allowed:
        return JSONResponse(status_code=423, content={"ok": False, "error": reason})
    script = BASE / "Start_Mason2.ps1"
    result = execute_control_script(script, ["-FullStack"], timeout_sec=300)
    append_event(kind="control_stack_start", status="completed" if result.get("ok") else "failed", details={"result": result})
    return result


@app.post("/api/control/stack/stop")
def api_control_stack_stop() -> dict[str, Any]:
    allowed, reason = ensure_control_allowed("stack_stop")
    if not allowed:
        return JSONResponse(status_code=423, content={"ok": False, "error": reason})
    script = BASE / "Stop_Stack.ps1"
    result = execute_control_script(script, [], timeout_sec=180)
    append_event(kind="control_stack_stop", status="completed" if result.get("ok") else "failed", details={"result": result})
    return result


@app.post("/api/control/onyx/restart")
def api_control_onyx_restart() -> dict[str, Any]:
    allowed, reason = ensure_control_allowed("onyx_restart")
    if not allowed:
        return JSONResponse(status_code=423, content={"ok": False, "error": reason})

    onyx_root = BASE / "Component - Onyx App" / "onyx_business_manager"
    script = onyx_root / "Restart-Onyx5353.ps1"
    result = execute_control_script(script, [], timeout_sec=180)
    append_event(kind="control_onyx_restart", status="completed" if result.get("ok") else "failed", details={"result": result})
    return result


@app.post("/api/control/onyx/smoketest")
def api_control_onyx_smoketest() -> dict[str, Any]:
    allowed, reason = ensure_control_allowed("onyx_smoketest")
    if not allowed:
        return JSONResponse(status_code=423, content={"ok": False, "error": reason})
    ports = load_ports_contract()
    onyx_port = int((ports.get("ports") or {}).get("onyx", 5353))
    url = f"http://127.0.0.1:{onyx_port}/main.dart.js"
    ok = False
    status_code = None
    error = ""
    try:
        import urllib.request

        req = urllib.request.Request(url, method="GET")
        with urllib.request.urlopen(req, timeout=8) as response:
            status_code = int(response.getcode())
            ok = status_code == 200
    except Exception as exc:
        error = f"{type(exc).__name__}"
    result = {
        "ok": ok,
        "url": url,
        "status_code": status_code,
        "error": error or None,
    }
    append_event(kind="control_onyx_smoketest", status="completed" if ok else "failed", details=result)
    return result


# --- API: ingest ---------------------------------------------------


@app.post("/api/ingest_chunk")
def ingest_chunk(payload: IngestChunkRequest) -> dict[str, Any]:
    teacher_policy = load_teacher_policy()
    max_chars = max(1, int(payload.max_chars or 6000))
    content = (payload.content or "")[:max_chars]
    redacted = redact_secrets(content)
    normalized = normalize_text_for_hash(redacted)
    content_sha256 = sha256_hex(normalized)
    run_id = f"ingest-{uuid4().hex[:12]}"

    if bool(teacher_policy.get("memoize_ingest_by_sha256", True)):
        memo = read_store_record_by_sha(content_sha256)
        if isinstance(memo, dict):
            return {
                "ok": True,
                "error": None,
                "run_id": run_id,
                "label": payload.label,
                "summary": normalize_text(memo.get("summary", "")),
                "decisions": extract_string_list(memo.get("decisions"), max_items=8),
                "rules": extract_string_list(memo.get("rules"), max_items=8),
                "done_items": extract_string_list(memo.get("done_items"), max_items=10),
                "open_items": extract_string_list(memo.get("open_items"), max_items=12),
                "tags": extract_string_list(memo.get("tags"), max_items=12),
                "usage": memo.get("usage"),
                "model": str(memo.get("model") or os.getenv("MASON_MODEL", "gpt-5.1")),
                "memoized": True,
                "teacher_used": False,
                "content_sha256": content_sha256,
            }

    api_key = load_openai_api_key()
    if not api_key:
        return JSONResponse(
            status_code=500,
            content={"ok": False, "error": "missing_api_key"},
        )

    contract = None
    usage = None
    teacher_used = False
    try:
        contract, usage = call_openai_ingest_contract(
            redacted_text=redacted,
            label=payload.label,
            max_chars=max_chars,
        )
        teacher_used = bool(contract)
    except Exception:
        contract = None
        usage = None

    if not contract:
        contract = heuristic_ingest_contract(redacted)
        teacher_used = False

    record_payload = {
        "content_sha256": content_sha256,
        "created_at_utc": utc_now_iso(),
        "label": payload.label,
        "summary": contract["summary"],
        "decisions": contract["decisions"],
        "rules": contract["rules"],
        "done_items": contract["done_items"],
        "open_items": contract["open_items"],
        "tags": contract["tags"],
        "usage": usage,
        "model": os.getenv("MASON_MODEL", "gpt-5.1"),
        "teacher_used": teacher_used,
    }
    if bool(teacher_policy.get("memoize_ingest_by_sha256", True)):
        write_store_record(content_sha256, record_payload)

    return {
        "ok": True,
        "error": None,
        "run_id": run_id,
        "label": payload.label,
        "summary": contract["summary"],
        "decisions": contract["decisions"],
        "rules": contract["rules"],
        "done_items": contract["done_items"],
        "open_items": contract["open_items"],
        "tags": contract["tags"],
        "usage": usage,
        "model": os.getenv("MASON_MODEL", "gpt-5.1"),
        "memoized": False,
        "teacher_used": teacher_used,
        "content_sha256": content_sha256,
    }


@app.get("/api/ingest_index")
def ingest_index(
    run_id: str | None = Query(default=None),
    latest: bool = Query(default=True),
) -> dict[str, Any]:
    if not isinstance(run_id, str):
        run_id = None
    if not isinstance(latest, bool):
        latest = True

    files = list_ingest_indexes()
    if not files:
        return {"ok": False, "reason": "no_ingest_index_files_found"}

    if run_id:
        preferred = REPORTS / f"ingest_index_{run_id}.json"
        candidate = preferred if preferred.exists() else None
        if candidate is None:
            for file in files:
                if run_id in file.name:
                    candidate = file
                    break
        if candidate is None:
            return {"ok": False, "reason": "run_id_not_found", "run_id": run_id}
        return {
            "ok": True,
            "run_id": run_id,
            "path": str(candidate),
            "index": read_json(candidate, default={}),
        }

    if latest:
        candidate = files[0]
        data = read_json(candidate, default={})
        inferred_run_id = data.get("run_id") if isinstance(data, dict) else None
        return {
            "ok": True,
            "run_id": inferred_run_id,
            "path": str(candidate),
            "index": data,
        }

    entries = []
    for file in files[:25]:
        data = read_json(file, default={})
        run_value = data.get("run_id") if isinstance(data, dict) else None
        entries.append(
            {
                "run_id": run_value,
                "path": str(file),
                "last_write_utc": datetime.fromtimestamp(file.stat().st_mtime, tz=timezone.utc)
                .isoformat()
                .replace("+00:00", "Z"),
            }
        )

    return {"ok": True, "indexes": entries}


# --- API: tool platform -------------------------------------------


@app.get("/api/tools/catalog")
def tools_catalog() -> dict[str, Any]:
    data = read_json(TOOL_REGISTRY_PATH, default={"tools": []})
    tools_out: list[dict[str, Any]] = []
    for tool in normalize_list(data.get("tools") if isinstance(data, dict) else []):
        if not isinstance(tool, dict):
            continue
        tools_out.append(sanitize_tool_catalog_entry(tool))

    return {
        "ok": True,
        "count": len(tools_out),
        "tools": tools_out,
    }


@app.get("/api/tiers")
def get_tiers() -> dict[str, Any]:
    data = read_json(TIERS_PATH, default={"tiers": [], "default_tier": "starter"})
    tiers = normalize_list(data.get("tiers") if isinstance(data, dict) else [])
    return {
        "ok": True,
        "default_tier": data.get("default_tier", "starter") if isinstance(data, dict) else "starter",
        "tiers": [tier for tier in tiers if isinstance(tier, dict)],
    }


@app.get("/api/addons")
def get_addons() -> dict[str, Any]:
    data = read_json(ADDONS_PATH, default={"addons": []})
    addons = normalize_list(data.get("addons") if isinstance(data, dict) else [])
    return {
        "ok": True,
        "addons": [addon for addon in addons if isinstance(addon, dict)],
    }


@app.post("/api/tools/recommend")
def tools_recommend(payload: ToolRecommendRequest) -> dict[str, Any]:
    answers_json = redact_secrets(json.dumps(payload.answers or {}, ensure_ascii=False))
    result = run_powershell_json(
        TOOL_RECOMMEND_SCRIPT,
        ["-RootPath", str(BASE), "-AnswersJson", answers_json],
        timeout_sec=120,
    )
    if not result.get("ok", False):
        return JSONResponse(
            status_code=500,
            content={"ok": False, "error": str(result.get("error", "recommend_failed"))},
        )
    return result


@app.post("/api/tools/run")
def tools_run(payload: ToolRunRequest) -> dict[str, Any]:
    tool_id = (payload.tool_id or "").strip()
    if not re.fullmatch(r"[A-Za-z0-9_.\-]+", tool_id):
        return JSONResponse(status_code=400, content={"ok": False, "error": "invalid_tool_id"})

    client_name = redact_secrets((payload.client_name or "client").strip())
    workspace_id = (payload.workspace_id or "").strip()
    input_json = redact_secrets(json.dumps(payload.input or {}, ensure_ascii=False))

    args = [
        "-RootPath",
        str(BASE),
        "-ToolId",
        tool_id,
        "-ClientName",
        client_name or "client",
        "-InputJson",
        input_json,
    ]
    if workspace_id:
        args += ["-WorkspaceId", workspace_id]

    result = run_powershell_json(TOOL_RUNNER_SCRIPT, args, timeout_sec=180)
    if not result.get("ok", False):
        return JSONResponse(
            status_code=500,
            content={"ok": False, "error": str(result.get("error", "tool_run_failed"))},
        )
    return result


@app.get("/api/tools/runs/latest")
def tools_runs_latest(limit: int = Query(default=10, ge=1, le=50)) -> dict[str, Any]:
    if not TOOL_RUNS_DIR.exists():
        return {"ok": True, "runs": []}

    run_dirs = [p for p in TOOL_RUNS_DIR.iterdir() if p.is_dir()]
    run_dirs.sort(key=lambda p: p.stat().st_mtime, reverse=True)

    runs: list[dict[str, Any]] = []
    for run_dir in run_dirs[:limit]:
        tool_run = read_json(run_dir / "tool_run.json", default={})
        report = read_json(run_dir / "report.json", default={})
        tasks = read_json(run_dir / "tasks.json", default=[])
        task_count = len(tasks) if isinstance(tasks, list) else 0

        runs.append(
            {
                "run_id": str(tool_run.get("run_id", run_dir.name)) if isinstance(tool_run, dict) else run_dir.name,
                "tool_id": str(tool_run.get("tool_id", "")) if isinstance(tool_run, dict) else "",
                "tool_version": str(tool_run.get("tool_version", "")) if isinstance(tool_run, dict) else "",
                "workspace_id": str(tool_run.get("workspace_id", "")) if isinstance(tool_run, dict) else "",
                "generated_at_utc": str(report.get("generated_at_utc", "")) if isinstance(report, dict) else "",
                "summary": str(report.get("summary", "")) if isinstance(report, dict) else "",
                "task_count": task_count,
                "path": str(run_dir),
            }
        )

    return {"ok": True, "runs": runs}


# --- API: knowledge append ----------------------------------------


@app.post("/api/knowledge/append")
def knowledge_append(payload: KnowledgeAppendRequest) -> dict[str, Any]:
    saved = append_knowledge_record(
        source=payload.source or "athena",
        kind=payload.kind or "note",
        text=payload.text or "",
        tags=[str(tag) for tag in (payload.tags or []) if str(tag).strip()],
        priority=int(payload.priority),
        event_kind="knowledge_append",
    )
    return {"ok": True, **saved}


@app.get("/", include_in_schema=False)
def root_redirect() -> RedirectResponse:
    return RedirectResponse(url="/athena/")


# Keep API routes reachable by mounting static last.
if ATHENA_STATIC_DIR.exists():
    app.mount("/athena", StaticFiles(directory=str(ATHENA_STATIC_DIR), html=True), name="athena_static")

if WEB_DIR.exists():
    app.mount("/legacy", StaticFiles(directory=str(WEB_DIR), html=True), name="legacy_static")
elif (LEGACY_WEB_DIR / "index.html").exists():
    app.mount("/legacy", StaticFiles(directory=str(LEGACY_WEB_DIR), html=True), name="legacy_static")


# --- Entrypoint ----------------------------------------------------

if __name__ == "__main__":
    import uvicorn

    uvicorn.run("server:app", host="127.0.0.1", port=8000, reload=False)
