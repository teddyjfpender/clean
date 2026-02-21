# Executable Issue: `roadmap/26-red-green-refactor-delivery-loop-spec.md`

- Source roadmap file: [`roadmap/26-red-green-refactor-delivery-loop-spec.md`](../26-red-green-refactor-delivery-loop-spec.md)
- Issue class: Delivery loop governance and automation
- Priority: P0
- Overall status: NOT DONE

## Objective

Implement a strict, deterministic RED->GREEN->REFACTOR loop pipeline with machine-validated status transitions for incremental capability delivery.

## Implementation loci

1. `roadmap/26-red-green-refactor-delivery-loop-spec.md`
2. `config/rgr-deliverable-spec.json`
3. `roadmap/reports/rgr-deliverables.{json,md}`
4. `scripts/roadmap/**`
5. `scripts/test/**`
6. `scripts/workflow/**`

## Formal method requirements

1. Deliverables are generated from canonical sources and validated by schema + invariants.
2. Every done transition is gate-backed and commit-referenced.
3. Loop runner executes RED, GREEN, and REFACTOR phases explicitly.
4. Determinism and freshness checks enforce reproducibility.

## Milestone status ledger

### RGL-1 Deliverable catalog schema + deterministic generation
- Status: DONE - 1bc5c30
- Evidence tests: `scripts/roadmap/check_rgr_deliverables.sh`; `scripts/roadmap/validate_rgr_deliverables.py --catalog roadmap/reports/rgr-deliverables.json`; `scripts/test/rgr_deliverables_negative.sh`
- Evidence proofs: `config/rgr-deliverable-spec.json`; `scripts/roadmap/generate_rgr_deliverables.py`; `scripts/roadmap/validate_rgr_deliverables.py`; `roadmap/reports/rgr-deliverables.json`; `roadmap/reports/rgr-deliverables.md`
- Acceptance tests:
1. Deliverable generation is deterministic.
2. Missing required sources fail checks.
3. Schema and status-format validation passes.

### RGL-2 Loop runner with explicit RED/GREEN/REFACTOR phase gates
- Status: DONE - 71dc3fe
- Evidence tests: `scripts/test/rgr_loop_smoke.sh`; `scripts/roadmap/run_rgr_loop.sh --deliverable d00-non-starknet-closure-guard --phase all --dry-run`; `scripts/roadmap/check_rgr_deliverables.sh`
- Evidence proofs: `scripts/roadmap/run_rgr_loop.sh`; `roadmap/reports/rgr-deliverables.json`; `config/rgr-deliverable-spec.json`; `scripts/test/rgr_loop_smoke.sh`
- Acceptance tests:
1. Loop runner executes all phases for a selected deliverable.
2. Missing gate command references fail fast.
3. Loop smoke test is deterministic.

### RGL-3 Status-transition tooling and legality guards
- Status: DONE - 1951ceb
- Evidence tests: `scripts/test/rgr_status_transition_negative.sh`; `scripts/roadmap/check_rgr_deliverables.sh`; `python3 scripts/roadmap/mark_rgr_deliverable_done.py --deliverable d00-non-starknet-closure-guard --catalog roadmap/reports/rgr-deliverables.json --commit $(git rev-parse --short=12 HEAD)`
- Evidence proofs: `scripts/roadmap/mark_rgr_deliverable_done.py`; `scripts/roadmap/validate_rgr_deliverables.py`; `roadmap/reports/rgr-deliverables.json`; `roadmap/reports/rgr-deliverables.md`
- Acceptance tests:
1. `NOT DONE -> DONE - <commit>` requires computed readiness and evidence.
2. Illegal transitions fail validation.
3. Transition negative tests pass.

### RGL-4 Workflow integration + bootstrap loop completion
- Status: NOT DONE
- Acceptance tests:
1. Loop checks are integrated into workflow gate execution.
2. Bootstrap deliverable completes full loop and is marked `DONE - <commit>`.
3. Gate manifest synchronization validates new loop checks.

## Global strict acceptance tests

1. `scripts/roadmap/check_rgr_deliverables.sh`
2. `scripts/test/rgr_deliverables_negative.sh`
3. `scripts/test/rgr_loop_smoke.sh`
4. `scripts/test/rgr_status_transition_negative.sh`
5. `./scripts/workflow/run-sierra-checks.sh`
6. `./scripts/workflow/run-mvp-checks.sh`

## Completion criteria

1. RGL-1 through RGL-4 are `DONE - <commit>`.
2. Loop status transitions are fully machine-validated.
3. Bootstrap loop transition demonstrates commit-backed completion update.
