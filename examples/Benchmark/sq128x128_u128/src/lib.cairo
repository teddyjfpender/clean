mod baseline_types;
mod baseline_arithmetic;
mod baseline_function;
mod generated_function;

#[cfg(test)]
mod tests {
    use super::baseline_function::sq128x128_affine_kernel_baseline_fn;
    use super::generated_function::sq128x128_affine_kernel_generated;

    const A_A: u128 = 1000000_u128;
    const B_A: u128 = 2000000_u128;
    const C_A: u128 = 7000_u128;
    const D_A: u128 = 2000_u128;
    const E_A: u128 = 9_u128;

    const A_B: u128 = 123456789_u128;
    const B_B: u128 = 987654321_u128;
    const C_B: u128 = 50000_u128;
    const D_B: u128 = 12345_u128;
    const E_B: u128 = 42_u128;

    const ROUNDS: usize = 4096_usize;
    const EXPECTED_ACC: u128 = 85716764358862848_u128;

    fn vector_input(i: usize) -> (u128, u128, u128, u128, u128) {
        if i % 2_usize == 0_usize {
            (A_A, B_A, C_A, D_A, E_A)
        } else {
            (A_B, B_B, C_B, D_B, E_B)
        }
    }

    fn run_baseline(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b, c, d, e) = vector_input(i);
            acc = acc + sq128x128_affine_kernel_baseline_fn(a, b, c, d, e);
            i = i + 1_usize;
        }
    }

    fn run_generated(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (a, b, c, d, e) = vector_input(i);
            acc = acc + sq128x128_affine_kernel_generated(a, b, c, d, e);
            i = i + 1_usize;
        }
    }

    #[test]
    fn test_equivalence_vectors() {
        assert(
            sq128x128_affine_kernel_baseline_fn(A_A, B_A, C_A, D_A, E_A)
                == sq128x128_affine_kernel_generated(A_A, B_A, C_A, D_A, E_A),
            'eq_a',
        );
        assert(
            sq128x128_affine_kernel_baseline_fn(A_B, B_B, C_B, D_B, E_B)
                == sq128x128_affine_kernel_generated(A_B, B_B, C_B, D_B, E_B),
            'eq_b',
        );
    }

    #[test]
    fn test_gas_baseline_function_case() {
        let acc = run_baseline(ROUNDS);
        assert(acc == EXPECTED_ACC, 'baseline_wrong');
    }

    #[test]
    fn test_gas_generated_function_case() {
        let acc = run_generated(ROUNDS);
        assert(acc == EXPECTED_ACC, 'generated_wrong');
    }
}
