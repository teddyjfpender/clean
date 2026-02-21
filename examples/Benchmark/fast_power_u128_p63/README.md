# Benchmark: fast_power_u128_p63 (Function-Only)

This benchmark compares pure function execution (no contract dispatch):

1. Generated function extracted from `examples/Cairo/fast_power_u128_p63/src/lib.cairo`:
   `pow63_generated(x)`
2. Alexandria baseline function from `examples/Cairo-Baseline/fast_power_u128_p63/src/fast_power.cairo`:
   `pow63_baseline(x) = fast_power(x, 63)`

Workload:
- 1024 rounds
- alternating inputs 2 and 3 to avoid degenerate constant-only behavior

Run:

```bash
cd examples/Benchmark/fast_power_u128_p63
./scripts/run_gas_comparison.sh
```
