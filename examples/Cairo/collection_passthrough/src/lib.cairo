#[starknet::interface]
pub trait ICollectionPassthroughContract<TContractState> {
    fn array_passthrough(self: @TContractState, value: Array<felt252>) -> Array<felt252>;
    fn span_passthrough(self: @TContractState, value: Span<felt252>) -> Span<felt252>;
    fn nullable_passthrough(self: @TContractState, value: Nullable<felt252>) -> Nullable<felt252>;
    fn boxed_passthrough(self: @TContractState, value: Box<felt252>) -> Box<felt252>;
}

#[starknet::contract]
mod CollectionPassthroughContract {
    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl CollectionPassthroughContractImpl of super::ICollectionPassthroughContract<ContractState> {
        fn array_passthrough(self: @ContractState, value: Array<felt252>) -> Array<felt252> {
            value
        }

        fn span_passthrough(self: @ContractState, value: Span<felt252>) -> Span<felt252> {
            value
        }

        fn nullable_passthrough(self: @ContractState, value: Nullable<felt252>) -> Nullable<felt252> {
            value
        }

        fn boxed_passthrough(self: @ContractState, value: Box<felt252>) -> Box<felt252> {
            value
        }
    }
}
