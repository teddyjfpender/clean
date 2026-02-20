# Executable Issue: `roadmap/07-low-level-optimization-sierra-casm.md`

- Source roadmap file: [`roadmap/07-low-level-optimization-sierra-casm.md`](../07-low-level-optimization-sierra-casm.md)
- Issue class: Optimization program
- Priority: P0
- Overall status: NOT DONE

## Objective

Deliver verified and benchmarked optimization from MIR through Sierra/CASM-relevant representations.

## Implementation loci

1. `src/LeanCairo/Compiler/Optimize/**`
2. `src/LeanCairo/Compiler/Proof/**`
3. `scripts/bench/**`
4. `tools/sierra_toolchain/**`
5. `docs/fixed-point/**` and benchmark docs

## Formal method requirements

1. Each pass has explicit legality conditions.
2. Passes must preserve semantics under declared preconditions.
3. Gas/AP/resource-sensitive transformations require side-condition checks.

## Milestones

### O1 MIR optimization expansion
- Status: DONE - c8594bb
- Evidence tests: `scripts/test/optimizer_pass_regression.sh`; `scripts/test/canonicalization_regression.sh`; `scripts/roadmap/check_proof_obligations.sh`
- Evidence proofs: `src/LeanCairo/Compiler/Optimize/Pipeline.lean`; `src/LeanCairo/Compiler/Proof/OptimizeSound.lean`; `src/LeanCairo/Compiler/Proof/CSELetNormSound.lean`
- Acceptance tests:
1. New pass unit tests and property tests pass.
2. Soundness theorems compile for enabled passes.

### O2 Sierra-level optimization layer
- Status: NOT DONE
- Acceptance tests:
1. Sierra structural transforms preserve validation and compilation success.
2. Differential semantic tests remain green.

### O3 Cost model calibration
- Status: NOT DONE
- Acceptance tests:
1. Cost model reproduces ranking on benchmark corpus.
2. Calibration artifacts are versioned and reproducible.

### O4 Benchmark gate hardening
- Status: NOT DONE
- Acceptance tests:
1. Non-regression gate is strict and deterministic.
2. Per-family regression thresholds enforced in CI.

## Global strict acceptance tests

1. `./scripts/bench/check_optimizer_non_regression.sh`
2. `./scripts/bench/compare_fixedpoint_steps.sh`
3. `./scripts/workflow/run-mvp-checks.sh`

## Completion criteria

1. Optimization claims are evidence-backed.
2. Regression gating is comprehensive for core families.
3. Proof and benchmark reports are linked for every major pass change.
