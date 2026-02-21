# Executable Issue: `roadmap/25-full-function-compiler-completion-matrix.md`

- Source roadmap file: [`roadmap/25-full-function-compiler-completion-matrix.md`](../25-full-function-compiler-completion-matrix.md)
- Issue class: Final completion audit and certification
- Priority: P0
- Overall status: NOT DONE

## Objective

Deliver machine-verifiable completion audits and certification for function-domain delivery across Track A and Track B.

## Implementation loci

1. `roadmap/25-full-function-compiler-completion-matrix.md`
2. `roadmap/reports/**`
3. `scripts/roadmap/**`
4. `scripts/workflow/**`
5. `roadmap/executable-issues/**`

## Formal method requirements

1. Completion status is derived from machine-validated metrics and evidence.
2. Track-A and Track-B completion predicates are explicit and checkable.
3. Program-level completion cannot be declared without closure gates.

## Milestone status ledger

### AUD-1 Completion matrix schema and data sources
- Status: DONE - b167c8b
- Evidence tests: `scripts/roadmap/check_completion_matrix.sh`; `scripts/roadmap/validate_completion_matrix.py --schema config/completion-matrix-schema.json --matrix roadmap/reports/completion-matrix.json`; `scripts/roadmap/check_gate_manifest_sync.sh`; `scripts/roadmap/list_quality_gates.sh --validate-workflows`
- Evidence proofs: `config/completion-matrix-schema.json`; `scripts/roadmap/generate_completion_matrix.py`; `scripts/roadmap/validate_completion_matrix.py`; `roadmap/reports/completion-matrix.json`; `roadmap/reports/completion-matrix.md`; `config/gate-manifest.json`
- Acceptance tests:
1. Completion matrix schema validates required fields.
2. Missing required data sources fail checks.
3. Matrix generation is deterministic.

### AUD-2 Track-A completion audit automation
- Status: DONE - ab1a6e6
- Evidence tests: `scripts/roadmap/check_track_a_completion_audit.sh`; `scripts/roadmap/check_completion_matrix.sh`; `scripts/roadmap/check_gate_manifest_sync.sh`; `scripts/roadmap/list_quality_gates.sh --validate-workflows`
- Evidence proofs: `scripts/roadmap/generate_track_a_completion_audit.py`; `scripts/roadmap/check_track_a_completion_audit.sh`; `roadmap/reports/track-a-completion-audit.json`; `roadmap/reports/track-a-completion-audit.md`; `roadmap/reports/completion-matrix.json`
- Acceptance tests:
1. Track-A closure predicates are validated automatically.
2. Missing family/proof/benchmark closure fails audit.
3. Audit diagnostics are reproducible.

### AUD-3 Track-B completion audit automation
- Status: DONE - a6e6422
- Evidence tests: `scripts/roadmap/check_track_b_completion_audit.sh`; `scripts/roadmap/check_corelib_parity_trend.sh`; `scripts/roadmap/check_capability_registry.sh`; `scripts/roadmap/check_gate_manifest_sync.sh`
- Evidence proofs: `scripts/roadmap/generate_track_b_completion_audit.py`; `scripts/roadmap/check_track_b_completion_audit.sh`; `roadmap/reports/track-b-completion-audit.json`; `roadmap/reports/track-b-completion-audit.md`; `roadmap/capabilities/registry.json`
- Acceptance tests:
1. Track-B parity/reviewability predicates are validated automatically.
2. Undocumented divergence blocks completion.
3. Audit diagnostics are reproducible.

### AUD-4 Program completion certificate
- Status: NOT DONE
- Acceptance tests:
1. Completion certificate generation is deterministic.
2. Certificate is blocked if any mandatory dimension is not ready.
3. Certificate includes evidence links and closure summaries.

## Global strict acceptance tests

1. `scripts/roadmap/check_issue_statuses.sh`
2. `scripts/roadmap/check_issue_dependencies.sh`
3. `scripts/roadmap/check_milestone_dependencies.py`
4. `scripts/roadmap/check_release_reports_freshness.sh`
5. `./scripts/workflow/run-sierra-checks.sh`
6. `./scripts/workflow/run-mvp-checks.sh`

## Completion criteria

1. AUD-1 through AUD-4 are `DONE - <commit>`.
2. Completion claims are fully automated and evidence-backed.
3. Final certification is reproducible and audit-ready.
