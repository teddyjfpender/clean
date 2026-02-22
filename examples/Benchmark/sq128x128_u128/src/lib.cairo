mod upstream;
mod baseline_function;
mod generated_function;

#[cfg(test)]
mod tests {
    use super::baseline_function::{
        sq128x128_add_raw_baseline_fn,
        sq128x128_add_raw_i16_baseline_fn,
        sq128x128_add_raw_u8_baseline_fn,
        sq128x128_add_raw_u16_baseline_fn,
        sq128x128_add_raw_u32_baseline_fn,
        sq128x128_add_raw_u64_baseline_fn,
        sq128x128_affine_kernel_baseline_fn,
        sq128x128_affine_kernel_i16_baseline_fn,
        sq128x128_affine_kernel_u8_baseline_fn,
        sq128x128_affine_kernel_u16_baseline_fn,
        sq128x128_affine_kernel_u32_baseline_fn,
        sq128x128_affine_kernel_u64_baseline_fn,
        sq128x128_delta_raw_baseline_fn,
        sq128x128_delta_raw_i16_baseline_fn,
        sq128x128_delta_raw_u8_baseline_fn,
        sq128x128_delta_raw_u16_baseline_fn,
        sq128x128_delta_raw_u32_baseline_fn,
        sq128x128_delta_raw_u64_baseline_fn,
        sq128x128_mul_raw_baseline_fn,
        sq128x128_mul_raw_i16_baseline_fn,
        sq128x128_mul_raw_u8_baseline_fn,
        sq128x128_mul_raw_u16_baseline_fn,
        sq128x128_mul_raw_u32_baseline_fn,
        sq128x128_mul_raw_u64_baseline_fn,
        sq128x128_sub_raw_baseline_fn,
        sq128x128_sub_raw_i16_baseline_fn,
        sq128x128_sub_raw_u8_baseline_fn,
        sq128x128_sub_raw_u16_baseline_fn,
        sq128x128_sub_raw_u32_baseline_fn,
        sq128x128_sub_raw_u64_baseline_fn,
    };
    use super::generated_function::{
        sq128x128_add_raw_generated,
        sq128x128_add_raw_i16_generated,
        sq128x128_add_raw_u8_generated,
        sq128x128_add_raw_u16_generated,
        sq128x128_add_raw_u32_generated,
        sq128x128_add_raw_u64_generated,
        sq128x128_affine_kernel_generated,
        sq128x128_affine_kernel_i16_generated,
        sq128x128_affine_kernel_u8_generated,
        sq128x128_affine_kernel_u16_generated,
        sq128x128_affine_kernel_u32_generated,
        sq128x128_affine_kernel_u64_generated,
        sq128x128_delta_raw_generated,
        sq128x128_delta_raw_i16_generated,
        sq128x128_delta_raw_u8_generated,
        sq128x128_delta_raw_u16_generated,
        sq128x128_delta_raw_u32_generated,
        sq128x128_delta_raw_u64_generated,
        sq128x128_mul_raw_generated,
        sq128x128_mul_raw_i16_generated,
        sq128x128_mul_raw_u8_generated,
        sq128x128_mul_raw_u16_generated,
        sq128x128_mul_raw_u32_generated,
        sq128x128_mul_raw_u64_generated,
        sq128x128_sub_raw_generated,
        sq128x128_sub_raw_i16_generated,
        sq128x128_sub_raw_u8_generated,
        sq128x128_sub_raw_u16_generated,
        sq128x128_sub_raw_u32_generated,
        sq128x128_sub_raw_u64_generated,
    };

    const ROUNDS: usize = 4096_usize;

    const EXPECTED_ADD_ACC: u128 = 142675968_u128;
    const EXPECTED_SUB_ACC: u128 = 1769978693632_u128;
    const EXPECTED_MUL_ACC: u128 = 1377469941760_u128;
    const EXPECTED_DELTA_ACC: u128 = 88014848_u128;
    const EXPECTED_AFFINE_ACC: u128 = 517251495936_u128;

    const EXPECTED_ADD_U16_ACC: u128 = 132233216_u128;
    const EXPECTED_SUB_U16_ACC: u128 = 131479552_u128;
    const EXPECTED_MUL_U16_ACC: u128 = 121821184_u128;
    const EXPECTED_DELTA_U16_ACC: u128 = 40708096_u128;
    const EXPECTED_AFFINE_U16_ACC: u128 = 49674240_u128;

    const EXPECTED_ADD_U8_ACC: u128 = 307200_u128;
    const EXPECTED_SUB_U8_ACC: u128 = 538624_u128;
    const EXPECTED_MUL_U8_ACC: u128 = 925696_u128;
    const EXPECTED_DELTA_U8_ACC: u128 = 405504_u128;
    const EXPECTED_AFFINE_U8_ACC: u128 = 677888_u128;

    const EXPECTED_ADD_I16_ACC: i32 = 17520640_i32;
    const EXPECTED_SUB_I16_ACC: i32 = 21364736_i32;
    const EXPECTED_MUL_I16_ACC: i32 = 99149824_i32;
    const EXPECTED_DELTA_I16_ACC: i32 = 8370176_i32;
    const EXPECTED_AFFINE_I16_ACC: i32 = 49674240_i32;

    const EXPECTED_ADD_U32_ACC: u128 = 6280535377920_u128;
    const EXPECTED_SUB_U32_ACC: u128 = 7939160496128_u128;
    const EXPECTED_MUL_U32_ACC: u128 = 1377469941760_u128;
    const EXPECTED_DELTA_U32_ACC: u128 = 2133967480832_u128;
    const EXPECTED_AFFINE_U32_ACC: u128 = 517355839488_u128;

    const EXPECTED_ADD_U64_ACC: u128 = 18568535377920_u128;
    const EXPECTED_SUB_U64_ACC: u128 = 38659160496128_u128;
    const EXPECTED_MUL_U64_ACC: u128 = 1414409368858624_u128;
    const EXPECTED_DELTA_U64_ACC: u128 = 2133967480832_u128;
    const EXPECTED_AFFINE_U64_ACC: u128 = 517264233351168000_u128;

    fn add_inputs(i: usize) -> (u128, u128) {
        if i % 2_usize == 0_usize {
            (1000_u128, 2000_u128)
        } else {
            (12345_u128, 54321_u128)
        }
    }

