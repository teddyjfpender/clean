#[starknet::interface]
pub trait IFastPowerU128Contract<TContractState> {
    fn pow13_u128(self: @TContractState, x: u128) -> u128;
}

#[starknet::contract]
mod FastPowerU128Contract {
    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl FastPowerU128ContractImpl of super::IFastPowerU128Contract<ContractState> {
        fn pow13_u128(self: @ContractState, x: u128) -> u128 {
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
    }
}
