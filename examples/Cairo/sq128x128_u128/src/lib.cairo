#[starknet::interface]
pub trait ISQ128x128TypedLaneContract<TContractState> {
    fn sq128x128_add_raw(self: @TContractState, a_lane: u128, b_lane: u128) -> u128;
    fn sq128x128_sub_raw(self: @TContractState, a_lane: u128, b_lane: u128) -> u128;
    fn sq128x128_mul_raw(self: @TContractState, a_lane: u128, b_lane: u128) -> u128;
    fn sq128x128_delta_raw(self: @TContractState, a_lane: u128, b_lane: u128) -> u128;
    fn sq128x128_affine_kernel(self: @TContractState, a_lane: u128, b_lane: u128, c_lane: u128, d_lane: u128, e_lane: u128) -> u128;
    fn sq128x128_add_raw_u64(self: @TContractState, a_lane: u64, b_lane: u64) -> u64;
    fn sq128x128_sub_raw_u64(self: @TContractState, a_lane: u64, b_lane: u64) -> u64;
    fn sq128x128_mul_raw_u64(self: @TContractState, a_lane: u64, b_lane: u64) -> u64;
    fn sq128x128_delta_raw_u64(self: @TContractState, a_lane: u64, b_lane: u64) -> u64;
    fn sq128x128_affine_kernel_u64(self: @TContractState, a_lane: u64, b_lane: u64, c_lane: u64, d_lane: u64, e_lane: u64) -> u64;
    fn sq128x128_add_raw_u32(self: @TContractState, a_lane: u32, b_lane: u32) -> u32;
    fn sq128x128_sub_raw_u32(self: @TContractState, a_lane: u32, b_lane: u32) -> u32;
    fn sq128x128_mul_raw_u32(self: @TContractState, a_lane: u32, b_lane: u32) -> u32;
    fn sq128x128_delta_raw_u32(self: @TContractState, a_lane: u32, b_lane: u32) -> u32;
    fn sq128x128_affine_kernel_u32(self: @TContractState, a_lane: u32, b_lane: u32, c_lane: u32, d_lane: u32, e_lane: u32) -> u32;
    fn sq128x128_add_raw_u16(self: @TContractState, a_lane: u16, b_lane: u16) -> u16;
    fn sq128x128_sub_raw_u16(self: @TContractState, a_lane: u16, b_lane: u16) -> u16;
    fn sq128x128_mul_raw_u16(self: @TContractState, a_lane: u16, b_lane: u16) -> u16;
    fn sq128x128_delta_raw_u16(self: @TContractState, a_lane: u16, b_lane: u16) -> u16;
    fn sq128x128_affine_kernel_u16(self: @TContractState, a_lane: u16, b_lane: u16, c_lane: u16, d_lane: u16, e_lane: u16) -> u16;
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

        fn sq128x128_add_raw_u64(self: @ContractState, a_lane: u64, b_lane: u64) -> u64 {
            (a_lane + b_lane)
        }

        fn sq128x128_sub_raw_u64(self: @ContractState, a_lane: u64, b_lane: u64) -> u64 {
            (a_lane - b_lane)
        }

        fn sq128x128_mul_raw_u64(self: @ContractState, a_lane: u64, b_lane: u64) -> u64 {
            (a_lane * b_lane)
        }

        fn sq128x128_delta_raw_u64(self: @ContractState, a_lane: u64, b_lane: u64) -> u64 {
            (b_lane - a_lane)
        }

        fn sq128x128_affine_kernel_u64(self: @ContractState, a_lane: u64, b_lane: u64, c_lane: u64, d_lane: u64, e_lane: u64) -> u64 {
            {
                let sum_ab: u64 = (a_lane + b_lane);
                {
                    let delta_cd: u64 = (c_lane - d_lane);
                    {
                        let mul_term: u64 = (sum_ab * delta_cd);
                        (mul_term + e_lane)
                    }
                }
            }
        }

        fn sq128x128_add_raw_u32(self: @ContractState, a_lane: u32, b_lane: u32) -> u32 {
            (a_lane + b_lane)
        }

        fn sq128x128_sub_raw_u32(self: @ContractState, a_lane: u32, b_lane: u32) -> u32 {
            (a_lane - b_lane)
        }

        fn sq128x128_mul_raw_u32(self: @ContractState, a_lane: u32, b_lane: u32) -> u32 {
            (a_lane * b_lane)
        }

        fn sq128x128_delta_raw_u32(self: @ContractState, a_lane: u32, b_lane: u32) -> u32 {
            (b_lane - a_lane)
        }

        fn sq128x128_affine_kernel_u32(self: @ContractState, a_lane: u32, b_lane: u32, c_lane: u32, d_lane: u32, e_lane: u32) -> u32 {
            {
                let sum_ab: u32 = (a_lane + b_lane);
                {
                    let delta_cd: u32 = (c_lane - d_lane);
                    {
                        let mul_term: u32 = (sum_ab * delta_cd);
                        (mul_term + e_lane)
                    }
                }
            }
        }

        fn sq128x128_add_raw_u16(self: @ContractState, a_lane: u16, b_lane: u16) -> u16 {
            (a_lane + b_lane)
        }

        fn sq128x128_sub_raw_u16(self: @ContractState, a_lane: u16, b_lane: u16) -> u16 {
            (a_lane - b_lane)
        }

        fn sq128x128_mul_raw_u16(self: @ContractState, a_lane: u16, b_lane: u16) -> u16 {
            (a_lane * b_lane)
        }

        fn sq128x128_delta_raw_u16(self: @ContractState, a_lane: u16, b_lane: u16) -> u16 {
            (b_lane - a_lane)
        }

        fn sq128x128_affine_kernel_u16(self: @ContractState, a_lane: u16, b_lane: u16, c_lane: u16, d_lane: u16, e_lane: u16) -> u16 {
            {
                let sum_ab: u16 = (a_lane + b_lane);
                {
                    let delta_cd: u16 = (c_lane - d_lane);
                    {
                        let mul_term: u16 = (sum_ab * delta_cd);
                        (mul_term + e_lane)
                    }
                }
            }
        }
    }
}
