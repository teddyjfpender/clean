#[starknet::interface]
pub trait IAggregatePayloadContract<TContractState> {
    fn payload_mix(self: @TContractState, f0: u128, f1: u128, f2: u128, f3: u128) -> u128;
}

#[starknet::contract]
mod AggregatePayloadContract {
    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl AggregatePayloadContractImpl of super::IAggregatePayloadContract<ContractState> {
        fn payload_mix(self: @ContractState, f0: u128, f1: u128, f2: u128, f3: u128) -> u128 {
            {
                let lane0: u128 = (f0 + f1);
                {
                    let lane1: u128 = (f2 + f3);
                    {
                        let mix: u128 = (lane0 * lane1);
                        {
                            let checksum: u128 = (mix + lane0);
                            (checksum - lane1)
                        }
                    }
                }
            }
        }
    }
}
