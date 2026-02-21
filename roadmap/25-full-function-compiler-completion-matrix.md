# 25. Full Function Compiler Completion Matrix

## Objective

Define final completion matrices and audit rules for declaring function-domain delivery complete for:

1. Lean -> Sierra -> CASM (primary)
2. Lean -> Cairo (secondary)

## Completion Dimensions

1. capability closure
2. semantic/proof closure
3. differential test closure
4. benchmark/performance closure
5. governance/release closure

## Completion Matrix Model

Each matrix row is:

1. `dimension_id`
2. `target_scope`
3. `required_metrics`
4. `required_artifacts`
5. `blocking_gates`
6. `status`

Status values:

1. `not_ready`
2. `conditionally_ready`
3. `ready`

## Track-A Completion Conditions

1. non-Starknet targeted family closure is complete
2. all implemented capabilities have closed proof/test obligations or approved bounded debt policy
3. Sierra validation and CASM compilation are green across corpus
4. benchmark regression gates are green across families
5. release evidence pack is complete and fresh

## Track-B Completion Conditions

1. parity coverage exists for all Track-A implemented capabilities or explicit divergence contracts
2. differential suites across evaluator/Sierra/Cairo are green
3. Cairo emission determinism and reviewability gates are green
4. Track-B does not alter Track-A compilation purity

## Program-Level Completion Conditions

1. all P0 executable issues in scope are `DONE - <commit>`
2. no unresolved critical risk controls
3. no stale required reports
4. completion certificate generated from matrix data

## Delivery Phases

### Phase AUD0: Completion matrix schema and data plumbing

1. define matrix schema and validators
2. map matrix inputs to existing reports and ledgers
3. fail on missing required fields

### Phase AUD1: Track-A audit automation

1. automate Track-A completion checks
2. produce failure diagnostics per dimension
3. gate status escalation on complete evidence

### Phase AUD2: Track-B audit automation

1. automate Track-B completion checks
2. include divergence policy validations
3. verify parity and determinism gate closure

### Phase AUD3: Program completion certificate

1. aggregate Track-A/Track-B/audit dimensions
2. generate machine-readable and human-readable certificate
3. enforce go/no-go output for release

## Required Gates

1. issue status/dependency checks
2. coverage/proof/benchmark/report freshness checks
3. release report and risk control checks
4. completion matrix validator and certificate generator checks

## Acceptance Criteria

1. Completion claims are data-backed and reproducible.
2. Track-level and program-level readiness are machine-verifiable.
3. No manual checklist can bypass automated completion gates.
4. Final completion certificate is deterministic and auditable.
