# Executable Issue: `roadmap/06-track-b-lean-to-cairo-functions.md`

- Source roadmap file: [`roadmap/06-track-b-lean-to-cairo-functions.md`](../06-track-b-lean-to-cairo-functions.md)
- Issue class: Secondary backend parity
- Priority: P1
- Overall status: NOT DONE

## Objective

Deliver deterministic function-level Lean -> Cairo emission from shared MIR with parity checks against the primary Lean -> Sierra pipeline.

## Implementation loci

1. `src/LeanCairo/Backend/Cairo/**`
2. `src/LeanCairo/Pipeline/Generation/**`
3. `src/LeanCairo/Compiler/IR/**` (shared MIR contracts)
4. `scripts/test/codegen_snapshot.sh`
5. `scripts/test/e2e.sh`
6. `scripts/test/backend_parity.sh` (new)

## Formal method requirements

1. Cairo emission must consume shared MIR only.
2. Any backend divergence must be explicit, tested, and documented.
3. Deterministic source shape is part of interface contract.

## Milestones

### B0 Structured Cairo AST emitter foundation
- Status: DONE - c8594bb
- Evidence tests: `scripts/test/cairo_ast_idempotence.sh`; `scripts/test/deterministic_codegen.sh`
- Evidence proofs: `src/LeanCairo/Backend/Cairo/Ast.lean`; `src/LeanCairo/Backend/Cairo/EmitIRFunction.lean`
- Acceptance tests:
1. Snapshot-stable output across repeated runs.
2. AST-to-source pretty-printer idempotence tests pass.

### B1 Scalar/integer parity
- Status: DONE - c8594bb
- Evidence tests: `scripts/test/backend_parity.sh`; `scripts/test/sierra_differential.sh`; `scripts/test/sierra_u128_wrapping_differential.sh`
- Evidence proofs: `scripts/utils/check_backend_parity.py`; `src/LeanCairo/Backend/Cairo/Naming.lean`
- Acceptance tests:
1. Scalar/integer differential tests vs Sierra path pass.
2. Overflow and checked-op semantics match expected outputs.

### B2 Aggregate/collection parity
- Status: DONE - 0052b25
- Evidence tests: `scripts/test/backend_parity_aggregate_collection.sh`; `scripts/test/sierra_aggregate_collection_e2e.sh`; `scripts/workflow/run-mvp-checks.sh`
- Evidence proofs: `src/LeanCairo/Backend/Cairo/EmitIRContract.lean`; `scripts/utils/check_backend_parity.py`; `src/Examples/SierraAggregateCollectionParity.lean`; `roadmap/capabilities/registry.json`
- Acceptance tests:
1. ADT and collection fixtures emit valid Cairo and compile.
2. Behavior matches primary backend on shared vectors.

### B3 Error/panic/control-flow parity
- Status: DONE - c22a9ea
- Evidence tests: `scripts/test/call_panic_semantics_regression.sh`; `scripts/test/control_flow_normalization_regression.sh`; `scripts/test/backend_parity.sh`; `scripts/workflow/run-mvp-checks.sh`
- Evidence proofs: `src/LeanCairo/Compiler/Semantics/Eval.lean`; `src/LeanCairo/Compiler/Optimize/Expr.lean`; `src/LeanCairo/Compiler/Proof/OptimizeSound.lean`
- Acceptance tests:
1. Panic and early-return differentials pass.
2. Branch-heavy corpus parity passes.

### B4 Advanced math/crypto/circuit parity
- Status: NOT DONE
- Acceptance tests:
1. Advanced function corpus parity passes.
2. Resource-sensitive emit rules are enforced.

### B5 Corelib closure reporting
- Status: NOT DONE
- Acceptance tests:
1. Corelib parity report is generated from inventory.
2. Coverage trends are monotonic non-decreasing.

## Global strict acceptance tests

1. `./scripts/test/codegen_snapshot.sh`
2. `./scripts/test/e2e.sh`
3. `scripts/test/backend_parity.sh` (to be implemented)

## Completion criteria

1. B0-B5 all `DONE - <commit>`.
2. Backend parity suite is stable and CI-gated.
3. Cairo backend remains secondary and does not alter primary compilation path.
