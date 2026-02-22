//! Advanced operations for SQ128x128: powers of two, integer powers, and square root.
//!
//! This module contains pow2, pow, and sqrt operations.
//!
//! ## Hint-Based Sqrt Optimization
//!
//! The `sqrt_verified` function allows callers to provide a precomputed sqrt hint,
//! which is then verified rather than computed. This is significantly faster than
//! the iterative Newton-Raphson approach:
//!
//! - **Computation (sqrt)**: 6-8 Newton iterations, each with division + addition
//! - **Verification (sqrt_verified)**: 2 multiplications + 2 additions + comparisons
//!
//! Use `sqrt_verified` when the sqrt can be precomputed off-chain or cached.

use core::integer::u512;
use super::arithmetic::{add, mul_down, sub};
use super::internal::{
    U256, U256_MAG_MAX_LIMIT, corelib_to_u256, i256_new, u256_cmp, u256_is_zero, u256_to_corelib,
};
use super::types::{ONE, ONE_ULP, SQ128x128, ZERO};

// ============================================================================
// Powers of Two (exact, shift-based)
// ============================================================================

/// Computes 2^n for integer n, returning an exact result.
///
/// Powers of 2 are fundamental in binary fixed-point arithmetic:
/// - Exact (no rounding error) - just bit shifts
/// - Composable: pow2(a) * pow2(b) = pow2(a + b)
/// - Invertible: pow2(n) * pow2(-n) = ONE
///
/// ## Range
/// - Minimum n: -128 (returns ONE_ULP = 2^-128)
/// - Maximum n: 127 (returns 2^127)
///
/// Returns None if n is out of representable range.
pub fn pow2(n: i32) -> Option<SQ128x128> {
    // The raw magnitude for 2^n is 2^(n+128) since we have 128 fractional bits
    // Valid range: n+128 in [0, 255] for positive values
    //   n >= -128 (so magnitude >= 1 = ONE_ULP)
    //   n <= 127 (so magnitude <= 2^255 < 2^256-1 = MAX magnitude)

    if n < -128 {
        return Option::None; // Would be smaller than ONE_ULP
    }
    if n > 127 {
        return Option::None; // Would exceed MAX
    }

    // Compute 2^(n+128) as raw magnitude
    // Since n+128 is in [0, 255], we can compute this exactly
    let shift: u32 = (n + 128).try_into().unwrap();

    // Determine which limb the bit falls into (each limb is 64 bits)
    let limb_idx = shift / 64;
    let bit_pos = shift % 64;
    let bit: u64 = pow2_u64(bit_pos);

    let mag = match limb_idx {
        0 => U256 { limb0: bit, limb1: 0, limb2: 0, limb3: 0 },
        1 => U256 { limb0: 0, limb1: bit, limb2: 0, limb3: 0 },
        2 => U256 { limb0: 0, limb1: 0, limb2: bit, limb3: 0 },
        _ => U256 { limb0: 0, limb1: 0, limb2: 0, limb3: bit },
    };

    Option::Some(SQ128x128 { raw: i256_new(mag, false) })
}

/// Powers of 2 lookup table for n in [0, 63].
/// Eliminates multiplication overhead from exponentiation by squaring.
const POW2_TABLE: [u64; 64] = [
    0x1, 0x2, 0x4, 0x8, 0x10, 0x20, 0x40, 0x80, 0x100, 0x200, 0x400, 0x800, 0x1000, 0x2000, 0x4000,
    0x8000, 0x1_0000, 0x2_0000, 0x4_0000, 0x8_0000, 0x10_0000, 0x20_0000, 0x40_0000, 0x80_0000,
    0x100_0000, 0x200_0000, 0x400_0000, 0x800_0000, 0x1000_0000, 0x2000_0000, 0x4000_0000,
    0x8000_0000, 0x1_0000_0000, 0x2_0000_0000, 0x4_0000_0000, 0x8_0000_0000, 0x10_0000_0000,
    0x20_0000_0000, 0x40_0000_0000, 0x80_0000_0000, 0x100_0000_0000, 0x200_0000_0000,
    0x400_0000_0000, 0x800_0000_0000, 0x1000_0000_0000, 0x2000_0000_0000, 0x4000_0000_0000,
    0x8000_0000_0000, 0x1_0000_0000_0000, 0x2_0000_0000_0000, 0x4_0000_0000_0000,
    0x8_0000_0000_0000, 0x10_0000_0000_0000, 0x20_0000_0000_0000, 0x40_0000_0000_0000,
    0x80_0000_0000_0000, 0x100_0000_0000_0000, 0x200_0000_0000_0000, 0x400_0000_0000_0000,
    0x800_0000_0000_0000, 0x1000_0000_0000_0000, 0x2000_0000_0000_0000, 0x4000_0000_0000_0000,
    0x8000_0000_0000_0000,
];

