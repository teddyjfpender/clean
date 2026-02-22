//! Operator trait implementations for SQ128x128.
//!
//! This module contains Add, Sub, Mul, Div, Neg, and Serde implementations
//! which depend on arithmetic functions.

use core::serde::Serde;
use super::arithmetic::{add, div_down, mul_down, neg, sub};
use super::constructors::{from_raw, to_raw};
use super::types::{SQ128x128, SQ128x128Raw};

// ============================================================================
// Operator Trait Implementations
// ============================================================================

/// Addition operator. Uses Option-returning `add` with expect internally.
pub impl SQ128x128Add of Add<SQ128x128> {
    fn add(lhs: SQ128x128, rhs: SQ128x128) -> SQ128x128 {
        add(lhs, rhs).expect('add overflow')
    }
}

/// Subtraction operator. Uses Option-returning `sub` with expect internally.
pub impl SQ128x128Sub of Sub<SQ128x128> {
    fn sub(lhs: SQ128x128, rhs: SQ128x128) -> SQ128x128 {
        sub(lhs, rhs).expect('sub overflow')
    }
}

/// Multiplication operator uses floor rounding (mul_down semantics).
/// Uses Option-returning `mul_down` with expect internally.
pub impl SQ128x128Mul of Mul<SQ128x128> {
    fn mul(lhs: SQ128x128, rhs: SQ128x128) -> SQ128x128 {
        mul_down(lhs, rhs).expect('mul overflow')
    }
}

/// Division operator uses floor rounding (div_down semantics).
/// Uses Option-returning `div_down` with expect internally.
pub impl SQ128x128Div of Div<SQ128x128> {
    fn div(lhs: SQ128x128, rhs: SQ128x128) -> SQ128x128 {
        div_down(lhs, rhs).expect('div overflow or zero')
    }
}

/// Negation operator. Uses Option-returning `neg` with expect internally.
pub impl SQ128x128Neg of Neg<SQ128x128> {
    fn neg(a: SQ128x128) -> SQ128x128 {
        neg(a).expect('neg overflow')
    }
}

// ============================================================================
// Manual Serde Implementation (validates through from_raw on deserialize)
// ============================================================================

pub impl SQ128x128Serde of Serde<SQ128x128> {
    fn serialize(self: @SQ128x128, ref output: Array<felt252>) {
        let raw = to_raw(*self);
        raw.serialize(ref output);
    }

    fn deserialize(ref serialized: Span<felt252>) -> Option<SQ128x128> {
        let raw = Serde::<SQ128x128Raw>::deserialize(ref serialized)?;
        from_raw(raw)
    }
}
