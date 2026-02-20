# Executable Issue: `roadmap/11-evaluator-type-domain-separation.md`

- Source roadmap file: [`roadmap/11-evaluator-type-domain-separation.md`](../11-evaluator-type-domain-separation.md)
- Issue class: Evaluator semantics closure
- Priority: P0
- Overall status: DONE - 9461b3d
- Completion evidence tests: `scripts/workflow/run-sierra-checks.sh`; `scripts/workflow/run-mvp-checks.sh`; `scripts/roadmap/check_proof_obligations.sh`
- Completion evidence proofs: `src/LeanCairo/Compiler/Semantics/Eval.lean`; `src/LeanCairo/Compiler/Proof/CSELetNormSound.lean`

## Objective

Deliver a type-faithful, fail-fast evaluator semantics layer that is suitable for formal optimization and lowering proofs, with no cross-family aliasing.

## Implementation loci

1. `src/LeanCairo/Compiler/Semantics/Eval.lean`
2. `src/LeanCairo/Compiler/Semantics/ContractEval.lean`
3. `src/LeanCairo/Core/Domain/Ty.lean`
4. `src/LeanCairo/Compiler/Proof/*.lean`
5. `tests/lean/*.lean`
6. `scripts/test/*.sh`
7. `scripts/roadmap/check_proof_obligations.sh`
8. `scripts/workflow/run-sierra-checks.sh`
9. `scripts/workflow/run-mvp-checks.sh`

## Formal method requirements

1. Read/write semantics are type-indexed and non-interfering across families.
2. Unsupported domains are explicit errors in strict evaluator paths.
3. Evaluator laws are machine-checked and required by CI.

## Milestone status ledger

### E1 Typed scalar variable/storage separation
- Status: DONE - 8beef38
- Evidence tests: `~/.elan/bin/lake build LeanCairo.Compiler.Semantics.Eval`; `scripts/test/eval_scalar_domain_isolation.sh`; `scripts/test/semantic_state_regression.sh`
- Evidence proofs: `src/LeanCairo/Compiler/Semantics/Eval.lean`
- Required work:
1. Add separate variable and storage slots for each scalar family (`felt252`, `bool`, `u128`, `u256`, `u8/u16/u32/u64`, `i8/i16/i32/i64/i128`, `qm31`).
2. Remove all scalar-family collapsing in evaluator read/bind functions.
3. Add deterministic regression tests proving no cross-family aliasing.
- Acceptance tests:
1. `~/.elan/bin/lake build LeanCairo.Compiler.Semantics.Eval`
2. `scripts/test/eval_scalar_domain_isolation.sh`
3. `scripts/test/semantic_state_regression.sh`

### E2 Fail-fast unsupported-domain evaluator interfaces
- Status: DONE - 272ee40
- Evidence tests: `scripts/test/eval_unsupported_domain_failfast.sh`; `scripts/roadmap/check_failfast_policy_lock.sh`; `scripts/test/proof_obligations_negative.sh`
- Evidence proofs: `src/LeanCairo/Compiler/Semantics/Eval.lean`; `src/LeanCairo/Compiler/Semantics/ContractEval.lean`
- Required work:
1. Add strict fail-fast evaluator API returning `Except String` for unsupported domains.
2. Emit stable error contracts that include type/family context.
3. Add negative tests for deterministic unsupported-domain failure behavior.
- Acceptance tests:
1. `scripts/test/eval_unsupported_domain_failfast.sh`
2. `scripts/roadmap/check_failfast_policy_lock.sh`
3. `scripts/test/proof_obligations_negative.sh`

### E3 Width/sign semantics closure for integer and qm31 families
- Status: DONE - fbb51b0
- Evidence tests: `scripts/test/eval_integer_width_semantics.sh`; `scripts/test/eval_qm31_semantics.sh`; `scripts/workflow/run-sierra-checks.sh`
- Evidence proofs: `src/LeanCairo/Compiler/Semantics/Eval.lean`; `src/LeanCairo/Compiler/Proof/OptimizeSound.lean`
- Required work:
1. Define width/sign semantics modules for signed and unsigned integer families.
2. Define `qm31` domain semantics with explicit arithmetic policy.
3. Add boundary and overflow/regression corpus per family.
- Acceptance tests:
1. `scripts/test/eval_integer_width_semantics.sh`
2. `scripts/test/eval_qm31_semantics.sh`
3. `scripts/workflow/run-sierra-checks.sh`

### E4 Resource/failure integration over typed domains
- Status: DONE - cd45c22
- Evidence tests: `scripts/test/semantic_state_regression.sh`; `scripts/test/effect_resource_regression.sh`; `scripts/roadmap/check_effect_isolation.sh`
- Evidence proofs: `src/LeanCairo/Compiler/Semantics/Eval.lean`; `src/LeanCairo/Compiler/Proof/CSELetNormSound.lean`
- Required work:
1. Prove typed-domain refactors preserve resource/failure state transitions.
2. Add mixed workloads exercising typed state + resource channels.
3. Verify no hidden resource coupling in evaluator domain operations.
- Acceptance tests:
1. `scripts/test/semantic_state_regression.sh`
2. `scripts/test/effect_resource_regression.sh`
3. `scripts/roadmap/check_effect_isolation.sh`

### E5 Proof/CI closure and dependency gating
- Status: DONE - 9461b3d
- Evidence tests: `scripts/roadmap/check_proof_obligations.sh`; `scripts/roadmap/check_milestone_dependencies.py`; `scripts/workflow/run-mvp-checks.sh`
- Evidence proofs: `src/LeanCairo/Compiler/Semantics/Eval.lean`; `scripts/roadmap/check_milestone_dependencies.py`
- Required work:
1. Add evaluator non-interference and fail-fast law theorems to mandatory proof checks.
2. Integrate evaluator gate scripts into Sierra and MVP workflows.
3. Add milestone dependencies so Track-A completion cannot bypass evaluator closure.
- Acceptance tests:
1. `scripts/roadmap/check_proof_obligations.sh`
2. `scripts/roadmap/check_milestone_dependencies.py`
3. `scripts/workflow/run-mvp-checks.sh`

## Global strict acceptance tests

1. `scripts/workflow/run-sierra-checks.sh`
2. `scripts/workflow/run-mvp-checks.sh`
3. `scripts/roadmap/check_issue_statuses.sh`
4. `scripts/roadmap/check_issue_dependencies.sh`
5. `scripts/roadmap/check_milestone_dependencies.py`

## Completion criteria

1. E1-E5 milestones are `DONE - <commit>`.
2. No scalar-domain collapsing remains in evaluator context logic.
3. Unsupported-domain behavior is fail-fast and test-gated.
4. Track-A status progression is dependency-gated on this issue.
