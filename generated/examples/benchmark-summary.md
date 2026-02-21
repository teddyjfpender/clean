# Manifest Benchmark Summary

- Config: `generated/examples/benchmark-harness.json`
- Cases: `5`

## Case Metrics

| Case | Family | Sierra improvement % | L2 improvement % | Log |
| --- | --- | ---: | ---: | --- |
| `fast_power_u128` | `integer` | `81.63` | `81.63` | `.artifacts/manifest_benchmark/fast_power_u128.log` |
| `fast_power_u128_p63` | `integer` | `80.48` | `80.48` | `.artifacts/manifest_benchmark/fast_power_u128_p63.log` |
| `karatsuba_u128` | `integer` | `99.47` | `99.47` | `.artifacts/manifest_benchmark/karatsuba_u128.log` |
| `newton_u128` | `fixed_point` | `2.45` | `2.45` | `.artifacts/manifest_benchmark/newton_u128.log` |
| `sq128x128_u128` | `fixed_point` | `0.0` | `0.0` | `.artifacts/manifest_benchmark/sq128x128_u128.log` |

## Family Aggregates

| Family | Cases | Avg Sierra improvement % | Avg L2 improvement % |
| --- | ---: | ---: | ---: |
| `fixed_point` | `2` | `1.225` | `1.225` |
| `integer` | `3` | `87.193333` | `87.193333` |
