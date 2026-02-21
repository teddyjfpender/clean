# Cairo Baseline: sq128x128_u128

This package provides a benchmark baseline derived from the upstream SQ128x128 family:

- commit: `9dc92b9e3d654c2f46c4588e42a4aab4e44f6bee`
- https://github.com/teddyjfpender/the-situation/tree/9dc92b9e3d654c2f46c4588e42a4aab4e44f6bee/contracts/src/types/sq128
- https://github.com/teddyjfpender/the-situation/blob/9dc92b9e3d654c2f46c4588e42a4aab4e44f6bee/contracts/src/types/sq128/arithmetic.cairo
- https://github.com/teddyjfpender/the-situation/blob/9dc92b9e3d654c2f46c4588e42a4aab4e44f6bee/contracts/src/types/sq128/types.cairo

Formal scope for this baseline package:
- reduced raw lane: `SQ128x128 { raw: u128 }`
- Option-first APIs: `add`, `sub`, `mul`, plus unchecked variants
- `delta` and a composed kernel: `sq128x128_affine_kernel_baseline`

The reduced raw lane is intentional and matches current Lean DSL constraints used in this repository's generated equivalent.
