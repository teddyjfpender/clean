# Verified Optimizer Roadmap (Constrained Lean Subset)

Date: 2026-02-20
Status: In progress

## Scope

This step moves the project from direct generator toward a verified optimizing compiler pipeline:

1. Source DSL (`Expr`) lowers into typed IR (`IRExpr`).
2. IR-to-IR optimization pass rewrites expression trees.
3. Semantics are defined for IR evaluation.
4. Soundness theorem proves optimization preserves evaluator semantics.
5. Pipeline emits Cairo from optimized IR form by default.

## Current implemented pass

- Algebraic identity simplifications for `u128`/`u256` (`+0`, `-0`, `*0`, `*1`).
- Branch pruning for `if true` / `if false`.
- CSE + let-normalization pass:
  - shares repeated identical subexpressions for `add/mul` (`u128`, `u256`) and `eq` via explicit let-binding,
  - normalizes identity lets (`let x = e; x`) when type-safe.

## Invariants

- Optimizer does not change function signatures or mutability.
- Optimizer only rewrites expressions and write-value expressions.
- `optimizeExprSound`: evaluation of optimized IR equals evaluation of original IR for all contexts.
- Verified pass interface enforces:
  - expression-level semantic preservation (`run` + `sound`),
  - function/contract shape preservation,
  - compositional soundness through pass composition.

## Cost model and benchmark gate

- Primary metric: CASM bytecode length when available, with Sierra length as tie-breaker.
- CI gate compares optimized vs non-optimized output and rejects regressions.
- Generated Scarb manifests expose Cairo compiler inlining strategy (`default`, `avoid`, numeric bound).
- `scripts/bench/tune_inlining_strategy.sh` sweeps inlining strategies against real artifacts.
- `run-mvp-checks` now includes an explicit CSE benchmark target (`MyLeanContractCSEBench`), validating non-regression (and current improvement).

## Current architecture caveat

- Optimizer rewrites are IR-to-IR and now feed an IR-native emitter path
  (`ContractSpec -> IRContractSpec -> optimizeIRContract -> renderProjectFromIR`).
- Contract-level lowering/raising roundtrip lemmas are now implemented (`raiseLowerContractSpec`, `lowerRaiseContractSpec`).
- Contract-level optimizer soundness is now proved over function outcomes (`evalFunc`, `evalFuncSigma`).
- Remaining milestone: move toward explicit Sierra/CASM pass interfaces with validation and pass-level proof obligations.

## Next phases

1. Add storage access optimization (read reuse / load-hoisting where semantics allow).
2. Add specialization/inlining with proof obligations per pass.
3. Extend semantics to model overflow/failure behavior for closer Cairo correspondence.
4. Expand constrained Lean frontend to larger supported subset with explicit rejection diagnostics.
5. Add artifact-level verified pass framework for constrained Sierra/CASM rewrites.
