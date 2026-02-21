// Wrapper to keep benchmark call-sites stable.
use super::baseline_arithmetic::sq128x128_affine_kernel_baseline;

pub fn sq128x128_affine_kernel_baseline_fn(
    a_raw: u128, b_raw: u128, c_raw: u128, d_raw: u128, e_raw: u128
) -> u128 {
    sq128x128_affine_kernel_baseline(a_raw, b_raw, c_raw, d_raw, e_raw)
}
