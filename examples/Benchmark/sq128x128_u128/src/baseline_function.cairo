// Wrappers over freshly pulled upstream SQ128 modules.

use super::upstream::sq128::{
    SQ128x128,
    U128IntoSQ128x128,
    add_unchecked,
    delta,
    mul_down_unchecked,
    sub_unchecked,
    to_raw,
};

const TWO_POW_64: u128 = 0x1_0000_0000_0000_0000_u128;
const TWO_POW_32: u64 = 0x1_0000_0000_u64;
const TWO_POW_16: u32 = 0x1_0000_u32;
const TWO_POW_8: u16 = 0x100_u16;

fn sq_to_u128_integer_unchecked(value: SQ128x128) -> u128 {
    let raw = to_raw(value);
    assert(raw.neg == false, 'sq_neg');
    assert(raw.limb0 == 0_u64, 'sq_frac0');
    assert(raw.limb1 == 0_u64, 'sq_frac1');
    raw.limb2.into() + raw.limb3.into() * TWO_POW_64
}

fn wrap_u64(value: u128) -> u64 {
    (value % TWO_POW_64).try_into().unwrap()
}

fn wrap_u32(value: u64) -> u32 {
    (value % TWO_POW_32).try_into().unwrap()
}

fn wrap_u16(value: u32) -> u16 {
    (value % TWO_POW_16).try_into().unwrap()
}

fn wrap_u8(value: u16) -> u8 {
    (value % TWO_POW_8).try_into().unwrap()
}

pub fn sq128x128_add_raw_baseline_fn(a_raw: u128, b_raw: u128) -> u128 {
    let a: SQ128x128 = a_raw.into();
    let b: SQ128x128 = b_raw.into();
    sq_to_u128_integer_unchecked(add_unchecked(a, b))
}

pub fn sq128x128_sub_raw_baseline_fn(a_raw: u128, b_raw: u128) -> u128 {
    let a: SQ128x128 = a_raw.into();
    let b: SQ128x128 = b_raw.into();
    sq_to_u128_integer_unchecked(sub_unchecked(a, b))
}

pub fn sq128x128_mul_raw_baseline_fn(a_raw: u128, b_raw: u128) -> u128 {
    let a: SQ128x128 = a_raw.into();
    let b: SQ128x128 = b_raw.into();
    sq_to_u128_integer_unchecked(mul_down_unchecked(a, b))
}

pub fn sq128x128_delta_raw_baseline_fn(a_raw: u128, b_raw: u128) -> u128 {
    let a: SQ128x128 = a_raw.into();
    let b: SQ128x128 = b_raw.into();
    sq_to_u128_integer_unchecked(delta(a, b))
}

pub fn sq128x128_affine_kernel_baseline_fn(
    a_raw: u128, b_raw: u128, c_raw: u128, d_raw: u128, e_raw: u128,
) -> u128 {
    let sum_ab = sq128x128_add_raw_baseline_fn(a_raw, b_raw);
    let delta_cd = sq128x128_sub_raw_baseline_fn(c_raw, d_raw);
    let mul_term = sq128x128_mul_raw_baseline_fn(sum_ab, delta_cd);
    sq128x128_add_raw_baseline_fn(mul_term, e_raw)
}

pub fn sq128x128_add_raw_u16_baseline_fn(a_raw: u16, b_raw: u16) -> u16 {
    wrap_u16(a_raw.into() + b_raw.into())
}

pub fn sq128x128_sub_raw_u16_baseline_fn(a_raw: u16, b_raw: u16) -> u16 {
    wrap_u16(a_raw.into() + TWO_POW_16 - b_raw.into())
}

pub fn sq128x128_mul_raw_u16_baseline_fn(a_raw: u16, b_raw: u16) -> u16 {
    wrap_u16(a_raw.into() * b_raw.into())
}

pub fn sq128x128_delta_raw_u16_baseline_fn(a_raw: u16, b_raw: u16) -> u16 {
    sq128x128_sub_raw_u16_baseline_fn(b_raw, a_raw)
}

pub fn sq128x128_affine_kernel_u16_baseline_fn(
    a_raw: u16, b_raw: u16, c_raw: u16, d_raw: u16, e_raw: u16,
) -> u16 {
    let sum_ab = sq128x128_add_raw_u16_baseline_fn(a_raw, b_raw);
    let delta_cd = sq128x128_sub_raw_u16_baseline_fn(c_raw, d_raw);
    let mul_term = sq128x128_mul_raw_u16_baseline_fn(sum_ab, delta_cd);
    sq128x128_add_raw_u16_baseline_fn(mul_term, e_raw)
}

