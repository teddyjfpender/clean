//! Internal types and operations for SQ128x128.
//!
//! This module contains implementation details that are not part of the public API:
//! - BoundedInt limb types for optimized arithmetic
//! - U256, I256, U512 internal types
//! - Limb arithmetic functions
//! - Conversion functions

use core::integer::u512;
use core::num::traits::WideMul;
use corelib_imports::bounded_int::bounded_int::add as bi_add;
use corelib_imports::bounded_int::{
    AddHelper, BoundedInt, DivRemHelper, UnitInt, bounded_int_div_rem, upcast,
};
use super::super::common::u128_split;

// ============================================================================
// BoundedInt Limb Types (eliminates overflow checks in limb arithmetic)
// ============================================================================

/// A 64-bit limb with exact u64 range. Upcast from u64 is free.
pub type Limb64 = BoundedInt<0, 18446744073709551615>;

/// Carry/borrow bit: 0 or 1.
pub type Carry = BoundedInt<0, 1>;

/// Sum of two Limb64 values (before adding carry).
pub type Limb64Sum = BoundedInt<0, 36893488147419103230>;

/// Sum of two Limb64 values plus a carry bit.
pub type Limb64SumWithCarry = BoundedInt<0, 36893488147419103231>;

/// 2^64 as a singleton for division.
pub type TwoPow64 = UnitInt<18446744073709551616>;

// BoundedInt impl: Limb64 + Limb64
pub impl AddLimb64Limb64 of AddHelper<Limb64, Limb64> {
    type Result = Limb64Sum;
}

// BoundedInt impl: Limb64Sum + Carry
pub impl AddLimb64SumCarry of AddHelper<Limb64Sum, Carry> {
    type Result = Limb64SumWithCarry;
}

// BoundedInt impl: divide by 2^64 to split into (carry, remainder)
pub impl DivRemLimbSplit of DivRemHelper<Limb64SumWithCarry, TwoPow64> {
    type DivT = Carry;
    type RemT = Limb64;
}


// ============================================================================
// Optimized Limb Arithmetic (BoundedInt-based, no overflow checks)
// ============================================================================

/// The zero carry constant for starting carry chains.
pub const CARRY_ZERO: Carry = 0;

/// Adds two u64 limbs with a bounded carry input. Returns (sum, carry_out).
/// Uses BoundedInt to eliminate overflow checks. Carries flow as bounded types.
#[inline(always)]
pub fn add_limbs_bounded(a: u64, b: u64, carry_in: Carry) -> (u64, Carry) {
    // Upcast to bounded types (free - u64 range equals Limb64 range)
    let a_b: Limb64 = upcast(a);
    let b_b: Limb64 = upcast(b);

    // Add: bounds are statically verified, no runtime checks
    let sum_ab: Limb64Sum = bi_add(a_b, b_b);
    let sum_abc: Limb64SumWithCarry = bi_add(sum_ab, carry_in);

    // Split by 2^64 to extract carry and low limb
    let nz_2pow64: NonZero<TwoPow64> = 18446744073709551616;
    let (carry_out, low): (Carry, Limb64) = bounded_int_div_rem(sum_abc, nz_2pow64);

    // Upcast low back to u64 (free - Limb64 is subset of u64)
    (upcast(low), carry_out)
}

/// Subtracts b from a with a borrow input. Returns (diff, borrow_out).
/// Note: Subtraction uses conditional logic; BoundedInt optimization applies to addition path.
#[inline(always)]
pub fn sub_limb_with_borrow(a: u64, b: u64, borrow_in: u64) -> (u64, u64) {
    let a128: u128 = a.into();
    let b128: u128 = b.into() + borrow_in.into();
    if a128 >= b128 {
        let diff: u128 = a128 - b128;
        (diff.try_into().unwrap(), 0)
    } else {
        let diff: u128 = 0x10000000000000000_u128 + a128 - b128;
        (diff.try_into().unwrap(), 1)
    }
}

// ============================================================================
// Internal Types
// ============================================================================

/// Internal 256-bit unsigned magnitude (4 x 64-bit limbs, little-endian)
/// Sufficient for Q128.128: max magnitude is 2^256
#[derive(Copy, Drop, Debug)]
pub struct U256 {
    pub limb0: u64,
    pub limb1: u64,
    pub limb2: u64,
    pub limb3: u64,
}

