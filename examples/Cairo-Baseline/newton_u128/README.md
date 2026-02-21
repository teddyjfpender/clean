# Cairo Baseline: newton_u128

This package contains a handwritten Cairo Newton baseline derived from Alexandria.

Reference source:
- `fast_root.cairo` at commit `d64124b96f4e12840d64f80f2526841413b72096`
- https://github.com/keep-starknet-strange/alexandria/blob/d64124b96f4e12840d64f80f2526841413b72096/packages/math/src/fast_root.cairo

Build:

```bash
cd examples/Cairo-Baseline/newton_u128
scarb build
```

Contract entrypoint for benchmark comparison:
- `NewtonU128BaselineContract.newton_reciprocal_two_steps_looped(a, x0)`
