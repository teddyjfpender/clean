# Executable Issue: `roadmap/00-charter-and-completion-definition.md`

- Source roadmap file: [`roadmap/00-charter-and-completion-definition.md`](../00-charter-and-completion-definition.md)
- Issue class: Definition of done and governance
- Priority: P0
- Overall status: DONE - 9d1b150
- Completion evidence tests: `scripts/roadmap/check_completion_contract.sh --track primary`; `scripts/roadmap/check_completion_contract.sh --track secondary`; `scripts/roadmap/check_issue_evidence.sh`; `scripts/roadmap/check_failfast_policy_lock.sh`
- Completion evidence proofs: `src/LeanCairo/Compiler/Proof/OptimizeSound.lean`

## Objective

Enforce a strict completion contract for both tracks so "supported" claims require implementation, formal obligations, tests, and reproducible evidence.

## Implementation loci

1. `docs/specification-compliance.md`
2. `scripts/workflow/run-mvp-checks.sh`
3. `scripts/workflow/run-sierra-checks.sh`
4. `scripts/roadmap/check_completion_contract.sh` (new)
5. `roadmap/executable-issues/**/*.issue.md`

## Formal method requirements

1. Completion predicates must be explicit boolean checks.
2. Predicates must include: coverage, proofs, tests, performance gates.
3. Unsupported features must be encoded as fail-fast obligations, not implied behavior.

## Milestones

### M-00-1: Encode completion predicates
- Status: DONE - 9d1b150
- Evidence tests: `scripts/roadmap/check_completion_contract.sh --track primary`; `scripts/roadmap/check_completion_contract.sh --track secondary`
- Evidence proofs: `src/LeanCairo/Compiler/Proof/OptimizeSound.lean`
- Required work:
1. Define machine-checkable predicates for primary and secondary track completion.
2. Add CLI/script to evaluate predicates.
- Acceptance tests:
1. `scripts/roadmap/check_completion_contract.sh --track primary` returns non-zero until all predicates are satisfied.
2. `scripts/roadmap/check_completion_contract.sh --track secondary` returns non-zero until all predicates are satisfied.

### M-00-2: Enforce evidence linkage
- Status: DONE - 9d1b150
- Evidence tests: `scripts/roadmap/check_issue_evidence.sh`; `scripts/workflow/run-sierra-checks.sh`; `scripts/workflow/run-mvp-checks.sh`
- Evidence proofs: `src/LeanCairo/Compiler/Proof/OptimizeSound.lean`
- Required work:
1. Require every completed item to reference test outputs and proof modules.
2. Add CI check preventing unbacked `DONE - <commit>` status changes.
- Acceptance tests:
1. Status flip to `DONE - <commit>` without evidence fails CI.
2. Evidence links resolve to existing files/commands.

### M-00-3: Fail-fast policy lock
- Status: DONE - 9d1b150
- Evidence tests: `scripts/roadmap/check_failfast_policy_lock.sh`; `scripts/test/sierra_failfast_unsupported.sh`
- Evidence proofs: `N/A`
- Required work:
1. Define canonical error-contract tests for unsupported families.
2. Gate release on those tests.
- Acceptance tests:
1. Unsupported family fixtures fail with exact messages.
2. Removing fail-fast guard causes regression test failure.

## Completion criteria

1. Completion predicates are executable and versioned.
2. Governance checks are in CI and blocking.
3. Status claims are auditable by commit and evidence.
