# Benchmark: karatsuba_u128 (Function-Only)

This benchmark compares pure function execution (no contract dispatch):

1. Generated function extracted from `examples/Cairo/karatsuba_u128/src/lib.cairo`:
   `karatsuba_combine_generated(x0, x1, y0, y1)`
2. Alexandria-derived recursive baseline from `examples/Cairo-Baseline/karatsuba_u128/src/karatsuba.cairo`:
   `karatsuba_baseline(x, y)` where `x = x1*10^9 + x0`, `y = y1*10^9 + y0`

Workload:
- 32 rounds
- alternates two input vectors

Run:

```bash
cd examples/Benchmark/karatsuba_u128
./scripts/run_gas_comparison.sh
```
