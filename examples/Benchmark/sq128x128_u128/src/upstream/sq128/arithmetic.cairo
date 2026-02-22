//! Basic arithmetic operations for SQ128x128.
//!
//! This module contains add, sub, neg, mul, div operations and their variants.

use core::integer::u512_safe_div_rem_by_u256;
use super::internal::{
    U256_MAG_MAX_LIMIT, apply_rounding, corelib_to_u256, from_parts, i256_add, i256_is_zero,
    i256_new, i256_sub, u256_eq, u256_mul_checked, u256_shifted_128_to_corelib_u512,
    u256_to_corelib, u512_has_remainder, u512_high_overflow, u512_shr_128,
};
use super::types::{SQ128x128, ZERO};
use super::super::common::Rounding;

// ============================================================================
// Option-First Arithmetic (canonical API - total functions returning Option)
// ============================================================================

/// Adds two SQ128x128 values. Returns None on overflow.
pub fn add(a: SQ128x128, b: SQ128x128) -> Option<SQ128x128> {
    match i256_add(a.raw, b.raw) {
        Option::Some(raw) => Option::Some(SQ128x128 { raw }),
        Option::None => Option::None,
    }
}

/// Subtracts b from a. Returns None on overflow.
pub fn sub(a: SQ128x128, b: SQ128x128) -> Option<SQ128x128> {
    match i256_sub(a.raw, b.raw) {
        Option::Some(raw) => Option::Some(SQ128x128 { raw }),
        Option::None => Option::None,
    }
}

/// Negates a value. Returns None if negating MIN (which has no positive counterpart).
pub fn neg(a: SQ128x128) -> Option<SQ128x128> {
    if a.raw.neg && u256_eq(a.raw.mag, U256_MAG_MAX_LIMIT) {
        return Option::None;
    }
    Option::Some(SQ128x128 { raw: i256_new(a.raw.mag, !a.raw.neg) })
}

/// Multiplies two values with explicit rounding policy. Returns None on overflow.
pub fn mul(a: SQ128x128, b: SQ128x128, rounding: Rounding) -> Option<SQ128x128> {
    if i256_is_zero(a.raw) || i256_is_zero(b.raw) {
        return Option::Some(ZERO);
    }

    let result_neg = a.raw.neg != b.raw.neg;
    let (product, mul_overflow) = u256_mul_checked(a.raw.mag, b.raw.mag);

    if mul_overflow || u512_high_overflow(product) {
        return Option::None;
    }

    let mag = u512_shr_128(product);
    let has_remainder = u512_has_remainder(product);
    let rounded_mag = apply_rounding(mag, result_neg, has_remainder, rounding)?;

    from_parts(rounded_mag, result_neg)
}

/// Multiplies with floor rounding (toward negative infinity). Returns None on overflow.
pub fn mul_down(a: SQ128x128, b: SQ128x128) -> Option<SQ128x128> {
    mul(a, b, Rounding::Down)
}

/// Multiplies with ceiling rounding (toward positive infinity). Returns None on overflow.
pub fn mul_up(a: SQ128x128, b: SQ128x128) -> Option<SQ128x128> {
    mul(a, b, Rounding::Up)
}

