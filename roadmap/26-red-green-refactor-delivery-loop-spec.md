# 26. RED-GREEN-REFACTOR Delivery Loop Specification

## Objective

Define a strict, machine-enforced delivery loop for incremental capability expansion where each deliverable is completed through:

1. RED gates (regression detectors / negative tests)
2. GREEN gates (positive correctness and differential tests)
3. REFACTOR gates (determinism, freshness, non-regression, and artifact integrity)

No deliverable can transition to done status without passing all three phases.

## Scope

This specification governs delivery-loop mechanics, not a single capability family. It applies to all expansion work derived from:

1. `roadmap/inventory/sierra-coverage-matrix.json`
2. `roadmap/capabilities/registry.json`

## Canonical Inputs

1. `spec.md` and `spec2.md` remain canonical requirements.
2. Pinned upstream commit is read from `config/cairo_pinned_commit.txt`.
3. Deliverables are generated from deterministic source data and policy (`config/rgr-deliverable-spec.json`).

## Deliverable Model

Each deliverable must include:

1. stable `id`
2. `title`
3. `priority`
4. `target_policy`
5. explicit `module_scope`
6. phase gates (`red`, `green`, `refactor`)
7. computed readiness (`computed_ready`)
8. status (`NOT DONE` or `DONE - <commit>`)
9. evidence fields (`evidence_tests`, `evidence_proofs`)

## Status Transition Law

1. Initial status is `NOT DONE`.
2. Transition `NOT DONE -> DONE - <commit>` requires:
1. successful RED/GREEN/REFACTOR phase execution
2. `computed_ready = true` under target policy
3. non-empty evidence tests/proofs
4. commit hash exists in git history
3. Illegal transitions are rejected by validation gates.
4. Any drift that invalidates a `DONE` item must fail checks.

## Loop Pipeline

### Phase 0: Generate + Validate

1. Generate deterministic deliverable catalog from sources and policy.
2. Validate schema, gate references, status format, and transition legality.
3. Fail on missing required sources or malformed deliverables.

### Phase 1: RED

1. Run negative/regression gates for selected deliverable.
2. RED phase must fail on injected regressions.
3. RED phase must pass under normal code state.

### Phase 2: GREEN

1. Run positive correctness gates.
2. Require compilation/validation/differential gates relevant to deliverable.

### Phase 3: REFACTOR

1. Run determinism/freshness/reproducibility/performance gates.
2. Reject nondeterministic artifacts or stale reports.

### Phase 4: Transition + Commit

1. Mark deliverable done only after all phase gates pass.
2. Commit implementation first.
3. Update status to `DONE - <commit>` in a separate evidence commit.

## Required Artifacts

1. `roadmap/reports/rgr-deliverables.json`
2. `roadmap/reports/rgr-deliverables.md`
3. delivery-loop scripts under `scripts/roadmap/**`
4. negative/smoke tests under `scripts/test/**`

## Required Gates

1. deliverable generation freshness check
2. deliverable schema/transition validation
3. RED-phase negative checks
4. loop-runner smoke check
5. status-transition negative check

## Completion Criteria

1. loop specification and policy are versioned and validated.
2. loop runner is executable and deterministic.
3. status transitions are machine-checked and evidence-backed.
4. workflow integration enforces loop gates.
5. bootstrap deliverable completes full RED->GREEN->REFACTOR->DONE transition.
