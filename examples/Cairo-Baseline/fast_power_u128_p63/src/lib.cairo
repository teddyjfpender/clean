//! Alexandria baseline wrapper for fast-power specialization at exponent 63.
//!
//! Source baseline:
//! https://github.com/keep-starknet-strange/alexandria/blob/main/packages/math/src/fast_power.cairo

mod fast_power;

/// Baseline from Alexandria generic fast power specialized to exponent 63.
pub fn pow63_baseline(x: u128) -> u128 {
    fast_power::fast_power(x, 63_u128)
}

#[cfg(test)]
mod tests {
    use super::pow63_baseline;

    #[test]
    fn test_pow63_baseline_smoke() {
        assert(pow63_baseline(2_u128) == 9223372036854775808_u128, 'bad2');
        assert(pow63_baseline(3_u128) == 1144561273430837494885949696427_u128, 'bad3');
    }
}
