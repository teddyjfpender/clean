# Benchmark: sq128x128_u128 (Function-Only)

This benchmark compares:

1. Baseline SQ128-style Option-first arithmetic kernel from
   `examples/Cairo-Baseline/sq128x128_u128/src/arithmetic.cairo`.
2. Lean-generated kernel extracted from
   `examples/Cairo/sq128x128_u128/src/lib.cairo`.

Kernel under test:
- `((a_raw + b_raw) * (c_raw - d_raw)) + e_raw`

Run:

```bash
cd examples/Benchmark/sq128x128_u128
./scripts/run_gas_comparison.sh
```
