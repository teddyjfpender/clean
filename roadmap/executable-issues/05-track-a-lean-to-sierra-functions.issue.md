# Executable Issue: `roadmap/05-track-a-lean-to-sierra-functions.md`

- Source roadmap file: [`roadmap/05-track-a-lean-to-sierra-functions.md`](../05-track-a-lean-to-sierra-functions.md)
- Issue class: Primary compiler delivery
- Priority: P0
- Overall status: NOT DONE

## Objective

Deliver full function-level Lean -> Sierra -> CASM support for the pinned Sierra family set with formal and benchmark gates.

## Implementation loci

1. `src/LeanCairo/Backend/Sierra/**`
2. `src/LeanCairo/Pipeline/Sierra/**`
3. `src/LeanCairo/Compiler/IR/**`
4. `src/LeanCairo/Compiler/Semantics/**`
5. `src/LeanCairo/Compiler/Proof/**`
6. `tools/sierra_toolchain/**`
7. `scripts/test/sierra_*.sh`
8. `scripts/bench/**`
9. `roadmap/12-direct-sierra-subset-coverage-ledger.md`

## Formal method requirements

1. Every newly enabled Sierra family has:
- MIR representation
- lowering rules
- fail-fast for unsupported variants
- semantic model and proof obligations
2. Resource-sensitive families require explicit state threading.
3. No family is marked supported without validation and CASM compilation evidence.

## Milestone status ledger

### A0 Surface synchronization and autogeneration
- Status: DONE - 6a1f5ce
- Evidence tests: `scripts/test/sierra_surface_codegen.sh`; `python3 scripts/roadmap/generate_inventory_docs.py && git diff --exit-code roadmap/inventory`
- Evidence proofs: `N/A`
- Acceptance tests:
1. `./scripts/test/sierra_surface_codegen.sh`
2. `python3 scripts/roadmap/generate_inventory_docs.py && git diff --exit-code roadmap/inventory`

### A1 Scalar arithmetic core
- Status: DONE - 8e775a3
- Evidence tests: `scripts/test/sierra_scalar_e2e.sh`; `scripts/test/sierra_differential.sh`; `scripts/workflow/run-sierra-checks.sh`
- Evidence proofs: `src/LeanCairo/Backend/Sierra/Emit/SubsetProgram.lean`; `src/LeanCairo/Compiler/Proof/OptimizeSound.lean`
- Acceptance tests:
1. Scalar corpus generates valid Sierra (`ProgramRegistry` pass).
2. Scalar corpus compiles to CASM without failures.
3. Differential scalar tests pass against reference runner.

### A2 Range-checked integer families
- Status: DONE - 6833a1a
- Evidence tests: `scripts/test/sierra_u128_range_checked_e2e.sh`; `scripts/test/sierra_u128_wrapping_differential.sh`; `scripts/test/sierra_failfast_unsupported.sh`; `scripts/workflow/run-sierra-checks.sh`
- Evidence proofs: `src/LeanCairo/Backend/Sierra/Emit/Subset/Function.lean`; `src/LeanCairo/Backend/Sierra/Generated/CapabilityProjection.lean`; `examples/Lean/u128_range_checked/Example.lean`; `tests/lean/sierra_u128_wrapping_differential.lean`; `roadmap/capabilities/registry.json`
- Acceptance tests:
1. Integer fixtures compile and validate with explicit range-check resources.
2. Unsupported integer variants fail fast with exact error contracts.
3. Integer differential tests cover overflow/checked paths.

### A3 Aggregates (struct/enum/tuple)
- Status: DONE - 0052b25
- Evidence tests: `scripts/test/sierra_aggregate_collection_e2e.sh`; `scripts/test/sierra_aggregate_branch_typing.sh`; `scripts/test/eval_aggregate_wrapper_semantics.sh`; `scripts/workflow/run-sierra-checks.sh`
- Evidence proofs: `src/LeanCairo/Backend/Sierra/Emit/Subset/Foundation.lean`; `src/LeanCairo/Compiler/Semantics/Aggregates.lean`; `src/LeanCairo/Backend/Sierra/Generated/CapabilityProjection.lean`; `roadmap/capabilities/registry.json`
- Acceptance tests:
1. ADT fixtures compile, validate, and run equivalently.
2. Pattern-match branch typing tests pass.
3. Constructor/destructor roundtrip laws are proved for enabled forms.

### A4 Arrays/spans/nullable/box/dict
- Status: DONE - 573579c
- Evidence tests: `scripts/test/sierra_aggregate_collection_e2e.sh`; `scripts/test/eval_aggregate_wrapper_semantics.sh`; `scripts/test/sierra_failfast_unsupported.sh`; `scripts/workflow/run-sierra-checks.sh`
- Evidence proofs: `src/LeanCairo/Backend/Sierra/Emit/Subset/Foundation.lean`; `src/LeanCairo/Compiler/Semantics/Aggregates.lean`; `src/Examples/SierraSubsetUnsupportedDictSig.lean`; `roadmap/capabilities/registry.json`
- Acceptance tests:
1. Collection corpus compiles to Sierra and CASM.
2. Alias/ownership invariants are tested.
3. Dictionary operation differential tests pass.

