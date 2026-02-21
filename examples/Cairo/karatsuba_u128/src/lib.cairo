#[starknet::interface]
pub trait IKaratsubaU128Contract<TContractState> {
    fn karatsuba_combine(self: @TContractState, x0: u128, x1: u128, y0: u128, y1: u128) -> u128;
}

#[starknet::contract]
mod KaratsubaU128Contract {
    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl KaratsubaU128ContractImpl of super::IKaratsubaU128Contract<ContractState> {
        fn karatsuba_combine(self: @ContractState, x0: u128, x1: u128, y0: u128, y1: u128) -> u128 {
            {
                let z0: u128 = (x0 * y0);
                {
                    let z1: u128 = (x1 * y1);
                    {
                        let z2: u128 = ((x0 + x1) * (y0 + y1));
                        {
                            let cross: u128 = ((z2 - z0) - z1);
                            ((z0 + (cross * 1000000000_u128)) + (z1 * 1000000000000000000_u128))
                        }
                    }
                }
            }
        }
    }
}
