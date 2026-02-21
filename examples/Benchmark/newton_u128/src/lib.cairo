mod baseline_contract;
mod generated_contract;

#[cfg(test)]
mod tests {
    use super::baseline_contract::{
        INewtonU128BaselineContractDispatcher,
        INewtonU128BaselineContractDispatcherTrait,
    };
    use super::generated_contract::{
        INewtonU128ContractDispatcher,
        INewtonU128ContractDispatcherTrait,
    };
    use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};

    const A_SAFE: u128 = 1_u128;
    const X0_SAFE: u128 = 1_u128;
    const BENCH_CALLS: usize = 1024_usize;

    fn deploy_generated() -> INewtonU128ContractDispatcher {
        let class = declare("NewtonU128Contract").unwrap().contract_class();
        let (addr, _deploy_result) = class.deploy(@array![]).unwrap();
        INewtonU128ContractDispatcher { contract_address: addr }
    }

    fn deploy_baseline() -> INewtonU128BaselineContractDispatcher {
        let class = declare("NewtonU128BaselineContract").unwrap().contract_class();
        let (addr, _deploy_result) = class.deploy(@array![]).unwrap();
        INewtonU128BaselineContractDispatcher { contract_address: addr }
    }

    fn run_generated_bench(dispatcher: INewtonU128ContractDispatcher, rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let y = dispatcher.newton_reciprocal_two_steps(A_SAFE, X0_SAFE);
            acc = acc + y;
            i = i + 1_usize;
        }
    }

    fn run_baseline_bench(dispatcher: INewtonU128BaselineContractDispatcher, rounds: usize) -> u128 {
        let mut i = 0_usize;
        let mut acc = 0_u128;
        loop {
            if i == rounds {
                break acc;
            }
            let y = dispatcher.newton_reciprocal_two_steps_looped(A_SAFE, X0_SAFE);
            acc = acc + y;
            i = i + 1_usize;
        }
    }

    #[test]
    fn test_equivalence_generated_vs_baseline_contract() {
        let generated = deploy_generated();
        let baseline = deploy_baseline();

        let g1 = generated.newton_reciprocal_two_steps(1_u128, 1_u128);
        let b1 = baseline.newton_reciprocal_two_steps_looped(1_u128, 1_u128);
        assert(g1 == b1, 'eq_case_1');

        let g2 = generated.newton_reciprocal_two_steps(0_u128, 1_u128);
        let b2 = baseline.newton_reciprocal_two_steps_looped(0_u128, 1_u128);
        assert(g2 == b2, 'eq_case_2');

        let g3 = generated.newton_reciprocal_two_steps(2_u128, 1_u128);
        let b3 = baseline.newton_reciprocal_two_steps_looped(2_u128, 1_u128);
        assert(g3 == b3, 'eq_case_3');
    }

    /// Gas probe for generated Lean->Cairo contract under repeated identical calls.
    #[test]
    fn test_gas_generated_contract_case() {
        let generated = deploy_generated();
        let acc = run_generated_bench(generated, BENCH_CALLS);
        assert(acc == 1024_u128, 'generated_wrong');
    }

    /// Gas probe for handwritten baseline contract under repeated identical calls.
    #[test]
    fn test_gas_baseline_contract_case() {
        let baseline = deploy_baseline();
        let acc = run_baseline_bench(baseline, BENCH_CALLS);
        assert(acc == 1024_u128, 'baseline_wrong');
    }
}
