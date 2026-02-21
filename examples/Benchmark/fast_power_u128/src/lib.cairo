mod baseline_function;
mod fast_power;
mod generated_function;

#[cfg(test)]
mod tests {
    use super::baseline_function::pow13_baseline;
    use super::generated_function::pow13_generated;

    const BENCH_ROUNDS: usize = 1024_usize;
    const BENCH_INPUT: u128 = 7_u128;
    const BENCH_SINGLE_EXPECTED: u128 = 96889010407_u128;
    const BENCH_ACC_EXPECTED: u128 = 99214346656768_u128;

    fn run_baseline(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            acc = acc + pow13_baseline(BENCH_INPUT);
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
            acc = acc + pow13_generated(BENCH_INPUT);
            i = i + 1_usize;
        }
    }

    #[test]
    fn test_equivalence_vectors() {
        assert(pow13_baseline(1_u128) == pow13_generated(1_u128), 'eq_1');
        assert(pow13_baseline(2_u128) == pow13_generated(2_u128), 'eq_2');
        assert(pow13_baseline(3_u128) == pow13_generated(3_u128), 'eq_3');
        assert(pow13_baseline(5_u128) == pow13_generated(5_u128), 'eq_5');
        assert(pow13_baseline(7_u128) == BENCH_SINGLE_EXPECTED, 'single_expected');
        assert(pow13_generated(7_u128) == BENCH_SINGLE_EXPECTED, 'single_generated');
    }

    #[test]
    fn test_gas_baseline_function_case() {
        let acc = run_baseline(BENCH_ROUNDS);
        assert(acc == BENCH_ACC_EXPECTED, 'baseline_wrong');
    }

    #[test]
    fn test_gas_generated_function_case() {
        let acc = run_generated(BENCH_ROUNDS);
        assert(acc == BENCH_ACC_EXPECTED, 'generated_wrong');
    }
}
