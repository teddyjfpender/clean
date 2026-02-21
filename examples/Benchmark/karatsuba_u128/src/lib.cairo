mod baseline_const_pow;

pub fn count_digits_of_base(mut num: u128, base: u128) -> u32 {
    let mut res = 0;
    while (num != 0) {
        num = num / base;
        res += 1;
    }
    res
}

mod baseline_karatsuba;
mod baseline_function;
mod generated_function;

#[cfg(test)]
mod tests {
    use super::baseline_function::karatsuba_baseline;
    use super::generated_function::karatsuba_combine_generated;

    const B: u128 = 1000000000_u128;
    const X0_A: u128 = 123456789_u128;
    const X1_A: u128 = 987654321_u128;
    const Y0_A: u128 = 111111111_u128;
    const Y1_A: u128 = 222222222_u128;

    const X0_B: u128 = 314159265_u128;
    const X1_B: u128 = 271828182_u128;
    const Y0_B: u128 = 161803398_u128;
    const Y1_B: u128 = 141421356_u128;

    const ROUNDS: usize = 32_usize;
    const EXPECTED_ACC: u128 = 4126736769656989083254416361223440784_u128;

    fn combine_parts(high: u128, low: u128) -> u128 {
        high * B + low
    }

    fn vector_input(i: usize) -> (u128, u128, u128, u128) {
        if i % 2_usize == 0_usize {
            (X0_A, X1_A, Y0_A, Y1_A)
        } else {
            (X0_B, X1_B, Y0_B, Y1_B)
        }
    }

    fn run_generated(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (x0, x1, y0, y1) = vector_input(i);
            acc = acc + karatsuba_combine_generated(x0, x1, y0, y1);
            i = i + 1_usize;
        }
    }

    fn run_baseline(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let (x0, x1, y0, y1) = vector_input(i);
            let x = combine_parts(x1, x0);
            let y = combine_parts(y1, y0);
            acc = acc + karatsuba_baseline(x, y);
            i = i + 1_usize;
        }
    }

    #[test]
    fn test_equivalence_vectors() {
        let xa = combine_parts(X1_A, X0_A);
        let ya = combine_parts(Y1_A, Y0_A);
        let xb = combine_parts(X1_B, X0_B);
        let yb = combine_parts(Y1_B, Y0_B);

        assert(
            karatsuba_baseline(xa, ya) == karatsuba_combine_generated(X0_A, X1_A, Y0_A, Y1_A),
            'eq_a',
        );
        assert(
            karatsuba_baseline(xb, yb) == karatsuba_combine_generated(X0_B, X1_B, Y0_B, Y1_B),
            'eq_b',
        );
    }

    #[test]
    fn test_gas_generated_function_case() {
        let acc = run_generated(ROUNDS);
        assert(acc == EXPECTED_ACC, 'generated_wrong');
    }

    #[test]
    fn test_gas_baseline_function_case() {
        let acc = run_baseline(ROUNDS);
        assert(acc == EXPECTED_ACC, 'baseline_wrong');
    }
}
