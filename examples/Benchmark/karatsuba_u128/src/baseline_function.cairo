// Synced wrapper for Alexandria baseline karatsuba.
use super::baseline_karatsuba::multiply;

pub fn karatsuba_baseline(x: u128, y: u128) -> u128 {
    multiply(x, y)
}