/// Internal 256-bit signed value (sign-magnitude representation)
/// Invariant: when mag is zero, neg must be false (no negative zero)
#[derive(Copy, Drop, Debug)]
pub struct I256 {
    pub mag: U256,
    pub neg: bool,
}

/// Internal 512-bit unsigned for multiplication results (8 x 64-bit limbs)
#[derive(Copy, Drop)]
pub struct U512 {
    pub limb0: u64,
    pub limb1: u64,
    pub limb2: u64,
    pub limb3: u64,
    pub limb4: u64,
    pub limb5: u64,
    pub limb6: u64,
    pub limb7: u64,
}

// ============================================================================
// Internal Constants
// ============================================================================

pub const U256_ZERO: U256 = U256 { limb0: 0, limb1: 0, limb2: 0, limb3: 0 };
pub const U256_ONE: U256 = U256 { limb0: 1, limb1: 0, limb2: 0, limb3: 0 };

/// 2^128 as U256 - the scaling factor for Q128.128
pub const U256_2_POW_128: U256 = U256 { limb0: 0, limb1: 0, limb2: 1, limb3: 0 };

/// Maximum magnitude for positive values: 2^256 - 1
/// This represents the value (2^128 - 2^-128) in fixed-point
pub const U256_MAG_MAX_LIMIT: U256 = U256 {
    limb0: 0xffff_ffff_ffff_ffff,
    limb1: 0xffff_ffff_ffff_ffff,
    limb2: 0xffff_ffff_ffff_ffff,
    limb3: 0xffff_ffff_ffff_ffff,
};

/// Maximum magnitude for negative values: 2^256
/// This would represent -2^128 but is unrepresentable (overflow)
/// For SQ128x128 we allow the full 256-bit range for magnitude
/// Negative min has the same limit as positive max (2^256 - 1)
pub const U256_MAG_MIN_LIMIT: U256 = U256_MAG_MAX_LIMIT;

pub const I256_ZERO: I256 = I256 { mag: U256_ZERO, neg: false };
pub const I256_ONE_ULP: I256 = I256 { mag: U256_ONE, neg: false };
pub const I256_ONE: I256 = I256 { mag: U256_2_POW_128, neg: false };
pub const I256_NEG_ONE: I256 = I256 { mag: U256_2_POW_128, neg: true };
pub const I256_MIN: I256 = I256 { mag: U256_MAG_MIN_LIMIT, neg: true };
pub const I256_MAX: I256 = I256 { mag: U256_MAG_MAX_LIMIT, neg: false };

// ============================================================================
// U256 Operations
// ============================================================================

pub fn u256_is_zero(value: U256) -> bool {
    value.limb0 == 0 && value.limb1 == 0 && value.limb2 == 0 && value.limb3 == 0
}

pub fn u256_eq(a: U256, b: U256) -> bool {
    a.limb0 == b.limb0 && a.limb1 == b.limb1 && a.limb2 == b.limb2 && a.limb3 == b.limb3
}

pub fn u256_cmp(a: U256, b: U256) -> i32 {
    if a.limb3 != b.limb3 {
        return if a.limb3 < b.limb3 {
            -1
        } else {
            1
        };
    }
    if a.limb2 != b.limb2 {
        return if a.limb2 < b.limb2 {
            -1
        } else {
            1
        };
    }
    if a.limb1 != b.limb1 {
        return if a.limb1 < b.limb1 {
            -1
        } else {
            1
        };
    }
    if a.limb0 != b.limb0 {
        return if a.limb0 < b.limb0 {
            -1
        } else {
            1
        };
    }
    0
}

pub fn u256_add(a: U256, b: U256) -> (U256, bool) {
    let (l0, c0) = add_limbs_bounded(a.limb0, b.limb0, CARRY_ZERO);
    let (l1, c1) = add_limbs_bounded(a.limb1, b.limb1, c0);
    let (l2, c2) = add_limbs_bounded(a.limb2, b.limb2, c1);
    let (l3, c3) = add_limbs_bounded(a.limb3, b.limb3, c2);
    (U256 { limb0: l0, limb1: l1, limb2: l2, limb3: l3 }, upcast::<Carry, u64>(c3) != 0)
}

