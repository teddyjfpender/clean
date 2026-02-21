#[starknet::interface]
pub trait ICryptoRoundContract<TContractState> {
    fn crypto_round(self: @TContractState, x: felt252, y: felt252, z: felt252) -> felt252;
}

#[starknet::contract]
mod CryptoRoundContract {
    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl CryptoRoundContractImpl of super::ICryptoRoundContract<ContractState> {
        fn crypto_round(self: @ContractState, x: felt252, y: felt252, z: felt252) -> felt252 {
            {
                let t0: felt252 = ((x + y) * (z - x));
                {
                    let t1: felt252 = ((t0 + 17) * (y + 3));
                    (t1 - (x * z))
                }
            }
        }
    }
}
