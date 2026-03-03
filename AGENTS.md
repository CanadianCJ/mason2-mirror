# Mason2 Agent Guardrails

## Global Priorities
1. Stability-first: protect existing behavior before adding or changing behavior.
2. Safety-first: avoid actions that increase risk to data, users, or runtime safety.
3. Minimal diffs: change only what is required for the approved objective.
4. Deterministic acceptance tests: every change must include reproducible pass/fail checks.

## Scope Gate (No Randomness Rule)
1. Every change must map to an explicit objective for `Mason`, `Athena`, or `Onyx`.
2. If no explicit objective exists, reject the change.
3. Do not add speculative refactors, cleanup, redesigns, or "nice to have" work outside approved scope.

## Security Constraints
1. Never access, modify, expose, or commit secrets.
2. Never print keys, tokens, passwords, or secret values in logs, output, or diffs.
3. Do not widen network exposure (ports, bindings, firewall rules) unless explicitly approved.
4. Prefer `localhost` bindings over external interfaces.

## Definition Of A Helpful Change
A change is helpful only if it has measurable benefit tied to scope, such as:
1. Deterministic smoke test passes.
2. Fewer crashes or error events.
3. Faster startup or reduced latency.
4. Clearer operator/user workflow with measurable completion improvements.
5. Reduced operational risk with verified rollback behavior.

## Acceptance Criteria For Any Change
1. Objective link: state Mason/Athena/Onyx objective.
2. Scope check: explain why out-of-scope changes were not included.
3. Deterministic test evidence: include exact commands and expected results.
4. Security check: confirm no secrets touched or exposed and no network widening.
