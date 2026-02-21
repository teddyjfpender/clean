# Benchmark: newton_u128

This benchmark compares:

1. Generated contract call:
   `examples/Cairo/newton_u128` -> `NewtonU128Contract.newton_reciprocal_two_steps`.
2. Handwritten baseline contract call:
   `examples/Cairo-Baseline/newton_u128` -> `NewtonU128BaselineContract.newton_reciprocal_two_steps_looped`.

Both paths are tested for equivalence and benchmarked on gas.

Current benchmark intensity:
- `BENCH_CALLS = 1024` in `src/lib.cairo`.

Before running tests directly, sync source mirrors:

```bash
./scripts/sync_sources.sh
```

## Run tests

```bash
cd examples/Benchmark/newton_u128
snforge test
```

## Run gas comparison

```bash
./scripts/run_gas_comparison.sh
```

The script fails fast if generated contract gas regresses above baseline.
It also reports:
- total `sierra gas` and `l2_gas`
- per-function average gas from the contract gas table
- estimated fixed overhead (`total - avg_per_call * calls`)