pub fn sq128x128_add_raw_u8_baseline_fn(a_raw: u8, b_raw: u8) -> u8 {
    wrap_u8(a_raw.into() + b_raw.into())
}

pub fn sq128x128_sub_raw_u8_baseline_fn(a_raw: u8, b_raw: u8) -> u8 {
    wrap_u8(a_raw.into() + TWO_POW_8 - b_raw.into())
}

pub fn sq128x128_mul_raw_u8_baseline_fn(a_raw: u8, b_raw: u8) -> u8 {
    wrap_u8(a_raw.into() * b_raw.into())
}

pub fn sq128x128_delta_raw_u8_baseline_fn(a_raw: u8, b_raw: u8) -> u8 {
    sq128x128_sub_raw_u8_baseline_fn(b_raw, a_raw)
}

pub fn sq128x128_affine_kernel_u8_baseline_fn(
    a_raw: u8, b_raw: u8, c_raw: u8, d_raw: u8, e_raw: u8,
) -> u8 {
    let sum_ab = sq128x128_add_raw_u8_baseline_fn(a_raw, b_raw);
    let delta_cd = sq128x128_sub_raw_u8_baseline_fn(c_raw, d_raw);
    let mul_term = sq128x128_mul_raw_u8_baseline_fn(sum_ab, delta_cd);
    sq128x128_add_raw_u8_baseline_fn(mul_term, e_raw)
}

pub fn sq128x128_add_raw_u32_baseline_fn(a_raw: u32, b_raw: u32) -> u32 {
    wrap_u32(a_raw.into() + b_raw.into())
}

pub fn sq128x128_sub_raw_u32_baseline_fn(a_raw: u32, b_raw: u32) -> u32 {
    wrap_u32(a_raw.into() + TWO_POW_32 - b_raw.into())
}

pub fn sq128x128_mul_raw_u32_baseline_fn(a_raw: u32, b_raw: u32) -> u32 {
    wrap_u32(a_raw.into() * b_raw.into())
}

pub fn sq128x128_delta_raw_u32_baseline_fn(a_raw: u32, b_raw: u32) -> u32 {
    sq128x128_sub_raw_u32_baseline_fn(b_raw, a_raw)
}

pub fn sq128x128_affine_kernel_u32_baseline_fn(
    a_raw: u32, b_raw: u32, c_raw: u32, d_raw: u32, e_raw: u32,
) -> u32 {
    let sum_ab = sq128x128_add_raw_u32_baseline_fn(a_raw, b_raw);
    let delta_cd = sq128x128_sub_raw_u32_baseline_fn(c_raw, d_raw);
    let mul_term = sq128x128_mul_raw_u32_baseline_fn(sum_ab, delta_cd);
    sq128x128_add_raw_u32_baseline_fn(mul_term, e_raw)
}

pub fn sq128x128_add_raw_u64_baseline_fn(a_raw: u64, b_raw: u64) -> u64 {
    wrap_u64(a_raw.into() + b_raw.into())
}

pub fn sq128x128_sub_raw_u64_baseline_fn(a_raw: u64, b_raw: u64) -> u64 {
    wrap_u64(a_raw.into() + TWO_POW_64 - b_raw.into())
}

pub fn sq128x128_mul_raw_u64_baseline_fn(a_raw: u64, b_raw: u64) -> u64 {
    wrap_u64(a_raw.into() * b_raw.into())
}

pub fn sq128x128_delta_raw_u64_baseline_fn(a_raw: u64, b_raw: u64) -> u64 {
    sq128x128_sub_raw_u64_baseline_fn(b_raw, a_raw)
}

pub fn sq128x128_affine_kernel_u64_baseline_fn(
    a_raw: u64, b_raw: u64, c_raw: u64, d_raw: u64, e_raw: u64,
) -> u64 {
    let sum_ab = sq128x128_add_raw_u64_baseline_fn(a_raw, b_raw);
    let delta_cd = sq128x128_sub_raw_u64_baseline_fn(c_raw, d_raw);
    let mul_term = sq128x128_mul_raw_u64_baseline_fn(sum_ab, delta_cd);
    sq128x128_add_raw_u64_baseline_fn(mul_term, e_raw)
}