pub fn u256_add_u64(a: U256, value: u64) -> (U256, bool) {
    let (l0, c0) = add_limbs_bounded(a.limb0, value, CARRY_ZERO);
    let (l1, c1) = add_limbs_bounded(a.limb1, 0, c0);
    let (l2, c2) = add_limbs_bounded(a.limb2, 0, c1);
    let (l3, c3) = add_limbs_bounded(a.limb3, 0, c2);
    (U256 { limb0: l0, limb1: l1, limb2: l2, limb3: l3 }, upcast::<Carry, u64>(c3) != 0)
}

pub fn u256_sub(a: U256, b: U256) -> (U256, bool) {
    let (l0, b0) = sub_limb_with_borrow(a.limb0, b.limb0, 0);
    let (l1, b1) = sub_limb_with_borrow(a.limb1, b.limb1, b0);
    let (l2, b2) = sub_limb_with_borrow(a.limb2, b.limb2, b1);
    let (l3, b3) = sub_limb_with_borrow(a.limb3, b.limb3, b2);
    (U256 { limb0: l0, limb1: l1, limb2: l2, limb3: l3 }, b3 != 0)
}

// ============================================================================
// U512 Operations (for multiplication)
// ============================================================================

pub fn u512_zero() -> U512 {
    U512 { limb0: 0, limb1: 0, limb2: 0, limb3: 0, limb4: 0, limb5: 0, limb6: 0, limb7: 0 }
}

pub fn u512_get_limb(value: @U512, idx: u32) -> u64 {
    match idx {
        0 => *value.limb0,
        1 => *value.limb1,
        2 => *value.limb2,
        3 => *value.limb3,
        4 => *value.limb4,
        5 => *value.limb5,
        6 => *value.limb6,
        _ => *value.limb7,
    }
}

pub fn u512_set_limb(ref value: U512, idx: u32, limb: u64) {
    match idx {
        0 => value.limb0 = limb,
        1 => value.limb1 = limb,
        2 => value.limb2 = limb,
        3 => value.limb3 = limb,
        4 => value.limb4 = limb,
        5 => value.limb5 = limb,
        6 => value.limb6 = limb,
        _ => value.limb7 = limb,
    }
}

pub fn u256_get_limb(value: @U256, idx: u32) -> u64 {
    match idx {
        0 => *value.limb0,
        1 => *value.limb1,
        2 => *value.limb2,
        _ => *value.limb3,
    }
}

/// Add 1 starting from a given limb index. Returns (result, overflow).
/// Uses bounded carry type to eliminate overflow checks.
pub fn u512_add_one_from(mut acc: U512, start: u32) -> (U512, bool) {
    let carry_one: Carry = 1;
    let mut carry: Carry = carry_one;
    let mut i: u32 = start;
    while i != 8 && upcast::<Carry, u64>(carry) != 0 {
        let limb = u512_get_limb(@acc, i);
        let (new_limb, new_carry) = add_limbs_bounded(limb, 0, carry);
        u512_set_limb(ref acc, i, new_limb);
        carry = new_carry;
        i += 1;
    }
    (acc, upcast::<Carry, u64>(carry) != 0)
}

/// Add a*b at position idx. Returns (result, overflow).
/// Uses bounded carry type to eliminate overflow checks.
pub fn u512_add_product(mut acc: U512, a: u64, b: u64, idx: u32) -> (U512, bool) {
    let prod: u128 = a.wide_mul(b);
    let (low, high) = u128_split(prod);

    let limb_low = u512_get_limb(@acc, idx);
    let (new_low, c0) = add_limbs_bounded(limb_low, low, CARRY_ZERO);
    u512_set_limb(ref acc, idx, new_low);

    let limb_high = u512_get_limb(@acc, idx + 1);
    let (new_high, c1) = add_limbs_bounded(limb_high, high, c0);
    u512_set_limb(ref acc, idx + 1, new_high);

    if upcast::<Carry, u64>(c1) != 0 {
        let (new_acc, overflow) = u512_add_one_from(acc, idx + 2);
        return (new_acc, overflow);
    }
    (acc, false)
}

