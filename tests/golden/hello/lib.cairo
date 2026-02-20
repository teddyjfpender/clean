#[starknet::interface]
pub trait IHelloContract<TContractState> {
    fn add_u128(self: @TContractState, lhs: u128, rhs: u128) -> u128;
    fn add_u256(self: @TContractState, lhs: u256, rhs: u256) -> u256;
    fn eq_felt252(self: @TContractState, lhs: felt252, rhs: felt252) -> bool;
    fn max_u128(self: @TContractState, lhs: u128, rhs: u128) -> u128;
    fn read_counter(self: @TContractState) -> u128;
    fn increment_counter(ref self: TContractState, amount: u128) -> u128;
}

#[starknet::contract]
mod HelloContract {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        counter: u128,
    }

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

        fn read_counter(self: @ContractState) -> u128 {
            self.counter.read()
        }

        fn increment_counter(ref self: ContractState, amount: u128) -> u128 {
            let __leancairo_internal_write_0: u128 = (self.counter.read() + amount);
            let __leancairo_internal_return_value: u128 = (self.counter.read() + amount);
            self.counter.write(__leancairo_internal_write_0);
            __leancairo_internal_return_value
        }
    }
}
