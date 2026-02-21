# Executable Issue: `roadmap/20-track-b-cairo-parity-and-reviewability-plan.md`

- Source roadmap file: [`roadmap/20-track-b-cairo-parity-and-reviewability-plan.md`](../20-track-b-cairo-parity-and-reviewability-plan.md)
- Issue class: Track-B parity and reviewability closure
- Priority: P1
- Overall status: NOT DONE

## Objective

Close Track-B function parity and reviewability guarantees while preserving Track-A primacy and shared MIR semantics.

## Implementation loci

1. `src/LeanCairo/Backend/Cairo/**`
2. `src/LeanCairo/Pipeline/Generation/**`
3. `src/LeanCairo/Compiler/IR/**`
4. `scripts/test/backend_parity.sh`
5. `scripts/test/cairo_ast_idempotence.sh`
6. `scripts/test/sierra_review_lift.sh`
7. `roadmap/20-track-b-cairo-parity-and-reviewability-plan.md`

## Formal method requirements

1. Cairo emission is MIR-projected and capability-guarded.
2. Divergence against Sierra path is explicit and tested.
3. Review-lift remains non-authoritative and traceable.

## Milestone status ledger

### CPL-1 Cairo AST and emitter family closure
- Status: DONE - 0052b25
- Evidence tests: `scripts/test/cairo_ast_idempotence.sh`; `scripts/test/deterministic_codegen.sh`; `scripts/test/backend_parity_aggregate_collection.sh`; `scripts/workflow/run-mvp-checks.sh`
- Evidence proofs: `src/LeanCairo/Backend/Cairo/EmitIRContract.lean`; `src/LeanCairo/Backend/Cairo/EmitIRFunction.lean`; `roadmap/capabilities/registry.json`; `src/Examples.lean`
- Acceptance tests:
1. AST/emitter supports all Track-A implemented capabilities or explicit fail-fast states.
2. Deterministic rendering and idempotence tests pass.
3. Capability guard checks pass.

### CPL-2 Corelib parity mapping and divergence policy
- Status: DONE - 167bfae
- Evidence tests: `scripts/roadmap/check_corelib_parity_freshness.sh`; `scripts/roadmap/check_capability_registry.sh`; `scripts/test/capability_registry_negative.sh`; `scripts/workflow/run-mvp-checks.sh`
- Evidence proofs: `scripts/roadmap/render_corelib_parity_report.py`; `roadmap/inventory/corelib-parity-report.json`; `roadmap/inventory/corelib-parity-report.md`; `scripts/roadmap/validate_capability_registry.py`; `roadmap/capabilities/registry.json`
- Acceptance tests:
1. Corelib parity mapping report is generated.
2. Undocumented divergence is rejected.
3. Divergence entries include capability IDs and rationale.

### CPL-3 Differential equivalence suite closure
- Status: DONE - 23a5513
- Evidence tests: `scripts/test/sierra_differential.sh`; `scripts/test/sierra_u128_wrapping_differential.sh`; `scripts/test/backend_parity.sh`; `scripts/test/differential_harness_reproducibility.sh`; `scripts/workflow/run-mvp-checks.sh`
- Evidence proofs: `scripts/test/generated/run_manifest_differential.sh`; `generated/examples/differential-harness.json`; `scripts/test/run_backend_parity_case.sh`; `scripts/utils/check_backend_parity.py`; `config/examples-manifest.json`
- Acceptance tests:
1. Evaluator/Sierra/Cairo differential suites pass for closed capabilities.
2. Failure/boundary parity vectors pass.
3. Mismatch diagnostics are reproducible.

### CPL-4 Reviewability and traceability closure
- Status: NOT DONE
- Acceptance tests:
1. Sierra review-lift trace links are generated and stable.
2. Review output does not feed compilation semantics.
3. Reviewability checks pass on complex corpus samples.

## Global strict acceptance tests

1. `scripts/test/backend_parity.sh`
2. `scripts/test/cairo_ast_idempotence.sh`
3. `scripts/test/codegen_snapshot.sh`
4. `scripts/test/sierra_review_lift.sh`

## Completion criteria

1. CPL-1 through CPL-4 are `DONE - <commit>`.
2. Track-B parity is evidence-backed and governance-compliant.
3. Track-B remains secondary and cannot regress Track-A semantics path.