/// Multiply two U256 values, returning U512. Returns (result, overflow).
/// Unrolled loop for 4x4 limb multiplication.
pub fn u256_mul_checked(a: U256, b: U256) -> (U512, bool) {
    let mut acc = u512_zero();

    // Row i=0: a.limb0 * b.limb[0,1,2,3] at positions [0,1,2,3]
    let (acc, o0) = u512_add_product(acc, a.limb0, b.limb0, 0);
    if o0 {
        return (acc, true);
    }
    let (acc, o1) = u512_add_product(acc, a.limb0, b.limb1, 1);
    if o1 {
        return (acc, true);
    }
    let (acc, o2) = u512_add_product(acc, a.limb0, b.limb2, 2);
    if o2 {
        return (acc, true);
    }
    let (acc, o3) = u512_add_product(acc, a.limb0, b.limb3, 3);
    if o3 {
        return (acc, true);
    }

    // Row i=1: a.limb1 * b.limb[0,1,2,3] at positions [1,2,3,4]
    let (acc, o4) = u512_add_product(acc, a.limb1, b.limb0, 1);
    if o4 {
        return (acc, true);
    }
    let (acc, o5) = u512_add_product(acc, a.limb1, b.limb1, 2);
    if o5 {
        return (acc, true);
    }
    let (acc, o6) = u512_add_product(acc, a.limb1, b.limb2, 3);
    if o6 {
        return (acc, true);
    }
    let (acc, o7) = u512_add_product(acc, a.limb1, b.limb3, 4);
    if o7 {
        return (acc, true);
    }

    // Row i=2: a.limb2 * b.limb[0,1,2,3] at positions [2,3,4,5]
    let (acc, o8) = u512_add_product(acc, a.limb2, b.limb0, 2);
    if o8 {
        return (acc, true);
    }
    let (acc, o9) = u512_add_product(acc, a.limb2, b.limb1, 3);
    if o9 {
        return (acc, true);
    }
    let (acc, o10) = u512_add_product(acc, a.limb2, b.limb2, 4);
    if o10 {
        return (acc, true);
    }
    let (acc, o11) = u512_add_product(acc, a.limb2, b.limb3, 5);
    if o11 {
        return (acc, true);
    }

    // Row i=3: a.limb3 * b.limb[0,1,2,3] at positions [3,4,5,6]
    let (acc, o12) = u512_add_product(acc, a.limb3, b.limb0, 3);
    if o12 {
        return (acc, true);
    }
    let (acc, o13) = u512_add_product(acc, a.limb3, b.limb1, 4);
    if o13 {
        return (acc, true);
    }
    let (acc, o14) = u512_add_product(acc, a.limb3, b.limb2, 5);
    if o14 {
        return (acc, true);
    }
    let (acc, o15) = u512_add_product(acc, a.limb3, b.limb3, 6);

    (acc, o15)
}

/// Check if upper bits overflow for Q128.128 multiplication.
/// After shifting right by 128 bits (2 limbs), result must fit in U256 (4 limbs)
/// So limb6 and limb7 must be zero after the multiplication
pub fn u512_high_overflow(value: U512) -> bool {
    value.limb6 != 0 || value.limb7 != 0
}

pub fn u512_has_remainder(value: U512) -> bool {
    value.limb0 != 0 || value.limb1 != 0
}

/// Right shift by 128 bits (2 limbs)
pub fn u512_shr_128(value: U512) -> U256 {
    U256 { limb0: value.limb2, limb1: value.limb3, limb2: value.limb4, limb3: value.limb5 }
}

// ============================================================================
// U256 <-> corelib u256/u512 Conversion (for division using corelib)
// ============================================================================

/// Convert our U256 to corelib u256
pub fn u256_to_corelib(value: U256) -> u256 {
    let low: u128 = value.limb0.into() + value.limb1.into() * 0x10000000000000000_u128;
    let high: u128 = value.limb2.into() + value.limb3.into() * 0x10000000000000000_u128;
    u256 { low, high }
}

/// Convert corelib u256 to our U256
pub fn corelib_to_u256(value: u256) -> U256 {
    let (low_lo, low_hi) = u128_split(value.low);
    let (high_lo, high_hi) = u128_split(value.high);
    U256 { limb0: low_lo, limb1: low_hi, limb2: high_lo, limb3: high_hi }
}