    fn sub_inputs(i: usize) -> (u128, u128) {
        if i % 2_usize == 0_usize {
            (50000_u128, 123_u128)
        } else {
            (987654321_u128, 123456789_u128)
        }
    }

    fn mul_inputs(i: usize) -> (u128, u128) {
        if i % 2_usize == 0_usize {
            (1000_u128, 2000_u128)
        } else {
            (12345_u128, 54321_u128)
        }
    }

    fn delta_inputs(i: usize) -> (u128, u128) {
        if i % 2_usize == 0_usize {
            (1000_u128, 2000_u128)
        } else {
            (12345_u128, 54321_u128)
        }
    }

    fn affine_inputs(i: usize) -> (u128, u128, u128, u128, u128) {
        if i % 2_usize == 0_usize {
            (1000_u128, 2000_u128, 700_u128, 200_u128, 9_u128)
        } else {
            (12345_u128, 54321_u128, 5000_u128, 1234_u128, 42_u128)
        }
    }

    fn add_u16_inputs(i: usize) -> (u16, u16) {
        if i % 2_usize == 0_usize {
            (10000_u16, 20000_u16)
        } else {
            (12345_u16, 22222_u16)
        }
    }

    fn add_u8_inputs(i: usize) -> (u8, u8) {
        if i % 2_usize == 0_usize {
            (10_u8, 20_u8)
        } else {
            (50_u8, 70_u8)
        }
    }

    fn sub_u16_inputs(i: usize) -> (u16, u16) {
        if i % 2_usize == 0_usize {
            (60000_u16, 12345_u16)
        } else {
            (40000_u16, 23456_u16)
        }
    }

    fn sub_u8_inputs(i: usize) -> (u8, u8) {
        if i % 2_usize == 0_usize {
            (200_u8, 123_u8)
        } else {
            (220_u8, 34_u8)
        }
    }

    fn mul_u16_inputs(i: usize) -> (u16, u16) {
        if i % 2_usize == 0_usize {
            (100_u16, 200_u16)
        } else {
            (123_u16, 321_u16)
        }
    }

    fn mul_u8_inputs(i: usize) -> (u8, u8) {
        if i % 2_usize == 0_usize {
            (10_u8, 20_u8)
        } else {
            (12_u8, 21_u8)
        }
    }

    fn delta_u16_inputs(i: usize) -> (u16, u16) {
        if i % 2_usize == 0_usize {
            (10000_u16, 20000_u16)
        } else {
            (12345_u16, 22222_u16)
        }
    }

    fn delta_u8_inputs(i: usize) -> (u8, u8) {
        if i % 2_usize == 0_usize {
            (100_u8, 200_u8)
        } else {
            (123_u8, 221_u8)
        }
    }

    fn affine_u16_inputs(i: usize) -> (u16, u16, u16, u16, u16) {
        if i % 2_usize == 0_usize {
            (10_u16, 20_u16, 70_u16, 20_u16, 9_u16)
        } else {
            (123_u16, 221_u16, 300_u16, 234_u16, 42_u16)
        }
    }

    fn affine_u8_inputs(i: usize) -> (u8, u8, u8, u8, u8) {
        if i % 2_usize == 0_usize {
            (5_u8, 10_u8, 20_u8, 5_u8, 3_u8)
        } else {
            (12_u8, 8_u8, 25_u8, 20_u8, 3_u8)
        }
    }

    fn add_i16_inputs(i: usize) -> (i16, i16) {
        if i % 2_usize == 0_usize {
            (1000_i16, 2000_i16)
        } else {
            (1234_i16, 4321_i16)
        }
    }

    fn sub_i16_inputs(i: usize) -> (i16, i16) {
        if i % 2_usize == 0_usize {
            (5000_i16, 123_i16)
        } else {
            (9876_i16, 4321_i16)
        }
    }

    fn mul_i16_inputs(i: usize) -> (i16, i16) {
        if i % 2_usize == 0_usize {
            (100_i16, 200_i16)
        } else {
            (123_i16, 231_i16)
        }
    }

    fn delta_i16_inputs(i: usize) -> (i16, i16) {
        if i % 2_usize == 0_usize {
            (1000_i16, 2000_i16)
        } else {
            (1234_i16, 4321_i16)
        }
    }

    fn affine_i16_inputs(i: usize) -> (i16, i16, i16, i16, i16) {
        if i % 2_usize == 0_usize {
            (10_i16, 20_i16, 70_i16, 20_i16, 9_i16)
        } else {
            (123_i16, 221_i16, 300_i16, 234_i16, 42_i16)
        }
    }

    fn add_u32_inputs(i: usize) -> (u32, u32) {
        if i % 2_usize == 0_usize {
            (1000000000_u32, 2000000000_u32)
        } else {
            (12345678_u32, 54321987_u32)
        }
    }

    fn sub_u32_inputs(i: usize) -> (u32, u32) {
        if i % 2_usize == 0_usize {
            (3000000000_u32, 123456789_u32)
        } else {
            (1234567890_u32, 234567890_u32)
        }
    }

    fn mul_u32_inputs(i: usize) -> (u32, u32) {
        if i % 2_usize == 0_usize {
            (1000_u32, 2000_u32)
        } else {
            (12345_u32, 54321_u32)
        }
    }

    fn delta_u32_inputs(i: usize) -> (u32, u32) {
        if i % 2_usize == 0_usize {
            (1000000000_u32, 2000000000_u32)
        } else {
            (12345678_u32, 54321987_u32)
        }
    }

    fn affine_u32_inputs(i: usize) -> (u32, u32, u32, u32, u32) {
        if i % 2_usize == 0_usize {
            (1000_u32, 2000_u32, 700_u32, 200_u32, 9000_u32)
        } else {
            (12345_u32, 54321_u32, 5000_u32, 1234_u32, 42000_u32)
        }
    }

    fn add_u64_inputs(i: usize) -> (u64, u64) {
        if i % 2_usize == 0_usize {
            (4000000000_u64, 5000000000_u64)
        } else {
            (12345678_u64, 54321987_u64)
        }
    }

    fn sub_u64_inputs(i: usize) -> (u64, u64) {
        if i % 2_usize == 0_usize {
            (9000000000_u64, 123456789_u64)
        } else {
            (12345678901_u64, 2345678901_u64)
        }
    }

    fn mul_u64_inputs(i: usize) -> (u64, u64) {
        if i % 2_usize == 0_usize {
            (100000_u64, 200000_u64)
        } else {
            (12345678_u64, 54321_u64)
        }
    }

