mod baseline_function;
mod fast_power;
mod generated_function;

#[cfg(test)]
mod tests {
    use super::baseline_function::pow63_baseline;
    use super::generated_function::pow63_generated;

    const BENCH_ROUNDS: usize = 1024_usize;
    const EVEN_INPUT: u128 = 2_u128;
    const ODD_INPUT: u128 = 3_u128;
    const POW2_EXPECTED: u128 = 9223372036854775808_u128;
    const POW3_EXPECTED: u128 = 1144561273430837494885949696427_u128;
    const BENCH_ACC_EXPECTED: u128 = 586015372001311163864475889784320_u128;

    fn benchmark_input(i: usize) -> u128 {
        if i % 2_usize == 0_usize {
            EVEN_INPUT
        } else {
            ODD_INPUT
        }
    }

    fn run_baseline(rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let x = benchmark_input(i);
            acc = acc + pow63_baseline(x);
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
            let x = benchmark_input(i);
            acc = acc + pow63_generated(x);
            i = i + 1_usize;
        }
    }

    #[test]
    fn test_equivalence_vectors() {
        assert(pow63_baseline(1_u128) == pow63_generated(1_u128), 'eq_1');
        assert(pow63_baseline(2_u128) == pow63_generated(2_u128), 'eq_2');
        assert(pow63_baseline(3_u128) == pow63_generated(3_u128), 'eq_3');
        assert(pow63_baseline(2_u128) == POW2_EXPECTED, 'pow2_expected');
        assert(pow63_generated(2_u128) == POW2_EXPECTED, 'pow2_generated');
        assert(pow63_baseline(3_u128) == POW3_EXPECTED, 'pow3_expected');
        assert(pow63_generated(3_u128) == POW3_EXPECTED, 'pow3_generated');
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
