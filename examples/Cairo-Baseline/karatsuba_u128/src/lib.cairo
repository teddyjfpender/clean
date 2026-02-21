//! Alexandria baseline wrapper for karatsuba u128 multiplication.
//!
//! Source baseline:
//! https://github.com/keep-starknet-strange/alexandria/blob/main/packages/math/src/karatsuba.cairo

mod const_pow;

/// Function to count the number of digits in a number (Alexandria family).
pub fn count_digits_of_base(mut num: u128, base: u128) -> u32 {
    let mut res = 0;
    while (num != 0) {
        num = num / base;
        res += 1;
    }
    res
}

mod karatsuba;

/// Baseline wrapper using Alexandria's recursive `multiply`.
pub fn karatsuba_baseline(x: u128, y: u128) -> u128 {
    karatsuba::multiply(x, y)
}

#[cfg(test)]
mod tests {
    use super::karatsuba_baseline;

    #[test]
    fn test_karatsuba_baseline_smoke() {
        assert(karatsuba_baseline(12_u128, 34_u128) == 408_u128, 'small');
    }
}