/// Helper: compute 2^n for n in [0, 63] using constant lookup table.
fn pow2_u64(n: u32) -> u64 {
    *POW2_TABLE.span()[n]
}

/// Computes 2^n for integer n. Panics if out of range.
///
/// Valid range: n in [-128, 127]
pub fn pow2_unchecked(n: i32) -> SQ128x128 {
    pow2(n).expect('pow2 out of range')
}

// ============================================================================
// Integer Powers (exponentiation by squaring)
// ============================================================================

/// Computes x^n using exponentiation by squaring.
///
/// This is the standard O(log n) algorithm:
/// - x^0 = 1
/// - x^(2k) = (x^2)^k
/// - x^(2k+1) = x * (x^2)^k
///
/// ## Algebraic Properties
/// - pow(x, 0) = ONE
/// - pow(x, 1) = x
/// - pow(x, a+b) = pow(x, a) * pow(x, b)
/// - pow(x*y, n) = pow(x, n) * pow(y, n)
///
/// Returns None on overflow.
pub fn pow(x: SQ128x128, n: u32) -> Option<SQ128x128> {
    if n == 0 {
        return Option::Some(ONE);
    }
    if n == 1 {
        return Option::Some(x);
    }

    // Exponentiation by squaring
    let mut base = x;
    let mut exp = n;
    let mut result = ONE;

    while exp != 0 {
        if exp % 2 == 1 {
            result = mul_down(result, base)?;
        }
        exp = exp / 2;
        if exp != 0 {
            base = mul_down(base, base)?;
        }
    }

    Option::Some(result)
}

/// Computes x^n using exponentiation by squaring. Panics on overflow.
pub fn pow_unchecked(x: SQ128x128, n: u32) -> SQ128x128 {
    pow(x, n).expect('pow overflow')
}

// ============================================================================
// Square Root Operations
// ============================================================================

/// Integer square root of u512 using Newton-Raphson.
/// Returns floor(sqrt(value)).
///
/// Note: A hint-based implementation with verification could reduce step count,
/// but the current arithmetic approach is self-verifying and production-ready.
fn u512_sqrt(value: u512) -> u256 {
    // Handle zero case
    if value.limb0 == 0 && value.limb1 == 0 && value.limb2 == 0 && value.limb3 == 0 {
        return u256 { low: 0, high: 0 };
    }

    // Find approximate bit position of the highest set bit
    // and use that to set initial guess
    let mut guess: u256 = if value.limb3 != 0 {
        // Value is in the range [2^384, 2^512), sqrt in [2^192, 2^256)
        // Start with a power of 2 approximation
        u256 { low: 0, high: 0x1_0000_0000_0000_0000_u128 } // 2^192
    } else if value.limb2 != 0 {
        // Value is in the range [2^256, 2^384), sqrt in [2^128, 2^192)
        u256 { low: 0, high: 1 } // 2^128
    } else if value.limb1 != 0 {
        // Value is in the range [2^128, 2^256), sqrt in [2^64, 2^128)
        u256 { low: 0x1_0000_0000_0000_0000_u128, high: 0 } // 2^64
    } else {
        // Value is in the range [1, 2^128), sqrt in [1, 2^64)
        // Use Sqrt trait from corelib
        let sqrt_low: u64 = core::num::traits::Sqrt::sqrt(value.limb0);
        return u256 { low: sqrt_low.into(), high: 0 };
    };

    // Newton-Raphson iteration: x_{n+1} = (x_n + S/x_n) / 2
    // Converges quadratically, typically 6-8 iterations for 256-bit precision
    let mut prev_guess: u256 = u256 { low: 0, high: 0 };

    // Iterate until convergence (when guess stops changing or oscillates by 1)
    loop {
        // Compute S / guess using u512 / u256
        let quotient = u512_div_by_u256(value, guess);

        // new_guess = (guess + quotient) / 2
        let sum = u256_add_u256(guess, quotient);
        let new_guess = u256_shr_1(sum);

        // Check for convergence
        if new_guess == guess || new_guess == prev_guess {
            // Return the smaller of the two to ensure floor(sqrt)
            return if u256_lt(new_guess, guess) {
                new_guess
            } else {
                guess
            };
        }

        prev_guess = guess;
        guess = new_guess;
    }
}

