# Executable Issue: `roadmap/14-complex-function-corpus-and-benchmarking-lab.md`

- Source roadmap file: [`roadmap/14-complex-function-corpus-and-benchmarking-lab.md`](../14-complex-function-corpus-and-benchmarking-lab.md)
- Issue class: Complex corpus and benchmark scaling
- Priority: P0
- Overall status: NOT DONE

## Objective

Deliver a manifest-driven complex function corpus with deterministic differential and benchmark harness generation, covering both Lean -> Sierra and Lean -> Cairo outputs.

## Implementation loci

1. `roadmap/14-complex-function-corpus-and-benchmarking-lab.md`
2. `config/examples-manifest.json`
3. `examples/**`
4. `scripts/examples/**`
5. `scripts/bench/**`
6. `scripts/test/examples_structure.sh`
7. `scripts/test/sierra_differential.sh`
8. `scripts/test/backend_parity.sh`

## Formal method requirements

1. Corpus items are manifest-defined and reproducibly generated.
2. Equivalence vectors and failure-mode vectors are explicit per corpus item.
3. Benchmark comparisons are same-signature and semantics-aligned.
4. Performance claims require committed artifacts and replayable commands.

## Milestone status ledger

### CFB-1 Unified corpus manifest schema extension
- Status: DONE - ce15de6
- Evidence tests: `scripts/roadmap/check_examples_manifest_schema.sh`; `scripts/test/examples_structure.sh`; `scripts/test/examples_manifest_mirror_negative.sh`; `scripts/test/examples_regeneration_deterministic.sh`; `scripts/examples/generate_examples.sh config/examples-manifest.json`
- Evidence proofs: `config/examples-manifest.json`; `scripts/examples/validate_examples_manifest.py`; `scripts/examples/generate_examples.sh`; `scripts/test/examples_structure.sh`; `examples/README.md`; `scripts/roadmap/list_quality_gates.sh`
- Acceptance tests:
1. Manifest schema validates Lean/Sierra/Cairo/Baseline/Benchmark mappings.
2. Missing mirror paths fail structure checks.
3. Regeneration from manifest is deterministic.

### CFB-2 Differential harness autogeneration
- Status: DONE - 4ca44aa
- Evidence tests: `scripts/roadmap/check_differential_harness_sync.sh`; `scripts/test/differential_harness_reproducibility.sh`; `scripts/test/examples_differential_vectors_negative.sh`; `scripts/test/backend_parity.sh`; `scripts/roadmap/list_quality_gates.sh --validate-workflows`
- Evidence proofs: `config/examples-manifest.json`; `scripts/examples/validate_examples_manifest.py`; `scripts/examples/generate_differential_harness.py`; `scripts/test/generated/run_manifest_differential.sh`; `generated/examples/differential-harness.json`; `scripts/test/run_backend_parity_case.sh`; `scripts/test/backend_parity.sh`
- Acceptance tests:
1. Generated differential tests compare evaluator/Sierra/Cairo outputs on shared vectors.
2. Boundary and failure vectors are included per corpus family.
3. Differential mismatch output is replayable and deterministic.

### CFB-3 Benchmark harness autogeneration
- Status: DONE - 6111d81
- Evidence tests: `scripts/roadmap/check_benchmark_harness_sync.sh`; `scripts/test/benchmark_harness_reproducibility.sh`; `scripts/test/benchmark_family_thresholds_negative.sh`; `scripts/bench/generated/run_manifest_benchmarks.sh`; `scripts/roadmap/list_quality_gates.sh --validate-workflows`
- Evidence proofs: `config/examples-manifest.json`; `scripts/examples/validate_examples_manifest.py`; `scripts/examples/generate_benchmark_harness.py`; `generated/examples/benchmark-harness.json`; `scripts/bench/generated/run_manifest_benchmarks.sh`; `scripts/bench/run_manifest_benchmark_suite.py`; `scripts/bench/check_manifest_benchmark_thresholds.py`; `generated/examples/benchmark-summary.json`; `generated/examples/benchmark-summary.md`
- Acceptance tests:
1. Benchmark harnesses generate from manifest kernels with stable naming.
2. Gas and steps comparisons are parsed into deterministic artifacts.
3. Family-level regression thresholds are enforced.

### CFB-4 Complex family scale-out and reporting
- Status: NOT DONE
- Acceptance tests:
1. Medium/high complexity kernels exist for integer, fixed-point, control-flow, aggregate, and crypto/circuit families.
2. Corpus coverage report maps kernels to capability IDs.
3. Release benchmark report summarizes per-family deltas and hotspots.

## Global strict acceptance tests

1. `./scripts/examples/generate_examples.sh`
2. `./scripts/test/examples_structure.sh`
3. `scripts/test/sierra_differential.sh`
4. `scripts/test/backend_parity.sh`
5. `scripts/bench/check_optimizer_non_regression.sh`
6. `scripts/bench/check_optimizer_family_thresholds.sh`

## Completion criteria

1. CFB-1 through CFB-4 are `DONE - <commit>`.
2. Complex corpus growth is manifest-driven and reproducible.
3. Benchmark and differential evidence is mandatory for capability promotion.
