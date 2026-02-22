#[starknet::interface]
pub trait ISQ128x128TypedLaneContract<TContractState> {
    fn sq128x128_add_raw(self: @TContractState, a_lane: u128, b_lane: u128) -> u128;
    fn sq128x128_sub_raw(self: @TContractState, a_lane: u128, b_lane: u128) -> u128;
    fn sq128x128_mul_raw(self: @TContractState, a_lane: u128, b_lane: u128) -> u128;
    fn sq128x128_delta_raw(self: @TContractState, a_lane: u128, b_lane: u128) -> u128;
    fn sq128x128_affine_kernel(self: @TContractState, a_lane: u128, b_lane: u128, c_lane: u128, d_lane: u128, e_lane: u128) -> u128;
}

#[starknet::contract]
mod SQ128x128TypedLaneContract {
    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl SQ128x128TypedLaneContractImpl of super::ISQ128x128TypedLaneContract<ContractState> {
        fn sq128x128_add_raw(self: @ContractState, a_lane: u128, b_lane: u128) -> u128 {
            (a_lane + b_lane)
        }

        fn sq128x128_sub_raw(self: @ContractState, a_lane: u128, b_lane: u128) -> u128 {
            (a_lane - b_lane)
        }

        fn sq128x128_mul_raw(self: @ContractState, a_lane: u128, b_lane: u128) -> u128 {
            (a_lane * b_lane)
        }

        fn sq128x128_delta_raw(self: @ContractState, a_lane: u128, b_lane: u128) -> u128 {
            (b_lane - a_lane)
        }

        fn sq128x128_affine_kernel(self: @ContractState, a_lane: u128, b_lane: u128, c_lane: u128, d_lane: u128, e_lane: u128) -> u128 {
            {
                let sum_ab: u128 = (a_lane + b_lane);
                {
                    let delta_cd: u128 = (c_lane - d_lane);
                    {
                        let mul_term: u128 = (sum_ab * delta_cd);
                        (mul_term + e_lane)
                    }
                }
            }
        }
    }
}