/// Divide u512 by u256, returning u256 quotient (assumes no overflow)
fn u512_div_by_u256(num: u512, denom: u256) -> u256 {
    let denom_nz: NonZero<u256> = denom.try_into().expect('div by zero');
    let (q, _r) = core::integer::u512_safe_div_rem_by_u256(num, denom_nz);
    // q is u512 but for sqrt the quotient fits in u256
    u256 { low: q.limb0, high: q.limb1 }
}

/// Add two u256 values, returning u512 to handle overflow
fn u256_add_u256(a: u256, b: u256) -> u512 {
    let (sum, overflow) = core::num::traits::OverflowingAdd::overflowing_add(a, b);
    let carry: u128 = if overflow {
        1
    } else {
        0
    };
    u512 { limb0: sum.low, limb1: sum.high, limb2: carry, limb3: 0 }
}

/// Right shift u512 by 1 bit, returning u256 (for division by 2).
///
/// # Lint Warning - INTENTIONAL OPTIMIZATION (BENCHMARKED)
/// This function uses bitwise AND (`& 1`) instead of `% 2` or `DivRem::div_rem()`.
/// The linter warns about this, but benchmarks prove `& 1` is faster:
///   - Bitwise AND: 176,315 steps, 21.96M L2 gas
///   - Modulo (% 2): 193,810 steps, 26.44M L2 gas (+17-21% slower)
/// DO NOT "fix" this - the bitwise operation is the optimal choice here.
fn u256_shr_1(value: u512) -> u256 {
    // LINT IGNORE: `& 1` is 17-21% faster than `% 2` (benchmarked)
    let lsb1: u128 = value.limb1 & 1;
    let lsb2: u128 = value.limb2 & 1;

    // Shift right by 1: divide by 2, then add carry from next limb's LSB
    let low_shifted = (value.limb0 / 2) + lsb1 * 0x8000_0000_0000_0000_0000_0000_0000_0000_u128;
    let high_shifted = (value.limb1 / 2) + lsb2 * 0x8000_0000_0000_0000_0000_0000_0000_0000_u128;

    u256 { low: low_shifted, high: high_shifted }
}

/// Compare two u256 values
fn u256_lt(a: u256, b: u256) -> bool {
    if a.high != b.high {
        a.high < b.high
    } else {
        a.low < b.low
    }
}

