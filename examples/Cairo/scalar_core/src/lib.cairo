#[starknet::interface]
pub trait ISierraScalarContract<TContractState> {
    fn felt_affine(self: @TContractState, x: felt252, y: felt252) -> felt252;
    fn eq_felt252(self: @TContractState, lhs: felt252, rhs: felt252) -> bool;
    fn eq_u128(self: @TContractState, lhs: u128, rhs: u128) -> bool;
    fn literal_true(self: @TContractState) -> bool;
    fn identity_bool(self: @TContractState, flag: bool) -> bool;
}

#[starknet::contract]
mod SierraScalarContract {
    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl SierraScalarContractImpl of super::ISierraScalarContract<ContractState> {
        fn felt_affine(self: @ContractState, x: felt252, y: felt252) -> felt252 {
            {
                let sum: felt252 = (x + 7);
                ((sum * y) - x)
            }
        }

        fn eq_felt252(self: @ContractState, lhs: felt252, rhs: felt252) -> bool {
            (lhs == rhs)
        }

        fn eq_u128(self: @ContractState, lhs: u128, rhs: u128) -> bool {
            (lhs == rhs)
        }

        fn literal_true(self: @ContractState) -> bool {
            true
        }

        fn identity_bool(self: @ContractState, flag: bool) -> bool {
            flag
        }
    }
}
