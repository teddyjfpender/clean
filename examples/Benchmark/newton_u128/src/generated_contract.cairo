#[starknet::interface]
pub trait INewtonU128Contract<TContractState> {
    fn newton_reciprocal_step(self: @TContractState, a: u128, x: u128) -> u128;
    fn newton_reciprocal_two_steps(self: @TContractState, a: u128, x0: u128) -> u128;
    fn newton_reciprocal_residual_after_step(self: @TContractState, a: u128, x0: u128) -> u128;
}

#[starknet::contract]
mod NewtonU128Contract {
    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl NewtonU128ContractImpl of super::INewtonU128Contract<ContractState> {
        fn newton_reciprocal_step(self: @ContractState, a: u128, x: u128) -> u128 {
            {
                let ax: u128 = (a * x);
                {
                    let two_minus_ax: u128 = (2_u128 - ax);
                    (x * two_minus_ax)
                }
            }
        }

        fn newton_reciprocal_two_steps(self: @ContractState, a: u128, x0: u128) -> u128 {
            {
                let x1: u128 = {
                let ax: u128 = (a * x0);
                {
                    let two_minus_ax: u128 = (2_u128 - ax);
                    (x0 * two_minus_ax)
                }
            };
                {
                    let ax: u128 = (a * x1);
                    {
                        let two_minus_ax: u128 = (2_u128 - ax);
                        (x1 * two_minus_ax)
                    }
                }
            }
        }

        fn newton_reciprocal_residual_after_step(self: @ContractState, a: u128, x0: u128) -> u128 {
            ({
                let ax: u128 = (a * x0);
                {
                    let two_minus_ax: u128 = (2_u128 - ax);
                    (x0 * two_minus_ax)
                }
            } - x0)
        }
    }
}
