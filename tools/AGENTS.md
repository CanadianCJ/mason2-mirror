# Tools Component Scope

## Focus
1. Watchdog, governor, and self-improve reliability.
2. Logging quality and operational traceability.
3. Safe retries with bounded behavior.
4. Rollback paths for failed updates or unsafe states.

## Allowed Work
1. Reliability hardening for tool loops and control scripts.
2. Logging improvements that help diagnose failures.
3. Retry/backoff safeguards that prevent runaway behavior.
4. Rollback and recovery steps that are testable.

## Not Allowed
1. UI or product feature work unrelated to tool reliability and operations.
2. Broad refactors without direct reliability or safety benefit.
3. Network exposure changes unless explicitly approved.

## Required For Every Tools Change
1. A short "why this improves reliability/safety" note.
2. A deterministic "how to test" PowerShell snippet with expected result.

## Test Snippet Format (Required)
```powershell
# How to test:
<exact command(s)>

# Expected:
<deterministic pass/fail signal>
```
