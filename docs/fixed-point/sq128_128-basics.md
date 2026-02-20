# SQ128.128 Basics

This note defines a practical contract for SQ128.128 values and the invariants you want before implementing advanced kernels.

## 1) Representation

Let:

- `S = 2^128`
- an SQ128.128 value be represented by a signed 256-bit integer `x`
- interpreted real value be `real(x) = x / S`

For non-negative-only pipelines, use UQ128.128 (`u256`) and the same scale.

## 2) Core invariants

Every kernel should state:

- Input domain constraints (e.g. `x > 0` for `log`).
- Overflow/underflow policy (trap, saturate, or error return).
- Rounding mode (`floor`, nearest-even, away-from-zero, etc.).
- Error bound target (absolute or relative).

A safe default for protocol code:

- explicit precondition checks,
- deterministic floor rounding,
- fail-closed on overflow.

## 3) Encode/decode examples

- `1.0` is `S`.
- `0.5` is `S / 2`.
- `2.0` is `2 * S`.
- `1.25` is `S + S/4`.

## 4) Pseudo-Cairo helpers

```cairo
// PSEUDO-CODE
const SCALE: u256 = 1_u256 << 128;

fn from_u128(v: u128) -> u256 {
    // exact for integer inputs
    (u256_from_u128(v) << 128)
}

fn to_u128_floor(x_q128: u256) -> u128 {
    // floor(x / 2^128)
    (x_q128 >> 128).try_into().unwrap()
}
```

## 5) Lean-style contract for kernels

Even before full arithmetic support in the DSL, define these contracts explicitly:

```lean
-- conceptual contract shape
structure FixedPointKernelSpec where
  name : String
  preconditions : List String
  rounding : String
  overflowPolicy : String
  errorBound : String
```

The key is that every numeric function carries semantic metadata, not only code.

## 6) Review checklist

Before accepting any SQ128.128 routine:

1. Is domain checked explicitly?
2. Is scale applied in the right order?
3. Is overflow behavior explicit?
4. Is rounding consistent across all call paths?
5. Is there a bounded error claim and test coverage?

