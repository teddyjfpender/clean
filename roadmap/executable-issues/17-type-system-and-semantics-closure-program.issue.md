# Executable Issue: `roadmap/17-type-system-and-semantics-closure-program.md`

- Source roadmap file: [`roadmap/17-type-system-and-semantics-closure-program.md`](../17-type-system-and-semantics-closure-program.md)
- Issue class: Type semantics closure
- Priority: P0
- Overall status: NOT DONE

## Objective

Close full function-domain type semantics for MIR/evaluator/backends with explicit width/sign/resource behavior and no type-erasure shortcuts.

## Implementation loci

1. `src/LeanCairo/Core/Domain/**`
2. `src/LeanCairo/Core/Syntax/**`
3. `src/LeanCairo/Compiler/IR/**`
4. `src/LeanCairo/Compiler/Semantics/**`
5. `src/LeanCairo/Compiler/Proof/**`
6. `roadmap/17-type-system-and-semantics-closure-program.md`

## Formal method requirements

1. Type domains are disjoint and explicit.
2. Conversions are explicit with legality checks.
3. Unsupported type operations fail fast.
4. Type family semantics map to proof/test obligations.

## Milestone status ledger

### TYC-1 Type universe closure in Core and MIR
- Status: DONE - cdd0bdd
- Evidence tests: `scripts/test/type_universe_regression.sh`; `scripts/test/eval_unsupported_domain_failfast.sh`; `scripts/roadmap/check_mir_family_contract.sh`; `scripts/roadmap/check_lowering_scaffold_sync.sh`
- Evidence proofs: `src/LeanCairo/Core/Domain/Ty.lean`; `src/LeanCairo/Compiler/IR/Expr.lean`; `roadmap/capabilities/mir-family-contract.json`; `scripts/roadmap/validate_mir_family_contract.py`; `scripts/roadmap/generate_lowering_scaffolds.py`; `src/LeanCairo/Backend/Sierra/Generated/LoweringScaffold.lean`; `src/LeanCairo/Backend/Cairo/Generated/LoweringScaffold.lean`
- Acceptance tests:
1. Declared type families have MIR representation or explicit fail-fast status.
2. Exhaustive type handling checks pass.
3. Type universe regression tests are green.

### TYC-2 Integer and field semantics closure
- Status: DONE - fbb51b0
- Evidence tests: `scripts/test/eval_integer_width_semantics.sh`; `scripts/test/eval_qm31_semantics.sh`; `scripts/test/eval_scalar_domain_isolation.sh`; `scripts/test/eval_typed_resource_mixed.sh`
- Evidence proofs: `src/LeanCairo/Compiler/Semantics/Eval.lean`; `src/LeanCairo/Compiler/Semantics/TypedValue.lean`; `src/LeanCairo/Compiler/Semantics/ValueDomain.lean`; `tests/lean/eval_integer_width_semantics.lean`; `tests/lean/eval_qm31_semantics.lean`
- Acceptance tests:
1. Integer width/sign semantics tests pass.
2. Field-domain semantics tests (`qm31` and related) pass.
3. No integer family aliases another storage domain in evaluator.

### TYC-3 Conversion and cast legality closure
- Status: NOT DONE
- Acceptance tests:
1. Conversion legality matrix is enforced.
2. Invalid cast paths fail fast with stable diagnostics.
3. Differential conversion behavior matches semantic oracle.

### TYC-4 Aggregate and wrapper semantics closure
- Status: NOT DONE
- Acceptance tests:
1. Tuple/struct/enum semantic law tests pass.
2. Wrapper semantics (nullable/box/nonzero) tests pass.
3. Collection element typing invariants pass.

### TYC-5 Proof and differential closure
- Status: NOT DONE
- Acceptance tests:
1. Type-family proof obligations compile.
2. Evaluator/Sierra/Cairo differential suites pass for closed families.
3. Proof debt entries are bounded and linked.

## Global strict acceptance tests

1. `scripts/test/type_universe_regression.sh`
2. `scripts/test/eval_integer_width_semantics.sh`
3. `scripts/test/eval_qm31_semantics.sh`
4. `scripts/test/eval_typed_resource_mixed.sh`

## Completion criteria

1. TYC-1 through TYC-5 are `DONE - <commit>`.
2. Type semantics are explicit, complete for scope, and non-overlapping.
3. Backends consume shared type semantics without hidden coercions.
