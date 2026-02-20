# Executable Issue: `roadmap/03-typed-ir-generalization-plan.md`

- Source roadmap file: [`roadmap/03-typed-ir-generalization-plan.md`](../03-typed-ir-generalization-plan.md)
- Issue class: MIR generalization
- Priority: P0
- Overall status: NOT DONE

## Objective

Generalize MIR to express full function-level semantics required by pinned Sierra/corelib surfaces while preserving strict typing and effect/resource explicitness.

## Implementation loci

1. `src/LeanCairo/Compiler/IR/Expr.lean`
2. `src/LeanCairo/Compiler/IR/Spec*.lean`
3. `src/LeanCairo/Core/Syntax/Expr.lean`
4. `src/LeanCairo/Core/Validation/*.lean`
5. `src/LeanCairo/Compiler/IR/Lowering.lean`
6. `src/LeanCairo/Compiler/Semantics/*.lean`

## Formal method requirements

1. New MIR constructors must have type-indexed safety (no erased type tags).
2. Effects/resources are typed data, not conventions.
3. Normal forms must be deterministic and explicitly specified.

## Milestones

### M-03-1: Type universe expansion
- Status: DONE - ef4b922
- Evidence tests: `scripts/test/type_universe_regression.sh`; `scripts/workflow/run-sierra-checks.sh`; `scripts/workflow/run-mvp-checks.sh`
- Evidence proofs: `src/LeanCairo/Compiler/Proof/OptimizeSound.lean`; `src/LeanCairo/Compiler/Proof/CSELetNormSound.lean`
- Required work:
1. Add generic scalar/compound types and wrappers.
2. Preserve exhaustive pattern matching across compiler stages.
- Acceptance tests:
1. `~/.elan/bin/lake build` with no non-exhaustive warnings.
2. Constructor-specific regression tests added for every new family.

### M-03-2: Effect/resource MIR
- Status: DONE - 41dae18
- Evidence tests: `scripts/roadmap/check_effect_isolation.sh`; `scripts/test/effect_resource_regression.sh`; `scripts/workflow/run-mvp-checks.sh`
- Evidence proofs: `src/LeanCairo/Compiler/Semantics/Eval.lean`; `src/LeanCairo/Compiler/IR/Lowering.lean`
- Required work:
1. Add typed effect/resource carriers (range-check, gas, arena, panic channel).
2. Thread effects explicitly in evaluators/lowering.
- Acceptance tests:
1. Hidden global effect usage check (grep/static check) returns zero violations.
2. Evaluator tests cover resource-sensitive expressions.

### M-03-3: Canonical form and ANF policies
- Status: NOT DONE
- Required work:
1. Define canonicalization algorithm and laws.
2. Integrate deterministic normalization pass.
- Acceptance tests:
1. Snapshot stability over repeated normalization passes.
2. Idempotence test: `normalize (normalize e) = normalize e` for test corpus.

## Completion criteria

1. MIR supports targeted families without backend leakage.
2. Effects/resources are explicit and test-covered.
3. Canonicalization is deterministic and law-checked.