    fn delta_u64_inputs(i: usize) -> (u64, u64) {
        if i % 2_usize == 0_usize {
            (4000000000_u64, 5000000000_u64)
        } else {
            (12345678_u64, 54321987_u64)
        }
    }

    fn affine_u64_inputs(i: usize) -> (u64, u64, u64, u64, u64) {
        if i % 2_usize == 0_usize {
            (1000000_u64, 2000000_u64, 700000_u64, 200000_u64, 9000_u64)
        } else {
            (12345678_u64, 54321987_u64, 5000000_u64, 1234000_u64, 42000_u64)
        }
    }

    fn run_baseline_add(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = add_inputs(i);
            acc = acc + sq128x128_add_raw_baseline_fn(a, b);
            i = i + 1_usize;
        }
    }

    fn run_generated_add(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = add_inputs(i);
            acc = acc + sq128x128_add_raw_generated(a, b);
            i = i + 1_usize;
        }
    }

    fn run_baseline_sub(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = sub_inputs(i);
            acc = acc + sq128x128_sub_raw_baseline_fn(a, b);
            i = i + 1_usize;
        }
    }

    fn run_generated_sub(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = sub_inputs(i);
            acc = acc + sq128x128_sub_raw_generated(a, b);
            i = i + 1_usize;
        }
    }

    fn run_baseline_mul(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = mul_inputs(i);
            acc = acc + sq128x128_mul_raw_baseline_fn(a, b);
            i = i + 1_usize;
        }
    }

    fn run_generated_mul(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = mul_inputs(i);
            acc = acc + sq128x128_mul_raw_generated(a, b);
            i = i + 1_usize;
        }
    }

    fn run_baseline_delta(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = delta_inputs(i);
            acc = acc + sq128x128_delta_raw_baseline_fn(a, b);
            i = i + 1_usize;
        }
    }

    fn run_generated_delta(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = delta_inputs(i);
            acc = acc + sq128x128_delta_raw_generated(a, b);
            i = i + 1_usize;
        }
    }

    fn run_baseline_affine(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b, c, d, e) = affine_inputs(i);
            acc = acc + sq128x128_affine_kernel_baseline_fn(a, b, c, d, e);
            i = i + 1_usize;
        }
    }

    fn run_generated_affine(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b, c, d, e) = affine_inputs(i);
            acc = acc + sq128x128_affine_kernel_generated(a, b, c, d, e);
            i = i + 1_usize;
        }
    }

    fn run_baseline_add_u8(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = add_u8_inputs(i);
            acc = acc + sq128x128_add_raw_u8_baseline_fn(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_add_u8(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = add_u8_inputs(i);
            acc = acc + sq128x128_add_raw_u8_generated(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_sub_u8(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = sub_u8_inputs(i);
            acc = acc + sq128x128_sub_raw_u8_baseline_fn(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_sub_u8(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = sub_u8_inputs(i);
            acc = acc + sq128x128_sub_raw_u8_generated(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_mul_u8(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = mul_u8_inputs(i);
            acc = acc + sq128x128_mul_raw_u8_baseline_fn(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_mul_u8(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = mul_u8_inputs(i);
            acc = acc + sq128x128_mul_raw_u8_generated(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_delta_u8(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = delta_u8_inputs(i);
            acc = acc + sq128x128_delta_raw_u8_baseline_fn(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_delta_u8(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = delta_u8_inputs(i);
            acc = acc + sq128x128_delta_raw_u8_generated(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_affine_u8(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b, c, d, e) = affine_u8_inputs(i);
            acc = acc + sq128x128_affine_kernel_u8_baseline_fn(a, b, c, d, e).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_affine_u8(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b, c, d, e) = affine_u8_inputs(i);
            acc = acc + sq128x128_affine_kernel_u8_generated(a, b, c, d, e).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_add_i16(rounds: usize) -> i32 {
        let mut i = 0_usize;
        let mut acc = 0_i32;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = add_i16_inputs(i);
            acc = acc + sq128x128_add_raw_i16_baseline_fn(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_add_i16(rounds: usize) -> i32 {
        let mut i = 0_usize;
        let mut acc = 0_i32;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = add_i16_inputs(i);
            acc = acc + sq128x128_add_raw_i16_generated(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_sub_i16(rounds: usize) -> i32 {
        let mut i = 0_usize;
        let mut acc = 0_i32;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = sub_i16_inputs(i);
            acc = acc + sq128x128_sub_raw_i16_baseline_fn(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_sub_i16(rounds: usize) -> i32 {
        let mut i = 0_usize;
        let mut acc = 0_i32;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = sub_i16_inputs(i);
            acc = acc + sq128x128_sub_raw_i16_generated(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_mul_i16(rounds: usize) -> i32 {
        let mut i = 0_usize;
        let mut acc = 0_i32;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = mul_i16_inputs(i);
            acc = acc + sq128x128_mul_raw_i16_baseline_fn(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_mul_i16(rounds: usize) -> i32 {
        let mut i = 0_usize;
        let mut acc = 0_i32;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = mul_i16_inputs(i);
            acc = acc + sq128x128_mul_raw_i16_generated(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_delta_i16(rounds: usize) -> i32 {
        let mut i = 0_usize;
        let mut acc = 0_i32;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = delta_i16_inputs(i);
            acc = acc + sq128x128_delta_raw_i16_baseline_fn(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_delta_i16(rounds: usize) -> i32 {
        let mut i = 0_usize;
        let mut acc = 0_i32;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = delta_i16_inputs(i);
            acc = acc + sq128x128_delta_raw_i16_generated(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_affine_i16(rounds: usize) -> i32 {
        let mut i = 0_usize;
        let mut acc = 0_i32;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b, c, d, e) = affine_i16_inputs(i);
            acc = acc + sq128x128_affine_kernel_i16_baseline_fn(a, b, c, d, e).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_affine_i16(rounds: usize) -> i32 {
        let mut i = 0_usize;
        let mut acc = 0_i32;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b, c, d, e) = affine_i16_inputs(i);
            acc = acc + sq128x128_affine_kernel_i16_generated(a, b, c, d, e).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_add_u16(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = add_u16_inputs(i);
            acc = acc + sq128x128_add_raw_u16_baseline_fn(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_add_u16(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = add_u16_inputs(i);
            acc = acc + sq128x128_add_raw_u16_generated(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_sub_u16(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = sub_u16_inputs(i);
            acc = acc + sq128x128_sub_raw_u16_baseline_fn(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_sub_u16(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = sub_u16_inputs(i);
            acc = acc + sq128x128_sub_raw_u16_generated(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_mul_u16(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = mul_u16_inputs(i);
            acc = acc + sq128x128_mul_raw_u16_baseline_fn(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_mul_u16(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = mul_u16_inputs(i);
            acc = acc + sq128x128_mul_raw_u16_generated(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_delta_u16(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = delta_u16_inputs(i);
            acc = acc + sq128x128_delta_raw_u16_baseline_fn(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_delta_u16(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = delta_u16_inputs(i);
            acc = acc + sq128x128_delta_raw_u16_generated(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_affine_u16(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b, c, d, e) = affine_u16_inputs(i);
            acc = acc + sq128x128_affine_kernel_u16_baseline_fn(a, b, c, d, e).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_affine_u16(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b, c, d, e) = affine_u16_inputs(i);
            acc = acc + sq128x128_affine_kernel_u16_generated(a, b, c, d, e).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_add_u32(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = add_u32_inputs(i);
            acc = acc + sq128x128_add_raw_u32_baseline_fn(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_add_u32(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = add_u32_inputs(i);
            acc = acc + sq128x128_add_raw_u32_generated(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_sub_u32(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = sub_u32_inputs(i);
            acc = acc + sq128x128_sub_raw_u32_baseline_fn(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_sub_u32(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = sub_u32_inputs(i);
            acc = acc + sq128x128_sub_raw_u32_generated(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_mul_u32(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = mul_u32_inputs(i);
            acc = acc + sq128x128_mul_raw_u32_baseline_fn(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_mul_u32(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = mul_u32_inputs(i);
            acc = acc + sq128x128_mul_raw_u32_generated(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_delta_u32(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = delta_u32_inputs(i);
            acc = acc + sq128x128_delta_raw_u32_baseline_fn(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_delta_u32(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = delta_u32_inputs(i);
            acc = acc + sq128x128_delta_raw_u32_generated(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_affine_u32(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b, c, d, e) = affine_u32_inputs(i);
            acc = acc + sq128x128_affine_kernel_u32_baseline_fn(a, b, c, d, e).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_affine_u32(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b, c, d, e) = affine_u32_inputs(i);
            acc = acc + sq128x128_affine_kernel_u32_generated(a, b, c, d, e).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_add_u64(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = add_u64_inputs(i);
            acc = acc + sq128x128_add_raw_u64_baseline_fn(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_add_u64(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = add_u64_inputs(i);
            acc = acc + sq128x128_add_raw_u64_generated(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_sub_u64(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = sub_u64_inputs(i);
            acc = acc + sq128x128_sub_raw_u64_baseline_fn(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_sub_u64(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = sub_u64_inputs(i);
            acc = acc + sq128x128_sub_raw_u64_generated(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_mul_u64(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = mul_u64_inputs(i);
            acc = acc + sq128x128_mul_raw_u64_baseline_fn(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_mul_u64(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = mul_u64_inputs(i);
            acc = acc + sq128x128_mul_raw_u64_generated(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_delta_u64(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = delta_u64_inputs(i);
            acc = acc + sq128x128_delta_raw_u64_baseline_fn(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_delta_u64(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b) = delta_u64_inputs(i);
            acc = acc + sq128x128_delta_raw_u64_generated(a, b).into();
            i = i + 1_usize;
        }
    }

    fn run_baseline_affine_u64(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b, c, d, e) = affine_u64_inputs(i);
            acc = acc + sq128x128_affine_kernel_u64_baseline_fn(a, b, c, d, e).into();
            i = i + 1_usize;
        }
    }

    fn run_generated_affine_u64(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b, c, d, e) = affine_u64_inputs(i);
            acc = acc + sq128x128_affine_kernel_u64_generated(a, b, c, d, e).into();
            i = i + 1_usize;
        }
    }

    #[test]
    fn test_equivalence_vectors() {
        assert(sq128x128_add_raw_baseline_fn(1000_u128, 2000_u128) == sq128x128_add_raw_generated(1000_u128, 2000_u128), 'eq_add_a');
        assert(sq128x128_add_raw_baseline_fn(12345_u128, 54321_u128) == sq128x128_add_raw_generated(12345_u128, 54321_u128), 'eq_add_b');

        assert(sq128x128_sub_raw_baseline_fn(50000_u128, 123_u128) == sq128x128_sub_raw_generated(50000_u128, 123_u128), 'eq_sub_a');
        assert(sq128x128_sub_raw_baseline_fn(987654321_u128, 123456789_u128) == sq128x128_sub_raw_generated(987654321_u128, 123456789_u128), 'eq_sub_b');

        assert(sq128x128_mul_raw_baseline_fn(1000_u128, 2000_u128) == sq128x128_mul_raw_generated(1000_u128, 2000_u128), 'eq_mul_a');
        assert(sq128x128_mul_raw_baseline_fn(12345_u128, 54321_u128) == sq128x128_mul_raw_generated(12345_u128, 54321_u128), 'eq_mul_b');

        assert(sq128x128_delta_raw_baseline_fn(1000_u128, 2000_u128) == sq128x128_delta_raw_generated(1000_u128, 2000_u128), 'eq_delta_a');
        assert(sq128x128_delta_raw_baseline_fn(12345_u128, 54321_u128) == sq128x128_delta_raw_generated(12345_u128, 54321_u128), 'eq_delta_b');

        assert(
            sq128x128_affine_kernel_baseline_fn(1000_u128, 2000_u128, 700_u128, 200_u128, 9_u128)
                == sq128x128_affine_kernel_generated(1000_u128, 2000_u128, 700_u128, 200_u128, 9_u128),
            'eq_affine_a',
        );
        assert(
            sq128x128_affine_kernel_baseline_fn(12345_u128, 54321_u128, 5000_u128, 1234_u128, 42_u128)
                == sq128x128_affine_kernel_generated(12345_u128, 54321_u128, 5000_u128, 1234_u128, 42_u128),
            'eq_affine_b',
        );

        assert(
            sq128x128_add_raw_u8_baseline_fn(10_u8, 20_u8)
                == sq128x128_add_raw_u8_generated(10_u8, 20_u8),
            'eq_add_u8_a',
        );
        assert(
            sq128x128_add_raw_u8_baseline_fn(50_u8, 70_u8)
                == sq128x128_add_raw_u8_generated(50_u8, 70_u8),
            'eq_add_u8_b',
        );

        assert(
            sq128x128_sub_raw_u8_baseline_fn(200_u8, 123_u8)
                == sq128x128_sub_raw_u8_generated(200_u8, 123_u8),
            'eq_sub_u8_a',
        );
        assert(
            sq128x128_sub_raw_u8_baseline_fn(220_u8, 34_u8)
                == sq128x128_sub_raw_u8_generated(220_u8, 34_u8),
            'eq_sub_u8_b',
        );

        assert(
            sq128x128_mul_raw_u8_baseline_fn(10_u8, 20_u8)
                == sq128x128_mul_raw_u8_generated(10_u8, 20_u8),
            'eq_mul_u8_a',
        );
        assert(
            sq128x128_mul_raw_u8_baseline_fn(12_u8, 21_u8)
                == sq128x128_mul_raw_u8_generated(12_u8, 21_u8),
            'eq_mul_u8_b',
        );

        assert(
            sq128x128_delta_raw_u8_baseline_fn(100_u8, 200_u8)
                == sq128x128_delta_raw_u8_generated(100_u8, 200_u8),
            'eq_delta_u8_a',
        );
        assert(
            sq128x128_delta_raw_u8_baseline_fn(123_u8, 221_u8)
                == sq128x128_delta_raw_u8_generated(123_u8, 221_u8),
            'eq_delta_u8_b',
        );

        assert(
            sq128x128_affine_kernel_u8_baseline_fn(
                5_u8, 10_u8, 20_u8, 5_u8, 3_u8,
            ) == sq128x128_affine_kernel_u8_generated(
                5_u8, 10_u8, 20_u8, 5_u8, 3_u8,
            ),
            'eq_affine_u8_a',
        );
        assert(
            sq128x128_affine_kernel_u8_baseline_fn(
                12_u8, 8_u8, 25_u8, 20_u8, 3_u8,
            ) == sq128x128_affine_kernel_u8_generated(
                12_u8, 8_u8, 25_u8, 20_u8, 3_u8,
            ),
            'eq_affine_u8_b',
        );

        assert(
            sq128x128_add_raw_i16_baseline_fn(1000_i16, 2000_i16)
                == sq128x128_add_raw_i16_generated(1000_i16, 2000_i16),
            'eq_add_i16_a',
        );
        assert(
            sq128x128_add_raw_i16_baseline_fn(1234_i16, 4321_i16)
                == sq128x128_add_raw_i16_generated(1234_i16, 4321_i16),
            'eq_add_i16_b',
        );

        assert(
            sq128x128_sub_raw_i16_baseline_fn(5000_i16, 123_i16)
                == sq128x128_sub_raw_i16_generated(5000_i16, 123_i16),
            'eq_sub_i16_a',
        );
        assert(
            sq128x128_sub_raw_i16_baseline_fn(9876_i16, 4321_i16)
                == sq128x128_sub_raw_i16_generated(9876_i16, 4321_i16),
            'eq_sub_i16_b',
        );

        assert(
            sq128x128_mul_raw_i16_baseline_fn(100_i16, 200_i16)
                == sq128x128_mul_raw_i16_generated(100_i16, 200_i16),
            'eq_mul_i16_a',
        );
        assert(
            sq128x128_mul_raw_i16_baseline_fn(123_i16, 231_i16)
                == sq128x128_mul_raw_i16_generated(123_i16, 231_i16),
            'eq_mul_i16_b',
        );

        assert(
            sq128x128_delta_raw_i16_baseline_fn(1000_i16, 2000_i16)
                == sq128x128_delta_raw_i16_generated(1000_i16, 2000_i16),
            'eq_delta_i16_a',
        );
        assert(
            sq128x128_delta_raw_i16_baseline_fn(1234_i16, 4321_i16)
                == sq128x128_delta_raw_i16_generated(1234_i16, 4321_i16),
            'eq_delta_i16_b',
        );

        assert(
            sq128x128_affine_kernel_i16_baseline_fn(
                10_i16, 20_i16, 70_i16, 20_i16, 9_i16,
            ) == sq128x128_affine_kernel_i16_generated(
                10_i16, 20_i16, 70_i16, 20_i16, 9_i16,
            ),
            'eq_affine_i16_a',
        );
        assert(
            sq128x128_affine_kernel_i16_baseline_fn(
                123_i16, 221_i16, 300_i16, 234_i16, 42_i16,
            ) == sq128x128_affine_kernel_i16_generated(
                123_i16, 221_i16, 300_i16, 234_i16, 42_i16,
            ),
            'eq_affine_i16_b',
        );

        assert(
            sq128x128_add_raw_u16_baseline_fn(10000_u16, 20000_u16)
                == sq128x128_add_raw_u16_generated(10000_u16, 20000_u16),
            'eq_add_u16_a',
        );
        assert(
            sq128x128_add_raw_u16_baseline_fn(12345_u16, 22222_u16)
                == sq128x128_add_raw_u16_generated(12345_u16, 22222_u16),
            'eq_add_u16_b',
        );

        assert(
            sq128x128_sub_raw_u16_baseline_fn(60000_u16, 12345_u16)
                == sq128x128_sub_raw_u16_generated(60000_u16, 12345_u16),
            'eq_sub_u16_a',
        );
        assert(
            sq128x128_sub_raw_u16_baseline_fn(40000_u16, 23456_u16)
                == sq128x128_sub_raw_u16_generated(40000_u16, 23456_u16),
            'eq_sub_u16_b',
        );

        assert(
            sq128x128_mul_raw_u16_baseline_fn(100_u16, 200_u16)
                == sq128x128_mul_raw_u16_generated(100_u16, 200_u16),
            'eq_mul_u16_a',
        );
        assert(
            sq128x128_mul_raw_u16_baseline_fn(123_u16, 321_u16)
                == sq128x128_mul_raw_u16_generated(123_u16, 321_u16),
            'eq_mul_u16_b',
        );

        assert(
            sq128x128_delta_raw_u16_baseline_fn(10000_u16, 20000_u16)
                == sq128x128_delta_raw_u16_generated(10000_u16, 20000_u16),
            'eq_delta_u16_a',
        );
        assert(
            sq128x128_delta_raw_u16_baseline_fn(12345_u16, 22222_u16)
                == sq128x128_delta_raw_u16_generated(12345_u16, 22222_u16),
            'eq_delta_u16_b',
        );

        assert(
            sq128x128_affine_kernel_u16_baseline_fn(
                10_u16, 20_u16, 70_u16, 20_u16, 9_u16,
            ) == sq128x128_affine_kernel_u16_generated(
                10_u16, 20_u16, 70_u16, 20_u16, 9_u16,
            ),
            'eq_affine_u16_a',
        );
        assert(
            sq128x128_affine_kernel_u16_baseline_fn(
                123_u16, 221_u16, 300_u16, 234_u16, 42_u16,
            ) == sq128x128_affine_kernel_u16_generated(
                123_u16, 221_u16, 300_u16, 234_u16, 42_u16,
            ),
            'eq_affine_u16_b',
        );

        assert(
            sq128x128_add_raw_u32_baseline_fn(1000000000_u32, 2000000000_u32)
                == sq128x128_add_raw_u32_generated(1000000000_u32, 2000000000_u32),
            'eq_add_u32_a',
        );
        assert(
            sq128x128_add_raw_u32_baseline_fn(12345678_u32, 54321987_u32)
                == sq128x128_add_raw_u32_generated(12345678_u32, 54321987_u32),
            'eq_add_u32_b',
        );

        assert(
            sq128x128_sub_raw_u32_baseline_fn(3000000000_u32, 123456789_u32)
                == sq128x128_sub_raw_u32_generated(3000000000_u32, 123456789_u32),
            'eq_sub_u32_a',
        );
        assert(
            sq128x128_sub_raw_u32_baseline_fn(1234567890_u32, 234567890_u32)
                == sq128x128_sub_raw_u32_generated(1234567890_u32, 234567890_u32),
            'eq_sub_u32_b',
        );

        assert(
            sq128x128_mul_raw_u32_baseline_fn(1000_u32, 2000_u32)
                == sq128x128_mul_raw_u32_generated(1000_u32, 2000_u32),
            'eq_mul_u32_a',
        );
        assert(
            sq128x128_mul_raw_u32_baseline_fn(12345_u32, 54321_u32)
                == sq128x128_mul_raw_u32_generated(12345_u32, 54321_u32),
            'eq_mul_u32_b',
        );

        assert(
            sq128x128_delta_raw_u32_baseline_fn(1000000000_u32, 2000000000_u32)
                == sq128x128_delta_raw_u32_generated(1000000000_u32, 2000000000_u32),
            'eq_delta_u32_a',
        );
        assert(
            sq128x128_delta_raw_u32_baseline_fn(12345678_u32, 54321987_u32)
                == sq128x128_delta_raw_u32_generated(12345678_u32, 54321987_u32),
            'eq_delta_u32_b',
        );

        assert(
            sq128x128_affine_kernel_u32_baseline_fn(
                1000_u32, 2000_u32, 700_u32, 200_u32, 9000_u32,
            ) == sq128x128_affine_kernel_u32_generated(
                1000_u32, 2000_u32, 700_u32, 200_u32, 9000_u32,
            ),
            'eq_affine_u32_a',
        );
        assert(
            sq128x128_affine_kernel_u32_baseline_fn(
                12345_u32, 54321_u32, 5000_u32, 1234_u32, 42000_u32,
            ) == sq128x128_affine_kernel_u32_generated(
                12345_u32, 54321_u32, 5000_u32, 1234_u32, 42000_u32,
            ),
            'eq_affine_u32_b',
        );

        assert(
            sq128x128_add_raw_u64_baseline_fn(4000000000_u64, 5000000000_u64)
                == sq128x128_add_raw_u64_generated(4000000000_u64, 5000000000_u64),
            'eq_add_u64_a',
        );
        assert(
            sq128x128_add_raw_u64_baseline_fn(12345678_u64, 54321987_u64)
                == sq128x128_add_raw_u64_generated(12345678_u64, 54321987_u64),
            'eq_add_u64_b',
        );

        assert(
            sq128x128_sub_raw_u64_baseline_fn(9000000000_u64, 123456789_u64)
                == sq128x128_sub_raw_u64_generated(9000000000_u64, 123456789_u64),
            'eq_sub_u64_a',
        );
        assert(
            sq128x128_sub_raw_u64_baseline_fn(12345678901_u64, 2345678901_u64)
                == sq128x128_sub_raw_u64_generated(12345678901_u64, 2345678901_u64),
            'eq_sub_u64_b',
        );

        assert(
            sq128x128_mul_raw_u64_baseline_fn(100000_u64, 200000_u64)
                == sq128x128_mul_raw_u64_generated(100000_u64, 200000_u64),
            'eq_mul_u64_a',
        );
        assert(
            sq128x128_mul_raw_u64_baseline_fn(12345678_u64, 54321_u64)
                == sq128x128_mul_raw_u64_generated(12345678_u64, 54321_u64),
            'eq_mul_u64_b',
        );

        assert(
            sq128x128_delta_raw_u64_baseline_fn(4000000000_u64, 5000000000_u64)
                == sq128x128_delta_raw_u64_generated(4000000000_u64, 5000000000_u64),
            'eq_delta_u64_a',
        );
        assert(
            sq128x128_delta_raw_u64_baseline_fn(12345678_u64, 54321987_u64)
                == sq128x128_delta_raw_u64_generated(12345678_u64, 54321987_u64),
            'eq_delta_u64_b',
        );

        assert(
            sq128x128_affine_kernel_u64_baseline_fn(
                1000000_u64, 2000000_u64, 700000_u64, 200000_u64, 9000_u64,
            ) == sq128x128_affine_kernel_u64_generated(
                1000000_u64, 2000000_u64, 700000_u64, 200000_u64, 9000_u64,
            ),
            'eq_affine_u64_a',
        );
        assert(
            sq128x128_affine_kernel_u64_baseline_fn(
                12345678_u64, 54321987_u64, 5000000_u64, 1234000_u64, 42000_u64,
            ) == sq128x128_affine_kernel_u64_generated(
                12345678_u64, 54321987_u64, 5000000_u64, 1234000_u64, 42000_u64,
            ),
            'eq_affine_u64_b',
        );
    }

    #[test]
    fn test_gas_baseline_add_case() {
        assert(run_baseline_add(ROUNDS) == EXPECTED_ADD_ACC, 'baseline_add_wrong');
    }

    #[test]
    fn test_gas_generated_add_case() {
        assert(run_generated_add(ROUNDS) == EXPECTED_ADD_ACC, 'generated_add_wrong');
    }

    #[test]
    fn test_gas_baseline_sub_case() {
        assert(run_baseline_sub(ROUNDS) == EXPECTED_SUB_ACC, 'baseline_sub_wrong');
    }

    #[test]
    fn test_gas_generated_sub_case() {
        assert(run_generated_sub(ROUNDS) == EXPECTED_SUB_ACC, 'generated_sub_wrong');
    }

    #[test]
    fn test_gas_baseline_mul_case() {
        assert(run_baseline_mul(ROUNDS) == EXPECTED_MUL_ACC, 'baseline_mul_wrong');
    }

    #[test]
    fn test_gas_generated_mul_case() {
        assert(run_generated_mul(ROUNDS) == EXPECTED_MUL_ACC, 'generated_mul_wrong');
    }

    #[test]
    fn test_gas_baseline_delta_case() {
        assert(run_baseline_delta(ROUNDS) == EXPECTED_DELTA_ACC, 'baseline_delta_wrong');
    }

    #[test]
    fn test_gas_generated_delta_case() {
        assert(run_generated_delta(ROUNDS) == EXPECTED_DELTA_ACC, 'generated_delta_wrong');
    }

    #[test]
    fn test_gas_baseline_affine_case() {
        assert(run_baseline_affine(ROUNDS) == EXPECTED_AFFINE_ACC, 'baseline_affine_wrong');
    }

    #[test]
    fn test_gas_generated_affine_case() {
        assert(run_generated_affine(ROUNDS) == EXPECTED_AFFINE_ACC, 'generated_affine_wrong');
    }

    #[test]
    fn test_gas_baseline_add_u8_case() {
        assert(run_baseline_add_u8(ROUNDS) == EXPECTED_ADD_U8_ACC, 'baseline_add_u8_wrong');
    }

    #[test]
    fn test_gas_generated_add_u8_case() {
        assert(run_generated_add_u8(ROUNDS) == EXPECTED_ADD_U8_ACC, 'generated_add_u8_wrong');
    }

    #[test]
    fn test_gas_baseline_sub_u8_case() {
        assert(run_baseline_sub_u8(ROUNDS) == EXPECTED_SUB_U8_ACC, 'baseline_sub_u8_wrong');
    }

    #[test]
    fn test_gas_generated_sub_u8_case() {
        assert(run_generated_sub_u8(ROUNDS) == EXPECTED_SUB_U8_ACC, 'generated_sub_u8_wrong');
    }

    #[test]
    fn test_gas_baseline_mul_u8_case() {
        assert(run_baseline_mul_u8(ROUNDS) == EXPECTED_MUL_U8_ACC, 'baseline_mul_u8_wrong');
    }

    #[test]
    fn test_gas_generated_mul_u8_case() {
        assert(run_generated_mul_u8(ROUNDS) == EXPECTED_MUL_U8_ACC, 'generated_mul_u8_wrong');
    }

    #[test]
    fn test_gas_baseline_delta_u8_case() {
        assert(run_baseline_delta_u8(ROUNDS) == EXPECTED_DELTA_U8_ACC, 'baseline_delta_u8_wrong');
    }

    #[test]
    fn test_gas_generated_delta_u8_case() {
        assert(run_generated_delta_u8(ROUNDS) == EXPECTED_DELTA_U8_ACC, 'generated_delta_u8_wrong');
    }

    #[test]
    fn test_gas_baseline_affine_u8_case() {
        assert(run_baseline_affine_u8(ROUNDS) == EXPECTED_AFFINE_U8_ACC, 'baseline_affine_u8_wrong');
    }

    #[test]
    fn test_gas_generated_affine_u8_case() {
        assert(run_generated_affine_u8(ROUNDS) == EXPECTED_AFFINE_U8_ACC, 'generated_affine_u8_wrong');
    }

    #[test]
    fn test_gas_baseline_add_i16_case() {
        assert(run_baseline_add_i16(ROUNDS) == EXPECTED_ADD_I16_ACC, 'baseline_add_i16_wrong');
    }

    #[test]
    fn test_gas_generated_add_i16_case() {
        assert(run_generated_add_i16(ROUNDS) == EXPECTED_ADD_I16_ACC, 'generated_add_i16_wrong');
    }

    #[test]
    fn test_gas_baseline_sub_i16_case() {
        assert(run_baseline_sub_i16(ROUNDS) == EXPECTED_SUB_I16_ACC, 'baseline_sub_i16_wrong');
    }

    #[test]
    fn test_gas_generated_sub_i16_case() {
        assert(run_generated_sub_i16(ROUNDS) == EXPECTED_SUB_I16_ACC, 'generated_sub_i16_wrong');
    }

    #[test]
    fn test_gas_baseline_mul_i16_case() {
        assert(run_baseline_mul_i16(ROUNDS) == EXPECTED_MUL_I16_ACC, 'baseline_mul_i16_wrong');
    }

    #[test]
    fn test_gas_generated_mul_i16_case() {
        assert(run_generated_mul_i16(ROUNDS) == EXPECTED_MUL_I16_ACC, 'generated_mul_i16_wrong');
    }

    #[test]
    fn test_gas_baseline_delta_i16_case() {
        assert(run_baseline_delta_i16(ROUNDS) == EXPECTED_DELTA_I16_ACC, 'baseline_delta_i16_wrong');
    }

    #[test]
    fn test_gas_generated_delta_i16_case() {
        assert(run_generated_delta_i16(ROUNDS) == EXPECTED_DELTA_I16_ACC, 'generated_delta_i16_wrong');
    }

    #[test]
    fn test_gas_baseline_affine_i16_case() {
        assert(run_baseline_affine_i16(ROUNDS) == EXPECTED_AFFINE_I16_ACC, 'baseline_affine_i16_wrong');
    }

    #[test]
    fn test_gas_generated_affine_i16_case() {
        assert(run_generated_affine_i16(ROUNDS) == EXPECTED_AFFINE_I16_ACC, 'generated_affine_i16_wrong');
    }

    #[test]
    fn test_gas_baseline_add_u16_case() {
        assert(run_baseline_add_u16(ROUNDS) == EXPECTED_ADD_U16_ACC, 'baseline_add_u16_wrong');
    }

    #[test]
    fn test_gas_generated_add_u16_case() {
        assert(run_generated_add_u16(ROUNDS) == EXPECTED_ADD_U16_ACC, 'generated_add_u16_wrong');
    }

    #[test]
    fn test_gas_baseline_sub_u16_case() {
        assert(run_baseline_sub_u16(ROUNDS) == EXPECTED_SUB_U16_ACC, 'baseline_sub_u16_wrong');
    }

    #[test]
    fn test_gas_generated_sub_u16_case() {
        assert(run_generated_sub_u16(ROUNDS) == EXPECTED_SUB_U16_ACC, 'generated_sub_u16_wrong');
    }

    #[test]
    fn test_gas_baseline_mul_u16_case() {
        assert(run_baseline_mul_u16(ROUNDS) == EXPECTED_MUL_U16_ACC, 'baseline_mul_u16_wrong');
    }

    #[test]
    fn test_gas_generated_mul_u16_case() {
        assert(run_generated_mul_u16(ROUNDS) == EXPECTED_MUL_U16_ACC, 'generated_mul_u16_wrong');
    }

    #[test]
    fn test_gas_baseline_delta_u16_case() {
        assert(run_baseline_delta_u16(ROUNDS) == EXPECTED_DELTA_U16_ACC, 'baseline_delta_u16_wrong');
    }

    #[test]
    fn test_gas_generated_delta_u16_case() {
        assert(run_generated_delta_u16(ROUNDS) == EXPECTED_DELTA_U16_ACC, 'generated_delta_u16_wrong');
    }

    #[test]
    fn test_gas_baseline_affine_u16_case() {
        assert(run_baseline_affine_u16(ROUNDS) == EXPECTED_AFFINE_U16_ACC, 'baseline_affine_u16_wrong');
    }

    #[test]
    fn test_gas_generated_affine_u16_case() {
        assert(run_generated_affine_u16(ROUNDS) == EXPECTED_AFFINE_U16_ACC, 'generated_affine_u16_wrong');
    }

    #[test]
    fn test_gas_baseline_add_u32_case() {
        assert(run_baseline_add_u32(ROUNDS) == EXPECTED_ADD_U32_ACC, 'baseline_add_u32_wrong');
    }

    #[test]
    fn test_gas_generated_add_u32_case() {
        assert(run_generated_add_u32(ROUNDS) == EXPECTED_ADD_U32_ACC, 'generated_add_u32_wrong');
    }

    #[test]
    fn test_gas_baseline_sub_u32_case() {
        assert(run_baseline_sub_u32(ROUNDS) == EXPECTED_SUB_U32_ACC, 'baseline_sub_u32_wrong');
    }

    #[test]
    fn test_gas_generated_sub_u32_case() {
        assert(run_generated_sub_u32(ROUNDS) == EXPECTED_SUB_U32_ACC, 'generated_sub_u32_wrong');
    }

    #[test]
    fn test_gas_baseline_mul_u32_case() {
        assert(run_baseline_mul_u32(ROUNDS) == EXPECTED_MUL_U32_ACC, 'baseline_mul_u32_wrong');
    }

    #[test]
    fn test_gas_generated_mul_u32_case() {
        assert(run_generated_mul_u32(ROUNDS) == EXPECTED_MUL_U32_ACC, 'generated_mul_u32_wrong');
    }

    #[test]
    fn test_gas_baseline_delta_u32_case() {
        assert(run_baseline_delta_u32(ROUNDS) == EXPECTED_DELTA_U32_ACC, 'baseline_delta_u32_wrong');
    }

    #[test]
    fn test_gas_generated_delta_u32_case() {
        assert(run_generated_delta_u32(ROUNDS) == EXPECTED_DELTA_U32_ACC, 'generated_delta_u32_wrong');
    }

    #[test]
    fn test_gas_baseline_affine_u32_case() {
        assert(run_baseline_affine_u32(ROUNDS) == EXPECTED_AFFINE_U32_ACC, 'baseline_affine_u32_wrong');
    }

    #[test]
    fn test_gas_generated_affine_u32_case() {
        assert(run_generated_affine_u32(ROUNDS) == EXPECTED_AFFINE_U32_ACC, 'generated_affine_u32_wrong');
    }

    #[test]
    fn test_gas_baseline_add_u64_case() {
        assert(run_baseline_add_u64(ROUNDS) == EXPECTED_ADD_U64_ACC, 'baseline_add_u64_wrong');
    }

    #[test]
    fn test_gas_generated_add_u64_case() {
        assert(run_generated_add_u64(ROUNDS) == EXPECTED_ADD_U64_ACC, 'generated_add_u64_wrong');
    }

    #[test]
    fn test_gas_baseline_sub_u64_case() {
        assert(run_baseline_sub_u64(ROUNDS) == EXPECTED_SUB_U64_ACC, 'baseline_sub_u64_wrong');
    }

    #[test]
    fn test_gas_generated_sub_u64_case() {
        assert(run_generated_sub_u64(ROUNDS) == EXPECTED_SUB_U64_ACC, 'generated_sub_u64_wrong');
    }

    #[test]
    fn test_gas_baseline_mul_u64_case() {
        assert(run_baseline_mul_u64(ROUNDS) == EXPECTED_MUL_U64_ACC, 'baseline_mul_u64_wrong');
    }

    #[test]
    fn test_gas_generated_mul_u64_case() {
        assert(run_generated_mul_u64(ROUNDS) == EXPECTED_MUL_U64_ACC, 'generated_mul_u64_wrong');
    }

    #[test]
    fn test_gas_baseline_delta_u64_case() {
        assert(run_baseline_delta_u64(ROUNDS) == EXPECTED_DELTA_U64_ACC, 'baseline_delta_u64_wrong');
    }

    #[test]
    fn test_gas_generated_delta_u64_case() {
        assert(run_generated_delta_u64(ROUNDS) == EXPECTED_DELTA_U64_ACC, 'generated_delta_u64_wrong');
    }

    #[test]
    fn test_gas_baseline_affine_u64_case() {
        assert(run_baseline_affine_u64(ROUNDS) == EXPECTED_AFFINE_U64_ACC, 'baseline_affine_u64_wrong');
    }

    #[test]
    fn test_gas_generated_affine_u64_case() {
        assert(run_generated_affine_u64(ROUNDS) == EXPECTED_AFFINE_U64_ACC, 'generated_affine_u64_wrong');
    }
}
