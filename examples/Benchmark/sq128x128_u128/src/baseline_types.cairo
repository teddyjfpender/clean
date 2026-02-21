//! Reduced SQ128x128 type lane for benchmark baselines.
//! Derived from SQ128x128 type shape in upstream `sq128/types.cairo`.

#[derive(Copy, Drop, Debug)]
pub struct SQ128x128 {
    pub raw: u128,
}

pub const ZERO: SQ128x128 = SQ128x128 { raw: 0_u128 };
pub const ONE_ULP: SQ128x128 = SQ128x128 { raw: 1_u128 };
