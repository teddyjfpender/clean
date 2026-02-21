# Executable Issue: `roadmap/19-track-a-sierra-family-closure-execution-plan.md`

- Source roadmap file: [`roadmap/19-track-a-sierra-family-closure-execution-plan.md`](../19-track-a-sierra-family-closure-execution-plan.md)
- Issue class: Track-A family closure execution
- Priority: P0
- Overall status: NOT DONE

## Objective

Execute full function-domain Sierra family closure for Track A with explicit lowering, fail-fast contracts, validation/compile evidence, and differential tests.

## Implementation loci

1. `src/LeanCairo/Backend/Sierra/**`
2. `src/LeanCairo/Pipeline/Sierra/**`
3. `src/LeanCairo/Compiler/IR/**`
4. `src/LeanCairo/Compiler/Semantics/**`
5. `src/LeanCairo/Compiler/Proof/**`
6. `scripts/test/sierra_*.sh`
7. `tools/sierra_toolchain/**`
8. `roadmap/19-track-a-sierra-family-closure-execution-plan.md`

## Formal method requirements

1. Family support is capability-driven and fail-fast for unsupported variants.
2. Resource and panic semantics are explicit and preserved.
3. Family promotion requires validation + CASM compilation + differential evidence.

## Milestone status ledger

### SCL-1 Sierra emitter architecture split and scaffold integration
- Status: DONE - 1063d7e
- Evidence tests: `scripts/test/architecture_boundaries.sh`; `scripts/roadmap/check_lowering_scaffold_sync.sh`; `scripts/roadmap/check_capability_projection_usage.sh`; `scripts/test/sierra_failfast_unsupported.sh`
- Evidence proofs: `src/LeanCairo/Backend/Sierra/Emit/Subset/Foundation.lean`; `src/LeanCairo/Backend/Sierra/Emit/Subset/Expr.lean`; `src/LeanCairo/Backend/Sierra/Emit/Subset/Function.lean`; `src/LeanCairo/Backend/Sierra/Generated/LoweringScaffold.lean`
- Acceptance tests:
1. Family-scoped emitter module boundaries are enforced.
2. Scaffold/projection sync checks pass.
3. Unsupported family paths fail fast consistently.

### SCL-2 Scalar/integer/field family closure
- Status: DONE - 6833a1a
- Evidence tests: `scripts/test/sierra_scalar_e2e.sh`; `scripts/test/sierra_u128_range_checked_e2e.sh`; `scripts/test/sierra_u128_wrapping_differential.sh`; `scripts/test/eval_qm31_semantics.sh`; `scripts/workflow/run-sierra-checks.sh`
- Evidence proofs: `src/LeanCairo/Backend/Sierra/Emit/Subset/Expr.lean`; `src/LeanCairo/Backend/Sierra/Emit/Subset/Function.lean`; `src/LeanCairo/Compiler/Semantics/Eval.lean`; `roadmap/capabilities/registry.json`
- Acceptance tests:
1. Scalar/integer/field corpora pass validation and CASM compilation.
2. Overflow/boundary differential tests pass.
3. Range-check/resource contracts are explicit and verified.

### SCL-3 Aggregate and collection family closure
- Status: DONE - 0052b25
- Evidence tests: `scripts/test/sierra_aggregate_collection_e2e.sh`; `scripts/test/sierra_aggregate_branch_typing.sh`; `scripts/test/backend_parity_aggregate_collection.sh`; `scripts/workflow/run-sierra-checks.sh`
- Evidence proofs: `src/LeanCairo/Backend/Sierra/Emit/Subset/Foundation.lean`; `src/LeanCairo/Backend/Sierra/Generated/CapabilityProjection.lean`; `roadmap/capabilities/registry.json`; `roadmap/capabilities/obligations.json`
- Acceptance tests:
1. Aggregate/collection fixtures validate and compile.
2. Ownership/aliasing invariants are test-covered.
3. Differential suites pass.

### SCL-4 Control/runtime/advanced family closure
- Status: NOT DONE
- Acceptance tests:
1. Call/control/panic/runtime fixtures validate and compile.
2. Gas/AP/segment-arena legality checks pass.
3. Advanced family benchmarks are non-regressive.

### SCL-5 Non-Starknet closure certification
- Status: NOT DONE
- Acceptance tests:
1. Coverage report shows closure ratio target met for non-Starknet families.
2. No unresolved implemented-family gaps remain.
3. Closure report is generated and fresh.

## Global strict acceptance tests

1. `./scripts/workflow/run-sierra-checks.sh`
2. `scripts/test/sierra_e2e.sh`
3. `scripts/test/sierra_differential.sh`
4. `scripts/test/sierra_failfast_unsupported.sh`
5. `cargo run --manifest-path tools/sierra_toolchain/Cargo.toml -- validate --input <generated program>`
6. `cargo run --manifest-path tools/sierra_toolchain/Cargo.toml -- compile --input <generated program> --out-casm <out>`

## Completion criteria

1. SCL-1 through SCL-5 are `DONE - <commit>`.
2. Track-A function family closure is evidence-backed and reproducible.
3. Non-Starknet closure is certified by generated reports and gates.
