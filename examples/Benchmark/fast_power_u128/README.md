# Benchmark: fast_power_u128 (Function-Only)

This benchmark compares pure function execution (no contract dispatch):

1. Generated function extracted from `examples/Cairo/fast_power_u128/src/lib.cairo`:
   `pow13_generated(x)`
2. Alexandria baseline function from `examples/Cairo-Baseline/fast_power_u128/src/fast_power.cairo`:
   `pow13_baseline(x) = fast_power(x, 13)`

Run:

```bash
cd examples/Benchmark/fast_power_u128
./scripts/run_gas_comparison.sh
```
