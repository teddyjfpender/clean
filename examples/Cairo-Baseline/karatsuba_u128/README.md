# Cairo Baseline: karatsuba_u128

This package contains an Alexandria-derived recursive Karatsuba baseline.

Reference sources:
- commit: `d64124b96f4e12840d64f80f2526841413b72096`
- https://github.com/keep-starknet-strange/alexandria/blob/d64124b96f4e12840d64f80f2526841413b72096/packages/math/src/karatsuba.cairo
- https://github.com/keep-starknet-strange/alexandria/blob/d64124b96f4e12840d64f80f2526841413b72096/packages/math/src/const_pow.cairo
- https://github.com/keep-starknet-strange/alexandria/blob/d64124b96f4e12840d64f80f2526841413b72096/packages/math/src/lib.cairo (`count_digits_of_base`)

Note:
- The upstream `div_half_ceil` expression in `karatsuba.cairo` is patched in benchmark sync (`(num + 1) % 2` -> `(num + 1) / 2`) to ensure termination.
