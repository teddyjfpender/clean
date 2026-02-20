# SQ128.128 Mul/Div Kernels

This file covers the two primitive operations most other high-step kernels depend on.

## 1) Multiplication

For SQ128.128 values `a`, `b` (scaled by `S = 2^128`):

- mathematical: `real(out) = real(a) * real(b)`
- integer form: `out = floor((a * b) / S)` (for floor rounding)

Because `a * b` can exceed 256 bits, use a widened intermediate.

```cairo
// PSEUDO-CODE
fn qmul_floor(a_q128: i256, b_q128: i256) -> i256 {
    // 1) wide multiply to 512-bit signed intermediate
    let prod_512: i512 = wide_mul_i256(a_q128, b_q128);

    // 2) scale down by 2^128
    let shifted: i512 = prod_512 >> 128;

    // 3) range-check -> i256
    assert_i256_range(shifted);
    i256_from_i512(shifted)
}
```

### Rounding variants

- Floor: deterministic, conservative.
- Nearest-even: lower bias across repeated operations, more logic.

Document and keep one default globally.

## 2) Division

For `a / b`:

- mathematical: `real(out) = real(a) / real(b)`
- integer form: `out = floor((a * S) / b)`

Again, use widened intermediate before dividing.

```cairo
// PSEUDO-CODE
fn qdiv_floor(a_q128: i256, b_q128: i256) -> i256 {
    assert!(b_q128 != 0, 'DIV_BY_ZERO');

    let num_512: i512 = widen_i256(a_q128) << 128;
    let quo_512: i512 = num_512 / widen_i256(b_q128);

    assert_i256_range(quo_512);
    i256_from_i512(quo_512)
}
```

## 3) Lean-generated style vs hand-written style

Hand-written Cairo often inlines repeated scaling logic at call sites.

A Lean->IR pipeline should instead normalize calls around kernel intrinsics:

- `qmul_floor(a,b)`
- `qdiv_floor(a,b)`

This gives optimizer passes clearer structure:

- CSE over repeated `qmul_floor(gross, rate)` patterns,
- safe let-normalization around scale shifts,
- easier proof obligations (`kernel contract` + `composition`).

## 4) Test vectors (minimum)

For each kernel:

1. identity: `x * 1 = x`, `x / 1 = x`
2. zero: `x * 0 = 0`, `0 / x = 0`
3. sign cases: `(+/-) * (+/-)`, `(+/-) / (+/-)`
4. near-boundary magnitudes
5. rounding-boundary values (fraction exactly at half-ulp when supported)

