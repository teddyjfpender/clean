//! Constructors and type conversions for SQ128x128.
//!
//! This module contains from_raw, to_raw, from_int constructors and Into implementations.

use super::internal::{U256, from_parts, i256_new, u256_from_u128_shifted_128};
use super::types::{SQ128x128, SQ128x128Raw};
use super::super::common::i128_abs_to_u128;

// ============================================================================
// Public Constructors
// ============================================================================

/// Creates an SQ128x128 from raw limbs with full validation.
/// Returns None if the value is out of range.
pub fn from_raw(raw: SQ128x128Raw) -> Option<SQ128x128> {
    let mag = U256 { limb0: raw.limb0, limb1: raw.limb1, limb2: raw.limb2, limb3: raw.limb3 };
    from_parts(mag, raw.neg)
}

/// Extracts the raw representation for serialization.
pub fn to_raw(value: SQ128x128) -> SQ128x128Raw {
    SQ128x128Raw {
        limb0: value.raw.mag.limb0,
        limb1: value.raw.mag.limb1,
        limb2: value.raw.mag.limb2,
        limb3: value.raw.mag.limb3,
        neg: value.raw.neg,
    }
}

/// Creates an SQ128x128 from an i128 integer.
/// This always succeeds since i128 range fits within SQ128x128's 128-bit integer range.
pub fn from_int(value: i128) -> SQ128x128 {
    let (mag128, neg) = i128_abs_to_u128(value);
    let mag = u256_from_u128_shifted_128(mag128);
    SQ128x128 { raw: i256_new(mag, neg) }
}

// ============================================================================
// Into Trait Implementations
// ============================================================================

pub impl I128IntoSQ128x128 of Into<i128, SQ128x128> {
    fn into(self: i128) -> SQ128x128 {
        from_int(self)
    }
}

pub impl U128IntoSQ128x128 of Into<u128, SQ128x128> {
    fn into(self: u128) -> SQ128x128 {
        let mag = u256_from_u128_shifted_128(self);
        SQ128x128 { raw: i256_new(mag, false) }
    }
}
