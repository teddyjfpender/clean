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

pub fn sq128x128_add_raw_u8_generated(a_lane: u8, b_lane: u8) -> u8 {
            (a_lane + b_lane)
        }

pub fn sq128x128_sub_raw_u8_generated(a_lane: u8, b_lane: u8) -> u8 {
            (a_lane - b_lane)
        }

pub fn sq128x128_mul_raw_u8_generated(a_lane: u8, b_lane: u8) -> u8 {
            (a_lane * b_lane)
        }

pub fn sq128x128_delta_raw_u8_generated(a_lane: u8, b_lane: u8) -> u8 {
            (b_lane - a_lane)
        }

pub fn sq128x128_affine_kernel_u8_generated(a_lane: u8, b_lane: u8, c_lane: u8, d_lane: u8, e_lane: u8) -> u8 {
            {
                let sum_ab: u8 = (a_lane + b_lane);
                {
                    let delta_cd: u8 = (c_lane - d_lane);
                    {
                        let mul_term: u8 = (sum_ab * delta_cd);
                        (mul_term + e_lane)
                    }
                }
            }
        }

pub fn sq128x128_add_raw_i16_generated(a_lane: i16, b_lane: i16) -> i16 {
            (a_lane + b_lane)
        }

pub fn sq128x128_sub_raw_i16_generated(a_lane: i16, b_lane: i16) -> i16 {
            (a_lane - b_lane)
        }

pub fn sq128x128_mul_raw_i16_generated(a_lane: i16, b_lane: i16) -> i16 {
            (a_lane * b_lane)
        }

pub fn sq128x128_delta_raw_i16_generated(a_lane: i16, b_lane: i16) -> i16 {
            (b_lane - a_lane)
        }

pub fn sq128x128_affine_kernel_i16_generated(a_lane: i16, b_lane: i16, c_lane: i16, d_lane: i16, e_lane: i16) -> i16 {
            {
                let sum_ab: i16 = (a_lane + b_lane);
                {
                    let delta_cd: i16 = (c_lane - d_lane);
                    {
                        let mul_term: i16 = (sum_ab * delta_cd);
                        (mul_term + e_lane)
                    }
                }
            }
        }

pub fn sq128x128_add_raw_u16_generated(a_lane: u16, b_lane: u16) -> u16 {
            (a_lane + b_lane)
        }

pub fn sq128x128_sub_raw_u16_generated(a_lane: u16, b_lane: u16) -> u16 {
            (a_lane - b_lane)
        }

pub fn sq128x128_mul_raw_u16_generated(a_lane: u16, b_lane: u16) -> u16 {
            (a_lane * b_lane)
        }

pub fn sq128x128_delta_raw_u16_generated(a_lane: u16, b_lane: u16) -> u16 {
            (b_lane - a_lane)
        }

pub fn sq128x128_affine_kernel_u16_generated(a_lane: u16, b_lane: u16, c_lane: u16, d_lane: u16, e_lane: u16) -> u16 {
            {
                let sum_ab: u16 = (a_lane + b_lane);
                {
                    let delta_cd: u16 = (c_lane - d_lane);
                    {
                        let mul_term: u16 = (sum_ab * delta_cd);
                        (mul_term + e_lane)
                    }
                }
            }
        }

pub fn sq128x128_add_raw_u32_generated(a_lane: u32, b_lane: u32) -> u32 {
            (a_lane + b_lane)
        }

pub fn sq128x128_sub_raw_u32_generated(a_lane: u32, b_lane: u32) -> u32 {
            (a_lane - b_lane)
        }

pub fn sq128x128_mul_raw_u32_generated(a_lane: u32, b_lane: u32) -> u32 {
            (a_lane * b_lane)
        }

pub fn sq128x128_delta_raw_u32_generated(a_lane: u32, b_lane: u32) -> u32 {
            (b_lane - a_lane)
        }

pub fn sq128x128_affine_kernel_u32_generated(a_lane: u32, b_lane: u32, c_lane: u32, d_lane: u32, e_lane: u32) -> u32 {
            {
                let sum_ab: u32 = (a_lane + b_lane);
                {
                    let delta_cd: u32 = (c_lane - d_lane);
                    {
                        let mul_term: u32 = (sum_ab * delta_cd);
                        (mul_term + e_lane)
                    }
                }
            }
        }

pub fn sq128x128_add_raw_u64_generated(a_lane: u64, b_lane: u64) -> u64 {
            (a_lane + b_lane)
        }

pub fn sq128x128_sub_raw_u64_generated(a_lane: u64, b_lane: u64) -> u64 {
            (a_lane - b_lane)
        }

pub fn sq128x128_mul_raw_u64_generated(a_lane: u64, b_lane: u64) -> u64 {
            (a_lane * b_lane)
        }

pub fn sq128x128_delta_raw_u64_generated(a_lane: u64, b_lane: u64) -> u64 {
            (b_lane - a_lane)
        }

pub fn sq128x128_affine_kernel_u64_generated(a_lane: u64, b_lane: u64, c_lane: u64, d_lane: u64, e_lane: u64) -> u64 {
            {
                let sum_ab: u64 = (a_lane + b_lane);
                {
                    let delta_cd: u64 = (c_lane - d_lane);
                    {
                        let mul_term: u64 = (sum_ab * delta_cd);
                        (mul_term + e_lane)
                    }
                }
            }
        }
