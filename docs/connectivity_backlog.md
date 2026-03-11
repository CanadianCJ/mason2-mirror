# Connectivity Backlog (Do Not Implement Yet)

This file records deferred recommendations for Athena and Onyx connectivity hardening/visibility.

## Athena (10)
1. Add `/api/connectivity/status` returning endpoint reachability matrix for Mason/Seed/Bridge/Onyx.
2. Add `/api/connectivity/history` backed by JSONL to track intermittent failures over time.
3. Add circuit-breaker state export (`open/half-open/closed`) for unstable upstreams.
4. Add explicit timeout/retry policy config (`connect_timeout_ms`, `read_timeout_ms`, retry backoff).
5. Emit per-endpoint latency percentiles into `reports/connectivity_athena.json`.
6. Add request correlation IDs propagated from Athena to all downstream calls.
7. Add endpoint-specific health reasons (DNS/connect/HTTP/non-JSON/schema mismatch).
8. Add signed “connectivity snapshot” artifact for postmortem reproducibility.
9. Add startup dependency graph check to validate required endpoints before enabling actions.
10. Add an Athena UI panel for connectivity drift alerts with actionable remediation links.

## Onyx (10)
1. Add an Onyx connectivity probe bundle (`/main.dart.js`, primary API, optional analyzer endpoint).
2. Add Onyx websocket/session heartbeat monitoring with reconnect diagnostics.
3. Add Onyx outbound dependency map (what hosts/ports are required and why).
4. Add Onyx request queue depth telemetry and failed-send counters.
5. Add on-device/offline cache state export for stale-data diagnostics.
6. Add per-build connectivity smoke tests before release packaging.
7. Add Onyx-to-Athena event bridge for real-time client connectivity failures.
8. Add strict schema/version negotiation report for Athena<->Onyx payloads.
9. Add mobile-network mode simulation (high latency/loss) with summarized results.
10. Add Onyx crash + connectivity correlation report to separate app bugs from network issues.

## Constraints Reminder
- No secrets in logs/artifacts.
- Sidecar7000 stays OFF.
- Risk gates stay enforced.
- Implement later under explicit approved work order only.
