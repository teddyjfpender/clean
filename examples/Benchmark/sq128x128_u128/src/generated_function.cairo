// Synced from examples/Cairo/sq128x128_u128/src/lib.cairo
// Extracted function: sq128x128_affine_kernel (self removed)

pub fn sq128x128_affine_kernel_generated(a_raw: u128, b_raw: u128, c_raw: u128, d_raw: u128, e_raw: u128) -> u128 {
            {
                let sum_ab: u128 = (a_raw + b_raw);
                {
                    let delta_cd: u128 = (c_raw - d_raw);
                    {
                        let mul_term: u128 = (sum_ab * delta_cd);
                        (mul_term + e_raw)
                    }
                }
            }
        }
