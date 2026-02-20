# Fixed-Point Benchmark Results

This document records measured step deltas for the `fixedpoint_bench` package.

## Benchmark contract

- Package: `packages/fixedpoint_bench`
- Date: `2026-02-20`
- Metric: Cairo VM `steps`

## Function generation pipeline

- Source of truth for kernel definitions: `src/Examples/FixedPointBench.lean`
- Lean entry module: `src/MyLeanFixedPointBench.lean`
- Generator orchestrator: `scripts/bench/generate_fixedpoint_bench.sh`
- Lean-to-Cairo extractor: `scripts/bench/build_fixedpoint_bench_from_lean.py`
- Generated benchmark package source: `packages/fixedpoint_bench/src/lib.cairo`
- Benchmark runner: `scripts/bench/compare_fixedpoint_steps.sh`
  - Step 1 in that runner regenerates `src/lib.cairo` before tests/measurements.

## Specification and invariants

- Input set: fixed executables with identical input values per pair:
  - `bench_qmul_hand` vs `bench_qmul_opt`
  - `bench_qexp_hand` vs `bench_qexp_opt`
  - `bench_qlog_hand` vs `bench_qlog_opt`
  - `bench_qnewton_hand` vs `bench_qnewton_opt`
  - `bench_fib_naive` vs `bench_fib_fast`
- Output invariant: hand and optimized variants must produce the same result.
- Failure mode: if equivalence tests fail, benchmark results are invalid and must not be used.
- Scope note: `qmul/qexp/qlog/qnewton` are Lean IR-derived kernel comparisons; `fib` remains a manual Cairo control benchmark (recursion is outside current Lean DSL subset).

## Reproduction commands

Prerequisites:
- `scarb`
- `cairo-profiler`
- `pprof` (`GOBIN="$HOME/.local/bin" go install github.com/google/pprof@latest`)

1. Run equivalence + step comparison:

```bash
./scripts/bench/compare_fixedpoint_steps.sh
```

2. Run profiler pipeline (step profiles + PNG call graphs), one executable at a time:

```bash
PROFILE_CLI="${PROFILE_CLI:-$HOME/.codex/skills/benchmarking-cairo/profile.py}"
rm -r packages/fixedpoint_bench/target/execute/fixedpoint_bench 2>/dev/null || true
python3 "$PROFILE_CLI" profile \
  --mode scarb \
  --package fixedpoint_bench \
  --executable bench_qmul_opt \
  --name qmul-opt \
  --metric steps
```

The first command produces deterministic summary data at:
- `.artifacts/bench/fixedpoint_steps/summary.csv`

## Measured step deltas

| Kernel | Hand Steps | Optimized Steps | Delta | Improvement | Speedup |
|---|---:|---:|---:|---:|---:|
| `qmul` | 721 | 255 | 466 | 64.63% | 2.83x |
| `qexp` | 1605 | 384 | 1221 | 76.07% | 4.18x |
| `qlog` | 973 | 401 | 572 | 58.79% | 2.43x |
| `qnewton` | 1195 | 512 | 683 | 57.15% | 2.33x |
| `fib` | 1117620 | 711 | 1116909 | 99.94% | 1571.90x |

## Interpretation

- The optimization patterns in this benchmark set are structural and deterministic (shared subexpressions, staged powers, and asymptotically better recursion strategy for Fibonacci).
- The step savings are measured, not inferred.
- These numbers are benchmark-scenario specific and should be treated as regression targets, not universal guarantees.