/// Convert U256 << 128 to corelib u512 (for division numerator)
pub fn u256_shifted_128_to_corelib_u512(value: U256) -> u512 {
    // Shifting by 128 bits means limb0,limb1 become limb1,limb2 (using u128 encoding)
    let limb1: u128 = value.limb0.into() + value.limb1.into() * 0x10000000000000000_u128;
    let limb2: u128 = value.limb2.into() + value.limb3.into() * 0x10000000000000000_u128;
    u512 { limb0: 0, limb1, limb2, limb3: 0 }
}

// ============================================================================
// I256 Operations
// ============================================================================

/// Smart constructor enforcing the no-negative-zero invariant
pub fn i256_new(mag: U256, neg: bool) -> I256 {
    I256 { mag, neg: neg && !u256_is_zero(mag) }
}

pub fn i256_is_zero(value: I256) -> bool {
    u256_is_zero(value.mag)
}

pub fn i256_eq(a: I256, b: I256) -> bool {
    a.neg == b.neg && u256_eq(a.mag, b.mag)
}

pub fn i256_cmp(a: I256, b: I256) -> i32 {
    if a.neg != b.neg {
        return if a.neg {
            -1
        } else {
            1
        };
    }
    let mag_cmp = u256_cmp(a.mag, b.mag);
    if a.neg {
        0 - mag_cmp
    } else {
        mag_cmp
    }
}

pub fn u256_from_u128_shifted_128(value: u128) -> U256 {
    let (low, high) = u128_split(value);
    U256 { limb0: 0, limb1: 0, limb2: low, limb3: high }
}
use super::types::SQ128x128;

// ============================================================================
// Shared Algebraic Helpers (Bird-ish factored lemmas)
// ============================================================================

use super::super::common::Rounding;

/// Returns the magnitude limit for a given sign.
/// For SQ128x128, both positive and negative use the full 256-bit range
pub fn mag_limit(_neg: bool) -> U256 {
    U256_MAG_MAX_LIMIT
}

/// Determines if we should round up (away from zero toward +/- infinity).
/// Down = toward negative infinity, Up = toward positive infinity.
/// For positive results: Up rounds away from zero when there's a remainder.
/// For negative results: Down rounds away from zero when there's a remainder.
pub fn should_round_away(result_neg: bool, has_remainder: bool, rounding: Rounding) -> bool {
    match rounding {
        Rounding::Down => result_neg && has_remainder,
        Rounding::Up => !result_neg && has_remainder,
    }
}

/// Validated constructor from sign+magnitude. Returns None if out of range.
pub fn from_parts(mag: U256, neg: bool) -> Option<SQ128x128> {
    let raw = i256_new(mag, neg);
    if u256_cmp(raw.mag, mag_limit(raw.neg)) > 0 {
        Option::None
    } else {
        Option::Some(SQ128x128 { raw })
    }
}

/// Apply rounding increment if needed, checking for overflow.
pub fn apply_rounding(
    mag: U256, neg: bool, has_remainder: bool, rounding: Rounding,
) -> Option<U256> {
    if should_round_away(neg, has_remainder, rounding) {
        let (inc, overflow) = u256_add_u64(mag, 1);
        if overflow {
            return Option::None;
        }
        Option::Some(inc)
    } else {
        Option::Some(mag)
    }
}

// ============================================================================
// Checked I256 Arithmetic
// ============================================================================

pub fn i256_add(a: I256, b: I256) -> Option<I256> {
    if a.neg == b.neg {
        let (sum, overflow) = u256_add(a.mag, b.mag);
        if overflow {
            return Option::None;
        }
        if u256_cmp(sum, mag_limit(a.neg)) > 0 {
            return Option::None;
        }
        return Option::Some(i256_new(sum, a.neg));
    }

    let cmp = u256_cmp(a.mag, b.mag);
    if cmp == 0 {
        return Option::Some(I256_ZERO);
    }
    let (larger, smaller, result_neg) = if cmp > 0 {
        (a.mag, b.mag, a.neg)
    } else {
        (b.mag, a.mag, b.neg)
    };
    let (diff, _) = u256_sub(larger, smaller);
    Option::Some(i256_new(diff, result_neg))
}

pub fn i256_sub(a: I256, b: I256) -> Option<I256> {
    i256_add(a, i256_new(b.mag, !b.neg))
}
