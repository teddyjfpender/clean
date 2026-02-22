// Synced from examples/Cairo/sq128x128_u128/src/lib.cairo
// Extracted generated functions with `self: @ContractState` removed.

pub fn sq128x128_add_raw_generated(a_lane: u128, b_lane: u128) -> u128 {
            (a_lane + b_lane)
        }

pub fn sq128x128_sub_raw_generated(a_lane: u128, b_lane: u128) -> u128 {
            (a_lane - b_lane)
        }

pub fn sq128x128_mul_raw_generated(a_lane: u128, b_lane: u128) -> u128 {
            (a_lane * b_lane)
        }

pub fn sq128x128_delta_raw_generated(a_lane: u128, b_lane: u128) -> u128 {
            (b_lane - a_lane)
        }

pub fn sq128x128_affine_kernel_generated(a_lane: u128, b_lane: u128, c_lane: u128, d_lane: u128, e_lane: u128) -> u128 {
            {
                let sum_ab: u128 = (a_lane + b_lane);
                {
                    let delta_cd: u128 = (c_lane - d_lane);
                    {
                        let mul_term: u128 = (sum_ab * delta_cd);
                        (mul_term + e_lane)
                    }
                }
            }
        }