### A5 Control-flow and calls
- Status: DONE - c22a9ea
- Evidence tests: `scripts/test/call_panic_semantics_regression.sh`; `scripts/test/control_flow_normalization_regression.sh`; `scripts/test/sierra_differential.sh`; `scripts/workflow/run-sierra-checks.sh`
- Evidence proofs: `src/LeanCairo/Compiler/Semantics/Eval.lean`; `src/LeanCairo/Compiler/Optimize/Expr.lean`; `tests/lean/call_panic_semantics_regression.lean`; `tests/lean/control_flow_normalization_regression.lean`
- Acceptance tests:
1. Function-call and recursion fixtures pass validation/compilation.
2. Panic propagation behavior matches reference semantics.
3. Control-flow normalization tests are deterministic.

### A6 Crypto/math/circuit/ec families
- Status: DONE - 23a5513
- Evidence tests: `scripts/test/sierra_advanced_family_e2e.sh`; `scripts/test/backend_parity_advanced_family.sh`; `scripts/roadmap/check_effect_metadata.sh`; `scripts/bench/check_optimizer_non_regression.sh`; `scripts/bench/check_optimizer_family_thresholds.sh`; `scripts/workflow/run-sierra-checks.sh`
- Evidence proofs: `examples/Lean/circuit_gate_felt/Example.lean`; `examples/Lean/crypto_round_felt/Example.lean`; `scripts/test/sierra_advanced_family_e2e.sh`; `config/effect-metadata.json`; `roadmap/capabilities/registry.json`
- Acceptance tests:
1. Crypto/circuit fixtures compile and validate.
2. Builtin/resource constraints are explicitly verified.
3. Performance benchmarks are non-regressive.

### A7 Gas/AP/segment-arena/diagnostics
- Status: DONE - c22a9ea
- Evidence tests: `scripts/roadmap/check_effect_metadata.sh`; `scripts/test/effect_resource_regression.sh`; `scripts/test/benchmark_family_thresholds_negative.sh`; `scripts/bench/check_optimizer_non_regression.sh`; `scripts/bench/check_optimizer_family_thresholds.sh`; `scripts/workflow/run-mvp-checks.sh`
- Evidence proofs: `config/effect-metadata.json`; `scripts/roadmap/validate_effect_metadata.py`; `scripts/bench/check_optimizer_family_thresholds.sh`; `scripts/bench/check_optimizer_non_regression.sh`; `roadmap/reports/cost-model-calibration-thresholds.json`
- Acceptance tests:
1. Gas/AP-sensitive corpus passes with metadata checks.
2. Illegal optimization under gas/AP constraints is rejected.
3. Resource law tests pass.

### A8 Full non-Starknet function-family closure
- Status: DONE - 140eb5c
- Evidence tests: `scripts/roadmap/check_sierra_primary_closure.sh`; `scripts/roadmap/check_coverage_matrix_freshness.sh`; `scripts/roadmap/check_sierra_coverage_report_freshness.sh`; `scripts/test/sierra_primary_closure_negative.sh`; `scripts/workflow/run-sierra-checks.sh`
- Evidence proofs: `scripts/roadmap/render_coverage_matrix.py`; `roadmap/inventory/sierra-coverage-matrix.json`; `roadmap/inventory/sierra-family-coverage-report.json`; `roadmap/inventory/sierra-family-coverage-report.md`; `scripts/roadmap/check_sierra_primary_closure.sh`
- Acceptance tests:
1. Coverage report shows 100% closure for targeted non-Starknet families.
2. No unresolved TODO in enabled families without fail-fast guard.

### A9 Starknet interop (optional, isolated)
- Status: DONE - a70c31f
- Evidence tests: `scripts/test/e2e.sh`; `scripts/test/sierra_primary_without_cairo.sh`; `scripts/test/sierra_primary_cairo_coupling_guard.sh`; `scripts/test/architecture_boundaries.sh`; `scripts/workflow/run-sierra-checks.sh`
- Evidence proofs: `src/LeanCairo/Pipeline/Sierra/Main.lean`; `src/LeanCairo/Backend/Cairo/EmitIRContract.lean`; `scripts/roadmap/check_architecture_boundaries.sh`; `scripts/test/sierra_primary_without_cairo.sh`
- Acceptance tests:
1. Contract adapter tests pass without regressing function-only lane.
2. Function-core CI lane remains independent and green.

### A10 Sierra -> Cairo review lift
- Status: DONE - a70c31f
- Evidence tests: `scripts/test/sierra_review_lift.sh`; `scripts/test/sierra_review_lift_complex.sh`; `scripts/roadmap/check_review_lift_isolation.sh`; `scripts/workflow/run-sierra-checks.sh`
- Evidence proofs: `scripts/sierra/render_review_lift.py`; `scripts/test/sierra_review_lift.sh`; `scripts/test/sierra_review_lift_complex.sh`; `scripts/roadmap/check_review_lift_isolation.sh`
- Acceptance tests:
1. Review output is generated with Sierra statement anchors.
2. No compilation path depends on review lift output.

## Global strict acceptance tests

1. `./scripts/workflow/run-sierra-checks.sh`
2. `~/.elan/bin/lake build leancairo-sierra-gen`
3. `cargo run --manifest-path tools/sierra_toolchain/Cargo.toml -- validate --input <generated program>`
4. `cargo run --manifest-path tools/sierra_toolchain/Cargo.toml -- compile --input <generated program> --out-casm <out>`
5. Differential test suite command (to be implemented): `scripts/test/sierra_differential.sh`

## Completion criteria

1. All A0-A8 milestones are `DONE - <commit>`.
2. All strict tests above are in CI and passing.
3. Coverage report and proof report are attached for release.
