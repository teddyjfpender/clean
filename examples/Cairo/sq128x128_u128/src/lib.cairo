#[starknet::interface]
pub trait ISQ128x128U128Contract<TContractState> {
    fn sq128x128_add_raw(self: @TContractState, a_raw: u128, b_raw: u128) -> u128;
    fn sq128x128_sub_raw(self: @TContractState, a_raw: u128, b_raw: u128) -> u128;
    fn sq128x128_mul_raw(self: @TContractState, a_raw: u128, b_raw: u128) -> u128;
    fn sq128x128_delta_raw(self: @TContractState, a_raw: u128, b_raw: u128) -> u128;
    fn sq128x128_affine_kernel(self: @TContractState, a_raw: u128, b_raw: u128, c_raw: u128, d_raw: u128, e_raw: u128) -> u128;
}

#[starknet::contract]
mod SQ128x128U128Contract {
    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl SQ128x128U128ContractImpl of super::ISQ128x128U128Contract<ContractState> {
        fn sq128x128_add_raw(self: @ContractState, a_raw: u128, b_raw: u128) -> u128 {
            (a_raw + b_raw)
        }

        fn sq128x128_sub_raw(self: @ContractState, a_raw: u128, b_raw: u128) -> u128 {
            (a_raw - b_raw)
        }

        fn sq128x128_mul_raw(self: @ContractState, a_raw: u128, b_raw: u128) -> u128 {
            (a_raw * b_raw)
        }

        fn sq128x128_delta_raw(self: @ContractState, a_raw: u128, b_raw: u128) -> u128 {
            (b_raw - a_raw)
        }

        fn sq128x128_affine_kernel(self: @ContractState, a_raw: u128, b_raw: u128, c_raw: u128, d_raw: u128, e_raw: u128) -> u128 {
            {
                let sum_ab: u128 = (a_raw + b_raw);
                {
                    let delta_cd: u128 = (c_raw - d_raw);
                    {
                        let mul_term: u128 = (sum_ab * delta_cd);
                        (mul_term + e_raw)
                    }
                }
            }
        }
    }
}
