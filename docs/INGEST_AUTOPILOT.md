# Mason2 Ingest Autopilot

## Overview
`Mason2` can ingest dropped documents, build ingest indexes, queue follow-up tasks, and enforce a weekly paid-call budget.

Primary scripts:
- `tools/ingest/Mason_IngestDrop_Once.ps1`
- `tools/ingest/Mason_IngestFolder.ps1`
- `tools/budget/Mason_Budget.ps1`
- `tools/budget/Mason_Select_Model.ps1`
- `tools/Mason_Build_Master_Roadmap.ps1`
- `tools/Mason_Tasks_From_Knowledge.ps1`

Primary configs:
- `config/ingest_policy.json`
- `config/budget_policy.json`
- `config/currency_policy.json`
- `config/model_policy.json`

Hands-off toggles in `config/ingest_policy.json`:
- `auto_install_task`
- `auto_run_on_boot`
- `use_flattened_inbox`
- `flatten_source_dir`
- `flatten_target_dir`

## Ingest Flow
1. `Mason_IngestDrop_Once.ps1` scans:
- `config.ingest_policy.drop_dir`
- flattened inbox (`flatten_target_dir`) when `use_flattened_inbox=true`
- otherwise each path in `config.ingest_policy.inbox_paths`
2. When flattened inbox is enabled, `tools/ingest/Mason_Inbox_Flatten.ps1` runs first:
- source: `flatten_source_dir` (Desktop archive)
- target: `flatten_target_dir` (`knowledge/inbox_flat`)
- converts extensionless and `.docx` content to sanitized `.txt`
- deduplicates by normalized SHA256 text hash
- writes:
  - `knowledge/inbox_flat/_manifest.json`
  - `reports/inbox_flatten_last.json`
3. Eligible files are staged and moved to `processed_dir` with timestamp suffixes.
4. `Mason_IngestFolder.ps1` chunks content (`max_chars_per_chunk`, `max_chunks_per_file`) and redacts secrets before any API call.
5. If paid calls are allowed, chunks are sent to `ingest_url` (`/api/ingest_chunk`).
6. If paid calls are blocked/exhausted/failing, chunk payloads are queued under `knowledge/pending_llm/<runId>/`.
7. Outputs are written to:
- `reports/ingest_index_<runId>.json`
- `reports/ingest_autopilot_status.json`
8. Post-ingest mirror workflow can run:
- `tools/sync/Mason_Mirror_Update.ps1 -Reason post-ingest`

## Budget Behavior
- Weekly spend state is tracked in:
  - `state/knowledge/budget_ledger.jsonl`
  - `state/knowledge/budget_state.json`
- Budget policy is CAD-first (`weekly_budget_cad`, default cap: `$50.00 CAD`).
- Ledger source-of-truth is still USD cost per usage record (`usage_usd`), with computed CAD (`usage_cad`) using `config/currency_policy.json`.
- Budget week window uses:
  - `reset_timezone`
  - `reset_weekday`
  - `reset_hour_local`
  - `reset_minute_local`
- Model/tier behavior uses `config/model_policy.json`:
  - PRIMARY -> SECONDARY -> TERTIARY degradation as remaining CAD drops.
  - When exhausted, mode switches to `storage_only` (no paid calls).

If token usage is unavailable from API responses, estimates are used from chunk size and configured cost rates.

## Security Guardrails
- Secret/token/private-key redaction runs before API calls and before writing queued chunk content.
- Web learning remains disabled (`web_learning_enabled=false`).
- Sidecar7000 is not touched.

## Scheduled Task
Install:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\ingest\Install_Mason_Ingest_Autopilot_Task.ps1
```

Task name:
- `\Mason2\Mason2 Ingest Autopilot`

Triggers:
- At logon
- Every 5 minutes

Logs:
- `reports/ingest_autopilot_stdout.log`
- `reports/ingest_autopilot_stderr.log`

## Disable Autopilot
Set in `config/ingest_policy.json`:

```json
{
  "enabled": false,
  "auto_install_task": false
}
```

With ingest disabled, status file still updates with `mode=disabled`.

## Manual Run Commands
Run once:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\ingest\Mason_IngestDrop_Once.ps1
```

Run ingest directly on a folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\ingest\Mason_IngestFolder.ps1 -InputPaths "C:\Users\Chris\Desktop\Mason2\drop\ingest"
```

Build roadmap + queue tasks:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\Mason_Build_Master_Roadmap.ps1
powershell -ExecutionPolicy Bypass -File .\tools\Mason_Tasks_From_Knowledge.ps1
```
