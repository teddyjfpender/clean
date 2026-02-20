# Typed Pass Interface + CSE/Let-Normalization

Date: 2026-02-20
Status: Implemented

## 1. Scope

Add a formally typed optimizer pass interface with explicit semantic obligations, then implement a non-trivial IR pass (CSE + let-normalization) and run benchmark gates over generated Sierra/CASM artifacts.

## 2. Interface contract

Location: `src/LeanCairo/Compiler/Optimize/Pass.lean`

`VerifiedExprPass` requires:

- `run : {ty : Ty} -> IRExpr ty -> IRExpr ty`
- `sound : ∀ ctx expr, evalExpr ctx (run expr) = evalExpr ctx expr`

Derived application functions:

- `applyStorageWrite`
- `applyFuncSpec`
- `applyContract`

Derived invariants and obligations:

- Storage-write shape preservation (`field`, `ty`)
- Function interface preservation (`name`, `args`, `ret`, `mutability`, write count)
- Contract shape preservation (`contractName`, `storage`, function count)
- Function/contract semantic preservation under `evalFunc` / `evalFuncSigma`

Composition:

- `compose : VerifiedExprPass -> VerifiedExprPass -> VerifiedExprPass`
- `composeMany : List VerifiedExprPass -> VerifiedExprPass`
- Soundness is algebraically compositional by construction.

## 3. Implemented passes

Pipeline location: `src/LeanCairo/Compiler/Optimize/Pipeline.lean`

Passes:

1. `algebraic-fold` (`Optimize.Expr`)
2. `cse-let-normalization` (`Optimize.CSELetNorm`)

Current order:

- `algebraic-fold |> cse-let-normalization`

## 4. CSE + let-normalization behavior

Location: `src/LeanCairo/Compiler/Optimize/CSELetNorm.lean`

Rewrites:

- CSE for repeated operands:
  - `addU128(e, e)`, `mulU128(e, e)`
  - `addU256(e, e)`, `mulU256(e, e)`
  - `eq(e, e)` for any supported scalar type
- Identity let normalization:
  - `let x = e; x` -> `e` (guarded by type equality to remain total and typed)

Soundness proof:

- `src/LeanCairo/Compiler/Proof/CSELetNormSound.lean`

## 5. Contract-level soundness integration

`optimizeIRContract` now applies `optimizerPass.applyContract`.

Proof module:

- `src/LeanCairo/Compiler/Proof/IRSpecSound.lean`

`optimizeIRContractSound` is derived via the generic pass-interface theorems.

## 6. Benchmark gate coverage

General non-regression gate:

- `scripts/bench/check_optimizer_non_regression.sh`

CSE-focused benchmark target:

- module: `MyLeanContractCSEBench`
- contract: `CSEBenchContract`
- sources: `src/Examples/CSEBench.lean`, `src/MyLeanContractCSEBench.lean`

Workflow integration:

- `scripts/workflow/run-mvp-checks.sh` runs both baseline and CSE-focused benchmark gates.
