from __future__ import annotations

from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any
import ctypes
import base64
import hashlib
import html as html_lib
import hmac
import ipaddress
import json
import os
import re
import shutil
import secrets
import subprocess
import threading
import time
import urllib.error
import urllib.request
import zipfile
from uuid import uuid4

from fastapi import FastAPI, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, JSONResponse, RedirectResponse
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
COMPONENT_DOCS_REGISTRY_PATH = CONFIG_DIR / "component_docs_registry.json"
BRAND_EXPOSURE_POLICY_PATH = CONFIG_DIR / "brand_exposure_policy.json"
KEEPALIVE_POLICY_PATH = CONFIG_DIR / "keepalive_policy.json"
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
START_RUN_LAST_PATH = REPORTS / "start" / "start_run_last.json"
LAST_FAILURE_PATH = REPORTS / "start" / "last_failure.json"
MIRROR_UPDATE_LAST_PATH = REPORTS / "mirror_update_last.json"
VERIFY_LAST_PATH = REPORTS / "verify_last.json"
VERIFY_LAST_STDOUT_PATH = REPORTS / "verify_last_stdout.log"
VERIFY_LAST_STDERR_PATH = REPORTS / "verify_last_stderr.log"
ONYX_STATE_DIR = STATE_ROOT / "onyx"
ONYX_TENANTS_DIR = ONYX_STATE_DIR / "tenants"
ONYX_TENANT_WORKSPACE_PATH = ONYX_STATE_DIR / "tenant_workspace.json"
ONYX_PLAN_STATE_PATH = ONYX_STATE_DIR / "plan_state.json"
ONYX_RECOMMENDATIONS_DIR = ONYX_STATE_DIR / "recommendations"
ONYX_BILLING_DIR = ONYX_STATE_DIR / "billing"
BILLING_PROVIDER_CONFIG_PATH = CONFIG_DIR / "billing_provider.json"
BILLING_SUMMARY_PATH = REPORTS / "billing_summary.json"
BILLING_SESSIONS_DIR = REPORTS / "billing"
IMPROVEMENT_QUEUE_PATH = STATE / "improvement_queue.json"
IMPROVEMENT_QUEUE_REPORT_PATH = REPORTS / "queue" / "improvement_queue_last.json"
BEHAVIOR_TRUST_PATH = STATE / "behavior_trust.json"
BEHAVIOR_TRUST_REPORT_PATH = REPORTS / "queue" / "behavior_trust_last.json"
TRUST_INDEX_PATH = STATE / "trust_index.json"
TOOL_FACTORY_PATH = STATE / "tool_factory.json"
TOOL_FACTORY_REPORT_PATH = REPORTS / "queue" / "tool_factory_last.json"
RBAC_POLICY_PATH = CONFIG_DIR / "rbac_policy.json"
DATA_GOVERNANCE_POLICY_PATH = CONFIG_DIR / "data_governance_policy.json"
DATA_GOVERNANCE_STATE_PATH = STATE / "data_governance_requests.json"
TENANT_SAFETY_REPORT_PATH = REPORTS / "tenant_safety_report.json"
SECURITY_POSTURE_PATH = REPORTS / "security_posture.json"
PLATFORM_AUDIT_LOG_PATH = REPORTS / "platform_audit.jsonl"
SYSTEM_VALIDATION_LAST_PATH = REPORTS / "system_validation_last.json"
LIVE_DOCS_INDEX_PATH = REPORTS / "live_docs_index.json"
LIVE_DOCS_SUMMARY_PATH = REPORTS / "live_docs_summary.json"
LIVE_DOCS_DIR = REPORTS / "docs"
BRAND_EXPOSURE_SUMMARY_PATH = REPORTS / "brand_exposure_isolation_last.json"
BRAND_LEAK_AUDIT_PATH = REPORTS / "brand_leak_audit_last.json"
PUBLIC_VOCABULARY_POLICY_LAST_PATH = REPORTS / "public_vocabulary_policy_last.json"
KEEPALIVE_LAST_PATH = REPORTS / "keepalive_last.json"
SELF_HEAL_LAST_PATH = REPORTS / "self_heal_last.json"
DAILY_REPORT_LAST_PATH = REPORTS / "daily_report_last.json"
ESCALATION_QUEUE_LAST_PATH = REPORTS / "escalation_queue_last.json"
SELF_IMPROVEMENT_POLICY_PATH = STATE / "self_improvement_policy.json"
SELF_IMPROVEMENT_GOVERNOR_REPORT_PATH = REPORTS / "self_improvement_governor_last.json"
TEACHER_CALL_BUDGET_REPORT_PATH = REPORTS / "teacher_call_budget_last.json"
TEACHER_DECISION_LOG_REPORT_PATH = REPORTS / "teacher_decision_log_last.json"
HOST_HEALTH_LAST_PATH = REPORTS / "host_health_last.json"
ENVIRONMENT_PROFILE_LAST_PATH = REPORTS / "environment_profile_last.json"
ENVIRONMENT_DRIFT_LAST_PATH = REPORTS / "environment_drift_last.json"
RUNTIME_POSTURE_LAST_PATH = REPORTS / "runtime_posture_last.json"
SYSTEM_TRUTH_SPINE_LAST_PATH = REPORTS / "system_truth_spine_last.json"
SYSTEM_METRICS_SPINE_LAST_PATH = REPORTS / "system_metrics_spine_last.json"
SYSTEM_TRUTH_SUMMARY_LAST_PATH = REPORTS / "system_truth_summary_last.json"
SYSTEM_TRUTH_REGISTRY_PATH = STATE / "system_truth_registry.json"
REGRESSION_GUARD_LAST_PATH = REPORTS / "regression_guard_last.json"
ROLLBACK_PLAN_LAST_PATH = REPORTS / "rollback_plan_last.json"
PROMOTION_GATE_LAST_PATH = REPORTS / "promotion_gate_last.json"
REGRESSION_BASELINES_PATH = STATE / "regression_baselines.json"
REGRESSION_GUARD_POLICY_PATH = CONFIG_DIR / "regression_guard_policy.json"
PLAYBOOK_LIBRARY_LAST_PATH = REPORTS / "playbook_library_last.json"
SUPPORT_BRAIN_LAST_PATH = REPORTS / "support_brain_last.json"
INCIDENT_EXPLANATIONS_LAST_PATH = REPORTS / "incident_explanations_last.json"
PLAYBOOK_REGISTRY_PATH = STATE / "playbook_registry.json"
PLAYBOOK_SUPPORT_POLICY_PATH = CONFIG_DIR / "playbook_support_policy.json"
WEDGE_PACK_FRAMEWORK_LAST_PATH = REPORTS / "wedge_pack_framework_last.json"
SEGMENT_OVERLAY_LAST_PATH = REPORTS / "segment_overlay_last.json"
WORKFLOW_PACK_LAST_PATH = REPORTS / "workflow_pack_last.json"
WEDGE_PACK_REGISTRY_PATH = STATE / "wedge_pack_registry.json"
WEDGE_PACK_POLICY_PATH = CONFIG_DIR / "wedge_pack_policy.json"
BUSINESS_OUTCOMES_LAST_PATH = REPORTS / "business_outcomes_last.json"
TOOL_USEFULNESS_LAST_PATH = REPORTS / "tool_usefulness_last.json"
RECOMMENDATION_EFFECTIVENESS_LAST_PATH = REPORTS / "recommendation_effectiveness_last.json"
TENANT_ENGAGEMENT_LAST_PATH = REPORTS / "tenant_engagement_last.json"
BUSINESS_OUTCOME_REGISTRY_PATH = STATE / "business_outcome_registry.json"
BUSINESS_OUTCOME_POLICY_PATH = CONFIG_DIR / "business_outcome_policy.json"
RELEASE_MANAGEMENT_LAST_PATH = REPORTS / "release_management_last.json"
RELEASE_CANDIDATE_LAST_PATH = REPORTS / "release_candidate_last.json"
RELEASE_NOTES_LAST_PATH = REPORTS / "release_notes_last.json"
RELEASE_ROLLOUT_LAST_PATH = REPORTS / "release_rollout_last.json"
RELEASE_REGISTRY_PATH = STATE / "release_registry.json"
RELEASE_MANAGEMENT_POLICY_PATH = CONFIG_DIR / "release_management_policy.json"
REVENUE_OPTIMIZATION_LAST_PATH = REPORTS / "revenue_optimization_last.json"
PLAN_FIT_ANALYSIS_LAST_PATH = REPORTS / "plan_fit_analysis_last.json"
UPGRADE_SUGGESTIONS_LAST_PATH = REPORTS / "upgrade_suggestions_last.json"
CHURN_RESCUE_LAST_PATH = REPORTS / "churn_rescue_last.json"
REVENUE_OPTIMIZATION_REGISTRY_PATH = STATE / "revenue_optimization_registry.json"
REVENUE_OPTIMIZATION_POLICY_PATH = CONFIG_DIR / "revenue_optimization_policy.json"
MODEL_COST_GOVERNANCE_LAST_PATH = REPORTS / "model_cost_governance_last.json"
TASK_CLASSIFICATION_LAST_PATH = REPORTS / "task_classification_last.json"
TEACHER_USEFULNESS_LAST_PATH = REPORTS / "teacher_usefulness_last.json"
COST_EFFECTIVENESS_LAST_PATH = REPORTS / "cost_effectiveness_last.json"
MODEL_COST_REGISTRY_PATH = STATE / "model_cost_registry.json"
MODEL_COST_GOVERNANCE_POLICY_PATH = CONFIG_DIR / "model_cost_governance_policy.json"
UX_SIMPLICITY_LAST_PATH = REPORTS / "ux_simplicity_last.json"
ATHENA_FOUNDER_UX_LAST_PATH = REPORTS / "athena_founder_ux_last.json"
ONYX_CUSTOMER_UX_LAST_PATH = REPORTS / "onyx_customer_ux_last.json"
APPROVAL_SURFACE_LAST_PATH = REPORTS / "approval_surface_last.json"
UX_SIMPLICITY_REGISTRY_PATH = STATE / "ux_simplicity_registry.json"
UX_SIMPLICITY_POLICY_PATH = CONFIG_DIR / "ux_simplicity_policy.json"
KNOWLEDGE_QUALITY_LAST_PATH = REPORTS / "knowledge_quality_last.json"
KNOWLEDGE_CARDS_LAST_PATH = REPORTS / "knowledge_cards_last.json"
KNOWLEDGE_REUSE_LAST_PATH = REPORTS / "knowledge_reuse_last.json"
ANTI_REPEAT_MEMORY_LAST_PATH = REPORTS / "anti_repeat_memory_last.json"
OUTCOME_LEARNING_LAST_PATH = REPORTS / "outcome_learning_last.json"
KNOWLEDGE_CARDS_STATE_PATH = STATE / "knowledge_cards.json"
KNOWLEDGE_FAILURES_STATE_PATH = STATE / "knowledge_failures.json"
KNOWLEDGE_OUTCOMES_STATE_PATH = STATE / "knowledge_outcomes.json"
KNOWLEDGE_REUSE_HISTORY_PATH = STATE / "knowledge_reuse_history.json"
KNOWLEDGE_QUALITY_POLICY_PATH = CONFIG_DIR / "knowledge_quality_policy.json"
WHOLE_FOLDER_VERIFICATION_LAST_PATH = REPORTS / "whole_folder_verification_last.json"
WHOLE_FOLDER_INVENTORY_LAST_PATH = REPORTS / "whole_folder_inventory_last.json"
WHOLE_FOLDER_REGISTRATION_GAPS_PATH = REPORTS / "whole_folder_registration_gaps.json"
WHOLE_FOLDER_BROKEN_PATHS_LAST_PATH = REPORTS / "whole_folder_broken_paths_last.json"
WHOLE_FOLDER_GOLDEN_PATHS_LAST_PATH = REPORTS / "whole_folder_golden_paths_last.json"
WHOLE_FOLDER_FAULT_TESTS_LAST_PATH = REPORTS / "whole_folder_fault_tests_last.json"
WHOLE_FOLDER_MIGRATION_CHECKS_LAST_PATH = REPORTS / "whole_folder_migration_checks_last.json"
WHOLE_FOLDER_USABILITY_CHECKS_LAST_PATH = REPORTS / "whole_folder_usability_checks_last.json"
WHOLE_FOLDER_CLEANUP_QUEUE_PATH = REPORTS / "whole_folder_cleanup_queue.json"
WHOLE_FOLDER_VERIFICATION_SUMMARY_MD_PATH = REPORTS / "whole_folder_verification_summary.md"
WHOLE_FOLDER_VERIFICATION_POLICY_PATH = CONFIG_DIR / "whole_folder_verification_policy.json"
REPAIR_WAVE_01_LAST_PATH = REPORTS / "repair_wave_01_last.json"
REPAIR_ONBOARDING_LAST_PATH = REPORTS / "repair_onboarding_last.json"
REPAIR_BILLING_ENTITLEMENTS_LAST_PATH = REPORTS / "repair_billing_entitlements_last.json"
REPAIR_HALFWIRED_LAST_PATH = REPORTS / "repair_halfwired_last.json"
REPAIR_REGISTRATION_GAPS_LAST_PATH = REPORTS / "repair_registration_gaps_last.json"
REPAIR_SCHEDULER_OVERSIGHT_LAST_PATH = REPORTS / "repair_scheduler_oversight_last.json"
REPAIR_INTERNAL_VISIBILITY_LAST_PATH = REPORTS / "repair_internal_visibility_last.json"
REPAIR_MIRROR_HARDENING_LAST_PATH = REPORTS / "repair_mirror_hardening_last.json"
REPAIR_BROKEN_PATHS_FIXED_LAST_PATH = REPORTS / "repair_broken_paths_fixed_last.json"
REPAIR_UNFIXED_QUEUE_LAST_PATH = REPORTS / "repair_unfixed_queue_last.json"
REPAIR_WAVE_02_LAST_PATH = REPORTS / "repair_wave_02_last.json"
INTERNAL_SCHEDULER_LAST_PATH = REPORTS / "internal_scheduler_last.json"
LEGACY_TASK_INVENTORY_LAST_PATH = REPORTS / "legacy_task_inventory_last.json"
LEGACY_TASK_MIGRATION_LAST_PATH = REPORTS / "legacy_task_migration_last.json"
POPUP_SUPPRESSION_LAST_PATH = REPORTS / "popup_suppression_last.json"
VALIDATOR_COVERAGE_REPAIR_LAST_PATH = REPORTS / "validator_coverage_repair_last.json"
BROKEN_PATH_CLUSTER_REPAIR_LAST_PATH = REPORTS / "broken_path_cluster_repair_last.json"
REMOTE_PUSH_REPAIR_LAST_PATH = REPORTS / "remote_push_repair_last.json"
REPAIR_WAVE_02_UNFIXED_QUEUE_LAST_PATH = REPORTS / "repair_wave_02_unfixed_queue_last.json"
MIRROR_COVERAGE_LAST_PATH = REPORTS / "mirror_coverage_last.json"
MIRROR_OMISSION_LAST_PATH = REPORTS / "mirror_omission_last.json"
MIRROR_SAFE_INDEX_PATH = REPORTS / "mirror_safe_index.md"
ATHENA_WIDGET_STATUS_PATH = REPORTS / "athena_widget_status.json"
ONYX_STACK_HEALTH_PATH = REPORTS / "onyx_stack_health.json"
REPAIR_WAVE_01_POLICY_PATH = CONFIG_DIR / "repair_wave_01_policy.json"
REPAIR_WAVE_02_POLICY_PATH = CONFIG_DIR / "repair_wave_02_policy.json"
INTERNAL_SCHEDULER_POLICY_PATH = CONFIG_DIR / "internal_scheduler_policy.json"
LEGACY_TASK_MIGRATION_POLICY_PATH = CONFIG_DIR / "legacy_task_migration_policy.json"

PENDING_PATCHES = STATE / "pending_patch_runs.json"
PENDING_PATCHES_QUARANTINE = STATE / "pending_patch_runs_quarantine.json"
APPROVALS_HISTORY_PATH = STATE / "approvals_history.json"
SUGGESTIONS = STATE / "mason_teacher_suggestions.json"

DEVICE_RATE_STATE: dict[str, list[float]] = {}
NONCE_STATE: dict[str, float] = {}
PAIRING_SESSIONS: dict[str, dict[str, Any]] = {}
TEACHER_CALL_COUNT = 0
VERIFY_RUN_LOCK = threading.Lock()
VERIFY_STATE_LOCK = threading.Lock()
VERIFY_RUNTIME_STATE: dict[str, Any] = {
    "running": False,
    "started_at_utc": "",
    "requested_by_device": "",
    "command_run": "",
}


def env_int(name: str, default: int) -> int:
    try:
        value = int(str(os.getenv(name, "")).strip())
        return value if value > 0 else default
    except Exception:
        return default


DOCTOR_FULL_TIMEOUT_SECONDS = env_int("MASON_DOCTOR_FULL_TIMEOUT_SECONDS", 600)
DOCTOR_QUICK_TIMEOUT_SECONDS = env_int("MASON_DOCTOR_QUICK_TIMEOUT_SECONDS", 90)
E2E_VERIFY_TIMEOUT_SECONDS = env_int("MASON_E2E_TIMEOUT_SECONDS", 240)


def build_verify_command_string() -> str:
    return f'powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\\tools\\Mason_E2E_Verify.ps1 -RootPath "{str(BASE)}"'


def get_verify_runtime_state() -> dict[str, Any]:
    with VERIFY_STATE_LOCK:
        return dict(VERIFY_RUNTIME_STATE)


def set_verify_runtime_state(*, running: bool, requested_by_device: str = "", command_run: str = "") -> None:
    with VERIFY_STATE_LOCK:
        VERIFY_RUNTIME_STATE.update(
            {
                "running": bool(running),
                "started_at_utc": utc_now_iso() if running else "",
                "requested_by_device": requested_by_device if running else "",
                "command_run": command_run if running else "",
            }
        )

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
    tenant_id: str | None = Field(default=None)
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


class BillingCheckoutRequest(BaseModel):
    tenant_id: str = Field(min_length=3, max_length=64)
    plan_id: str = Field(min_length=3, max_length=80)
    success_url: str = Field(default="")
    cancel_url: str = Field(default="")


class BillingPortalRequest(BaseModel):
    tenant_id: str = Field(min_length=3, max_length=64)


class BillingWebhookRequest(BaseModel):
    provider: str = Field(default="stripe_stub")
    event_type: str = Field(min_length=3, max_length=64)
    tenant_id: str = Field(default="")
    plan_id: str = Field(default="")
    customer_id: str = Field(default="")
    subscription_id: str = Field(default="")
    session_id: str = Field(default="")
    status: str = Field(default="")
    renewal_date: str | None = Field(default=None)
    last_payment_at: str | None = Field(default=None)
    addon_ids: list[str] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(default_factory=dict)


class OnyxBusinessContextRequest(BaseModel):
    workspace: dict[str, Any] = Field(default_factory=dict)


class OnyxRecommendationRefreshRequest(BaseModel):
    tenant_id: str = Field(min_length=3, max_length=64)


class OnyxRecommendationStatusRequest(BaseModel):
    tenant_id: str = Field(min_length=3, max_length=64)
    recommendation_id: str = Field(min_length=8, max_length=96)
    status: str = Field(min_length=3, max_length=24)


class ImprovementRefreshRequest(BaseModel):
    sources: list[str] = Field(default_factory=list)


class ImprovementCreateRequest(BaseModel):
    target_type: str = Field(min_length=3, max_length=32)
    target_id: str = Field(default="")
    title: str = Field(min_length=3, max_length=160)
    description: str = Field(default="")
    source: str = Field(default="manual")
    reason: str = Field(default="")
    evidence: list[dict[str, Any]] = Field(default_factory=list)
    expected_outcome: str = Field(default="")
    priority: int = Field(default=50, ge=0, le=100)
    risk_level: str = Field(default="R1")
    approval_required: bool = Field(default=False)
    linked_behavior_id: str | None = Field(default=None)
    linked_tenant_id: str | None = Field(default=None)


class ImprovementStatusRequest(BaseModel):
    improvement_id: str = Field(min_length=8, max_length=96)
    status: str = Field(min_length=3, max_length=24)
    note: str = Field(default="")


class ApprovalDecisionRequest(BaseModel):
    approval_id: str = Field(min_length=3, max_length=160)
    decision: str = Field(min_length=6, max_length=16)
    owner_reason: str = Field(default="")


class BehaviorCreateRequest(BaseModel):
    behavior_id: str | None = Field(default=None, min_length=8, max_length=96)
    behavior_name: str = Field(min_length=3, max_length=120)
    domain: str = Field(min_length=3, max_length=32)
    description: str = Field(default="")
    risk_level: str = Field(default="low")
    required_evidence: list[str] = Field(default_factory=list)
    trust_state: str = Field(default="discovered")
    approval_required: bool | None = Field(default=None)
    last_tested_at: str | None = Field(default=None)
    promotion_reason: str = Field(default="")
    rollback_condition: str = Field(default="")


class BehaviorStateRequest(BaseModel):
    behavior_id: str = Field(min_length=8, max_length=96)
    trust_state: str = Field(min_length=3, max_length=24)
    promotion_reason: str = Field(default="")
    note: str = Field(default="")
    last_tested_at: str | None = Field(default=None)


class ToolFactoryRefreshRequest(BaseModel):
    sources: list[str] = Field(default_factory=list)


class ToolOpportunityCreateRequest(BaseModel):
    spec_id: str | None = Field(default=None, min_length=8, max_length=96)
    title: str = Field(min_length=3, max_length=160)
    category: str = Field(min_length=3, max_length=64)
    target_domain: str = Field(min_length=3, max_length=32)
    problem_statement: str = Field(default="")
    proposed_tool_name: str = Field(min_length=3, max_length=120)
    why_needed: str = Field(default="")
    expected_inputs: list[str] = Field(default_factory=list)
    expected_outputs: list[str] = Field(default_factory=list)
    risk_level: str = Field(default="medium")
    tenant_scope: str = Field(default="global")
    source: str = Field(default="owner")
    linked_improvement_id: str | None = Field(default=None)
    linked_behavior_id: str | None = Field(default=None)
    status: str = Field(default="new")


class ToolOpportunityStatusRequest(BaseModel):
    spec_id: str = Field(min_length=8, max_length=96)
    status: str = Field(min_length=3, max_length=24)
    note: str = Field(default="")


class ToolOpportunityPublishRequest(BaseModel):
    spec_id: str = Field(min_length=8, max_length=96)


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


def normalize_short_text(value: Any, max_len: int = 200) -> str:
    return normalize_text(redact_secrets(str(value or "")))[:max_len].strip()


def normalize_multiline_text(value: Any, max_len: int = 2000) -> str:
    raw = redact_secrets(str(value or "")).replace("\r\n", "\n").replace("\r", "\n").strip()
    if len(raw) <= max_len:
        return raw
    return raw[:max_len].rstrip()


def normalize_string_list(value: Any, *, max_items: int = 24, max_len: int = 160) -> list[str]:
    items: list[str] = []
    if isinstance(value, list):
        source_items = value
    elif isinstance(value, str) and value.strip():
        source_items = [part.strip() for part in value.split(",")]
    else:
        source_items = []
    seen: set[str] = set()
    for item in source_items:
        text = normalize_short_text(item, max_len=max_len)
        if not text:
            continue
        key = text.lower()
        if key in seen:
            continue
        seen.add(key)
        items.append(text)
        if len(items) >= max_items:
            break
    return items


def sanitize_onyx_tenant_id(value: Any) -> str:
    raw = normalize_text(value).lower()
    sanitized = re.sub(r"[^a-z0-9_\-]+", "_", raw).strip("_")
    if sanitized:
        return sanitized[:64]
    return f"tenant_{uuid4().hex[:12]}"


def normalize_optional_onyx_tenant_id(value: Any) -> str:
    raw = normalize_text(value)
    if not raw:
        return ""
    return sanitize_onyx_tenant_id(raw)


def parse_utc_timestamp(value: Any) -> datetime | None:
    text = normalize_text(value)
    if not text:
        return None
    try:
        return datetime.fromisoformat(text.replace("Z", "+00:00")).astimezone(timezone.utc)
    except Exception:
        return None


def normalize_actor_role(value: Any) -> str:
    raw = normalize_text(value).lower()
    mapping = {
        "owner": "owner",
        "tenant_admin": "tenant_admin",
        "tenant admin": "tenant_admin",
        "tenant_member": "tenant_member",
        "tenant member": "tenant_member",
        "mason_internal": "mason_internal",
        "mason internal": "mason_internal",
        "system": "mason_internal",
        "system_internal": "mason_internal",
        "system/mason internal": "mason_internal",
    }
    normalized = mapping.get(raw, raw.replace("-", "_").replace("/", "_").replace(" ", "_"))
    return normalized if normalized in {"owner", "tenant_admin", "tenant_member", "mason_internal"} else "mason_internal"


def normalize_permission_name(value: Any) -> str:
    text = re.sub(r"[^a-z0-9_:\-]+", "_", normalize_text(value).lower()).strip("_")
    return text[:80]


def default_rbac_policy() -> dict[str, Any]:
    now = utc_now_iso()
    return {
        "version": 1,
        "updated_at_utc": now,
        "roles": [
            {
                "role_id": "owner",
                "label": "Owner",
                "description": "Platform owner with approval, export, delete, and governance authority.",
                "permissions": [
                    "tenant:read_all",
                    "tenant:write_all",
                    "tool:run_all",
                    "recommendation:review_all",
                    "queue:triage",
                    "trust:promote",
                    "audit:read",
                    "data:export",
                    "data:delete",
                    "security:review",
                ],
                "tenant_scope": "global",
                "approval_override": True,
            },
            {
                "role_id": "tenant_admin",
                "label": "Tenant Admin",
                "description": "Admin for one tenant with profile, recommendation, and tool execution control.",
                "permissions": [
                    "tenant:read",
                    "tenant:write",
                    "tool:catalog",
                    "tool:run",
                    "recommendation:read",
                    "recommendation:act",
                    "data:export_request",
                    "data:delete_request",
                ],
                "tenant_scope": "single_tenant",
                "approval_override": False,
            },
            {
                "role_id": "tenant_member",
                "label": "Tenant Member",
                "description": "Read-mostly tenant access with limited recommendation and tool visibility.",
                "permissions": [
                    "tenant:read",
                    "tool:catalog",
                    "recommendation:read",
                ],
                "tenant_scope": "single_tenant",
                "approval_override": False,
            },
            {
                "role_id": "mason_internal",
                "label": "System/Mason Internal",
                "description": "Internal service role for governed automation and background maintenance.",
                "permissions": [
                    "tenant:read_all",
                    "recommendation:generate",
                    "queue:refresh",
                    "trust:read",
                    "tool_factory:read",
                    "audit:write",
                    "security:write_posture",
                ],
                "tenant_scope": "system",
                "approval_override": False,
            },
        ],
        "default_bindings": {
            "owner_actor": "owner",
            "tenant_admin_actor": "tenant_admin",
            "tenant_member_actor": "tenant_member",
            "system_actor": "mason_internal",
        },
    }


def load_rbac_policy() -> dict[str, Any]:
    default_policy = default_rbac_policy()
    data = read_json(RBAC_POLICY_PATH, default=default_policy)
    if not isinstance(data, dict):
        data = default_policy
    roles_out: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    for role in normalize_list(data.get("roles")):
        if not isinstance(role, dict):
            continue
        role_id = normalize_actor_role(role.get("role_id") or role.get("id"))
        if role_id in seen_ids:
            continue
        seen_ids.add(role_id)
        permissions = [
            permission
            for permission in (
                normalize_permission_name(item)
                for item in normalize_list(role.get("permissions"))
            )
            if permission
        ]
        roles_out.append(
            {
                "role_id": role_id,
                "label": normalize_short_text(role.get("label") or role_id.replace("_", " ").title(), max_len=80),
                "description": normalize_short_text(role.get("description"), max_len=240),
                "permissions": permissions,
                "tenant_scope": normalize_short_text(role.get("tenant_scope") or "single_tenant", max_len=40).lower(),
                "approval_override": bool(role.get("approval_override")),
            }
        )
    if not roles_out:
        roles_out = default_policy["roles"]
    payload = {
        "version": 1,
        "updated_at_utc": normalize_short_text(data.get("updated_at_utc"), max_len=64) or default_policy["updated_at_utc"],
        "roles": roles_out,
        "default_bindings": data.get("default_bindings") if isinstance(data.get("default_bindings"), dict) else default_policy["default_bindings"],
    }
    if not RBAC_POLICY_PATH.exists():
        write_json(RBAC_POLICY_PATH, payload)
    return payload


def default_data_governance_policy() -> dict[str, Any]:
    now = utc_now_iso()
    return {
        "version": 1,
        "updated_at_utc": now,
        "retention": {
            "knowledge_records_days": 3650,
            "tenant_profiles_days": 3650,
            "tool_artifacts_days": 730,
            "audit_log_days": 3650,
            "reports_days": 365,
        },
        "export": {
            "enabled": True,
            "approval_required_roles": ["owner"],
            "supported_formats": ["json", "zip"],
            "target_sla_hours": 72,
        },
        "delete": {
            "enabled": True,
            "approval_required_roles": ["owner"],
            "hard_delete_requires_owner": True,
            "target_sla_hours": 72,
        },
        "legal": {
            "tenant_isolation_required": True,
            "audit_required_for_sensitive_actions": True,
            "billing_sensitive_actions_require_approval": True,
        },
    }


def load_data_governance_policy() -> dict[str, Any]:
    default_policy = default_data_governance_policy()
    data = read_json(DATA_GOVERNANCE_POLICY_PATH, default=default_policy)
    if not isinstance(data, dict):
        data = default_policy
    payload = {
        "version": 1,
        "updated_at_utc": normalize_short_text(data.get("updated_at_utc"), max_len=64) or default_policy["updated_at_utc"],
        "retention": data.get("retention") if isinstance(data.get("retention"), dict) else default_policy["retention"],
        "export": data.get("export") if isinstance(data.get("export"), dict) else default_policy["export"],
        "delete": data.get("delete") if isinstance(data.get("delete"), dict) else default_policy["delete"],
        "legal": data.get("legal") if isinstance(data.get("legal"), dict) else default_policy["legal"],
    }
    if not DATA_GOVERNANCE_POLICY_PATH.exists():
        write_json(DATA_GOVERNANCE_POLICY_PATH, payload)
    return payload


def empty_data_governance_state() -> dict[str, Any]:
    return {
        "version": 1,
        "updated_at_utc": "",
        "export_requests": [],
        "delete_requests": [],
        "retention_exceptions": [],
    }


def load_data_governance_state() -> dict[str, Any]:
    default_state = empty_data_governance_state()
    data = read_json(DATA_GOVERNANCE_STATE_PATH, default=default_state)
    if not isinstance(data, dict):
        data = default_state
    payload = {
        "version": 1,
        "updated_at_utc": normalize_short_text(data.get("updated_at_utc"), max_len=64),
        "export_requests": [item for item in normalize_list(data.get("export_requests")) if isinstance(item, dict)],
        "delete_requests": [item for item in normalize_list(data.get("delete_requests")) if isinstance(item, dict)],
        "retention_exceptions": [item for item in normalize_list(data.get("retention_exceptions")) if isinstance(item, dict)],
    }
    if not DATA_GOVERNANCE_STATE_PATH.exists():
        write_json(DATA_GOVERNANCE_STATE_PATH, payload)
    return payload


def summarize_data_governance_state(state: dict[str, Any] | None = None) -> dict[str, Any]:
    payload = state if isinstance(state, dict) else load_data_governance_state()
    export_requests = [item for item in normalize_list(payload.get("export_requests")) if isinstance(item, dict)]
    delete_requests = [item for item in normalize_list(payload.get("delete_requests")) if isinstance(item, dict)]
    open_statuses = {"new", "queued", "approved", "in_progress"}
    open_export_total = sum(1 for item in export_requests if normalize_short_text(item.get("status") or "new", max_len=32).lower() in open_statuses)
    open_delete_total = sum(1 for item in delete_requests if normalize_short_text(item.get("status") or "new", max_len=32).lower() in open_statuses)
    return {
        "export_request_total": len(export_requests),
        "delete_request_total": len(delete_requests),
        "open_export_request_total": open_export_total,
        "open_delete_request_total": open_delete_total,
        "open_total": open_export_total + open_delete_total,
        "artifact_path": str(DATA_GOVERNANCE_STATE_PATH),
    }


def sanitize_audit_value(value: Any, *, depth: int = 0) -> Any:
    if depth >= 3:
        return normalize_short_text(value, max_len=240)
    if isinstance(value, dict):
        output: dict[str, Any] = {}
        for key, item in list(value.items())[:24]:
            clean_key = normalize_short_text(key, max_len=64)
            if not clean_key:
                continue
            output[clean_key] = sanitize_audit_value(item, depth=depth + 1)
        return output
    if isinstance(value, list):
        return [sanitize_audit_value(item, depth=depth + 1) for item in value[:24]]
    if isinstance(value, (int, float, bool)) or value is None:
        return value
    return normalize_short_text(value, max_len=240)


def append_platform_audit_event(
    *,
    event_type: str,
    actor_role: str,
    resource_type: str,
    resource_id: str,
    action: str,
    outcome: str,
    tenant_id: str = "",
    actor_id: str = "",
    risk_level: str = "",
    details: dict[str, Any] | None = None,
) -> dict[str, Any]:
    payload = {
        "schema_version": 1,
        "event_id": f"audit_{uuid4().hex[:12]}",
        "timestamp_utc": utc_now_iso(),
        "event_type": normalize_short_text(event_type, max_len=48).lower(),
        "actor_role": normalize_actor_role(actor_role),
        "actor_id": normalize_short_text(actor_id or actor_role, max_len=80),
        "tenant_id": normalize_optional_onyx_tenant_id(tenant_id),
        "resource_type": normalize_short_text(resource_type, max_len=48).lower(),
        "resource_id": normalize_short_text(resource_id, max_len=120),
        "action": normalize_short_text(action, max_len=48).lower(),
        "outcome": normalize_short_text(outcome, max_len=32).lower(),
        "risk_level": normalize_short_text(risk_level, max_len=24).upper(),
        "details": sanitize_audit_value(details or {}, depth=0),
    }
    append_jsonl(PLATFORM_AUDIT_LOG_PATH, payload)
    if hasattr(build_security_posture, "_cache"):
        build_security_posture._cache = {"ts": 0.0, "payload": {}}
    return payload


def load_platform_audit_events(limit: int = 200) -> list[dict[str, Any]]:
    if limit <= 0 or not PLATFORM_AUDIT_LOG_PATH.exists():
        return []
    try:
        with PLATFORM_AUDIT_LOG_PATH.open("r", encoding="utf-8") as handle:
            lines = handle.readlines()
    except Exception:
        return []
    rows: list[dict[str, Any]] = []
    for line in lines[-limit:]:
        text = line.strip()
        if not text:
            continue
        try:
            item = json.loads(text)
        except Exception:
            continue
        if isinstance(item, dict):
            rows.append(item)
    return rows


def summarize_platform_audit_log(limit: int = 400) -> dict[str, Any]:
    rows = load_platform_audit_events(limit=limit)
    by_event_type: dict[str, int] = {}
    events_24h = 0
    cutoff = time.time() - 86400
    latest_event_at = ""
    for item in rows:
        event_type = normalize_short_text(item.get("event_type"), max_len=48).lower() or "unknown"
        by_event_type[event_type] = by_event_type.get(event_type, 0) + 1
        event_time = parse_utc_timestamp(item.get("timestamp_utc"))
        if event_time and event_time.timestamp() >= cutoff:
            events_24h += 1
        if not latest_event_at:
            latest_event_at = normalize_short_text(item.get("timestamp_utc"), max_len=64)
    return {
        "total_events": len(rows),
        "events_24h": events_24h,
        "by_event_type": by_event_type,
        "latest_event_at_utc": latest_event_at,
        "artifact_path": str(PLATFORM_AUDIT_LOG_PATH),
    }


def dict_path_get(value: Any, path: str) -> Any:
    current = value
    for part in path.split("."):
        if not isinstance(current, dict):
            return None
        current = current.get(part)
    return current


def is_loopback_listener_address(value: Any) -> bool:
    text = normalize_text(value).strip("[]")
    if not text:
        return True
    if text.lower() in {"localhost", "127.0.0.1", "::1"}:
        return True
    if text in {"0.0.0.0", "::"}:
        return False
    try:
        return bool(ipaddress.ip_address(text).is_loopback)
    except Exception:
        return False


def add_tenant_safety_issue(
    issues: list[dict[str, Any]],
    *,
    severity: str,
    category: str,
    path: str,
    message: str,
    tenant_id: str = "",
    expected_tenant_id: str = "",
    observed_tenant_id: str = "",
) -> None:
    issues.append(
        {
            "severity": normalize_short_text(severity, max_len=16).lower() or "warn",
            "category": normalize_short_text(category, max_len=48).lower(),
            "path": normalize_text(path),
            "tenant_id": normalize_optional_onyx_tenant_id(tenant_id),
            "expected_tenant_id": normalize_optional_onyx_tenant_id(expected_tenant_id),
            "observed_tenant_id": normalize_optional_onyx_tenant_id(observed_tenant_id),
            "message": normalize_short_text(message, max_len=240),
        }
    )


def build_tenant_safety_report() -> dict[str, Any]:
    cache = getattr(build_tenant_safety_report, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 10.0:
        return cache["payload"]

    workspace = load_onyx_workspace()
    known_tenants = {
        normalize_optional_onyx_tenant_id(dict_path_get(context, "tenant.id"))
        for context in normalize_list(workspace.get("contexts"))
        if isinstance(context, dict)
    }
    known_tenants.discard("")
    issues: list[dict[str, Any]] = []
    active_tenant_id = normalize_optional_onyx_tenant_id(workspace.get("activeTenantId"))
    if active_tenant_id and active_tenant_id not in known_tenants:
        add_tenant_safety_issue(
            issues,
            severity="critical",
            category="workspace",
            path=str(ONYX_TENANT_WORKSPACE_PATH),
            message="Active tenant is not present in the workspace context list.",
            tenant_id=active_tenant_id,
            expected_tenant_id=active_tenant_id,
        )

    tenant_artifact_total = 0
    recommendation_artifact_total = 0
    tool_run_artifact_total = 0

    for tenant_path in sorted(ONYX_TENANTS_DIR.glob("*.json")):
        tenant_artifact_total += 1
        expected_tenant_id = sanitize_onyx_tenant_id(tenant_path.stem)
        if expected_tenant_id not in known_tenants:
            add_tenant_safety_issue(
                issues,
                severity="warn",
                category="tenant_artifact",
                path=str(tenant_path),
                message="Tenant artifact exists without a matching workspace context.",
                tenant_id=expected_tenant_id,
                expected_tenant_id=expected_tenant_id,
            )
        artifact = read_json(tenant_path, default={})
        if not isinstance(artifact, dict) or not artifact:
            add_tenant_safety_issue(
                issues,
                severity="critical",
                category="tenant_artifact",
                path=str(tenant_path),
                message="Tenant artifact is missing or unreadable.",
                tenant_id=expected_tenant_id,
                expected_tenant_id=expected_tenant_id,
            )
            continue
        for field_path in ("tenant_id", "tenant.tenant_id", "business_profile.tenant_id"):
            observed_tenant_id = normalize_optional_onyx_tenant_id(dict_path_get(artifact, field_path))
            if not observed_tenant_id:
                add_tenant_safety_issue(
                    issues,
                    severity="critical",
                    category="tenant_artifact",
                    path=str(tenant_path),
                    message=f"Tenant artifact field '{field_path}' is missing.",
                    tenant_id=expected_tenant_id,
                    expected_tenant_id=expected_tenant_id,
                )
            elif observed_tenant_id != expected_tenant_id:
                add_tenant_safety_issue(
                    issues,
                    severity="critical",
                    category="tenant_artifact",
                    path=str(tenant_path),
                    message=f"Tenant artifact field '{field_path}' does not match the file tenant scope.",
                    tenant_id=expected_tenant_id,
                    expected_tenant_id=expected_tenant_id,
                    observed_tenant_id=observed_tenant_id,
                )

    for recommendation_path in sorted(ONYX_RECOMMENDATIONS_DIR.glob("*.json")):
        recommendation_artifact_total += 1
        expected_tenant_id = sanitize_onyx_tenant_id(recommendation_path.stem)
        artifact = read_json(recommendation_path, default={})
        if not isinstance(artifact, dict):
            add_tenant_safety_issue(
                issues,
                severity="critical",
                category="recommendations",
                path=str(recommendation_path),
                message="Recommendation artifact is unreadable.",
                tenant_id=expected_tenant_id,
                expected_tenant_id=expected_tenant_id,
            )
            continue
        observed_tenant_id = normalize_optional_onyx_tenant_id(artifact.get("tenant_id"))
        if observed_tenant_id != expected_tenant_id:
            add_tenant_safety_issue(
                issues,
                severity="critical" if observed_tenant_id else "warn",
                category="recommendations",
                path=str(recommendation_path),
                message="Recommendation artifact tenant_id does not match the file tenant scope.",
                tenant_id=expected_tenant_id,
                expected_tenant_id=expected_tenant_id,
                observed_tenant_id=observed_tenant_id,
            )
        for item in normalize_list(artifact.get("recommendations")):
            if not isinstance(item, dict):
                continue
            item_tenant_id = normalize_optional_onyx_tenant_id(item.get("tenant_id"))
            if item_tenant_id != expected_tenant_id:
                add_tenant_safety_issue(
                    issues,
                    severity="critical" if item_tenant_id else "warn",
                    category="recommendations",
                    path=str(recommendation_path),
                    message="Recommendation item tenant_id does not match the owning tenant artifact.",
                    tenant_id=expected_tenant_id,
                    expected_tenant_id=expected_tenant_id,
                    observed_tenant_id=item_tenant_id,
                )

    if TOOL_RUNS_DIR.exists():
        run_dirs = [path for path in TOOL_RUNS_DIR.iterdir() if path.is_dir()]
        run_dirs.sort(key=lambda item: item.stat().st_mtime, reverse=True)
        for run_dir in run_dirs[:50]:
            tool_run_path = run_dir / "tool_run.json"
            if not tool_run_path.exists():
                continue
            tool_run_artifact_total += 1
            tool_run = read_json(tool_run_path, default={})
            if not isinstance(tool_run, dict):
                add_tenant_safety_issue(
                    issues,
                    severity="critical",
                    category="tool_run",
                    path=str(tool_run_path),
                    message="Tool run artifact is unreadable.",
                )
                continue
            tenant_id = normalize_optional_onyx_tenant_id(tool_run.get("tenant_id"))
            workspace_id = normalize_optional_onyx_tenant_id(tool_run.get("workspace_id"))
            if not tenant_id:
                add_tenant_safety_issue(
                    issues,
                    severity="warn",
                    category="tool_run",
                    path=str(tool_run_path),
                    message="Tool run is missing an explicit tenant_id.",
                )
            else:
                if tenant_id not in known_tenants:
                    add_tenant_safety_issue(
                        issues,
                        severity="warn",
                        category="tool_run",
                        path=str(tool_run_path),
                        message="Tool run references a tenant that is not present in the workspace.",
                        tenant_id=tenant_id,
                        observed_tenant_id=tenant_id,
                    )
                if workspace_id and workspace_id != tenant_id:
                    add_tenant_safety_issue(
                        issues,
                        severity="critical",
                        category="tool_run",
                        path=str(tool_run_path),
                        message="Tool run workspace_id does not match tenant_id.",
                        tenant_id=tenant_id,
                        expected_tenant_id=tenant_id,
                        observed_tenant_id=workspace_id,
                    )
                profile_path = normalize_text(tool_run.get("tenant_profile_path"))
                if profile_path:
                    profile_tenant_id = sanitize_onyx_tenant_id(Path(profile_path).stem)
                    if profile_tenant_id != tenant_id:
                        add_tenant_safety_issue(
                            issues,
                            severity="critical",
                            category="tool_run",
                            path=str(tool_run_path),
                            message="Tool run tenant profile path does not match tenant_id.",
                            tenant_id=tenant_id,
                            expected_tenant_id=tenant_id,
                            observed_tenant_id=profile_tenant_id,
                        )

    severity_rank = {"critical": 2, "warn": 1}
    highest_severity = max((severity_rank.get(item.get("severity", ""), 0) for item in issues), default=0)
    status = "guarded" if highest_severity == 0 else ("restricted" if highest_severity >= 2 else "watch")
    payload = {
        "schema_version": 1,
        "generated_at_utc": utc_now_iso(),
        "ok": highest_severity == 0,
        "status": status,
        "tenant_count": len(known_tenants),
        "active_tenant_id": active_tenant_id,
        "artifacts_checked": tenant_artifact_total + recommendation_artifact_total + tool_run_artifact_total,
        "tenant_artifact_total": tenant_artifact_total,
        "recommendation_artifact_total": recommendation_artifact_total,
        "tool_run_artifact_total": tool_run_artifact_total,
        "issues_total": len(issues),
        "critical_issues_total": sum(1 for item in issues if item.get("severity") == "critical"),
        "warning_issues_total": sum(1 for item in issues if item.get("severity") == "warn"),
        "known_tenant_ids": sorted(known_tenants),
        "workspace_path": str(ONYX_TENANT_WORKSPACE_PATH),
        "tenant_root_path": str(ONYX_TENANTS_DIR),
        "recommendations_root_path": str(ONYX_RECOMMENDATIONS_DIR),
        "tool_runs_root_path": str(TOOL_RUNS_DIR),
        "issues": issues[:50],
    }
    write_json(TENANT_SAFETY_REPORT_PATH, payload)
    build_tenant_safety_report._cache = {"ts": now_monotonic, "payload": payload}
    return payload


def summarize_tenant_safety_report(report: dict[str, Any] | None = None) -> dict[str, Any]:
    payload = report if isinstance(report, dict) else build_tenant_safety_report()
    return {
        "ok": bool(payload.get("ok")),
        "status": normalize_short_text(payload.get("status"), max_len=24),
        "tenant_count": int(payload.get("tenant_count") or 0),
        "artifacts_checked": int(payload.get("artifacts_checked") or 0),
        "issues_total": int(payload.get("issues_total") or 0),
        "critical_issues_total": int(payload.get("critical_issues_total") or 0),
        "warning_issues_total": int(payload.get("warning_issues_total") or 0),
        "artifact_path": str(TENANT_SAFETY_REPORT_PATH),
    }


def extract_legacy_security_scan_snapshot(previous: dict[str, Any] | None = None) -> dict[str, Any]:
    payload = previous if isinstance(previous, dict) else read_json(SECURITY_POSTURE_PATH, default={})
    legacy = payload.get("legacy_security_scan_snapshot") if isinstance(payload, dict) else None
    if isinstance(legacy, dict):
        return legacy
    scan = payload.get("secrets_scan") if isinstance(payload, dict) and isinstance(payload.get("secrets_scan"), dict) else {}
    return {
        "generated_at_utc": normalize_short_text(payload.get("generated_at_utc") or payload.get("timestamp_utc"), max_len=64),
        "violation_count": int(scan.get("violation_count") or 0),
        "files_scanned": int(scan.get("files_scanned") or 0),
        "allowed_locations": normalize_string_list(scan.get("allowed_locations"), max_items=12, max_len=160),
    }


def build_security_posture() -> dict[str, Any]:
    cache = getattr(build_security_posture, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 10.0:
        return cache["payload"]

    previous = read_json(SECURITY_POSTURE_PATH, default={})
    legacy_scan = extract_legacy_security_scan_snapshot(previous if isinstance(previous, dict) else None)
    tenant_safety = build_tenant_safety_report()
    audit_summary = summarize_platform_audit_log(limit=600)
    approvals = build_approvals_section()
    trust_summary = summarize_behavior_trust_state()
    remote_policy = load_remote_access_policy()
    general_policy = read_json(CONFIG_DIR / "policy.json", default={})
    core_status = read_json(MASON_CORE_STATUS_PATH, default={})
    rbac_policy = load_rbac_policy()
    governance_policy = load_data_governance_policy()
    governance_state = load_data_governance_state()
    governance_summary = summarize_data_governance_state(governance_state)

    guardrails = core_status.get("policy_guardrails") if isinstance(core_status, dict) and isinstance(core_status.get("policy_guardrails"), dict) else {}
    ports = resolve_stack_ports()
    ordered_names = ["mason_api", "seed_api", "bridge", "athena", "onyx"]
    listeners_by_port = netstat_listener_map([int(ports[name]) for name in ordered_names])
    non_loopback_bindings: list[dict[str, Any]] = []
    listener_rows: list[dict[str, Any]] = []
    for name in ordered_names:
        port = int(ports[name])
        listeners = listeners_by_port.get(port, [])
        loopback_only = all(is_loopback_listener_address(item.get("local_address")) for item in listeners) if listeners else True
        listener_rows.append(
            {
                "component_id": name,
                "port": port,
                "listener_count": len(listeners),
                "loopback_only": loopback_only,
            }
        )
        for listener in listeners:
            local_address = normalize_text(listener.get("local_address"))
            if is_loopback_listener_address(local_address):
                continue
            non_loopback_bindings.append(
                {
                    "component_id": name,
                    "port": port,
                    "local_address": local_address,
                    "owning_pid": int(listener.get("owning_pid") or 0),
                }
            )

    secrets_violation_count = int(legacy_scan.get("violation_count") or 0)
    secrets_posture = {
        "status": "watch" if secrets_violation_count > 0 else "guarded",
        "managed_secret_store_present": SECRETS_PATH.exists(),
        "redaction_enabled": True,
        "output_moderation_rules": normalize_string_list(general_policy.get("output_moderation_rules"), max_items=12, max_len=120),
        "legacy_violation_count": secrets_violation_count,
        "allowed_secret_locations": legacy_scan.get("allowed_locations") or ["config/secrets_mason.json", "config/.env", ".env"],
    }
    ports_contract = read_json(PORTS_PATH, default={})
    open_ports_bind_posture = {
        "status": "watch" if non_loopback_bindings else "guarded",
        "bind_host_contract": normalize_short_text((ports_contract or {}).get("bind_host") or "127.0.0.1", max_len=64),
        "listener_rows": listener_rows,
        "non_loopback_bindings_total": len(non_loopback_bindings),
        "non_loopback_bindings": non_loopback_bindings[:12],
    }
    auth_signing_posture = {
        "status": "guarded" if bool(remote_policy.get("require_signed_requests")) else "watch",
        "remote_access_enabled": bool(remote_policy.get("enabled", False)),
        "allow_loopback": bool(remote_policy.get("allow_loopback", True)),
        "require_signed_requests": bool(remote_policy.get("require_signed_requests", False)),
        "signed_exempt_path_total": len(normalize_list(remote_policy.get("signed_exempt_paths"))),
        "pairing_flag_path": normalize_text(remote_policy.get("pairing_flag_path") or str(PAIRING_FLAG_PATH_DEFAULT)),
    }
    approval_posture_status = "guarded"
    if bool(guardrails.get("high_risk_auto_apply")) or bool(guardrails.get("money_loop_enabled")):
        approval_posture_status = "restricted"
    elif int(approvals.get("pending_total") or 0) > 0 or int(trust_summary.get("awaiting_approval_total") or 0) > 0:
        approval_posture_status = "watch"
    approval_posture = {
        "status": approval_posture_status,
        "pending_approvals_total": int(approvals.get("pending_total") or 0),
        "eligible_approvals_total": int(approvals.get("eligible_total") or 0),
        "quarantine_total": int(approvals.get("quarantine_total") or 0),
        "behavior_awaiting_approval_total": int(trust_summary.get("awaiting_approval_total") or 0),
        "high_risk_auto_apply": bool(guardrails.get("high_risk_auto_apply", False)),
        "money_loop_enabled": bool(guardrails.get("money_loop_enabled", False)),
    }
    tenant_isolation_posture = {
        "status": normalize_short_text(tenant_safety.get("status"), max_len=24) or "guarded",
        "tenant_count": int(tenant_safety.get("tenant_count") or 0),
        "issues_total": int(tenant_safety.get("issues_total") or 0),
        "critical_issues_total": int(tenant_safety.get("critical_issues_total") or 0),
        "artifact_path": str(TENANT_SAFETY_REPORT_PATH),
    }
    audit_posture = {
        "status": "guarded" if int(audit_summary.get("total_events") or 0) > 0 else "watch",
        "total_events": int(audit_summary.get("total_events") or 0),
        "events_24h": int(audit_summary.get("events_24h") or 0),
        "by_event_type": audit_summary.get("by_event_type", {}),
        "artifact_path": str(PLATFORM_AUDIT_LOG_PATH),
    }
    retention_export_delete_posture = {
        "status": "watch" if int(governance_summary.get("open_total") or 0) > 0 else "guarded",
        "retention_days": governance_policy.get("retention", {}),
        "export_enabled": bool((governance_policy.get("export") or {}).get("enabled", False)),
        "delete_enabled": bool((governance_policy.get("delete") or {}).get("enabled", False)),
        "open_export_request_total": int(governance_summary.get("open_export_request_total") or 0),
        "open_delete_request_total": int(governance_summary.get("open_delete_request_total") or 0),
        "policy_path": str(DATA_GOVERNANCE_POLICY_PATH),
        "state_path": str(DATA_GOVERNANCE_STATE_PATH),
    }
    permission_model = {
        "status": "guarded" if len(normalize_list(rbac_policy.get("roles"))) >= 4 else "watch",
        "role_total": len(normalize_list(rbac_policy.get("roles"))),
        "roles": [
            {
                "role_id": normalize_actor_role(item.get("role_id")),
                "permission_total": len(normalize_list(item.get("permissions"))),
                "tenant_scope": normalize_short_text(item.get("tenant_scope"), max_len=40),
            }
            for item in normalize_list(rbac_policy.get("roles"))
            if isinstance(item, dict)
        ],
        "policy_path": str(RBAC_POLICY_PATH),
    }

    status_rank = {"guarded": 0, "watch": 1, "restricted": 2}
    overall_status = "guarded"
    for posture in (
        secrets_posture,
        open_ports_bind_posture,
        auth_signing_posture,
        approval_posture,
        tenant_isolation_posture,
        audit_posture,
        retention_export_delete_posture,
        permission_model,
    ):
        posture_status = normalize_short_text(posture.get("status"), max_len=24).lower() or "guarded"
        if status_rank.get(posture_status, 0) > status_rank.get(overall_status, 0):
            overall_status = posture_status

    now = utc_now_iso()
    payload = {
        "schema_version": 1,
        "timestamp_utc": now,
        "overall_status": overall_status,
        "secrets_posture": secrets_posture,
        "open_ports_bind_posture": open_ports_bind_posture,
        "auth_signing_posture": auth_signing_posture,
        "approval_posture": approval_posture,
        "tenant_isolation_posture": tenant_isolation_posture,
        "audit_posture": audit_posture,
        "retention_export_delete_posture": retention_export_delete_posture,
        "permission_model": permission_model,
        "artifacts": {
            "tenant_safety_report_path": str(TENANT_SAFETY_REPORT_PATH),
            "audit_log_path": str(PLATFORM_AUDIT_LOG_PATH),
            "rbac_policy_path": str(RBAC_POLICY_PATH),
            "data_governance_policy_path": str(DATA_GOVERNANCE_POLICY_PATH),
            "data_governance_state_path": str(DATA_GOVERNANCE_STATE_PATH),
        },
        "legacy_security_scan_snapshot": legacy_scan,
        "generated_at_utc": now,
        "overall_pass": overall_status == "guarded",
        "secrets_scan": {
            "pass": secrets_posture["status"] == "guarded",
            "violation_count": secrets_violation_count,
            "files_scanned": int(legacy_scan.get("files_scanned") or 0),
            "allowed_locations": legacy_scan.get("allowed_locations") or [],
        },
        "loopback_bindings": {
            "pass": open_ports_bind_posture["status"] == "guarded",
            "ports_checked": listener_rows,
            "non_loopback_bindings_total": len(non_loopback_bindings),
        },
        "approvals_integrity": {
            "pass": approval_posture["status"] != "restricted",
            "pending_total": approval_posture["pending_approvals_total"],
            "awaiting_approval_total": approval_posture["behavior_awaiting_approval_total"],
        },
    }
    write_json(SECURITY_POSTURE_PATH, payload)
    build_security_posture._cache = {"ts": now_monotonic, "payload": payload}
    return payload


def summarize_security_posture(posture: dict[str, Any] | None = None) -> dict[str, Any]:
    payload = posture if isinstance(posture, dict) else build_security_posture()
    tenant_posture = payload.get("tenant_isolation_posture") if isinstance(payload.get("tenant_isolation_posture"), dict) else {}
    audit_posture = payload.get("audit_posture") if isinstance(payload.get("audit_posture"), dict) else {}
    retention_posture = payload.get("retention_export_delete_posture") if isinstance(payload.get("retention_export_delete_posture"), dict) else {}
    permission_model = payload.get("permission_model") if isinstance(payload.get("permission_model"), dict) else {}
    open_ports_posture = payload.get("open_ports_bind_posture") if isinstance(payload.get("open_ports_bind_posture"), dict) else {}
    return {
        "overall_status": normalize_short_text(payload.get("overall_status"), max_len=24) or "guarded",
        "tenant_isolation_issues_total": int(tenant_posture.get("issues_total") or 0),
        "audit_events_24h": int(audit_posture.get("events_24h") or 0),
        "open_data_requests_total": int(retention_posture.get("open_export_request_total") or 0) + int(retention_posture.get("open_delete_request_total") or 0),
        "rbac_roles_total": int(permission_model.get("role_total") or 0),
        "non_loopback_bindings_total": int(open_ports_posture.get("non_loopback_bindings_total") or 0),
        "artifact_path": str(SECURITY_POSTURE_PATH),
    }


def clear_security_posture_caches() -> None:
    if hasattr(build_tenant_safety_report, "_cache"):
        build_tenant_safety_report._cache = {"ts": 0.0, "payload": {}}
    if hasattr(build_security_posture, "_cache"):
        build_security_posture._cache = {"ts": 0.0, "payload": {}}


def empty_onyx_workspace() -> dict[str, Any]:
    return {
        "version": 1,
        "activeTenantId": "",
        "contexts": [],
        "lastUpdatedAtUtc": "",
    }


def sanitize_onyx_business_context(workspace_raw: Any) -> dict[str, Any]:
    if not isinstance(workspace_raw, dict):
        return empty_onyx_workspace()

    contexts_out: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    for item in normalize_list(workspace_raw.get("contexts"))[:24]:
        if not isinstance(item, dict):
            continue
        tenant_raw = item.get("tenant") if isinstance(item.get("tenant"), dict) else {}
        profile_raw = item.get("profile") if isinstance(item.get("profile"), dict) else {}
        plan_raw = item.get("plan") if isinstance(item.get("plan"), dict) else {}
        onboarding_raw = item.get("onboarding") if isinstance(item.get("onboarding"), dict) else {}
        tenant_id = sanitize_onyx_tenant_id(
            tenant_raw.get("id")
            or profile_raw.get("tenantId")
            or item.get("tenantId")
        )
        if tenant_id in seen_ids:
            continue
        seen_ids.add(tenant_id)

        context_updated_at = normalize_short_text(
            item.get("lastUpdatedAtUtc")
            or tenant_raw.get("lastUpdatedAtUtc")
            or profile_raw.get("lastUpdatedAtUtc")
            or plan_raw.get("lastUpdatedAtUtc")
            or onboarding_raw.get("lastUpdatedAtUtc")
            or utc_now_iso(),
            max_len=64,
        )
        tenant_out = {
            "id": tenant_id,
            "owner": normalize_short_text(tenant_raw.get("owner") or "Owner", max_len=120),
            "createdAtUtc": normalize_short_text(tenant_raw.get("createdAtUtc") or context_updated_at, max_len=64),
            "status": normalize_short_text(tenant_raw.get("status") or "active", max_len=32) or "active",
            "planTier": normalize_short_text(
                tenant_raw.get("planTier") or plan_raw.get("currentTier") or "Founder",
                max_len=40,
            )
            or "Founder",
            "lastUpdatedAtUtc": normalize_short_text(
                tenant_raw.get("lastUpdatedAtUtc") or context_updated_at,
                max_len=64,
            ),
        }
        profile_out = {
            "tenantId": tenant_id,
            "businessName": normalize_short_text(profile_raw.get("businessName") or "Untitled business", max_len=160)
            or "Untitled business",
            "businessType": normalize_short_text(profile_raw.get("businessType") or "General", max_len=120) or "General",
            "size": normalize_short_text(profile_raw.get("size") or "Solo", max_len=40) or "Solo",
            "currency": normalize_short_text(profile_raw.get("currency") or "CAD", max_len=8) or "CAD",
            "countryRegion": normalize_short_text(
                profile_raw.get("countryRegion") or profile_raw.get("region") or "CA",
                max_len=32,
            )
            or "CA",
            "mainGoal": normalize_short_text(
                profile_raw.get("mainGoal") or "Get organized and get paid",
                max_len=240,
            ),
            "servicesProducts": normalize_string_list(
                profile_raw.get("servicesProducts") or profile_raw.get("services") or profile_raw.get("products"),
            ),
            "locations": normalize_string_list(profile_raw.get("locations")),
            "operatingArea": normalize_short_text(profile_raw.get("operatingArea"), max_len=160),
            "currentTools": normalize_string_list(profile_raw.get("currentTools") or profile_raw.get("software")),
            "goals": normalize_string_list(profile_raw.get("goals")),
            "painPoints": normalize_string_list(profile_raw.get("painPoints")),
            "growthPriorities": normalize_string_list(profile_raw.get("growthPriorities")),
            "riskTolerance": normalize_short_text(profile_raw.get("riskTolerance") or "Balanced", max_len=40) or "Balanced",
            "automationTolerance": normalize_short_text(
                profile_raw.get("automationTolerance") or "Assist only",
                max_len=64,
            )
            or "Assist only",
            "budgetSensitivity": normalize_short_text(
                profile_raw.get("budgetSensitivity") or "Balanced",
                max_len=40,
            )
            or "Balanced",
            "notes": normalize_multiline_text(profile_raw.get("notes"), max_len=4000),
            "uploadReferences": normalize_string_list(profile_raw.get("uploadReferences"), max_items=32, max_len=260),
            "lastUpdatedAtUtc": normalize_short_text(
                profile_raw.get("lastUpdatedAtUtc") or context_updated_at,
                max_len=64,
            ),
        }
        plan_out = {
            "currentTier": normalize_short_text(plan_raw.get("currentTier") or tenant_out["planTier"], max_len=40)
            or tenant_out["planTier"],
            "enabledFeatures": normalize_string_list(plan_raw.get("enabledFeatures"), max_items=32, max_len=64),
            "addonFeatures": normalize_string_list(plan_raw.get("addonFeatures"), max_items=32, max_len=64),
            "betaOptIn": bool(plan_raw.get("betaOptIn", True)),
            "lastUpdatedAtUtc": normalize_short_text(
                plan_raw.get("lastUpdatedAtUtc") or context_updated_at,
                max_len=64,
            ),
        }
        current_step = onboarding_raw.get("currentStepIndex")
        try:
            current_step_int = int(current_step)
        except Exception:
            current_step_int = 0
        completion = onboarding_raw.get("completionPercent")
        try:
            completion_int = int(completion)
        except Exception:
            completion_int = 0
        onboarding_out = {
            "currentStepIndex": max(0, min(3, current_step_int)),
            "completedStepIds": normalize_string_list(onboarding_raw.get("completedStepIds"), max_items=8, max_len=32),
            "isCompleted": bool(onboarding_raw.get("isCompleted", False)),
            "completionPercent": max(0, min(100, completion_int)),
            "lastUpdatedAtUtc": normalize_short_text(
                onboarding_raw.get("lastUpdatedAtUtc") or context_updated_at,
                max_len=64,
            ),
        }
        contexts_out.append(
            {
                "tenant": tenant_out,
                "profile": profile_out,
                "plan": plan_out,
                "onboarding": onboarding_out,
                "lastUpdatedAtUtc": context_updated_at,
            }
        )

    active_tenant_id = sanitize_onyx_tenant_id(workspace_raw.get("activeTenantId"))
    if not active_tenant_id or active_tenant_id not in {ctx["tenant"]["id"] for ctx in contexts_out}:
        active_tenant_id = contexts_out[0]["tenant"]["id"] if contexts_out else ""
    return {
        "version": 1,
        "activeTenantId": active_tenant_id,
        "contexts": contexts_out,
        "lastUpdatedAtUtc": normalize_short_text(
            workspace_raw.get("lastUpdatedAtUtc")
            or (contexts_out[0]["lastUpdatedAtUtc"] if contexts_out else ""),
            max_len=64,
        ),
    }


def write_onyx_business_context_artifacts(workspace: dict[str, Any]) -> dict[str, Any]:
    write_json(ONYX_TENANT_WORKSPACE_PATH, workspace)

    tenant_paths: list[str] = []
    tenant_summaries: list[dict[str, Any]] = []
    active_id = str(workspace.get("activeTenantId") or "")
    active_artifact: dict[str, Any] | None = None
    for item in workspace.get("contexts", []):
        if not isinstance(item, dict):
            continue
        tenant = item.get("tenant") if isinstance(item.get("tenant"), dict) else {}
        profile = item.get("profile") if isinstance(item.get("profile"), dict) else {}
        plan = item.get("plan") if isinstance(item.get("plan"), dict) else {}
        onboarding = item.get("onboarding") if isinstance(item.get("onboarding"), dict) else {}
        tenant_id = sanitize_onyx_tenant_id(tenant.get("id"))
        artifact = {
            "version": 1,
            "tenant_id": tenant_id,
            "tenant": {
                "tenant_id": tenant_id,
                "owner": tenant.get("owner"),
                "created_at_utc": tenant.get("createdAtUtc"),
                "status": tenant.get("status"),
                "plan_tier": tenant.get("planTier"),
                "last_updated_at_utc": tenant.get("lastUpdatedAtUtc"),
            },
            "business_profile": {
                "tenant_id": tenant_id,
                "business_name": profile.get("businessName"),
                "business_type": profile.get("businessType"),
                "team_size": profile.get("size"),
                "currency": profile.get("currency"),
                "country_region": profile.get("countryRegion"),
                "main_goal": profile.get("mainGoal"),
                "services_products": profile.get("servicesProducts"),
                "locations": profile.get("locations"),
                "operating_area": profile.get("operatingArea"),
                "current_tools": profile.get("currentTools"),
                "goals": profile.get("goals"),
                "pain_points": profile.get("painPoints"),
                "growth_priorities": profile.get("growthPriorities"),
                "risk_tolerance": profile.get("riskTolerance"),
                "automation_tolerance": profile.get("automationTolerance"),
                "budget_sensitivity": profile.get("budgetSensitivity"),
                "notes": profile.get("notes"),
                "upload_references": profile.get("uploadReferences"),
                "last_updated_at_utc": profile.get("lastUpdatedAtUtc"),
            },
            "plan": {
                "current_tier": plan.get("currentTier"),
                "enabled_features": plan.get("enabledFeatures"),
                "addon_features": plan.get("addonFeatures"),
                "beta_opt_in": plan.get("betaOptIn"),
                "last_updated_at_utc": plan.get("lastUpdatedAtUtc"),
            },
            "onboarding": {
                "current_step_index": onboarding.get("currentStepIndex"),
                "completed_step_ids": onboarding.get("completedStepIds"),
                "is_completed": onboarding.get("isCompleted"),
                "completion_percent": onboarding.get("completionPercent"),
                "last_updated_at_utc": onboarding.get("lastUpdatedAtUtc"),
            },
            "last_updated_at_utc": item.get("lastUpdatedAtUtc"),
        }
        target_path = ONYX_TENANTS_DIR / f"{tenant_id}.json"
        write_json(target_path, artifact)
        tenant_paths.append(str(target_path))
        tenant_summaries.append(
            {
                "tenant_id": tenant_id,
                "business_name": profile.get("businessName"),
                "owner": tenant.get("owner"),
                "status": tenant.get("status"),
                "plan_tier": tenant.get("planTier"),
                "last_updated_at_utc": item.get("lastUpdatedAtUtc"),
            }
        )
        if tenant_id == active_id:
            active_artifact = artifact

    if active_artifact is None and workspace.get("contexts"):
        first_context = workspace["contexts"][0]
        first_id = sanitize_onyx_tenant_id(
            first_context.get("tenant", {}).get("id") if isinstance(first_context.get("tenant"), dict) else ""
        )
        active_artifact = read_json(ONYX_TENANTS_DIR / f"{first_id}.json", default={})

    active_profile = active_artifact.get("business_profile", {}) if isinstance(active_artifact, dict) else {}
    active_tenant = active_artifact.get("tenant", {}) if isinstance(active_artifact, dict) else {}
    active_plan = active_artifact.get("plan", {}) if isinstance(active_artifact, dict) else {}
    active_onboarding = active_artifact.get("onboarding", {}) if isinstance(active_artifact, dict) else {}
    compat_plan_state = {
        "version": 2,
        "owner": active_tenant.get("owner"),
        "tenant_id": active_tenant.get("tenant_id"),
        "status": active_tenant.get("status"),
        "plan": active_plan,
        "business_profile": active_profile,
        "onboarding": active_onboarding,
        "tenants": tenant_summaries,
        "last_updated_at_utc": workspace.get("lastUpdatedAtUtc"),
    }
    write_json(ONYX_PLAN_STATE_PATH, compat_plan_state)
    clear_security_posture_caches()
    return {
        "workspace_path": str(ONYX_TENANT_WORKSPACE_PATH),
        "plan_state_path": str(ONYX_PLAN_STATE_PATH),
        "tenant_paths": tenant_paths,
    }


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


def load_tool_registry_document() -> dict[str, Any]:
    data = read_json(TOOL_REGISTRY_PATH, default={"version": 1, "tools": []})
    if not isinstance(data, dict):
        return {"version": 1, "tools": []}
    if not isinstance(data.get("tools"), list):
        data["tools"] = []
    if "version" not in data:
        data["version"] = 1
    return data


def load_tool_registry_entries() -> list[dict[str, Any]]:
    data = load_tool_registry_document()
    return [tool for tool in normalize_list(data.get("tools")) if isinstance(tool, dict)]


def get_tool_registry_entry(tool_id: str) -> dict[str, Any] | None:
    wanted = normalize_text(tool_id).lower()
    if not wanted:
        return None
    for tool in load_tool_registry_entries():
        candidate = normalize_text(tool.get("tool_id")).lower()
        if candidate == wanted:
            return tool
    return None


def normalize_tool_token(value: Any) -> str:
    return re.sub(r"[^a-z0-9]+", "", normalize_text(value).lower())


def normalize_tool_contract(tool: dict[str, Any]) -> dict[str, Any]:
    eligibility_raw = tool.get("tenant_eligibility") if isinstance(tool.get("tenant_eligibility"), dict) else {}
    minimum_completion_raw = eligibility_raw.get("minimum_onboarding_completion_percent", 0)
    try:
        minimum_completion = max(0, min(100, int(minimum_completion_raw)))
    except Exception:
        minimum_completion = 0

    status = normalize_short_text(
        tool.get("status") or ("enabled" if bool(tool.get("enabled", True)) else "disabled"),
        max_len=24,
    ).lower()
    if status not in {"enabled", "disabled", "pilot", "deprecated"}:
        status = "enabled"

    name = normalize_short_text(tool.get("name") or tool.get("title"), max_len=120) or "Unnamed tool"
    created_at = normalize_short_text(tool.get("created_at") or tool.get("createdAt") or utc_now_iso(), max_len=64)
    updated_at = normalize_short_text(tool.get("updated_at") or tool.get("updatedAt") or created_at, max_len=64)

    business_types = normalize_string_list(
        eligibility_raw.get("business_types") or tool.get("supported_business_types"),
        max_items=24,
        max_len=64,
    )
    allowed_statuses = normalize_string_list(
        eligibility_raw.get("allowed_statuses") or ["active", "pilot"],
        max_items=8,
        max_len=32,
    )
    allowed_plan_tiers = normalize_string_list(
        eligibility_raw.get("allowed_plan_tiers"),
        max_items=12,
        max_len=40,
    )
    allowed_tenant_ids = [
        normalize_optional_onyx_tenant_id(item)
        for item in normalize_list(eligibility_raw.get("allowed_tenant_ids"))
        if normalize_text(item)
    ]
    required_integrations = normalize_string_list(
        tool.get("required_integrations"),
        max_items=16,
        max_len=64,
    )

    return {
        "tool_id": normalize_short_text(tool.get("tool_id"), max_len=80),
        "name": name,
        "title": name,
        "version": normalize_short_text(tool.get("version"), max_len=40),
        "category": normalize_short_text(tool.get("category"), max_len=80),
        "description": normalize_short_text(tool.get("description"), max_len=400),
        "input_schema": tool.get("input_schema", {}) if isinstance(tool.get("input_schema"), dict) else {},
        "output_schema": tool.get("output_schema", {}) if isinstance(tool.get("output_schema"), dict) else {},
        "risk_level": normalize_short_text(tool.get("risk_level"), max_len=24),
        "tenant_eligibility": {
            "allowed_statuses": allowed_statuses,
            "allowed_plan_tiers": allowed_plan_tiers,
            "business_types": business_types,
            "allowed_tenant_ids": allowed_tenant_ids,
            "minimum_onboarding_completion_percent": minimum_completion,
            "require_onboarding_completed": bool(eligibility_raw.get("require_onboarding_completed", False)),
        },
        "required_integrations": required_integrations,
        "status": status,
        "created_at": created_at,
        "updated_at": updated_at,
        "budget_class": normalize_short_text(tool.get("budget_class"), max_len=32),
        "tags": normalize_string_list(tool.get("tags"), max_items=16, max_len=64),
        "supported_business_types": business_types,
    }


def tool_business_type_allowed(business_type: str, allowed_types: list[str]) -> bool:
    if not allowed_types:
        return True
    business_token = normalize_tool_token(business_type)
    if not business_token:
        return False
    allowed_tokens = [normalize_tool_token(item) for item in allowed_types if normalize_tool_token(item)]
    if not allowed_tokens:
        return True
    if business_token in allowed_tokens:
        return True
    for allowed in allowed_tokens:
        if allowed and (allowed in business_token or business_token in allowed):
            return True
    return "other" in allowed_tokens


def evaluate_tool_tenant_eligibility(
    tool_contract: dict[str, Any],
    tenant_context: dict[str, Any] | None,
) -> tuple[bool, str]:
    status = str(tool_contract.get("status") or "enabled").lower()
    if status != "enabled":
        return False, f"tool_status_{status}"
    if tenant_context is None:
        return True, "no_tenant_context"

    tenant = tenant_context.get("tenant") if isinstance(tenant_context.get("tenant"), dict) else {}
    profile = tenant_context.get("profile") if isinstance(tenant_context.get("profile"), dict) else {}
    onboarding = tenant_context.get("onboarding") if isinstance(tenant_context.get("onboarding"), dict) else {}
    eligibility = (
        tool_contract.get("tenant_eligibility")
        if isinstance(tool_contract.get("tenant_eligibility"), dict)
        else {}
    )
    entitlements = resolve_tenant_entitlements(tenant_context)
    entitled_tools = {
        normalize_text(item).lower()
        for item in normalize_list(entitlements.get("enabled_tools"))
        if normalize_text(item)
    }
    tool_id = normalize_text(tool_contract.get("tool_id")).lower()
    if tool_id:
        if entitled_tools and tool_id not in entitled_tools:
            return False, "plan_entitlement_required"
        if bool(entitlements.get("checkout_required")) and not entitled_tools:
            return False, "plan_entitlement_required"

    tenant_id = normalize_optional_onyx_tenant_id(tenant.get("id"))
    allowed_tenant_ids = [
        normalize_optional_onyx_tenant_id(item)
        for item in normalize_list(eligibility.get("allowed_tenant_ids"))
        if normalize_text(item)
    ]
    if allowed_tenant_ids and tenant_id not in allowed_tenant_ids:
        return False, "tenant_not_allowed"

    tenant_status = normalize_text(tenant.get("status")).lower()
    allowed_statuses = [normalize_text(item).lower() for item in normalize_list(eligibility.get("allowed_statuses"))]
    if allowed_statuses and tenant_status not in allowed_statuses:
        return False, "tenant_status_not_allowed"

    plan_tier = normalize_text(tenant.get("planTier")).lower()
    allowed_plan_tiers = [normalize_text(item).lower() for item in normalize_list(eligibility.get("allowed_plan_tiers"))]
    if allowed_plan_tiers and not entitled_tools and plan_tier not in allowed_plan_tiers:
        return False, "plan_tier_not_allowed"

    business_type = normalize_text(profile.get("businessType"))
    allowed_types = [str(item) for item in normalize_list(eligibility.get("business_types"))]
    if allowed_types and not tool_business_type_allowed(business_type, allowed_types):
        return False, "business_type_not_allowed"

    if bool(eligibility.get("require_onboarding_completed", False)) and not bool(onboarding.get("isCompleted", False)):
        return False, "onboarding_incomplete"

    try:
        completion = int(onboarding.get("completionPercent", 0))
    except Exception:
        completion = 0
    try:
        minimum_completion = int(eligibility.get("minimum_onboarding_completion_percent", 0))
    except Exception:
        minimum_completion = 0
    if completion < max(0, min(100, minimum_completion)):
        return False, "onboarding_below_minimum"

    return True, "eligible"


def sanitize_tool_catalog_entry(
    tool: dict[str, Any],
    tenant_context: dict[str, Any] | None = None,
) -> dict[str, Any]:
    contract = normalize_tool_contract(tool)
    eligible, reason = evaluate_tool_tenant_eligibility(contract, tenant_context)
    entitlements = resolve_tenant_entitlements(tenant_context)
    tool_id = normalize_text(contract.get("tool_id"))
    contract["eligible"] = eligible
    contract["eligibility_reason"] = reason
    contract["tenant_plan_id"] = entitlements.get("plan_id") or entitlements.get("selected_plan_id") or ""
    contract["tenant_plan_name"] = entitlements.get("plan_name") or entitlements.get("selected_plan_name") or ""
    contract["billing_status"] = entitlements.get("billing_status") or "inactive"
    contract["checkout_required"] = bool(entitlements.get("checkout_required"))
    contract["plan_entitled"] = tool_id in {normalize_text(item) for item in normalize_list(entitlements.get("enabled_tools"))}
    contract["available_addon_ids"] = normalize_list(
        (entitlements.get("available_addons_by_tool") or {}).get(tool_id)
        if isinstance(entitlements.get("available_addons_by_tool"), dict)
        else []
    )
    return contract


def load_onyx_workspace() -> dict[str, Any]:
    return sanitize_onyx_business_context(read_json(ONYX_TENANT_WORKSPACE_PATH, default=empty_onyx_workspace()))


def resolve_onyx_tenant_context(
    tenant_id: str | None,
    workspace: dict[str, Any] | None = None,
) -> tuple[str, dict[str, Any] | None]:
    workspace_obj = workspace if isinstance(workspace, dict) else load_onyx_workspace()
    requested_id = normalize_optional_onyx_tenant_id(tenant_id)
    active_id = normalize_optional_onyx_tenant_id(workspace_obj.get("activeTenantId"))
    wanted = requested_id or active_id
    for context in normalize_list(workspace_obj.get("contexts")):
        if not isinstance(context, dict):
            continue
        tenant = context.get("tenant") if isinstance(context.get("tenant"), dict) else {}
        context_id = normalize_optional_onyx_tenant_id(tenant.get("id"))
        if context_id == wanted:
            return context_id, context
    return wanted, None


def default_billing_provider_config() -> dict[str, Any]:
    return {
        "version": 1,
        "provider": "stripe",
        "mode": "stub",
        "publishable_key_env": "STRIPE_PUBLISHABLE_KEY",
        "secret_key_env": "STRIPE_SECRET_KEY",
        "webhook_secret_env": "STRIPE_WEBHOOK_SECRET",
        "currency": "USD",
        "success_url": "http://127.0.0.1:5353/",
        "cancel_url": "http://127.0.0.1:5353/",
        "portal_return_url": "http://127.0.0.1:5353/",
        "money_actions_require_approval": True,
    }


def load_billing_provider_config() -> dict[str, Any]:
    default_config = default_billing_provider_config()
    data = read_json(BILLING_PROVIDER_CONFIG_PATH, default=default_config)
    if not isinstance(data, dict):
        data = default_config
    payload = dict(default_config)
    payload.update({key: value for key, value in data.items() if key in payload})
    if not BILLING_PROVIDER_CONFIG_PATH.exists():
        write_json(BILLING_PROVIDER_CONFIG_PATH, payload)
    return payload


def billing_provider_public_summary() -> dict[str, Any]:
    config = load_billing_provider_config()
    publishable_env = normalize_text(config.get("publishable_key_env"))
    secret_env = normalize_text(config.get("secret_key_env"))
    webhook_env = normalize_text(config.get("webhook_secret_env"))
    configured = bool(os.getenv(publishable_env)) and bool(os.getenv(secret_env))
    webhook_configured = bool(os.getenv(webhook_env))
    return {
        "provider": normalize_short_text(config.get("provider"), max_len=40) or "stripe",
        "mode": normalize_short_text(config.get("mode"), max_len=24).lower() or "stub",
        "currency": normalize_short_text(config.get("currency"), max_len=8) or "USD",
        "configured": configured,
        "webhook_configured": webhook_configured,
        "publishable_key_env": publishable_env,
        "secret_key_env": secret_env,
        "webhook_secret_env": webhook_env,
        "money_actions_require_approval": bool(config.get("money_actions_require_approval", True)),
        "success_url": normalize_text(config.get("success_url")),
        "cancel_url": normalize_text(config.get("cancel_url")),
        "portal_return_url": normalize_text(config.get("portal_return_url")),
    }


def normalize_plan_id(value: Any) -> str:
    text = re.sub(r"[^a-z0-9_]+", "_", normalize_text(value).lower()).strip("_")
    return text[:80]


def load_plan_catalog() -> dict[str, Any]:
    data = read_json(TIERS_PATH, default={"version": 2, "default_plan_id": "starter_monthly", "tiers": []})
    if not isinstance(data, dict):
        data = {"version": 2, "default_plan_id": "starter_monthly", "tiers": []}
    plans_out: list[dict[str, Any]] = []
    for item in normalize_list(data.get("tiers") or data.get("plans")):
        if not isinstance(item, dict):
            continue
        plan_name = normalize_short_text(item.get("name") or item.get("tier_name"), max_len=120)
        tier_id = normalize_plan_id(item.get("tier_id") or plan_name)
        plan_id = normalize_plan_id(item.get("plan_id") or f"{tier_id}_{item.get('billing_interval') or 'monthly'}")
        try:
            price_usd = round(float(item.get("price_usd") or item.get("monthly_price_usd") or 0.0), 2)
        except Exception:
            price_usd = 0.0
        billing_interval = normalize_short_text(item.get("billing_interval") or "month", max_len=24).lower() or "month"
        plans_out.append(
            {
                "plan_id": plan_id,
                "tier_id": tier_id,
                "name": plan_name or tier_id.replace("_", " ").title(),
                "description": normalize_short_text(item.get("description") or item.get("notes"), max_len=320),
                "price_usd": max(0.0, price_usd),
                "currency": normalize_short_text(item.get("currency") or data.get("currency") or "USD", max_len=8) or "USD",
                "billing_interval": billing_interval,
                "enabled_tools": normalize_string_list(item.get("enabled_tools") or item.get("included_tools"), max_items=24, max_len=80),
                "enabled_features": normalize_string_list(item.get("enabled_features"), max_items=24, max_len=80),
                "limits": item.get("limits") if isinstance(item.get("limits"), dict) else {},
                "addon_ids": normalize_string_list(item.get("addon_ids") or item.get("add_ons") or item.get("addons"), max_items=24, max_len=80),
                "target_segment": normalize_short_text(item.get("target_segment"), max_len=200),
                "launch_wedge": bool(item.get("launch_wedge", False)),
                "recommended_business_types": normalize_string_list(item.get("recommended_business_types"), max_items=12, max_len=64),
                "allow_without_subscription": bool(item.get("allow_without_subscription", False)),
                "status": normalize_short_text(item.get("status") or "active", max_len=24).lower() or "active",
            }
        )
    if not plans_out:
        plans_out = [
            {
                "plan_id": "starter_monthly",
                "tier_id": "starter",
                "name": "Starter",
                "description": "Core Onyx workspace and rescue planning for solo operators.",
                "price_usd": 29.0,
                "currency": "USD",
                "billing_interval": "month",
                "enabled_tools": ["rescue_plan_v1"],
                "enabled_features": ["invoices", "clients", "tasks"],
                "limits": {"tool_runs_per_month": 20, "active_clients": 50},
                "addon_ids": ["addon_sales_followup_v1", "addon_marketing_pack_v1"],
                "target_segment": "Solo service businesses getting organized.",
                "launch_wedge": False,
                "recommended_business_types": ["service", "consulting", "studio", "other"],
                "allow_without_subscription": False,
                "status": "active",
            },
            {
                "plan_id": "growth_monthly",
                "tier_id": "growth",
                "name": "Growth",
                "description": "Lead follow-up and multi-channel ops for small teams.",
                "price_usd": 79.0,
                "currency": "USD",
                "billing_interval": "month",
                "enabled_tools": ["rescue_plan_v1", "sales_followup_v1"],
                "enabled_features": ["invoices", "clients", "tasks", "deals"],
                "limits": {"tool_runs_per_month": 80, "active_clients": 250},
                "addon_ids": ["addon_marketing_pack_v1"],
                "target_segment": "Small service teams ready to tighten pipeline execution.",
                "launch_wedge": True,
                "recommended_business_types": ["service", "consulting", "agency", "studio"],
                "allow_without_subscription": False,
                "status": "active",
            },
            {
                "plan_id": "founder_monthly",
                "tier_id": "founder",
                "name": "Founder",
                "description": "Full Onyx operator stack for businesses that want guided growth and launch support.",
                "price_usd": 149.0,
                "currency": "USD",
                "billing_interval": "month",
                "enabled_tools": ["rescue_plan_v1", "sales_followup_v1", "marketing_pack_v1"],
                "enabled_features": ["invoices", "clients", "tasks", "deals"],
                "limits": {"tool_runs_per_month": 200, "active_clients": 1000},
                "addon_ids": [],
                "target_segment": "Service businesses using Onyx as an operator cockpit.",
                "launch_wedge": False,
                "recommended_business_types": ["service", "consulting", "agency", "saas", "studio"],
                "allow_without_subscription": False,
                "status": "active",
            },
        ]
    default_plan_id = normalize_plan_id(data.get("default_plan_id") or data.get("default_tier") or plans_out[0].get("plan_id"))
    launch_wedge_plan_id = normalize_plan_id(data.get("launch_wedge_plan_id"))
    if not launch_wedge_plan_id:
        for plan in plans_out:
            if bool(plan.get("launch_wedge")):
                launch_wedge_plan_id = normalize_plan_id(plan.get("plan_id"))
                break
    return {
        "version": int(data.get("version") or 2),
        "default_plan_id": default_plan_id or plans_out[0].get("plan_id"),
        "launch_wedge_plan_id": launch_wedge_plan_id,
        "currency": normalize_short_text(data.get("currency") or "USD", max_len=8) or "USD",
        "tiers": plans_out,
    }


def find_plan_definition(plan_id_or_name: Any) -> dict[str, Any] | None:
    target = normalize_text(plan_id_or_name).lower()
    if not target:
        return None
    catalog = load_plan_catalog()
    for plan in normalize_list(catalog.get("tiers")):
        if not isinstance(plan, dict):
            continue
        if target in {
            normalize_text(plan.get("plan_id")).lower(),
            normalize_text(plan.get("tier_id")).lower(),
            normalize_text(plan.get("name")).lower(),
        }:
            return plan
    return None


def load_addon_catalog() -> dict[str, Any]:
    data = read_json(ADDONS_PATH, default={"version": 2, "addons": []})
    if not isinstance(data, dict):
        data = {"version": 2, "addons": []}
    addons_out: list[dict[str, Any]] = []
    for item in normalize_list(data.get("addons")):
        if not isinstance(item, dict):
            continue
        addon_id = normalize_plan_id(item.get("addon_id") or item.get("tool_id") or item.get("name"))
        try:
            price_usd = round(float(item.get("price_usd") or item.get("monthly_price_usd") or item.get("one_off_price_usd") or 0.0), 2)
        except Exception:
            price_usd = 0.0
        tool_id = normalize_short_text(item.get("tool_id"), max_len=80)
        addons_out.append(
            {
                "addon_id": addon_id,
                "tool_id": tool_id,
                "name": normalize_short_text(item.get("name"), max_len=120) or addon_id.replace("_", " ").title(),
                "description": normalize_short_text(item.get("description"), max_len=320),
                "price_usd": max(0.0, price_usd),
                "billing_interval": normalize_short_text(item.get("billing_interval") or "month", max_len=24).lower() or "month",
                "eligible_plan_ids": normalize_string_list(item.get("eligible_plan_ids"), max_items=24, max_len=80),
                "enabled_tools": normalize_string_list(item.get("enabled_tools") or ([tool_id] if tool_id else []), max_items=24, max_len=80),
                "enabled_features": normalize_string_list(item.get("enabled_features"), max_items=24, max_len=80),
                "status": normalize_short_text(item.get("status") or "active", max_len=24).lower() or "active",
            }
        )
    return {
        "version": int(data.get("version") or 2),
        "addons": addons_out,
    }


def billing_state_path(tenant_id: str) -> Path:
    return ONYX_BILLING_DIR / f"{tenant_id}.json"


def empty_billing_state(tenant_id: str) -> dict[str, Any]:
    now = utc_now_iso()
    return {
        "version": 1,
        "tenant_id": normalize_optional_onyx_tenant_id(tenant_id),
        "customer_id": "",
        "subscription_id": "",
        "provider": "stripe_stub",
        "plan_id": "",
        "status": "inactive",
        "renewal_date": "",
        "last_payment_at": "",
        "created_at": now,
        "updated_at": now,
        "addon_ids": [],
        "billing_interval": "month",
        "currency": "USD",
        "amount_usd": 0.0,
        "checkout_session_id": "",
    }


def normalize_billing_status(value: Any) -> str:
    raw = normalize_short_text(value, max_len=32).lower()
    mapping = {
        "trial": "trialing",
        "paid": "active",
        "cancelled": "canceled",
        "past-due": "past_due",
    }
    raw = mapping.get(raw, raw)
    allowed = {"inactive", "trialing", "active", "past_due", "canceled", "incomplete", "pending_checkout", "unpaid"}
    return raw if raw in allowed else "inactive"


def load_billing_state(tenant_id: str) -> dict[str, Any]:
    safe_tenant_id = normalize_optional_onyx_tenant_id(tenant_id)
    if not safe_tenant_id:
        return empty_billing_state("")
    data = read_json(billing_state_path(safe_tenant_id), default=empty_billing_state(safe_tenant_id))
    if not isinstance(data, dict):
        data = empty_billing_state(safe_tenant_id)
    payload = empty_billing_state(safe_tenant_id)
    payload.update(data)
    payload["tenant_id"] = safe_tenant_id
    payload["provider"] = normalize_short_text(payload.get("provider") or "stripe_stub", max_len=40) or "stripe_stub"
    payload["plan_id"] = normalize_plan_id(payload.get("plan_id"))
    payload["status"] = normalize_billing_status(payload.get("status"))
    payload["customer_id"] = normalize_short_text(payload.get("customer_id"), max_len=80)
    payload["subscription_id"] = normalize_short_text(payload.get("subscription_id"), max_len=80)
    payload["addon_ids"] = normalize_string_list(payload.get("addon_ids"), max_items=24, max_len=80)
    payload["billing_interval"] = normalize_short_text(payload.get("billing_interval") or "month", max_len=24).lower() or "month"
    payload["currency"] = normalize_short_text(payload.get("currency") or "USD", max_len=8) or "USD"
    payload["checkout_session_id"] = normalize_short_text(payload.get("checkout_session_id"), max_len=80)
    try:
        payload["amount_usd"] = round(float(payload.get("amount_usd") or 0.0), 2)
    except Exception:
        payload["amount_usd"] = 0.0
    payload["renewal_date"] = normalize_short_text(payload.get("renewal_date"), max_len=64)
    payload["last_payment_at"] = normalize_short_text(payload.get("last_payment_at"), max_len=64)
    payload["created_at"] = normalize_short_text(payload.get("created_at"), max_len=64) or utc_now_iso()
    payload["updated_at"] = normalize_short_text(payload.get("updated_at"), max_len=64) or payload["created_at"]
    return payload


def save_billing_state(state: dict[str, Any]) -> dict[str, Any]:
    tenant_id = normalize_optional_onyx_tenant_id(state.get("tenant_id"))
    payload = load_billing_state(tenant_id)
    payload.update(state if isinstance(state, dict) else {})
    payload["tenant_id"] = tenant_id
    payload["status"] = normalize_billing_status(payload.get("status"))
    payload["provider"] = normalize_short_text(payload.get("provider") or "stripe_stub", max_len=40) or "stripe_stub"
    payload["plan_id"] = normalize_plan_id(payload.get("plan_id"))
    payload["addon_ids"] = normalize_string_list(payload.get("addon_ids"), max_items=24, max_len=80)
    payload["updated_at"] = utc_now_iso()
    plan = find_plan_definition(payload.get("plan_id"))
    if isinstance(plan, dict):
        payload["billing_interval"] = normalize_short_text(plan.get("billing_interval"), max_len=24).lower() or payload.get("billing_interval") or "month"
        payload["currency"] = normalize_short_text(plan.get("currency"), max_len=8) or payload.get("currency") or "USD"
        try:
            payload["amount_usd"] = round(float(plan.get("price_usd") or 0.0), 2)
        except Exception:
            payload["amount_usd"] = 0.0
    write_json(billing_state_path(tenant_id), payload)
    return payload


def subscription_is_entitled(status: Any) -> bool:
    return normalize_billing_status(status) in {"trialing", "active", "past_due"}


def resolve_tenant_entitlements(tenant_context: dict[str, Any] | None) -> dict[str, Any]:
    if tenant_context is None:
        return {
            "plan_id": "",
            "plan_name": "",
            "selected_plan_id": "",
            "selected_plan_name": "",
            "billing_status": "inactive",
            "entitlement_source": "none",
            "enabled_tools": [],
            "enabled_features": [],
            "addon_ids": [],
            "available_addons_by_tool": {},
            "limits": {},
            "checkout_required": True,
            "subscription": empty_billing_state(""),
        }

    tenant = tenant_context.get("tenant") if isinstance(tenant_context.get("tenant"), dict) else {}
    plan_state = tenant_context.get("plan") if isinstance(tenant_context.get("plan"), dict) else {}
    tenant_id = normalize_optional_onyx_tenant_id(tenant.get("id"))
    billing_state = load_billing_state(tenant_id)
    selected_plan = (
        find_plan_definition(tenant.get("planTier"))
        or find_plan_definition(plan_state.get("currentTier"))
        or find_plan_definition(load_plan_catalog().get("default_plan_id"))
        or {}
    )
    plan = None
    source = "plan_selection"
    if subscription_is_entitled(billing_state.get("status")):
        plan = find_plan_definition(billing_state.get("plan_id"))
        if isinstance(plan, dict):
            source = "billing_subscription"
    if not isinstance(plan, dict):
        plan = selected_plan
    allow_without_subscription = bool(plan.get("allow_without_subscription", False))
    checkout_required = source != "billing_subscription" and not allow_without_subscription
    addon_ids = billing_state.get("addon_ids") if source == "billing_subscription" else []
    enabled_tools: set[str] = set()
    enabled_features: set[str] = set()
    if source == "billing_subscription" or allow_without_subscription:
        enabled_tools = {
            normalize_short_text(item, max_len=80)
            for item in normalize_list(plan.get("enabled_tools"))
            if normalize_text(item)
        }
        enabled_features = {
            normalize_short_text(item, max_len=80)
            for item in normalize_list(plan.get("enabled_features"))
            if normalize_text(item)
        }
    available_addons_by_tool: dict[str, list[str]] = {}
    active_addon_ids = {normalize_plan_id(item) for item in normalize_list(addon_ids) if normalize_text(item)}
    current_plan_id = normalize_plan_id(plan.get("plan_id"))
    plan_addon_ids = {normalize_plan_id(item) for item in normalize_list(plan.get("addon_ids")) if normalize_text(item)}
    for addon in normalize_list(load_addon_catalog().get("addons")):
        if not isinstance(addon, dict):
            continue
        addon_id = normalize_plan_id(addon.get("addon_id"))
        tool_id = normalize_short_text(addon.get("tool_id"), max_len=80)
        eligible_plan_ids = {normalize_plan_id(item) for item in normalize_list(addon.get("eligible_plan_ids")) if normalize_text(item)}
        addon_allowed = (not eligible_plan_ids or current_plan_id in eligible_plan_ids) and (not plan_addon_ids or addon_id in plan_addon_ids)
        if addon_allowed and tool_id:
            available_addons_by_tool.setdefault(tool_id, []).append(addon_id)
        if addon_id in active_addon_ids:
            enabled_tools.update(normalize_string_list(addon.get("enabled_tools"), max_items=24, max_len=80))
            enabled_features.update(normalize_string_list(addon.get("enabled_features"), max_items=24, max_len=80))
    return {
        "plan_id": current_plan_id,
        "plan_name": normalize_short_text(plan.get("name"), max_len=120),
        "selected_plan_id": normalize_plan_id(selected_plan.get("plan_id")),
        "selected_plan_name": normalize_short_text(selected_plan.get("name"), max_len=120),
        "billing_status": normalize_billing_status(billing_state.get("status")),
        "entitlement_source": source,
        "enabled_tools": sorted(enabled_tools),
        "enabled_features": sorted(enabled_features),
        "addon_ids": sorted(active_addon_ids),
        "available_addons_by_tool": available_addons_by_tool,
        "limits": plan.get("limits") if isinstance(plan.get("limits"), dict) else {},
        "checkout_required": checkout_required,
        "subscription": billing_state,
    }


def normalize_billing_interval(value: Any) -> str:
    raw = normalize_short_text(value, max_len=24).lower()
    mapping = {
        "month": "monthly",
        "monthly": "monthly",
        "mo": "monthly",
        "year": "annual",
        "yearly": "annual",
        "annual": "annual",
        "annually": "annual",
        "one_off": "one_off",
        "one-off": "one_off",
    }
    return mapping.get(raw, "monthly")


def interval_days(interval: Any) -> int:
    normalized = normalize_billing_interval(interval)
    if normalized == "annual":
        return 365
    if normalized == "monthly":
        return 30
    return 0


def recurring_monthly_amount(amount_usd: Any, interval: Any) -> float:
    try:
        amount = round(float(amount_usd or 0.0), 2)
    except Exception:
        amount = 0.0
    normalized = normalize_billing_interval(interval)
    if normalized == "annual":
        return round(amount / 12.0, 2)
    if normalized == "monthly":
        return amount
    return 0.0


def load_all_billing_states() -> list[dict[str, Any]]:
    if not ONYX_BILLING_DIR.exists():
        return []
    rows: list[dict[str, Any]] = []
    for path in sorted(ONYX_BILLING_DIR.glob("*.json")):
        state = load_billing_state(path.stem)
        if normalize_optional_onyx_tenant_id(state.get("tenant_id")):
            rows.append(state)
    return rows


def catalog_addons_for_plan(plan_id: Any) -> list[dict[str, Any]]:
    current_plan_id = normalize_plan_id(plan_id)
    addons: list[dict[str, Any]] = []
    for addon in normalize_list(load_addon_catalog().get("addons")):
        if not isinstance(addon, dict):
            continue
        addon_id = normalize_plan_id(addon.get("addon_id"))
        if not addon_id:
            continue
        eligible_plan_ids = {
            normalize_plan_id(item)
            for item in normalize_list(addon.get("eligible_plan_ids"))
            if normalize_text(item)
        }
        if eligible_plan_ids and current_plan_id not in eligible_plan_ids:
            continue
        if normalize_short_text(addon.get("status"), max_len=24).lower() == "disabled":
            continue
        addons.append(addon)
    return addons


def sync_workspace_plan_projection(
    tenant_id: str,
    plan: dict[str, Any] | None,
    enabled_features: list[str] | None = None,
) -> None:
    safe_tenant_id = normalize_optional_onyx_tenant_id(tenant_id)
    if not safe_tenant_id or not isinstance(plan, dict):
        return
    workspace = load_onyx_workspace()
    contexts = [item for item in normalize_list(workspace.get("contexts")) if isinstance(item, dict)]
    updated = False
    now = utc_now_iso()
    for index, context in enumerate(contexts):
        tenant = context.get("tenant") if isinstance(context.get("tenant"), dict) else {}
        if normalize_optional_onyx_tenant_id(tenant.get("id")) != safe_tenant_id:
            continue
        plan_state = context.get("plan") if isinstance(context.get("plan"), dict) else {}
        tenant_updated = dict(tenant)
        plan_updated = dict(plan_state)
        plan_name = normalize_short_text(plan.get("name"), max_len=40) or normalize_short_text(plan.get("tier_id"), max_len=40)
        plan_features = enabled_features if isinstance(enabled_features, list) else normalize_string_list(plan.get("enabled_features"), max_items=32, max_len=64)
        tenant_updated["planTier"] = plan_name or tenant_updated.get("planTier") or "Starter"
        tenant_updated["lastUpdatedAtUtc"] = now
        plan_updated["currentTier"] = plan_name or plan_updated.get("currentTier") or tenant_updated["planTier"]
        plan_updated["enabledFeatures"] = plan_features
        plan_updated["lastUpdatedAtUtc"] = now
        updated_context = dict(context)
        updated_context["tenant"] = tenant_updated
        updated_context["plan"] = plan_updated
        updated_context["lastUpdatedAtUtc"] = now
        contexts[index] = updated_context
        updated = True
        break
    if not updated:
        return
    workspace["contexts"] = contexts
    workspace["lastUpdatedAtUtc"] = now
    sanitized = sanitize_onyx_business_context(workspace)
    write_onyx_business_context_artifacts(sanitized)


def build_tenant_billing_detail(tenant_context: dict[str, Any] | None) -> dict[str, Any]:
    if tenant_context is None:
        provider = billing_provider_public_summary()
        return {
            "tenant_id": "",
            "business_name": "",
            "customer_id": "",
            "subscription_id": "",
            "provider": normalize_short_text(provider.get("provider"), max_len=40) or "stripe",
            "plan_id": "",
            "plan_name": "",
            "selected_plan_id": "",
            "selected_plan_name": "",
            "status": "inactive",
            "renewal_date": "",
            "last_payment_at": "",
            "created_at": "",
            "updated_at": "",
            "billing_interval": "monthly",
            "currency": normalize_short_text(provider.get("currency"), max_len=8) or "USD",
            "amount_usd": 0.0,
            "enabled_tools": [],
            "enabled_features": [],
            "addon_ids": [],
            "available_addons": [],
            "active_addons": [],
            "limits": {},
            "entitlement_source": "none",
            "checkout_required": True,
            "portal_url": "",
        }

    tenant = tenant_context.get("tenant") if isinstance(tenant_context.get("tenant"), dict) else {}
    profile = tenant_context.get("profile") if isinstance(tenant_context.get("profile"), dict) else {}
    tenant_id = normalize_optional_onyx_tenant_id(tenant.get("id"))
    entitlements = resolve_tenant_entitlements(tenant_context)
    subscription = entitlements.get("subscription") if isinstance(entitlements.get("subscription"), dict) else load_billing_state(tenant_id)
    plan = find_plan_definition(entitlements.get("plan_id") or entitlements.get("selected_plan_id")) or {}
    available_addons = catalog_addons_for_plan(entitlements.get("selected_plan_id") or entitlements.get("plan_id"))
    active_addon_ids = {normalize_plan_id(item) for item in normalize_list(entitlements.get("addon_ids")) if normalize_text(item)}
    active_addons = [
        addon
        for addon in available_addons
        if normalize_plan_id(addon.get("addon_id")) in active_addon_ids
    ]
    amount_source = subscription.get("amount_usd")
    if entitlements.get("entitlement_source") != "billing_subscription" and plan:
        amount_source = plan.get("price_usd")
    try:
        amount_usd = round(float(amount_source or plan.get("price_usd") or 0.0), 2)
    except Exception:
        amount_usd = 0.0
    return {
        "tenant_id": tenant_id,
        "business_name": normalize_short_text(profile.get("businessName"), max_len=160),
        "customer_id": normalize_short_text(subscription.get("customer_id"), max_len=80),
        "subscription_id": normalize_short_text(subscription.get("subscription_id"), max_len=80),
        "provider": normalize_short_text(subscription.get("provider"), max_len=40) or "stripe_stub",
        "plan_id": entitlements.get("plan_id") or "",
        "plan_name": entitlements.get("plan_name") or "",
        "selected_plan_id": entitlements.get("selected_plan_id") or "",
        "selected_plan_name": entitlements.get("selected_plan_name") or "",
        "status": entitlements.get("billing_status") or "inactive",
        "renewal_date": normalize_short_text(subscription.get("renewal_date"), max_len=64),
        "last_payment_at": normalize_short_text(subscription.get("last_payment_at"), max_len=64),
        "created_at": normalize_short_text(subscription.get("created_at"), max_len=64),
        "updated_at": normalize_short_text(subscription.get("updated_at"), max_len=64),
        "billing_interval": normalize_billing_interval(subscription.get("billing_interval") or plan.get("billing_interval")),
        "currency": normalize_short_text(subscription.get("currency") or plan.get("currency") or "USD", max_len=8) or "USD",
        "amount_usd": amount_usd,
        "enabled_tools": [item for item in normalize_list(entitlements.get("enabled_tools")) if normalize_text(item)],
        "enabled_features": [item for item in normalize_list(entitlements.get("enabled_features")) if normalize_text(item)],
        "addon_ids": sorted(active_addon_ids),
        "available_addons": available_addons,
        "active_addons": active_addons,
        "limits": entitlements.get("limits") if isinstance(entitlements.get("limits"), dict) else {},
        "entitlement_source": entitlements.get("entitlement_source") or "none",
        "checkout_required": bool(entitlements.get("checkout_required")),
        "portal_url": f"http://127.0.0.1:8000/billing/portal/{tenant_id}" if tenant_id else "",
    }


def build_billing_summary(
    tenant_id: str | None = None,
    tenant_context: dict[str, Any] | None = None,
) -> dict[str, Any]:
    provider = billing_provider_public_summary()
    plan_catalog = load_plan_catalog()
    states = load_all_billing_states()
    by_status: dict[str, int] = {}
    failed_payment_total = 0
    churn_risk_total = 0
    active_subscription_total = 0
    trialing_total = 0
    paid_mrr = 0.0
    active_rows: list[dict[str, Any]] = []
    addon_catalog = {
        normalize_plan_id(addon.get("addon_id")): addon
        for addon in normalize_list(load_addon_catalog().get("addons"))
        if isinstance(addon, dict)
    }
    for state in states:
        status = normalize_billing_status(state.get("status"))
        by_status[status] = by_status.get(status, 0) + 1
        if status == "trialing":
            trialing_total += 1
        if status in {"active", "past_due"}:
            active_subscription_total += 1
        if status in {"past_due", "unpaid"}:
            failed_payment_total += 1
        if status in {"past_due", "unpaid", "canceled"}:
            churn_risk_total += 1
        if status in {"active", "past_due"}:
            plan = find_plan_definition(state.get("plan_id")) or {}
            amount = recurring_monthly_amount(
                state.get("amount_usd") or plan.get("price_usd"),
                state.get("billing_interval") or plan.get("billing_interval"),
            )
            for addon_id in normalize_list(state.get("addon_ids")):
                addon = addon_catalog.get(normalize_plan_id(addon_id))
                if isinstance(addon, dict):
                    amount += recurring_monthly_amount(addon.get("price_usd"), addon.get("billing_interval"))
            paid_mrr += amount
            active_rows.append(
                {
                    "tenant_id": normalize_optional_onyx_tenant_id(state.get("tenant_id")),
                    "plan_id": normalize_plan_id(state.get("plan_id")),
                    "status": status,
                    "amount_usd": round(amount, 2),
                    "renewal_date": normalize_short_text(state.get("renewal_date"), max_len=64),
                }
            )
    tenant_detail = None
    resolved_tenant_id = normalize_optional_onyx_tenant_id(tenant_id)
    if tenant_context is not None:
        tenant_detail = build_tenant_billing_detail(tenant_context)
        resolved_tenant_id = normalize_optional_onyx_tenant_id(tenant_detail.get("tenant_id"))
    elif resolved_tenant_id:
        _, resolved_context = resolve_onyx_tenant_context(resolved_tenant_id)
        tenant_detail = build_tenant_billing_detail(resolved_context)
    else:
        resolved_tenant_id, resolved_context = resolve_onyx_tenant_context(None)
        if resolved_context is not None:
            tenant_detail = build_tenant_billing_detail(resolved_context)
    payload = {
        "ok": True,
        "generated_at_utc": utc_now_iso(),
        "provider": provider,
        "default_plan_id": plan_catalog.get("default_plan_id") or "",
        "launch_wedge_plan_id": plan_catalog.get("launch_wedge_plan_id") or "",
        "plans": [plan for plan in normalize_list(plan_catalog.get("tiers")) if isinstance(plan, dict)],
        "addons": [addon for addon in normalize_list(load_addon_catalog().get("addons")) if isinstance(addon, dict)],
        "subscription_counts": {
            "total": len(states),
            "active": active_subscription_total,
            "trialing": trialing_total,
            "past_due": int(by_status.get("past_due") or 0),
            "inactive": int(by_status.get("inactive") or 0),
            "pending_checkout": int(by_status.get("pending_checkout") or 0),
            "canceled": int(by_status.get("canceled") or 0),
            "unpaid": int(by_status.get("unpaid") or 0),
            "incomplete": int(by_status.get("incomplete") or 0),
        },
        "revenue": {
            "currency": normalize_short_text(provider.get("currency"), max_len=8) or "USD",
            "mrr_usd": round(paid_mrr, 2),
            "arr_usd": round(paid_mrr * 12.0, 2),
        },
        "failed_payment_total": failed_payment_total,
        "churn_risk_total": churn_risk_total,
        "money_actions_require_approval": bool(provider.get("money_actions_require_approval", True)),
        "provider_configured": bool(provider.get("configured")),
        "active_subscriptions": active_rows[:12],
        "tenant_id": resolved_tenant_id or "",
        "tenant": tenant_detail,
        "artifact_path": str(BILLING_SUMMARY_PATH),
    }
    write_json(BILLING_SUMMARY_PATH, payload)
    return payload


def sanitize_billing_session_id(value: Any) -> str:
    text = re.sub(r"[^A-Za-z0-9_\-]+", "", normalize_text(value))
    return text[:96]


def billing_session_path(session_id: str) -> Path:
    return BILLING_SESSIONS_DIR / f"{session_id}.json"


def load_billing_session(session_id: str) -> dict[str, Any] | None:
    safe_session_id = sanitize_billing_session_id(session_id)
    if not safe_session_id:
        return None
    data = read_json(billing_session_path(safe_session_id), default=None)
    return data if isinstance(data, dict) else None


def save_billing_session(session: dict[str, Any]) -> dict[str, Any]:
    session_id = sanitize_billing_session_id(session.get("session_id"))
    if not session_id:
        raise ValueError("missing_session_id")
    payload = dict(session)
    payload["session_id"] = session_id
    payload["updated_at_utc"] = utc_now_iso()
    write_json(billing_session_path(session_id), payload)
    return payload


def build_checkout_success_url(session_id: str) -> str:
    return f"http://127.0.0.1:8000/billing/checkout/{session_id}/complete?outcome=success"


def build_checkout_cancel_url(session_id: str) -> str:
    return f"http://127.0.0.1:8000/billing/checkout/{session_id}/complete?outcome=canceled"


def create_billing_checkout_session(
    tenant_context: dict[str, Any],
    plan: dict[str, Any],
    *,
    success_url: str = "",
    cancel_url: str = "",
) -> dict[str, Any]:
    tenant = tenant_context.get("tenant") if isinstance(tenant_context.get("tenant"), dict) else {}
    profile = tenant_context.get("profile") if isinstance(tenant_context.get("profile"), dict) else {}
    tenant_id = normalize_optional_onyx_tenant_id(tenant.get("id"))
    provider = billing_provider_public_summary()
    session_id = f"chk_{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}_{uuid4().hex[:8]}"
    checkout_url = f"http://127.0.0.1:8000/billing/checkout/{session_id}"
    session = {
        "version": 1,
        "session_id": session_id,
        "tenant_id": tenant_id,
        "tenant_name": normalize_short_text(profile.get("businessName"), max_len=160) or tenant_id,
        "provider": f"{provider.get('provider')}_{provider.get('mode')}",
        "provider_mode": provider.get("mode"),
        "plan_id": normalize_plan_id(plan.get("plan_id")),
        "plan_name": normalize_short_text(plan.get("name"), max_len=120),
        "amount_usd": round(float(plan.get("price_usd") or 0.0), 2),
        "currency": normalize_short_text(plan.get("currency") or provider.get("currency"), max_len=8) or "USD",
        "billing_interval": normalize_billing_interval(plan.get("billing_interval")),
        "status": "created",
        "created_at_utc": utc_now_iso(),
        "updated_at_utc": utc_now_iso(),
        "success_url": success_url or normalize_text(provider.get("success_url")) or "http://127.0.0.1:5353/",
        "cancel_url": cancel_url or normalize_text(provider.get("cancel_url")) or "http://127.0.0.1:5353/",
        "checkout_url": checkout_url,
    }
    save_billing_session(session)
    save_billing_state(
        {
            "tenant_id": tenant_id,
            "provider": session["provider"],
            "plan_id": session["plan_id"],
            "status": "pending_checkout",
            "checkout_session_id": session_id,
        }
    )
    append_platform_audit_event(
        event_type="billing_sensitive_action",
        actor_role="tenant_admin",
        actor_id=tenant_id,
        tenant_id=tenant_id,
        resource_type="subscription",
        resource_id=session["plan_id"],
        action="create_checkout_session",
        outcome="pending_checkout",
        risk_level="R2",
        details={
            "session_id": session_id,
            "provider_mode": session.get("provider_mode"),
            "amount_usd": session.get("amount_usd"),
        },
    )
    build_billing_summary(tenant_id=tenant_id, tenant_context=tenant_context)
    return session


def complete_billing_checkout_session(session_id: str, outcome: str) -> tuple[dict[str, Any] | None, dict[str, Any] | None]:
    session = load_billing_session(session_id)
    if not isinstance(session, dict):
        return None, None
    safe_outcome = normalize_short_text(outcome, max_len=24).lower() or "canceled"
    tenant_id = normalize_optional_onyx_tenant_id(session.get("tenant_id"))
    _, tenant_context = resolve_onyx_tenant_context(tenant_id)
    plan = find_plan_definition(session.get("plan_id")) or {}
    now = utc_now_iso()
    if safe_outcome == "success":
        renewal_days = interval_days(session.get("billing_interval"))
        renewal_date = ""
        if renewal_days > 0:
            renewal_date = (datetime.now(timezone.utc) + timedelta(days=renewal_days)).isoformat().replace("+00:00", "Z")
        existing_state = load_billing_state(tenant_id)
        customer_id = normalize_short_text(existing_state.get("customer_id"), max_len=80) or f"cust_{uuid4().hex[:10]}"
        subscription_id = normalize_short_text(existing_state.get("subscription_id"), max_len=80) or f"sub_{uuid4().hex[:10]}"
        saved_state = save_billing_state(
            {
                "tenant_id": tenant_id,
                "customer_id": customer_id,
                "subscription_id": subscription_id,
                "provider": normalize_short_text(session.get("provider"), max_len=40) or "stripe_stub",
                "plan_id": normalize_plan_id(session.get("plan_id")),
                "status": "active",
                "renewal_date": renewal_date,
                "last_payment_at": now,
                "checkout_session_id": sanitize_billing_session_id(session_id),
            }
        )
        if tenant_context is not None and isinstance(plan, dict):
            tenant_detail = build_tenant_billing_detail(tenant_context)
            sync_workspace_plan_projection(
                tenant_id,
                plan,
                enabled_features=normalize_string_list(tenant_detail.get("enabled_features"), max_items=32, max_len=64),
            )
        session["status"] = "completed"
        session["completed_at_utc"] = now
        save_billing_session(session)
        append_platform_audit_event(
            event_type="billing_sensitive_action",
            actor_role="tenant_admin",
            actor_id=tenant_id,
            tenant_id=tenant_id,
            resource_type="subscription",
            resource_id=normalize_plan_id(session.get("plan_id")),
            action="complete_checkout",
            outcome="active",
            risk_level="R2",
            details={"session_id": session_id, "subscription_id": saved_state.get("subscription_id")},
        )
        build_billing_summary(tenant_id=tenant_id, tenant_context=tenant_context)
        return session, saved_state

    saved_state = save_billing_state(
        {
            "tenant_id": tenant_id,
            "provider": normalize_short_text(session.get("provider"), max_len=40) or "stripe_stub",
            "plan_id": normalize_plan_id(session.get("plan_id")),
            "status": "inactive",
            "checkout_session_id": "",
        }
    )
    session["status"] = "canceled"
    session["completed_at_utc"] = now
    save_billing_session(session)
    append_platform_audit_event(
        event_type="billing_sensitive_action",
        actor_role="tenant_admin",
        actor_id=tenant_id,
        tenant_id=tenant_id,
        resource_type="subscription",
        resource_id=normalize_plan_id(session.get("plan_id")),
        action="complete_checkout",
        outcome="canceled",
        risk_level="R2",
        details={"session_id": session_id},
    )
    build_billing_summary(tenant_id=tenant_id, tenant_context=tenant_context)
    return session, saved_state


def apply_billing_webhook_event(payload: BillingWebhookRequest) -> dict[str, Any]:
    tenant_id = normalize_optional_onyx_tenant_id(payload.tenant_id)
    if not tenant_id:
        return {"ok": False, "error": "tenant_not_found"}
    event_type = normalize_short_text(payload.event_type, max_len=64).lower()
    current_state = load_billing_state(tenant_id)
    status = normalize_billing_status(payload.status or current_state.get("status"))
    if event_type in {"checkout.session.completed", "invoice.paid", "customer.subscription.created"} and status == "inactive":
        status = "active"
    elif event_type == "invoice.payment_failed":
        status = "past_due"
    elif event_type in {"customer.subscription.deleted", "customer.subscription.canceled"}:
        status = "canceled"
    plan_id = normalize_plan_id(payload.plan_id or current_state.get("plan_id"))
    saved_state = save_billing_state(
        {
            "tenant_id": tenant_id,
            "customer_id": normalize_short_text(payload.customer_id or current_state.get("customer_id"), max_len=80),
            "subscription_id": normalize_short_text(payload.subscription_id or current_state.get("subscription_id"), max_len=80),
            "provider": normalize_short_text(payload.provider or current_state.get("provider") or "stripe_stub", max_len=40),
            "plan_id": plan_id,
            "status": status,
            "renewal_date": normalize_short_text(payload.renewal_date or current_state.get("renewal_date"), max_len=64),
            "last_payment_at": normalize_short_text(payload.last_payment_at or current_state.get("last_payment_at"), max_len=64),
            "addon_ids": (
                [normalize_plan_id(item) for item in payload.addon_ids if normalize_text(item)]
                if payload.addon_ids
                else normalize_string_list(current_state.get("addon_ids"), max_items=24, max_len=80)
            ),
            "checkout_session_id": normalize_short_text(payload.session_id or current_state.get("checkout_session_id"), max_len=80),
        }
    )
    _, tenant_context = resolve_onyx_tenant_context(tenant_id)
    plan = find_plan_definition(plan_id)
    if subscription_is_entitled(saved_state.get("status")) and isinstance(plan, dict):
        tenant_detail = build_tenant_billing_detail(tenant_context)
        sync_workspace_plan_projection(
            tenant_id,
            plan,
            enabled_features=normalize_string_list(tenant_detail.get("enabled_features"), max_items=32, max_len=64),
        )
    append_platform_audit_event(
        event_type="billing_sensitive_action",
        actor_role="mason_internal",
        actor_id="billing_webhook",
        tenant_id=tenant_id,
        resource_type="subscription",
        resource_id=plan_id or tenant_id,
        action=event_type or "webhook",
        outcome=saved_state.get("status") or "inactive",
        risk_level="R2",
        details={"session_id": payload.session_id, "metadata": payload.metadata},
    )
    summary = build_billing_summary(tenant_id=tenant_id, tenant_context=tenant_context)
    return {
        "ok": True,
        "tenant_id": tenant_id,
        "status": saved_state.get("status"),
        "subscription": saved_state,
        "summary": summary,
    }


def render_billing_checkout_page(session: dict[str, Any]) -> str:
    session_id = sanitize_billing_session_id(session.get("session_id"))
    tenant_name = html_lib.escape(normalize_short_text(session.get("tenant_name"), max_len=160) or "Tenant")
    plan_name = html_lib.escape(normalize_short_text(session.get("plan_name"), max_len=120) or "Plan")
    amount = round(float(session.get("amount_usd") or 0.0), 2)
    currency = html_lib.escape(normalize_short_text(session.get("currency"), max_len=8) or "USD")
    interval = html_lib.escape(normalize_billing_interval(session.get("billing_interval")))
    status = html_lib.escape(normalize_short_text(session.get("status"), max_len=24) or "created")
    success_href = html_lib.escape(build_checkout_success_url(session_id))
    cancel_href = html_lib.escape(build_checkout_cancel_url(session_id))
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Onyx Billing Checkout</title>
  <style>
    body {{ font-family: Segoe UI, Arial, sans-serif; background: #f6f4ef; color: #1c1f24; margin: 0; padding: 32px; }}
    .panel {{ max-width: 720px; margin: 0 auto; background: #ffffff; border: 1px solid #d9d3c7; border-radius: 16px; padding: 24px; box-shadow: 0 12px 30px rgba(0,0,0,0.08); }}
    .eyebrow {{ font-size: 12px; letter-spacing: 0.08em; text-transform: uppercase; color: #816c4f; }}
    h1 {{ margin: 8px 0 16px; font-size: 30px; }}
    .grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px; margin: 16px 0 24px; }}
    .tile {{ border: 1px solid #e6dfd2; border-radius: 12px; padding: 12px; background: #fbfaf7; }}
    .actions {{ display: flex; gap: 12px; flex-wrap: wrap; margin-top: 24px; }}
    .btn {{ display: inline-block; padding: 12px 18px; border-radius: 999px; text-decoration: none; font-weight: 600; }}
    .btn-primary {{ background: #0f6c5b; color: white; }}
    .btn-secondary {{ background: #ece6da; color: #1c1f24; }}
    .note {{ margin-top: 18px; color: #5c6470; line-height: 1.5; }}
  </style>
</head>
<body>
  <div class="panel">
    <div class="eyebrow">Stub Billing Checkout</div>
    <h1>{tenant_name}</h1>
    <p>This is a local billing stub. No card details are collected or stored here. Use it to confirm the plan entitlement flow before wiring a live provider.</p>
    <div class="grid">
      <div class="tile"><strong>Plan</strong><br>{plan_name}</div>
      <div class="tile"><strong>Price</strong><br>{currency} {amount:.2f} / {interval}</div>
      <div class="tile"><strong>Session</strong><br>{html_lib.escape(session_id)}</div>
      <div class="tile"><strong>Status</strong><br>{status}</div>
    </div>
    <div class="actions">
      <a class="btn btn-primary" href="{success_href}">Confirm test checkout</a>
      <a class="btn btn-secondary" href="{cancel_href}">Cancel</a>
    </div>
    <p class="note">Completing this stub session writes tenant billing state and updates plan entitlements locally. Mason can read the resulting billing summary, but money actions stay approval-gated.</p>
  </div>
</body>
</html>"""


def render_billing_portal_page(detail: dict[str, Any]) -> str:
    tenant_name = html_lib.escape(normalize_short_text(detail.get("business_name") or detail.get("tenant_id"), max_len=160) or "Tenant")
    enabled_tools = "".join(f"<li>{html_lib.escape(normalize_short_text(item, max_len=120))}</li>" for item in normalize_list(detail.get("enabled_tools")))
    active_addons = "".join(
        f"<li>{html_lib.escape(normalize_short_text(addon.get('name'), max_len=120) or normalize_short_text(addon.get('addon_id'), max_len=120))}</li>"
        for addon in normalize_list(detail.get("active_addons"))
        if isinstance(addon, dict)
    )
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Onyx Billing Portal</title>
  <style>
    body {{ font-family: Segoe UI, Arial, sans-serif; background: #eef3f0; color: #182026; margin: 0; padding: 32px; }}
    .panel {{ max-width: 760px; margin: 0 auto; background: white; border: 1px solid #d7e0da; border-radius: 16px; padding: 24px; box-shadow: 0 12px 30px rgba(0,0,0,0.08); }}
    .grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px; margin: 16px 0 20px; }}
    .tile {{ border: 1px solid #e0e8e2; border-radius: 12px; padding: 12px; background: #f9fbfa; }}
    h1 {{ margin: 0 0 12px; font-size: 28px; }}
    ul {{ margin: 8px 0 0 18px; }}
    .note {{ color: #5d6b63; }}
  </style>
</head>
<body>
  <div class="panel">
    <h1>{tenant_name} billing</h1>
    <p class="note">Local billing portal summary for the current tenant. This keeps money actions visible without enabling uncontrolled billing automation.</p>
    <div class="grid">
      <div class="tile"><strong>Status</strong><br>{html_lib.escape(normalize_short_text(detail.get("status"), max_len=24) or "inactive")}</div>
      <div class="tile"><strong>Plan</strong><br>{html_lib.escape(normalize_short_text(detail.get("plan_name") or detail.get("selected_plan_name"), max_len=120) or "Not subscribed")}</div>
      <div class="tile"><strong>Renewal</strong><br>{html_lib.escape(normalize_short_text(detail.get("renewal_date"), max_len=64) or "n/a")}</div>
      <div class="tile"><strong>Provider</strong><br>{html_lib.escape(normalize_short_text(detail.get("provider"), max_len=40) or "stripe_stub")}</div>
    </div>
    <h2>Enabled tools</h2>
    <ul>{enabled_tools or '<li>No currently entitled tools.</li>'}</ul>
    <h2>Active add-ons</h2>
    <ul>{active_addons or '<li>No active add-ons.</li>'}</ul>
  </div>
</body>
</html>"""


def build_tool_run_input(
    input_payload: dict[str, Any],
    tenant_context: dict[str, Any] | None,
) -> dict[str, Any]:
    output = dict(input_payload or {})
    if tenant_context is None:
        return output

    tenant = tenant_context.get("tenant") if isinstance(tenant_context.get("tenant"), dict) else {}
    profile = tenant_context.get("profile") if isinstance(tenant_context.get("profile"), dict) else {}
    onboarding = tenant_context.get("onboarding") if isinstance(tenant_context.get("onboarding"), dict) else {}
    tenant_id = normalize_optional_onyx_tenant_id(tenant.get("id"))
    services_products = normalize_string_list(profile.get("servicesProducts"), max_items=24, max_len=120)
    pain_points = normalize_string_list(profile.get("painPoints"), max_items=24, max_len=160)
    locations = normalize_string_list(profile.get("locations"), max_items=16, max_len=120)
    current_tools = normalize_string_list(profile.get("currentTools"), max_items=24, max_len=120)
    goals = normalize_string_list(profile.get("goals"), max_items=12, max_len=160)
    operating_area = normalize_short_text(profile.get("operatingArea"), max_len=160)

    defaults: dict[str, Any] = {
        "tenant_id": tenant_id,
        "business_name": normalize_short_text(profile.get("businessName"), max_len=160),
        "business_type": normalize_short_text(profile.get("businessType"), max_len=120),
        "goal": normalize_short_text(profile.get("mainGoal") or (goals[0] if goals else ""), max_len=240),
        "current_issues": pain_points,
        "budget": normalize_short_text(profile.get("budgetSensitivity"), max_len=40),
        "staff_size": normalize_short_text(profile.get("size"), max_len=40),
        "marketing_status": ", ".join(current_tools),
        "audience": operating_area or ", ".join(locations),
        "offers": services_products,
        "sales_pipeline_status": "Active tenant context ready" if bool(onboarding.get("isCompleted", False)) else "Needs qualification",
        "lead_sources": locations,
        "objections": pain_points,
        "risk_tolerance": normalize_short_text(profile.get("riskTolerance"), max_len=40),
        "automation_tolerance": normalize_short_text(profile.get("automationTolerance"), max_len=64),
        "budget_sensitivity": normalize_short_text(profile.get("budgetSensitivity"), max_len=40),
    }

    for key, value in defaults.items():
        current = output.get(key)
        if current is None:
            output[key] = value
            continue
        if isinstance(current, str) and not current.strip():
            output[key] = value
            continue
        if isinstance(current, list) and not current:
            output[key] = value
    return output


def summarize_tool_run(run_dir: Path) -> dict[str, Any]:
    tool_run = read_json(run_dir / "tool_run.json", default={})
    report = read_json(run_dir / "report.json", default={})
    tasks = read_json(run_dir / "tasks.json", default=[])
    artifact = read_json(run_dir / "artifact.json", default={})

    task_count = len(tasks) if isinstance(tasks, list) else 0
    artifact_files: list[str] = []
    if isinstance(artifact, dict):
        for item in normalize_list(artifact.get("artifact_files")):
            if isinstance(item, dict):
                path_value = normalize_text(item.get("path"))
                if path_value:
                    artifact_files.append(path_value)
            else:
                path_value = normalize_text(item)
                if path_value:
                    artifact_files.append(path_value)

    summary = ""
    recommendations: list[str] = []
    output_obj: dict[str, Any] = {}
    if isinstance(report, dict):
        summary = normalize_text(report.get("summary"))
        recommendations = [str(item) for item in normalize_list(report.get("recommendations")) if normalize_text(item)]
    if isinstance(artifact, dict):
        if not summary:
            output_value = artifact.get("output")
            if isinstance(output_value, dict):
                output_obj = output_value
                summary = normalize_text(output_value.get("summary"))
        else:
            output_value = artifact.get("output")
            if isinstance(output_value, dict):
                output_obj = output_value
        if not recommendations:
            recommendations = [str(item) for item in normalize_list(artifact.get("recommendations")) if normalize_text(item)]

    generated_at = ""
    for source in (report, artifact, tool_run):
        if isinstance(source, dict):
            generated_at = normalize_short_text(
                source.get("generated_at_utc") or source.get("created_at_utc"),
                max_len=64,
            )
            if generated_at:
                break

    tool_name = ""
    tenant_id = ""
    tenant_business_name = ""
    if isinstance(tool_run, dict):
        tool_name = normalize_text(tool_run.get("tool_name") or tool_run.get("title"))
        tenant_id = normalize_text(tool_run.get("tenant_id"))
        tenant_business_name = normalize_text(tool_run.get("tenant_business_name"))

    return {
        "run_id": normalize_text(tool_run.get("run_id") if isinstance(tool_run, dict) else run_dir.name) or run_dir.name,
        "tool_id": normalize_text(tool_run.get("tool_id") if isinstance(tool_run, dict) else ""),
        "tool_name": tool_name,
        "tool_version": normalize_text(tool_run.get("tool_version") if isinstance(tool_run, dict) else ""),
        "tenant_id": tenant_id,
        "tenant_business_name": tenant_business_name,
        "workspace_id": normalize_text(tool_run.get("workspace_id") if isinstance(tool_run, dict) else ""),
        "status": normalize_text(artifact.get("status") if isinstance(artifact, dict) else "completed") or "completed",
        "generated_at_utc": generated_at,
        "summary": summary,
        "recommendations": recommendations,
        "task_count": task_count,
        "artifact_path": str(run_dir / "artifact.json"),
        "report_path": str(run_dir / "report.json"),
        "tasks_path": str(run_dir / "tasks.json"),
        "tool_run_path": str(run_dir / "tool_run.json"),
        "artifact_files": artifact_files,
        "output": output_obj,
        "path": str(run_dir),
    }


def text_contains_any(text: str, keywords: list[str]) -> bool:
    lowered = normalize_text(text).lower()
    if not lowered:
        return False
    return any(keyword in lowered for keyword in keywords)


def recommendation_state_path(tenant_id: str) -> Path:
    return ONYX_RECOMMENDATIONS_DIR / f"{tenant_id}.json"


def empty_recommendation_state(tenant_id: str) -> dict[str, Any]:
    return {
        "version": 1,
        "tenant_id": tenant_id,
        "generated_at_utc": "",
        "recommendations": [],
    }


def load_tenant_recommendation_state(tenant_id: str) -> dict[str, Any]:
    safe_tenant_id = normalize_optional_onyx_tenant_id(tenant_id)
    if not safe_tenant_id:
        return empty_recommendation_state("")
    data = read_json(
        recommendation_state_path(safe_tenant_id),
        default=empty_recommendation_state(safe_tenant_id),
    )
    if not isinstance(data, dict):
        return empty_recommendation_state(safe_tenant_id)
    recommendations: list[dict[str, Any]] = []
    for item in normalize_list(data.get("recommendations")):
        if not isinstance(item, dict):
            continue
        clean_item = dict(item)
        clean_item["tenant_id"] = safe_tenant_id
        recommendations.append(clean_item)
    return {
        "version": 1,
        "tenant_id": safe_tenant_id,
        "generated_at_utc": normalize_short_text(data.get("generated_at_utc"), max_len=64),
        "recommendations": recommendations,
    }


def save_tenant_recommendation_state(tenant_id: str, state: dict[str, Any]) -> dict[str, Any]:
    safe_tenant_id = normalize_optional_onyx_tenant_id(tenant_id)
    payload = empty_recommendation_state(safe_tenant_id)
    if isinstance(state, dict):
        payload.update(state)
    payload["tenant_id"] = safe_tenant_id
    recommendations: list[dict[str, Any]] = []
    for item in normalize_list(payload.get("recommendations")):
        if not isinstance(item, dict):
            continue
        clean_item = dict(item)
        clean_item["tenant_id"] = safe_tenant_id
        recommendations.append(clean_item)
    payload["recommendations"] = recommendations
    write_json(recommendation_state_path(safe_tenant_id), payload)
    clear_security_posture_caches()
    return payload


def collect_tenant_tool_runs(tenant_id: str, limit: int = 10) -> list[dict[str, Any]]:
    safe_tenant_id = normalize_optional_onyx_tenant_id(tenant_id)
    if not safe_tenant_id or not TOOL_RUNS_DIR.exists():
        return []
    run_dirs = [p for p in TOOL_RUNS_DIR.iterdir() if p.is_dir()]
    run_dirs.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    runs: list[dict[str, Any]] = []
    for run_dir in run_dirs:
        summary = summarize_tool_run(run_dir)
        if normalize_optional_onyx_tenant_id(summary.get("tenant_id")) != safe_tenant_id:
            continue
        runs.append(summary)
        if len(runs) >= limit:
            break
    return runs


def make_recommendation_id(
    tenant_id: str,
    rec_type: str,
    title: str,
    linked_tool_id: str = "",
) -> str:
    seed = "|".join(
        [
            normalize_optional_onyx_tenant_id(tenant_id),
            normalize_text(rec_type).lower(),
            normalize_text(linked_tool_id).lower(),
            normalize_text(title).lower(),
        ]
    )
    digest = hashlib.sha1(seed.encode("utf-8")).hexdigest()[:12]
    return f"rec_{digest}"


def build_recommendation_record(
    *,
    tenant_id: str,
    rec_type: str,
    title: str,
    description: str,
    reason: str,
    evidence: list[dict[str, Any]],
    priority: int,
    estimated_roi_impact: str,
    risk_level: str,
    linked_tool_id: str = "",
) -> dict[str, Any]:
    now = utc_now_iso()
    recommendation_id = make_recommendation_id(tenant_id, rec_type, title, linked_tool_id)
    clean_evidence: list[dict[str, Any]] = []
    for item in evidence:
        if not isinstance(item, dict):
            continue
        clean_evidence.append(
            {
                "source": normalize_short_text(item.get("source"), max_len=64),
                "label": normalize_short_text(item.get("label"), max_len=120),
                "value": normalize_short_text(item.get("value"), max_len=280),
                "path": normalize_text(item.get("path")),
            }
        )
    return {
        "recommendation_id": recommendation_id,
        "tenant_id": normalize_optional_onyx_tenant_id(tenant_id),
        "type": normalize_short_text(rec_type, max_len=24),
        "title": normalize_short_text(title, max_len=160),
        "description": normalize_short_text(description, max_len=320),
        "reason": normalize_short_text(reason, max_len=320),
        "evidence": clean_evidence,
        "priority": max(0, min(100, int(priority))),
        "estimated_roi_impact": normalize_short_text(estimated_roi_impact, max_len=160),
        "risk_level": normalize_short_text(risk_level, max_len=24),
        "status": "new",
        "linked_tool_id": normalize_short_text(linked_tool_id, max_len=80),
        "created_at": now,
        "updated_at": now,
        "is_current": True,
    }


def recommendation_sort_key(item: dict[str, Any]) -> tuple[int, int, int, str]:
    status_order = {
        "accepted": 0,
        "new": 1,
        "seen": 2,
        "completed": 3,
        "dismissed": 4,
    }
    try:
        priority = int(item.get("priority", 0))
    except Exception:
        priority = 0
    return (
        0 if bool(item.get("is_current", True)) else 1,
        status_order.get(str(item.get("status") or "new").lower(), 9),
        -priority,
        normalize_text(item.get("title")).lower(),
    )


def generate_tenant_recommendation_candidates(tenant_id: str) -> list[dict[str, Any]]:
    safe_tenant_id, tenant_context = resolve_onyx_tenant_context(tenant_id)
    if not safe_tenant_id or tenant_context is None:
        return []

    tenant = tenant_context.get("tenant") if isinstance(tenant_context.get("tenant"), dict) else {}
    profile = tenant_context.get("profile") if isinstance(tenant_context.get("profile"), dict) else {}
    onboarding = tenant_context.get("onboarding") if isinstance(tenant_context.get("onboarding"), dict) else {}

    available_tools: dict[str, dict[str, Any]] = {}
    for tool in load_tool_registry_entries():
        entry = sanitize_tool_catalog_entry(tool, tenant_context)
        if bool(entry.get("eligible")) and str(entry.get("status") or "").lower() == "enabled":
            available_tools[str(entry.get("tool_id"))] = entry

    latest_runs = collect_tenant_tool_runs(safe_tenant_id, limit=8)
    latest_by_tool: dict[str, dict[str, Any]] = {}
    for run in latest_runs:
        tool_id = normalize_text(run.get("tool_id"))
        if tool_id and tool_id not in latest_by_tool:
            latest_by_tool[tool_id] = run

    business_type = normalize_text(profile.get("businessType"))
    main_goal = normalize_text(profile.get("mainGoal"))
    goal_items = normalize_string_list(profile.get("goals"), max_items=12, max_len=200)
    growth_priorities = normalize_string_list(profile.get("growthPriorities"), max_items=12, max_len=200)
    current_tools = normalize_string_list(profile.get("currentTools"), max_items=12, max_len=120)
    pain_points = [
        item
        for item in normalize_string_list(profile.get("painPoints"), max_items=12, max_len=200)
        if normalize_text(item).lower() not in {"none", "n/a", "na", "no", "nothing"}
    ]
    combined_goal_text = " ".join([main_goal, *goal_items, *growth_priorities])
    combined_pain_text = " ".join(pain_points)

    rescue_run = latest_by_tool.get("rescue_plan_v1")
    rescue_output = rescue_run.get("output") if isinstance(rescue_run.get("output"), dict) else {}
    rescue_risks = normalize_string_list(rescue_output.get("top_risks"), max_items=8, max_len=200)
    rescue_tasks = [
        normalize_short_text(item.get("title"), max_len=160)
        for item in normalize_list(rescue_output.get("tasks"))
        if isinstance(item, dict) and normalize_text(item.get("title"))
    ]

    marketing_run = latest_by_tool.get("marketing_pack_v1")
    sales_run = latest_by_tool.get("sales_followup_v1")
    recommendations: list[dict[str, Any]] = []

    if not bool(onboarding.get("isCompleted", False)):
        recommendations.append(
            build_recommendation_record(
                tenant_id=safe_tenant_id,
                rec_type="action",
                title="Finish tenant onboarding",
                description="Complete the remaining onboarding steps so Mason can rank tools with better context.",
                reason="Onboarding is incomplete, which limits recommendation quality.",
                evidence=[
                    {
                        "source": "onboarding",
                        "label": "Completion",
                        "value": f"{int(onboarding.get('completionPercent', 0) or 0)}%",
                        "path": "",
                    }
                ],
                priority=96,
                estimated_roi_impact="High: better recommendation quality and less manual triage.",
                risk_level="R1",
            )
        )

    if not rescue_run and "rescue_plan_v1" in available_tools:
        pain_value = pain_points[0] if pain_points else main_goal or business_type or "New tenant context"
        recommendations.append(
            build_recommendation_record(
                tenant_id=safe_tenant_id,
                rec_type="tool",
                title="Run Rescue Plan",
                description="Generate a first-pass stabilization plan for this tenant before expanding workflows.",
                reason="No Rescue Plan artifact exists yet for this tenant.",
                evidence=[
                    {
                        "source": "business_profile",
                        "label": "Primary signal",
                        "value": pain_value,
                        "path": str(ONYX_TENANTS_DIR / f"{safe_tenant_id}.json"),
                    }
                ],
                priority=94 if pain_points else 82,
                estimated_roi_impact="High: clearer priorities and faster owner assignment.",
                risk_level="R1",
                linked_tool_id="rescue_plan_v1",
            )
        )

    if rescue_run and rescue_tasks:
        recommendations.append(
            build_recommendation_record(
                tenant_id=safe_tenant_id,
                rec_type="workflow",
                title="Execute the latest Rescue Plan checklist",
                description="Review the pending Rescue Plan tasks and assign owners before starting more tooling work.",
                reason="The latest Rescue Plan artifact still has open tasks.",
                evidence=[
                    {
                        "source": "tool_artifact",
                        "label": "Latest task",
                        "value": rescue_tasks[0],
                        "path": normalize_text(rescue_run.get("artifact_path")),
                    }
                ],
                priority=91,
                estimated_roi_impact="High: faster execution against the current stabilization plan.",
                risk_level="R1",
            )
        )

    sales_signal = (
        text_contains_any(combined_goal_text, ["sales", "pipeline", "lead", "revenue", "close"])
        or text_contains_any(combined_pain_text, ["follow-up", "follow up", "pipeline", "conversion", "lead"])
        or text_contains_any(" ".join(rescue_risks), ["follow-up", "follow up", "intake", "pipeline", "lead"])
    )
    if sales_signal and "sales_followup_v1" in available_tools and not sales_run:
        evidence_items = []
        if rescue_risks:
            evidence_items.append(
                {
                    "source": "tool_artifact",
                    "label": "Latest rescue risk",
                    "value": rescue_risks[0],
                    "path": normalize_text(rescue_run.get("artifact_path") if rescue_run else ""),
                }
            )
        elif pain_points:
            evidence_items.append(
                {
                    "source": "business_profile",
                    "label": "Pain point",
                    "value": pain_points[0],
                    "path": str(ONYX_TENANTS_DIR / f"{safe_tenant_id}.json"),
                }
            )
        recommendations.append(
            build_recommendation_record(
                tenant_id=safe_tenant_id,
                rec_type="tool",
                title="Run Sales Follow-Up",
                description="Create a tenant-specific follow-up sequence for leads, objections, and pipeline movement.",
                reason="Sales friction is visible in the current tenant state or latest Rescue Plan output.",
                evidence=evidence_items,
                priority=88,
                estimated_roi_impact="High: less revenue leakage from slow or inconsistent follow-up.",
                risk_level="R1",
                linked_tool_id="sales_followup_v1",
            )
        )

    marketing_signal = (
        text_contains_any(combined_goal_text, ["marketing", "brand", "audience", "campaign", "visibility", "traffic", "grow"])
        or text_contains_any(" ".join(growth_priorities), ["grow", "reach", "visibility", "lead"])
        or (not marketing_run and not text_contains_any(" ".join(current_tools), ["mailchimp", "hubspot", "ads", "seo", "social"]))
    )
    if marketing_signal and "marketing_pack_v1" in available_tools and not marketing_run:
        signal_value = goal_items[0] if goal_items else growth_priorities[0] if growth_priorities else main_goal
        recommendations.append(
            build_recommendation_record(
                tenant_id=safe_tenant_id,
                rec_type="tool",
                title="Run Marketing Pack",
                description="Build message pillars and a campaign outline that fit this tenant's business profile.",
                reason="Growth or audience-building signals are present, and no current Marketing Pack artifact exists.",
                evidence=[
                    {
                        "source": "business_profile",
                        "label": "Goal signal",
                        "value": signal_value or business_type or "Growth priority detected",
                        "path": str(ONYX_TENANTS_DIR / f"{safe_tenant_id}.json"),
                    }
                ],
                priority=76,
                estimated_roi_impact="Medium: faster campaign launch and clearer messaging.",
                risk_level="R1",
                linked_tool_id="marketing_pack_v1",
            )
        )

    return recommendations


def merge_recommendation_state(
    tenant_id: str,
    generated_recommendations: list[dict[str, Any]],
) -> dict[str, Any]:
    safe_tenant_id = normalize_optional_onyx_tenant_id(tenant_id)
    now = utc_now_iso()
    existing_state = load_tenant_recommendation_state(safe_tenant_id)
    existing_map = {
        normalize_text(item.get("recommendation_id")): item
        for item in existing_state.get("recommendations", [])
        if isinstance(item, dict)
    }
    generated_ids: set[str] = set()
    merged: list[dict[str, Any]] = []

    for item in generated_recommendations:
        recommendation_id = normalize_text(item.get("recommendation_id"))
        if not recommendation_id:
            continue
        generated_ids.add(recommendation_id)
        prior = existing_map.get(recommendation_id)
        merged_item = dict(item)
        merged_item["is_current"] = True
        if isinstance(prior, dict):
            merged_item["status"] = normalize_short_text(prior.get("status") or "new", max_len=24) or "new"
            merged_item["created_at"] = normalize_short_text(prior.get("created_at") or item.get("created_at"), max_len=64)
            merged_item["updated_at"] = now if any(
                normalize_text(prior.get(field)) != normalize_text(item.get(field))
                for field in (
                    "type",
                    "title",
                    "description",
                    "reason",
                    "priority",
                    "estimated_roi_impact",
                    "risk_level",
                    "linked_tool_id",
                )
            ) else normalize_short_text(prior.get("updated_at") or item.get("updated_at"), max_len=64)
        merged.append(merged_item)

    for recommendation_id, prior in existing_map.items():
        if recommendation_id in generated_ids:
            continue
        stale_item = dict(prior)
        stale_item["is_current"] = False
        merged.append(stale_item)

    merged.sort(key=recommendation_sort_key)
    return save_tenant_recommendation_state(
        safe_tenant_id,
        {
            "version": 1,
            "tenant_id": safe_tenant_id,
            "generated_at_utc": now,
            "recommendations": merged,
        },
    )


def refresh_tenant_recommendations(tenant_id: str) -> dict[str, Any]:
    generated = generate_tenant_recommendation_candidates(tenant_id)
    return merge_recommendation_state(tenant_id, generated)


def update_tenant_recommendation_status(
    tenant_id: str,
    recommendation_id: str,
    status: str,
) -> dict[str, Any] | None:
    safe_tenant_id = normalize_optional_onyx_tenant_id(tenant_id)
    normalized_status = normalize_short_text(status, max_len=24).lower()
    if normalized_status not in {"new", "seen", "accepted", "dismissed", "completed"}:
        return None
    state = load_tenant_recommendation_state(safe_tenant_id)
    recommendations = [item for item in state.get("recommendations", []) if isinstance(item, dict)]
    updated = False
    for item in recommendations:
        if normalize_text(item.get("recommendation_id")) != normalize_text(recommendation_id):
            continue
        item["status"] = normalized_status
        item["updated_at"] = utc_now_iso()
        updated = True
        break
    if not updated:
        return None
    recommendations.sort(key=recommendation_sort_key)
    state["recommendations"] = recommendations
    state["generated_at_utc"] = normalize_short_text(state.get("generated_at_utc"), max_len=64) or utc_now_iso()
    saved_state = save_tenant_recommendation_state(safe_tenant_id, state)
    updated_item = None
    for item in recommendations:
        if normalize_text(item.get("recommendation_id")) == normalize_text(recommendation_id):
            updated_item = item
            break
    append_platform_audit_event(
        event_type="recommendation_action",
        actor_role="tenant_admin",
        actor_id=safe_tenant_id,
        tenant_id=safe_tenant_id,
        resource_type="recommendation",
        resource_id=recommendation_id,
        action="status_update",
        outcome=normalized_status,
        risk_level=normalize_short_text((updated_item or {}).get("risk_level"), max_len=24),
        details={
            "title": normalize_short_text((updated_item or {}).get("title"), max_len=160),
            "linked_tool_id": normalize_short_text((updated_item or {}).get("linked_tool_id"), max_len=80),
        },
    )
    return saved_state


def normalize_improvement_target_type(value: Any) -> str:
    allowed = {"mason", "onyx", "athena", "tool", "security", "system", "business"}
    text = normalize_short_text(value, max_len=32).lower()
    return text if text in allowed else "system"


def normalize_improvement_source(value: Any) -> str:
    allowed = {"runtime", "recommendation", "competitor", "owner", "manual", "self-heal", "tool-gap"}
    text = normalize_short_text(value, max_len=32).lower()
    return text if text in allowed else "manual"


def normalize_improvement_status(value: Any) -> str:
    raw = normalize_short_text(value, max_len=32).lower()
    mapping = {
        "approved": "planned",
        "queued": "triaged",
        "executed": "completed",
        "rejected": "dismissed",
        "in-progress": "in_progress",
    }
    raw = mapping.get(raw, raw)
    allowed = {
        "new",
        "triaged",
        "planned",
        "in_progress",
        "blocked",
        "completed",
        "reverted",
        "dismissed",
    }
    return raw if raw in allowed else "new"


def empty_improvement_queue_state() -> dict[str, Any]:
    return {
        "version": 1,
        "updated_at_utc": "",
        "items": [],
    }


def load_improvement_queue_state() -> dict[str, Any]:
    data = read_json(IMPROVEMENT_QUEUE_PATH, default=empty_improvement_queue_state())
    if not isinstance(data, dict):
        return empty_improvement_queue_state()
    items = [item for item in normalize_list(data.get("items")) if isinstance(item, dict)]
    return {
        "version": 1,
        "updated_at_utc": normalize_short_text(data.get("updated_at_utc"), max_len=64),
        "items": items,
    }


def save_improvement_queue_state(state: dict[str, Any]) -> dict[str, Any]:
    payload = empty_improvement_queue_state()
    if isinstance(state, dict):
        payload.update(state)
    payload["version"] = 1
    payload["updated_at_utc"] = normalize_short_text(payload.get("updated_at_utc"), max_len=64) or utc_now_iso()
    items = [item for item in normalize_list(payload.get("items")) if isinstance(item, dict)]
    items.sort(key=improvement_sort_key)
    payload["items"] = items
    write_json(IMPROVEMENT_QUEUE_PATH, payload)
    write_json(IMPROVEMENT_QUEUE_REPORT_PATH, payload)
    return payload


def sanitize_improvement_evidence(evidence: Any) -> list[dict[str, Any]]:
    output: list[dict[str, Any]] = []
    for item in normalize_list(evidence):
        if not isinstance(item, dict):
            continue
        output.append(
            {
                "source": normalize_short_text(item.get("source"), max_len=64),
                "label": normalize_short_text(item.get("label"), max_len=120),
                "value": normalize_short_text(item.get("value"), max_len=280),
                "path": normalize_text(item.get("path")),
            }
        )
    return output


def improvement_history_event(
    *,
    action: str,
    status: str,
    source: str,
    note: str = "",
) -> dict[str, Any]:
    return {
        "at_utc": utc_now_iso(),
        "action": normalize_short_text(action, max_len=40),
        "status": normalize_improvement_status(status),
        "source": normalize_improvement_source(source),
        "note": normalize_short_text(note, max_len=240),
    }


def make_improvement_id(
    *,
    source: str,
    target_type: str,
    target_id: str,
    title: str,
    linked_tenant_id: str = "",
    linked_behavior_id: str = "",
) -> str:
    seed = "|".join(
        [
            normalize_improvement_source(source),
            normalize_improvement_target_type(target_type),
            normalize_text(target_id).lower(),
            normalize_text(title).lower(),
            normalize_optional_onyx_tenant_id(linked_tenant_id),
            normalize_text(linked_behavior_id).lower(),
        ]
    )
    return f"imp_{hashlib.sha1(seed.encode('utf-8')).hexdigest()[:12]}"


def should_improvement_require_approval(target_type: str, risk_level: str) -> bool:
    target_value = normalize_improvement_target_type(target_type)
    risk_value = normalize_short_text(risk_level, max_len=24).upper() or "R1"
    if target_value in {"security", "system", "athena"}:
        return True
    return risk_value not in {"R0", "R1"}


def build_improvement_item(
    *,
    target_type: str,
    target_id: str,
    title: str,
    description: str,
    source: str,
    reason: str,
    evidence: list[dict[str, Any]],
    expected_outcome: str,
    priority: int,
    risk_level: str,
    status: str = "new",
    approval_required: bool | None = None,
    linked_behavior_id: str = "",
    linked_tenant_id: str = "",
) -> dict[str, Any]:
    now = utc_now_iso()
    normalized_target_type = normalize_improvement_target_type(target_type)
    normalized_source = normalize_improvement_source(source)
    normalized_risk = normalize_short_text(risk_level, max_len=24).upper() or "R1"
    normalized_status = normalize_improvement_status(status)
    improvement_id = make_improvement_id(
        source=normalized_source,
        target_type=normalized_target_type,
        target_id=target_id,
        title=title,
        linked_tenant_id=linked_tenant_id,
        linked_behavior_id=linked_behavior_id,
    )
    approval_value = (
        should_improvement_require_approval(normalized_target_type, normalized_risk)
        if approval_required is None
        else bool(approval_required)
    )
    item = {
        "improvement_id": improvement_id,
        "target_type": normalized_target_type,
        "target_id": normalize_short_text(target_id, max_len=96),
        "title": normalize_short_text(title, max_len=160),
        "description": normalize_short_text(description, max_len=320),
        "source": normalized_source,
        "reason": normalize_short_text(reason, max_len=320),
        "evidence": sanitize_improvement_evidence(evidence),
        "expected_outcome": normalize_short_text(expected_outcome, max_len=240),
        "priority": max(0, min(100, int(priority))),
        "risk_level": normalized_risk,
        "status": normalized_status,
        "approval_required": approval_value,
        "linked_behavior_id": normalize_short_text(linked_behavior_id, max_len=96),
        "linked_tenant_id": normalize_optional_onyx_tenant_id(linked_tenant_id),
        "created_at": now,
        "updated_at": now,
        "is_current": True,
        "history": [
            improvement_history_event(
                action="created",
                status=normalized_status,
                source=normalized_source,
                note=reason,
            )
        ],
    }
    return item


def improvement_sort_key(item: dict[str, Any]) -> tuple[int, int, int, str]:
    status_order = {
        "new": 0,
        "triaged": 1,
        "planned": 2,
        "in_progress": 3,
        "blocked": 4,
        "completed": 5,
        "reverted": 6,
        "dismissed": 7,
    }
    try:
        priority = int(item.get("priority", 0))
    except Exception:
        priority = 0
    return (
        0 if bool(item.get("is_current", True)) else 1,
        status_order.get(normalize_improvement_status(item.get("status")), 9),
        -priority,
        normalize_text(item.get("title")).lower(),
    )


def map_approval_status_to_improvement_status(value: Any) -> str:
    mapping = {
        "approved": "planned",
        "queued": "triaged",
        "executed": "completed",
        "rejected": "dismissed",
    }
    raw = normalize_short_text(value, max_len=32).lower()
    return normalize_improvement_status(mapping.get(raw, raw))


def map_recommendation_status_to_improvement_status(value: Any) -> str:
    mapping = {
        "new": "new",
        "seen": "triaged",
        "accepted": "planned",
        "completed": "completed",
        "dismissed": "dismissed",
    }
    raw = normalize_short_text(value, max_len=32).lower()
    return normalize_improvement_status(mapping.get(raw, raw))


def generate_runtime_improvements() -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    start_state = read_json(START_RUN_LAST_PATH, default={})
    if isinstance(start_state, dict):
        overall_status = normalize_short_text(start_state.get("overall_status"), max_len=24).upper()
        failure_artifact = normalize_text(start_state.get("start_failure_artifact"))
        if overall_status and overall_status != "PASS":
            items.append(
                build_improvement_item(
                    target_type="system",
                    target_id="start_run_last",
                    title="Resolve latest stack start issue",
                    description="The latest full-stack start artifact is not passing cleanly.",
                    source="runtime",
                    reason="Latest start run reported a non-PASS result.",
                    evidence=[
                        {
                            "source": "runtime",
                            "label": "Overall status",
                            "value": overall_status,
                            "path": str(START_RUN_LAST_PATH),
                        },
                        {
                            "source": "runtime",
                            "label": "Failure artifact",
                            "value": failure_artifact,
                            "path": failure_artifact,
                        },
                    ],
                    expected_outcome="Latest start run returns PASS with no failure artifact.",
                    priority=95,
                    risk_level="R2",
                    status="new",
                    approval_required=True,
                    linked_behavior_id=normalize_text(start_state.get("run_id")),
                )
            )
    return items


def generate_self_heal_improvements() -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    doctor_report = read_json(DOCTOR_REPORT_PATH, default={})
    if isinstance(doctor_report, dict):
        overall_result = normalize_short_text(doctor_report.get("overall_result"), max_len=24).upper()
        if overall_result and overall_result != "PASS":
            failing_checks: list[str] = []
            checks = doctor_report.get("checks") if isinstance(doctor_report.get("checks"), dict) else {}
            for group_value in checks.values():
                for check in normalize_list(group_value):
                    if not isinstance(check, dict) or bool(check.get("pass", True)):
                        continue
                    failing_checks.append(
                        normalize_short_text(check.get("name") or check.get("detail"), max_len=160)
                    )
                    if len(failing_checks) >= 3:
                        break
                if len(failing_checks) >= 3:
                    break
            items.append(
                build_improvement_item(
                    target_type="system",
                    target_id="doctor_report",
                    title="Resolve current doctor failures",
                    description="Doctor is still reporting failing checks against the current Mason baseline.",
                    source="self-heal",
                    reason="Latest doctor report is not PASS.",
                    evidence=[
                        {
                            "source": "self-heal",
                            "label": "Overall result",
                            "value": overall_result,
                            "path": str(DOCTOR_REPORT_PATH),
                        },
                        {
                            "source": "self-heal",
                            "label": "Failing check",
                            "value": failing_checks[0] if failing_checks else "See doctor report",
                            "path": str(DOCTOR_REPORT_PATH),
                        },
                    ],
                    expected_outcome="Doctor report returns PASS.",
                    priority=90,
                    risk_level="R2",
                    status="new",
                    approval_required=True,
                    linked_behavior_id="doctor_report",
                )
            )
    verify_state = read_json(VERIFY_LAST_PATH, default={})
    if isinstance(verify_state, dict):
        verify_status = normalize_short_text(verify_state.get("status"), max_len=24).upper()
        if verify_status and verify_status in {"FAIL", "WARN"}:
            items.append(
                build_improvement_item(
                    target_type="system",
                    target_id="verify_last",
                    title="Resolve current verify issues",
                    description="The latest verify run still reports unresolved warnings or failures.",
                    source="self-heal",
                    reason="Verify Stack did not return PASS.",
                    evidence=[
                        {
                            "source": "self-heal",
                            "label": "Verify status",
                            "value": verify_status,
                            "path": str(VERIFY_LAST_PATH),
                        },
                        {
                            "source": "self-heal",
                            "label": "Failing component",
                            "value": normalize_short_text(verify_state.get("failing_component"), max_len=160),
                            "path": normalize_text(verify_state.get("raw_report_path")),
                        },
                    ],
                    expected_outcome="Verify Stack returns PASS.",
                    priority=92 if verify_status == "FAIL" else 74,
                    risk_level="R2" if verify_status == "FAIL" else "R1",
                    status="new",
                    approval_required=True,
                    linked_behavior_id="verify_last",
                )
            )
    return items


def generate_recommendation_improvements() -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    if not ONYX_RECOMMENDATIONS_DIR.exists():
        return items
    for file in sorted(ONYX_RECOMMENDATIONS_DIR.glob("*.json")):
        state = read_json(file, default={})
        if not isinstance(state, dict):
            continue
        for recommendation in normalize_list(state.get("recommendations")):
            if not isinstance(recommendation, dict):
                continue
            if not bool(recommendation.get("is_current", True)):
                continue
            if normalize_improvement_status(recommendation.get("status")) == "dismissed":
                continue
            linked_tool_id = normalize_short_text(recommendation.get("linked_tool_id"), max_len=80)
            linked_tenant_id = normalize_optional_onyx_tenant_id(recommendation.get("tenant_id"))
            target_type = "tool" if linked_tool_id else ("business" if linked_tenant_id else "system")
            target_id = linked_tool_id or linked_tenant_id or normalize_text(recommendation.get("recommendation_id"))
            items.append(
                build_improvement_item(
                    target_type=target_type,
                    target_id=target_id,
                    title=normalize_short_text(recommendation.get("title"), max_len=160),
                    description=normalize_short_text(recommendation.get("description"), max_len=320),
                    source="recommendation",
                    reason=normalize_short_text(recommendation.get("reason"), max_len=320),
                    evidence=sanitize_improvement_evidence(recommendation.get("evidence")),
                    expected_outcome=normalize_short_text(
                        recommendation.get("estimated_roi_impact"),
                        max_len=240,
                    ),
                    priority=int(recommendation.get("priority", 50) or 50),
                    risk_level=normalize_short_text(recommendation.get("risk_level"), max_len=24).upper() or "R1",
                    status=map_recommendation_status_to_improvement_status(recommendation.get("status")),
                    approval_required=None,
                    linked_behavior_id=normalize_text(recommendation.get("recommendation_id")),
                    linked_tenant_id=linked_tenant_id,
                )
            )
    return items


def generate_manual_improvements_from_approvals() -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    for approval in get_approvals():
        approval_id = normalize_text(approval.get("id"))
        component_id = normalize_text(approval.get("component_id"))
        if not approval_id:
            continue
        try:
            numeric_risk = int(approval.get("risk_level", 1))
        except Exception:
            numeric_risk = 1
        priority = 55 if numeric_risk <= 0 else 70 if numeric_risk == 1 else 88
        item = build_improvement_item(
                target_type=normalize_improvement_target_type(component_id or approval.get("area")),
                target_id=approval_id,
                title=normalize_short_text(approval.get("title"), max_len=160),
                description="Imported from the legacy approvals queue.",
                source="owner" if normalize_text(approval.get("decision_by")).lower() == "owner" else "manual",
                reason=normalize_short_text(
                    approval.get("domain") or approval.get("kind") or "Legacy queue item",
                    max_len=240,
                ),
                evidence=[
                    {
                        "source": "legacy_queue",
                        "label": "Approval item",
                        "value": approval_id,
                        "path": str(PENDING_PATCHES),
                    },
                    {
                        "source": "legacy_queue",
                        "label": "Component",
                        "value": component_id,
                        "path": str(PENDING_PATCHES),
                    },
                ],
                expected_outcome=normalize_short_text(approval.get("title"), max_len=240),
                priority=priority,
                risk_level=f"R{max(0, numeric_risk)}",
                status=map_approval_status_to_improvement_status(approval.get("status")),
                approval_required=True,
                linked_behavior_id=approval_id,
            )
        item["queue_origin"] = "legacy_approval"
        items.append(item)
    return items


def generate_tool_gap_improvements() -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    workspace = load_onyx_workspace()
    for context in normalize_list(workspace.get("contexts")):
        if not isinstance(context, dict):
            continue
        tenant = context.get("tenant") if isinstance(context.get("tenant"), dict) else {}
        profile = context.get("profile") if isinstance(context.get("profile"), dict) else {}
        tenant_id = normalize_optional_onyx_tenant_id(tenant.get("id"))
        if not tenant_id:
            continue
        eligible_tools = 0
        for tool in load_tool_registry_entries():
            entry = sanitize_tool_catalog_entry(tool, context)
            if bool(entry.get("eligible")) and normalize_text(entry.get("status")).lower() == "enabled":
                eligible_tools += 1
        if eligible_tools == 0:
            items.append(
                build_improvement_item(
                    target_type="tool",
                    target_id=tenant_id,
                    title="Add the first runnable tool for this tenant",
                    description="This tenant has no eligible tools in the current catalog.",
                    source="tool-gap",
                    reason="No registered tools are currently available for the tenant.",
                    evidence=[
                        {
                            "source": "tool_catalog",
                            "label": "Tenant",
                            "value": normalize_short_text(profile.get("businessName"), max_len=160),
                            "path": str(ONYX_TENANTS_DIR / f"{tenant_id}.json"),
                        }
                    ],
                    expected_outcome="At least one governed tool becomes available in the tenant catalog.",
                    priority=78,
                    risk_level="R1",
                    status="new",
                    approval_required=True,
                    linked_tenant_id=tenant_id,
                )
            )
    return items


def merge_improvement_queue(generated_items: list[dict[str, Any]]) -> dict[str, Any]:
    existing_state = load_improvement_queue_state()
    existing_map = {
        normalize_text(item.get("improvement_id")): item
        for item in existing_state.get("items", [])
        if isinstance(item, dict)
    }
    now = utc_now_iso()
    generated_ids: set[str] = set()
    merged: list[dict[str, Any]] = []

    for item in generated_items:
        improvement_id = normalize_text(item.get("improvement_id"))
        if not improvement_id:
            continue
        generated_ids.add(improvement_id)
        prior = existing_map.get(improvement_id)
        merged_item = dict(item)
        merged_item["is_current"] = True
        if isinstance(prior, dict):
            merged_item["status"] = normalize_improvement_status(prior.get("status") or item.get("status"))
            merged_item["created_at"] = normalize_short_text(prior.get("created_at") or item.get("created_at"), max_len=64)
            merged_item["updated_at"] = now if any(
                normalize_text(prior.get(field)) != normalize_text(item.get(field))
                for field in (
                    "title",
                    "description",
                    "reason",
                    "expected_outcome",
                    "priority",
                    "risk_level",
                    "linked_behavior_id",
                    "linked_tenant_id",
                )
            ) else normalize_short_text(prior.get("updated_at") or item.get("updated_at"), max_len=64)
            merged_item["history"] = [
                row for row in normalize_list(prior.get("history")) if isinstance(row, dict)
            ] or merged_item.get("history", [])
        merged.append(merged_item)

    for improvement_id, prior in existing_map.items():
        if improvement_id in generated_ids:
            continue
        stale_item = dict(prior)
        preserve_manual_item = normalize_text(prior.get("queue_origin")) == "manual_create" or (
            normalize_improvement_source(prior.get("source")) in {"manual", "owner"}
            and not normalize_text(prior.get("linked_behavior_id"))
        )
        stale_item["is_current"] = True if preserve_manual_item else False
        merged.append(stale_item)

    return save_improvement_queue_state(
        {
            "version": 1,
            "updated_at_utc": now,
            "items": merged,
        }
    )


def refresh_improvement_queue(sources: list[str] | None = None) -> dict[str, Any]:
    requested = {normalize_improvement_source(item) for item in (sources or []) if normalize_text(item)}
    if not requested:
        requested = {"runtime", "recommendation", "manual", "owner", "self-heal", "tool-gap"}
    generated: list[dict[str, Any]] = []
    if "runtime" in requested:
        generated.extend(generate_runtime_improvements())
    if "recommendation" in requested:
        generated.extend(generate_recommendation_improvements())
    if "manual" in requested or "owner" in requested:
        generated.extend(generate_manual_improvements_from_approvals())
    if "self-heal" in requested:
        generated.extend(generate_self_heal_improvements())
    if "tool-gap" in requested:
        generated.extend(generate_tool_gap_improvements())
    return merge_improvement_queue(generated)


def create_or_update_manual_improvement(payload: ImprovementCreateRequest) -> dict[str, Any]:
    state = load_improvement_queue_state()
    item = build_improvement_item(
        target_type=payload.target_type,
        target_id=payload.target_id or payload.title,
        title=payload.title,
        description=payload.description,
        source=payload.source,
        reason=payload.reason,
        evidence=payload.evidence,
        expected_outcome=payload.expected_outcome,
        priority=payload.priority,
        risk_level=payload.risk_level,
        status="new",
        approval_required=payload.approval_required,
        linked_behavior_id=payload.linked_behavior_id or "",
        linked_tenant_id=payload.linked_tenant_id or "",
    )
    item["queue_origin"] = "manual_create"
    improvement_id = normalize_text(item.get("improvement_id"))
    items = [row for row in normalize_list(state.get("items")) if isinstance(row, dict)]
    replaced = False
    for index, existing in enumerate(items):
        if normalize_text(existing.get("improvement_id")) != improvement_id:
            continue
        updated = dict(item)
        updated["status"] = normalize_improvement_status(existing.get("status") or "new")
        updated["created_at"] = normalize_short_text(existing.get("created_at") or item.get("created_at"), max_len=64)
        updated["updated_at"] = utc_now_iso()
        updated["queue_origin"] = normalize_text(existing.get("queue_origin")) or "manual_create"
        history = [row for row in normalize_list(existing.get("history")) if isinstance(row, dict)]
        history.append(
            improvement_history_event(
                action="manual_update",
                status=updated["status"],
                source=updated["source"],
                note=updated["title"],
            )
        )
        updated["history"] = history
        items[index] = updated
        replaced = True
        break
    if not replaced:
        items.append(item)
    state["items"] = items
    state["updated_at_utc"] = utc_now_iso()
    saved_state = save_improvement_queue_state(state)
    append_platform_audit_event(
        event_type="improvement_queue_action",
        actor_role="owner",
        actor_id="owner",
        tenant_id=normalize_optional_onyx_tenant_id(item.get("linked_tenant_id")),
        resource_type="improvement",
        resource_id=normalize_text(item.get("improvement_id")),
        action="manual_create" if not replaced else "manual_update",
        outcome=normalize_improvement_status(item.get("status")),
        risk_level=normalize_short_text(item.get("risk_level"), max_len=24),
        details={
            "title": normalize_short_text(item.get("title"), max_len=160),
            "target_type": normalize_improvement_target_type(item.get("target_type")),
        },
    )
    return saved_state


def update_improvement_status(payload: ImprovementStatusRequest) -> dict[str, Any] | None:
    state = load_improvement_queue_state()
    improvement_id = normalize_text(payload.improvement_id)
    new_status = normalize_improvement_status(payload.status)
    items = [row for row in normalize_list(state.get("items")) if isinstance(row, dict)]
    updated = False
    for item in items:
        if normalize_text(item.get("improvement_id")) != improvement_id:
            continue
        item["status"] = new_status
        item["updated_at"] = utc_now_iso()
        history = [row for row in normalize_list(item.get("history")) if isinstance(row, dict)]
        history.append(
            improvement_history_event(
                action="status_update",
                status=new_status,
                source=str(item.get("source") or "manual"),
                note=payload.note,
            )
        )
        item["history"] = history
        updated = True
        break
    if not updated:
        return None
    state["items"] = items
    state["updated_at_utc"] = utc_now_iso()
    saved_state = save_improvement_queue_state(state)
    updated_item = None
    for item in items:
        if normalize_text(item.get("improvement_id")) == improvement_id:
            updated_item = item
            break
    append_platform_audit_event(
        event_type="improvement_queue_action",
        actor_role="owner",
        actor_id="owner",
        tenant_id=normalize_optional_onyx_tenant_id((updated_item or {}).get("linked_tenant_id")),
        resource_type="improvement",
        resource_id=improvement_id,
        action="status_update",
        outcome=new_status,
        risk_level=normalize_short_text((updated_item or {}).get("risk_level"), max_len=24),
        details={
            "note": normalize_short_text(payload.note, max_len=200),
            "title": normalize_short_text((updated_item or {}).get("title"), max_len=160),
        },
    )
    return saved_state


def filter_improvement_items(
    state: dict[str, Any] | None = None,
    *,
    statuses: list[str] | None = None,
    sources: list[str] | None = None,
    target_types: list[str] | None = None,
    tenant_id: str = "",
    current_only: bool = True,
) -> list[dict[str, Any]]:
    queue_state = state if isinstance(state, dict) else load_improvement_queue_state()
    behavior_map = behavior_lookup_map()
    items = [item for item in normalize_list(queue_state.get("items")) if isinstance(item, dict)]
    allowed_statuses = {normalize_improvement_status(item) for item in normalize_list(statuses) if normalize_text(item)}
    allowed_sources = {normalize_improvement_source(item) for item in normalize_list(sources) if normalize_text(item)}
    allowed_target_types = {
        normalize_improvement_target_type(item) for item in normalize_list(target_types) if normalize_text(item)
    }
    safe_tenant_id = normalize_optional_onyx_tenant_id(tenant_id)
    filtered: list[dict[str, Any]] = []
    governor_map = self_improvement_decision_lookup()
    for item in items:
        if current_only and not bool(item.get("is_current", True)):
            continue
        if allowed_statuses and normalize_improvement_status(item.get("status")) not in allowed_statuses:
            continue
        if allowed_sources and normalize_improvement_source(item.get("source")) not in allowed_sources:
            continue
        if allowed_target_types and normalize_improvement_target_type(item.get("target_type")) not in allowed_target_types:
            continue
        if safe_tenant_id and normalize_optional_onyx_tenant_id(item.get("linked_tenant_id")) != safe_tenant_id:
            continue
        filtered.append(decorate_improvement_item(item, behavior_map, governor_map))
    filtered.sort(key=improvement_sort_key)
    return filtered


def summarize_improvement_queue_state(state: dict[str, Any] | None = None) -> dict[str, Any]:
    queue_state = state if isinstance(state, dict) else load_improvement_queue_state()
    items = [item for item in normalize_list(queue_state.get("items")) if isinstance(item, dict)]
    current_items = [item for item in items if bool(item.get("is_current", True))]
    by_status: dict[str, int] = {}
    by_source: dict[str, int] = {}
    by_target_type: dict[str, int] = {}
    tenant_ids: set[str] = set()
    approval_required_total = 0
    for item in current_items:
        status = normalize_improvement_status(item.get("status"))
        source = normalize_improvement_source(item.get("source"))
        target_type = normalize_improvement_target_type(item.get("target_type"))
        by_status[status] = by_status.get(status, 0) + 1
        by_source[source] = by_source.get(source, 0) + 1
        by_target_type[target_type] = by_target_type.get(target_type, 0) + 1
        if bool(item.get("approval_required")):
            approval_required_total += 1
        tenant_id = normalize_optional_onyx_tenant_id(item.get("linked_tenant_id"))
        if tenant_id:
            tenant_ids.add(tenant_id)
    return {
        "total": len(items),
        "current_total": len(current_items),
        "approval_required_total": approval_required_total,
        "tenant_total": len(tenant_ids),
        "by_status": by_status,
        "by_source": by_source,
        "by_target_type": by_target_type,
        "updated_at_utc": normalize_short_text(queue_state.get("updated_at_utc"), max_len=64),
        "artifact_path": str(IMPROVEMENT_QUEUE_PATH),
        "report_path": str(IMPROVEMENT_QUEUE_REPORT_PATH),
    }


def normalize_behavior_domain(value: Any) -> str:
    return normalize_improvement_target_type(value)


def normalize_behavior_risk_level(value: Any) -> str:
    raw = normalize_short_text(value, max_len=24).lower()
    mapping = {
        "r0": "low",
        "r1": "low",
        "r2": "medium",
        "r3": "high",
        "r4": "critical",
        "low": "low",
        "medium": "medium",
        "med": "medium",
        "high": "high",
        "critical": "critical",
    }
    return mapping.get(raw, "medium")


def normalize_behavior_trust_state(value: Any) -> str:
    raw = normalize_short_text(value, max_len=24).lower()
    allowed = {
        "discovered",
        "shadow",
        "tested",
        "candidate",
        "approved",
        "trusted",
        "auto_allowed",
        "blocked",
        "reverted",
    }
    return raw if raw in allowed else "discovered"


def sanitize_behavior_required_evidence(value: Any) -> list[str]:
    cleaned: list[str] = []
    seen: set[str] = set()
    for item in normalize_list(value):
        text = normalize_short_text(item, max_len=120)
        if not text:
            continue
        key = text.lower()
        if key in seen:
            continue
        seen.add(key)
        cleaned.append(text)
    return cleaned


def empty_behavior_trust_state() -> dict[str, Any]:
    return {
        "version": 1,
        "updated_at_utc": "",
        "behaviors": [],
    }


def behavior_history_event(
    *,
    action: str,
    trust_state: str,
    note: str = "",
    promotion_reason: str = "",
) -> dict[str, Any]:
    return {
        "at_utc": utc_now_iso(),
        "action": normalize_short_text(action, max_len=40),
        "trust_state": normalize_behavior_trust_state(trust_state),
        "note": normalize_short_text(note, max_len=240),
        "promotion_reason": normalize_short_text(promotion_reason, max_len=240),
    }


def make_behavior_id(behavior_name: str, domain: str, requested_id: str = "") -> str:
    candidate = normalize_short_text(requested_id, max_len=96).lower().replace(" ", "_")
    if re.fullmatch(r"[a-z0-9_.-]{8,96}", candidate):
        return candidate
    seed = f"{normalize_behavior_domain(domain)}|{normalize_text(behavior_name).lower()}"
    return f"beh_{hashlib.sha1(seed.encode('utf-8')).hexdigest()[:12]}"


def behavior_has_hard_gate(record: dict[str, Any]) -> bool:
    combined = " ".join(
        [
            normalize_text(record.get("behavior_name")).lower(),
            normalize_text(record.get("description")).lower(),
            normalize_text(record.get("rollback_condition")).lower(),
            " ".join(normalize_text(item).lower() for item in normalize_list(record.get("required_evidence"))),
        ]
    )
    gated_keywords = (
        "money",
        "billing",
        "payment",
        "invoice",
        "refund",
        "credential",
        "credentials",
        "secret",
        "token",
        "password",
        "api key",
        "oauth",
        "policy expansion",
        "major policy",
        "external action",
        "external actions",
        "third-party",
        "third party",
        "outbound",
        "public network",
    )
    return any(keyword in combined for keyword in gated_keywords)


def apply_behavior_policy_fields(record: dict[str, Any]) -> dict[str, Any]:
    behavior = dict(record)
    behavior["domain"] = normalize_behavior_domain(behavior.get("domain"))
    behavior["risk_level"] = normalize_behavior_risk_level(behavior.get("risk_level"))
    requested_state = normalize_behavior_trust_state(behavior.get("trust_state"))
    requested_operator_gate = bool(behavior.get("operator_gate"))
    hard_gated = behavior_has_hard_gate(behavior)
    risk_gated = behavior["risk_level"] in {"medium", "high", "critical"}
    auto_action_eligible = (
        requested_state == "auto_allowed"
        and not requested_operator_gate
        and not hard_gated
        and not risk_gated
    )
    behavior["trust_state"] = "trusted" if requested_state == "auto_allowed" and not auto_action_eligible else requested_state
    behavior["hard_gated"] = hard_gated
    behavior["policy_gate_reason"] = (
        "always_gated"
        if hard_gated
        else "risk_gated"
        if risk_gated
        else "operator_gate"
        if requested_operator_gate and behavior["trust_state"] != "auto_allowed"
        else ""
    )
    behavior["operator_gate"] = requested_operator_gate
    behavior["auto_action_eligible"] = auto_action_eligible
    behavior["approval_required"] = bool(
        requested_operator_gate
        or hard_gated
        or risk_gated
        or behavior["trust_state"] != "auto_allowed"
    )
    return behavior


def sanitize_behavior_record(record: dict[str, Any]) -> dict[str, Any]:
    now = utc_now_iso()
    behavior_id = make_behavior_id(
        normalize_text(record.get("behavior_name")),
        normalize_text(record.get("domain")),
        normalize_text(record.get("behavior_id")),
    )
    history = []
    for entry in normalize_list(record.get("history")):
        if not isinstance(entry, dict):
            continue
        history.append(
            {
                "at_utc": normalize_short_text(entry.get("at_utc"), max_len=64) or now,
                "action": normalize_short_text(entry.get("action"), max_len=40),
                "trust_state": normalize_behavior_trust_state(entry.get("trust_state")),
                "note": normalize_short_text(entry.get("note"), max_len=240),
                "promotion_reason": normalize_short_text(entry.get("promotion_reason"), max_len=240),
            }
        )
    behavior = {
        "behavior_id": behavior_id,
        "behavior_name": normalize_short_text(record.get("behavior_name"), max_len=120) or behavior_id,
        "domain": normalize_behavior_domain(record.get("domain")),
        "description": normalize_short_text(record.get("description"), max_len=320),
        "risk_level": normalize_behavior_risk_level(record.get("risk_level")),
        "required_evidence": sanitize_behavior_required_evidence(record.get("required_evidence")),
        "trust_state": normalize_behavior_trust_state(record.get("trust_state")),
        "operator_gate": bool(record.get("operator_gate")) if "operator_gate" in record else False,
        "last_tested_at": normalize_short_text(record.get("last_tested_at"), max_len=64),
        "promotion_reason": normalize_short_text(record.get("promotion_reason"), max_len=240),
        "rollback_condition": normalize_short_text(record.get("rollback_condition"), max_len=240),
        "created_at": normalize_short_text(record.get("created_at"), max_len=64) or now,
        "updated_at": normalize_short_text(record.get("updated_at"), max_len=64) or now,
        "history": history,
    }
    if not behavior["history"]:
        behavior["history"] = [
            behavior_history_event(
                action="created",
                trust_state=behavior["trust_state"],
                note=behavior["behavior_name"],
                promotion_reason=behavior["promotion_reason"],
            )
        ]
    return apply_behavior_policy_fields(behavior)


def build_behavior_record(payload: BehaviorCreateRequest) -> dict[str, Any]:
    now = utc_now_iso()
    behavior = {
        "behavior_id": make_behavior_id(payload.behavior_name, payload.domain, payload.behavior_id or ""),
        "behavior_name": normalize_short_text(payload.behavior_name, max_len=120),
        "domain": normalize_behavior_domain(payload.domain),
        "description": normalize_short_text(payload.description, max_len=320),
        "risk_level": normalize_behavior_risk_level(payload.risk_level),
        "required_evidence": sanitize_behavior_required_evidence(payload.required_evidence),
        "trust_state": normalize_behavior_trust_state(payload.trust_state),
        "operator_gate": bool(payload.approval_required) if payload.approval_required is not None else False,
        "last_tested_at": normalize_short_text(payload.last_tested_at, max_len=64),
        "promotion_reason": normalize_short_text(payload.promotion_reason, max_len=240),
        "rollback_condition": normalize_short_text(payload.rollback_condition, max_len=240),
        "created_at": now,
        "updated_at": now,
        "history": [
            behavior_history_event(
                action="created",
                trust_state=payload.trust_state,
                note=payload.behavior_name,
                promotion_reason=payload.promotion_reason,
            )
        ],
    }
    return apply_behavior_policy_fields(behavior)


def behavior_sort_key(item: dict[str, Any]) -> tuple[int, int, str]:
    state_order = {
        "blocked": 0,
        "candidate": 1,
        "approved": 2,
        "trusted": 3,
        "auto_allowed": 4,
        "tested": 5,
        "shadow": 6,
        "discovered": 7,
        "reverted": 8,
    }
    risk_order = {
        "critical": 0,
        "high": 1,
        "medium": 2,
        "low": 3,
    }
    return (
        state_order.get(normalize_behavior_trust_state(item.get("trust_state")), 9),
        risk_order.get(normalize_behavior_risk_level(item.get("risk_level")), 9),
        normalize_text(item.get("behavior_name")).lower(),
    )


def build_trust_index_snapshot(state: dict[str, Any]) -> dict[str, Any]:
    rules: dict[str, Any] = {}
    for behavior in normalize_list(state.get("behaviors")):
        if not isinstance(behavior, dict):
            continue
        history = [item for item in normalize_list(behavior.get("history")) if isinstance(item, dict)]
        behavior_id = normalize_text(behavior.get("behavior_id"))
        if not behavior_id:
            continue
        rules[behavior_id] = {
            "id": behavior_id,
            "description": normalize_short_text(behavior.get("description"), max_len=320),
            "source": "behavior_trust",
            "area": normalize_behavior_domain(behavior.get("domain")),
            "risk_level": normalize_behavior_risk_level(behavior.get("risk_level")),
            "state": normalize_behavior_trust_state(behavior.get("trust_state")),
            "auto_apply_allowed": bool(behavior.get("auto_action_eligible")),
            "stats": {
                "shadow_runs": sum(1 for item in history if normalize_behavior_trust_state(item.get("trust_state")) == "shadow"),
                "real_runs_successful": sum(
                    1 for item in history if normalize_behavior_trust_state(item.get("trust_state")) in {"trusted", "auto_allowed"}
                ),
                "real_runs_failed": sum(
                    1 for item in history if normalize_behavior_trust_state(item.get("trust_state")) in {"blocked", "reverted"}
                ),
                "rollback_count": sum(
                    1 for item in history if normalize_behavior_trust_state(item.get("trust_state")) == "reverted"
                ),
            },
            "teacher_api": {
                "approved": normalize_behavior_trust_state(behavior.get("trust_state")) in {"approved", "trusted", "auto_allowed"},
                "last_decision": normalize_behavior_trust_state(behavior.get("trust_state")),
                "last_decision_at": normalize_short_text(behavior.get("updated_at"), max_len=64),
                "notes": normalize_short_text(behavior.get("promotion_reason"), max_len=240),
            },
            "governor": {
                "auto_apply_opt_in": bool(behavior.get("auto_action_eligible")),
                "last_decision_at": normalize_short_text(behavior.get("updated_at"), max_len=64),
                "notes": normalize_short_text(behavior.get("rollback_condition"), max_len=240),
            },
            "created_at": normalize_short_text(behavior.get("created_at"), max_len=64),
            "last_updated_at": normalize_short_text(behavior.get("updated_at"), max_len=64),
        }
    return {
        "version": 1,
        "rules": rules,
    }


def save_behavior_trust_state(state: dict[str, Any]) -> dict[str, Any]:
    payload = empty_behavior_trust_state()
    if isinstance(state, dict):
        payload.update(state)
    payload["version"] = 1
    payload["updated_at_utc"] = normalize_short_text(payload.get("updated_at_utc"), max_len=64) or utc_now_iso()
    behaviors = [sanitize_behavior_record(item) for item in normalize_list(payload.get("behaviors")) if isinstance(item, dict)]
    behaviors.sort(key=behavior_sort_key)
    payload["behaviors"] = behaviors
    write_json(BEHAVIOR_TRUST_PATH, payload)
    write_json(BEHAVIOR_TRUST_REPORT_PATH, payload)
    write_json(TRUST_INDEX_PATH, build_trust_index_snapshot(payload))
    return payload


def load_behavior_trust_state() -> dict[str, Any]:
    if not BEHAVIOR_TRUST_PATH.exists():
        return save_behavior_trust_state(empty_behavior_trust_state())
    data = read_json(BEHAVIOR_TRUST_PATH, default=empty_behavior_trust_state())
    if not isinstance(data, dict):
        return save_behavior_trust_state(empty_behavior_trust_state())
    return save_behavior_trust_state(data)


def can_transition_behavior_state(current_state: str, next_state: str) -> bool:
    current_value = normalize_behavior_trust_state(current_state)
    next_value = normalize_behavior_trust_state(next_state)
    if current_value == next_value:
        return True
    allowed = {
        "discovered": {"shadow", "blocked"},
        "shadow": {"tested", "blocked", "reverted"},
        "tested": {"candidate", "blocked", "reverted"},
        "candidate": {"approved", "blocked", "reverted"},
        "approved": {"trusted", "blocked", "reverted"},
        "trusted": {"auto_allowed", "blocked", "reverted"},
        "auto_allowed": {"blocked", "reverted"},
        "blocked": {"candidate", "reverted"},
        "reverted": {"shadow", "candidate", "blocked"},
    }
    return next_value in allowed.get(current_value, set())


def create_or_update_behavior(payload: BehaviorCreateRequest) -> dict[str, Any]:
    state = load_behavior_trust_state()
    behavior_id = make_behavior_id(payload.behavior_name, payload.domain, payload.behavior_id or "")
    behaviors = [item for item in normalize_list(state.get("behaviors")) if isinstance(item, dict)]
    for index, existing in enumerate(behaviors):
        if normalize_text(existing.get("behavior_id")) != behavior_id:
            continue
        updated = dict(existing)
        updated["behavior_name"] = normalize_short_text(payload.behavior_name, max_len=120)
        updated["domain"] = normalize_behavior_domain(payload.domain)
        updated["description"] = normalize_short_text(payload.description, max_len=320)
        updated["risk_level"] = normalize_behavior_risk_level(payload.risk_level)
        updated["required_evidence"] = sanitize_behavior_required_evidence(payload.required_evidence)
        updated["rollback_condition"] = normalize_short_text(payload.rollback_condition, max_len=240)
        if payload.last_tested_at:
            updated["last_tested_at"] = normalize_short_text(payload.last_tested_at, max_len=64)
        if payload.promotion_reason:
            updated["promotion_reason"] = normalize_short_text(payload.promotion_reason, max_len=240)
        if payload.approval_required is not None:
            updated["operator_gate"] = bool(payload.approval_required)
        updated = apply_behavior_policy_fields(updated)
        updated["updated_at"] = utc_now_iso()
        history = [item for item in normalize_list(existing.get("history")) if isinstance(item, dict)]
        history.append(
            behavior_history_event(
                action="metadata_update",
                trust_state=updated.get("trust_state"),
                note=updated.get("behavior_name"),
                promotion_reason=updated.get("promotion_reason"),
            )
        )
        updated["history"] = history
        behaviors[index] = updated
        state["behaviors"] = behaviors
        state["updated_at_utc"] = utc_now_iso()
        saved_state = save_behavior_trust_state(state)
        append_platform_audit_event(
            event_type="trust_state_change",
            actor_role="owner",
            actor_id="owner",
            resource_type="behavior",
            resource_id=behavior_id,
            action="metadata_update",
            outcome=normalize_behavior_trust_state(updated.get("trust_state")),
            risk_level=normalize_behavior_risk_level(updated.get("risk_level")),
            details={
                "behavior_name": normalize_short_text(updated.get("behavior_name"), max_len=120),
                "domain": normalize_behavior_domain(updated.get("domain")),
            },
        )
        return saved_state
    created = build_behavior_record(payload)
    behaviors.append(created)
    state["behaviors"] = behaviors
    state["updated_at_utc"] = utc_now_iso()
    saved_state = save_behavior_trust_state(state)
    append_platform_audit_event(
        event_type="trust_state_change",
        actor_role="owner",
        actor_id="owner",
        resource_type="behavior",
        resource_id=behavior_id,
        action="register",
        outcome=normalize_behavior_trust_state(created.get("trust_state")),
        risk_level=normalize_behavior_risk_level(created.get("risk_level")),
        details={
            "behavior_name": normalize_short_text(created.get("behavior_name"), max_len=120),
            "domain": normalize_behavior_domain(created.get("domain")),
        },
    )
    return saved_state


def update_behavior_state(payload: BehaviorStateRequest) -> tuple[dict[str, Any] | None, str]:
    state = load_behavior_trust_state()
    behavior_id = normalize_text(payload.behavior_id)
    requested_state = normalize_behavior_trust_state(payload.trust_state)
    behaviors = [item for item in normalize_list(state.get("behaviors")) if isinstance(item, dict)]
    for index, behavior in enumerate(behaviors):
        if normalize_text(behavior.get("behavior_id")) != behavior_id:
            continue
        current_state = normalize_behavior_trust_state(behavior.get("trust_state"))
        if not can_transition_behavior_state(current_state, requested_state):
            return None, "invalid_transition"
        updated = dict(behavior)
        updated["trust_state"] = requested_state
        if payload.promotion_reason:
            updated["promotion_reason"] = normalize_short_text(payload.promotion_reason, max_len=240)
        if payload.last_tested_at:
            updated["last_tested_at"] = normalize_short_text(payload.last_tested_at, max_len=64)
        elif requested_state in {"tested", "candidate", "approved", "trusted", "auto_allowed"}:
            updated["last_tested_at"] = utc_now_iso()
        updated = apply_behavior_policy_fields(updated)
        updated["updated_at"] = utc_now_iso()
        history = [item for item in normalize_list(behavior.get("history")) if isinstance(item, dict)]
        history.append(
            behavior_history_event(
                action="state_update",
                trust_state=updated.get("trust_state"),
                note=payload.note,
                promotion_reason=payload.promotion_reason or updated.get("promotion_reason"),
            )
        )
        updated["history"] = history
        behaviors[index] = updated
        state["behaviors"] = behaviors
        state["updated_at_utc"] = utc_now_iso()
        saved_state = save_behavior_trust_state(state)
        append_platform_audit_event(
            event_type="trust_state_change",
            actor_role="owner",
            actor_id="owner",
            resource_type="behavior",
            resource_id=behavior_id,
            action="state_update",
            outcome=requested_state,
            risk_level=normalize_behavior_risk_level(updated.get("risk_level")),
            details={
                "note": normalize_short_text(payload.note, max_len=200),
                "promotion_reason": normalize_short_text(payload.promotion_reason or updated.get("promotion_reason"), max_len=240),
            },
        )
        return saved_state, ""
    return None, "behavior_not_found"


def summarize_behavior_brief(behavior: dict[str, Any]) -> dict[str, Any]:
    return {
        "behavior_id": normalize_text(behavior.get("behavior_id")),
        "behavior_name": normalize_short_text(behavior.get("behavior_name"), max_len=120),
        "domain": normalize_behavior_domain(behavior.get("domain")),
        "trust_state": normalize_behavior_trust_state(behavior.get("trust_state")),
        "risk_level": normalize_behavior_risk_level(behavior.get("risk_level")),
        "approval_required": bool(behavior.get("approval_required")),
        "auto_action_eligible": bool(behavior.get("auto_action_eligible")),
        "updated_at": normalize_short_text(behavior.get("updated_at"), max_len=64),
    }


def summarize_behavior_trust_state(state: dict[str, Any] | None = None) -> dict[str, Any]:
    trust_state = state if isinstance(state, dict) else load_behavior_trust_state()
    behaviors = [item for item in normalize_list(trust_state.get("behaviors")) if isinstance(item, dict)]
    by_trust_state: dict[str, int] = {}
    by_domain: dict[str, int] = {}
    by_risk_level: dict[str, int] = {}
    approval_required_total = 0
    auto_allowed_total = 0
    blocked_behaviors: list[dict[str, Any]] = []
    awaiting_approval_behaviors: list[dict[str, Any]] = []
    trusted_behaviors: list[dict[str, Any]] = []
    for behavior in behaviors:
        trust_value = normalize_behavior_trust_state(behavior.get("trust_state"))
        domain_value = normalize_behavior_domain(behavior.get("domain"))
        risk_value = normalize_behavior_risk_level(behavior.get("risk_level"))
        by_trust_state[trust_value] = by_trust_state.get(trust_value, 0) + 1
        by_domain[domain_value] = by_domain.get(domain_value, 0) + 1
        by_risk_level[risk_value] = by_risk_level.get(risk_value, 0) + 1
        if bool(behavior.get("approval_required")):
            approval_required_total += 1
        if bool(behavior.get("auto_action_eligible")):
            auto_allowed_total += 1
        brief = summarize_behavior_brief(behavior)
        if trust_value == "blocked" and len(blocked_behaviors) < 5:
            blocked_behaviors.append(brief)
        if trust_value == "candidate" and bool(behavior.get("approval_required")) and len(awaiting_approval_behaviors) < 5:
            awaiting_approval_behaviors.append(brief)
        if trust_value in {"trusted", "auto_allowed"} and len(trusted_behaviors) < 5:
            trusted_behaviors.append(brief)
    return {
        "total": len(behaviors),
        "approval_required_total": approval_required_total,
        "auto_allowed_total": auto_allowed_total,
        "blocked_total": int(by_trust_state.get("blocked") or 0),
        "awaiting_approval_total": int(by_trust_state.get("candidate") or 0),
        "trusted_total": int(by_trust_state.get("trusted") or 0) + int(by_trust_state.get("auto_allowed") or 0),
        "by_trust_state": by_trust_state,
        "by_domain": by_domain,
        "by_risk_level": by_risk_level,
        "blocked_behaviors": blocked_behaviors,
        "awaiting_approval_behaviors": awaiting_approval_behaviors,
        "trusted_behaviors": trusted_behaviors,
        "updated_at_utc": normalize_short_text(trust_state.get("updated_at_utc"), max_len=64),
        "artifact_path": str(BEHAVIOR_TRUST_PATH),
        "report_path": str(BEHAVIOR_TRUST_REPORT_PATH),
        "trust_index_path": str(TRUST_INDEX_PATH),
    }


def behavior_lookup_map(state: dict[str, Any] | None = None) -> dict[str, dict[str, Any]]:
    trust_state = state if isinstance(state, dict) else load_behavior_trust_state()
    return {
        normalize_text(item.get("behavior_id")): item
        for item in normalize_list(trust_state.get("behaviors"))
        if isinstance(item, dict) and normalize_text(item.get("behavior_id"))
    }


def describe_improvement_execution(
    item: dict[str, Any],
    behavior: dict[str, Any] | None,
    governor_decision: dict[str, Any] | None = None,
) -> dict[str, Any]:
    if behavior is None:
        if normalize_text(item.get("linked_behavior_id")):
            execution_mode = "suggestion_only"
            execution_reason = "Linked behavior is not registered in the trust ladder."
        elif bool(item.get("approval_required")):
            execution_mode = "approval_required"
            execution_reason = "No trusted behavior is linked, so this improvement remains gated."
        else:
            execution_mode = "suggestion_only"
            execution_reason = "No linked behavior trust state is registered yet."
    elif bool(behavior.get("auto_action_eligible")):
        execution_mode = "auto_allowed"
        execution_reason = "Linked low-risk behavior is auto_allowed under policy."
    elif bool(item.get("approval_required")) or bool(behavior.get("approval_required")):
        execution_mode = "approval_required"
        execution_reason = "Linked behavior is not auto_allowed and still requires approval."
    else:
        execution_mode = "suggestion_only"
        execution_reason = "Linked behavior is still earning trust evidence."

    execution_disposition = {
        "auto_allowed": "safe_to_test",
        "approval_required": "approval_required",
    }.get(execution_mode, "suggest_only")
    execution_disposition_reason = execution_reason

    if isinstance(behavior, dict) and bool(behavior.get("hard_gated")):
        execution_disposition = "blocked"
        execution_disposition_reason = normalize_short_text(
            behavior.get("policy_gate_reason") or "Linked behavior is hard-gated by policy.",
            max_len=240,
        ) or "Linked behavior is hard-gated by policy."

    teacher_call_classification = ""
    teacher_quality_classification = ""
    teacher_quality_score = 0
    teacher_cost_tier = ""
    blocked_by_local_first = False
    local_first_mandatory = bool(load_self_improvement_policy().get("local_first_mandatory", True))

    if isinstance(governor_decision, dict):
        decision_disposition = normalize_short_text(governor_decision.get("execution_disposition"), max_len=32).lower()
        if decision_disposition:
            execution_disposition = decision_disposition
        decision_reason = normalize_short_text(governor_decision.get("execution_disposition_reason"), max_len=240)
        if decision_reason:
            execution_disposition_reason = decision_reason
        teacher_call_classification = normalize_short_text(
            governor_decision.get("teacher_call_classification"),
            max_len=48,
        ).lower()
        teacher_quality_classification = normalize_short_text(
            governor_decision.get("teacher_quality_classification"),
            max_len=32,
        ).lower()
        try:
            teacher_quality_score = int(governor_decision.get("teacher_quality_score") or 0)
        except Exception:
            teacher_quality_score = 0
        teacher_cost_tier = normalize_short_text(governor_decision.get("estimated_cost_tier"), max_len=16).lower()
        blocked_by_local_first = bool(governor_decision.get("blocked_by_local_first", False))

    return {
        "execution_mode": execution_mode,
        "execution_reason": execution_reason,
        "execution_disposition": execution_disposition,
        "execution_disposition_reason": execution_disposition_reason,
        "teacher_call_classification": teacher_call_classification,
        "teacher_quality_classification": teacher_quality_classification,
        "teacher_quality_score": teacher_quality_score,
        "teacher_cost_tier": teacher_cost_tier,
        "blocked_by_local_first": blocked_by_local_first,
        "local_first_mandatory": local_first_mandatory,
    }


def decorate_improvement_item(
    item: dict[str, Any],
    lookup: dict[str, dict[str, Any]] | None = None,
    governor_lookup: dict[str, dict[str, Any]] | None = None,
) -> dict[str, Any]:
    output = dict(item)
    behavior_id = normalize_text(output.get("linked_behavior_id"))
    behavior_map = lookup if isinstance(lookup, dict) else behavior_lookup_map()
    decision_map = governor_lookup if isinstance(governor_lookup, dict) else self_improvement_decision_lookup()
    behavior = behavior_map.get(behavior_id) if behavior_id else None
    governor_decision = decision_map.get(normalize_text(output.get("improvement_id")))
    output["linked_behavior"] = summarize_behavior_brief(behavior) if isinstance(behavior, dict) else None
    output.update(describe_improvement_execution(output, behavior, governor_decision))
    return output


def normalize_tool_factory_source(value: Any) -> str:
    raw = normalize_short_text(value, max_len=24).lower()
    if raw == "manual":
        raw = "owner"
    allowed = {"owner", "recommendation", "queue", "competitor", "runtime", "tool-gap"}
    return raw if raw in allowed else "owner"


def normalize_tool_factory_status(value: Any) -> str:
    raw = normalize_short_text(value, max_len=24).lower()
    allowed = {"new", "spec_ready", "build_ready", "built", "tested", "published", "rejected"}
    return raw if raw in allowed else "new"


def normalize_tool_factory_list(value: Any, *, max_items: int = 16, max_len: int = 120) -> list[str]:
    cleaned: list[str] = []
    seen: set[str] = set()
    for item in normalize_list(value):
        text = normalize_short_text(item, max_len=max_len)
        if not text:
            continue
        key = text.lower()
        if key in seen:
            continue
        seen.add(key)
        cleaned.append(text)
        if len(cleaned) >= max_items:
            break
    return cleaned


def empty_tool_factory_state() -> dict[str, Any]:
    return {
        "version": 1,
        "updated_at_utc": "",
        "specs": [],
    }


def tool_factory_history_event(
    *,
    action: str,
    status: str,
    note: str = "",
) -> dict[str, Any]:
    return {
        "at_utc": utc_now_iso(),
        "action": normalize_short_text(action, max_len=40),
        "status": normalize_tool_factory_status(status),
        "note": normalize_short_text(note, max_len=240),
    }


def make_tool_factory_spec_id(
    *,
    title: str,
    source: str,
    target_domain: str,
    proposed_tool_name: str,
    linked_improvement_id: str = "",
    linked_behavior_id: str = "",
    requested_id: str = "",
) -> str:
    candidate = normalize_short_text(requested_id, max_len=96).lower().replace(" ", "_")
    if re.fullmatch(r"[a-z0-9_.-]{8,96}", candidate):
        return candidate
    seed = "|".join(
        [
            normalize_tool_factory_source(source),
            normalize_behavior_domain(target_domain),
            normalize_text(title).lower(),
            normalize_text(proposed_tool_name).lower(),
            normalize_text(linked_improvement_id).lower(),
            normalize_text(linked_behavior_id).lower(),
        ]
    )
    return f"spec_{hashlib.sha1(seed.encode('utf-8')).hexdigest()[:12]}"


def tool_factory_text_tokens(text: str) -> list[str]:
    return [token for token in re.findall(r"[a-z0-9]+", normalize_text(text).lower()) if len(token) >= 3]


def infer_tool_factory_blueprint(
    title: str,
    problem_statement: str,
    target_domain: str,
) -> dict[str, Any]:
    combined = f"{title} {problem_statement}".lower()
    if any(keyword in combined for keyword in ("marketing", "campaign", "audience", "content")):
        return {
            "category": "marketing",
            "proposed_tool_name": "Campaign Opportunity Builder",
            "expected_inputs": ["tenant_profile", "goal", "offer_catalog", "audience"],
            "expected_outputs": ["campaign_plan", "message_pillars", "launch_tasks"],
            "risk_level": "low",
            "target_domain": "business",
        }
    if any(keyword in combined for keyword in ("sales", "follow-up", "follow up", "pipeline", "lead")):
        return {
            "category": "sales",
            "proposed_tool_name": "Pipeline Follow-Up Builder",
            "expected_inputs": ["tenant_profile", "sales_context", "objections", "goal"],
            "expected_outputs": ["followup_sequence", "objection_playbook", "tasks"],
            "risk_level": "low",
            "target_domain": "business",
        }
    if any(keyword in combined for keyword in ("verify", "failure", "runtime", "diagnostic", "log", "health")):
        return {
            "category": "operations",
            "proposed_tool_name": "Failure Diagnostics Pack",
            "expected_inputs": ["failure_context", "log_paths", "recent_reports"],
            "expected_outputs": ["diagnostic_summary", "root_cause_candidates", "next_actions"],
            "risk_level": "medium",
            "target_domain": "system",
        }
    if any(keyword in combined for keyword in ("tenant", "onboarding", "profile", "coverage")):
        return {
            "category": "operations",
            "proposed_tool_name": "Tenant Coverage Builder",
            "expected_inputs": ["tenant_profile", "onboarding_state", "tool_catalog"],
            "expected_outputs": ["coverage_gaps", "recommended_tool_spec", "tasks"],
            "risk_level": "low",
            "target_domain": "business",
        }
    return {
        "category": "operations",
        "proposed_tool_name": "Workflow Capability Builder",
        "expected_inputs": ["context_summary", "goal", "constraints"],
        "expected_outputs": ["tool_spec_outline", "build_tasks", "risk_notes"],
        "risk_level": "medium" if normalize_behavior_domain(target_domain) in {"system", "security"} else "low",
        "target_domain": normalize_behavior_domain(target_domain),
    }


def find_matching_registry_tool(proposed_tool_name: str, category: str) -> dict[str, Any] | None:
    proposed_tokens = set(tool_factory_text_tokens(proposed_tool_name))
    category_value = normalize_short_text(category, max_len=64).lower()
    for tool in load_tool_registry_entries():
        contract = normalize_tool_contract(tool)
        candidate_tokens = set(
            tool_factory_text_tokens(contract.get("name")) + tool_factory_text_tokens(contract.get("tool_id"))
        )
        if proposed_tokens and (
            proposed_tokens == candidate_tokens
            or len(proposed_tokens & candidate_tokens) >= 2
            or normalize_tool_token(proposed_tool_name) == normalize_tool_token(contract.get("name"))
        ):
            return contract
        if category_value and category_value == normalize_short_text(contract.get("category"), max_len=64).lower():
            overlap = proposed_tokens & candidate_tokens
            if overlap:
                return contract
    return None


def apply_tool_factory_registry_linkage(record: dict[str, Any]) -> dict[str, Any]:
    spec = dict(record)
    matched = find_matching_registry_tool(spec.get("proposed_tool_name"), spec.get("category"))
    capability_state = "missing_capability"
    matched_tool_id = ""
    registry_status = ""
    if isinstance(matched, dict):
        matched_tool_id = normalize_text(matched.get("tool_id"))
        registry_status = normalize_text(matched.get("status"))
        capability_state = "existing_tool_available" if registry_status == "enabled" else "existing_tool_needs_improvement"
    spec["matched_tool_id"] = matched_tool_id
    spec["registry_status"] = registry_status
    spec["capability_state"] = capability_state
    spec["published_tool_id"] = normalize_text(spec.get("published_tool_id"))
    return spec


def sanitize_tool_factory_record(record: dict[str, Any]) -> dict[str, Any]:
    now = utc_now_iso()
    spec = {
        "spec_id": make_tool_factory_spec_id(
            title=record.get("title"),
            source=record.get("source"),
            target_domain=record.get("target_domain"),
            proposed_tool_name=record.get("proposed_tool_name"),
            linked_improvement_id=record.get("linked_improvement_id"),
            linked_behavior_id=record.get("linked_behavior_id"),
            requested_id=record.get("spec_id"),
        ),
        "title": normalize_short_text(record.get("title"), max_len=160),
        "category": normalize_short_text(record.get("category"), max_len=64).lower() or "operations",
        "target_domain": normalize_behavior_domain(record.get("target_domain")),
        "problem_statement": normalize_short_text(record.get("problem_statement"), max_len=320),
        "proposed_tool_name": normalize_short_text(record.get("proposed_tool_name"), max_len=120),
        "why_needed": normalize_short_text(record.get("why_needed"), max_len=320),
        "expected_inputs": normalize_tool_factory_list(record.get("expected_inputs")),
        "expected_outputs": normalize_tool_factory_list(record.get("expected_outputs")),
        "risk_level": normalize_behavior_risk_level(record.get("risk_level")),
        "tenant_scope": normalize_short_text(record.get("tenant_scope"), max_len=80) or "global",
        "source": normalize_tool_factory_source(record.get("source")),
        "linked_improvement_id": normalize_short_text(record.get("linked_improvement_id"), max_len=96),
        "linked_behavior_id": normalize_short_text(record.get("linked_behavior_id"), max_len=96),
        "status": normalize_tool_factory_status(record.get("status")),
        "created_at": normalize_short_text(record.get("created_at"), max_len=64) or now,
        "updated_at": normalize_short_text(record.get("updated_at"), max_len=64) or now,
        "history": [
            item for item in normalize_list(record.get("history")) if isinstance(item, dict)
        ],
        "published_tool_id": normalize_text(record.get("published_tool_id")),
    }
    if not spec["history"]:
        spec["history"] = [
            tool_factory_history_event(
                action="created",
                status=spec["status"],
                note=spec["title"],
            )
        ]
    return apply_tool_factory_registry_linkage(spec)


def build_tool_factory_record(payload: ToolOpportunityCreateRequest) -> dict[str, Any]:
    now = utc_now_iso()
    spec = {
        "spec_id": make_tool_factory_spec_id(
            title=payload.title,
            source=payload.source,
            target_domain=payload.target_domain,
            proposed_tool_name=payload.proposed_tool_name,
            linked_improvement_id=payload.linked_improvement_id or "",
            linked_behavior_id=payload.linked_behavior_id or "",
            requested_id=payload.spec_id or "",
        ),
        "title": normalize_short_text(payload.title, max_len=160),
        "category": normalize_short_text(payload.category, max_len=64).lower(),
        "target_domain": normalize_behavior_domain(payload.target_domain),
        "problem_statement": normalize_short_text(payload.problem_statement, max_len=320),
        "proposed_tool_name": normalize_short_text(payload.proposed_tool_name, max_len=120),
        "why_needed": normalize_short_text(payload.why_needed, max_len=320),
        "expected_inputs": normalize_tool_factory_list(payload.expected_inputs),
        "expected_outputs": normalize_tool_factory_list(payload.expected_outputs),
        "risk_level": normalize_behavior_risk_level(payload.risk_level),
        "tenant_scope": normalize_short_text(payload.tenant_scope, max_len=80) or "global",
        "source": normalize_tool_factory_source(payload.source),
        "linked_improvement_id": normalize_short_text(payload.linked_improvement_id, max_len=96),
        "linked_behavior_id": normalize_short_text(payload.linked_behavior_id, max_len=96),
        "status": normalize_tool_factory_status(payload.status),
        "created_at": now,
        "updated_at": now,
        "history": [
            tool_factory_history_event(
                action="created",
                status=payload.status,
                note=payload.title,
            )
        ],
        "published_tool_id": "",
    }
    return apply_tool_factory_registry_linkage(spec)


def tool_factory_sort_key(item: dict[str, Any]) -> tuple[int, int, str]:
    order = {
        "new": 0,
        "spec_ready": 1,
        "build_ready": 2,
        "built": 3,
        "tested": 4,
        "published": 5,
        "rejected": 6,
    }
    risk_order = {
        "critical": 0,
        "high": 1,
        "medium": 2,
        "low": 3,
    }
    return (
        order.get(normalize_tool_factory_status(item.get("status")), 9),
        risk_order.get(normalize_behavior_risk_level(item.get("risk_level")), 9),
        normalize_text(item.get("title")).lower(),
    )


def save_tool_factory_state(state: dict[str, Any]) -> dict[str, Any]:
    payload = empty_tool_factory_state()
    if isinstance(state, dict):
        payload.update(state)
    payload["version"] = 1
    payload["updated_at_utc"] = normalize_short_text(payload.get("updated_at_utc"), max_len=64) or utc_now_iso()
    specs = [sanitize_tool_factory_record(item) for item in normalize_list(payload.get("specs")) if isinstance(item, dict)]
    specs.sort(key=tool_factory_sort_key)
    payload["specs"] = specs
    write_json(TOOL_FACTORY_PATH, payload)
    write_json(TOOL_FACTORY_REPORT_PATH, payload)
    return payload


def load_tool_factory_state() -> dict[str, Any]:
    if not TOOL_FACTORY_PATH.exists():
        return save_tool_factory_state(empty_tool_factory_state())
    data = read_json(TOOL_FACTORY_PATH, default=empty_tool_factory_state())
    if not isinstance(data, dict):
        return save_tool_factory_state(empty_tool_factory_state())
    return save_tool_factory_state(data)


def summarize_tool_factory_brief(spec: dict[str, Any]) -> dict[str, Any]:
    return {
        "spec_id": normalize_text(spec.get("spec_id")),
        "title": normalize_short_text(spec.get("title"), max_len=160),
        "proposed_tool_name": normalize_short_text(spec.get("proposed_tool_name"), max_len=120),
        "category": normalize_short_text(spec.get("category"), max_len=64).lower(),
        "status": normalize_tool_factory_status(spec.get("status")),
        "capability_state": normalize_short_text(spec.get("capability_state"), max_len=40),
        "matched_tool_id": normalize_text(spec.get("matched_tool_id")),
        "updated_at": normalize_short_text(spec.get("updated_at"), max_len=64),
    }


def summarize_tool_factory_state(state: dict[str, Any] | None = None) -> dict[str, Any]:
    factory_state = state if isinstance(state, dict) else load_tool_factory_state()
    specs = [item for item in normalize_list(factory_state.get("specs")) if isinstance(item, dict)]
    by_status: dict[str, int] = {}
    by_source: dict[str, int] = {}
    by_domain: dict[str, int] = {}
    published_specs: list[dict[str, Any]] = []
    build_ready_specs: list[dict[str, Any]] = []
    new_specs: list[dict[str, Any]] = []
    for spec in specs:
        status = normalize_tool_factory_status(spec.get("status"))
        source = normalize_tool_factory_source(spec.get("source"))
        domain = normalize_behavior_domain(spec.get("target_domain"))
        by_status[status] = by_status.get(status, 0) + 1
        by_source[source] = by_source.get(source, 0) + 1
        by_domain[domain] = by_domain.get(domain, 0) + 1
        brief = summarize_tool_factory_brief(spec)
        if status == "published" and len(published_specs) < 5:
            published_specs.append(brief)
        if status == "build_ready" and len(build_ready_specs) < 5:
            build_ready_specs.append(brief)
        if status == "new" and len(new_specs) < 5:
            new_specs.append(brief)
    return {
        "total": len(specs),
        "new_total": int(by_status.get("new") or 0),
        "build_ready_total": int(by_status.get("build_ready") or 0),
        "published_total": int(by_status.get("published") or 0),
        "by_status": by_status,
        "by_source": by_source,
        "by_domain": by_domain,
        "new_specs": new_specs,
        "build_ready_specs": build_ready_specs,
        "published_specs": published_specs,
        "updated_at_utc": normalize_short_text(factory_state.get("updated_at_utc"), max_len=64),
        "artifact_path": str(TOOL_FACTORY_PATH),
        "report_path": str(TOOL_FACTORY_REPORT_PATH),
    }


def build_generated_tool_opportunity(
    *,
    title: str,
    problem_statement: str,
    why_needed: str,
    target_domain: str,
    tenant_scope: str,
    source: str,
    linked_improvement_id: str = "",
    linked_behavior_id: str = "",
) -> dict[str, Any]:
    blueprint = infer_tool_factory_blueprint(title, problem_statement, target_domain)
    now = utc_now_iso()
    spec = {
        "spec_id": make_tool_factory_spec_id(
            title=title,
            source=source,
            target_domain=blueprint.get("target_domain") or target_domain,
            proposed_tool_name=blueprint.get("proposed_tool_name") or title,
            linked_improvement_id=linked_improvement_id,
            linked_behavior_id=linked_behavior_id,
        ),
        "title": normalize_short_text(title, max_len=160),
        "category": normalize_short_text(blueprint.get("category"), max_len=64).lower(),
        "target_domain": normalize_behavior_domain(blueprint.get("target_domain") or target_domain),
        "problem_statement": normalize_short_text(problem_statement, max_len=320),
        "proposed_tool_name": normalize_short_text(blueprint.get("proposed_tool_name"), max_len=120),
        "why_needed": normalize_short_text(why_needed, max_len=320),
        "expected_inputs": normalize_tool_factory_list(blueprint.get("expected_inputs")),
        "expected_outputs": normalize_tool_factory_list(blueprint.get("expected_outputs")),
        "risk_level": normalize_behavior_risk_level(blueprint.get("risk_level")),
        "tenant_scope": normalize_short_text(tenant_scope, max_len=80) or "global",
        "source": normalize_tool_factory_source(source),
        "linked_improvement_id": normalize_short_text(linked_improvement_id, max_len=96),
        "linked_behavior_id": normalize_short_text(linked_behavior_id, max_len=96),
        "status": "new",
        "created_at": now,
        "updated_at": now,
        "history": [
            tool_factory_history_event(
                action="generated",
                status="new",
                note=title,
            )
        ],
        "published_tool_id": "",
    }
    return apply_tool_factory_registry_linkage(spec)


def generate_tool_factory_from_improvement_queue() -> list[dict[str, Any]]:
    specs: list[dict[str, Any]] = []
    queue_state = load_improvement_queue_state()
    for item in normalize_list(queue_state.get("items")):
        if not isinstance(item, dict) or not bool(item.get("is_current", True)):
            continue
        source = normalize_improvement_source(item.get("source"))
        target_type = normalize_improvement_target_type(item.get("target_type"))
        if source != "tool-gap" and target_type != "tool":
            continue
        title = normalize_short_text(item.get("title"), max_len=160) or "Tool capability gap"
        specs.append(
            build_generated_tool_opportunity(
                title=title,
                problem_statement=normalize_short_text(item.get("description") or item.get("reason"), max_len=320),
                why_needed=normalize_short_text(item.get("expected_outcome") or item.get("reason"), max_len=320),
                target_domain="business" if target_type == "tool" else target_type,
                tenant_scope=normalize_short_text(item.get("linked_tenant_id"), max_len=80) or "global",
                source="tool-gap" if source == "tool-gap" else "queue",
                linked_improvement_id=normalize_text(item.get("improvement_id")),
                linked_behavior_id=normalize_text(item.get("linked_behavior_id")),
            )
        )
    return specs


def generate_tool_factory_from_recommendation_gaps() -> list[dict[str, Any]]:
    specs: list[dict[str, Any]] = []
    if not ONYX_RECOMMENDATIONS_DIR.exists():
        return specs
    for path in sorted(ONYX_RECOMMENDATIONS_DIR.glob("*.json")):
        state = read_json(path, default={})
        if not isinstance(state, dict):
            continue
        tenant_id = normalize_optional_onyx_tenant_id(state.get("tenant_id") or path.stem)
        for recommendation in normalize_list(state.get("recommendations")):
            if not isinstance(recommendation, dict):
                continue
            status = normalize_text(recommendation.get("status")).lower()
            if status in {"dismissed", "completed"}:
                continue
            linked_tool_id = normalize_text(recommendation.get("linked_tool_id"))
            if linked_tool_id and get_tool_registry_entry(linked_tool_id):
                continue
            rec_title = normalize_short_text(recommendation.get("title"), max_len=160)
            if not rec_title:
                continue
            specs.append(
                build_generated_tool_opportunity(
                    title=f"Factory spec for {rec_title}",
                    problem_statement=normalize_short_text(recommendation.get("description") or recommendation.get("reason"), max_len=320),
                    why_needed=normalize_short_text(recommendation.get("reason") or recommendation.get("description"), max_len=320),
                    target_domain="business",
                    tenant_scope=tenant_id or "global",
                    source="recommendation",
                )
            )
    return specs


def generate_tool_factory_from_runtime_patterns() -> list[dict[str, Any]]:
    specs: list[dict[str, Any]] = []
    verify_state = read_json(VERIFY_LAST_PATH, default={})
    doctor_state = read_json(REPORTS / "mason2_doctor_report.json", default={})
    verify_status = normalize_text(verify_state.get("status")).upper() if isinstance(verify_state, dict) else ""
    doctor_result = normalize_text(doctor_state.get("overall_result")).upper() if isinstance(doctor_state, dict) else ""
    if verify_status in {"WARN", "FAIL"} or doctor_result == "FAIL":
        reason = "Repeated local runtime failures still require manual diagnostics."
        if verify_status in {"WARN", "FAIL"} and isinstance(verify_state, dict):
            reason = normalize_short_text(
                verify_state.get("recommended_next_action") or verify_state.get("failing_component") or reason,
                max_len=320,
            )
        specs.append(
            build_generated_tool_opportunity(
                title="Factory spec for failure diagnostics automation",
                problem_statement="Runtime and verify failures still rely on manual log inspection.",
                why_needed=reason,
                target_domain="system",
                tenant_scope="global",
                source="runtime",
            )
        )
    return specs


def generate_tool_factory_from_registry_gaps() -> list[dict[str, Any]]:
    specs: list[dict[str, Any]] = []
    workspace = load_onyx_workspace()
    for context in normalize_list(workspace.get("contexts")):
        if not isinstance(context, dict):
            continue
        tenant = context.get("tenant") if isinstance(context.get("tenant"), dict) else {}
        profile = context.get("profile") if isinstance(context.get("profile"), dict) else {}
        tenant_id = normalize_optional_onyx_tenant_id(tenant.get("id"))
        if not tenant_id:
            continue
        eligible_tools = 0
        for tool in load_tool_registry_entries():
            entry = sanitize_tool_catalog_entry(tool, context)
            if bool(entry.get("eligible")) and normalize_text(entry.get("status")).lower() == "enabled":
                eligible_tools += 1
        if eligible_tools == 0:
            business_name = normalize_short_text(profile.get("businessName"), max_len=160) or tenant_id
            specs.append(
                build_generated_tool_opportunity(
                    title=f"Factory spec for {business_name} starter capability",
                    problem_statement="This tenant currently has no eligible enabled tools in the registry.",
                    why_needed="Factory should stage at least one tenant-safe starter capability before recommendations stall.",
                    target_domain="business",
                    tenant_scope=tenant_id,
                    source="tool-gap",
                )
            )
    return specs


def merge_tool_factory_state(generated_specs: list[dict[str, Any]]) -> dict[str, Any]:
    existing_state = load_tool_factory_state()
    existing_map = {
        normalize_text(item.get("spec_id")): item
        for item in normalize_list(existing_state.get("specs"))
        if isinstance(item, dict)
    }
    merged: list[dict[str, Any]] = []
    generated_ids: set[str] = set()
    now = utc_now_iso()
    for spec in generated_specs:
        spec_id = normalize_text(spec.get("spec_id"))
        if not spec_id:
            continue
        generated_ids.add(spec_id)
        prior = existing_map.get(spec_id)
        merged_spec = dict(spec)
        if isinstance(prior, dict):
            merged_spec["status"] = normalize_tool_factory_status(prior.get("status") or spec.get("status"))
            merged_spec["created_at"] = normalize_short_text(prior.get("created_at") or spec.get("created_at"), max_len=64)
            merged_spec["published_tool_id"] = normalize_text(prior.get("published_tool_id") or spec.get("published_tool_id"))
            merged_spec["updated_at"] = now if any(
                normalize_text(prior.get(field)) != normalize_text(spec.get(field))
                for field in (
                    "title",
                    "category",
                    "target_domain",
                    "problem_statement",
                    "proposed_tool_name",
                    "why_needed",
                    "risk_level",
                    "tenant_scope",
                    "matched_tool_id",
                    "capability_state",
                )
            ) else normalize_short_text(prior.get("updated_at") or spec.get("updated_at"), max_len=64)
            merged_spec["history"] = [
                item for item in normalize_list(prior.get("history")) if isinstance(item, dict)
            ] or merged_spec.get("history", [])
        merged.append(apply_tool_factory_registry_linkage(merged_spec))
    for spec_id, prior in existing_map.items():
        if spec_id in generated_ids:
            continue
        merged.append(apply_tool_factory_registry_linkage(dict(prior)))
    return save_tool_factory_state(
        {
            "version": 1,
            "updated_at_utc": now,
            "specs": merged,
        }
    )


def refresh_tool_factory(sources: list[str] | None = None) -> dict[str, Any]:
    requested = {normalize_tool_factory_source(item) for item in (sources or []) if normalize_text(item)}
    if not requested:
        requested = {"queue", "recommendation", "runtime", "tool-gap"}
    generated: list[dict[str, Any]] = []
    if "queue" in requested:
        generated.extend(generate_tool_factory_from_improvement_queue())
    if "recommendation" in requested:
        generated.extend(generate_tool_factory_from_recommendation_gaps())
    if "runtime" in requested:
        generated.extend(generate_tool_factory_from_runtime_patterns())
    if "tool-gap" in requested:
        generated.extend(generate_tool_factory_from_registry_gaps())
    return merge_tool_factory_state(generated)


def create_or_update_tool_opportunity(payload: ToolOpportunityCreateRequest) -> dict[str, Any]:
    state = load_tool_factory_state()
    spec = build_tool_factory_record(payload)
    spec_id = normalize_text(spec.get("spec_id"))
    specs = [item for item in normalize_list(state.get("specs")) if isinstance(item, dict)]
    for index, existing in enumerate(specs):
        if normalize_text(existing.get("spec_id")) != spec_id:
            continue
        updated = dict(spec)
        updated["status"] = normalize_tool_factory_status(existing.get("status") or spec.get("status"))
        updated["created_at"] = normalize_short_text(existing.get("created_at") or spec.get("created_at"), max_len=64)
        updated["published_tool_id"] = normalize_text(existing.get("published_tool_id") or spec.get("published_tool_id"))
        updated["updated_at"] = utc_now_iso()
        history = [item for item in normalize_list(existing.get("history")) if isinstance(item, dict)]
        history.append(
            tool_factory_history_event(
                action="metadata_update",
                status=updated["status"],
                note=updated["title"],
            )
        )
        updated["history"] = history
        specs[index] = apply_tool_factory_registry_linkage(updated)
        state["specs"] = specs
        state["updated_at_utc"] = utc_now_iso()
        return save_tool_factory_state(state)
    specs.append(spec)
    state["specs"] = specs
    state["updated_at_utc"] = utc_now_iso()
    return save_tool_factory_state(state)


def can_transition_tool_factory_status(current_status: str, next_status: str) -> bool:
    current_value = normalize_tool_factory_status(current_status)
    next_value = normalize_tool_factory_status(next_status)
    if current_value == next_value:
        return True
    allowed = {
        "new": {"spec_ready", "rejected"},
        "spec_ready": {"build_ready", "rejected"},
        "build_ready": {"built", "rejected"},
        "built": {"tested", "rejected"},
        "tested": {"published", "rejected"},
        "published": set(),
        "rejected": {"spec_ready"},
    }
    return next_value in allowed.get(current_value, set())


def update_tool_opportunity_status(payload: ToolOpportunityStatusRequest) -> tuple[dict[str, Any] | None, str]:
    state = load_tool_factory_state()
    spec_id = normalize_text(payload.spec_id)
    next_status = normalize_tool_factory_status(payload.status)
    specs = [item for item in normalize_list(state.get("specs")) if isinstance(item, dict)]
    for index, spec in enumerate(specs):
        if normalize_text(spec.get("spec_id")) != spec_id:
            continue
        current_status = normalize_tool_factory_status(spec.get("status"))
        if not can_transition_tool_factory_status(current_status, next_status):
            return None, "invalid_transition"
        updated = dict(spec)
        updated["status"] = next_status
        updated["updated_at"] = utc_now_iso()
        history = [item for item in normalize_list(spec.get("history")) if isinstance(item, dict)]
        history.append(
            tool_factory_history_event(
                action="status_update",
                status=next_status,
                note=payload.note,
            )
        )
        updated["history"] = history
        specs[index] = apply_tool_factory_registry_linkage(updated)
        state["specs"] = specs
        state["updated_at_utc"] = utc_now_iso()
        return save_tool_factory_state(state), ""
    return None, "spec_not_found"


def save_tool_registry_document(document: dict[str, Any]) -> dict[str, Any]:
    payload = document if isinstance(document, dict) else {"version": 2, "tools": []}
    if not isinstance(payload.get("tools"), list):
        payload["tools"] = []
    if "version" not in payload:
        payload["version"] = 2
    write_json(TOOL_REGISTRY_PATH, payload)
    return payload


def tool_factory_list_to_schema(items: list[str], *, kind: str) -> dict[str, Any]:
    properties: dict[str, Any] = {}
    required: list[str] = []
    for index, item in enumerate(items):
        key = re.sub(r"[^a-z0-9]+", "_", normalize_text(item).lower()).strip("_") or f"{kind}_{index + 1}"
        properties[key] = {"type": "string", "title": normalize_short_text(item, max_len=120)}
        if index < 2:
            required.append(key)
    return {
        "required": required,
        "properties": properties,
    }


def registry_entry_from_tool_spec(spec: dict[str, Any]) -> dict[str, Any]:
    tenant_scope = normalize_short_text(spec.get("tenant_scope"), max_len=80) or "global"
    allowed_tenant_ids = [tenant_scope] if tenant_scope not in {"", "global"} else []
    risk_mapping = {
        "low": "R1",
        "medium": "R2",
        "high": "R3",
        "critical": "R4",
    }
    tool_id_seed = re.sub(r"[^a-z0-9]+", "_", normalize_text(spec.get("proposed_tool_name")).lower()).strip("_")
    tool_id = normalize_short_text(f"{tool_id_seed}_v1", max_len=80) or normalize_short_text(spec.get("spec_id"), max_len=80)
    return {
        "tool_id": tool_id,
        "name": normalize_short_text(spec.get("proposed_tool_name"), max_len=120),
        "version": "0.1.0",
        "category": normalize_short_text(spec.get("category"), max_len=64).lower() or "operations",
        "description": normalize_short_text(
            spec.get("problem_statement") or spec.get("why_needed") or spec.get("title"),
            max_len=400,
        ),
        "risk_level": risk_mapping.get(normalize_behavior_risk_level(spec.get("risk_level")), "R2"),
        "budget_class": "LOW",
        "status": "disabled",
        "enabled": False,
        "required_integrations": [],
        "created_at": utc_now_iso(),
        "updated_at": utc_now_iso(),
        "tenant_eligibility": {
            "allowed_statuses": ["active", "pilot"],
            "allowed_plan_tiers": [],
            "business_types": ["agency", "retail", "service", "consulting", "saas", "other"],
            "allowed_tenant_ids": allowed_tenant_ids,
            "minimum_onboarding_completion_percent": 0,
            "require_onboarding_completed": False,
        },
        "tags": ["factory", "staged", normalize_tool_factory_source(spec.get("source"))],
        "supported_business_types": ["agency", "retail", "service", "consulting", "saas", "other"],
        "input_schema": tool_factory_list_to_schema(normalize_tool_factory_list(spec.get("expected_inputs")), kind="input"),
        "output_schema": {"properties": tool_factory_list_to_schema(normalize_tool_factory_list(spec.get("expected_outputs")), kind="output").get("properties", {})},
        "factory_spec_id": normalize_text(spec.get("spec_id")),
    }


def publish_tool_opportunity(payload: ToolOpportunityPublishRequest) -> tuple[dict[str, Any] | None, str]:
    state = load_tool_factory_state()
    spec_id = normalize_text(payload.spec_id)
    specs = [item for item in normalize_list(state.get("specs")) if isinstance(item, dict)]
    target_spec = None
    target_index = -1
    for index, spec in enumerate(specs):
        if normalize_text(spec.get("spec_id")) == spec_id:
            target_spec = dict(spec)
            target_index = index
            break
    if target_spec is None:
        return None, "spec_not_found"
    if normalize_tool_factory_status(target_spec.get("status")) not in {"tested", "published"}:
        return None, "spec_not_ready_to_publish"

    registry = load_tool_registry_document()
    tools = [tool for tool in normalize_list(registry.get("tools")) if isinstance(tool, dict)]
    matched_tool_id = normalize_text(target_spec.get("matched_tool_id"))
    published_tool_id = ""
    updated_registry = False
    if matched_tool_id:
        for index, tool in enumerate(tools):
            if normalize_text(tool.get("tool_id")) != matched_tool_id:
                continue
            updated_tool = dict(tool)
            factory_spec_ids = normalize_tool_factory_list(updated_tool.get("factory_spec_ids"), max_items=24, max_len=96)
            if spec_id not in factory_spec_ids:
                factory_spec_ids.append(spec_id)
            updated_tool["factory_spec_ids"] = factory_spec_ids
            updated_tool["updated_at"] = utc_now_iso()
            tags = normalize_tool_factory_list(updated_tool.get("tags"), max_items=24, max_len=64)
            if "factory-linked" not in [tag.lower() for tag in tags]:
                tags.append("factory-linked")
            updated_tool["tags"] = tags
            tools[index] = updated_tool
            published_tool_id = matched_tool_id
            updated_registry = True
            break
    if not updated_registry:
        new_entry = registry_entry_from_tool_spec(target_spec)
        published_tool_id = normalize_text(new_entry.get("tool_id"))
        tools.append(new_entry)
    registry["tools"] = tools
    save_tool_registry_document(registry)

    target_spec["status"] = "published"
    target_spec["published_tool_id"] = published_tool_id
    target_spec["updated_at"] = utc_now_iso()
    history = [item for item in normalize_list(target_spec.get("history")) if isinstance(item, dict)]
    history.append(
        tool_factory_history_event(
            action="published",
            status="published",
            note=published_tool_id,
        )
    )
    target_spec["history"] = history
    specs[target_index] = apply_tool_factory_registry_linkage(target_spec)
    state["specs"] = specs
    state["updated_at_utc"] = utc_now_iso()
    return save_tool_factory_state(state), ""
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
            "/api/stack_status",
            "/api/ingest_chunk",
            "/api/ingest_index",
            "/api/onyx/business_context*",
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
        "/api/stack_status",
        "/api/auth/pair/start",
        "/api/auth/pair/complete",
    }
    if path in hard_exempt:
        return True
    if path.startswith("/api/onyx/business_context"):
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


def is_loopback_unsigned_tool_path(path: str, client_ip: str) -> bool:
    try:
        ip_obj = ipaddress.ip_address(client_ip)
    except Exception:
        return False
    if not ip_obj.is_loopback:
        return False
    return path in {
        "/api/tools/catalog",
        "/api/tools/run",
        "/api/tools/runs/latest",
        "/api/onyx/recommendations",
        "/api/onyx/recommendations/refresh",
        "/api/onyx/recommendations/status",
        "/api/billing/summary",
        "/api/billing/checkout_session",
        "/api/billing/portal",
    }


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
    improvement_summary = summarize_improvement_queue_state()
    return {
        "pending_llm_chunks": pending_llm_count,
        "approvals_total": approvals_total,
        "improvements_total": improvement_summary.get("total", 0),
        "improvements_current_total": improvement_summary.get("current_total", 0),
        "improvements_approval_required_total": improvement_summary.get("approval_required_total", 0),
        "improvements_by_status": improvement_summary.get("by_status", {}),
        "improvements_updated_at_utc": improvement_summary.get("updated_at_utc", ""),
    }


def resolve_stack_ports() -> dict[str, int]:
    defaults = {
        "mason_api": 8383,
        "seed_api": 8109,
        "bridge": 8484,
        "athena": 8000,
        "onyx": 5353,
    }
    contract = load_ports_contract()
    ports_obj = contract.get("ports") if isinstance(contract, dict) else {}
    if not isinstance(ports_obj, dict):
        return defaults

    for key, fallback in defaults.items():
        raw = ports_obj.get(key, fallback)
        try:
            parsed = int(str(raw).strip())
            if 1 <= parsed <= 65535:
                defaults[key] = parsed
        except Exception:
            continue
    return defaults


def parse_endpoint_port(endpoint: str) -> int | None:
    match = re.search(r":(\d+)$", str(endpoint or "").strip())
    if not match:
        return None
    try:
        port = int(match.group(1))
        if 1 <= port <= 65535:
            return port
    except Exception:
        return None
    return None


def netstat_listener_map(target_ports: list[int]) -> dict[int, list[dict[str, Any]]]:
    wanted = sorted({int(port) for port in target_ports if isinstance(port, int) and port > 0})
    out: dict[int, list[dict[str, Any]]] = {port: [] for port in wanted}
    if not wanted:
        return out

    try:
        proc = subprocess.run(
            ["netstat", "-ano", "-p", "tcp"],
            capture_output=True,
            text=True,
            timeout=8,
            check=False,
        )
    except Exception:
        return out

    pattern = re.compile(r"^\s*TCP\s+(\S+)\s+\S+\s+LISTENING\s+(\d+)\s*$", re.IGNORECASE)
    for line in (proc.stdout or "").splitlines():
        match = pattern.match(line.strip())
        if not match:
            continue

        endpoint = str(match.group(1))
        port = parse_endpoint_port(endpoint)
        if port is None or port not in out:
            continue

        try:
            owner_pid = int(match.group(2))
        except Exception:
            continue
        if owner_pid <= 0:
            continue

        address_match = re.match(r"^(.*):(\d+)$", endpoint)
        local_address = endpoint
        if address_match:
            local_address = str(address_match.group(1))

        out[port].append(
            {
                "local_address": local_address,
                "local_port": port,
                "owning_pid": owner_pid,
            }
        )

    for port in out:
        out[port] = sorted(out[port], key=lambda row: (int(row.get("owning_pid", 0)), str(row.get("local_address", ""))))
    return out


def probe_http_ready(url: str, timeout_sec: int = 3) -> dict[str, Any]:
    probe: dict[str, Any] = {
        "url": url,
        "ready": False,
        "status_code": 0,
        "error": None,
        "checked_at_utc": utc_now_iso(),
    }
    try:
        request = urllib.request.Request(url, method="GET")
        with urllib.request.urlopen(request, timeout=timeout_sec) as response:
            status_code = int(getattr(response, "status", 0) or response.getcode() or 0)
        probe["status_code"] = status_code
        probe["ready"] = 200 <= status_code < 400
        return probe
    except urllib.error.HTTPError as exc:
        probe["status_code"] = int(getattr(exc, "code", 0) or 0)
        probe["error"] = str(exc)
        return probe
    except Exception as exc:
        probe["error"] = str(exc)
        return probe


def format_bytes_human(value: Any) -> str:
    try:
        size = float(value)
    except Exception:
        return "n/a"
    for unit in ["B", "KB", "MB", "GB", "TB"]:
        if abs(size) < 1024.0 or unit == "TB":
            return f"{int(size)} {unit}" if unit == "B" else f"{size:.1f} {unit}"
        size /= 1024.0
    return "n/a"


def format_duration_human(total_seconds: Any) -> str:
    try:
        seconds = max(0, int(float(total_seconds)))
    except Exception:
        return "n/a"
    days, remainder = divmod(seconds, 86400)
    hours, remainder = divmod(remainder, 3600)
    minutes, _ = divmod(remainder, 60)
    parts: list[str] = []
    if days:
        parts.append(f"{days}d")
    if days or hours:
        parts.append(f"{hours}h")
    parts.append(f"{minutes}m")
    return " ".join(parts)


def tail_text_lines(path: Path | None, max_lines: int = 50) -> list[str]:
    if path is None or max_lines <= 0 or not path.exists():
        return []
    try:
        with path.open("rb") as handle:
            handle.seek(0, os.SEEK_END)
            position = handle.tell()
            data = b""
            lines: list[bytes] = []
            while position > 0 and len(lines) <= max_lines:
                read_size = min(4096, position)
                position -= read_size
                handle.seek(position)
                data = handle.read(read_size) + data
                lines = data.splitlines()
        return [redact_secrets(line.decode("utf-8", errors="ignore")).rstrip() for line in lines[-max_lines:] if line.strip()]
    except Exception:
        return []


def build_recent_actions(limit: int = 50) -> list[dict[str, Any]]:
    if limit <= 0 or not EVENTS_PATH.exists():
        return []
    rows: list[dict[str, Any]] = []
    for line in tail_text_lines(EVENTS_PATH, max_lines=max(limit * 4, limit)):
        item = extract_json_object(line)
        if not item:
            continue
        details = item.get("details") if isinstance(item.get("details"), dict) else {}
        if not details and isinstance(item.get("data"), dict):
            details = item.get("data")
        summary = ""
        for key in ("reason", "error", "detail", "path", "report_path", "run_id", "commit_message"):
            if isinstance(details, dict):
                summary = normalize_text(details.get(key))
            if summary:
                break
        if not summary and isinstance(details, dict) and details:
            summary = first_sentence_summary(json.dumps(details, ensure_ascii=False))
        rows.append(
            {
                "timestamp_utc": normalize_text(item.get("ts_utc") or item.get("ts")),
                "kind": normalize_text(item.get("kind") or item.get("event")),
                "status": normalize_text(item.get("status") or item.get("level")),
                "component": normalize_text(item.get("component")),
                "summary": summary,
            }
        )
    return list(reversed(rows[-limit:]))


def get_quarantined_approvals() -> list[dict[str, Any]]:
    data = read_json(PENDING_PATCHES_QUARANTINE, default=[])
    if isinstance(data, dict):
        data = [data]
    return [item for item in normalize_list(data) if isinstance(item, dict)]


def get_approvals_history() -> list[dict[str, Any]]:
    data = read_json(APPROVALS_HISTORY_PATH, default=[])
    if isinstance(data, dict):
        data = [data]
    return [item for item in normalize_list(data) if isinstance(item, dict)]


def approval_reason_summary(item: dict[str, Any]) -> str:
    source = normalize_text(item.get("source") or item.get("kind") or "manual")
    domain = normalize_text(item.get("domain"))
    area = normalize_text(item.get("area"))
    parts = [component_label(normalize_component_id(item.get("component_id"))), source]
    if area:
        parts.append(area)
    if domain:
        parts.append(domain)
    return " / ".join(part for part in parts if part)


def approval_recommended_action(item: dict[str, Any]) -> str:
    risk = normalize_founder_risk_level(item.get("risk_level"))
    if risk in {"R3", "R4"}:
        return "Review scope carefully before deciding. Reject if the change expands risk, exposure, or tenant impact."
    if risk == "R2":
        return "Review the title and component before approving. Reject if the scope no longer matches the intended work."
    return "Approve only if the title still matches the intended work. Reject if the scope is stale or unclear."


def build_actionable_approval_item(item: dict[str, Any]) -> dict[str, Any]:
    component_id = normalize_component_id(item.get("component_id"))
    status = normalize_text(item.get("status")).lower() or "pending"
    evidence_files = item.get("evidence_files")
    if isinstance(evidence_files, list):
        source_path = normalize_text(evidence_files[0] if evidence_files else "")
    else:
        source_path = normalize_text(evidence_files)
    source_path = source_path or str(PENDING_PATCHES)
    return {
        "approval_id": normalize_text(item.get("id")),
        "title": normalize_text(item.get("title")) or component_label(component_id) or "Pending approval",
        "component_id": component_id,
        "component_label": component_label(component_id),
        "risk_level": normalize_founder_risk_level(item.get("risk_level")),
        "status": status,
        "created_at": normalize_text(item.get("created_at")),
        "source": normalize_text(item.get("source") or item.get("kind") or "manual"),
        "why_approval_needed": approval_reason_summary(item),
        "recommended_action": approval_recommended_action(item),
        "source_path": source_path,
        "can_approve": status == "pending",
        "can_reject": status == "pending",
        "disabled_reason": "" if status == "pending" else f"Approval is already {status}.",
    }


def build_approvals_section(items: list[dict[str, Any]] | None = None) -> dict[str, Any]:
    items = items if isinstance(items, list) else get_approvals()
    by_status: dict[str, int] = {}
    by_risk: dict[str, int] = {}
    for item in items:
        status = normalize_text(item.get("status")) or "unknown"
        risk = normalize_text(item.get("risk_level")) or "unknown"
        by_status[status] = by_status.get(status, 0) + 1
        by_risk[risk] = by_risk.get(risk, 0) + 1
    posture_path = REPORTS / "approvals_posture.json"
    posture = read_json(posture_path, default={})
    counts = posture.get("counts") if isinstance(posture, dict) and isinstance(posture.get("counts"), dict) else {}
    eligible_by_status = counts.get("eligible_by_status") if isinstance(counts.get("eligible_by_status"), dict) else {}
    pending_items = [
        item for item in items if normalize_text(item.get("status")).lower() == "pending"
    ]
    quarantine_items = get_quarantined_approvals()
    actionable_items = [
        build_actionable_approval_item(item)
        for item in sorted(
            pending_items,
            key=lambda row: (
                -founder_risk_sort_value(row.get("risk_level")),
                normalize_text(row.get("created_at")),
            ),
        )[:8]
    ]
    return {
        "path": str(posture_path),
        "generated_at_utc": normalize_text(posture.get("generated_at_utc")) if isinstance(posture, dict) else "",
        "pending_total": len(pending_items),
        "by_status": by_status,
        "by_risk": by_risk,
        "eligible_total": len(items),
        "quarantine_total": len(quarantine_items),
        "approved_total": int(by_status.get("approved") or eligible_by_status.get("approved") or 0),
        "executed_total": int(by_status.get("executed") or eligible_by_status.get("executed") or 0),
        "actionable_items": actionable_items,
        "quarantine_path": str(PENDING_PATCHES_QUARANTINE),
        "history_path": str(APPROVALS_HISTORY_PATH),
    }


def build_autonomy_summary(security_summary: dict[str, Any] | None = None) -> dict[str, Any]:
    teacher_policy = load_teacher_policy()
    core_status = read_json(MASON_CORE_STATUS_PATH, default={})
    inventory = read_json(COMPONENT_INVENTORY_PATH, default={})
    behavior_summary = summarize_behavior_trust_state()
    tool_factory_summary = summarize_tool_factory_state()
    billing_summary = build_billing_summary()
    security = security_summary if isinstance(security_summary, dict) else summarize_security_posture()
    guardrails = core_status.get("policy_guardrails") if isinstance(core_status, dict) and isinstance(core_status.get("policy_guardrails"), dict) else {}
    inventory_summary = inventory.get("summary") if isinstance(inventory, dict) and isinstance(inventory.get("summary"), dict) else {}
    drift_high_risk = int(inventory_summary.get("drift_high_risk_count") or 0)
    if bool(guardrails.get("high_risk_auto_apply")) or bool(guardrails.get("money_loop_enabled")):
        trust_posture = "restricted"
    elif drift_high_risk > 0:
        trust_posture = "watch"
    else:
        trust_posture = "guarded"
    return {
        "trust_posture": trust_posture,
        "local_first": bool(teacher_policy.get("local_first", True)),
        "memoize_ingest_by_sha256": bool(teacher_policy.get("memoize_ingest_by_sha256", True)),
        "memoize_chat_by_query": bool(teacher_policy.get("memoize_chat_by_query", True)),
        "high_risk_auto_apply": bool(guardrails.get("high_risk_auto_apply", False)),
        "money_loop_enabled": bool(guardrails.get("money_loop_enabled", False)),
        "drift_findings_total": int(inventory_summary.get("drift_findings_total") or 0),
        "drift_high_risk_count": drift_high_risk,
        "behavior_total": int(behavior_summary.get("total") or 0),
        "behavior_auto_allowed_total": int(behavior_summary.get("auto_allowed_total") or 0),
        "behavior_blocked_total": int(behavior_summary.get("blocked_total") or 0),
        "behavior_awaiting_approval_total": int(behavior_summary.get("awaiting_approval_total") or 0),
        "behavior_trusted_total": int(behavior_summary.get("trusted_total") or 0),
        "behavior_by_trust_state": behavior_summary.get("by_trust_state", {}),
        "blocked_behaviors": behavior_summary.get("blocked_behaviors", []),
        "awaiting_approval_behaviors": behavior_summary.get("awaiting_approval_behaviors", []),
        "trusted_behaviors": behavior_summary.get("trusted_behaviors", []),
        "behavior_store_path": str(BEHAVIOR_TRUST_PATH),
        "behavior_report_path": str(BEHAVIOR_TRUST_REPORT_PATH),
        "trust_index_path": str(TRUST_INDEX_PATH),
        "tool_factory_total": int(tool_factory_summary.get("total") or 0),
        "tool_factory_new_total": int(tool_factory_summary.get("new_total") or 0),
        "tool_factory_build_ready_total": int(tool_factory_summary.get("build_ready_total") or 0),
        "tool_factory_published_total": int(tool_factory_summary.get("published_total") or 0),
        "tool_factory_by_status": tool_factory_summary.get("by_status", {}),
        "tool_factory_path": str(TOOL_FACTORY_PATH),
        "tool_factory_report_path": str(TOOL_FACTORY_REPORT_PATH),
        "money_actions_require_approval": bool(billing_summary.get("money_actions_require_approval", True)),
        "billing_active_subscriptions_total": int((billing_summary.get("subscription_counts") or {}).get("active") or 0),
        "billing_trialing_total": int((billing_summary.get("subscription_counts") or {}).get("trialing") or 0),
        "billing_mrr_usd": float((billing_summary.get("revenue") or {}).get("mrr_usd") or 0.0),
        "billing_summary_path": str(BILLING_SUMMARY_PATH),
        "security_posture_status": normalize_short_text(security.get("overall_status"), max_len=24) or "guarded",
        "tenant_isolation_issues_total": int(security.get("tenant_isolation_issues_total") or 0),
        "audit_events_24h": int(security.get("audit_events_24h") or 0),
        "open_data_requests_total": int(security.get("open_data_requests_total") or 0),
        "rbac_roles_total": int(security.get("rbac_roles_total") or 0),
        "non_loopback_bindings_total": int(security.get("non_loopback_bindings_total") or 0),
        "security_posture_path": str(SECURITY_POSTURE_PATH),
        "tenant_safety_report_path": str(TENANT_SAFETY_REPORT_PATH),
        "component_inventory_path": str(COMPONENT_INVENTORY_PATH),
        "core_status_path": str(MASON_CORE_STATUS_PATH),
    }


def build_system_health_summary() -> dict[str, Any]:
    cache = getattr(build_system_health_summary, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 5.0:
        return cache["payload"]
    cpu_percent = None
    try:
        proc = subprocess.run(
            ["powershell.exe", "-NoLogo", "-NoProfile", "-Command", '$sample=(Get-Counter "\\Processor(_Total)\\% Processor Time").CounterSamples[0].CookedValue; [Math]::Round($sample,1)'],
            capture_output=True,
            text=True,
            timeout=5,
            cwd=str(BASE),
        )
        if proc.returncode == 0:
            lines = [line.strip() for line in (proc.stdout or "").splitlines() if line.strip()]
            if lines:
                cpu_percent = float(lines[-1])
    except Exception:
        cpu_percent = None
    memory_total = 0
    memory_available = 0
    try:
        class MEMORYSTATUSEX(ctypes.Structure):
            _fields_ = [("dwLength", ctypes.c_ulong), ("dwMemoryLoad", ctypes.c_ulong), ("ullTotalPhys", ctypes.c_ulonglong), ("ullAvailPhys", ctypes.c_ulonglong), ("ullTotalPageFile", ctypes.c_ulonglong), ("ullAvailPageFile", ctypes.c_ulonglong), ("ullTotalVirtual", ctypes.c_ulonglong), ("ullAvailVirtual", ctypes.c_ulonglong), ("ullAvailExtendedVirtual", ctypes.c_ulonglong)]
        status = MEMORYSTATUSEX()
        status.dwLength = ctypes.sizeof(MEMORYSTATUSEX)
        if ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(status)):
            memory_total = int(status.ullTotalPhys)
            memory_available = int(status.ullAvailPhys)
    except Exception:
        memory_total = 0
        memory_available = 0
    disk_total = 0
    disk_free = 0
    try:
        usage = shutil.disk_usage(BASE.anchor or "C:\\")
        disk_total = int(usage.total)
        disk_free = int(usage.free)
    except Exception:
        disk_total = 0
        disk_free = 0
    uptime_seconds = 0
    try:
        uptime_seconds = int(ctypes.windll.kernel32.GetTickCount64() / 1000)
    except Exception:
        uptime_seconds = 0
    memory_used_percent = round(((memory_total - memory_available) / memory_total) * 100.0, 1) if memory_total else None
    payload = {
        "captured_at_utc": utc_now_iso(),
        "cpu_percent": cpu_percent,
        "memory_total_bytes": memory_total,
        "memory_available_bytes": memory_available,
        "memory_used_percent": memory_used_percent,
        "memory_used_human": format_bytes_human(memory_total - memory_available) if memory_total else "n/a",
        "memory_total_human": format_bytes_human(memory_total),
        "disk_total_bytes": disk_total,
        "disk_free_bytes": disk_free,
        "disk_free_human": format_bytes_human(disk_free),
        "uptime_seconds": uptime_seconds,
        "uptime_human": format_duration_human(uptime_seconds),
    }
    build_system_health_summary._cache = {"ts": now_monotonic, "payload": payload}
    return payload


def normalize_component_id(value: Any) -> str:
    raw = normalize_text(value).lower().replace(" ", "_")
    return {"mason": "core", "mason_core": "core", "masonconsole": "athena", "seed": "seed_api"}.get(raw, raw)


def component_label(component_id: str) -> str:
    labels = {"core": "Mason Core", "mason_api": "Mason API", "seed_api": "Seed API", "bridge": "Bridge", "athena": "Athena", "onyx": "Onyx", "launcher": "Launcher"}
    normalized = normalize_component_id(component_id)
    return labels.get(normalized, normalized.replace("_", " ").title() or "Unknown")


def component_aliases(component_id: str) -> list[str]:
    normalized = normalize_component_id(component_id)
    aliases = [normalized]
    if normalized in {"mason_api", "seed_api", "launcher"}:
        aliases.append("core")
    if normalized == "core":
        aliases.extend(["mason_api", "seed_api"])
    deduped: list[str] = []
    for alias in aliases:
        clean = normalize_component_id(alias)
        if clean and clean not in deduped:
            deduped.append(clean)
    return deduped


def component_matches(target: Any, candidate: Any) -> bool:
    return bool(set(component_aliases(str(target or ""))).intersection(component_aliases(str(candidate or ""))))


def latest_path_by_patterns(directory: Path, patterns: list[str]) -> Path | None:
    if not directory.exists():
        return None
    latest_path = None
    latest_mtime = 0.0
    seen: set[str] = set()
    for pattern in patterns:
        try:
            matches = list(directory.glob(pattern))
        except Exception:
            matches = []
        for candidate in matches:
            if not candidate.is_file():
                continue
            key = str(candidate.resolve())
            if key in seen:
                continue
            seen.add(key)
            try:
                mtime = candidate.stat().st_mtime
            except Exception:
                continue
            if latest_path is None or mtime > latest_mtime:
                latest_path = candidate
                latest_mtime = mtime
    return latest_path


def resolve_log_paths_for_component(component_id: str, start_run_data: dict[str, Any], last_failure_data: dict[str, Any] | None) -> dict[str, str]:
    stdout_path = None
    stderr_path = None

    def pick_path(value: Any):
        resolved = resolve_artifact_path_in_repo(str(value or ""))
        return resolved if resolved and resolved.exists() else None

    if isinstance(last_failure_data, dict):
        for failure in normalize_list(last_failure_data.get("failures")):
            if not isinstance(failure, dict) or not component_matches(component_id, failure.get("component")):
                continue
            stderr_path = stderr_path or pick_path(failure.get("stderr_log"))
            stdout_path = stdout_path or pick_path(failure.get("stdout_log"))

    for launch in normalize_list(start_run_data.get("launch_results")):
        if not isinstance(launch, dict) or not component_matches(component_id, launch.get("component")):
            continue
        stderr_path = stderr_path or pick_path(launch.get("stderr_log"))
        stdout_path = stdout_path or pick_path(launch.get("stdout_log"))

    stderr_patterns: list[str] = []
    stdout_patterns: list[str] = []
    for alias in component_aliases(component_id):
        stderr_patterns.extend([f"*_{alias}_*_stderr.log", f"{alias}_*_stderr.log", f"{alias}*stderr*.log"])
        stdout_patterns.extend([f"*_{alias}_*_stdout.log", f"{alias}_*_stdout.log", f"{alias}*stdout*.log"])
    for directory in [REPORTS / "start", REPORTS, BASE / "logs"]:
        if not stderr_path:
            stderr_path = latest_path_by_patterns(directory, stderr_patterns)
        if not stdout_path:
            stdout_path = latest_path_by_patterns(directory, stdout_patterns)
    log_path = stderr_path or stdout_path
    return {"stdout_log": str(stdout_path) if stdout_path else "", "stderr_log": str(stderr_path) if stderr_path else "", "log_path": str(log_path) if log_path else ""}


def find_latest_exact_component_stderr_log(component_id: str) -> str:
    normalized = normalize_component_id(component_id)
    if not normalized:
        return ""
    patterns = [f"*_{normalized}_*_stderr.log", f"{normalized}_*_stderr.log", f"{normalized}*stderr*.log"]
    for directory in [REPORTS / "start", REPORTS, BASE / "logs"]:
        path = latest_path_by_patterns(directory, patterns)
        if path:
            return str(path)
    return ""


def build_start_run_summary(start_run_data: dict[str, Any]) -> dict[str, Any]:
    readiness = [item for item in normalize_list(start_run_data.get("readiness")) if isinstance(item, dict)]
    launch_results = [item for item in normalize_list(start_run_data.get("launch_results")) if isinstance(item, dict)]
    ready_count = sum(1 for item in readiness if bool(item.get("ready")))
    total_required = len(readiness)
    status = normalize_text(start_run_data.get("overall_status")).upper() or "UNKNOWN"
    return {"status": status, "run_id": normalize_text(start_run_data.get("run_id")), "generated_at_utc": normalize_text(start_run_data.get("generated_at_utc")), "mode": normalize_text(start_run_data.get("mode")), "ready_count": ready_count, "required_count": total_required, "launch_count": len(launch_results), "started_count": sum(1 for item in launch_results if bool(item.get("started"))), "reused_count": sum(1 for item in launch_results if bool(item.get("reused")))}


def build_mirror_summary(mirror_data: dict[str, Any]) -> dict[str, Any]:
    steps = mirror_data.get("steps") if isinstance(mirror_data.get("steps"), dict) else {}
    mirror_push = normalize_text(mirror_data.get("mirror_push_result")) or normalize_text(steps.get("mirror_push"))
    return {"ok": bool(mirror_data.get("ok", False)), "phase": normalize_text(mirror_data.get("phase")), "mirror_push": mirror_push, "timestamp_utc": normalize_text(mirror_data.get("timestamp_utc")), "reason": normalize_text(mirror_data.get("reason") or mirror_data.get("reason_requested")), "error": normalize_text(mirror_data.get("error")), "next_action": normalize_text(mirror_data.get("next_action"))}


def build_system_validation_summary(validation_data: dict[str, Any] | None = None) -> dict[str, Any]:
    payload = validation_data if isinstance(validation_data, dict) else read_json(SYSTEM_VALIDATION_LAST_PATH, default={})
    payload = payload if isinstance(payload, dict) else {}
    failing_components = normalize_string_list(payload.get("failing_components"), max_items=8, max_len=120)
    relevant_paths = normalize_string_list(payload.get("relevant_paths"), max_items=8, max_len=220)
    return {
        "timestamp_utc": normalize_text(payload.get("timestamp_utc")),
        "overall_status": normalize_text(payload.get("overall_status")).upper() or "UNKNOWN",
        "passed_count": int(payload.get("passed_count") or 0),
        "failed_count": int(payload.get("failed_count") or 0),
        "warn_count": int(payload.get("warn_count") or 0),
        "failing_components": failing_components,
        "recommended_next_action": normalize_text(payload.get("recommended_next_action")),
        "relevant_paths": relevant_paths,
        "mirror_ok": bool(payload.get("mirror_ok", False)),
        "baseline_tag": normalize_text(payload.get("baseline_tag")),
        "path": str(SYSTEM_VALIDATION_LAST_PATH),
    }


def load_live_docs_payload() -> dict[str, Any]:
    cache = getattr(load_live_docs_payload, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 5.0:
        return cache["payload"]

    index_payload = read_json(LIVE_DOCS_INDEX_PATH, default={})
    index_payload = index_payload if isinstance(index_payload, dict) else {}
    summary_payload = read_json(LIVE_DOCS_SUMMARY_PATH, default={})
    summary_payload = summary_payload if isinstance(summary_payload, dict) else {}
    docs_components = [item for item in normalize_list(summary_payload.get("components") or index_payload.get("components")) if isinstance(item, dict)]

    component_items: list[dict[str, Any]] = []
    manuals: list[dict[str, Any]] = []
    for component in sorted(
        docs_components,
        key=lambda item: (
            int(item.get("sort_order") or 100),
            normalize_text(item.get("display_name") or item.get("component_id")),
        ),
    ):
        manual_path_text = normalize_text(component.get("manual_path"))
        manual_path = Path(manual_path_text) if manual_path_text else LIVE_DOCS_DIR / f"{normalize_text(component.get('component_id'))}_live_manual.json"
        if not manual_path.is_absolute():
            manual_path = BASE / manual_path
        manual_payload = read_json(manual_path, default={})
        manual_payload = manual_payload if isinstance(manual_payload, dict) else {}

        warnings = [item for item in normalize_list(manual_payload.get("latest_known_warnings") or component.get("latest_known_warnings")) if isinstance(item, dict)]
        actions = [item for item in normalize_list(manual_payload.get("safe_next_actions") or component.get("safe_next_actions")) if isinstance(item, dict)]
        founder_actions = [item for item in normalize_list(manual_payload.get("founder_actions") or component.get("founder_actions")) if isinstance(item, dict)]
        mason_safe_actions = [item for item in normalize_list(manual_payload.get("mason_safe_actions") or component.get("mason_safe_actions")) if isinstance(item, dict)]
        blocked_actions = [item for item in normalize_list(manual_payload.get("blocked_or_guarded_actions") or component.get("blocked_or_guarded_actions")) if isinstance(item, dict)]
        recent_changes = [item for item in normalize_list(manual_payload.get("recent_changes") or component.get("recent_changes")) if isinstance(item, dict)]
        source_artifacts = [item for item in normalize_list(manual_payload.get("source_artifacts") or component.get("source_artifacts")) if isinstance(item, dict)]
        warning_summary = manual_payload.get("warning_summary") if isinstance(manual_payload.get("warning_summary"), dict) else {}
        validation_summary = manual_payload.get("validation_summary") if isinstance(manual_payload.get("validation_summary"), dict) else {}
        summary_item = {
            "component_id": normalize_text(component.get("component_id") or manual_payload.get("component_id")),
            "display_name": normalize_short_text(component.get("display_name") or manual_payload.get("display_name"), max_len=120),
            "role": normalize_short_text(component.get("role") or manual_payload.get("role"), max_len=64),
            "purpose_summary": normalize_short_text(component.get("purpose_summary") or manual_payload.get("purpose_summary"), max_len=240),
            "current_status": normalize_text(component.get("current_status") or manual_payload.get("current_status")).upper() or "WARN",
            "current_status_reason": normalize_short_text(component.get("current_status_reason") or manual_payload.get("current_status_reason"), max_len=240),
            "warning_summary": warning_summary,
            "latest_known_warnings": warnings[:3],
            "safe_next_actions": actions[:3],
            "founder_actions": founder_actions[:3],
            "mason_safe_actions": mason_safe_actions[:3],
            "blocked_or_guarded_actions": blocked_actions[:3],
            "recent_changes": recent_changes[:3],
            "source_artifacts": source_artifacts[:6],
            "validation_summary": validation_summary,
            "manual_path": str(manual_path),
            "owner_surface": normalize_short_text(component.get("owner_surface") or manual_payload.get("owner_surface"), max_len=32),
            "visible_in_athena": bool(component.get("visible_in_athena", manual_payload.get("visible_in_athena", True))),
            "sort_order": int(component.get("sort_order") or manual_payload.get("sort_order") or 100),
            "stale": bool(component.get("stale", manual_payload.get("stale", False))),
        }
        component_items.append(summary_item)
        if manual_payload:
            manuals.append(manual_payload)

    default_component = normalize_text(summary_payload.get("default_component") or index_payload.get("default_component"))
    if not default_component and component_items:
        default_component = normalize_text(component_items[0].get("component_id"))

    payload = {
        "owner_only": True,
        "generated_at_utc": normalize_text(summary_payload.get("generated_at_utc") or index_payload.get("generated_at_utc")),
        "latest_generated_at_utc": normalize_text(
            summary_payload.get("latest_generated_at_utc") or summary_payload.get("generated_at_utc") or index_payload.get("latest_generated_at_utc") or index_payload.get("generated_at_utc")
        ),
        "summary_status": normalize_text(summary_payload.get("summary_status")).upper() or "WARN",
        "docs_count": int(summary_payload.get("docs_count") or len(component_items)),
        "components_with_warnings": normalize_string_list(summary_payload.get("components_with_warnings"), max_items=24, max_len=64),
        "components_healthy": normalize_string_list(summary_payload.get("components_healthy"), max_items=24, max_len=64),
        "components_blocked": normalize_string_list(summary_payload.get("components_blocked"), max_items=24, max_len=64),
        "stale_docs_count": int(summary_payload.get("stale_docs_count") or 0),
        "components": component_items,
        "index_path": str(LIVE_DOCS_INDEX_PATH),
        "summary_path": str(LIVE_DOCS_SUMMARY_PATH),
        "default_component": default_component,
        "manuals": manuals,
        "registry_path": str(COMPONENT_DOCS_REGISTRY_PATH),
    }
    load_live_docs_payload._cache = {"ts": now_monotonic, "payload": payload}
    return payload


def load_brand_exposure_payload() -> dict[str, Any]:
    cache = getattr(load_brand_exposure_payload, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 5.0:
        return cache["payload"]

    summary_payload = read_json(BRAND_EXPOSURE_SUMMARY_PATH, default={})
    summary_payload = summary_payload if isinstance(summary_payload, dict) else {}
    audit_payload = read_json(BRAND_LEAK_AUDIT_PATH, default={})
    audit_payload = audit_payload if isinstance(audit_payload, dict) else {}
    vocabulary_payload = read_json(PUBLIC_VOCABULARY_POLICY_LAST_PATH, default={})
    vocabulary_payload = vocabulary_payload if isinstance(vocabulary_payload, dict) else {}

    payload = {
        "overall_status": normalize_text(summary_payload.get("overall_status")).upper() or "UNKNOWN",
        "public_brand_posture": normalize_short_text(summary_payload.get("public_brand_posture"), max_len=48) or "unknown",
        "internal_brand_posture": normalize_short_text(summary_payload.get("internal_brand_posture"), max_len=48) or "unknown",
        "public_leak_count": int(summary_payload.get("public_leak_count") or 0),
        "surfaces_scanned": int(summary_payload.get("total_surfaces_scanned") or 0),
        "public_safe_surface_count": int(summary_payload.get("public_safe_surface_count") or 0),
        "internal_surface_count": int(summary_payload.get("internal_surface_count") or 0),
        "recommended_next_action": normalize_short_text(summary_payload.get("recommended_next_action"), max_len=240),
        "owner_only_preserved": bool(summary_payload.get("owner_only_wording_preserved", False)),
        "customer_safe": bool(summary_payload.get("customer_only_wording_isolated", False)),
        "severity_summary": audit_payload.get("severity_summary") if isinstance(audit_payload.get("severity_summary"), dict) else {},
        "exposures_found_count": int(audit_payload.get("exposures_found_count") or 0),
        "public_surfaces_clean": bool(audit_payload.get("public_surfaces_clean", False)),
        "owner_internal_surfaces_intact": bool(audit_payload.get("owner_internal_surfaces_intact", False)),
        "timestamp_utc": normalize_text(summary_payload.get("timestamp_utc") or audit_payload.get("timestamp_utc") or vocabulary_payload.get("timestamp_utc")),
        "summary_path": str(BRAND_EXPOSURE_SUMMARY_PATH),
        "audit_path": str(BRAND_LEAK_AUDIT_PATH),
        "policy_path": str(BRAND_EXPOSURE_POLICY_PATH),
        "public_vocabulary_policy_path": str(PUBLIC_VOCABULARY_POLICY_LAST_PATH),
    }
    load_brand_exposure_payload._cache = {"ts": now_monotonic, "payload": payload}
    return payload


def load_keepalive_ops_payload() -> dict[str, Any]:
    cache = getattr(load_keepalive_ops_payload, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 5.0:
        return cache["payload"]

    keepalive_payload = read_json(KEEPALIVE_LAST_PATH, default={})
    keepalive_payload = keepalive_payload if isinstance(keepalive_payload, dict) else {}
    self_heal_payload = read_json(SELF_HEAL_LAST_PATH, default={})
    self_heal_payload = self_heal_payload if isinstance(self_heal_payload, dict) else {}
    daily_report_payload = read_json(DAILY_REPORT_LAST_PATH, default={})
    daily_report_payload = daily_report_payload if isinstance(daily_report_payload, dict) else {}
    escalation_payload = read_json(ESCALATION_QUEUE_LAST_PATH, default={})
    escalation_payload = escalation_payload if isinstance(escalation_payload, dict) else {}

    escalations = [item for item in normalize_list(escalation_payload.get("escalations")) if isinstance(item, dict)]
    issue_rows = [item for item in normalize_list(self_heal_payload.get("issues")) if isinstance(item, dict)]
    services_evaluated = [item for item in normalize_list(keepalive_payload.get("services_evaluated")) if isinstance(item, dict)]
    blocked_repair_items = [
        {
            "issue_id": normalize_text(item.get("issue_id")),
            "component": normalize_short_text(item.get("component"), max_len=48),
            "reason": normalize_short_text(item.get("recommended_next_step") or item.get("summary"), max_len=220),
            "policy_decision": normalize_short_text(item.get("policy_decision"), max_len=48),
        }
        for item in issue_rows
        if normalize_text(item.get("action_attempted_or_blocked")) not in {"attempted", "attempted_success", "deferred_due_single_action_limit"}
    ][:5]
    latest_escalations = [
        {
            "issue_id": normalize_text(item.get("issue_id")),
            "component": normalize_short_text(item.get("component"), max_len=48),
            "severity": normalize_short_text(item.get("severity"), max_len=24).upper(),
            "recommended_next_step": normalize_short_text(item.get("recommended_next_step"), max_len=220),
            "owner_action_required": bool(item.get("owner_action_required", False)),
        }
        for item in escalations[:5]
    ]
    latest_attempts = [
        {
            "issue_id": normalize_text(item.get("issue_id")),
            "component": normalize_short_text(item.get("component"), max_len=48),
            "result": normalize_short_text(item.get("result"), max_len=48).upper(),
            "action_id": normalize_short_text(item.get("action_id"), max_len=64),
        }
        for item in issue_rows
        if normalize_text(item.get("action_attempted_or_blocked")) in {"attempted", "attempted_success"}
    ][:5]

    payload = {
        "owner_only": True,
        "overall_status": normalize_text(keepalive_payload.get("overall_status")).upper() or "UNKNOWN",
        "recoverable_issue_count": int(keepalive_payload.get("recoverable_issue_count") or 0),
        "escalated_issue_count": int(keepalive_payload.get("escalated_issue_count") or escalation_payload.get("escalation_count") or 0),
        "repair_success_count": int(keepalive_payload.get("repair_success_count") or 0),
        "repair_blocked_count": int(keepalive_payload.get("repair_blocked_count") or 0),
        "repair_attempt_count": int(keepalive_payload.get("repair_attempt_count") or 0),
        "healthy_service_count": int(keepalive_payload.get("healthy_service_count") or 0),
        "services_evaluated_count": len(services_evaluated),
        "daily_report_status": normalize_text(daily_report_payload.get("overall_status") or keepalive_payload.get("daily_report_status")).upper() or "UNKNOWN",
        "throttle_guidance": normalize_short_text(keepalive_payload.get("throttle_guidance"), max_len=40),
        "recommended_next_action": normalize_short_text(
            keepalive_payload.get("recommended_next_action")
            or daily_report_payload.get("recommended_next_action")
            or escalation_payload.get("recommended_next_action"),
            max_len=240,
        ),
        "latest_escalations": latest_escalations,
        "blocked_repair_items": blocked_repair_items,
        "latest_attempts": latest_attempts,
        "timestamp_utc": normalize_text(
            keepalive_payload.get("timestamp_utc")
            or daily_report_payload.get("timestamp_utc")
            or escalation_payload.get("timestamp_utc")
        ),
        "keepalive_path": str(KEEPALIVE_LAST_PATH),
        "self_heal_path": str(SELF_HEAL_LAST_PATH),
        "daily_report_path": str(DAILY_REPORT_LAST_PATH),
        "escalation_queue_path": str(ESCALATION_QUEUE_LAST_PATH),
        "policy_path": str(KEEPALIVE_POLICY_PATH),
    }
    load_keepalive_ops_payload._cache = {"ts": now_monotonic, "payload": payload}
    return payload


def load_system_truth_payload() -> dict[str, Any]:
    cache = getattr(load_system_truth_payload, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 5.0:
        return cache["payload"]

    truth_payload = read_json(SYSTEM_TRUTH_SPINE_LAST_PATH, default={})
    truth_payload = truth_payload if isinstance(truth_payload, dict) else {}
    summary_payload = read_json(SYSTEM_TRUTH_SUMMARY_LAST_PATH, default={})
    summary_payload = summary_payload if isinstance(summary_payload, dict) else {}
    registry_payload = read_json(SYSTEM_TRUTH_REGISTRY_PATH, default={})
    registry_payload = registry_payload if isinstance(registry_payload, dict) else {}
    domains_payload = truth_payload.get("domains") if isinstance(truth_payload.get("domains"), dict) else {}
    top_warning_domains: list[str] = []
    if isinstance(summary_payload.get("top_warnings"), list):
        top_warning_domains = [
            normalize_text(item.get("domain"))
            for item in summary_payload.get("top_warnings")
            if isinstance(item, dict) and normalize_text(item.get("domain"))
        ][:8]
    if not top_warning_domains and isinstance(truth_payload.get("summary"), dict):
        top_warning_domains = normalize_string_list(truth_payload.get("summary", {}).get("top_warning_domains"), max_items=8, max_len=64)
    top_healthy_domains: list[str] = []
    if isinstance(summary_payload.get("top_healthy_areas"), list):
        top_healthy_domains = [
            normalize_text(item.get("domain"))
            for item in summary_payload.get("top_healthy_areas")
            if isinstance(item, dict) and normalize_text(item.get("domain"))
        ][:8]
    if not top_healthy_domains and isinstance(truth_payload.get("summary"), dict):
        top_healthy_domains = normalize_string_list(truth_payload.get("summary", {}).get("top_healthy_domains"), max_items=8, max_len=64)

    payload = {
        "owner_only": True,
        "overall_status": normalize_text(truth_payload.get("overall_status") or summary_payload.get("overall_status")).upper() or "UNKNOWN",
        "recommended_next_action": normalize_short_text(
            truth_payload.get("recommended_next_action") or summary_payload.get("recommended_next_action"),
            max_len=240,
        ),
        "available_domain_count": int(truth_payload.get("summary", {}).get("available_domain_count") or 0) if isinstance(truth_payload.get("summary"), dict) else 0,
        "warning_domain_count": int(truth_payload.get("summary", {}).get("warning_domain_count") or 0) if isinstance(truth_payload.get("summary"), dict) else 0,
        "failing_domain_count": int(truth_payload.get("summary", {}).get("failing_domain_count") or 0) if isinstance(truth_payload.get("summary"), dict) else 0,
        "healthy_domain_count": int(truth_payload.get("summary", {}).get("healthy_domain_count") or 0) if isinstance(truth_payload.get("summary"), dict) else 0,
        "domain_count": len(domains_payload),
        "truth_timestamp_utc": normalize_text(truth_payload.get("timestamp_utc") or summary_payload.get("truth_timestamp_utc")),
        "top_warning_domains": top_warning_domains,
        "top_healthy_domains": top_healthy_domains,
        "current_blocker_domains": normalize_string_list(summary_payload.get("current_blocker_domains"), max_items=8, max_len=64),
        "baseline_tag": normalize_text(truth_payload.get("baseline_tag") or summary_payload.get("baseline_tag")),
        "path": str(SYSTEM_TRUTH_SPINE_LAST_PATH),
        "summary_path": str(SYSTEM_TRUTH_SUMMARY_LAST_PATH),
        "registry_path": str(SYSTEM_TRUTH_REGISTRY_PATH),
        "last_build_timestamp_utc": normalize_text(registry_payload.get("last_build_timestamp_utc")),
    }
    load_system_truth_payload._cache = {"ts": now_monotonic, "payload": payload}
    return payload


def load_system_metrics_payload() -> dict[str, Any]:
    cache = getattr(load_system_metrics_payload, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 5.0:
        return cache["payload"]

    metrics_payload = read_json(SYSTEM_METRICS_SPINE_LAST_PATH, default={})
    metrics_payload = metrics_payload if isinstance(metrics_payload, dict) else {}
    payload = {
        "timestamp_utc": normalize_text(metrics_payload.get("timestamp_utc")),
        "overall_status": normalize_text(metrics_payload.get("overall_status")).upper() or "UNKNOWN",
        "service_count": int(metrics_payload.get("service_count") or 0),
        "healthy_service_count": int(metrics_payload.get("healthy_service_count") or 0),
        "tenant_count": int(metrics_payload.get("tenant_count") or 0),
        "queue_total": int(metrics_payload.get("queue_total") or 0),
        "tool_total": int(metrics_payload.get("tool_total") or 0),
        "enabled_tool_total": int(metrics_payload.get("enabled_tool_total") or 0),
        "warning_domain_count": int(metrics_payload.get("warning_domain_count") or 0),
        "failing_domain_count": int(metrics_payload.get("failing_domain_count") or 0),
        "blocked_governed_count": int(metrics_payload.get("blocked_governed_count") or 0),
        "path": str(SYSTEM_METRICS_SPINE_LAST_PATH),
    }
    load_system_metrics_payload._cache = {"ts": now_monotonic, "payload": payload}
    return payload


def load_regression_guard_payload() -> dict[str, Any]:
    cache = getattr(load_regression_guard_payload, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 5.0:
        return cache["payload"]

    regression_payload = read_json(REGRESSION_GUARD_LAST_PATH, default={})
    regression_payload = regression_payload if isinstance(regression_payload, dict) else {}
    promotion_payload = read_json(PROMOTION_GATE_LAST_PATH, default={})
    promotion_payload = promotion_payload if isinstance(promotion_payload, dict) else {}
    rollback_payload = read_json(ROLLBACK_PLAN_LAST_PATH, default={})
    rollback_payload = rollback_payload if isinstance(rollback_payload, dict) else {}
    baseline_registry = read_json(REGRESSION_BASELINES_PATH, default={})
    baseline_registry = baseline_registry if isinstance(baseline_registry, dict) else {}

    payload = {
        "owner_only": True,
        "overall_status": normalize_text(regression_payload.get("overall_status")).upper() or "UNKNOWN",
        "baseline_available": bool(regression_payload.get("baseline_available", False)),
        "baseline_trusted": bool(regression_payload.get("baseline_trusted", False)),
        "baseline_id": normalize_text(regression_payload.get("baseline_id")),
        "comparison_mode": normalize_short_text(regression_payload.get("comparison_mode"), max_len=40),
        "comparison_result": normalize_short_text(regression_payload.get("comparison_result"), max_len=80),
        "regression_count": int(regression_payload.get("regression_count") or 0),
        "blocking_regression_count": int(regression_payload.get("blocking_regression_count") or 0),
        "warning_regression_count": int(regression_payload.get("warning_regression_count") or 0),
        "rollback_recommended": bool(regression_payload.get("rollback_recommended", False)),
        "promotion_allowed": bool(regression_payload.get("promotion_allowed", False)),
        "promotion_blocked": bool(promotion_payload.get("promotion_blocked", False) or not regression_payload.get("promotion_allowed", False)),
        "recommended_next_action": normalize_short_text(
            regression_payload.get("recommended_next_action") or promotion_payload.get("recommended_next_action"),
            max_len=240,
        ),
        "blocking_reasons": normalize_string_list(promotion_payload.get("blocking_reasons"), max_items=8, max_len=80),
        "gating_domains": normalize_string_list(promotion_payload.get("gating_domains"), max_items=8, max_len=64),
        "timestamp_utc": normalize_text(regression_payload.get("timestamp_utc") or promotion_payload.get("timestamp_utc") or rollback_payload.get("timestamp_utc")),
        "policy_path": str(REGRESSION_GUARD_POLICY_PATH),
        "regression_path": str(REGRESSION_GUARD_LAST_PATH),
        "promotion_gate_path": str(PROMOTION_GATE_LAST_PATH),
        "rollback_plan_path": str(ROLLBACK_PLAN_LAST_PATH),
        "baseline_registry_path": str(REGRESSION_BASELINES_PATH),
        "current_active_baseline_id": normalize_text(baseline_registry.get("current_active_baseline_id")),
    }
    load_regression_guard_payload._cache = {"ts": now_monotonic, "payload": payload}
    return payload


def load_playbook_support_payload() -> dict[str, Any]:
    cache = getattr(load_playbook_support_payload, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 5.0:
        return cache["payload"]

    library_payload = read_json(PLAYBOOK_LIBRARY_LAST_PATH, default={})
    library_payload = library_payload if isinstance(library_payload, dict) else {}
    support_payload = read_json(SUPPORT_BRAIN_LAST_PATH, default={})
    support_payload = support_payload if isinstance(support_payload, dict) else {}
    incident_payload = read_json(INCIDENT_EXPLANATIONS_LAST_PATH, default={})
    incident_payload = incident_payload if isinstance(incident_payload, dict) else {}
    registry_payload = read_json(PLAYBOOK_REGISTRY_PATH, default={})
    registry_payload = registry_payload if isinstance(registry_payload, dict) else {}

    top_issue_explanations: list[dict[str, Any]] = []
    if isinstance(incident_payload.get("issues"), list):
        for item in incident_payload.get("issues", [])[:4]:
            if not isinstance(item, dict):
                continue
            top_issue_explanations.append(
                {
                    "issue_id": normalize_text(item.get("issue_id")),
                    "issue_type": normalize_short_text(item.get("issue_type"), max_len=80),
                    "severity": normalize_short_text(item.get("severity"), max_len=24),
                    "plain_english_explanation": normalize_short_text(item.get("plain_english_explanation"), max_len=240),
                    "what_should_happen_next": normalize_short_text(item.get("what_should_happen_next"), max_len=220),
                    "linked_playbook_id": normalize_short_text(item.get("linked_playbook_id"), max_len=80),
                    "source_truth_path": normalize_text(item.get("source_truth_path")),
                }
            )

    payload = {
        "owner_only": True,
        "overall_status": normalize_text(
            support_payload.get("overall_status")
            or library_payload.get("overall_status")
            or incident_payload.get("overall_status")
        ).upper()
        or "UNKNOWN",
        "playbook_count": int(library_payload.get("playbook_count") or registry_payload.get("current_playbook_count") or 0),
        "active_playbook_count": int(library_payload.get("active_playbook_count") or 0),
        "recurring_issue_count": int(support_payload.get("recurring_issue_count") or incident_payload.get("issue_count") or 0),
        "customer_safe_ready_count": int(support_payload.get("customer_safe_ready_count") or 0),
        "internal_support_ready_count": int(support_payload.get("internal_support_ready_count") or 0),
        "recommended_next_action": normalize_short_text(
            support_payload.get("recommended_next_action")
            or library_payload.get("recommended_next_action")
            or incident_payload.get("recommended_next_action"),
            max_len=240,
        ),
        "supported_issue_types": normalize_string_list(support_payload.get("supported_issue_types"), max_items=16, max_len=64),
        "playbook_categories": normalize_string_list(library_payload.get("playbook_categories"), max_items=16, max_len=64),
        "generated_at_utc": normalize_text(
            library_payload.get("timestamp_utc")
            or support_payload.get("timestamp_utc")
            or incident_payload.get("timestamp_utc")
            or registry_payload.get("generated_at_utc")
        ),
        "top_issue_explanations": top_issue_explanations,
        "library_path": str(PLAYBOOK_LIBRARY_LAST_PATH),
        "support_path": str(SUPPORT_BRAIN_LAST_PATH),
        "incident_path": str(INCIDENT_EXPLANATIONS_LAST_PATH),
        "registry_path": str(PLAYBOOK_REGISTRY_PATH),
        "policy_path": str(PLAYBOOK_SUPPORT_POLICY_PATH),
    }
    load_playbook_support_payload._cache = {"ts": now_monotonic, "payload": payload}
    return payload


def load_wedge_pack_framework_payload() -> dict[str, Any]:
    cache = getattr(load_wedge_pack_framework_payload, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 5.0:
        return cache["payload"]

    framework_payload = read_json(WEDGE_PACK_FRAMEWORK_LAST_PATH, default={})
    framework_payload = framework_payload if isinstance(framework_payload, dict) else {}
    overlay_payload = read_json(SEGMENT_OVERLAY_LAST_PATH, default={})
    overlay_payload = overlay_payload if isinstance(overlay_payload, dict) else {}
    workflow_payload = read_json(WORKFLOW_PACK_LAST_PATH, default={})
    workflow_payload = workflow_payload if isinstance(workflow_payload, dict) else {}
    registry_payload = read_json(WEDGE_PACK_REGISTRY_PATH, default={})
    registry_payload = registry_payload if isinstance(registry_payload, dict) else {}

    active_tenant_fit = framework_payload.get("active_tenant_fit")
    active_tenant_fit = active_tenant_fit if isinstance(active_tenant_fit, dict) else {}
    pack_statuses = registry_payload.get("pack_statuses")
    pack_statuses = pack_statuses if isinstance(pack_statuses, dict) else {}

    payload = {
        "owner_only": True,
        "overall_status": normalize_text(framework_payload.get("overall_status")).upper() or "UNKNOWN",
        "business_category_count": int(framework_payload.get("business_category_count") or len(framework_payload.get("categories") or []) or 0),
        "business_subcategory_count": int(framework_payload.get("business_subcategory_count") or len(framework_payload.get("subcategories") or []) or 0),
        "wedge_pack_count": int(framework_payload.get("wedge_pack_count") or len(framework_payload.get("wedge_packs") or []) or 0),
        "customer_ready_pack_count": int(framework_payload.get("customer_ready_pack_count") or pack_statuses.get("customer_ready") or 0),
        "experimental_pack_count": int(framework_payload.get("experimental_pack_count") or pack_statuses.get("experimental") or 0),
        "fallback_pack_available": bool(framework_payload.get("fallback_pack_available", False)),
        "recommended_next_action": normalize_short_text(framework_payload.get("recommended_next_action"), max_len=240),
        "generated_at_utc": normalize_text(framework_payload.get("timestamp_utc") or registry_payload.get("generated_at_utc")),
        "active_tenant_id": normalize_text(framework_payload.get("active_tenant_id")),
        "active_business_category": normalize_short_text(active_tenant_fit.get("business_category"), max_len=64),
        "active_business_subcategory": normalize_short_text(active_tenant_fit.get("business_subcategory"), max_len=64),
        "active_workflow_pack_ids": normalize_string_list(active_tenant_fit.get("workflow_pack_ids"), max_items=8, max_len=80),
        "active_tool_bundle_ids": normalize_string_list(active_tenant_fit.get("tool_bundle_ids"), max_items=8, max_len=80),
        "pilot_ready_pack_count": int(pack_statuses.get("pilot_ready") or 0),
        "planned_pack_count": int(pack_statuses.get("planned") or 0),
        "overlay_count": int(
            len(overlay_payload.get("onboarding_overlays") or [])
            + len(overlay_payload.get("dashboard_overlays") or [])
            + len(overlay_payload.get("recommendation_overlays") or [])
        ),
        "workflow_pack_artifact_count": int(len(workflow_payload.get("workflow_packs") or [])),
        "framework_path": str(WEDGE_PACK_FRAMEWORK_LAST_PATH),
        "segment_overlay_path": str(SEGMENT_OVERLAY_LAST_PATH),
        "workflow_pack_path": str(WORKFLOW_PACK_LAST_PATH),
        "registry_path": str(WEDGE_PACK_REGISTRY_PATH),
        "policy_path": str(WEDGE_PACK_POLICY_PATH),
    }
    load_wedge_pack_framework_payload._cache = {"ts": now_monotonic, "payload": payload}
    return payload


def load_business_outcomes_payload() -> dict[str, Any]:
    cache = getattr(load_business_outcomes_payload, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 5.0:
        return cache["payload"]

    outcomes_payload = read_json(BUSINESS_OUTCOMES_LAST_PATH, default={})
    outcomes_payload = outcomes_payload if isinstance(outcomes_payload, dict) else {}
    tool_payload = read_json(TOOL_USEFULNESS_LAST_PATH, default={})
    tool_payload = tool_payload if isinstance(tool_payload, dict) else {}
    recommendation_payload = read_json(RECOMMENDATION_EFFECTIVENESS_LAST_PATH, default={})
    recommendation_payload = recommendation_payload if isinstance(recommendation_payload, dict) else {}
    engagement_payload = read_json(TENANT_ENGAGEMENT_LAST_PATH, default={})
    engagement_payload = engagement_payload if isinstance(engagement_payload, dict) else {}
    registry_payload = read_json(BUSINESS_OUTCOME_REGISTRY_PATH, default={})
    registry_payload = registry_payload if isinstance(registry_payload, dict) else {}

    revenue_help = outcomes_payload.get("revenue_help_indicators")
    revenue_help = revenue_help if isinstance(revenue_help, dict) else {}
    churn_risk = outcomes_payload.get("churn_risk_indicators")
    churn_risk = churn_risk if isinstance(churn_risk, dict) else {}
    onboarding = outcomes_payload.get("onboarding_completion")
    onboarding = onboarding if isinstance(onboarding, dict) else {}

    payload = {
        "owner_only": True,
        "overall_status": normalize_text(outcomes_payload.get("overall_status")).upper() or "UNKNOWN",
        "tenant_count": int(outcomes_payload.get("tenant_count") or registry_payload.get("tenant_count") or 0),
        "tenants_with_measurable_signals": int(outcomes_payload.get("tenants_with_measurable_signals") or 0),
        "tool_usefulness_summary": normalize_short_text(
            tool_payload.get("recommended_next_action")
            or outcomes_payload.get("tool_usefulness", {}).get("summary"),
            max_len=220,
        ),
        "recommendation_effectiveness_summary": normalize_short_text(
            recommendation_payload.get("effectiveness_summary")
            or outcomes_payload.get("recommendation_effectiveness", {}).get("summary"),
            max_len=220,
        ),
        "onboarding_completion_summary": normalize_short_text(onboarding.get("summary"), max_len=220),
        "revenue_help_summary": normalize_short_text(revenue_help.get("summary"), max_len=220),
        "churn_risk_summary": normalize_short_text(churn_risk.get("summary"), max_len=220),
        "recommended_next_action": normalize_short_text(outcomes_payload.get("recommended_next_action"), max_len=240),
        "generated_at_utc": normalize_text(outcomes_payload.get("timestamp_utc") or registry_payload.get("generated_at_utc")),
        "low_confidence_domain_count": int(outcomes_payload.get("low_confidence_domain_count") or 0),
        "active_signal_count": int(engagement_payload.get("active_signal_count") or 0),
        "churn_risk_count": int(engagement_payload.get("churn_risk_count") or 0),
        "tools_with_usage_signal": int(tool_payload.get("tools_with_usage_signal") or 0),
        "accepted_recommendation_count": int(recommendation_payload.get("accepted_count") or 0),
        "dismissed_recommendation_count": int(recommendation_payload.get("rejected_count") or 0),
        "outcomes_path": str(BUSINESS_OUTCOMES_LAST_PATH),
        "tool_usefulness_path": str(TOOL_USEFULNESS_LAST_PATH),
        "recommendation_effectiveness_path": str(RECOMMENDATION_EFFECTIVENESS_LAST_PATH),
        "tenant_engagement_path": str(TENANT_ENGAGEMENT_LAST_PATH),
        "registry_path": str(BUSINESS_OUTCOME_REGISTRY_PATH),
        "policy_path": str(BUSINESS_OUTCOME_POLICY_PATH),
    }
    load_business_outcomes_payload._cache = {"ts": now_monotonic, "payload": payload}
    return payload


def load_release_management_payload() -> dict[str, Any]:
    cache = getattr(load_release_management_payload, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 5.0:
        return cache["payload"]

    management_payload = read_json(RELEASE_MANAGEMENT_LAST_PATH, default={})
    management_payload = management_payload if isinstance(management_payload, dict) else {}
    candidate_payload = read_json(RELEASE_CANDIDATE_LAST_PATH, default={})
    candidate_payload = candidate_payload if isinstance(candidate_payload, dict) else {}
    rollout_payload = read_json(RELEASE_ROLLOUT_LAST_PATH, default={})
    rollout_payload = rollout_payload if isinstance(rollout_payload, dict) else {}
    notes_payload = read_json(RELEASE_NOTES_LAST_PATH, default={})
    notes_payload = notes_payload if isinstance(notes_payload, dict) else {}
    registry_payload = read_json(RELEASE_REGISTRY_PATH, default={})
    registry_payload = registry_payload if isinstance(registry_payload, dict) else {}

    blocked_items = candidate_payload.get("blocking_reasons")
    blocked_items = blocked_items if isinstance(blocked_items, list) else []
    warning_items = candidate_payload.get("warning_reasons")
    warning_items = warning_items if isinstance(warning_items, list) else []

    payload = {
        "owner_only": True,
        "overall_status": normalize_text(management_payload.get("overall_status")).upper() or "UNKNOWN",
        "release_candidate_id": normalize_text(
            management_payload.get("release_candidate_id")
            or candidate_payload.get("release_candidate_id")
            or registry_payload.get("current_release_candidate_id")
        ),
        "release_stage": normalize_text(
            management_payload.get("release_stage")
            or candidate_payload.get("release_stage")
            or registry_payload.get("current_release_stage")
        ),
        "promotion_allowed": bool(
            management_payload.get("promotion_allowed")
            if "promotion_allowed" in management_payload
            else candidate_payload.get("promotion_allowed")
        ),
        "rollout_mode": normalize_text(
            management_payload.get("rollout_mode")
            or rollout_payload.get("rollout_mode")
        ),
        "rollback_ready": bool(
            management_payload.get("rollback_ready")
            if "rollback_ready" in management_payload
            else False
        ),
        "blocking_reason_count": int(
            management_payload.get("blocking_reason_count")
            or len(blocked_items)
            or 0
        ),
        "warning_reason_count": int(
            management_payload.get("warning_reason_count")
            or len(warning_items)
            or 0
        ),
        "recommended_next_action": normalize_short_text(
            management_payload.get("recommended_next_action")
            or candidate_payload.get("recommended_next_action"),
            max_len=240,
        ),
        "canary_allowed": bool(candidate_payload.get("canary_allowed")) if "canary_allowed" in candidate_payload else False,
        "pilot_ready": bool(candidate_payload.get("pilot_ready")) if "pilot_ready" in candidate_payload else False,
        "customer_ready": bool(candidate_payload.get("customer_ready")) if "customer_ready" in candidate_payload else False,
        "release_readiness_classification": normalize_short_text(
            management_payload.get("release_readiness_classification"),
            max_len=64,
        ),
        "known_warning_count": int(len(notes_payload.get("known_warnings") or [])),
        "blocked_item_count": int(len(notes_payload.get("blocked_items") or [])),
        "recommended_release_scope": normalize_short_text(
            notes_payload.get("recommended_release_scope"),
            max_len=80,
        ),
        "generated_at_utc": normalize_text(
            management_payload.get("timestamp_utc")
            or candidate_payload.get("timestamp_utc")
            or registry_payload.get("generated_at_utc")
        ),
        "release_management_path": str(RELEASE_MANAGEMENT_LAST_PATH),
        "release_candidate_path": str(RELEASE_CANDIDATE_LAST_PATH),
        "release_notes_path": str(RELEASE_NOTES_LAST_PATH),
        "release_rollout_path": str(RELEASE_ROLLOUT_LAST_PATH),
        "registry_path": str(RELEASE_REGISTRY_PATH),
        "policy_path": str(RELEASE_MANAGEMENT_POLICY_PATH),
    }
    load_release_management_payload._cache = {"ts": now_monotonic, "payload": payload}
    return payload


def load_revenue_optimization_payload() -> dict[str, Any]:
    cache = getattr(load_revenue_optimization_payload, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 5.0:
        return cache["payload"]

    optimization_payload = read_json(REVENUE_OPTIMIZATION_LAST_PATH, default={})
    optimization_payload = optimization_payload if isinstance(optimization_payload, dict) else {}
    plan_fit_payload = read_json(PLAN_FIT_ANALYSIS_LAST_PATH, default={})
    plan_fit_payload = plan_fit_payload if isinstance(plan_fit_payload, dict) else {}
    upgrade_payload = read_json(UPGRADE_SUGGESTIONS_LAST_PATH, default={})
    upgrade_payload = upgrade_payload if isinstance(upgrade_payload, dict) else {}
    churn_payload = read_json(CHURN_RESCUE_LAST_PATH, default={})
    churn_payload = churn_payload if isinstance(churn_payload, dict) else {}
    registry_payload = read_json(REVENUE_OPTIMIZATION_REGISTRY_PATH, default={})
    registry_payload = registry_payload if isinstance(registry_payload, dict) else {}

    billing_linkage = optimization_payload.get("billing_posture_linkage")
    billing_linkage = billing_linkage if isinstance(billing_linkage, dict) else {}

    payload = {
        "owner_only": True,
        "overall_status": normalize_text(optimization_payload.get("overall_status")).upper() or "UNKNOWN",
        "tenant_count": int(optimization_payload.get("tenant_count") or registry_payload.get("tenant_count") or 0),
        "upgrade_opportunity_count": int(optimization_payload.get("upgrade_opportunity_count") or upgrade_payload.get("upgrade_suggestion_count") or 0),
        "add_on_fit_count": int(optimization_payload.get("add_on_fit_count") or upgrade_payload.get("add_on_suggestion_count") or 0),
        "churn_rescue_count": int(optimization_payload.get("churn_rescue_count") or churn_payload.get("churn_rescue_count") or 0),
        "blocked_money_action_count": int(optimization_payload.get("blocked_money_action_count") or 0),
        "billing_gated": bool(
            billing_linkage.get("billing_gated")
            if "billing_gated" in billing_linkage
            else True
        ),
        "tool_usefulness_summary": normalize_short_text(
            optimization_payload.get("plan_fit", {}).get("summary"),
            max_len=220,
        ),
        "recommendation_effectiveness_summary": normalize_short_text(
            optimization_payload.get("upgrade_suggestions", {}).get("summary"),
            max_len=220,
        ),
        "onboarding_completion_summary": normalize_short_text(
            plan_fit_payload.get("recommended_next_action"),
            max_len=220,
        ),
        "revenue_help_summary": normalize_short_text(
            billing_linkage.get("summary"),
            max_len=220,
        ),
        "churn_risk_summary": normalize_short_text(
            churn_payload.get("recommended_next_action"),
            max_len=220,
        ),
        "recommended_next_action": normalize_short_text(
            optimization_payload.get("recommended_next_action")
            or upgrade_payload.get("recommended_next_action"),
            max_len=240,
        ),
        "generated_at_utc": normalize_text(
            optimization_payload.get("timestamp_utc")
            or registry_payload.get("generated_at_utc")
        ),
        "low_confidence_count": int(optimization_payload.get("low_confidence_count") or 0),
        "customer_safe_suggestion_count": int(upgrade_payload.get("customer_safe_suggestion_count") or 0),
        "owner_review_required_count": int(upgrade_payload.get("owner_review_required_count") or 0),
        "underfit_count": int(plan_fit_payload.get("underfit_count") or 0),
        "well_fit_count": int(plan_fit_payload.get("well_fit_count") or 0),
        "revenue_optimization_path": str(REVENUE_OPTIMIZATION_LAST_PATH),
        "plan_fit_analysis_path": str(PLAN_FIT_ANALYSIS_LAST_PATH),
        "upgrade_suggestions_path": str(UPGRADE_SUGGESTIONS_LAST_PATH),
        "churn_rescue_path": str(CHURN_RESCUE_LAST_PATH),
        "registry_path": str(REVENUE_OPTIMIZATION_REGISTRY_PATH),
        "policy_path": str(REVENUE_OPTIMIZATION_POLICY_PATH),
    }
    load_revenue_optimization_payload._cache = {"ts": now_monotonic, "payload": payload}
    return payload


def load_model_cost_governance_payload() -> dict[str, Any]:
    cache = getattr(load_model_cost_governance_payload, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 5.0:
        return cache["payload"]

    governance_payload = read_json(MODEL_COST_GOVERNANCE_LAST_PATH, default={})
    governance_payload = governance_payload if isinstance(governance_payload, dict) else {}
    task_payload = read_json(TASK_CLASSIFICATION_LAST_PATH, default={})
    task_payload = task_payload if isinstance(task_payload, dict) else {}
    usefulness_payload = read_json(TEACHER_USEFULNESS_LAST_PATH, default={})
    usefulness_payload = usefulness_payload if isinstance(usefulness_payload, dict) else {}
    cost_payload = read_json(COST_EFFECTIVENESS_LAST_PATH, default={})
    cost_payload = cost_payload if isinstance(cost_payload, dict) else {}
    registry_payload = read_json(MODEL_COST_REGISTRY_PATH, default={})
    registry_payload = registry_payload if isinstance(registry_payload, dict) else {}

    mirror_payload = governance_payload.get("mirror_refresh")
    mirror_payload = mirror_payload if isinstance(mirror_payload, dict) else {}

    payload = {
        "owner_only": True,
        "overall_status": normalize_text(governance_payload.get("overall_status")).upper() or "UNKNOWN",
        "task_class_count": int(governance_payload.get("task_class_count") or task_payload.get("task_class_total") or 0),
        "teacher_allowed_count": int(governance_payload.get("teacher_allowed_count") or registry_payload.get("teacher_allowed_count") or 0),
        "teacher_blocked_count": int(governance_payload.get("teacher_blocked_count") or registry_payload.get("teacher_blocked_count") or 0),
        "quality_floor_status": normalize_text(governance_payload.get("quality_floor_status")) or normalize_text(registry_payload.get("quality_floor_status")),
        "cost_governance_posture": normalize_text(governance_payload.get("cost_governance_posture")) or "unknown",
        "mirror_refresh_status": normalize_text(governance_payload.get("mirror_refresh_status") or registry_payload.get("mirror_refresh_status")) or "unknown",
        "recommended_next_action": normalize_short_text(
            governance_payload.get("recommended_next_action")
            or task_payload.get("recommended_next_action")
            or usefulness_payload.get("recommended_next_action")
            or cost_payload.get("recommended_next_action"),
            max_len=240,
        ),
        "budget_class_count": int(governance_payload.get("budget_class_count") or 0),
        "local_first_mandatory_count": int(governance_payload.get("local_first_mandatory_count") or 0),
        "teacher_reviewed_item_count": int(usefulness_payload.get("teacher_reviewed_item_count") or 0),
        "useful_count": int(usefulness_payload.get("useful_count") or 0),
        "mixed_count": int(usefulness_payload.get("mixed_count") or 0),
        "reject_count": int(usefulness_payload.get("reject_count") or 0),
        "successful_low_cost_count": int(cost_payload.get("successful_low_cost_count") or 0),
        "successful_high_cost_count": int(cost_payload.get("successful_high_cost_count") or 0),
        "high_cost_low_value_count": int(cost_payload.get("high_cost_low_value_count") or 0),
        "mirror_ok": bool(mirror_payload.get("ok")) if "ok" in mirror_payload else False,
        "mirror_phase": normalize_text(mirror_payload.get("phase")) or "",
        "mirror_push_result": normalize_text(mirror_payload.get("mirror_push_result")) or "",
        "generated_at_utc": normalize_text(
            governance_payload.get("timestamp_utc")
            or registry_payload.get("generated_at_utc")
        ),
        "model_cost_governance_path": str(MODEL_COST_GOVERNANCE_LAST_PATH),
        "task_classification_path": str(TASK_CLASSIFICATION_LAST_PATH),
        "teacher_usefulness_path": str(TEACHER_USEFULNESS_LAST_PATH),
        "cost_effectiveness_path": str(COST_EFFECTIVENESS_LAST_PATH),
        "registry_path": str(MODEL_COST_REGISTRY_PATH),
        "policy_path": str(MODEL_COST_GOVERNANCE_POLICY_PATH),
    }
    load_model_cost_governance_payload._cache = {"ts": now_monotonic, "payload": payload}
    return payload


def load_knowledge_learning_quality_payload() -> dict[str, Any]:
    cache = getattr(load_knowledge_learning_quality_payload, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 5.0:
        return cache["payload"]

    summary_payload = read_json(KNOWLEDGE_QUALITY_LAST_PATH, default={})
    summary_payload = summary_payload if isinstance(summary_payload, dict) else {}
    cards_payload = read_json(KNOWLEDGE_CARDS_LAST_PATH, default={})
    cards_payload = cards_payload if isinstance(cards_payload, dict) else {}
    reuse_payload = read_json(KNOWLEDGE_REUSE_LAST_PATH, default={})
    reuse_payload = reuse_payload if isinstance(reuse_payload, dict) else {}
    anti_repeat_payload = read_json(ANTI_REPEAT_MEMORY_LAST_PATH, default={})
    anti_repeat_payload = anti_repeat_payload if isinstance(anti_repeat_payload, dict) else {}
    outcome_payload = read_json(OUTCOME_LEARNING_LAST_PATH, default={})
    outcome_payload = outcome_payload if isinstance(outcome_payload, dict) else {}

    trust_band_counts = summary_payload.get("trust_band_counts")
    trust_band_counts = trust_band_counts if isinstance(trust_band_counts, dict) else {}

    payload = {
        "owner_only": True,
        "overall_status": normalize_text(summary_payload.get("overall_status")).upper() or "UNKNOWN",
        "card_count": int(summary_payload.get("card_count") or cards_payload.get("card_count") or 0),
        "reusable_card_count": int(summary_payload.get("reusable_card_count") or reuse_payload.get("selected_card_count") or 0),
        "trusted_card_count": int(trust_band_counts.get("trusted") or cards_payload.get("trusted_card_count") or 0),
        "review_card_count": int(summary_payload.get("review_card_count") or cards_payload.get("review_required_count") or 0),
        "stale_card_count": int(summary_payload.get("stale_card_count") or cards_payload.get("stale_card_count") or 0),
        "blocked_card_count": int(summary_payload.get("blocked_card_count") or cards_payload.get("blocked_card_count") or 0),
        "anti_repeat_count": int(summary_payload.get("anti_repeat_count") or anti_repeat_payload.get("anti_repeat_count") or 0),
        "low_confidence_teacher_count": int(summary_payload.get("low_confidence_teacher_count") or 0),
        "recommended_next_action": normalize_short_text(
            summary_payload.get("recommended_next_action")
            or reuse_payload.get("recommended_next_action")
            or anti_repeat_payload.get("recommended_next_action"),
            max_len=240,
        ),
        "recent_reused_cards": [
            {
                "card_id": normalize_text(item.get("card_id")),
                "title": normalize_short_text(item.get("title"), max_len=140),
                "confidence_band": normalize_text(item.get("confidence_band")),
                "evidence_band": normalize_text(item.get("evidence_band")),
                "why_selected": normalize_short_text(item.get("why_selected"), max_len=180),
            }
            for item in (summary_payload.get("recent_reused_cards") or reuse_payload.get("recent_reused_cards") or [])
            if isinstance(item, dict)
        ][:6],
        "low_confidence_teacher_material": [
            {
                "card_id": normalize_text(item.get("card_id")),
                "title": normalize_short_text(item.get("title"), max_len=160),
                "confidence_band": normalize_text(item.get("confidence_band")),
                "review_status": normalize_text(item.get("review_status")),
                "notes_for_reviewer": [
                    normalize_short_text(note, max_len=180)
                    for note in (item.get("notes_for_reviewer") or [])
                    if normalize_text(note)
                ][:3],
            }
            for item in (summary_payload.get("low_confidence_teacher_material") or reuse_payload.get("low_confidence_teacher_material") or [])
            if isinstance(item, dict)
        ][:8],
        "outcome_update_count": int(outcome_payload.get("update_count") or 0),
        "outcome_supported_count": int(outcome_payload.get("outcome_supported_count") or 0),
        "generated_at_utc": normalize_text(summary_payload.get("timestamp_utc") or cards_payload.get("timestamp_utc")),
        "knowledge_quality_path": str(KNOWLEDGE_QUALITY_LAST_PATH),
        "knowledge_cards_path": str(KNOWLEDGE_CARDS_LAST_PATH),
        "knowledge_reuse_path": str(KNOWLEDGE_REUSE_LAST_PATH),
        "anti_repeat_path": str(ANTI_REPEAT_MEMORY_LAST_PATH),
        "outcome_learning_path": str(OUTCOME_LEARNING_LAST_PATH),
        "policy_path": str(KNOWLEDGE_QUALITY_POLICY_PATH),
        "knowledge_cards_state_path": str(KNOWLEDGE_CARDS_STATE_PATH),
    }
    load_knowledge_learning_quality_payload._cache = {"ts": now_monotonic, "payload": payload}
    return payload


def load_ux_simplicity_payload() -> dict[str, Any]:
    cache = getattr(load_ux_simplicity_payload, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 5.0:
        return cache["payload"]

    summary_payload = read_json(UX_SIMPLICITY_LAST_PATH, default={})
    summary_payload = summary_payload if isinstance(summary_payload, dict) else {}
    founder_payload = read_json(ATHENA_FOUNDER_UX_LAST_PATH, default={})
    founder_payload = founder_payload if isinstance(founder_payload, dict) else {}
    onyx_payload = read_json(ONYX_CUSTOMER_UX_LAST_PATH, default={})
    onyx_payload = onyx_payload if isinstance(onyx_payload, dict) else {}
    approvals_payload = read_json(APPROVAL_SURFACE_LAST_PATH, default={})
    approvals_payload = approvals_payload if isinstance(approvals_payload, dict) else {}
    registry_payload = read_json(UX_SIMPLICITY_REGISTRY_PATH, default={})
    registry_payload = registry_payload if isinstance(registry_payload, dict) else {}

    payload = {
        "owner_only": True,
        "overall_status": normalize_text(summary_payload.get("overall_status")).upper() or "UNKNOWN",
        "athena_founder_ux_status": normalize_text(
            summary_payload.get("athena_founder_ux_status")
            or founder_payload.get("overall_status")
        ).upper() or "UNKNOWN",
        "onyx_customer_ux_status": normalize_text(
            summary_payload.get("onyx_customer_ux_status")
            or onyx_payload.get("overall_status")
        ).upper() or "UNKNOWN",
        "dead_button_count": int(
            summary_payload.get("dead_button_count")
            if "dead_button_count" in summary_payload
            else founder_payload.get("dead_button_count") or 0
        ),
        "approval_surface_status": normalize_text(
            summary_payload.get("approval_surface_status")
            or founder_payload.get("approval_surface_status")
            or approvals_payload.get("overall_status")
        ).upper() or "UNKNOWN",
        "mobile_layout_status": normalize_text(
            summary_payload.get("mobile_layout_status")
            or founder_payload.get("mobile_friendliness_classification")
        ) or "unknown",
        "recommended_next_action": normalize_short_text(
            summary_payload.get("recommended_next_action")
            or founder_payload.get("recommended_next_action")
            or onyx_payload.get("recommended_next_action")
            or approvals_payload.get("recommended_next_action"),
            max_len=240,
        ),
        "approval_button_count": int(approvals_payload.get("approve_button_count") or 0),
        "reject_button_count": int(approvals_payload.get("reject_button_count") or 0),
        "control_button_count": int(summary_payload.get("control_button_count") or 0),
        "founder_only_confirmed": bool(founder_payload.get("founder_only_confirmed")),
        "generated_at_utc": normalize_text(
            summary_payload.get("timestamp_utc")
            or registry_payload.get("generated_at_utc")
        ),
        "ux_simplicity_path": str(UX_SIMPLICITY_LAST_PATH),
        "athena_founder_ux_path": str(ATHENA_FOUNDER_UX_LAST_PATH),
        "onyx_customer_ux_path": str(ONYX_CUSTOMER_UX_LAST_PATH),
        "approval_surface_path": str(APPROVAL_SURFACE_LAST_PATH),
        "registry_path": str(UX_SIMPLICITY_REGISTRY_PATH),
        "policy_path": str(UX_SIMPLICITY_POLICY_PATH),
    }
    load_ux_simplicity_payload._cache = {"ts": now_monotonic, "payload": payload}
    return payload


def load_whole_folder_verification_payload() -> dict[str, Any]:
    cache = getattr(load_whole_folder_verification_payload, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 5.0:
        return cache["payload"]

    summary_payload = read_json(WHOLE_FOLDER_VERIFICATION_LAST_PATH, default={})
    summary_payload = summary_payload if isinstance(summary_payload, dict) else {}
    registration_payload = read_json(WHOLE_FOLDER_REGISTRATION_GAPS_PATH, default={})
    registration_payload = registration_payload if isinstance(registration_payload, dict) else {}
    broken_payload = read_json(WHOLE_FOLDER_BROKEN_PATHS_LAST_PATH, default={})
    broken_payload = broken_payload if isinstance(broken_payload, dict) else {}
    golden_payload = read_json(WHOLE_FOLDER_GOLDEN_PATHS_LAST_PATH, default={})
    golden_payload = golden_payload if isinstance(golden_payload, dict) else {}
    fault_payload = read_json(WHOLE_FOLDER_FAULT_TESTS_LAST_PATH, default={})
    fault_payload = fault_payload if isinstance(fault_payload, dict) else {}
    migration_payload = read_json(WHOLE_FOLDER_MIGRATION_CHECKS_LAST_PATH, default={})
    migration_payload = migration_payload if isinstance(migration_payload, dict) else {}
    usability_payload = read_json(WHOLE_FOLDER_USABILITY_CHECKS_LAST_PATH, default={})
    usability_payload = usability_payload if isinstance(usability_payload, dict) else {}

    inventory_summary = summary_payload.get("inventory_summary")
    inventory_summary = inventory_summary if isinstance(inventory_summary, dict) else {}

    top_broken_paths = []
    for item in (summary_payload.get("top_broken_paths") or broken_payload.get("records") or []):
        if not isinstance(item, dict):
            continue
        top_broken_paths.append(
            {
                "path": normalize_text(item.get("path")),
                "component": normalize_text(item.get("component")),
                "severity": normalize_text(item.get("severity")).upper() or "UNKNOWN",
                "description": normalize_short_text(item.get("description"), max_len=200),
                "recommended_action": normalize_short_text(item.get("recommended_action"), max_len=200),
            }
        )
        if len(top_broken_paths) >= 6:
            break

    top_registration_gaps = []
    for item in (summary_payload.get("top_registration_gaps") or registration_payload.get("gaps") or []):
        if not isinstance(item, dict):
            continue
        top_registration_gaps.append(
            {
                "item_id": normalize_text(item.get("item_id")),
                "gap_type": normalize_text(item.get("gap_type")),
                "severity": normalize_text(item.get("severity")).upper() or "UNKNOWN",
                "path": normalize_text(item.get("path")),
                "description": normalize_short_text(item.get("description"), max_len=200),
                "recommended_action": normalize_short_text(item.get("recommended_action"), max_len=200),
            }
        )
        if len(top_registration_gaps) >= 6:
            break

    payload = {
        "owner_only": True,
        "overall_status": normalize_text(summary_payload.get("overall_status")).upper() or "UNKNOWN",
        "inventory_summary": {
            "total_scanned": int(inventory_summary.get("total_scanned") or 0),
            "broken_count": int(inventory_summary.get("broken_count") or 0),
            "orphaned_count": int(inventory_summary.get("orphaned_count") or 0),
            "dangerous_count": int(inventory_summary.get("dangerous_count") or 0),
            "stale_count": int(inventory_summary.get("stale_count") or 0),
        },
        "broken_path_count": int(summary_payload.get("broken_path_count") or broken_payload.get("broken_path_count") or 0),
        "unregistered_count": int(summary_payload.get("unregistered_count") or registration_payload.get("unregistered_count") or 0),
        "registry_gap_count": int(summary_payload.get("registry_gap_count") or registration_payload.get("gap_count") or 0),
        "golden_path_status": normalize_text(summary_payload.get("golden_path_status") or golden_payload.get("overall_status")).upper() or "UNKNOWN",
        "fault_test_status": normalize_text(summary_payload.get("fault_test_status") or fault_payload.get("overall_status")).upper() or "UNKNOWN",
        "migration_risk_status": normalize_text(summary_payload.get("migration_risk_status") or migration_payload.get("overall_status")).upper() or "UNKNOWN",
        "usability_status": normalize_text(summary_payload.get("usability_status") or usability_payload.get("overall_status")).upper() or "UNKNOWN",
        "mirror_status": normalize_text(summary_payload.get("mirror_status")).upper() or "UNKNOWN",
        "critical_path_broken": bool(summary_payload.get("critical_path_broken")),
        "recommended_next_action": normalize_short_text(
            summary_payload.get("recommended_next_action")
            or broken_payload.get("recommended_next_action")
            or registration_payload.get("recommended_next_action"),
            max_len=240,
        ),
        "inventory_summary_line": normalize_short_text(summary_payload.get("inventory_summary_line"), max_len=220),
        "mirror_summary_line": normalize_short_text(summary_payload.get("mirror_summary_line"), max_len=220),
        "generated_at_utc": normalize_text(summary_payload.get("timestamp_utc")),
        "top_broken_paths": top_broken_paths,
        "top_registration_gaps": top_registration_gaps,
        "whole_folder_verification_path": str(WHOLE_FOLDER_VERIFICATION_LAST_PATH),
        "inventory_path": str(WHOLE_FOLDER_INVENTORY_LAST_PATH),
        "registration_gaps_path": str(WHOLE_FOLDER_REGISTRATION_GAPS_PATH),
        "broken_paths_path": str(WHOLE_FOLDER_BROKEN_PATHS_LAST_PATH),
        "golden_paths_path": str(WHOLE_FOLDER_GOLDEN_PATHS_LAST_PATH),
        "fault_tests_path": str(WHOLE_FOLDER_FAULT_TESTS_LAST_PATH),
        "migration_checks_path": str(WHOLE_FOLDER_MIGRATION_CHECKS_LAST_PATH),
        "usability_checks_path": str(WHOLE_FOLDER_USABILITY_CHECKS_LAST_PATH),
        "cleanup_queue_path": str(WHOLE_FOLDER_CLEANUP_QUEUE_PATH),
        "summary_markdown_path": str(WHOLE_FOLDER_VERIFICATION_SUMMARY_MD_PATH),
        "policy_path": str(WHOLE_FOLDER_VERIFICATION_POLICY_PATH),
    }
    load_whole_folder_verification_payload._cache = {"ts": now_monotonic, "payload": payload}
    return payload


def load_repair_wave_payloads() -> dict[str, dict[str, Any]]:
    cache = getattr(load_repair_wave_payloads, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 5.0:
        return cache["payload"]

    summary_payload = read_json(REPAIR_WAVE_01_LAST_PATH, default={})
    summary_payload = summary_payload if isinstance(summary_payload, dict) else {}
    onboarding_payload = read_json(REPAIR_ONBOARDING_LAST_PATH, default={})
    onboarding_payload = onboarding_payload if isinstance(onboarding_payload, dict) else {}
    billing_payload = read_json(REPAIR_BILLING_ENTITLEMENTS_LAST_PATH, default={})
    billing_payload = billing_payload if isinstance(billing_payload, dict) else {}
    halfwired_payload = read_json(REPAIR_HALFWIRED_LAST_PATH, default={})
    halfwired_payload = halfwired_payload if isinstance(halfwired_payload, dict) else {}
    scheduler_payload = read_json(REPAIR_SCHEDULER_OVERSIGHT_LAST_PATH, default={})
    scheduler_payload = scheduler_payload if isinstance(scheduler_payload, dict) else {}
    visibility_payload = read_json(REPAIR_INTERNAL_VISIBILITY_LAST_PATH, default={})
    visibility_payload = visibility_payload if isinstance(visibility_payload, dict) else {}
    mirror_payload = read_json(REPAIR_MIRROR_HARDENING_LAST_PATH, default={})
    mirror_payload = mirror_payload if isinstance(mirror_payload, dict) else {}
    repair_wave_02_payload = read_json(REPAIR_WAVE_02_LAST_PATH, default={})
    repair_wave_02_payload = repair_wave_02_payload if isinstance(repair_wave_02_payload, dict) else {}
    internal_scheduler_payload = read_json(INTERNAL_SCHEDULER_LAST_PATH, default={})
    internal_scheduler_payload = internal_scheduler_payload if isinstance(internal_scheduler_payload, dict) else {}
    legacy_task_inventory_payload = read_json(LEGACY_TASK_INVENTORY_LAST_PATH, default={})
    legacy_task_inventory_payload = legacy_task_inventory_payload if isinstance(legacy_task_inventory_payload, dict) else {}
    legacy_task_migration_payload = read_json(LEGACY_TASK_MIGRATION_LAST_PATH, default={})
    legacy_task_migration_payload = legacy_task_migration_payload if isinstance(legacy_task_migration_payload, dict) else {}
    popup_suppression_payload = read_json(POPUP_SUPPRESSION_LAST_PATH, default={})
    popup_suppression_payload = popup_suppression_payload if isinstance(popup_suppression_payload, dict) else {}
    validator_coverage_repair_payload = read_json(VALIDATOR_COVERAGE_REPAIR_LAST_PATH, default={})
    validator_coverage_repair_payload = validator_coverage_repair_payload if isinstance(validator_coverage_repair_payload, dict) else {}
    broken_path_cluster_repair_payload = read_json(BROKEN_PATH_CLUSTER_REPAIR_LAST_PATH, default={})
    broken_path_cluster_repair_payload = broken_path_cluster_repair_payload if isinstance(broken_path_cluster_repair_payload, dict) else {}
    remote_push_repair_payload = read_json(REMOTE_PUSH_REPAIR_LAST_PATH, default={})
    remote_push_repair_payload = remote_push_repair_payload if isinstance(remote_push_repair_payload, dict) else {}

    payload = {
        "repair_wave_01": {
            "owner_only": True,
            "overall_status": normalize_text(summary_payload.get("overall_status")).upper() or "UNKNOWN",
            "onboarding_repair_status": normalize_text(summary_payload.get("onboarding_repair_status")).upper() or "UNKNOWN",
            "billing_entitlements_repair_status": normalize_text(summary_payload.get("billing_entitlements_repair_status")).upper() or "UNKNOWN",
            "halfwired_repair_status": normalize_text(summary_payload.get("halfwired_repair_status")).upper() or "UNKNOWN",
            "registration_gap_status": normalize_text(summary_payload.get("registration_gap_status")).upper() or "UNKNOWN",
            "fixed_count": int(summary_payload.get("fixed_count") or 0),
            "unresolved_queue_count": int(summary_payload.get("unresolved_queue_count") or 0),
            "broken_paths_before": int(summary_payload.get("broken_paths_before") or 0),
            "broken_paths_after": int(summary_payload.get("broken_paths_after") or 0),
            "registration_gaps_before": int(summary_payload.get("registration_gaps_before") or 0),
            "registration_gaps_after": int(summary_payload.get("registration_gaps_after") or 0),
            "mirror_push_result": normalize_text(summary_payload.get("mirror_push_result")) or "unknown",
            "recommended_next_action": normalize_short_text(summary_payload.get("recommended_next_action"), max_len=240),
            "generated_at_utc": normalize_text(summary_payload.get("timestamp_utc")),
            "repair_wave_01_path": str(REPAIR_WAVE_01_LAST_PATH),
            "policy_path": str(REPAIR_WAVE_01_POLICY_PATH),
        },
        "onboarding_repair": {
            "owner_only": True,
            "overall_status": normalize_text(onboarding_payload.get("overall_status")).upper() or "UNKNOWN",
            "public_wording_status": normalize_text(onboarding_payload.get("public_wording_status")).upper() or "UNKNOWN",
            "completion_action_status": normalize_text(onboarding_payload.get("completion_action_status")).upper() or "UNKNOWN",
            "dead_button_count": int(onboarding_payload.get("dead_button_count") or 0),
            "active_selector_label": normalize_short_text(onboarding_payload.get("active_selector_label"), max_len=80),
            "recommended_next_action": normalize_short_text(onboarding_payload.get("recommended_next_action"), max_len=240),
            "generated_at_utc": normalize_text(onboarding_payload.get("timestamp_utc")),
            "repair_onboarding_path": str(REPAIR_ONBOARDING_LAST_PATH),
        },
        "billing_entitlements_repair": {
            "owner_only": True,
            "overall_status": normalize_text(billing_payload.get("overall_status")).upper() or "UNKNOWN",
            "root_cause_class": normalize_text(billing_payload.get("root_cause_class")) or "unknown",
            "active_workspace_label": normalize_short_text(billing_payload.get("active_workspace_label"), max_len=120),
            "current_tier": normalize_short_text(billing_payload.get("current_tier"), max_len=80),
            "enabled_tools_before_count": len(normalize_list(billing_payload.get("enabled_tools_before"))),
            "enabled_tools_after_count": len(normalize_list(billing_payload.get("enabled_tools_after"))),
            "repaired": bool(billing_payload.get("repaired_bool")),
            "checkout_required": bool(billing_payload.get("checkout_required")),
            "recommended_next_action": normalize_short_text(
                billing_payload.get("recommended_next_action") or billing_payload.get("why_blocked_if_not_repaired"),
                max_len=240,
            ),
            "generated_at_utc": normalize_text(billing_payload.get("timestamp_utc")),
            "repair_billing_path": str(REPAIR_BILLING_ENTITLEMENTS_LAST_PATH),
        },
        "halfwired_repair": {
            "owner_only": True,
            "overall_status": normalize_text(halfwired_payload.get("overall_status")).upper() or "UNKNOWN",
            "fixed_count": int(halfwired_payload.get("fixed_count") or 0),
            "queued_count": int(halfwired_payload.get("queued_count") or 0),
            "recommended_next_action": normalize_short_text(halfwired_payload.get("recommended_next_action"), max_len=240),
            "generated_at_utc": normalize_text(halfwired_payload.get("timestamp_utc")),
            "repair_halfwired_path": str(REPAIR_HALFWIRED_LAST_PATH),
        },
        "scheduler_oversight": {
            "owner_only": True,
            "overall_status": normalize_text(scheduler_payload.get("overall_status")).upper() or "UNKNOWN",
            "relevant_task_count": int(scheduler_payload.get("relevant_task_count") or 0),
            "healthy_count": int(scheduler_payload.get("healthy_count") or 0),
            "disabled_count": int(scheduler_payload.get("disabled_count") or 0),
            "stale_count": int(scheduler_payload.get("stale_count") or 0),
            "failing_count": int(scheduler_payload.get("failing_count") or 0),
            "recommended_next_action": normalize_short_text(scheduler_payload.get("recommended_next_action"), max_len=240),
            "generated_at_utc": normalize_text(scheduler_payload.get("timestamp_utc")),
            "repair_scheduler_path": str(REPAIR_SCHEDULER_OVERSIGHT_LAST_PATH),
        },
        "internal_visibility": {
            "owner_only": True,
            "overall_status": normalize_text(visibility_payload.get("overall_status")).upper() or "UNKNOWN",
            "visible_category_count": int(visibility_payload.get("visible_category_count") or 0),
            "blind_spot_count": int(visibility_payload.get("blind_spot_count") or 0),
            "recommended_next_action": normalize_short_text(visibility_payload.get("recommended_next_action"), max_len=240),
            "generated_at_utc": normalize_text(visibility_payload.get("timestamp_utc")),
            "repair_internal_visibility_path": str(REPAIR_INTERNAL_VISIBILITY_LAST_PATH),
        },
        "mirror_hardening": {
            "owner_only": True,
            "overall_status": normalize_text(mirror_payload.get("overall_status")).upper() or "UNKNOWN",
            "coverage_status": normalize_text(mirror_payload.get("coverage_status")).upper() or "UNKNOWN",
            "omission_status": normalize_text(mirror_payload.get("omission_status")).upper() or "UNKNOWN",
            "matched_file_count": int(mirror_payload.get("matched_file_count") or 0),
            "omission_count": int(mirror_payload.get("omission_count") or 0),
            "remote_push_result": normalize_text(mirror_payload.get("remote_push_result")) or "unknown",
            "remote_current": bool(mirror_payload.get("remote_current")),
            "recommended_next_action": normalize_short_text(mirror_payload.get("recommended_next_action"), max_len=240),
            "generated_at_utc": normalize_text(mirror_payload.get("timestamp_utc")),
            "repair_mirror_path": str(REPAIR_MIRROR_HARDENING_LAST_PATH),
            "mirror_coverage_path": str(MIRROR_COVERAGE_LAST_PATH),
            "mirror_omission_path": str(MIRROR_OMISSION_LAST_PATH),
            "mirror_safe_index_path": str(MIRROR_SAFE_INDEX_PATH),
        },
        "repair_wave_02": {
            "owner_only": True,
            "overall_status": normalize_text(repair_wave_02_payload.get("overall_status")).upper() or "UNKNOWN",
            "internal_scheduler_status": normalize_text(repair_wave_02_payload.get("internal_scheduler_status")).upper() or "UNKNOWN",
            "legacy_task_migration_status": normalize_text(repair_wave_02_payload.get("legacy_task_migration_status")).upper() or "UNKNOWN",
            "popup_suppression_status": normalize_text(repair_wave_02_payload.get("popup_suppression_status")).upper() or "UNKNOWN",
            "validator_coverage_status": normalize_text(repair_wave_02_payload.get("validator_coverage_status")).upper() or "UNKNOWN",
            "broken_path_repair_status": normalize_text(repair_wave_02_payload.get("broken_path_repair_status")).upper() or "UNKNOWN",
            "remote_push_repair_status": normalize_text(repair_wave_02_payload.get("remote_push_repair_status")).upper() or "UNKNOWN",
            "migrated_task_count": int(repair_wave_02_payload.get("migrated_task_count") or 0),
            "popup_fixed_count": int(repair_wave_02_payload.get("popup_fixed_count") or 0),
            "broken_paths_before": int(repair_wave_02_payload.get("broken_paths_before") or 0),
            "broken_paths_after": int(repair_wave_02_payload.get("broken_paths_after") or 0),
            "remote_push_result": normalize_text(repair_wave_02_payload.get("remote_push_result")) or "unknown",
            "recommended_next_action": normalize_short_text(repair_wave_02_payload.get("recommended_next_action"), max_len=240),
            "generated_at_utc": normalize_text(repair_wave_02_payload.get("timestamp_utc")),
            "repair_wave_02_path": str(REPAIR_WAVE_02_LAST_PATH),
            "policy_path": str(REPAIR_WAVE_02_POLICY_PATH),
        },
        "internal_scheduler": {
            "owner_only": True,
            "overall_status": normalize_text(internal_scheduler_payload.get("overall_status")).upper() or "UNKNOWN",
            "task_definition_count": int(internal_scheduler_payload.get("task_definition_count") or 0),
            "enabled_task_count": int(internal_scheduler_payload.get("enabled_task_count") or 0),
            "foundation_status": normalize_text(internal_scheduler_payload.get("foundation_status")).upper() or "UNKNOWN",
            "audit_logging_status": normalize_text(internal_scheduler_payload.get("audit_logging_status")).upper() or "UNKNOWN",
            "windows_fallback_dependency_count": int(internal_scheduler_payload.get("windows_fallback_dependency_count") or 0),
            "recommended_next_action": normalize_short_text(internal_scheduler_payload.get("recommended_next_action"), max_len=240),
            "generated_at_utc": normalize_text(internal_scheduler_payload.get("timestamp_utc")),
            "internal_scheduler_path": str(INTERNAL_SCHEDULER_LAST_PATH),
            "policy_path": str(INTERNAL_SCHEDULER_POLICY_PATH),
        },
        "legacy_task_migration": {
            "owner_only": True,
            "overall_status": normalize_text(legacy_task_migration_payload.get("overall_status")).upper() or "UNKNOWN",
            "relevant_task_count": int(legacy_task_inventory_payload.get("relevant_task_count") or 0),
            "migrated_count": int(legacy_task_migration_payload.get("migrated_count") or 0),
            "fallback_only_count": int(legacy_task_migration_payload.get("fallback_only_count") or 0),
            "keep_temporarily_count": int(legacy_task_migration_payload.get("keep_temporarily_count") or 0),
            "blocked_count": int(legacy_task_migration_payload.get("blocked_count") or 0),
            "recommended_next_action": normalize_short_text(legacy_task_migration_payload.get("recommended_next_action"), max_len=240),
            "generated_at_utc": normalize_text(legacy_task_migration_payload.get("timestamp_utc")),
            "legacy_task_inventory_path": str(LEGACY_TASK_INVENTORY_LAST_PATH),
            "legacy_task_migration_path": str(LEGACY_TASK_MIGRATION_LAST_PATH),
            "policy_path": str(LEGACY_TASK_MIGRATION_POLICY_PATH),
        },
        "popup_suppression": {
            "owner_only": True,
            "overall_status": normalize_text(popup_suppression_payload.get("overall_status")).upper() or "UNKNOWN",
            "noisy_source_count": int(popup_suppression_payload.get("noisy_source_count") or 0),
            "fixed_count": int(popup_suppression_payload.get("fixed_count") or 0),
            "remaining_visible_count": int(popup_suppression_payload.get("remaining_visible_count") or 0),
            "recommended_next_action": normalize_short_text(popup_suppression_payload.get("recommended_next_action"), max_len=240),
            "generated_at_utc": normalize_text(popup_suppression_payload.get("timestamp_utc")),
            "popup_suppression_path": str(POPUP_SUPPRESSION_LAST_PATH),
        },
        "validator_coverage_repair": {
            "owner_only": True,
            "overall_status": normalize_text(validator_coverage_repair_payload.get("overall_status")).upper() or "UNKNOWN",
            "components_checked": normalize_list(validator_coverage_repair_payload.get("components_checked")),
            "fully_covered_count": int(validator_coverage_repair_payload.get("fully_covered_count") or 0),
            "uncovered_count": int(validator_coverage_repair_payload.get("uncovered_count") or 0),
            "recommended_next_action": normalize_short_text(validator_coverage_repair_payload.get("recommended_next_action"), max_len=240),
            "generated_at_utc": normalize_text(validator_coverage_repair_payload.get("timestamp_utc")),
            "validator_coverage_repair_path": str(VALIDATOR_COVERAGE_REPAIR_LAST_PATH),
        },
        "broken_path_cluster_repair": {
            "owner_only": True,
            "overall_status": normalize_text(broken_path_cluster_repair_payload.get("overall_status")).upper() or "UNKNOWN",
            "target_cluster_count": int(broken_path_cluster_repair_payload.get("target_cluster_count") or 0),
            "fixed_count": int(broken_path_cluster_repair_payload.get("fixed_count") or 0),
            "broken_paths_before": int(broken_path_cluster_repair_payload.get("broken_paths_before") or 0),
            "broken_paths_after": int(broken_path_cluster_repair_payload.get("broken_paths_after") or 0),
            "recommended_next_action": normalize_short_text(broken_path_cluster_repair_payload.get("recommended_next_action"), max_len=240),
            "generated_at_utc": normalize_text(broken_path_cluster_repair_payload.get("timestamp_utc")),
            "broken_path_cluster_repair_path": str(BROKEN_PATH_CLUSTER_REPAIR_LAST_PATH),
        },
        "remote_push_repair": {
            "owner_only": True,
            "overall_status": normalize_text(remote_push_repair_payload.get("overall_status")).upper() or "UNKNOWN",
            "push_failure_class": normalize_text(remote_push_repair_payload.get("push_failure_class")) or "unknown",
            "safe_repair_attempted": bool(remote_push_repair_payload.get("safe_repair_attempted")),
            "remote_push_result": normalize_text(remote_push_repair_payload.get("remote_push_result")) or "unknown",
            "remote_current": bool(remote_push_repair_payload.get("remote_current")),
            "oversized_path_count": len(normalize_list(remote_push_repair_payload.get("oversized_paths"))),
            "recommended_next_action": normalize_short_text(remote_push_repair_payload.get("recommended_next_action"), max_len=240),
            "generated_at_utc": normalize_text(remote_push_repair_payload.get("timestamp_utc")),
            "remote_push_repair_path": str(REMOTE_PUSH_REPAIR_LAST_PATH),
        },
    }
    load_repair_wave_payloads._cache = {"ts": now_monotonic, "payload": payload}
    return payload


def normalize_founder_risk_level(value: Any) -> str:
    text = normalize_short_text(value, max_len=24).upper()
    if not text:
        return "R1"
    if re.fullmatch(r"R\d+", text):
        return text
    if text.isdigit():
        return f"R{text}"
    if text in {"LOW", "MEDIUM", "HIGH", "CRITICAL"}:
        return text
    return "R1"


def founder_risk_sort_value(value: Any) -> int:
    text = normalize_founder_risk_level(value)
    if text.startswith("R"):
        try:
            return int(text[1:])
        except Exception:
            return 1
    order = {"LOW": 1, "MEDIUM": 2, "HIGH": 3, "CRITICAL": 4}
    return order.get(text, 1)


def founder_display_state(value: Any) -> str:
    text = normalize_text(value).strip().lower()
    if not text:
        return "Review Only"
    if text in {"pass", "ok", "green", "success", "healthy", "guarded", "normal", "done", "no_material_change", "retain_current_posture", "loopback_only"}:
        return "Healthy"
    if text in {"blocked", "blocked_pending_human_review"}:
        return "Blocked"
    if text in {"review_only", "queue_for_review", "suggest_only", "approval_required"}:
        return "Review Only"
    if text in {"fail", "failed", "red", "restricted", "protect_host", "error"}:
        return "Action Required"
    if text in {"warn", "warning", "yellow", "watch", "caution", "stub", "pending_reboot", "minor_change", "significant_change", "new_environment"}:
        return "Warning"
    return "Review Only"


def founder_item(
    *,
    title: str,
    raw_status: Any = "",
    display_state: str = "",
    reason: str = "",
    source_path: str = "",
    risk_level: str = "R1",
    action_posture: str = "review_needed",
    item_id: str = "",
    component: str = "",
) -> dict[str, Any]:
    state = normalize_short_text(display_state, max_len=32) or founder_display_state(raw_status)
    posture = normalize_short_text(action_posture, max_len=24).lower() or "review_needed"
    if posture not in {"safe", "review_needed", "blocked"}:
        posture = "review_needed"
    return {
        "item_id": normalize_short_text(item_id, max_len=120),
        "title": normalize_short_text(title, max_len=140) or "Untitled",
        "display_state": state,
        "raw_status": normalize_short_text(raw_status, max_len=32),
        "reason": normalize_short_text(reason, max_len=240),
        "source_path": normalize_text(source_path),
        "risk_level": normalize_founder_risk_level(risk_level),
        "action_posture": posture,
        "component": normalize_short_text(component, max_len=80),
    }


def load_host_guardian_summary() -> dict[str, Any]:
    cache = getattr(load_host_guardian_summary, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 5.0:
        return cache["payload"]

    payload = read_json(HOST_HEALTH_LAST_PATH, default={})
    payload = payload if isinstance(payload, dict) else {}
    uptime = payload.get("uptime") if isinstance(payload.get("uptime"), dict) else {}
    disk = payload.get("disk") if isinstance(payload.get("disk"), dict) else {}
    runtime = payload.get("mason_runtime_health") if isinstance(payload.get("mason_runtime_health"), dict) else {}
    report_growth = runtime.get("report_growth") if isinstance(runtime.get("report_growth"), dict) else {}
    summary = {
        "timestamp_utc": normalize_text(payload.get("timestamp_utc")),
        "overall_status": normalize_text(payload.get("overall_status")).upper() or "UNKNOWN",
        "display_state": founder_display_state(payload.get("overall_status")),
        "pending_reboot": bool(uptime.get("pending_reboot", False)),
        "throttle_guidance": normalize_short_text(payload.get("throttle_guidance"), max_len=40) or "normal",
        "disk_free_percent": disk.get("system_drive_free_percent"),
        "report_growth_status": normalize_text(report_growth.get("status")).upper(),
        "report_growth_recommended_action": normalize_short_text(report_growth.get("recommended_action"), max_len=240),
        "recommended_next_action": normalize_short_text(payload.get("recommended_next_action"), max_len=240),
        "path": str(HOST_HEALTH_LAST_PATH),
    }
    load_host_guardian_summary._cache = {"ts": now_monotonic, "payload": summary}
    return summary


def load_environment_adaptation_summary() -> dict[str, Any]:
    cache = getattr(load_environment_adaptation_summary, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 5.0:
        return cache["payload"]

    profile = read_json(ENVIRONMENT_PROFILE_LAST_PATH, default={})
    profile = profile if isinstance(profile, dict) else {}
    drift = read_json(ENVIRONMENT_DRIFT_LAST_PATH, default={})
    drift = drift if isinstance(drift, dict) else {}
    posture = read_json(RUNTIME_POSTURE_LAST_PATH, default={})
    posture = posture if isinstance(posture, dict) else {}
    summary = {
        "timestamp_utc": normalize_text(posture.get("timestamp_utc") or drift.get("timestamp_utc") or profile.get("timestamp_utc")),
        "environment_id": normalize_short_text(posture.get("environment_id") or drift.get("current_environment_id"), max_len=64),
        "host_classification": normalize_short_text(posture.get("host_classification"), max_len=40),
        "drift_level": normalize_short_text(drift.get("drift_level"), max_len=40) or "unknown",
        "migration_detected": bool(drift.get("migration_detected", False)),
        "learning_posture": normalize_short_text(posture.get("learning_posture"), max_len=40),
        "heavy_jobs_posture": normalize_short_text(posture.get("heavy_jobs_posture"), max_len=40),
        "monitoring_posture": normalize_short_text(posture.get("monitoring_posture"), max_len=40),
        "cleanup_posture": normalize_short_text(posture.get("cleanup_posture"), max_len=40),
        "throttle_guidance": normalize_short_text(posture.get("throttle_guidance"), max_len=40),
        "recommended_next_action": normalize_short_text(posture.get("recommended_next_action") or drift.get("recommended_next_action"), max_len=240),
        "profile_path": str(ENVIRONMENT_PROFILE_LAST_PATH),
        "drift_path": str(ENVIRONMENT_DRIFT_LAST_PATH),
        "posture_path": str(RUNTIME_POSTURE_LAST_PATH),
    }
    load_environment_adaptation_summary._cache = {"ts": now_monotonic, "payload": summary}
    return summary


def load_self_improvement_posture_summary() -> dict[str, Any]:
    cache = getattr(load_self_improvement_posture_summary, "_cache", {"ts": 0.0, "payload": {}})
    now_monotonic = time.monotonic()
    if isinstance(cache.get("payload"), dict) and cache.get("payload") and (now_monotonic - float(cache.get("ts") or 0.0)) < 10.0:
        return cache["payload"]

    governor = read_json(SELF_IMPROVEMENT_GOVERNOR_REPORT_PATH, default={})
    governor = governor if isinstance(governor, dict) else {}
    budget = read_json(TEACHER_CALL_BUDGET_REPORT_PATH, default={})
    budget = budget if isinstance(budget, dict) else {}
    decision_log = read_json(TEACHER_DECISION_LOG_REPORT_PATH, default={})
    decision_log = decision_log if isinstance(decision_log, dict) else {}
    policy = load_self_improvement_policy()
    exec_counts = governor.get("counts_by_execution_disposition") if isinstance(governor.get("counts_by_execution_disposition"), dict) else {}
    quality_counts = governor.get("counts_by_teacher_quality_classification") if isinstance(governor.get("counts_by_teacher_quality_classification"), dict) else {}
    items = [item for item in normalize_list(governor.get("items")) if isinstance(item, dict)]

    def sorted_items_for(dispositions: set[str]) -> list[dict[str, Any]]:
        filtered = [
            item
            for item in items
            if normalize_text(item.get("execution_disposition")).lower() in dispositions
        ]
        return sorted(
            filtered,
            key=lambda item: (
                -int(item.get("priority") or 0),
                normalize_text(item.get("title")),
            ),
        )

    def summarize_item(item: dict[str, Any], posture: str) -> dict[str, Any]:
        disposition = normalize_text(item.get("execution_disposition")) or normalize_text(item.get("teacher_quality_classification"))
        return founder_item(
            item_id=normalize_text(item.get("improvement_id")),
            title=normalize_text(item.get("title")) or normalize_text(item.get("target_id")) or "Improvement item",
            raw_status=disposition,
            display_state=founder_display_state(disposition),
            reason=normalize_text(item.get("execution_disposition_reason"))
            or normalize_text(item.get("matched_teacher_title"))
            or first_sentence_summary(" ".join(normalize_string_list(item.get("rationale"), max_items=6, max_len=80))),
            source_path=normalize_text(governor.get("queue_path") or str(IMPROVEMENT_QUEUE_PATH)),
            risk_level=normalize_founder_risk_level(item.get("risk_level")),
            action_posture=posture,
            component=normalize_text(item.get("target_type")) or normalize_text(item.get("target_id")),
        )

    blocked_items = [summarize_item(item, "blocked") for item in sorted_items_for({"blocked"})[:5]]
    review_items = [summarize_item(item, "review_needed") for item in sorted_items_for({"approval_required", "suggest_only"})[:5]]
    safe_to_test_items = [summarize_item(item, "safe") for item in sorted_items_for({"safe_to_test"})[:5]]

    summary = {
        "timestamp_utc": normalize_text(governor.get("timestamp_utc") or budget.get("timestamp_utc")),
        "overall_status": normalize_text(governor.get("overall_status")).upper() or "UNKNOWN",
        "display_state": founder_display_state(governor.get("overall_status")),
        "active_improvement_total": int(governor.get("active_improvement_total") or 0),
        "teacher_calls_allowed": int(governor.get("total_teacher_allowed") or budget.get("total_allowed") or 0),
        "teacher_calls_blocked": int(governor.get("total_blocked_by_local_first") or budget.get("total_blocked_by_local_first") or 0),
        "teacher_calls_high_value_only": int(governor.get("total_teacher_high_value_only") or budget.get("total_high_value_only") or 0),
        "local_first_enforced": bool(policy.get("local_first_mandatory", True)),
        "safe_to_test_count": int(exec_counts.get("safe_to_test") or 0),
        "review_only_count": int(quality_counts.get("queue_for_review") or 0),
        "blocked_count": int(exec_counts.get("blocked") or 0),
        "approval_required_count": int(exec_counts.get("approval_required") or 0),
        "suggest_only_count": int(exec_counts.get("suggest_only") or 0),
        "teacher_response_reviews_total": int(governor.get("teacher_response_reviews_total") or len(normalize_list(decision_log.get("teacher_response_reviews")))),
        "budget_posture": normalize_short_text(governor.get("current_budget_posture") or budget.get("current_budget_posture"), max_len=32) or "guarded",
        "recommended_next_action": normalize_short_text(governor.get("recommended_next_action") or budget.get("recommended_next_action"), max_len=240),
        "blocked_items": blocked_items,
        "review_items": review_items,
        "safe_to_test_items": safe_to_test_items,
        "artifact_path": str(SELF_IMPROVEMENT_GOVERNOR_REPORT_PATH),
        "budget_path": str(TEACHER_CALL_BUDGET_REPORT_PATH),
        "decision_log_path": str(TEACHER_DECISION_LOG_REPORT_PATH),
        "policy_path": str(SELF_IMPROVEMENT_POLICY_PATH),
    }
    load_self_improvement_posture_summary._cache = {"ts": now_monotonic, "payload": summary}
    return summary


def build_founder_mode_payload(
    *,
    validation_data: dict[str, Any],
    system_validation_summary: dict[str, Any],
    approvals: dict[str, Any],
    approvals_items: list[dict[str, Any]],
    security_summary: dict[str, Any],
    tenant_safety_summary: dict[str, Any],
    billing_summary: dict[str, Any],
    mirror_summary: dict[str, Any],
    controls: dict[str, Any],
    live_rows: list[dict[str, Any]],
    live_docs: dict[str, Any],
) -> dict[str, Any]:
    host_summary = load_host_guardian_summary()
    environment_summary = load_environment_adaptation_summary()
    self_improvement_summary = load_self_improvement_posture_summary()
    sections = [item for item in normalize_list(validation_data.get("sections")) if isinstance(item, dict)]
    section_lookup = {
        normalize_text(item.get("section_name")).strip().lower(): item
        for item in sections
        if normalize_text(item.get("section_name"))
    }

    def section_item(section_name: str, title: str) -> dict[str, Any]:
        section = section_lookup.get(section_name.lower(), {})
        status = normalize_text(section.get("status")).upper() or "UNKNOWN"
        reason = normalize_text(section.get("recommended_next_action")) or normalize_text(section.get("failing_component")) or "No action required."
        return founder_item(
            title=title,
            raw_status=status,
            display_state=founder_display_state(status),
            reason=reason,
            source_path=normalize_text(section.get("relevant_log_or_artifact_path")) or system_validation_summary.get("path", ""),
            risk_level="R1",
            action_posture="safe" if founder_display_state(status) == "Healthy" else "review_needed",
            component=normalize_text(section.get("failing_component")),
        )

    stack_truth_items = [
        founder_item(
            title="Overall Validation",
            raw_status=system_validation_summary.get("overall_status"),
            display_state=founder_display_state(system_validation_summary.get("overall_status")),
            reason=f"{int(system_validation_summary.get('failed_count') or 0)} fail / {int(system_validation_summary.get('warn_count') or 0)} warn / {int(system_validation_summary.get('passed_count') or 0)} pass",
            source_path=system_validation_summary.get("path", ""),
            risk_level="R1",
            action_posture="safe" if normalize_text(system_validation_summary.get("overall_status")).upper() == "PASS" else "review_needed",
        ),
        section_item("stack/base", "Stack/Base"),
        section_item("athena", "Athena"),
        section_item("onyx", "Onyx"),
        founder_item(
            title="Mirror/Checkpoint",
            raw_status=(section_lookup.get("mirror/checkpoint state", {}) or {}).get("status") or ("PASS" if mirror_summary.get("ok") else "WARN"),
            display_state=founder_display_state((section_lookup.get("mirror/checkpoint state", {}) or {}).get("status") or ("PASS" if mirror_summary.get("ok") else "WARN")),
            reason=normalize_text((section_lookup.get("mirror/checkpoint state", {}) or {}).get("recommended_next_action"))
            or normalize_text(mirror_summary.get("next_action"))
            or "No action required.",
            source_path=normalize_text((section_lookup.get("mirror/checkpoint state", {}) or {}).get("relevant_log_or_artifact_path")) or str(MIRROR_UPDATE_LAST_PATH),
            risk_level="R1",
            action_posture="safe" if mirror_summary.get("ok") else "review_needed",
        ),
        founder_item(
            title="Host Guardian",
            raw_status=host_summary.get("overall_status"),
            display_state=host_summary.get("display_state"),
            reason=host_summary.get("recommended_next_action") or f"Throttle guidance is {host_summary.get('throttle_guidance') or 'normal'}.",
            source_path=host_summary.get("path", ""),
            risk_level="R1",
            action_posture="review_needed" if host_summary.get("display_state") == "Warning" else "safe",
        ),
        founder_item(
            title="Environment Adaptation",
            raw_status=(section_lookup.get("environment adaptation", {}) or {}).get("status") or environment_summary.get("drift_level"),
            display_state=founder_display_state((section_lookup.get("environment adaptation", {}) or {}).get("status") or environment_summary.get("drift_level")),
            reason=f"Host is {environment_summary.get('host_classification') or 'unknown'} with drift {environment_summary.get('drift_level') or 'unknown'}.",
            source_path=environment_summary.get("posture_path") or environment_summary.get("profile_path", ""),
            risk_level="R1",
            action_posture="safe",
        ),
        founder_item(
            title="Self-Improvement Governor",
            raw_status=self_improvement_summary.get("overall_status"),
            display_state=self_improvement_summary.get("display_state"),
            reason=self_improvement_summary.get("recommended_next_action") or "Governor posture available.",
            source_path=self_improvement_summary.get("artifact_path", ""),
            risk_level="R1",
            action_posture="review_needed" if self_improvement_summary.get("display_state") != "Healthy" else "safe",
        ),
    ]

    warnings: list[dict[str, Any]] = []
    blocked: list[dict[str, Any]] = []
    owner_actions: list[dict[str, Any]] = []
    safe_to_ignore: list[dict[str, Any]] = []

    if host_summary.get("pending_reboot"):
        warnings.append(
            founder_item(
                title="Pending Windows reboot",
                raw_status="pending_reboot",
                display_state="Warning",
                reason=host_summary.get("recommended_next_action") or "Host reports a pending reboot after extended uptime.",
                source_path=host_summary.get("path", ""),
                risk_level="R1",
                action_posture="review_needed",
                component="host",
            )
        )
    if normalize_text(host_summary.get("report_growth_status")).upper() == "WARN":
        warnings.append(
            founder_item(
                title="Report growth is elevated",
                raw_status="warn",
                display_state="Warning",
                reason=host_summary.get("report_growth_recommended_action") or "Reports and logs are growing faster than the comfort baseline.",
                source_path=host_summary.get("path", ""),
                risk_level="R1",
                action_posture="review_needed",
                component="reports",
            )
        )
    if normalize_text(security_summary.get("overall_status")).lower() not in {"", "guarded"}:
        warnings.append(
            founder_item(
                title="Security posture is watch",
                raw_status=security_summary.get("overall_status"),
                display_state=founder_display_state(security_summary.get("overall_status")),
                reason="Tenant isolation or governance warnings remain active and need review before expanding risk.",
                source_path=normalize_text(security_summary.get("artifact_path")),
                risk_level="R2",
                action_posture="review_needed",
                component="security",
            )
        )
    provider = billing_summary.get("provider") if isinstance(billing_summary.get("provider"), dict) else {}
    provider_mode = normalize_short_text(provider.get("mode"), max_len=24) or ("stub" if not billing_summary.get("provider_configured") else "live")
    if provider_mode == "stub" or not billing_summary.get("provider_configured"):
        warnings.append(
            founder_item(
                title="Billing provider remains stubbed",
                raw_status="stub",
                display_state="Warning",
                reason="Money actions stay approval-gated until external billing is configured for real use.",
                source_path=normalize_text(billing_summary.get("artifact_path")),
                risk_level="R2",
                action_posture="review_needed",
                component="billing",
            )
        )
    if self_improvement_summary.get("display_state") != "Healthy":
        warnings.append(
            founder_item(
                title="Self-improvement is review-gated",
                raw_status=self_improvement_summary.get("overall_status"),
                display_state=self_improvement_summary.get("display_state"),
                reason=self_improvement_summary.get("recommended_next_action"),
                source_path=self_improvement_summary.get("artifact_path", ""),
                risk_level="R1",
                action_posture="review_needed",
                component="self_improvement",
            )
        )

    if int(self_improvement_summary.get("blocked_count") or 0) > 0:
        blocked.append(
            founder_item(
                title="Blocked governed improvements",
                raw_status="blocked",
                display_state="Blocked",
                reason=f"{int(self_improvement_summary.get('blocked_count') or 0)} improvement items are blocked under current teacher and risk gates.",
                source_path=self_improvement_summary.get("artifact_path", ""),
                risk_level="R2",
                action_posture="blocked",
                component="self_improvement",
            )
        )
    if int(self_improvement_summary.get("teacher_calls_blocked") or 0) > 0:
        blocked.append(
            founder_item(
                title="Teacher calls blocked by local-first policy",
                raw_status="blocked_pending_human_review",
                display_state="Blocked",
                reason=f"{int(self_improvement_summary.get('teacher_calls_blocked') or 0)} teacher-worthy items were held locally instead of spending budget.",
                source_path=self_improvement_summary.get("budget_path", ""),
                risk_level="R1",
                action_posture="blocked",
                component="self_improvement",
            )
        )

    pending_approval_items = [
        item for item in approvals_items if normalize_text(item.get("status")).lower() == "pending"
    ]
    pending_approval_items = sorted(
        pending_approval_items,
        key=lambda item: (
            -founder_risk_sort_value(item.get("risk_level")),
            normalize_text(item.get("created_at")),
        ),
    )
    if int(approvals.get("pending_total") or 0) > 0:
        owner_actions.append(
            founder_item(
                title="Pending approvals need owner review",
                raw_status="review_only",
                display_state="Review Only",
                reason=f"{int(approvals.get('pending_total') or 0)} approvals are waiting in Athena.",
                source_path=normalize_text(approvals.get("path")),
                risk_level="R1",
                action_posture="review_needed",
                component="approvals",
            )
        )
    if int(tenant_safety_summary.get("issues_total") or 0) > 0:
        owner_actions.append(
            founder_item(
                title="Tenant safety warnings need review",
                raw_status=tenant_safety_summary.get("status"),
                display_state=founder_display_state(tenant_safety_summary.get("status")),
                reason=f"{int(tenant_safety_summary.get('issues_total') or 0)} tenant-safety issues are still open.",
                source_path=normalize_text(tenant_safety_summary.get("artifact_path")),
                risk_level="R2",
                action_posture="review_needed",
                component="tenant_safety",
            )
        )

    if provider_mode == "stub" or not billing_summary.get("provider_configured"):
        safe_to_ignore.append(
            founder_item(
                title="Billing stub is acceptable until launch",
                raw_status="stub",
                display_state="Warning",
                reason="You do not need to configure live billing until you are ready to take real money.",
                source_path=normalize_text(billing_summary.get("artifact_path")),
                risk_level="R1",
                action_posture="safe",
                component="billing",
            )
        )
    if not environment_summary.get("migration_detected"):
        safe_to_ignore.append(
            founder_item(
                title="No environment migration is in progress",
                raw_status="no_material_change",
                display_state="Healthy",
                reason="The current environment matches the known host posture, so no migration response is needed now.",
                source_path=environment_summary.get("drift_path", ""),
                risk_level="R1",
                action_posture="safe",
                component="environment",
            )
        )
    if int(self_improvement_summary.get("teacher_calls_blocked") or 0) > 0:
        safe_to_ignore.append(
            founder_item(
                title="Teacher spend is being held correctly",
                raw_status="guarded",
                display_state="Healthy",
                reason="Local-first is blocking weak or unnecessary teacher calls, which is protective rather than broken.",
                source_path=self_improvement_summary.get("budget_path", ""),
                risk_level="R1",
                action_posture="safe",
                component="self_improvement",
            )
        )

    safe_next_actions = [
        founder_item(
            title="Reboot later to clear the pending reboot flag",
            raw_status="warn" if host_summary.get("pending_reboot") else "pass",
            display_state="Warning" if host_summary.get("pending_reboot") else "Healthy",
            reason=host_summary.get("recommended_next_action") or "No reboot action required right now.",
            source_path=host_summary.get("path", ""),
            risk_level="R1",
            action_posture="review_needed" if host_summary.get("pending_reboot") else "safe",
            component="host",
        ),
        founder_item(
            title="Review tenant safety warnings",
            raw_status=tenant_safety_summary.get("status"),
            display_state=founder_display_state(tenant_safety_summary.get("status")),
            reason=f"{int(tenant_safety_summary.get('issues_total') or 0)} tenant-safety issues remain in the report.",
            source_path=normalize_text(tenant_safety_summary.get("artifact_path")),
            risk_level="R2",
            action_posture="review_needed",
            component="tenant_safety",
        ),
        founder_item(
            title="Configure billing only when ready for real money",
            raw_status="stub" if provider_mode == "stub" else "pass",
            display_state="Warning" if provider_mode == "stub" else "Healthy",
            reason="Billing is intentionally stubbed and money actions remain approval-gated until live secrets are configured.",
            source_path=normalize_text(billing_summary.get("artifact_path")),
            risk_level="R2",
            action_posture="review_needed" if provider_mode == "stub" else "safe",
            component="billing",
        ),
        founder_item(
            title="Run safe maintenance only if report growth keeps climbing",
            raw_status=host_summary.get("report_growth_status") or "pass",
            display_state="Warning" if normalize_text(host_summary.get("report_growth_status")).upper() == "WARN" else "Healthy",
            reason=host_summary.get("report_growth_recommended_action") or "Report growth is within baseline.",
            source_path=host_summary.get("path", ""),
            risk_level="R1",
            action_posture="safe",
            component="reports",
        ),
        founder_item(
            title="Continue governed chunk execution with lightweight posture",
            raw_status=environment_summary.get("heavy_jobs_posture") or "guarded",
            display_state="Healthy",
            reason=f"Heavy-job posture is {environment_summary.get('heavy_jobs_posture') or 'unknown'} and throttle guidance is {environment_summary.get('throttle_guidance') or 'normal'}.",
            source_path=environment_summary.get("posture_path", ""),
            risk_level="R1",
            action_posture="safe",
            component="environment",
        ),
        founder_item(
            title="Review blocked teacher-backed items before spending budget",
            raw_status=self_improvement_summary.get("overall_status"),
            display_state=self_improvement_summary.get("display_state"),
            reason=self_improvement_summary.get("recommended_next_action") or "Teacher-backed work remains governed.",
            source_path=self_improvement_summary.get("artifact_path", ""),
            risk_level="R1",
            action_posture="review_needed",
            component="self_improvement",
        ),
    ]

    pending_items = [
        founder_item(
            item_id=normalize_text(item.get("id")),
            title=normalize_text(item.get("title")) or normalize_text(item.get("component_id")) or "Pending approval",
            raw_status=normalize_text(item.get("status")) or "pending",
            display_state="Review Only",
            reason=f"{component_label(normalize_text(item.get('component_id')))} / {normalize_text(item.get('source') or item.get('kind') or 'manual')}",
            source_path=normalize_text(((item.get("evidence_files")[0] if isinstance(item.get("evidence_files"), list) and item.get("evidence_files") else item.get("evidence_files")))),
            risk_level=normalize_founder_risk_level(item.get("risk_level")),
            action_posture="review_needed",
            component=normalize_text(item.get("component_id")),
        )
        for item in pending_approval_items[:5]
    ]

    actionable_approvals = []
    for row in approvals.get("actionable_items", []):
        if not isinstance(row, dict):
            continue
        actionable_approvals.append(
            {
                **row,
                "display_state": founder_display_state(row.get("status")),
                "approve_action": {"api_path": "/api/approvals/decision", "decision": "approve"},
                "reject_action": {"api_path": "/api/approvals/decision", "decision": "reject"},
            }
        )

    quick_actions: list[dict[str, Any]] = []
    for action_id in ("verify", "mirror", "onyx_restart", "onyx_smoketest", "freeze", "unfreeze", "doctor"):
        control = controls.get(action_id) if isinstance(controls, dict) else None
        if not isinstance(control, dict):
            continue
        requires_signed_session = action_id in {"freeze", "unfreeze", "doctor"}
        quick_actions.append(
            {
                "action_id": action_id,
                "action_type": "control",
                "label": normalize_text(control.get("label")) or action_id.replace("_", " ").title(),
                "description": normalize_text(control.get("message")) or "Athena control action.",
                "status": normalize_text(control.get("result_status") or control.get("status")) or "UNKNOWN",
                "display_state": founder_display_state(control.get("result_status") or control.get("status")),
                "api_path": normalize_text(control.get("api_path")),
                "command": normalize_text(control.get("command_run") or control.get("command")),
                "requires_signed_session": requires_signed_session,
                "manual_supported": bool(normalize_text(control.get("command_run") or control.get("command"))),
                "disabled_reason": "Requires a signed Athena session." if requires_signed_session else "",
            }
        )
    quick_actions.extend(
        [
            {
                "action_id": "founder_refresh",
                "action_type": "refresh",
                "label": "Refresh Founder View",
                "description": "Reload the live founder cockpit without leaving the page.",
                "display_state": "Healthy",
                "requires_signed_session": False,
                "manual_supported": True,
                "disabled_reason": "",
            },
            {
                "action_id": "open_onyx",
                "action_type": "open_url",
                "label": "Open Onyx",
                "description": "Open the Onyx business app on loopback.",
                "url": "http://127.0.0.1:5353/",
                "display_state": "Healthy",
                "requires_signed_session": False,
                "manual_supported": True,
                "disabled_reason": "",
            },
            {
                "action_id": "open_docs",
                "action_type": "view",
                "label": "Open Live Docs",
                "description": "Jump straight into the generated manuals tab.",
                "view": "docs",
                "display_state": "Healthy",
                "requires_signed_session": False,
                "manual_supported": True,
                "disabled_reason": "",
            },
        ]
    )

    docs_components = {
        normalize_text(item.get("component_id")).lower(): item
        for item in normalize_list(live_docs.get("components"))
        if isinstance(item, dict) and normalize_text(item.get("component_id"))
    }
    component_cards = []
    for row in live_rows:
        if not isinstance(row, dict):
            continue
        component_id = normalize_component_id(row.get("component_id"))
        status_value = "PASS" if bool(row.get("listening")) and bool(row.get("health_ready")) else ("WARN" if bool(row.get("listening")) else "FAIL")
        docs_id = component_id if component_id in {"athena", "onyx"} else "mason"
        docs_component = docs_components.get(docs_id, {})
        actions = [
            {"action_id": "open_docs", "action_type": "view_docs", "label": "View docs", "component_id": docs_id},
        ]
        if component_id == "athena":
            actions.append({"action_id": "open_athena", "action_type": "open_url", "label": "Open Athena", "url": "http://127.0.0.1:8000/athena/"})
        if component_id == "onyx":
            actions.append({"action_id": "open_onyx", "action_type": "open_url", "label": "Open Onyx", "url": "http://127.0.0.1:5353/"})
            if isinstance(controls.get("onyx_restart"), dict):
                actions.append({"action_id": "onyx_restart", "action_type": "control", "label": "Restart Onyx"})
            if isinstance(controls.get("onyx_smoketest"), dict):
                actions.append({"action_id": "onyx_smoketest", "action_type": "control", "label": "Smoke test"})
        component_cards.append(
            {
                "component_id": component_id,
                "label": component_label(component_id),
                "display_state": founder_display_state(status_value),
                "status_summary": normalize_text(row.get("health_error"))
                or ("Listening and healthy." if bool(row.get("health_ready")) else f"Health probe returned {int(row.get('health_status_code') or 0)}."),
                "port": int(row.get("port") or 0),
                "listener_count": int(row.get("listener_count") or 0),
                "health_url": normalize_text(row.get("health_url")),
                "docs_component_id": docs_id,
                "docs_available": bool(docs_component),
                "actions": actions,
            }
        )

    summary_line = (
        f"Validator is {system_validation_summary.get('overall_status') or 'UNKNOWN'} with "
        f"{int(system_validation_summary.get('failed_count') or 0)} fails, "
        f"{len(warnings)} active warnings, and {len(blocked)} blocked governance items."
    )

    return {
        "owner_only": True,
        "generated_at_utc": utc_now_iso(),
        "summary_line": summary_line,
        "stack_truth_summary": {
            "items": stack_truth_items,
            "validation_path": system_validation_summary.get("path", ""),
        },
        "attention_queue": {
            "warnings": warnings[:6],
            "blocked": blocked[:6],
            "owner_actions": owner_actions[:6],
            "safe_to_ignore": safe_to_ignore[:6],
        },
        "safe_next_actions": safe_next_actions[:6],
        "self_improvement_posture": self_improvement_summary,
        "approvals_governed_actions": {
            "pending_total": int(approvals.get("pending_total") or 0),
            "eligible_total": int(approvals.get("eligible_total") or 0),
            "quarantine_total": int(approvals.get("quarantine_total") or 0),
            "approval_required_total": int(self_improvement_summary.get("approval_required_count") or 0),
            "blocked_total": int(self_improvement_summary.get("blocked_count") or 0),
            "review_only_total": int(self_improvement_summary.get("review_only_count") or 0),
            "safe_to_test_total": int(self_improvement_summary.get("safe_to_test_count") or 0),
            "pending_items": pending_items,
            "blocked_items": self_improvement_summary.get("blocked_items", []),
            "review_items": self_improvement_summary.get("review_items", []),
            "safe_to_test_items": self_improvement_summary.get("safe_to_test_items", []),
            "actionable_items": actionable_approvals[:8],
            "path": normalize_text(approvals.get("path")),
            "history_path": normalize_text(approvals.get("history_path")),
            "quarantine_path": normalize_text(approvals.get("quarantine_path")),
        },
        "quick_actions": quick_actions,
        "component_cards": component_cards,
        "runtime_environment_host_posture": {
            "host_classification": environment_summary.get("host_classification") or "unknown",
            "throttle_guidance": environment_summary.get("throttle_guidance") or host_summary.get("throttle_guidance") or "normal",
            "learning_posture": environment_summary.get("learning_posture") or "unknown",
            "heavy_jobs_posture": environment_summary.get("heavy_jobs_posture") or "unknown",
            "monitoring_posture": environment_summary.get("monitoring_posture") or "unknown",
            "cleanup_posture": environment_summary.get("cleanup_posture") or "unknown",
            "loopback_network_posture": "loopback_only" if int(security_summary.get("non_loopback_bindings_total") or 0) == 0 else "review_bindings",
            "current_environment_id": environment_summary.get("environment_id") or "unknown",
            "drift_level": environment_summary.get("drift_level") or "unknown",
            "migration_detected": bool(environment_summary.get("migration_detected")),
            "disk_free_percent": host_summary.get("disk_free_percent"),
            "host_status": host_summary.get("overall_status") or "UNKNOWN",
            "recommended_next_action": host_summary.get("recommended_next_action") or environment_summary.get("recommended_next_action") or "No action required.",
            "host_path": host_summary.get("path", ""),
            "environment_profile_path": environment_summary.get("profile_path", ""),
            "environment_drift_path": environment_summary.get("drift_path", ""),
            "runtime_posture_path": environment_summary.get("posture_path", ""),
        },
        "source_paths": normalize_string_list(
            [
                system_validation_summary.get("path"),
                host_summary.get("path"),
                environment_summary.get("profile_path"),
                environment_summary.get("drift_path"),
                environment_summary.get("posture_path"),
                self_improvement_summary.get("artifact_path"),
                self_improvement_summary.get("budget_path"),
                normalize_text(approvals.get("path")),
                normalize_text(security_summary.get("artifact_path")),
                normalize_text(tenant_safety_summary.get("artifact_path")),
                normalize_text(billing_summary.get("artifact_path")),
                str(MIRROR_UPDATE_LAST_PATH),
            ],
            max_items=16,
            max_len=220,
        ),
    }


def build_last_failure_summary(last_failure_data: dict[str, Any] | None) -> dict[str, Any]:
    if not isinstance(last_failure_data, dict):
        return {"status": "NONE", "failure_count": 0, "component": "", "reason": ""}
    failures = [item for item in normalize_list(last_failure_data.get("failures")) if isinstance(item, dict)]
    first = failures[0] if failures else {}
    return {"status": "FAILED" if failures else "EMPTY", "generated_at_utc": normalize_text(last_failure_data.get("generated_at_utc")), "run_id": normalize_text(last_failure_data.get("run_id")), "failure_count": int(last_failure_data.get("failure_count") or len(failures)), "component": normalize_component_id(first.get("component")), "reason": normalize_text(first.get("probe_error") or first.get("stderr_tail_200") or first.get("stdout_tail_200") or first.get("readiness_name")), "commandline": normalize_text(first.get("commandline")), "stderr_log": normalize_text(first.get("stderr_log")), "stdout_log": normalize_text(first.get("stdout_log"))}


def normalize_repo_path_text(value: Any) -> str:
    text = str(value or "").strip()
    if not text:
        return ""
    resolved = resolve_artifact_path_in_repo(text)
    if resolved:
        return str(resolved)
    try:
        candidate = Path(text)
        if candidate.is_absolute():
            return str(candidate)
    except Exception:
        return text
    return text


def normalize_verify_status(value: Any) -> str:
    raw = normalize_text(value).upper()
    if raw in {"OK", "SUCCESS", "DONE"}:
        return "PASS"
    if raw in {"PASS", "WARN", "FAIL", "UNKNOWN", "RUNNING"}:
        return raw
    return raw or "UNKNOWN"


def default_verify_result(command_run: str = "") -> dict[str, Any]:
    return {
        "timestamp_utc": "",
        "ok": False,
        "status": "UNKNOWN",
        "failing_component": "",
        "failing_component_id": "",
        "failing_log_path": "",
        "recommended_next_action": "",
        "raw_report_path": "",
        "command_run": command_run or build_verify_command_string(),
    }


def load_verify_result() -> dict[str, Any]:
    result = default_verify_result()
    data = read_json(VERIFY_LAST_PATH, default=None)
    if not isinstance(data, dict):
        return result
    result.update(
        {
            "timestamp_utc": normalize_text(data.get("timestamp_utc")),
            "ok": bool(data.get("ok", False)),
            "status": normalize_verify_status(data.get("status")),
            "failing_component": normalize_text(data.get("failing_component")),
            "failing_component_id": normalize_component_id(data.get("failing_component_id")),
            "failing_log_path": normalize_repo_path_text(data.get("failing_log_path")),
            "recommended_next_action": normalize_text(data.get("recommended_next_action")),
            "raw_report_path": normalize_repo_path_text(data.get("raw_report_path")),
            "command_run": normalize_text(data.get("command_run")) or build_verify_command_string(),
        }
    )
    result["ok"] = result["status"] == "PASS"
    return result


def describe_verify_check(check: dict[str, Any]) -> dict[str, str]:
    name = normalize_text(check.get("name")).lower()
    component_id = ""
    component_text = name.replace("_", " ").title() or "Unknown"
    if name.startswith("listener_"):
        component_id = normalize_component_id(name.replace("listener_", "", 1))
        component_text = component_label(component_id)
    elif name.startswith("endpoint_"):
        component_name = name.replace("endpoint_", "", 1)
        for suffix in ("_health", "_smoke", "_main_dart_js"):
            if component_name.endswith(suffix):
                component_name = component_name[: -len(suffix)]
                break
        component_id = normalize_component_id(component_name)
        component_text = component_label(component_id)
    elif name == "scheduled_tasks":
        component_id = "launcher"
        component_text = "Scheduled Tasks"
    elif name == "onyx_launcher":
        component_id = "onyx"
        component_text = "Onyx"
    elif name == "ports_contract":
        component_text = "Ports Contract"
    elif name == "mirror_status":
        component_text = "Mirror Status"
    elif name == "ingest_status":
        component_text = "Ingest Status"
    elif name == "approvals_posture":
        component_text = "Approvals Posture"
    elif name == "pending_llm_queue":
        component_text = "Pending LLM Queue"
    elif name == "currency_cad_audit":
        component_text = "Currency CAD Audit"
    return {"component_id": component_id, "component_label": component_text}


def select_verify_issue(checks: list[dict[str, Any]]) -> dict[str, Any] | None:
    for severity in ("FAIL", "WARN"):
        for check in checks:
            if normalize_verify_status(check.get("status")) != severity:
                continue
            data = check.get("data") if isinstance(check.get("data"), dict) else {}
            description = describe_verify_check(check)
            return {
                "name": normalize_text(check.get("name")).lower(),
                "status": severity,
                "detail": normalize_text(check.get("detail")),
                "data": data,
                **description,
            }
    return None


def pick_verify_issue_log_path(
    issue: dict[str, Any],
    *,
    start_run_data: dict[str, Any],
    last_failure_data: dict[str, Any] | None,
    raw_report_path: str,
) -> str:
    data = issue.get("data") if isinstance(issue.get("data"), dict) else {}
    direct_candidates = [
        data.get("stderr_log"),
        data.get("stdout_log"),
        data.get("log_path"),
    ]
    component_id = normalize_component_id(issue.get("component_id"))
    if component_id:
        exact_component_log = find_latest_exact_component_stderr_log(component_id)
        if exact_component_log:
            direct_candidates.insert(0, exact_component_log)
        logs = resolve_log_paths_for_component(component_id, start_run_data, last_failure_data)
        direct_candidates.extend(
            [
                logs.get("stderr_log"),
                logs.get("stdout_log"),
                logs.get("log_path"),
            ]
        )
    direct_candidates.extend(
        [
            data.get("path"),
            data.get("posture_path"),
            data.get("start_run_report"),
            data.get("mirror_delta_path"),
            data.get("mirror_manifest_path"),
            data.get("currency_policy_path"),
            data.get("budget_state_path"),
            raw_report_path,
        ]
    )
    for candidate in direct_candidates:
        path_text = normalize_repo_path_text(candidate)
        if path_text:
            return path_text
    return ""


def build_verify_issue_next_action(issue: dict[str, Any], *, failing_log_path: str, raw_report_path: str) -> str:
    data = issue.get("data") if isinstance(issue.get("data"), dict) else {}
    hint = normalize_text(data.get("remediation_hint"))
    if hint:
        return hint
    name = normalize_text(issue.get("name")).lower()
    detail = normalize_text(issue.get("detail"))
    fallback_by_name = {
        "ports_contract": "Restore config/ports.json and rerun Verify Stack.",
        "scheduled_tasks": "Create or repair the missing Mason2 scheduled tasks and rerun Verify Stack.",
        "mirror_status": "Generate the mirror status files under docs and rerun Verify Stack.",
        "ingest_status": "Refresh reports/ingest_autopilot_status.json and rerun Verify Stack.",
        "approvals_posture": "Refresh reports/approvals_posture.json and rerun Verify Stack.",
        "onyx_launcher": "Restore the Onyx launcher script and rerun Verify Stack.",
        "currency_cad_audit": detail or "Run WO-CURRENCY-CAD-0001 and rerun Verify Stack.",
    }
    if name in fallback_by_name:
        return fallback_by_name[name]
    if failing_log_path:
        return f"Inspect {failing_log_path} and rerun Verify Stack."
    if detail:
        return detail if detail.endswith(".") else f"{detail}."
    if raw_report_path:
        return f"Inspect {raw_report_path} and rerun Verify Stack."
    return "Rerun Verify Stack and inspect the latest report."


def build_authoritative_verify_result(raw_report: dict[str, Any], command_run: str) -> dict[str, Any]:
    result = default_verify_result(command_run=command_run)
    if not isinstance(raw_report, dict):
        return result
    result["timestamp_utc"] = normalize_text(raw_report.get("generated_at_utc")) or utc_now_iso()
    result["raw_report_path"] = normalize_repo_path_text(raw_report.get("report_path")) or str(E2E_VERIFY_REPORT_PATH)

    status = normalize_verify_status(raw_report.get("overall_status") or raw_report.get("overall_result"))
    if status == "UNKNOWN":
        summary = raw_report.get("summary") if isinstance(raw_report.get("summary"), dict) else {}
        if int(summary.get("fail_count") or 0) > 0:
            status = "FAIL"
        elif int(summary.get("warn_count") or 0) > 0:
            status = "WARN"
        elif int(summary.get("pass_count") or 0) > 0:
            status = "PASS"
    result["status"] = status
    result["ok"] = status == "PASS"

    checks = [item for item in normalize_list(raw_report.get("checks")) if isinstance(item, dict)]
    issue = select_verify_issue(checks)
    if not issue:
        result["recommended_next_action"] = "No action required." if status == "PASS" else "Inspect the raw verify report and rerun Verify Stack."
        return result

    start_run_data = read_json(START_RUN_LAST_PATH, default={})
    start_run_data = start_run_data if isinstance(start_run_data, dict) else {}
    last_failure_data = read_json(LAST_FAILURE_PATH, default=None)
    last_failure_data = last_failure_data if isinstance(last_failure_data, dict) else None
    failing_log_path = pick_verify_issue_log_path(
        issue,
        start_run_data=start_run_data,
        last_failure_data=last_failure_data,
        raw_report_path=result["raw_report_path"],
    )

    result.update(
        {
            "failing_component": normalize_text(issue.get("component_label")),
            "failing_component_id": normalize_component_id(issue.get("component_id")),
            "failing_log_path": failing_log_path,
            "recommended_next_action": build_verify_issue_next_action(
                issue,
                failing_log_path=failing_log_path,
                raw_report_path=result["raw_report_path"],
            ),
        }
    )
    return result


def build_verify_summary(e2e_data: dict[str, Any]) -> dict[str, Any]:
    if not isinstance(e2e_data, dict):
        return {"status": "UNKNOWN", "generated_at_utc": "", "fail_count": 0, "warn_count": 0, "pass_count": 0, "first_issue": None}
    summary = e2e_data.get("summary") if isinstance(e2e_data.get("summary"), dict) else {}
    checks = [item for item in normalize_list(e2e_data.get("checks")) if isinstance(item, dict)]
    first_issue = None
    for check in checks:
        check_status = normalize_text(check.get("status")).upper()
        if check_status not in {"WARN", "FAIL"}:
            continue
        name = normalize_text(check.get("name"))
        component_id = "launcher"
        if name.startswith("listener_"):
            component_id = normalize_component_id(name.replace("listener_", "", 1))
        elif name.startswith("endpoint_"):
            component_id = normalize_component_id(name.replace("endpoint_", "", 1).replace("_health", "").replace("_smoke", ""))
        data = check.get("data") if isinstance(check.get("data"), dict) else {}
        first_issue = {"name": name, "status": check_status, "detail": normalize_text(check.get("detail")), "component_id": component_id, "hint": normalize_text(data.get("remediation_hint"))}
        break
    return {"status": normalize_text(e2e_data.get("overall_status") or e2e_data.get("overall_result")).upper() or "UNKNOWN", "generated_at_utc": normalize_text(e2e_data.get("generated_at_utc")), "fail_count": int(summary.get("fail_count") or 0), "warn_count": int(summary.get("warn_count") or 0), "pass_count": int(summary.get("pass_count") or 0), "first_issue": first_issue}


def find_last_successful_start_run(current_start_run_data: dict[str, Any]) -> dict[str, Any] | None:
    current_status = normalize_text(current_start_run_data.get("overall_status")).upper()
    if current_status in {"PASS", "OK"}:
        return {"run_id": normalize_text(current_start_run_data.get("run_id")), "status": current_status, "generated_at_utc": normalize_text(current_start_run_data.get("generated_at_utc")), "path": str(START_RUN_LAST_PATH)}
    start_dir = START_RUN_LAST_PATH.parent
    if not start_dir.exists():
        return None
    for run_path in sorted(start_dir.glob("start_run_*.json"), key=lambda item: item.stat().st_mtime, reverse=True):
        data = read_json(run_path, default={})
        if not isinstance(data, dict):
            continue
        status = normalize_text(data.get("overall_status")).upper()
        if status in {"PASS", "OK"}:
            return {"run_id": normalize_text(data.get("run_id")), "status": status, "generated_at_utc": normalize_text(data.get("generated_at_utc")), "path": str(run_path)}
    return None


def get_control_action_specs() -> dict[str, dict[str, Any]]:
    return {
        "start": {"label": "Start Stack", "api_path": "/api/control/stack/start", "command": "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\\Start_Mason2.ps1 -FullStack"},
        "stop": {"label": "Stop Stack", "api_path": "/api/control/stack/stop", "command": "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\\Stop_Stack.ps1"},
        "verify": {"label": "Verify Stack", "api_path": "/api/control/verify_stack", "command": build_verify_command_string()},
        "mirror": {"label": "Mirror Update", "api_path": "/api/control/mirror/run", "command": f'powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\\tools\\sync\\Mason_Mirror_Update.ps1 -RootPath "{str(BASE)}" -Reason manual'},
        "onyx_restart": {"label": "Restart Onyx", "api_path": "/api/control/onyx/restart", "command": 'powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File ".\\Component - Onyx App\\onyx_business_manager\\Restart-Onyx5353.ps1"'},
        "onyx_smoketest": {"label": "Run Onyx Smoke Test", "api_path": "/api/control/onyx/smoketest", "command": "powershell -NoLogo -NoProfile -Command \"Invoke-WebRequest -UseBasicParsing http://127.0.0.1:5353/main.dart.js | Out-Null\""},
        "freeze": {"label": "Freeze Changes", "api_path": "/api/control/freeze", "command": ""},
        "unfreeze": {"label": "Unfreeze Changes", "api_path": "/api/control/unfreeze", "command": ""},
        "doctor": {"label": "Run Doctor", "api_path": "/api/control/doctor/run", "command": ""},
    }


def control_state_from_result_status(result_status: Any) -> str:
    value = normalize_text(result_status).upper()
    if not value or value == "UNKNOWN":
        return "idle"
    if value == "WARN":
        return "warn"
    return "success" if value in {"PASS", "OK", "DONE", "SUCCESS"} else "fail"


def build_stack_status_payload() -> dict[str, Any]:
    ports = resolve_stack_ports()
    ordered_names = ["mason_api", "seed_api", "bridge", "athena", "onyx"]
    port_numbers = [int(ports[name]) for name in ordered_names]
    listeners_by_port = netstat_listener_map(port_numbers)

    probes = [
        {"name": "mason_api_health", **probe_http_ready(f"http://127.0.0.1:{ports['mason_api']}/health")},
        {"name": "seed_api_health", **probe_http_ready(f"http://127.0.0.1:{ports['seed_api']}/health")},
        {"name": "bridge_health", **probe_http_ready(f"http://127.0.0.1:{ports['bridge']}/health")},
        {"name": "athena_health", **probe_http_ready(f"http://127.0.0.1:{ports['athena']}/api/health")},
        {"name": "onyx_main_dart_js", **probe_http_ready(f"http://127.0.0.1:{ports['onyx']}/main.dart.js")},
    ]
    probe_by_component = {
        "mason_api": probes[0],
        "seed_api": probes[1],
        "bridge": probes[2],
        "athena": probes[3],
        "onyx": probes[4],
    }

    listener_rows: list[dict[str, Any]] = []
    live_rows: list[dict[str, Any]] = []
    for name in ordered_names:
        port = int(ports[name])
        listeners = listeners_by_port.get(port, [])
        listener_row = {
            "name": name,
            "port": port,
            "listening": len(listeners) > 0,
            "listener_count": len(listeners),
            "listeners": listeners,
        }
        listener_rows.append(listener_row)
        probe = probe_by_component.get(name, {})
        live_rows.append(
            {
                "component_id": name,
                "label": component_label(name),
                "port": port,
                "listening": listener_row["listening"],
                "listener_count": listener_row["listener_count"],
                "listeners": listeners,
                "health_ready": bool(probe.get("ready")),
                "health_status_code": int(probe.get("status_code") or 0),
                "health_error": normalize_text(probe.get("error")),
                "health_url": normalize_text(probe.get("url")),
                "checked_at_utc": normalize_text(probe.get("checked_at_utc") or probe.get("checked_at")),
            }
        )

    all_ready = all(bool(item.get("ready")) for item in probes)
    any_ready = any(bool(item.get("ready")) for item in probes)

    start_run_data = read_json(START_RUN_LAST_PATH, default={})
    start_run_data = start_run_data if isinstance(start_run_data, dict) else {}
    start_summary = build_start_run_summary(start_run_data)

    mirror_data = read_json(MIRROR_UPDATE_LAST_PATH, default={})
    mirror_data = mirror_data if isinstance(mirror_data, dict) else {}
    mirror_summary = build_mirror_summary(mirror_data)
    validation_data = read_json(SYSTEM_VALIDATION_LAST_PATH, default={})
    validation_data = validation_data if isinstance(validation_data, dict) else {}
    system_validation_summary = build_system_validation_summary(validation_data)

    last_failure_data = read_json(LAST_FAILURE_PATH, default=None)
    last_failure_data = last_failure_data if isinstance(last_failure_data, dict) else None
    last_failure_summary = build_last_failure_summary(last_failure_data)

    verify_result = load_verify_result()
    verify_runtime = get_verify_runtime_state()
    verify_running = bool(verify_runtime.get("running"))

    start_status_raw = normalize_text(start_summary.get("status")).upper() or "UNKNOWN"
    if all_ready and start_status_raw in {"PASS", "OK"}:
        overall_status = "GREEN"
        overall_severity = "green"
    elif all_ready or any_ready:
        overall_status = "YELLOW"
        overall_severity = "yellow"
    else:
        overall_status = "RED"
        overall_severity = "red"

    specs = get_control_action_specs()
    start_logs = resolve_log_paths_for_component("core", start_run_data, last_failure_data)
    latest_stop_log = latest_path_by_patterns(BASE / "logs", ["stop_stack_*.txt"])
    stop_finished = ""
    if latest_stop_log:
        try:
            stop_finished = datetime.fromtimestamp(latest_stop_log.stat().st_mtime, tz=timezone.utc).isoformat().replace("+00:00", "Z")
        except Exception:
            stop_finished = ""
    verify_log_path = (
        verify_result.get("failing_log_path")
        or verify_result.get("raw_report_path")
        or str(VERIFY_LAST_PATH)
    )
    verify_message = "No authoritative verify result yet. Run Verify Stack to write reports/verify_last.json."
    if verify_running:
        verify_message = "Fresh verify is running. Athena will update this card when the command finishes."
    elif verify_result.get("timestamp_utc"):
        verify_message = f"{verify_result.get('status') or 'UNKNOWN'} result from reports/verify_last.json."

    controls = {
        "start": {
            "action_id": "start",
            "label": specs["start"]["label"],
            "api_path": specs["start"]["api_path"],
            "status": control_state_from_result_status(start_summary.get("status")),
            "command": specs["start"]["command"],
            "log_path": start_logs.get("log_path") or str(START_RUN_LAST_PATH),
            "result_path": str(START_RUN_LAST_PATH),
            "last_finished_at_utc": start_summary.get("generated_at_utc") or "",
            "result_status": start_summary.get("status") or "",
            "message": f"{start_summary.get('status') or 'UNKNOWN'} run {start_summary.get('run_id') or 'n/a'} with {start_summary.get('ready_count', 0)}/{start_summary.get('required_count', 0)} required checks ready.",
        },
        "stop": {
            "action_id": "stop",
            "label": specs["stop"]["label"],
            "api_path": specs["stop"]["api_path"],
            "status": "success" if latest_stop_log else "idle",
            "command": specs["stop"]["command"],
            "log_path": str(latest_stop_log) if latest_stop_log else "",
            "result_path": str(latest_stop_log) if latest_stop_log else "",
            "last_finished_at_utc": stop_finished,
            "result_status": "PASS" if latest_stop_log else "",
            "message": "Last stop transcript captured." if latest_stop_log else "No stop transcript found yet.",
        },
        "verify": {
            "action_id": "verify",
            "label": specs["verify"]["label"],
            "api_path": specs["verify"]["api_path"],
            "status": "running" if verify_running else control_state_from_result_status(verify_result.get("status")),
            "command": specs["verify"]["command"],
            "log_path": str(verify_log_path) if verify_log_path else str(VERIFY_LAST_PATH),
            "result_path": str(VERIFY_LAST_PATH),
            "last_finished_at_utc": "" if verify_running else (verify_result.get("timestamp_utc") or ""),
            "result_status": verify_result.get("status") or "",
            "message": verify_message,
            "failing_component": verify_result.get("failing_component") or "",
            "failing_log_path": verify_result.get("failing_log_path") or "",
            "recommended_next_action": verify_result.get("recommended_next_action") or "",
            "raw_report_path": verify_result.get("raw_report_path") or "",
            "command_run": verify_result.get("command_run") or specs["verify"]["command"],
        },
        "mirror": {
            "action_id": "mirror",
            "label": specs["mirror"]["label"],
            "api_path": specs["mirror"]["api_path"],
            "status": control_state_from_result_status("PASS" if mirror_summary.get("ok") else ("FAIL" if mirror_data else "")),
            "command": specs["mirror"]["command"],
            "log_path": str(MIRROR_UPDATE_LAST_PATH),
            "result_path": str(MIRROR_UPDATE_LAST_PATH),
            "last_finished_at_utc": mirror_summary.get("timestamp_utc") or "",
            "result_status": "PASS" if mirror_summary.get("ok") else ("FAIL" if mirror_data else ""),
            "message": f"phase={mirror_summary.get('phase') or 'n/a'} push={mirror_summary.get('mirror_push') or 'n/a'}",
        },
        "onyx_restart": {
            "action_id": "onyx_restart",
            "label": specs["onyx_restart"]["label"],
            "api_path": specs["onyx_restart"]["api_path"],
            "status": "success" if bool(probe_by_component["onyx"].get("ready")) else "warn",
            "command": specs["onyx_restart"]["command"],
            "log_path": str(BASE / "Component - Onyx App" / "onyx_business_manager" / "Restart-Onyx5353.ps1"),
            "result_path": str(BASE / "Component - Onyx App" / "onyx_business_manager" / "Restart-Onyx5353.ps1"),
            "last_finished_at_utc": "",
            "result_status": "READY" if bool(probe_by_component["onyx"].get("ready")) else "WARN",
            "message": "Restart the loopback Onyx app on port 5353.",
        },
        "onyx_smoketest": {
            "action_id": "onyx_smoketest",
            "label": specs["onyx_smoketest"]["label"],
            "api_path": specs["onyx_smoketest"]["api_path"],
            "status": "success" if bool(probe_by_component["onyx"].get("ready")) else "warn",
            "command": specs["onyx_smoketest"]["command"],
            "log_path": normalize_text(probe_by_component["onyx"].get("url")),
            "result_path": normalize_text(probe_by_component["onyx"].get("url")),
            "last_finished_at_utc": normalize_text(probe_by_component["onyx"].get("checked_at_utc")),
            "result_status": "PASS" if bool(probe_by_component["onyx"].get("ready")) else "WARN",
            "message": "Confirm the Onyx app responds on its main Dart asset route.",
        },
        "freeze": {
            "action_id": "freeze",
            "label": specs["freeze"]["label"],
            "api_path": specs["freeze"]["api_path"],
            "status": "warn" if KILLSWITCH_PATH.exists() else "idle",
            "command": specs["freeze"]["command"],
            "log_path": str(KILLSWITCH_PATH),
            "result_path": str(KILLSWITCH_PATH),
            "last_finished_at_utc": "",
            "result_status": "ON" if KILLSWITCH_PATH.exists() else "OFF",
            "message": "Freeze autonomous changes without widening exposure or touching customer data.",
        },
        "unfreeze": {
            "action_id": "unfreeze",
            "label": specs["unfreeze"]["label"],
            "api_path": specs["unfreeze"]["api_path"],
            "status": "success" if not KILLSWITCH_PATH.exists() else "warn",
            "command": specs["unfreeze"]["command"],
            "log_path": str(KILLSWITCH_PATH),
            "result_path": str(KILLSWITCH_PATH),
            "last_finished_at_utc": "",
            "result_status": "OFF" if not KILLSWITCH_PATH.exists() else "ON",
            "message": "Unfreeze governed changes after review when the stack is ready.",
        },
        "doctor": {
            "action_id": "doctor",
            "label": specs["doctor"]["label"],
            "api_path": specs["doctor"]["api_path"],
            "status": "idle",
            "command": specs["doctor"]["command"],
            "log_path": str(BASE / "tools" / "Mason_Doctor.ps1"),
            "result_path": str(BASE / "tools" / "Mason_Doctor.ps1"),
            "last_finished_at_utc": "",
            "result_status": "",
            "message": "Run the governed doctor path for a deeper stack check.",
        },
    }

    most_relevant_failure = {"component_id": "", "component_label": "No failing component", "why": "All required stack checks are currently passing.", "log_path": "", "source": "current_state"}
    for row in live_rows:
        if not row["listening"]:
            logs = resolve_log_paths_for_component(row["component_id"], start_run_data, last_failure_data)
            most_relevant_failure = {"component_id": row["component_id"], "component_label": row["label"], "why": f"Port {row['port']} is not listening.", "log_path": logs.get("log_path") or "", "source": "listeners"}
            break
    if not most_relevant_failure["component_id"]:
        for row in live_rows:
            if not row["health_ready"]:
                logs = resolve_log_paths_for_component(row["component_id"], start_run_data, last_failure_data)
                why = row["health_error"] or (f"Health probe returned {row['health_status_code']}." if row["health_status_code"] else "Health probe failed.")
                most_relevant_failure = {"component_id": row["component_id"], "component_label": row["label"], "why": why, "log_path": logs.get("log_path") or "", "source": "probe"}
                break
    if not most_relevant_failure["component_id"] and int(last_failure_summary.get("failure_count") or 0) > 0:
        component_id = normalize_component_id(last_failure_summary.get("component") or "launcher")
        logs = resolve_log_paths_for_component(component_id, start_run_data, last_failure_data)
        most_relevant_failure = {"component_id": component_id, "component_label": component_label(component_id), "why": last_failure_summary.get("reason") or "Last failure artifact recorded a failure.", "log_path": logs.get("log_path") or normalize_text(last_failure_summary.get("stderr_log") or last_failure_summary.get("stdout_log")), "source": "last_failure"}
    verify_status = normalize_verify_status(verify_result.get("status"))
    if not most_relevant_failure["component_id"] and verify_status not in {"", "UNKNOWN", "PASS"}:
        component_id = normalize_component_id(verify_result.get("failing_component_id") or "")
        component_text = verify_result.get("failing_component") or (component_label(component_id) if component_id else "Verify Stack")
        most_relevant_failure = {
            "component_id": component_id,
            "component_label": component_text,
            "why": verify_result.get("recommended_next_action") or f"Verify reported {verify_status}.",
            "log_path": verify_result.get("failing_log_path") or verify_result.get("raw_report_path") or "",
            "source": "verify_authoritative",
        }
    if not most_relevant_failure["component_id"] and start_status_raw not in {"PASS", "OK", "UNKNOWN"}:
        component_id = normalize_component_id(last_failure_summary.get("component") or "launcher")
        logs = resolve_log_paths_for_component(component_id, start_run_data, last_failure_data)
        most_relevant_failure = {"component_id": component_id, "component_label": component_label(component_id), "why": last_failure_summary.get("reason") or f"Start run reported {start_status_raw}.", "log_path": logs.get("log_path") or "", "source": "start_run"}

    failure_log_candidates = {"stdout_log": "", "stderr_log": "", "log_path": ""}
    if most_relevant_failure.get("component_id"):
        failure_log_candidates = resolve_log_paths_for_component(most_relevant_failure.get("component_id") or "", start_run_data, last_failure_data)
    resolved_failure_log = resolve_artifact_path_in_repo(failure_log_candidates.get("stderr_log") or failure_log_candidates.get("stdout_log") or most_relevant_failure.get("log_path") or "")
    if not resolved_failure_log and most_relevant_failure.get("log_path"):
        candidate = Path(str(most_relevant_failure.get("log_path")))
        if candidate.is_absolute() and candidate.exists():
            resolved_failure_log = candidate
    failure_log_lines = tail_text_lines(resolved_failure_log, max_lines=50) if resolved_failure_log else []
    if not failure_log_lines and failure_log_candidates.get("stdout_log"):
        alternate_log = resolve_artifact_path_in_repo(failure_log_candidates.get("stdout_log") or "")
        if alternate_log and alternate_log != resolved_failure_log:
            resolved_failure_log = alternate_log
            failure_log_lines = tail_text_lines(resolved_failure_log, max_lines=50)
    if not failure_log_lines:
        failure_log_lines = [most_relevant_failure.get("why") or "No failing component log available."]

    last_successful_pass = find_last_successful_start_run(start_run_data)
    approvals_items = get_approvals()
    approvals = build_approvals_section(approvals_items)
    security_posture = build_security_posture()
    security_summary = summarize_security_posture(security_posture)
    tenant_safety_summary = summarize_tenant_safety_report(build_tenant_safety_report())
    billing_summary = build_billing_summary()
    autonomy = build_autonomy_summary(security_summary)
    recent_actions = build_recent_actions(limit=50)
    system_health = build_system_health_summary()
    live_docs = load_live_docs_payload()
    brand_exposure = load_brand_exposure_payload()
    keepalive_ops = load_keepalive_ops_payload()
    system_truth = load_system_truth_payload()
    system_metrics = load_system_metrics_payload()
    regression_guard = load_regression_guard_payload()
    playbook_support = load_playbook_support_payload()
    wedge_pack_framework = load_wedge_pack_framework_payload()
    business_outcomes = load_business_outcomes_payload()
    release_management = load_release_management_payload()
    revenue_optimization = load_revenue_optimization_payload()
    model_cost_governance = load_model_cost_governance_payload()
    knowledge_learning_quality = load_knowledge_learning_quality_payload()
    ux_simplicity = load_ux_simplicity_payload()
    whole_folder_verification = load_whole_folder_verification_payload()
    repair_wave_payloads = load_repair_wave_payloads()
    founder_mode = build_founder_mode_payload(
        validation_data=validation_data,
        system_validation_summary=system_validation_summary,
        approvals=approvals,
        approvals_items=approvals_items,
        security_summary=security_summary,
        tenant_safety_summary=tenant_safety_summary,
        billing_summary=billing_summary,
        mirror_summary=mirror_summary,
        controls=controls,
        live_rows=live_rows,
        live_docs=live_docs,
    )

    recovery = {"show": False, "recommended_action_id": "", "recommended_action_label": "", "why": ""}
    if overall_status == "RED":
        listeners_alive = any(bool(row.get("listening")) for row in live_rows)
        recovery_action = "stop" if listeners_alive else "start"
        recovery = {
            "show": True,
            "recommended_action_id": recovery_action,
            "recommended_action_label": controls[recovery_action]["label"],
            "why": "Required health checks are down while ports are still bound. Stop stale listeners first." if listeners_alive else "No required stack services are healthy. Start the stack from a clean state.",
            "failed_component": most_relevant_failure.get("component_label") or "Stack",
        }

    return {
        "ok": True,
        "generated_at_utc": utc_now_iso(),
        "overall": {"status": overall_status, "severity": overall_severity, "ready_count": sum(1 for item in probes if bool(item.get("ready"))), "required_count": len(probes)},
        "current_run_id": start_summary.get("run_id") or "",
        "last_successful_pass": last_successful_pass,
        "most_relevant_failure": most_relevant_failure,
        "failure_logs": {"component_id": most_relevant_failure.get("component_id") or "", "component_label": most_relevant_failure.get("component_label") or "No failing component", "log_path": str(resolved_failure_log) if resolved_failure_log else normalize_text(most_relevant_failure.get("log_path")), "lines": failure_log_lines},
        "ports": {"contract": ports, "listeners": listener_rows, "table": live_rows},
        "probes": probes,
        "start_run": {"path": str(START_RUN_LAST_PATH), "summary": start_summary},
        "mirror_update": {"path": str(MIRROR_UPDATE_LAST_PATH), "summary": mirror_summary},
        "system_validation": system_validation_summary,
        "verify": {"path": str(VERIFY_LAST_PATH), "summary": verify_result},
        "last_failure": last_failure_data,
        "last_failure_file": {"path": str(LAST_FAILURE_PATH), "summary": last_failure_summary},
        "controls": controls,
        "commands": {action_id: state.get("command", "") for action_id, state in controls.items()},
        "approvals": approvals,
        "autonomy": autonomy,
        "security": security_summary,
        "tenant_safety": tenant_safety_summary,
        "billing": billing_summary,
        "recent_actions": recent_actions,
        "queues": current_queue_summary(),
        "system_health": system_health,
        "live_docs": live_docs,
        "brand_exposure": brand_exposure,
        "keepalive_ops": keepalive_ops,
        "system_truth": system_truth,
        "system_metrics": system_metrics,
        "regression_guard": regression_guard,
        "playbook_support": playbook_support,
        "wedge_pack_framework": wedge_pack_framework,
        "business_outcomes": business_outcomes,
        "release_management": release_management,
        "revenue_optimization": revenue_optimization,
        "model_cost_governance": model_cost_governance,
        "knowledge_learning_quality": knowledge_learning_quality,
        "ux_simplicity": ux_simplicity,
        "whole_folder_verification": whole_folder_verification,
        "repair_wave_01": repair_wave_payloads["repair_wave_01"],
        "onboarding_repair": repair_wave_payloads["onboarding_repair"],
        "billing_entitlements_repair": repair_wave_payloads["billing_entitlements_repair"],
        "halfwired_repair": repair_wave_payloads["halfwired_repair"],
        "scheduler_oversight": repair_wave_payloads["scheduler_oversight"],
        "internal_visibility": repair_wave_payloads["internal_visibility"],
        "mirror_hardening": repair_wave_payloads["mirror_hardening"],
        "repair_wave_02": repair_wave_payloads["repair_wave_02"],
        "internal_scheduler": repair_wave_payloads["internal_scheduler"],
        "legacy_task_migration": repair_wave_payloads["legacy_task_migration"],
        "popup_suppression": repair_wave_payloads["popup_suppression"],
        "validator_coverage_repair": repair_wave_payloads["validator_coverage_repair"],
        "broken_path_cluster_repair": repair_wave_payloads["broken_path_cluster_repair"],
        "remote_push_repair": repair_wave_payloads["remote_push_repair"],
        "founder_mode": founder_mode,
        "recovery": recovery,
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


def load_self_improvement_policy() -> dict[str, Any]:
    default = {
        "version": 1,
        "policy_name": "self_improvement_governor",
        "local_first_mandatory": True,
        "teacher_calls_enabled": True,
        "cost_sensitivity": "guarded",
        "minimum_teacher_quality_score": 70,
        "minimum_teacher_quality_classification": "queue_for_review",
        "blocked_target_types": ["billing", "security"],
        "score_thresholds": {
            "trivial_local_only_max_difficulty": 30,
            "local_first_optional_min_fallback": 65,
            "teacher_low_cost_min_expected_value": 55,
            "teacher_standard_min_expected_value": 70,
            "teacher_high_value_min_expected_value": 85,
            "safe_to_stage_min_quality": 78,
            "safe_to_test_min_quality": 88,
        },
    }
    configured = read_json(SELF_IMPROVEMENT_POLICY_PATH, default={})
    if isinstance(configured, dict):
        for key, value in configured.items():
            if isinstance(value, dict) and isinstance(default.get(key), dict):
                merged = dict(default.get(key) or {})
                merged.update(value)
                default[key] = merged
            else:
                default[key] = value
    return default


def load_self_improvement_governor_report() -> dict[str, Any]:
    data = read_json(SELF_IMPROVEMENT_GOVERNOR_REPORT_PATH, default={})
    return data if isinstance(data, dict) else {}


def self_improvement_decision_lookup(report: dict[str, Any] | None = None) -> dict[str, dict[str, Any]]:
    payload = report if isinstance(report, dict) else load_self_improvement_governor_report()
    items = normalize_list(payload.get("items"))
    return {
        normalize_text(item.get("improvement_id")): item
        for item in items
        if isinstance(item, dict) and normalize_text(item.get("improvement_id"))
    }


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
    local_unsigned_tool_path = is_loopback_unsigned_tool_path(path, client_ip)
    if require_signed and not local_unsigned_tool_path and not is_signed_exempt_path(path, policy):
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
        "pending_total": int(by_status.get("pending") or 0),
        "by_status": by_status,
        "by_component": by_component,
        "by_risk": by_risk,
    }


@app.post("/api/approvals/decision")
def api_approval_decision(payload: ApprovalDecisionRequest, request: Request) -> dict[str, Any]:
    decision = normalize_text(payload.decision).lower()
    if decision not in {"approve", "reject"}:
        return JSONResponse(status_code=400, content={"ok": False, "error": "invalid_decision"})

    items = get_approvals()
    target_index = -1
    for index, item in enumerate(items):
        if normalize_text(item.get("id")) == normalize_text(payload.approval_id):
            target_index = index
            break
    if target_index < 0:
        return JSONResponse(status_code=404, content={"ok": False, "error": "approval_not_found"})

    target = dict(items[target_index])
    status = normalize_text(target.get("status")).lower()
    if status != "pending":
        return JSONResponse(
            status_code=409,
            content={"ok": False, "error": "approval_not_pending", "status": status or "unknown"},
        )

    now_utc = utc_now_iso()
    requested_by_device = str(getattr(getattr(request, "state", object()), "authenticated_device_id", "") or "owner")
    owner_reason = normalize_text(payload.owner_reason)

    target["decision_by"] = requested_by_device
    target["decision_at"] = now_utc
    if owner_reason:
        target["owner_reason"] = owner_reason

    history = get_approvals_history()
    history.append(
        {
            "id": normalize_text(target.get("id")),
            "component_id": normalize_component_id(target.get("component_id")),
            "kind": normalize_text(target.get("kind") or "patch_run"),
            "decision": decision,
            "owner_reason": owner_reason,
            "decided_at": now_utc,
            "risk_level": normalize_founder_risk_level(target.get("risk_level")),
            "source": normalize_text(target.get("source")),
        }
    )
    write_json(APPROVALS_HISTORY_PATH, history)

    if decision == "approve":
        target["status"] = "approved"
        items[target_index] = target
    else:
        target["status"] = "rejected"
        target["quarantine_reason"] = "owner_rejected"
        items.pop(target_index)
        quarantine_items = get_quarantined_approvals()
        quarantine_items.append(target)
        write_json(PENDING_PATCHES_QUARANTINE, quarantine_items)

    write_json(PENDING_PATCHES, items)
    append_event(
        kind="approval_decision",
        status=decision,
        details={
            "approval_id": normalize_text(target.get("id")),
            "decision": decision,
            "component_id": normalize_component_id(target.get("component_id")),
            "requested_by_device": requested_by_device,
            "risk_level": normalize_founder_risk_level(target.get("risk_level")),
            "title": normalize_text(target.get("title")),
            "reason": owner_reason,
        },
        correlation_id=normalize_text(target.get("id")),
    )
    return {
        "ok": True,
        "approval_id": normalize_text(target.get("id")),
        "decision": decision,
        "status": normalize_text(target.get("status")),
        "pending_total": int(build_approvals_section(get_approvals()).get("pending_total") or 0),
        "history_path": str(APPROVALS_HISTORY_PATH),
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


@app.get("/api/stack_status")
def api_stack_status() -> dict[str, Any]:
    return build_stack_status_payload()


@app.get("/api/queues")
def api_queues() -> dict[str, Any]:
    queues = current_queue_summary()
    return {
        "ok": True,
        "generated_at_utc": utc_now_iso(),
        **queues,
        "pending_patch_path": str(PENDING_PATCHES),
        "pending_llm_dir": str(KNOWLEDGE_PENDING_LLM_DIR),
        "improvement_queue_path": str(IMPROVEMENT_QUEUE_PATH),
        "improvement_queue_report_path": str(IMPROVEMENT_QUEUE_REPORT_PATH),
        "improvement_queue": summarize_improvement_queue_state(),
    }


@app.get("/api/improvements")
def api_get_improvements(
    status: list[str] | None = Query(default=None),
    source: list[str] | None = Query(default=None),
    target_type: list[str] | None = Query(default=None),
    tenant_id: str | None = Query(default=None, min_length=3, max_length=64),
    current_only: bool = Query(default=True),
) -> dict[str, Any]:
    state = load_improvement_queue_state()
    status_filters = status if isinstance(status, list) else []
    source_filters = source if isinstance(source, list) else []
    target_type_filters = target_type if isinstance(target_type, list) else []
    tenant_filter = tenant_id if isinstance(tenant_id, str) else ""
    items = filter_improvement_items(
        state,
        statuses=status_filters,
        sources=source_filters,
        target_types=target_type_filters,
        tenant_id=tenant_filter,
        current_only=current_only,
    )
    return {
        "ok": True,
        "generated_at_utc": state.get("updated_at_utc") or utc_now_iso(),
        "count": len(items),
        "current_only": current_only,
        "filters": {
            "status": status_filters,
            "source": source_filters,
            "target_type": target_type_filters,
            "tenant_id": normalize_optional_onyx_tenant_id(tenant_filter),
        },
        "summary": summarize_improvement_queue_state(state),
        "items": items,
        "artifact_path": str(IMPROVEMENT_QUEUE_PATH),
        "report_path": str(IMPROVEMENT_QUEUE_REPORT_PATH),
    }


@app.get("/api/improvements/summary")
def api_get_improvements_summary() -> dict[str, Any]:
    return {
        "ok": True,
        "generated_at_utc": utc_now_iso(),
        **summarize_improvement_queue_state(),
    }


@app.post("/api/improvements/refresh")
def api_refresh_improvements(payload: ImprovementRefreshRequest) -> dict[str, Any]:
    state = refresh_improvement_queue(payload.sources)
    items = filter_improvement_items(state, current_only=False)
    return {
        "ok": True,
        "generated_at_utc": state.get("updated_at_utc") or utc_now_iso(),
        "count": len(items),
        "summary": summarize_improvement_queue_state(state),
        "items": items,
        "artifact_path": str(IMPROVEMENT_QUEUE_PATH),
        "report_path": str(IMPROVEMENT_QUEUE_REPORT_PATH),
    }


@app.post("/api/improvements")
def api_create_improvement(payload: ImprovementCreateRequest) -> dict[str, Any]:
    state = create_or_update_manual_improvement(payload)
    item = None
    expected_id = make_improvement_id(
        source=payload.source,
        target_type=payload.target_type,
        target_id=payload.target_id or payload.title,
        title=payload.title,
        linked_tenant_id=payload.linked_tenant_id or "",
        linked_behavior_id=payload.linked_behavior_id or "",
    )
    for candidate in filter_improvement_items(state, current_only=False):
        if normalize_text(candidate.get("improvement_id")) == expected_id:
            item = candidate
            break
    return {
        "ok": True,
        "generated_at_utc": state.get("updated_at_utc") or utc_now_iso(),
        "item": item,
        "summary": summarize_improvement_queue_state(state),
        "artifact_path": str(IMPROVEMENT_QUEUE_PATH),
        "report_path": str(IMPROVEMENT_QUEUE_REPORT_PATH),
    }


@app.post("/api/improvements/status")
def api_update_improvement_status(payload: ImprovementStatusRequest) -> dict[str, Any]:
    state = update_improvement_status(payload)
    if state is None:
        return JSONResponse(
            status_code=404,
            content={"ok": False, "error": "improvement_not_found", "improvement_id": payload.improvement_id},
        )
    item = None
    for candidate in filter_improvement_items(state, current_only=False):
        if normalize_text(candidate.get("improvement_id")) == normalize_text(payload.improvement_id):
            item = candidate
            break
    return {
        "ok": True,
        "generated_at_utc": state.get("updated_at_utc") or utc_now_iso(),
        "item": item,
        "summary": summarize_improvement_queue_state(state),
        "artifact_path": str(IMPROVEMENT_QUEUE_PATH),
        "report_path": str(IMPROVEMENT_QUEUE_REPORT_PATH),
    }


@app.get("/api/behaviors")
def api_get_behaviors(
    trust_state: list[str] | None = Query(default=None),
    domain: list[str] | None = Query(default=None),
    auto_allowed_only: bool = Query(default=False),
) -> dict[str, Any]:
    state = load_behavior_trust_state()
    trust_values = trust_state if isinstance(trust_state, list) else []
    domain_values = domain if isinstance(domain, list) else []
    auto_allowed_flag = auto_allowed_only if isinstance(auto_allowed_only, bool) else False
    trust_filters = {normalize_behavior_trust_state(item) for item in trust_values if normalize_text(item)}
    domain_filters = {normalize_behavior_domain(item) for item in domain_values if normalize_text(item)}
    behaviors: list[dict[str, Any]] = []
    for behavior in normalize_list(state.get("behaviors")):
        if not isinstance(behavior, dict):
            continue
        if trust_filters and normalize_behavior_trust_state(behavior.get("trust_state")) not in trust_filters:
            continue
        if domain_filters and normalize_behavior_domain(behavior.get("domain")) not in domain_filters:
            continue
        if auto_allowed_flag and not bool(behavior.get("auto_action_eligible")):
            continue
        behaviors.append(behavior)
    behaviors.sort(key=behavior_sort_key)
    return {
        "ok": True,
        "generated_at_utc": state.get("updated_at_utc") or utc_now_iso(),
        "count": len(behaviors),
        "filters": {
            "trust_state": sorted(trust_filters),
            "domain": sorted(domain_filters),
            "auto_allowed_only": auto_allowed_flag,
        },
        "summary": summarize_behavior_trust_state(state),
        "behaviors": behaviors,
        "artifact_path": str(BEHAVIOR_TRUST_PATH),
        "report_path": str(BEHAVIOR_TRUST_REPORT_PATH),
        "trust_index_path": str(TRUST_INDEX_PATH),
    }


@app.get("/api/behaviors/summary")
def api_get_behaviors_summary() -> dict[str, Any]:
    return {
        "ok": True,
        "generated_at_utc": utc_now_iso(),
        **summarize_behavior_trust_state(),
    }


@app.post("/api/behaviors")
def api_create_behavior(payload: BehaviorCreateRequest) -> dict[str, Any]:
    state = create_or_update_behavior(payload)
    behavior_id = make_behavior_id(payload.behavior_name, payload.domain, payload.behavior_id or "")
    behavior = None
    for candidate in normalize_list(state.get("behaviors")):
        if not isinstance(candidate, dict):
            continue
        if normalize_text(candidate.get("behavior_id")) == behavior_id:
            behavior = candidate
            break
    return {
        "ok": True,
        "generated_at_utc": state.get("updated_at_utc") or utc_now_iso(),
        "behavior": behavior,
        "summary": summarize_behavior_trust_state(state),
        "artifact_path": str(BEHAVIOR_TRUST_PATH),
        "report_path": str(BEHAVIOR_TRUST_REPORT_PATH),
        "trust_index_path": str(TRUST_INDEX_PATH),
    }


@app.post("/api/behaviors/state")
def api_update_behavior_state(payload: BehaviorStateRequest) -> dict[str, Any]:
    state, err = update_behavior_state(payload)
    if state is None:
        status_code = 404 if err == "behavior_not_found" else 400
        return JSONResponse(
            status_code=status_code,
            content={"ok": False, "error": err, "behavior_id": payload.behavior_id},
        )
    behavior = None
    for candidate in normalize_list(state.get("behaviors")):
        if not isinstance(candidate, dict):
            continue
        if normalize_text(candidate.get("behavior_id")) == normalize_text(payload.behavior_id):
            behavior = candidate
            break
    return {
        "ok": True,
        "generated_at_utc": state.get("updated_at_utc") or utc_now_iso(),
        "behavior": behavior,
        "summary": summarize_behavior_trust_state(state),
        "artifact_path": str(BEHAVIOR_TRUST_PATH),
        "report_path": str(BEHAVIOR_TRUST_REPORT_PATH),
        "trust_index_path": str(TRUST_INDEX_PATH),
    }


@app.get("/api/tool_factory")
def api_get_tool_factory(
    status: list[str] | None = Query(default=None),
    source: list[str] | None = Query(default=None),
    target_domain: list[str] | None = Query(default=None),
) -> dict[str, Any]:
    state = load_tool_factory_state()
    status_filters = {normalize_tool_factory_status(item) for item in (status if isinstance(status, list) else []) if normalize_text(item)}
    source_filters = {normalize_tool_factory_source(item) for item in (source if isinstance(source, list) else []) if normalize_text(item)}
    domain_filters = {normalize_behavior_domain(item) for item in (target_domain if isinstance(target_domain, list) else []) if normalize_text(item)}
    specs: list[dict[str, Any]] = []
    for spec in normalize_list(state.get("specs")):
        if not isinstance(spec, dict):
            continue
        if status_filters and normalize_tool_factory_status(spec.get("status")) not in status_filters:
            continue
        if source_filters and normalize_tool_factory_source(spec.get("source")) not in source_filters:
            continue
        if domain_filters and normalize_behavior_domain(spec.get("target_domain")) not in domain_filters:
            continue
        specs.append(spec)
    specs.sort(key=tool_factory_sort_key)
    return {
        "ok": True,
        "generated_at_utc": state.get("updated_at_utc") or utc_now_iso(),
        "count": len(specs),
        "filters": {
            "status": sorted(status_filters),
            "source": sorted(source_filters),
            "target_domain": sorted(domain_filters),
        },
        "summary": summarize_tool_factory_state(state),
        "specs": specs,
        "artifact_path": str(TOOL_FACTORY_PATH),
        "report_path": str(TOOL_FACTORY_REPORT_PATH),
    }


@app.get("/api/tool_factory/summary")
def api_get_tool_factory_summary() -> dict[str, Any]:
    return {
        "ok": True,
        "generated_at_utc": utc_now_iso(),
        **summarize_tool_factory_state(),
    }


@app.post("/api/tool_factory/refresh")
def api_refresh_tool_factory(payload: ToolFactoryRefreshRequest) -> dict[str, Any]:
    state = refresh_tool_factory(payload.sources)
    return {
        "ok": True,
        "generated_at_utc": state.get("updated_at_utc") or utc_now_iso(),
        "count": len([item for item in normalize_list(state.get("specs")) if isinstance(item, dict)]),
        "summary": summarize_tool_factory_state(state),
        "specs": [item for item in normalize_list(state.get("specs")) if isinstance(item, dict)],
        "artifact_path": str(TOOL_FACTORY_PATH),
        "report_path": str(TOOL_FACTORY_REPORT_PATH),
    }


@app.post("/api/tool_factory")
def api_create_tool_opportunity(payload: ToolOpportunityCreateRequest) -> dict[str, Any]:
    state = create_or_update_tool_opportunity(payload)
    spec_id = make_tool_factory_spec_id(
        title=payload.title,
        source=payload.source,
        target_domain=payload.target_domain,
        proposed_tool_name=payload.proposed_tool_name,
        linked_improvement_id=payload.linked_improvement_id or "",
        linked_behavior_id=payload.linked_behavior_id or "",
        requested_id=payload.spec_id or "",
    )
    spec = None
    for candidate in normalize_list(state.get("specs")):
        if not isinstance(candidate, dict):
            continue
        if normalize_text(candidate.get("spec_id")) == spec_id:
            spec = candidate
            break
    return {
        "ok": True,
        "generated_at_utc": state.get("updated_at_utc") or utc_now_iso(),
        "spec": spec,
        "summary": summarize_tool_factory_state(state),
        "artifact_path": str(TOOL_FACTORY_PATH),
        "report_path": str(TOOL_FACTORY_REPORT_PATH),
    }


@app.post("/api/tool_factory/status")
def api_update_tool_opportunity_status(payload: ToolOpportunityStatusRequest) -> dict[str, Any]:
    state, err = update_tool_opportunity_status(payload)
    if state is None:
        status_code = 404 if err == "spec_not_found" else 400
        return JSONResponse(
            status_code=status_code,
            content={"ok": False, "error": err, "spec_id": payload.spec_id},
        )
    spec = None
    for candidate in normalize_list(state.get("specs")):
        if not isinstance(candidate, dict):
            continue
        if normalize_text(candidate.get("spec_id")) == normalize_text(payload.spec_id):
            spec = candidate
            break
    return {
        "ok": True,
        "generated_at_utc": state.get("updated_at_utc") or utc_now_iso(),
        "spec": spec,
        "summary": summarize_tool_factory_state(state),
        "artifact_path": str(TOOL_FACTORY_PATH),
        "report_path": str(TOOL_FACTORY_REPORT_PATH),
    }


@app.post("/api/tool_factory/publish")
def api_publish_tool_opportunity(payload: ToolOpportunityPublishRequest) -> dict[str, Any]:
    state, err = publish_tool_opportunity(payload)
    if state is None:
        status_code = 404 if err == "spec_not_found" else 400
        return JSONResponse(
            status_code=status_code,
            content={"ok": False, "error": err, "spec_id": payload.spec_id},
        )
    spec = None
    for candidate in normalize_list(state.get("specs")):
        if not isinstance(candidate, dict):
            continue
        if normalize_text(candidate.get("spec_id")) == normalize_text(payload.spec_id):
            spec = candidate
            break
    return {
        "ok": True,
        "generated_at_utc": state.get("updated_at_utc") or utc_now_iso(),
        "spec": spec,
        "summary": summarize_tool_factory_state(state),
        "artifact_path": str(TOOL_FACTORY_PATH),
        "report_path": str(TOOL_FACTORY_REPORT_PATH),
        "registry_path": str(TOOL_REGISTRY_PATH),
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


@app.get("/api/onyx/business_context")
def api_onyx_business_context() -> dict[str, Any]:
    workspace = read_json(ONYX_TENANT_WORKSPACE_PATH, default=empty_onyx_workspace())
    sanitized = sanitize_onyx_business_context(workspace)
    return {
        "ok": True,
        "workspace": sanitized,
        "workspace_path": str(ONYX_TENANT_WORKSPACE_PATH),
    }


@app.get("/api/onyx/business_context/{tenant_id}")
def api_onyx_business_context_tenant(tenant_id: str) -> dict[str, Any]:
    safe_tenant_id = sanitize_onyx_tenant_id(tenant_id)
    tenant_path = ONYX_TENANTS_DIR / f"{safe_tenant_id}.json"
    if not tenant_path.exists():
        return JSONResponse(
            status_code=404,
            content={"ok": False, "error": "tenant_not_found", "tenant_id": safe_tenant_id},
        )
    artifact = read_json(tenant_path, default={})
    if not isinstance(artifact, dict) or not artifact:
        return JSONResponse(
            status_code=404,
            content={"ok": False, "error": "tenant_not_found", "tenant_id": safe_tenant_id},
        )
    return {
        "ok": True,
        "tenant_id": safe_tenant_id,
        "artifact": artifact,
        "artifact_path": str(tenant_path),
    }


@app.post("/api/onyx/business_context")
def api_post_onyx_business_context(payload: OnyxBusinessContextRequest) -> dict[str, Any]:
    workspace = sanitize_onyx_business_context(payload.workspace)
    if not workspace.get("contexts"):
        return JSONResponse(
            status_code=400,
            content={"ok": False, "error": "workspace_has_no_contexts"},
        )
    artifact_paths = write_onyx_business_context_artifacts(workspace)
    return {
        "ok": True,
        "message": "Business context synced to local workspace.",
        "synced_at_utc": workspace.get("lastUpdatedAtUtc") or utc_now_iso(),
        "workspace": workspace,
        **artifact_paths,
    }


@app.get("/api/onyx/recommendations")
def api_get_onyx_recommendations(
    tenant_id: str = Query(min_length=3, max_length=64),
    refresh: bool = Query(default=False),
) -> dict[str, Any]:
    safe_tenant_id, tenant_context = resolve_onyx_tenant_context(tenant_id)
    if not safe_tenant_id or tenant_context is None:
        return JSONResponse(
            status_code=404,
            content={"ok": False, "error": "tenant_not_found", "tenant_id": normalize_optional_onyx_tenant_id(tenant_id)},
        )
    state = refresh_tenant_recommendations(safe_tenant_id) if refresh else load_tenant_recommendation_state(safe_tenant_id)
    if not state.get("recommendations"):
        state = refresh_tenant_recommendations(safe_tenant_id)
    recommendations = [item for item in normalize_list(state.get("recommendations")) if isinstance(item, dict)]
    current_count = sum(1 for item in recommendations if bool(item.get("is_current", True)))
    return {
        "ok": True,
        "tenant_id": safe_tenant_id,
        "generated_at_utc": state.get("generated_at_utc") or utc_now_iso(),
        "count": len(recommendations),
        "current_count": current_count,
        "recommendations": recommendations,
        "artifact_path": str(recommendation_state_path(safe_tenant_id)),
    }


@app.post("/api/onyx/recommendations/refresh")
def api_refresh_onyx_recommendations(payload: OnyxRecommendationRefreshRequest) -> dict[str, Any]:
    safe_tenant_id, tenant_context = resolve_onyx_tenant_context(payload.tenant_id)
    if not safe_tenant_id or tenant_context is None:
        return JSONResponse(
            status_code=404,
            content={"ok": False, "error": "tenant_not_found", "tenant_id": normalize_optional_onyx_tenant_id(payload.tenant_id)},
        )
    state = refresh_tenant_recommendations(safe_tenant_id)
    recommendations = [item for item in normalize_list(state.get("recommendations")) if isinstance(item, dict)]
    return {
        "ok": True,
        "tenant_id": safe_tenant_id,
        "generated_at_utc": state.get("generated_at_utc") or utc_now_iso(),
        "count": len(recommendations),
        "recommendations": recommendations,
        "artifact_path": str(recommendation_state_path(safe_tenant_id)),
    }


@app.post("/api/onyx/recommendations/status")
def api_update_onyx_recommendation_status(payload: OnyxRecommendationStatusRequest) -> dict[str, Any]:
    safe_tenant_id, tenant_context = resolve_onyx_tenant_context(payload.tenant_id)
    if not safe_tenant_id or tenant_context is None:
        return JSONResponse(
            status_code=404,
            content={"ok": False, "error": "tenant_not_found", "tenant_id": normalize_optional_onyx_tenant_id(payload.tenant_id)},
        )
    state = update_tenant_recommendation_status(
        safe_tenant_id,
        payload.recommendation_id,
        payload.status,
    )
    if state is None:
        return JSONResponse(
            status_code=400,
            content={"ok": False, "error": "recommendation_update_failed", "tenant_id": safe_tenant_id},
        )
    recommendations = [item for item in normalize_list(state.get("recommendations")) if isinstance(item, dict)]
    return {
        "ok": True,
        "tenant_id": safe_tenant_id,
        "generated_at_utc": state.get("generated_at_utc") or utc_now_iso(),
        "count": len(recommendations),
        "recommendations": recommendations,
        "artifact_path": str(recommendation_state_path(safe_tenant_id)),
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


def write_verify_output_logs(stdout_text: str, stderr_text: str) -> None:
    ensure_parent(VERIFY_LAST_STDOUT_PATH)
    VERIFY_LAST_STDOUT_PATH.write_text(stdout_text or "", encoding="utf-8")
    VERIFY_LAST_STDERR_PATH.write_text(stderr_text or "", encoding="utf-8")


def build_verify_runner_failure_result(
    *,
    command_run: str,
    error: str,
    failing_log_path: str,
    raw_report_path: str,
) -> dict[str, Any]:
    if error == "script_timeout":
        next_action = f"Rerun the exact verify command and inspect {failing_log_path or raw_report_path or str(VERIFY_LAST_PATH)}."
    elif error == "e2e_script_missing":
        next_action = "Restore tools\\Mason_E2E_Verify.ps1 and rerun Verify Stack."
    else:
        next_action = f"Run the exact verify command below and inspect {failing_log_path or raw_report_path or str(VERIFY_LAST_PATH)}."
    result = default_verify_result(command_run=command_run)
    result.update(
        {
            "timestamp_utc": utc_now_iso(),
            "ok": False,
            "status": "FAIL",
            "failing_component": "Verify Runner",
            "failing_component_id": "launcher",
            "failing_log_path": normalize_repo_path_text(failing_log_path),
            "recommended_next_action": next_action,
            "raw_report_path": normalize_repo_path_text(raw_report_path) or str(E2E_VERIFY_REPORT_PATH),
        }
    )
    return result


def run_verify_script_sync(script_path: Path, timeout_seconds: int) -> dict[str, Any]:
    cmd = [
        "powershell.exe",
        "-NoLogo",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        str(script_path),
        "-RootPath",
        str(BASE),
    ]
    try:
        proc = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=max(1, int(timeout_seconds)),
            cwd=str(BASE),
        )
        stdout_text = redact_secrets(proc.stdout or "")
        stderr_text = redact_secrets(proc.stderr or "")
        write_verify_output_logs(stdout_text, stderr_text)
        parsed = parse_json_from_output(stdout_text)
        return {
            "ok": proc.returncode == 0,
            "error": "" if proc.returncode == 0 else f"script_exit_{proc.returncode}",
            "timed_out": False,
            "parsed_report": parsed if isinstance(parsed, dict) else {},
            "stdout_path": str(VERIFY_LAST_STDOUT_PATH),
            "stderr_path": str(VERIFY_LAST_STDERR_PATH),
        }
    except subprocess.TimeoutExpired as exc:
        stdout_text = redact_secrets((exc.stdout or "") if isinstance(exc.stdout, str) else "")
        stderr_text = redact_secrets((exc.stderr or "") if isinstance(exc.stderr, str) else "")
        write_verify_output_logs(stdout_text, stderr_text)
        return {
            "ok": False,
            "error": "script_timeout",
            "timed_out": True,
            "parsed_report": {},
            "stdout_path": str(VERIFY_LAST_STDOUT_PATH),
            "stderr_path": str(VERIFY_LAST_STDERR_PATH),
        }
    except Exception as exc:
        write_verify_output_logs("", f"verify_spawn_failed:{type(exc).__name__}")
        return {
            "ok": False,
            "error": f"script_spawn_failed:{type(exc).__name__}",
            "timed_out": False,
            "parsed_report": {},
            "stdout_path": str(VERIFY_LAST_STDOUT_PATH),
            "stderr_path": str(VERIFY_LAST_STDERR_PATH),
        }


def run_authoritative_verify(requested_by_device: str) -> dict[str, Any]:
    script = BASE / "tools" / "Mason_E2E_Verify.ps1"
    command_run = build_verify_command_string()
    started_at = time.monotonic()
    report_mtime_before = E2E_VERIFY_REPORT_PATH.stat().st_mtime if E2E_VERIFY_REPORT_PATH.exists() else None
    if not script.exists():
        verify_result = build_verify_runner_failure_result(
            command_run=command_run,
            error="e2e_script_missing",
            failing_log_path="",
            raw_report_path=str(E2E_VERIFY_REPORT_PATH),
        )
        write_json(VERIFY_LAST_PATH, verify_result)
        return {
            **verify_result,
            "error": "e2e_script_missing",
            "result_path": str(VERIFY_LAST_PATH),
            "duration_seconds": round(time.monotonic() - started_at, 1),
            "requested_by_device": requested_by_device or "unknown",
        }

    script_result = run_verify_script_sync(script, E2E_VERIFY_TIMEOUT_SECONDS)
    parsed_report = script_result.get("parsed_report") if isinstance(script_result.get("parsed_report"), dict) else {}
    report_data = parsed_report
    if not report_data:
        report_is_fresh = False
        if E2E_VERIFY_REPORT_PATH.exists():
            report_mtime_after = E2E_VERIFY_REPORT_PATH.stat().st_mtime
            report_is_fresh = report_mtime_before is None or report_mtime_after > report_mtime_before
        if report_is_fresh:
            raw_report = read_json(E2E_VERIFY_REPORT_PATH, default={})
            report_data = raw_report if isinstance(raw_report, dict) else {}

    if report_data:
        verify_result = build_authoritative_verify_result(report_data, command_run=command_run)
    else:
        failing_log_path = script_result.get("stderr_path") or script_result.get("stdout_path") or ""
        verify_result = build_verify_runner_failure_result(
            command_run=command_run,
            error=str(script_result.get("error") or "verify_failed"),
            failing_log_path=str(failing_log_path),
            raw_report_path=str(E2E_VERIFY_REPORT_PATH),
        )

    write_json(VERIFY_LAST_PATH, verify_result)
    return {
        **verify_result,
        "error": str(script_result.get("error") or ""),
        "result_path": str(VERIFY_LAST_PATH),
        "duration_seconds": round(time.monotonic() - started_at, 1),
        "requested_by_device": requested_by_device or "unknown",
    }


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


@app.post("/api/control/verify_stack")
def api_control_verify_stack(request: Request) -> dict[str, Any]:
    allowed, reason = ensure_control_allowed("verify")
    if not allowed:
        return JSONResponse(status_code=423, content={"ok": False, "error": reason})
    requested_by_device = str(getattr(getattr(request, "state", object()), "authenticated_device_id", "") or "unknown")
    if not VERIFY_RUN_LOCK.acquire(blocking=False):
        current_state = get_verify_runtime_state()
        return JSONResponse(
            status_code=409,
            content={
                "ok": False,
                "error": "verify_in_progress",
                "status": "running",
                "command_run": current_state.get("command_run") or build_verify_command_string(),
                "started_at_utc": current_state.get("started_at_utc") or "",
                "result_path": str(VERIFY_LAST_PATH),
            },
        )

    command_run = build_verify_command_string()
    set_verify_runtime_state(
        running=True,
        requested_by_device=requested_by_device,
        command_run=command_run,
    )
    append_event(
        kind="control_e2e_verify",
        status="running",
        details={
            "requested_by_device": requested_by_device,
            "command_run": command_run,
        },
    )
    try:
        result = run_authoritative_verify(requested_by_device=requested_by_device)
        append_event(
            kind="control_e2e_verify",
            status="completed" if normalize_verify_status(result.get("status")) == "PASS" else "failed",
            details={
                "requested_by_device": requested_by_device,
                "status": result.get("status"),
                "failing_component": result.get("failing_component"),
                "failing_log_path": result.get("failing_log_path"),
                "recommended_next_action": result.get("recommended_next_action"),
                "result_path": result.get("result_path"),
            },
        )
        return result
    finally:
        set_verify_runtime_state(running=False)
        VERIFY_RUN_LOCK.release()


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


@app.get("/api/billing/summary")
def api_billing_summary(
    tenant_id: str | None = Query(default=None),
) -> dict[str, Any]:
    resolved_tenant_id, tenant_context = resolve_onyx_tenant_context(tenant_id)
    requested_tenant_id = normalize_optional_onyx_tenant_id(tenant_id)
    if requested_tenant_id and tenant_context is None:
        return JSONResponse(
            status_code=404,
            content={"ok": False, "error": "tenant_not_found", "tenant_id": requested_tenant_id},
        )
    summary = build_billing_summary(
        tenant_id=resolved_tenant_id if tenant_context is not None else requested_tenant_id,
        tenant_context=tenant_context,
    )
    return summary


@app.post("/api/billing/checkout_session")
def api_billing_checkout_session(payload: BillingCheckoutRequest) -> dict[str, Any]:
    safe_tenant_id, tenant_context = resolve_onyx_tenant_context(payload.tenant_id)
    if not safe_tenant_id or tenant_context is None:
        return JSONResponse(
            status_code=404,
            content={"ok": False, "error": "tenant_not_found", "tenant_id": normalize_optional_onyx_tenant_id(payload.tenant_id)},
        )
    plan = find_plan_definition(payload.plan_id)
    if not isinstance(plan, dict):
        return JSONResponse(
            status_code=404,
            content={"ok": False, "error": "plan_not_found", "plan_id": normalize_plan_id(payload.plan_id)},
        )
    session = create_billing_checkout_session(
        tenant_context,
        plan,
        success_url=payload.success_url,
        cancel_url=payload.cancel_url,
    )
    return {
        "ok": True,
        "tenant_id": safe_tenant_id,
        "plan_id": session.get("plan_id"),
        "session_id": session.get("session_id"),
        "checkout_url": session.get("checkout_url"),
        "mode": session.get("provider_mode"),
        "message": "Checkout session created. Complete the local stub checkout to activate billing entitlements.",
    }


@app.post("/api/billing/portal")
def api_billing_portal(payload: BillingPortalRequest) -> dict[str, Any]:
    safe_tenant_id, tenant_context = resolve_onyx_tenant_context(payload.tenant_id)
    if not safe_tenant_id or tenant_context is None:
        return JSONResponse(
            status_code=404,
            content={"ok": False, "error": "tenant_not_found", "tenant_id": normalize_optional_onyx_tenant_id(payload.tenant_id)},
        )
    detail = build_tenant_billing_detail(tenant_context)
    append_platform_audit_event(
        event_type="billing_sensitive_action",
        actor_role="tenant_admin",
        actor_id=safe_tenant_id,
        tenant_id=safe_tenant_id,
        resource_type="subscription",
        resource_id=normalize_plan_id(detail.get("plan_id") or detail.get("selected_plan_id") or safe_tenant_id),
        action="open_billing_portal",
        outcome=detail.get("status") or "inactive",
        risk_level="R1",
        details={"portal_url": detail.get("portal_url")},
    )
    return {
        "ok": True,
        "tenant_id": safe_tenant_id,
        "portal_url": detail.get("portal_url"),
        "status": detail.get("status"),
        "message": "Billing portal opened in local stub mode.",
    }


@app.post("/api/billing/webhook")
def api_billing_webhook(payload: BillingWebhookRequest) -> dict[str, Any]:
    result = apply_billing_webhook_event(payload)
    if not result.get("ok"):
        return JSONResponse(status_code=400, content=result)
    return result


@app.get("/billing/checkout/{session_id}", include_in_schema=False)
def billing_checkout_page(session_id: str) -> HTMLResponse:
    session = load_billing_session(session_id)
    if not isinstance(session, dict):
        return HTMLResponse("<h1>Billing session not found.</h1>", status_code=404)
    return HTMLResponse(render_billing_checkout_page(session))


@app.get("/billing/checkout/{session_id}/complete", include_in_schema=False)
def billing_checkout_complete_page(
    session_id: str,
    outcome: str = Query(default="success"),
) -> Any:
    session, _ = complete_billing_checkout_session(session_id, outcome)
    if not isinstance(session, dict):
        return HTMLResponse("<h1>Billing session not found.</h1>", status_code=404)
    target_url = normalize_text(session.get("success_url") if normalize_short_text(outcome, max_len=24).lower() == "success" else session.get("cancel_url"))
    if target_url:
        return RedirectResponse(url=target_url)
    return HTMLResponse("<h1>Billing session updated.</h1>")


@app.get("/billing/portal/{tenant_id}", include_in_schema=False)
def billing_portal_page(tenant_id: str) -> HTMLResponse:
    safe_tenant_id, tenant_context = resolve_onyx_tenant_context(tenant_id)
    if not safe_tenant_id or tenant_context is None:
        return HTMLResponse("<h1>Tenant not found.</h1>", status_code=404)
    return HTMLResponse(render_billing_portal_page(build_tenant_billing_detail(tenant_context)))


@app.get("/api/tools/catalog")
def tools_catalog(
    tenant_id: str | None = Query(default=None),
    include_ineligible: bool = Query(default=False),
) -> dict[str, Any]:
    registry = load_tool_registry_document()
    workspace = load_onyx_workspace()
    resolved_tenant_id, tenant_context = resolve_onyx_tenant_context(tenant_id, workspace)
    requested_tenant_id = normalize_optional_onyx_tenant_id(tenant_id)
    if requested_tenant_id and tenant_context is None:
        return JSONResponse(
            status_code=404,
            content={"ok": False, "error": "tenant_not_found", "tenant_id": requested_tenant_id, "tools": []},
        )
    tools_out: list[dict[str, Any]] = []
    for tool in load_tool_registry_entries():
        entry = sanitize_tool_catalog_entry(tool, tenant_context)
        if not include_ineligible and (not entry.get("eligible") or entry.get("status") != "enabled"):
            continue
        tools_out.append(entry)
    entitlements = resolve_tenant_entitlements(tenant_context)

    return {
        "ok": True,
        "version": registry.get("version", 1),
        "tenant_id": resolved_tenant_id,
        "tenant_found": tenant_context is not None,
        "entitlements": entitlements,
        "count": len(tools_out),
        "tools": tools_out,
    }


@app.get("/api/tiers")
def get_tiers() -> dict[str, Any]:
    data = load_plan_catalog()
    tiers = normalize_list(data.get("tiers") if isinstance(data, dict) else [])
    return {
        "ok": True,
        "default_plan_id": data.get("default_plan_id", "starter_monthly") if isinstance(data, dict) else "starter_monthly",
        "launch_wedge_plan_id": data.get("launch_wedge_plan_id", "") if isinstance(data, dict) else "",
        "currency": data.get("currency", "USD") if isinstance(data, dict) else "USD",
        "tiers": [tier for tier in tiers if isinstance(tier, dict)],
    }


@app.get("/api/addons")
def get_addons() -> dict[str, Any]:
    data = load_addon_catalog()
    addons = normalize_list(data.get("addons") if isinstance(data, dict) else [])
    return {
        "ok": True,
        "version": data.get("version", 2) if isinstance(data, dict) else 2,
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
    workspace = load_onyx_workspace()
    resolved_tenant_id, tenant_context = resolve_onyx_tenant_context(payload.tenant_id, workspace)
    if tenant_context is None:
        return JSONResponse(status_code=404, content={"ok": False, "error": "tenant_not_found"})

    tool_entry = get_tool_registry_entry(tool_id)
    if not tool_entry:
        return JSONResponse(status_code=404, content={"ok": False, "error": "unknown_tool_id"})
    tool_contract = sanitize_tool_catalog_entry(tool_entry, tenant_context)
    if not bool(tool_contract.get("eligible")):
        return JSONResponse(
            status_code=403,
            content={
                "ok": False,
                "error": str(tool_contract.get("eligibility_reason") or "tool_not_eligible"),
                "tenant_id": resolved_tenant_id,
            },
        )

    effective_input = build_tool_run_input(payload.input or {}, tenant_context)
    profile = tenant_context.get("profile") if isinstance(tenant_context.get("profile"), dict) else {}
    client_name = redact_secrets(
        (payload.client_name or profile.get("businessName") or "client").strip()
    )
    workspace_id = (payload.workspace_id or resolved_tenant_id or "").strip()
    input_json = redact_secrets(json.dumps(effective_input, ensure_ascii=False))

    args = [
        "-RootPath",
        str(BASE),
        "-ToolId",
        tool_id,
        "-TenantId",
        resolved_tenant_id,
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
    run_dir = safe_resolve_in_repo(str(result.get("output_root") or ""))
    if run_dir and run_dir.is_dir():
        run_summary = summarize_tool_run(run_dir)
        run_tenant_id = normalize_optional_onyx_tenant_id(run_summary.get("tenant_id"))
        if run_tenant_id and run_tenant_id != resolved_tenant_id:
            append_platform_audit_event(
                event_type="tool_run",
                actor_role="tenant_admin",
                actor_id=resolved_tenant_id,
                tenant_id=resolved_tenant_id,
                resource_type="tool",
                resource_id=tool_id,
                action="run",
                outcome="tenant_scope_mismatch",
                risk_level=normalize_short_text(tool_contract.get("risk_level"), max_len=24),
                details={
                    "run_id": normalize_short_text(run_summary.get("run_id"), max_len=80),
                    "observed_tenant_id": run_tenant_id,
                },
            )
            return JSONResponse(
                status_code=500,
                content={
                    "ok": False,
                    "error": "tool_run_tenant_scope_mismatch",
                    "tenant_id": resolved_tenant_id,
                    "observed_tenant_id": run_tenant_id,
                },
            )
        append_platform_audit_event(
            event_type="tool_run",
            actor_role="tenant_admin",
            actor_id=resolved_tenant_id,
            tenant_id=resolved_tenant_id,
            resource_type="tool",
            resource_id=tool_id,
            action="run",
            outcome=normalize_short_text(run_summary.get("status"), max_len=32) or "completed",
            risk_level=normalize_short_text(tool_contract.get("risk_level"), max_len=24),
            details={
                "run_id": normalize_short_text(run_summary.get("run_id"), max_len=80),
                "artifact_path": normalize_text(run_summary.get("artifact_path")),
                "tool_name": normalize_short_text(run_summary.get("tool_name") or tool_contract.get("name"), max_len=120),
            },
        )
        enriched = dict(result)
        enriched.update(
            {
                "tenant_id": resolved_tenant_id,
                "tool_name": run_summary.get("tool_name") or tool_contract.get("name"),
                "status": run_summary.get("status", "completed"),
                "summary": run_summary.get("summary", ""),
                "recommendations": run_summary.get("recommendations", []),
                "artifact_path": run_summary.get("artifact_path", ""),
            }
        )
        return enriched
    result["tenant_id"] = resolved_tenant_id
    result["tool_name"] = tool_contract.get("name", "")
    return result


@app.get("/api/tools/runs/latest")
def tools_runs_latest(
    limit: int = Query(default=10, ge=1, le=50),
    tenant_id: str | None = Query(default=None),
) -> dict[str, Any]:
    if not TOOL_RUNS_DIR.exists():
        return {"ok": True, "tenant_id": tenant_id or "", "runs": []}

    run_dirs = [p for p in TOOL_RUNS_DIR.iterdir() if p.is_dir()]
    run_dirs.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    wanted_tenant_id = normalize_optional_onyx_tenant_id(tenant_id)

    runs: list[dict[str, Any]] = []
    for run_dir in run_dirs:
        summary = summarize_tool_run(run_dir)
        if wanted_tenant_id and normalize_optional_onyx_tenant_id(summary.get("tenant_id")) != wanted_tenant_id:
            continue
        runs.append(summary)
        if len(runs) >= limit:
            break

    return {"ok": True, "tenant_id": wanted_tenant_id, "runs": runs}


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
