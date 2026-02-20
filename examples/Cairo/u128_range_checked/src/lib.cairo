#[starknet::interface]
pub trait ISierraU128RangeCheckedContract<TContractState> {
    fn add_u128_wrapping(self: @TContractState, lhs: u128, rhs: u128) -> u128;
    fn sub_u128_wrapping(self: @TContractState, lhs: u128, rhs: u128) -> u128;
    fn mul_u128_wrapping(self: @TContractState, lhs: u128, rhs: u128) -> u128;
}

#[starknet::contract]
mod SierraU128RangeCheckedContract {
    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl SierraU128RangeCheckedContractImpl of super::ISierraU128RangeCheckedContract<ContractState> {
        fn add_u128_wrapping(self: @ContractState, lhs: u128, rhs: u128) -> u128 {
            (lhs + rhs)
        }

        fn sub_u128_wrapping(self: @ContractState, lhs: u128, rhs: u128) -> u128 {
            (lhs - rhs)
        }

        fn mul_u128_wrapping(self: @ContractState, lhs: u128, rhs: u128) -> u128 {
            (lhs * rhs)
        }
    }
}
