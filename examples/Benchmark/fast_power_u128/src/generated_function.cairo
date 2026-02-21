// Synced from examples/Cairo/fast_power_u128/src/lib.cairo
// Extracted function: pow13_u128 (self removed)

pub fn pow13_generated(x: u128) -> u128 {
            {
                let x2: u128 = {
                let __leancairo_internal_cse_u128: u128 = x;
                (__leancairo_internal_cse_u128 * __leancairo_internal_cse_u128)
            };
                {
                    let x4: u128 = {
                    let __leancairo_internal_cse_u128: u128 = x2;
                    (__leancairo_internal_cse_u128 * __leancairo_internal_cse_u128)
                };
                    {
                        let x8: u128 = {
                        let __leancairo_internal_cse_u128: u128 = x4;
                        (__leancairo_internal_cse_u128 * __leancairo_internal_cse_u128)
                    };
                        {
                            let x12: u128 = (x8 * x4);
                            (x12 * x)
                        }
                    }
                }
            }
        }
