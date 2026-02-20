# Executable Issue: `roadmap/08-quality-gates-bench-and-release.md`

- Source roadmap file: [`roadmap/08-quality-gates-bench-and-release.md`](../08-quality-gates-bench-and-release.md)
- Issue class: Quality and release enforcement
- Priority: P0
- Overall status: NOT DONE

## Objective

Define and enforce deterministic quality gates so release claims are mechanically verified.

## Implementation loci

1. `scripts/lint/pedantic.sh`
2. `scripts/workflow/run-mvp-checks.sh`
3. `scripts/workflow/run-sierra-checks.sh`
4. `scripts/test/**`
5. `scripts/bench/**`
6. `.github/workflows/**` (if/when CI pipelines are expanded)

## Formal method requirements

1. Every gate has explicit pass/fail predicates.
2. Fast/full/release lanes are disjoint and documented.
3. Release candidate checks are reproducible locally.

## Milestones

### Q1 Gate taxonomy implementation
- Status: DONE - 1607761
- Acceptance tests:
1. `scripts/roadmap/list_quality_gates.sh` enumerates all mandatory gates.
2. Missing required gate in workflow triggers failure.

### Q2 Differential and failure-mode suites
- Status: DONE - 1607761
- Acceptance tests:
1. Differential test suite exists and is deterministic.
2. Fail-fast suite covers all unsupported families and exact messages.

### Q3 Release artifact reports
- Status: DONE - 1607761
- Acceptance tests:
1. Compatibility report is generated and versioned.
2. Proof report is generated and versioned.
3. Benchmark report is generated and versioned.

## Global strict acceptance tests

1. `./scripts/workflow/run-mvp-checks.sh`
2. `./scripts/workflow/run-sierra-checks.sh`
3. Release lane script (to be implemented): `scripts/workflow/run-release-candidate-checks.sh`

## Completion criteria

1. All release predicates are executable scripts.
2. All reports are generated from source artifacts, not manual text.
3. Release lane is stable and blocking.
