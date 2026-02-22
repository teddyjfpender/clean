//! Core types, constants, and trait implementations for SQ128x128.
//!
//! This module contains the public types, constants, and all trait implementations
//! for the SQ128x128 fixed-point number.

use core::hash::{Hash, HashStateTrait};
use core::num::traits::Bounded;
use super::internal::{
    I256, I256_MAX, I256_MIN, I256_NEG_ONE, I256_ONE, I256_ONE_ULP, I256_ZERO, U256_2_POW_128,
    i256_cmp, i256_eq, u256_eq, u256_is_zero,
};

// Re-export Rounding for public API
pub use super::super::common::Rounding;

// ============================================================================
// Public Type and Constants
// ============================================================================

/// A signed Q128.128 fixed-point number.
///
/// Represents decimal values with ~128 bits of integer precision and 128 bits
/// of fractional precision. The internal representation is hidden.
///
/// ## Range
/// - Minimum: approximately -2^128 ≈ -3.4×10^38
/// - Maximum: approximately 2^128 - 2^-128 ≈ 3.4×10^38
/// - Precision: 2^-128 (one ULP)
///
/// ## Serde
/// Serialization goes through `SQ128x128Raw` and `from_raw`, ensuring invariants
/// are validated on deserialization. Invalid values will panic on deserialize.
#[derive(Copy, Drop, Debug)]
pub struct SQ128x128 {
    pub raw: I256,
}

/// The zero value (0.0)
pub const ZERO: SQ128x128 = SQ128x128 { raw: I256_ZERO };

/// The value one (1.0)
pub const ONE: SQ128x128 = SQ128x128 { raw: I256_ONE };

/// The value negative one (-1.0)
pub const NEG_ONE: SQ128x128 = SQ128x128 { raw: I256_NEG_ONE };

/// The minimum representable value (approximately -2^128)
pub const MIN: SQ128x128 = SQ128x128 { raw: I256_MIN };

/// The maximum representable value (approximately 2^128 - 2^-128)
pub const MAX: SQ128x128 = SQ128x128 { raw: I256_MAX };

/// One unit in the last place (ULP) - the smallest positive value (2^-128)
pub const ONE_ULP: SQ128x128 = SQ128x128 { raw: I256_ONE_ULP };

// ============================================================================
// Raw Serialization DTO
// ============================================================================

/// Raw representation for serialization/deserialization.
/// This is intentionally "dumb data" - validation happens via from_raw.
#[derive(Copy, Drop, Serde, Debug)]
pub struct SQ128x128Raw {
    pub limb0: u64,
    pub limb1: u64,
    pub limb2: u64,
    pub limb3: u64,
    pub neg: bool,
}

// ============================================================================
// Trait Implementations
// ============================================================================

pub impl SQ128x128PartialEq of PartialEq<SQ128x128> {
    fn eq(lhs: @SQ128x128, rhs: @SQ128x128) -> bool {
        i256_eq(*lhs.raw, *rhs.raw)
    }
}

pub impl SQ128x128PartialOrd of PartialOrd<SQ128x128> {
    fn lt(lhs: SQ128x128, rhs: SQ128x128) -> bool {
        i256_cmp(lhs.raw, rhs.raw) < 0
    }

    fn le(lhs: SQ128x128, rhs: SQ128x128) -> bool {
        i256_cmp(lhs.raw, rhs.raw) <= 0
    }

    fn gt(lhs: SQ128x128, rhs: SQ128x128) -> bool {
        i256_cmp(lhs.raw, rhs.raw) > 0
    }

    fn ge(lhs: SQ128x128, rhs: SQ128x128) -> bool {
        i256_cmp(lhs.raw, rhs.raw) >= 0
    }
}

pub impl SQ128x128Zero of core::num::traits::Zero<SQ128x128> {
    fn zero() -> SQ128x128 {
        ZERO
    }

    fn is_zero(self: @SQ128x128) -> bool {
        u256_is_zero(*self.raw.mag)
    }

    fn is_non_zero(self: @SQ128x128) -> bool {
        !u256_is_zero(*self.raw.mag)
    }
}

pub impl SQ128x128One of core::num::traits::One<SQ128x128> {
    fn one() -> SQ128x128 {
        ONE
    }

    fn is_one(self: @SQ128x128) -> bool {
        !(*self.raw.neg) && u256_eq(*self.raw.mag, U256_2_POW_128)
    }

    fn is_non_one(self: @SQ128x128) -> bool {
        (*self.raw.neg) || !u256_eq(*self.raw.mag, U256_2_POW_128)
    }
}

pub impl SQ128x128Bounded of Bounded<SQ128x128> {
    const MIN: SQ128x128 = MIN;
    const MAX: SQ128x128 = MAX;
}

pub impl SQ128x128Default of Default<SQ128x128> {
    fn default() -> SQ128x128 {
        ZERO
    }
}

impl SQ128x128Display of core::fmt::Display<SQ128x128> {
    fn fmt(self: @SQ128x128, ref f: core::fmt::Formatter) -> Result<(), core::fmt::Error> {
        if (*self.raw.neg) {
            write!(f, "-")?;
        }
        write!(
            f,
            "SQ128x128(limb0={}, limb1={}, limb2={}, limb3={})/2^128",
            *self.raw.mag.limb0,
            *self.raw.mag.limb1,
            *self.raw.mag.limb2,
            *self.raw.mag.limb3,
        )
    }
}

impl SQ128x128Hash<S, +HashStateTrait<S>, +Drop<S>> of Hash<SQ128x128, S> {
    fn update_state(state: S, value: SQ128x128) -> S {
        let state = state.update(value.raw.mag.limb0.into());
        let state = state.update(value.raw.mag.limb1.into());
        let state = state.update(value.raw.mag.limb2.into());
        let state = state.update(value.raw.mag.limb3.into());
        state.update(if value.raw.neg {
            1
        } else {
            0
        })
    }
}
