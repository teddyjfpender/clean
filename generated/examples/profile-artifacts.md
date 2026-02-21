# Benchmark Profile Artifacts

- Source summary: `/Users/theodorepender/Coding/clean/generated/examples/benchmark-summary.json`
- Profile cases: `5`

## Hotspot Ranking

| Case | Family | Generated Sierra Gas | Baseline Sierra Gas | Delta | Sierra improvement % | Hotspot ratio |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| `newton_u128` | `fixed_point` | `118464490.0` | `121444330.0` | `2979840.0` | `2.45` | `0.9754633254594924` |
| `fast_power_u128_p63` | `integer` | `37392310.0` | `191565750.0` | `154173440.0` | `80.48` | `0.19519308644682049` |
| `sq128x128_u128` | `fixed_point` | `32128950.0` | `32128950.0` | `0.0` | `0.0` | `1.0` |
| `fast_power_u128` | `integer` | `19974070.0` | `108703670.0` | `88729600.0` | `81.63` | `0.18374789002064051` |
| `karatsuba_u128` | `integer` | `786550.0` | `147523830.0` | `146737280.0` | `99.47` | `0.005331680990115292` |

## Family Hotspot Summary

| Family | Cases | Generated Sierra Total | Avg hotspot ratio |
| --- | ---: | ---: | ---: |
| `fixed_point` | `2` | `150593440.0` | `0.987732` |
| `integer` | `3` | `58152930.0` | `0.128091` |
