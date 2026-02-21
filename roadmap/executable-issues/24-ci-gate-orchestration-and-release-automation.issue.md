# Executable Issue: `roadmap/24-ci-gate-orchestration-and-release-automation.md`

- Source roadmap file: [`roadmap/24-ci-gate-orchestration-and-release-automation.md`](../24-ci-gate-orchestration-and-release-automation.md)
- Issue class: CI and release automation scaling
- Priority: P0
- Overall status: NOT DONE

## Objective

Automate and harden CI gate orchestration and release-governance workflows as capability scope and corpus size scale.

## Implementation loci

1. `scripts/workflow/**`
2. `scripts/roadmap/**`
3. `scripts/test/**`
4. `roadmap/reports/**`
5. `roadmap/24-ci-gate-orchestration-and-release-automation.md`

## Formal method requirements

1. Gate manifests are generated from authoritative metadata.
2. Workflow drift is detected and rejected.
3. Scaled execution remains deterministic.
4. Release go/no-go checks are evidence-backed.

## Milestone status ledger

### CIX-1 Gate manifest generation from obligations/capabilities
- Status: DONE - 6ca24b1
- Evidence tests: `scripts/roadmap/check_gate_manifest_sync.sh`; `scripts/test/gate_manifest_reproducibility.sh`; `scripts/test/gate_manifest_negative.sh`; `scripts/roadmap/list_quality_gates.sh --validate-workflows`
- Evidence proofs: `scripts/roadmap/generate_gate_manifest.py`; `config/gate-manifest.json`; `scripts/roadmap/validate_gate_manifest_workflows.py`; `roadmap/capabilities/obligations.json`; `scripts/workflow/run-sierra-checks.sh`; `scripts/workflow/run-mvp-checks.sh`
- Acceptance tests:
1. Gate manifest generation is deterministic.
2. Missing required gates are detected.
3. Manifest validation checks pass.

### CIX-2 Workflow synchronization and drift detection
- Status: DONE - 6ca24b1
- Evidence tests: `scripts/roadmap/list_quality_gates.sh --validate-workflows`; `scripts/test/gate_manifest_negative.sh`; `scripts/roadmap/check_gate_manifest_sync.sh`; `scripts/test/gate_manifest_reproducibility.sh`
- Evidence proofs: `scripts/roadmap/validate_gate_manifest_workflows.py`; `scripts/roadmap/list_quality_gates.sh`; `config/gate-manifest.json`; `scripts/workflow/run-sierra-checks.sh`; `scripts/workflow/run-mvp-checks.sh`; `scripts/workflow/run-release-candidate-checks.sh`
- Acceptance tests:
1. Workflow scripts validate against generated gate manifests.
2. Manual drift is detected and fails checks.
3. Negative drift tests pass.

### CIX-3 Deterministic scaled execution topology
- Status: DONE - b88ee2f
- Evidence tests: `scripts/roadmap/check_gate_sharding_pipeline.sh`; `scripts/test/gate_sharding_reproducibility.sh`; `scripts/test/gate_shard_aggregation_reproducibility.sh`; `scripts/test/gate_retry_determinism.sh`
- Evidence proofs: `scripts/workflow/run-gates-sharded.sh`; `scripts/workflow/aggregate_gate_shard_reports.py`; `scripts/workflow/run_gate_with_retry.sh`; `config/gate-manifest.json`; `scripts/workflow/run-sierra-checks.sh`; `scripts/workflow/run-mvp-checks.sh`
- Acceptance tests:
1. Sharded/partitioned gate execution remains deterministic.
2. Report aggregation is stable and reproducible.
3. Timeout/retry policies preserve deterministic outcomes.

### CIX-4 Release go/no-go gate automation
- Status: NOT DONE
- Acceptance tests:
1. Release gate checker aggregates closure evidence correctly.
2. Missing mandatory evidence blocks release.
3. Release readiness report generation is deterministic.

## Global strict acceptance tests

1. `./scripts/workflow/run-sierra-checks.sh`
2. `./scripts/workflow/run-mvp-checks.sh`
3. `scripts/roadmap/check_release_reports_freshness.sh`
4. `scripts/roadmap/check_issue_dependencies.sh`
5. `scripts/roadmap/check_milestone_dependencies.py`

## Completion criteria

1. CIX-1 through CIX-4 are `DONE - <commit>`.
2. CI gating scales without manual drift.
3. Release decisions are automated and auditable.