/// Divides two values with explicit rounding policy. Returns None on overflow or division by zero.
///
/// Division in Q128.128: result = (a * 2^128) / b
/// This requires computing a 384-bit numerator divided by a 256-bit denominator.
pub fn div(a: SQ128x128, b: SQ128x128, rounding: Rounding) -> Option<SQ128x128> {
    // Division by zero check
    if i256_is_zero(b.raw) {
        return Option::None;
    }

    // Zero numerator
    if i256_is_zero(a.raw) {
        return Option::Some(ZERO);
    }

    let result_neg = a.raw.neg != b.raw.neg;

    // Convert numerator to corelib u512: a_mag * 2^128
    let numerator = u256_shifted_128_to_corelib_u512(a.raw.mag);

    // Convert denominator to corelib u256
    let denominator_u256 = u256_to_corelib(b.raw.mag);

    // Convert to NonZero (safe: we checked b != 0 above)
    let denominator_nz: NonZero<u256> = denominator_u256.try_into()?;

    // Safe division: numerator / denominator
    let (quotient_u512, remainder_u256) = u512_safe_div_rem_by_u256(numerator, denominator_nz);

    // Check if quotient fits in U256 (limb2 and limb3 must be zero)
    if quotient_u512.limb2 != 0 || quotient_u512.limb3 != 0 {
        return Option::None; // Overflow
    }

    // Convert quotient to our U256
    let quotient_corelib = u256 { low: quotient_u512.limb0, high: quotient_u512.limb1 };
    let mag = corelib_to_u256(quotient_corelib);

    // Check if there's a remainder (for rounding)
    let has_remainder = remainder_u256.low != 0 || remainder_u256.high != 0;

    // Apply rounding
    let rounded_mag = apply_rounding(mag, result_neg, has_remainder, rounding)?;

    from_parts(rounded_mag, result_neg)
}

/// Divides with floor rounding (toward negative infinity). Returns None on overflow or div by zero.
pub fn div_down(a: SQ128x128, b: SQ128x128) -> Option<SQ128x128> {
    div(a, b, Rounding::Down)
}

/// Divides with ceiling rounding (toward positive infinity). Returns None on overflow or div by
/// zero.
pub fn div_up(a: SQ128x128, b: SQ128x128) -> Option<SQ128x128> {
    div(a, b, Rounding::Up)
}

// ============================================================================
// Unchecked Arithmetic (panicking variants for performance-critical paths)
// ============================================================================

/// Adds two SQ128x128 values. Panics on overflow.
pub fn add_unchecked(a: SQ128x128, b: SQ128x128) -> SQ128x128 {
    add(a, b).expect('add overflow')
}

/// Subtracts b from a. Panics on overflow.
pub fn sub_unchecked(a: SQ128x128, b: SQ128x128) -> SQ128x128 {
    sub(a, b).expect('sub overflow')
}

/// Negates a value. Panics if negating MIN.
pub fn neg_unchecked(a: SQ128x128) -> SQ128x128 {
    neg(a).expect('neg overflow')
}

/// Multiplies two values with explicit rounding policy. Panics on overflow.
pub fn mul_unchecked(a: SQ128x128, b: SQ128x128, rounding: Rounding) -> SQ128x128 {
    mul(a, b, rounding).expect('mul overflow')
}

/// Multiplies with floor rounding (toward negative infinity). Panics on overflow.
pub fn mul_down_unchecked(a: SQ128x128, b: SQ128x128) -> SQ128x128 {
    mul_down(a, b).expect('mul overflow')
}

/// Multiplies with ceiling rounding (toward positive infinity). Panics on overflow.
pub fn mul_up_unchecked(a: SQ128x128, b: SQ128x128) -> SQ128x128 {
    mul_up(a, b).expect('mul overflow')
}

/// Divides two values with explicit rounding policy. Panics on overflow or division by zero.
pub fn div_unchecked(a: SQ128x128, b: SQ128x128, rounding: Rounding) -> SQ128x128 {
    div(a, b, rounding).expect('div overflow or zero')
}

/// Divides with floor rounding (toward negative infinity). Panics on overflow or division by zero.
pub fn div_down_unchecked(a: SQ128x128, b: SQ128x128) -> SQ128x128 {
    div_down(a, b).expect('div overflow or zero')
}

/// Divides with ceiling rounding (toward positive infinity). Panics on overflow or division by
/// zero.
pub fn div_up_unchecked(a: SQ128x128, b: SQ128x128) -> SQ128x128 {
    div_up(a, b).expect('div overflow or zero')
}

// ============================================================================
// Convenience Functions
// ============================================================================

/// Computes b - a (the delta from a to b). Panics on overflow.
///
/// This is a convenience wrapper that encodes the common pattern of computing
/// the difference needed to go from one value to another.
pub fn delta(a: SQ128x128, b: SQ128x128) -> SQ128x128 {
    sub_unchecked(b, a)
}
