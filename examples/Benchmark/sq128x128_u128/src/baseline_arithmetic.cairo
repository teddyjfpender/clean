//! Reduced arithmetic API derived from upstream SQ128x128 arithmetic style.
//!
//! This keeps the Option-first contract (`Option<SQ128x128>`) while operating in
//! the reduced raw lane (`u128`) used by current generated Lean kernels.

use core::num::traits::{OverflowingAdd, OverflowingMul, OverflowingSub};
use super::baseline_types::SQ128x128;

pub fn add(a: SQ128x128, b: SQ128x128) -> Option<SQ128x128> {
    let (raw, overflow) = OverflowingAdd::overflowing_add(a.raw, b.raw);
    if overflow {
        return Option::None;
    }
    Option::Some(SQ128x128 { raw })
}

pub fn sub(a: SQ128x128, b: SQ128x128) -> Option<SQ128x128> {
    let (raw, overflow) = OverflowingSub::overflowing_sub(a.raw, b.raw);
    if overflow {
        return Option::None;
    }
    Option::Some(SQ128x128 { raw })
}

pub fn mul(a: SQ128x128, b: SQ128x128) -> Option<SQ128x128> {
    let (raw, overflow) = OverflowingMul::overflowing_mul(a.raw, b.raw);
    if overflow {
        return Option::None;
    }
    Option::Some(SQ128x128 { raw })
}

pub fn add_unchecked(a: SQ128x128, b: SQ128x128) -> SQ128x128 {
    add(a, b).expect('sq_add_overflow')
}

pub fn sub_unchecked(a: SQ128x128, b: SQ128x128) -> SQ128x128 {
    sub(a, b).expect('sq_sub_overflow')
}

pub fn mul_unchecked(a: SQ128x128, b: SQ128x128) -> SQ128x128 {
    mul(a, b).expect('sq_mul_overflow')
}

pub fn delta(a: SQ128x128, b: SQ128x128) -> SQ128x128 {
    sub_unchecked(b, a)
}

/// Composed SQ128-style kernel used for baseline-vs-generated gas comparison.
///
/// Preconditions:
/// - `a_raw + b_raw` does not overflow `u128`
/// - `c_raw >= d_raw`
/// - `(a_raw + b_raw) * (c_raw - d_raw) + e_raw` does not overflow `u128`
pub fn sq128x128_affine_kernel_baseline(
    a_raw: u128, b_raw: u128, c_raw: u128, d_raw: u128, e_raw: u128
) -> u128 {
    let a = SQ128x128 { raw: a_raw };
    let b = SQ128x128 { raw: b_raw };
    let c = SQ128x128 { raw: c_raw };
    let d = SQ128x128 { raw: d_raw };
    let e = SQ128x128 { raw: e_raw };

    let sum_ab = add_unchecked(a, b);
    let delta_cd = delta(d, c);
    let mul_term = mul_unchecked(sum_ab, delta_cd);
    let out = add_unchecked(mul_term, e);
    out.raw
}
