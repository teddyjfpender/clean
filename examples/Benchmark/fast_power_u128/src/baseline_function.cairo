// Synced from examples/Cairo-Baseline/fast_power_u128/src/lib.cairo
use super::fast_power::fast_power;

pub fn pow13_baseline(x: u128) -> u128 {
    fast_power(x, 13_u128)
}
