# Cairo Baseline: karatsuba_u128

This package contains an Alexandria-derived recursive Karatsuba baseline.

Reference sources:
- https://github.com/keep-starknet-strange/alexandria/blob/main/packages/math/src/karatsuba.cairo
- https://github.com/keep-starknet-strange/alexandria/blob/main/packages/math/src/const_pow.cairo
- https://github.com/keep-starknet-strange/alexandria/blob/main/packages/math/src/lib.cairo (`count_digits_of_base`)

Note:
- The upstream `div_half_ceil` expression in `karatsuba.cairo` is patched in benchmark sync (`(num + 1) % 2` -> `(num + 1) / 2`) to ensure termination.
