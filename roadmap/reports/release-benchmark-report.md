# Release Benchmark Report

- Commit: `e56055c87a9db4e3dbb91c82ccb2ea751a8dc617`
- Benchmark source: `generated/examples/benchmark-summary.json`
- Cases parsed: `5`
- Best Sierra improvement: `99.47%` (`karatsuba_u128`)
- Hotspot (lowest Sierra improvement): `0.00%` (`sq128x128_u128`)

## Family Summary

| Family | Cases | Avg Sierra improvement % | Avg L2 improvement % |
| --- | ---: | ---: | ---: |
| `fixed_point` | `2` | `1.225` | `1.225` |
| `integer` | `3` | `87.193333` | `87.193333` |

## Case Summary

| Case | Sierra improvement % | L2 improvement % |
| --- | ---: | ---: |
| `fast_power_u128` | `81.63` | `81.63` |
| `fast_power_u128_p63` | `80.48` | `80.48` |
| `karatsuba_u128` | `99.47` | `99.47` |
| `newton_u128` | `2.45` | `2.45` |
| `sq128x128_u128` | `0.0` | `0.0` |
