# fixedpoint_bench

Deterministic Cairo benchmark package used to compare hand-written vs optimized kernel shapes.

## Source of truth

- Lean benchmark spec: `src/Examples/FixedPointBench.lean`
- Lean entry module: `src/MyLeanFixedPointBench.lean`
- Generator script: `scripts/bench/generate_fixedpoint_bench.sh`
- Generated file: `packages/fixedpoint_bench/src/lib.cairo`

`src/lib.cairo` is generated output and should be refreshed through:

```bash
./scripts/bench/generate_fixedpoint_bench.sh
```

## Benchmark kernels

- `bench_qmul_hand` vs `bench_qmul_opt`
- `bench_qexp_hand` vs `bench_qexp_opt`
- `bench_qlog_hand` vs `bench_qlog_opt`
- `bench_qnewton_hand` vs `bench_qnewton_opt`
- `bench_fib_naive` vs `bench_fib_fast`

Note:
- The first four kernel pairs are Lean IR derived (baseline `--optimize false` vs optimized `--optimize true`).
- Fibonacci remains a manual Cairo control benchmark because recursion is outside the current Lean DSL subset.

## Required invariants

- Equivalence tests must pass before reading benchmark deltas.
- Each pair must execute equivalent inputs and expose comparable outputs.
- Step measurements must come from the same package revision.

## Standard benchmark pipeline

```bash
./scripts/bench/compare_fixedpoint_steps.sh
```

The script enforces generation, equivalence tests, and step comparison in one run.
