# Executable Issue: `roadmap/22-benchmarking-cost-model-and-profiling-governance.md`

- Source roadmap file: [`roadmap/22-benchmarking-cost-model-and-profiling-governance.md`](../22-benchmarking-cost-model-and-profiling-governance.md)
- Issue class: Benchmark and cost-model governance
- Priority: P0
- Overall status: NOT DONE

## Objective

Deliver deterministic benchmarking/profiling governance and cost-model calibration workflows for optimization-safe subset expansion.

## Implementation loci

1. `scripts/bench/**`
2. `scripts/test/**`
3. `roadmap/reports/release-benchmark-report.md`
4. `roadmap/22-benchmarking-cost-model-and-profiling-governance.md`
5. `examples/Benchmark/**`

## Formal method requirements

1. Benchmarks are same-signature and semantics-aligned.
2. Parsing/report generation is deterministic.
3. Cost model changes require calibration artifacts.
4. Family-level thresholds are enforced in CI.

## Milestone status ledger

### BEN-1 Benchmark schema and runner normalization
- Status: NOT DONE
- Acceptance tests:
1. Benchmark manifest validation passes for all corpus items.
2. Runner outputs are deterministic across repeated runs.
3. Parse/report scripts reject malformed logs.

### BEN-2 Profiling pipeline closure
- Status: NOT DONE
- Acceptance tests:
1. Baseline/generated profile artifacts are produced for configured items.
2. Hotspot summaries are generated reproducibly.
3. Profile artifact freshness checks pass.

### BEN-3 Cost-model calibration bootstrap
- Status: NOT DONE
- Acceptance tests:
1. Calibration datasets and outputs are reproducible.
2. Versioned calibration artifacts are generated.
3. Prediction-vs-measurement checks pass policy thresholds.

### BEN-4 Family threshold gate hardening
- Status: NOT DONE
- Acceptance tests:
1. Per-family non-regression thresholds are enforced.
2. Threshold regressions fail CI deterministically.
3. False-positive control tests pass.

### BEN-5 Release benchmark dossier generation
- Status: NOT DONE
- Acceptance tests:
1. Release benchmark report includes family deltas and hotspots.
2. Missing benchmark evidence for promoted capabilities fails checks.
3. Report freshness checks pass.

## Global strict acceptance tests

1. `scripts/bench/check_optimizer_non_regression.sh`
2. `scripts/bench/check_optimizer_family_thresholds.sh`
3. `scripts/roadmap/check_release_reports_freshness.sh`

## Completion criteria

1. BEN-1 through BEN-5 are `DONE - <commit>`.
2. Benchmark claims are reproducible and audit-ready.
3. Cost model evolution is evidence-backed and policy-gated.
