# Release Benchmark Report

- Commit: `e56055c87a9db4e3dbb91c82ccb2ea751a8dc617`
- Benchmark source: `docs/fixed-point/benchmark-results.md`
- Kernel rows parsed: `5`
- Best measured improvement: `76.07%` (`qexp`)

## Kernel Summary

| Kernel | Hand Steps | Optimized Steps | Delta | Improvement | Speedup |
| --- | ---: | ---: | ---: | ---: | ---: |
| `qmul` | `499` | `255` | `244` | `48.90%` | `1.96x` |
| `qexp` | `1605` | `384` | `1221` | `76.07%` | `4.18x` |
| `qlog` | `973` | `401` | `572` | `58.79%` | `2.43x` |
| `qnewton` | `1195` | `512` | `683` | `57.15%` | `2.33x` |
| `fib` | `1226` | `299` | `927` | `75.61%` | `4.10x` |
