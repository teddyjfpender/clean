# Executable Issue: `roadmap/23-verified-optimizing-compiler-escalation-plan.md`

- Source roadmap file: [`roadmap/23-verified-optimizing-compiler-escalation-plan.md`](../23-verified-optimizing-compiler-escalation-plan.md)
- Issue class: Verified optimization escalation
- Priority: P0
- Overall status: NOT DONE

## Objective

Escalate to a verified optimizing compiler pipeline for the constrained Lean subset with semantics-preserving passes and benchmark-governed performance wins.

## Implementation loci

1. `src/LeanCairo/Compiler/Optimize/**`
2. `src/LeanCairo/Compiler/Proof/**`
3. `src/LeanCairo/Backend/Sierra/**`
4. `scripts/test/optimizer_pass_regression.sh`
5. `scripts/roadmap/check_proof_obligations.sh`
6. `scripts/bench/**`
7. `roadmap/23-verified-optimizing-compiler-escalation-plan.md`

## Formal method requirements

1. Every pass has explicit legality conditions.
2. Semantics preservation obligations are tracked and checked.
3. Unproven passes are bounded by explicit debt and checker coverage.
4. Optimization claims require benchmark evidence.

## Milestone status ledger

### OPTX-1 Typed pass contract and legality framework
- Status: DONE - 5754656
- Evidence tests: `scripts/test/optimizer_contracts_regression.sh`; `scripts/test/optimizer_pass_regression.sh`; `scripts/roadmap/check_gate_manifest_sync.sh`; `scripts/workflow/run-mvp-checks.sh`
- Evidence proofs: `src/LeanCairo/Compiler/Optimize/Pass.lean`; `src/LeanCairo/Compiler/Optimize/Pipeline.lean`; `tests/lean/optimizer_contracts_regression.lean`; `config/gate-manifest.json`
- Acceptance tests:
1. Pass contract interfaces enforce declared pre/post conditions.
2. Missing legality metadata fails pass integration checks.
3. Pipeline contract checks pass.

### OPTX-2 MIR optimization expansion with proofs
- Status: DONE - 5754656
- Evidence tests: `scripts/test/optimizer_pass_regression.sh`; `scripts/test/canonicalization_regression.sh`; `scripts/roadmap/check_proof_obligations.sh`; `scripts/roadmap/check_proof_debt_policy.sh`
- Evidence proofs: `src/LeanCairo/Compiler/Optimize/Expr.lean`; `src/LeanCairo/Compiler/Optimize/CSELetNorm.lean`; `src/LeanCairo/Compiler/Proof/OptimizeSound.lean`; `src/LeanCairo/Compiler/Proof/CSELetNormSound.lean`; `roadmap/proof-debt.json`
- Acceptance tests:
1. MIR pass regression suites pass.
2. Soundness theorems compile for enabled passes.
3. Proof debt entries are linked and bounded where theorem gaps remain.

### OPTX-3 Sierra structural optimization layer
- Status: NOT DONE
- Acceptance tests:
1. Sierra transforms preserve validation and CASM compile success.
2. Differential semantic checks pass.
3. Resource legality checks pass.

### OPTX-4 CASM-aware cost-guided decisions
- Status: NOT DONE
- Acceptance tests:
1. Cost-guided decisions are reproducible.
2. Calibration and ranking checks pass policy thresholds.
3. Performance regressions are blocked by gates.

### OPTX-5 Verified optimization closure report
- Status: NOT DONE
- Acceptance tests:
1. Proof and benchmark closure report is generated.
2. Missing evidence for optimization claims fails checks.
3. Release readiness report includes optimization closure status.

## Global strict acceptance tests

1. `scripts/test/optimizer_pass_regression.sh`
2. `scripts/roadmap/check_proof_obligations.sh`
3. `scripts/bench/check_optimizer_non_regression.sh`
4. `scripts/bench/check_optimizer_family_thresholds.sh`

## Completion criteria

1. OPTX-1 through OPTX-5 are `DONE - <commit>`.
2. Optimization pipeline is legality-checked, proof-tracked, and benchmark-backed.
3. Verified optimization closure is reportable for release decisions.
