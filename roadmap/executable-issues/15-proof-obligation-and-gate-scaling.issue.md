# Executable Issue: `roadmap/15-proof-obligation-and-gate-scaling.md`

- Source roadmap file: [`roadmap/15-proof-obligation-and-gate-scaling.md`](../15-proof-obligation-and-gate-scaling.md)
- Issue class: Formal closure and gate automation scaling
- Priority: P0
- Overall status: NOT DONE

## Objective

Automate proof obligation tracking and quality gate synthesis so subset growth remains formally controlled as capability count and complexity increase.

## Implementation loci

1. `roadmap/15-proof-obligation-and-gate-scaling.md`
2. `roadmap/proof-debt.json`
3. `scripts/roadmap/check_proof_obligations.sh`
4. `scripts/roadmap/check_issue_evidence.sh`
5. `scripts/workflow/run-sierra-checks.sh`
6. `scripts/workflow/run-mvp-checks.sh`
7. `src/LeanCairo/Compiler/Proof/**`
8. `roadmap/reports/**`

## Formal method requirements

1. Implemented capabilities must map to explicit proof/test/benchmark obligations.
2. Proof debt is versioned, bounded, and linked to capability IDs.
3. Workflow gate lists are generated from obligation metadata, not manually drifted.
4. Promotion from fail-fast to implemented is blocked until obligations close.

## Milestone status ledger

### LPA-1 Capability-to-obligation schema and validator
- Status: DONE - db61737
- Evidence tests: `scripts/roadmap/check_capability_obligations.sh`; `scripts/test/capability_obligations_reproducibility.sh`; `scripts/test/capability_obligations_negative.sh`; `scripts/roadmap/list_quality_gates.sh --validate-workflows`
- Evidence proofs: `roadmap/capabilities/obligations.json`; `scripts/roadmap/validate_capability_obligations.py`; `scripts/roadmap/project_capability_obligations.py`; `roadmap/inventory/capability-obligation-report.json`; `roadmap/inventory/capability-obligation-report.md`; `scripts/workflow/run-sierra-checks.sh`; `scripts/workflow/run-mvp-checks.sh`
- Acceptance tests:
1. Missing obligation entries for implemented capabilities fail validation.
2. Invalid proof/test/benchmark references fail validation.
3. Obligation projections are deterministic.

### LPA-2 Gate manifest generation and workflow sync
- Status: DONE - 6ca24b1
- Evidence tests: `scripts/roadmap/check_gate_manifest_sync.sh`; `scripts/test/gate_manifest_reproducibility.sh`; `scripts/test/gate_manifest_negative.sh`; `scripts/roadmap/list_quality_gates.sh --validate-workflows`
- Evidence proofs: `config/gate-manifest.json`; `scripts/roadmap/generate_gate_manifest.py`; `scripts/roadmap/validate_gate_manifest_workflows.py`; `scripts/roadmap/list_quality_gates.sh`; `scripts/workflow/run-sierra-checks.sh`; `scripts/workflow/run-mvp-checks.sh`
- Acceptance tests:
1. Gate manifest generation reproduces workflow gate sets deterministically.
2. Manual workflow drift from generated manifests is detected.
3. Negative tests prove missing required gates fail CI.

### LPA-3 Proof debt policy enforcement
- Status: DONE - 6d70e98
- Evidence tests: `scripts/roadmap/check_proof_debt_policy.sh`; `scripts/test/proof_debt_policy_negative.sh`; `scripts/roadmap/check_gate_manifest_sync.sh`; `scripts/roadmap/list_quality_gates.sh --validate-workflows`
- Evidence proofs: `roadmap/proof-debt.json`; `scripts/roadmap/check_proof_debt_policy.py`; `scripts/roadmap/check_proof_debt_policy.sh`; `config/gate-manifest.json`; `scripts/roadmap/generate_gate_manifest.py`; `scripts/workflow/run-sierra-checks.sh`; `scripts/workflow/run-mvp-checks.sh`
- Acceptance tests:
1. Proof debt entries require capability linkage and expiry metadata.
2. Expired exception/debt entries fail CI.
3. Promotion attempts with unresolved mandatory debt fail CI.

### LPA-4 Release evidence pack hard gate
- Status: NOT DONE
- Acceptance tests:
1. Release reports include capability closure, proof closure, and benchmark closure sections.
2. Missing evidence links for done milestones fail release check.
3. Final go/no-go gate enforces closure thresholds.

## Global strict acceptance tests

1. `scripts/roadmap/check_proof_obligations.sh`
2. `scripts/test/proof_obligations_negative.sh`
3. `scripts/roadmap/check_issue_evidence.sh`
4. `scripts/roadmap/check_release_reports_freshness.sh`
5. `scripts/workflow/run-sierra-checks.sh`
6. `scripts/workflow/run-mvp-checks.sh`

## Completion criteria

1. LPA-1 through LPA-4 are `DONE - <commit>`.
2. Capability promotion is impossible without closed obligations.
3. Proof/test/benchmark governance scales with subset growth without manual drift.
