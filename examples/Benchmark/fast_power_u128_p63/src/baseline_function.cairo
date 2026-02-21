// Synced from examples/Cairo-Baseline/fast_power_u128_p63/src/lib.cairo
use super::fast_power::fast_power;

pub fn pow63_baseline(x: u128) -> u128 {
    fast_power(x, 63_u128)
}
