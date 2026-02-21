#[starknet::interface]
pub trait ICircuitGateContract<TContractState> {
    fn gate_constraint(self: @TContractState, a: felt252, b: felt252, c: felt252) -> bool;
}

#[starknet::contract]
mod CircuitGateContract {
    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl CircuitGateContractImpl of super::ICircuitGateContract<ContractState> {
        fn gate_constraint(self: @ContractState, a: felt252, b: felt252, c: felt252) -> bool {
            (((a * b) + c) == ({
                let __leancairo_internal_cse_felt252: felt252 = c;
                (__leancairo_internal_cse_felt252 * __leancairo_internal_cse_felt252)
            } + 5))
        }
    }
}
