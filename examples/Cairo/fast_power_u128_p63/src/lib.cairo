#[starknet::interface]
pub trait IFastPowerU128P63Contract<TContractState> {
    fn pow63_u128(self: @TContractState, x: u128) -> u128;
}

#[starknet::contract]
mod FastPowerU128P63Contract {
    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl FastPowerU128P63ContractImpl of super::IFastPowerU128P63Contract<ContractState> {
        fn pow63_u128(self: @ContractState, x: u128) -> u128 {
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
                            let x16: u128 = {
                            let __leancairo_internal_cse_u128: u128 = x8;
                            (__leancairo_internal_cse_u128 * __leancairo_internal_cse_u128)
                        };
                            {
                                let x32: u128 = {
                                let __leancairo_internal_cse_u128: u128 = x16;
                                (__leancairo_internal_cse_u128 * __leancairo_internal_cse_u128)
                            };
                                {
                                    let x48: u128 = (x32 * x16);
                                    {
                                        let x56: u128 = (x48 * x8);
                                        {
                                            let x60: u128 = (x56 * x4);
                                            {
                                                let x62: u128 = (x60 * x2);
                                                (x62 * x)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
