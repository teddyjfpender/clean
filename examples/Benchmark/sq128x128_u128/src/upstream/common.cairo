//! Common utilities for fixed-point arithmetic.
//!
//! This module contains shared types and functions used by multiple
//! fixed-point implementations (SQ128x128, SQ128x128, etc.).

// ============================================================================
// Rounding Policy
// ============================================================================

/// Rounding mode for multiplication operations.
/// Makes call sites self-documenting and extensible.
#[derive(Copy, Drop, Debug, PartialEq)]
pub enum Rounding {
    /// Round toward negative infinity (floor)
    Down,
    /// Round toward positive infinity (ceiling)
    Up,
}

// ============================================================================
// Limb Arithmetic Primitives
// ============================================================================

/// 2^64 as u128, used for limb splitting and carry propagation.
pub const TWO_POW_64: u128 = 0x1_0000_0000_0000_0000_u128;

/// Truncates a u128 to u64 (takes the lower 64 bits).
#[inline(always)]
pub fn u128_to_u64(value: u128) -> u64 {
    value.try_into().unwrap()
}

/// Splits a u128 into two u64 limbs (low, high).
#[inline(always)]
pub fn u128_split(value: u128) -> (u64, u64) {
    (u128_to_u64(value & 0xFFFFFFFFFFFFFFFF), u128_to_u64(value / TWO_POW_64))
}

/// Adds two u64 values with a carry input, returns (sum, carry_out).
#[inline(always)]
pub fn add_u64_with_carry(a: u64, b: u64, carry: u64) -> (u64, u64) {
    let sum: u128 = a.into() + b.into() + carry.into();
    (u128_to_u64(sum & 0xFFFFFFFFFFFFFFFF), u128_to_u64(sum / TWO_POW_64))
}

/// Subtracts b from a with a borrow input, returns (diff, borrow_out).
#[inline(always)]
pub fn sub_u64_with_borrow(a: u64, b: u64, borrow: u64) -> (u64, u64) {
    let a128: u128 = a.into();
    let b128: u128 = b.into() + borrow.into();
    if a128 >= b128 {
        (u128_to_u64(a128 - b128), 0)
    } else {
        (u128_to_u64(TWO_POW_64 + a128 - b128), 1)
    }
}

// ============================================================================
// Integer Conversion Helpers
// ============================================================================

/// Converts an i128 to its absolute value as u128 and a sign flag.
/// Handles the edge case of i128::MIN correctly.
pub fn i128_abs_to_u128(value: i128) -> (u128, bool) {
    if value >= 0 {
        (value.try_into().unwrap(), false)
    } else {
        // Handle i128::MIN carefully: -(-128) overflows, so we do value+1 first
        let plus_one: i128 = value + 1;
        let mag_minus_one: u128 = (-plus_one).try_into().unwrap();
        (mag_minus_one + 1, true)
    }
}
