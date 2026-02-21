# Examples Mirror

This directory is the canonical examples workspace for formal end-to-end checks.

1. `examples/Lean/<example-id>/`:
   canonical Lean source of truth.
2. `examples/Sierra/<example-id>/`:
   generated Sierra artifacts.
3. `examples/Cairo/<example-id>/`:
   generated Cairo project artifacts.
4. `examples/Cairo-Baseline/<example-id>/`:
   handwritten Cairo baseline reference implementations.
5. `examples/Benchmark/<example-id>/`:
   gas/step comparison harnesses for baseline vs optimized paths.

Rules:
1. Example source belongs in `examples/Lean/`, not `src/`.
2. Every `<example-id>` must map to Lean/Sierra/Cairo mirrors via `config/examples-manifest.json`.
3. Baseline/Benchmark mirrors are explicit in the manifest (`path` or `null`), not implicit.
4. Differential harness metadata is explicit per example via `differential` in the manifest.
5. `examples/Sierra/` and `examples/Cairo/` are generated outputs.
6. `examples/Cairo-Baseline/` and `examples/Benchmark/` are manual reference/measurement packages.

## Regenerate

```bash
./scripts/examples/generate_examples.sh
```

The generator uses formal CLI commands from this repository:

1. `lake exe leancairo-sierra-gen --module <module> --out examples/Sierra/<id> --optimize true`
2. `lake exe leancairo-gen --module <module> --out examples/Cairo/<id> --emit-casm false --optimize true`

`<module>` values are declared in `config/examples-manifest.json` and map to Lean modules under `examples/Lean/`.

## Validate Manifest Schema

```bash
./scripts/roadmap/check_examples_manifest_schema.sh
```

## Differential Harness

```bash
python3 scripts/examples/generate_differential_harness.py \
  --manifest config/examples-manifest.json \
  --out-script scripts/test/generated/run_manifest_differential.sh \
  --out-json generated/examples/differential-harness.json
./scripts/roadmap/check_differential_harness_sync.sh
```

## Benchmark Harness

```bash
python3 scripts/examples/generate_benchmark_harness.py \
  --manifest config/examples-manifest.json \
  --out-config generated/examples/benchmark-harness.json \
  --out-script scripts/bench/generated/run_manifest_benchmarks.sh
./scripts/roadmap/check_benchmark_harness_sync.sh
scripts/bench/generated/run_manifest_benchmarks.sh
```

## Validate Structure

```bash
./scripts/test/examples_structure.sh
```

## Baseline Provenance

```bash
python3 scripts/examples/validate_baselines_manifest.py \
  --manifest config/baselines-manifest.json \
  --examples-manifest config/examples-manifest.json
./scripts/examples/sync_baselines.sh --manifest config/baselines-manifest.json
./scripts/roadmap/check_baseline_provenance.sh
```

## Add A New Example

1. Add Lean source under `examples/Lean/<new-id>/`.
2. Add a module entrypoint file under `examples/Lean/<new-id>.lean`.
3. Register the example in `config/examples-manifest.json` with `mirrors` for Lean/Sierra/Cairo/Baseline/Benchmark.
4. Run:
   ```bash
   ./scripts/roadmap/check_examples_manifest_schema.sh
   ./scripts/examples/generate_examples.sh
   ./scripts/test/examples_structure.sh
   ```
