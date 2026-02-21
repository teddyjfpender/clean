# Completion Matrix

- Pinned commit: `e56055c87a9db4e3dbb91c82ccb2ea751a8dc617`
- Schema: `config/completion-matrix-schema.json`

## Data Sources

- `capability_registry`: `roadmap/capabilities/registry.json`
- `corelib_parity_trend`: `roadmap/inventory/corelib-parity-trend.json`
- `optimization_closure`: `roadmap/reports/optimization-closure-report.json`
- `release_go_no_go`: `roadmap/reports/release-go-no-go-report.json`
- `sierra_matrix`: `roadmap/inventory/sierra-coverage-matrix.json`
- `track_a_issue`: `roadmap/executable-issues/05-track-a-lean-to-sierra-functions.issue.md`
- `track_b_issue`: `roadmap/executable-issues/20-track-b-cairo-parity-and-reviewability-plan.issue.md`

## Dimensions

| Dimension | Scope | Status | Blocking gates |
| --- | --- | --- | --- |
| `program_p0_issue_closure` | `program` | `not_ready` | `scripts/roadmap/check_issue_statuses.sh`, `scripts/roadmap/check_issue_dependencies.sh`, `scripts/roadmap/check_milestone_dependencies.py` |
| `program_release_evidence_closure` | `program` | `ready` | `scripts/roadmap/check_release_reports_freshness.sh`, `scripts/roadmap/check_release_go_no_go.sh` |
| `track_a_benchmark_closure` | `lean->sierra->casm` | `ready` | `scripts/bench/check_optimizer_non_regression.sh`, `scripts/bench/check_optimizer_family_thresholds.sh` |
| `track_a_family_closure` | `lean->sierra->casm` | `ready` | `scripts/roadmap/check_sierra_primary_closure.sh`, `scripts/roadmap/check_sierra_coverage_report_freshness.sh` |
| `track_a_optimization_closure` | `lean->sierra->casm` | `ready` | `scripts/roadmap/check_optimization_closure_report.sh`, `scripts/roadmap/check_release_go_no_go.sh` |
| `track_a_proof_closure` | `lean->sierra->casm` | `ready` | `scripts/roadmap/check_proof_obligations.sh`, `scripts/roadmap/check_release_go_no_go.sh` |
| `track_b_divergence_contract_closure` | `lean->cairo` | `ready` | `scripts/roadmap/check_capability_registry.sh`, `scripts/roadmap/check_capability_obligations.sh` |
| `track_b_parity_closure` | `lean->cairo` | `ready` | `scripts/roadmap/check_corelib_parity_freshness.sh`, `scripts/roadmap/check_corelib_parity_trend.sh` |
| `track_b_purity_closure` | `lean->cairo` | `ready` | `scripts/test/sierra_primary_without_cairo.sh`, `scripts/test/sierra_primary_cairo_coupling_guard.sh` |
| `track_b_reviewability_closure` | `lean->cairo` | `ready` | `scripts/test/sierra_review_lift.sh`, `scripts/test/sierra_review_lift_complex.sh` |

## Diagnostics

### `program_p0_issue_closure`
- 25-full-function-compiler-completion-matrix.issue.md
