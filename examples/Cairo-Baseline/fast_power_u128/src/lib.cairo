//! Alexandria baseline wrapper for fast power specialization.
//!
//! Source baseline:
//! https://github.com/keep-starknet-strange/alexandria/blob/main/packages/math/src/fast_power.cairo

mod fast_power;

/// Baseline from Alexandria generic fast power specialized to exponent 13.
pub fn pow13_baseline(x: u128) -> u128 {
    fast_power::fast_power(x, 13_u128)
}

#[cfg(test)]
mod tests {
    use super::pow13_baseline;

    #[test]
    fn test_pow13_baseline_smoke() {
        assert(pow13_baseline(7_u128) == 96889010407_u128, 'bad');
    }
}
