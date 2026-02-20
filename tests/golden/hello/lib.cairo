#[starknet::interface]
pub trait IHelloContract<TContractState> {
    fn add_u128(self: @TContractState, lhs: u128, rhs: u128) -> u128;
    fn add_u256(self: @TContractState, lhs: u256, rhs: u256) -> u256;
    fn eq_felt252(self: @TContractState, lhs: felt252, rhs: felt252) -> bool;
    fn max_u128(self: @TContractState, lhs: u128, rhs: u128) -> u128;
}

#[starknet::contract]
mod HelloContract {
    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl HelloContractImpl of super::IHelloContract<ContractState> {
        fn add_u128(self: @ContractState, lhs: u128, rhs: u128) -> u128 {
            (lhs + rhs)
        }

        fn add_u256(self: @ContractState, lhs: u256, rhs: u256) -> u256 {
            (lhs + rhs)
        }

        fn eq_felt252(self: @ContractState, lhs: felt252, rhs: felt252) -> bool {
            (lhs == rhs)
        }

        fn max_u128(self: @ContractState, lhs: u128, rhs: u128) -> u128 {
            {
                let lhs_less_or_equal: bool = (lhs <= rhs);
                if lhs_less_or_equal {
                    rhs
                } else {
                    lhs
                }
            }
        }
    }
}