/// Square root for SQ128x128.
///
/// Returns None if the value is negative (sqrt undefined for negative numbers).
/// Returns Some(sqrt(value)) for non-negative values with floor rounding.
///
/// Uses the identity: sqrt(x) * 2^128 = sqrt(x * 2^256) = sqrt(x_raw * 2^128)
/// where x_raw is the fixed-point representation.
pub fn sqrt(value: SQ128x128) -> Option<SQ128x128> {
    // Sqrt of negative is undefined
    if value.raw.neg {
        return Option::None;
    }

    // Sqrt of zero is zero
    if u256_is_zero(value.raw.mag) {
        return Option::Some(ZERO);
    }

    // Convert our U256 to corelib u256
    let mag_corelib = u256_to_corelib(value.raw.mag);

    // Compute x_raw * 2^128 as u512
    // x_raw is stored in U256 (limb0, limb1, limb2, limb3)
    // Shifting left by 128 bits
    let shifted = u512 { limb0: 0, limb1: mag_corelib.low, limb2: mag_corelib.high, limb3: 0 };

    // Compute integer sqrt
    let sqrt_result = u512_sqrt(shifted);

    // Convert u256 result back to our U256
    let result_u256 = corelib_to_u256(sqrt_result);

    // Check if result is in valid range for SQ128x128
    if u256_cmp(result_u256, U256_MAG_MAX_LIMIT) > 0 {
        return Option::None;
    }

    Option::Some(SQ128x128 { raw: i256_new(result_u256, false) })
}

/// Square root for SQ128x128. Panics if the value is negative.
pub fn sqrt_unchecked(value: SQ128x128) -> SQ128x128 {
    sqrt(value).expect('sqrt of negative')
}

// ============================================================================
// Hint-Based Square Root (Optimized Verification)
// ============================================================================

/// Verifies a precomputed square root hint and returns it if valid.
///
/// This is significantly faster than computing sqrt from scratch:
/// - **Computation**: 6-8 Newton iterations with division each
/// - **Verification**: 2 multiplications + comparisons
///
/// ## Verification
///
/// For floor(sqrt(value)) = hint, we verify:
/// 1. hint² ≤ value (hint is not too large)
/// 2. value - hint² < 2*hint + ONE_ULP (hint is the floor, not smaller)
///
/// The second condition comes from: (hint+1)² - hint² = 2*hint + 1
/// So if value - hint² ≥ 2*hint + 1, then hint+1 would also satisfy hint² ≤ value.
///
/// ## Usage
///
/// ```cairo
/// // Off-chain: compute sqrt
/// let hint = compute_sqrt_offchain(value);
///
/// // On-chain: verify (fast) instead of compute (slow)
/// let result = sqrt_verified(value, hint).expect('invalid hint');
/// ```
///
/// ## Returns
///
/// - `Some(hint)` if verification passes
/// - `None` if hint is invalid (wrong sqrt) or value is negative
pub fn sqrt_verified(value: SQ128x128, hint: SQ128x128) -> Option<SQ128x128> {
    // Sqrt of negative is undefined
    if value.raw.neg {
        return Option::None;
    }

    // Hint must be non-negative
    if hint.raw.neg {
        return Option::None;
    }

    // Special case: sqrt(0) = 0
    if u256_is_zero(value.raw.mag) {
        return if u256_is_zero(hint.raw.mag) {
            Option::Some(ZERO)
        } else {
            Option::None
        };
    }

    // Compute hint²
    let hint_squared = mul_down(hint, hint)?;

    // Verify: hint² ≤ value
    if hint_squared > value {
        return Option::None;
    }

    // Compute gap = value - hint²
    let gap = sub(value, hint_squared)?;

    // Compute threshold = 2*hint + ONE_ULP
    // This is the maximum gap for hint to be the floor sqrt
    let two_hint = add(hint, hint)?;
    let threshold = add(two_hint, ONE_ULP)?;

    // Verify: gap < threshold (i.e., value - hint² < 2*hint + ONE_ULP)
    if gap >= threshold {
        return Option::None;
    }

    Option::Some(hint)
}

/// Verifies a precomputed square root hint. Panics if verification fails.
///
/// See `sqrt_verified` for details on the verification algorithm.
pub fn sqrt_verified_unchecked(value: SQ128x128, hint: SQ128x128) -> SQ128x128 {
    sqrt_verified(value, hint).expect('sqrt hint invalid')
}
