# Cost Model Calibration

- Summary source: `/Users/theodorepender/Coding/clean/generated/examples/benchmark-summary.json`
- Model: `ratio_by_case_v1`
- Case count: `5`
- Mean absolute pct error: `0.0014317218448221076`
- Max absolute pct error: `0.005983289047097287`

| Case | Family | Coefficient | Measured Sierra Gas | Predicted Sierra Gas | Abs Error % |
| --- | --- | ---: | ---: | ---: | ---: |
| `fast_power_u128` | `integer` | `0.183748` | `19974070.0` | `19974081.95516` | `5.985339993016035e-05` |
| `fast_power_u128_p63` | `integer` | `0.195193` | `37392310.0` | `37392293.43975` | `4.4287849558279585e-05` |
| `karatsuba_u128` | `integer` | `0.005332` | `786550.0` | `786597.06156` | `0.005983289047097287` |
| `newton_u128` | `fixed_point` | `0.975463` | `118464490.0` | `118464450.47478999` | `3.336460572111117e-05` |
| `sq128x128_u128` | `fixed_point` | `0.042842` | `103628430.0` | `103629505.470688` | `0.0010378143218036995` |
