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
