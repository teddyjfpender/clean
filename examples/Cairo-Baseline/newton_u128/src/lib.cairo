//! Newton baseline reference for `newton_u128`.
//!
//! Source baseline: Alexandria `fast_root.cairo`
//! https://github.com/keep-starknet-strange/alexandria/blob/d64124b96f4e12840d64f80f2526841413b72096/packages/math/src/fast_root.cairo

#[starknet::interface]
pub trait INewtonU128BaselineContract<TContractState> {
    fn newton_reciprocal_two_steps_looped(
        self: @TContractState, a: u128, x0: u128
    ) -> u128;
    fn fast_sqrt_fixed_iters(self: @TContractState, x: u128) -> u128;
}

/// Integer power helper used by `fast_nr_optimize`.
pub fn pow_u128(mut base: u128, mut exp: u128) -> u128 {
    let mut result: u128 = 1_u128;

    loop {
        if exp == 0_u128 {
            break result;
        }

        if exp % 2_u128 == 1_u128 {
            result = result * base;
        }

        exp = exp / 2_u128;
        if exp == 0_u128 {
            break result;
        }
        base = base * base;
    }
}

/// Divide with nearest-integer rounding.
pub fn round_div(a: u128, b: u128) -> u128 {
    assert(b != 0_u128, 'round_div_by_zero');

    let remained = a % b;
    if b - remained <= remained {
        return a / b + 1_u128;
    }
    a / b
}

/// Newton-Raphson optimization to solve `a^r = x` with rounding steps.
pub fn fast_nr_optimize(x: u128, r: u128, iter: usize) -> u128 {
    if x == 0_u128 {
        return 0_u128;
    }

    if r == 1_u128 {
        return x;
    }

    let mut x_optim = round_div(x, r);
    let mut n_iter: usize = 0_usize;

    loop {
        if n_iter == iter {
            break ();
        }
        let x_r_m1 = pow_u128(x_optim, r - 1_u128);
        x_optim = round_div(((r - 1_u128) * x_optim + round_div(x, x_r_m1)), r);
        n_iter = n_iter + 1_usize;
    }

    x_optim
}

/// Integer square-root via Newton-Raphson.
pub fn fast_sqrt(x: u128, iter: usize) -> u128 {
    fast_nr_optimize(x, 2_u128, iter)
}

/// Integer cubic-root via Newton-Raphson.
pub fn fast_cbrt(x: u128, iter: usize) -> u128 {
    fast_nr_optimize(x, 3_u128, iter)
}

/// Handwritten baseline for reciprocal Newton step.
pub fn reciprocal_step(a: u128, x: u128) -> u128 {
    let ax = a * x;
    let two_minus_ax = 2_u128 - ax;
    x * two_minus_ax
}

/// Handwritten baseline for two reciprocal Newton steps using a small loop.
pub fn reciprocal_two_steps_looped(a: u128, x0: u128) -> u128 {
    let mut x = x0;
    let mut i: u8 = 0_u8;
    loop {
        if i == 2_u8 {
            break x;
        }
        x = reciprocal_step(a, x);
        i = i + 1_u8;
    }
}

#[starknet::contract]
mod NewtonU128BaselineContract {
    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl NewtonU128BaselineContractImpl of super::INewtonU128BaselineContract<ContractState> {
        fn newton_reciprocal_two_steps_looped(
            self: @ContractState, a: u128, x0: u128
        ) -> u128 {
            super::reciprocal_two_steps_looped(a, x0)
        }

        fn fast_sqrt_fixed_iters(self: @ContractState, x: u128) -> u128 {
            super::fast_sqrt(x, 8_usize)
        }
    }
}
