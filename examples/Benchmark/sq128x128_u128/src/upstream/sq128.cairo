//! # SQ128x128 Fixed-Point Arithmetic Library
//!
//! A signed Q128.128 fixed-point number type for precise binary fixed-point
//! arithmetic on Starknet. Uses sign-magnitude representation with 128 integer
//! bits (including sign) and 128 fractional bits.
//!
//! ## Module Structure
//!
//! - `types`: Core type definitions (SQ128x128, SQ128x128Raw, constants)
//! - `internal`: Internal implementation details (U256, I256, U512, limb arithmetic)
//! - `arithmetic`: Basic operations (add, sub, mul, div)
//! - `advanced`: Advanced operations (pow, pow2, sqrt, sqrt_verified)
//! - `constructors`: Type constructors (from_raw, to_raw, from_int)
//! - `traits`: Trait implementations (PartialEq, PartialOrd, Add, Sub, etc.)
//!
//! ## Design Principles
//! - **Option-first API**: All arithmetic operations return `Option<SQ128x128>`,
//!   making overflow handling explicit and compositional via `?` operator
//! - `_unchecked` suffix marks panicking variants for performance-critical paths
//! - Representation is hidden; only `SQ128x128` is the public abstraction
//! - Rounding policy is explicit via the `Rounding` enum
//! - Invariants enforced at boundaries via validated constructors
//! - Serde goes through `from_raw` to maintain invariants
//!
//! ## Range and Precision
//! - Range: approximately ±2^128 ≈ ±3.4×10^38
//! - Precision: 2^-128 (same ULP as SQ128x128)
//! - Positive max: 2^128 - 2^-128 (magnitude 2^256 - 1)
//! - Negative min: -2^128 (magnitude 2^256)
//!
//! ## Algebraic Laws
//! - Normalization: `from_raw(to_raw(x))` always produces a normalized value
//! - Delta: `a + delta(a, b) == b`
//! - Negation: for all `x != MIN`, `x + (-x) == ZERO`
//! - Identity: `a * ONE == a`, `a / ONE == a`
//! - Self-division: `a / a == ONE` for `a != ZERO`
//! - Rounding sandwich: `op_down(a, b) <= exact <= op_up(a, b)`

pub mod advanced;
pub mod arithmetic;
pub mod constructors;
pub(crate) mod internal;
pub mod traits;
pub mod types;

// Re-export advanced operations
pub use advanced::{
    pow, pow2, pow2_unchecked, pow_unchecked, sqrt, sqrt_unchecked, sqrt_verified,
    sqrt_verified_unchecked,
};

// Re-export arithmetic operations
pub use arithmetic::{
    add, add_unchecked, delta, div, div_down, div_down_unchecked, div_unchecked, div_up,
    div_up_unchecked, mul, mul_down, mul_down_unchecked, mul_unchecked, mul_up, mul_up_unchecked,
    neg, neg_unchecked, sub, sub_unchecked,
};

// Re-export constructors
pub use constructors::{I128IntoSQ128x128, U128IntoSQ128x128, from_int, from_raw, to_raw};

// Re-export operator trait implementations from traits module
pub use traits::{
    SQ128x128Add, SQ128x128Div, SQ128x128Mul, SQ128x128Neg, SQ128x128Serde, SQ128x128Sub,
};

// Re-export public API from types
pub use types::{MAX, MIN, NEG_ONE, ONE, ONE_ULP, Rounding, SQ128x128, SQ128x128Raw, ZERO};

// Re-export basic trait implementations from types module
pub use types::{
    SQ128x128Bounded, SQ128x128Default, SQ128x128One, SQ128x128PartialEq, SQ128x128PartialOrd,
    SQ128x128Zero,
};
