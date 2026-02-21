# Executable Issue: `roadmap/21-function-corpus-and-baseline-expansion-program.md`

- Source roadmap file: [`roadmap/21-function-corpus-and-baseline-expansion-program.md`](../21-function-corpus-and-baseline-expansion-program.md)
- Issue class: Corpus and baseline expansion
- Priority: P0
- Overall status: NOT DONE

## Objective

Build a manifest-driven complex function corpus program with baseline ingestion, vector generation, and capability-linked coverage reporting.

## Implementation loci

1. `config/examples-manifest.json`
2. `examples/**`
3. `scripts/examples/**`
4. `scripts/test/examples_structure.sh`
5. `scripts/test/sierra_differential.sh`
6. `scripts/test/backend_parity.sh`
7. `roadmap/21-function-corpus-and-baseline-expansion-program.md`

## Formal method requirements

1. Corpus and baseline generation is reproducible.
2. Baseline provenance and patching is explicit.
3. Capability promotion requires linked corpus evidence.

## Milestone status ledger

### COR-1 Unified corpus manifest schema and validation
- Status: DONE - ce15de6
- Evidence tests: `scripts/roadmap/check_examples_manifest_schema.sh`; `scripts/examples/generate_examples.sh`; `scripts/test/examples_structure.sh`; `scripts/test/examples_manifest_mirror_negative.sh`; `scripts/test/examples_regeneration_deterministic.sh`
- Evidence proofs: `config/examples-manifest.json`; `scripts/examples/validate_examples_manifest.py`; `scripts/examples/generate_examples.sh`; `examples/README.md`; `scripts/roadmap/list_quality_gates.sh`
- Acceptance tests:
1. Manifest validates corpus, baseline, benchmark, and capability mapping fields.
2. Missing mirror artifacts fail structure checks.
3. Regeneration is deterministic.

### COR-2 Baseline ingestion and patch governance
- Status: DONE - d272d36
- Evidence tests: `scripts/roadmap/check_baseline_provenance.sh`; `scripts/test/baseline_sync_reproducibility.sh`; `scripts/test/baseline_provenance_negative.sh`; `scripts/roadmap/list_quality_gates.sh --validate-workflows`
- Evidence proofs: `config/baselines-manifest.json`; `scripts/examples/validate_baselines_manifest.py`; `scripts/examples/sync_baselines.sh`; `scripts/examples/sync_baseline_from_github.sh`; `scripts/examples/apply_baseline_patches.sh`; `examples/Cairo-Baseline/README.md`; `examples/README.md`; `scripts/workflow/run-sierra-checks.sh`; `scripts/workflow/run-mvp-checks.sh`
- Acceptance tests:
1. Baseline pull/sync scripts are reproducible and pinned.
2. Baseline patches are scripted and justified.
3. Provenance metadata checks pass.

### COR-3 Differential vector generation and replay tooling
- Status: DONE - 4ca44aa
- Evidence tests: `scripts/roadmap/check_differential_harness_sync.sh`; `scripts/test/differential_harness_reproducibility.sh`; `scripts/test/examples_differential_vectors_negative.sh`; `scripts/test/backend_parity.sh`
- Evidence proofs: `scripts/examples/generate_differential_harness.py`; `generated/examples/differential-harness.json`; `scripts/test/generated/run_manifest_differential.sh`; `scripts/test/run_backend_parity_case.sh`; `config/examples-manifest.json`
- Acceptance tests:
1. Equivalence vectors generate deterministically.
2. Boundary/failure vectors are generated per capability class.
3. Replay tooling reproduces mismatches.

### COR-4 Complex kernel pack expansion
- Status: DONE - 9ffe25e
- Evidence tests: `scripts/roadmap/check_corpus_coverage_report_sync.sh`; `scripts/test/corpus_coverage_reproducibility.sh`; `scripts/test/examples_structure.sh`; `scripts/test/backend_parity.sh`
- Evidence proofs: `config/examples-manifest.json`; `generated/examples/corpus-coverage-report.json`; `generated/examples/corpus-coverage-report.md`; `scripts/examples/generate_corpus_coverage_report.py`; `examples/Lean/aggregate_payload_mix/Example.lean`; `examples/Lean/circuit_gate_felt/Example.lean`; `examples/Lean/crypto_round_felt/Example.lean`
- Acceptance tests:
1. Medium/high complexity kernels exist across all planned family domains.
2. Generated and baseline paths remain signature-aligned.
3. Complex corpus differential suites pass.

### COR-5 Corpus-capability coverage reporting
- Status: DONE - 83bcc1f
- Evidence tests: `scripts/roadmap/check_corpus_coverage_report_sync.sh`; `scripts/roadmap/check_corpus_coverage_trend_sync.sh`; `scripts/test/corpus_coverage_reproducibility.sh`; `scripts/test/corpus_coverage_trend_reproducibility.sh`; `scripts/test/corpus_coverage_negative.sh`
- Evidence proofs: `scripts/examples/generate_corpus_coverage_report.py`; `scripts/examples/generate_corpus_coverage_trend.py`; `generated/examples/corpus-coverage-report.json`; `generated/examples/corpus-coverage-report.md`; `generated/examples/corpus-coverage-trend.json`; `generated/examples/corpus-coverage-trend.md`; `roadmap/capabilities/corpus-coverage-trend-baseline.json`; `config/examples-manifest.json`; `roadmap/capabilities/registry.json`
- Acceptance tests:
1. Coverage report maps implemented capabilities to corpus items.
2. Missing coverage for implemented capabilities fails checks.
3. Coverage trend reports are generated and fresh.

## Global strict acceptance tests

1. `./scripts/examples/generate_examples.sh`
2. `./scripts/test/examples_structure.sh`
3. `scripts/test/sierra_differential.sh`
4. `scripts/test/backend_parity.sh`

## Completion criteria

1. COR-1 through COR-5 are `DONE - <commit>`.
2. Complex corpus growth is deterministic and capability-linked.
3. Baseline comparisons are provenance-safe and reproducible.
