# Fibonacci: Tail Recursion Baseline vs Fast Doubling

This example is a high-step control-flow benchmark that complements the SQ128.128 arithmetic kernels.

## Why this example is included

- It is not fixed-point arithmetic by itself.
- It is useful for validating optimizer behavior on recursive call structure.
- It demonstrates a measurable algorithmic win from fast doubling against a realistic recursive baseline.

## Input/output contract

- Baseline input: `(a: felt252, b: felt252, n: felt252)`
- Optimized input: `(n: u32)`
- Output: Fibonacci value represented in `felt252`
- Invariant: both implementations return equal value for benchmarked `n`.
- Failure mode: if outputs diverge, benchmark numbers must be discarded.

## Baseline shape (recursive fib with accumulators)

```cairo
pub fn fib(a: felt252, b: felt252, n: felt252) -> felt252 {
    match n {
        0 => a,
        _ => fib(b, a + b, n - 1),
    }
}
```

Characteristics:
- straightforward recursive implementation
- linear recursion depth in `n`
- good baseline for “simple handwritten recursive Cairo”

## Optimized shape (fast doubling)

```cairo
fn fib_pair_fast(n: u32) -> (felt252, felt252) {
    if n == 0 {
        (0, 1)
    } else {
        let (a, b) = fib_pair_fast(n / 2);
        let c = a * (2 * b - a);
        let d = a * a + b * b;
        if n % 2 == 0 { (c, d) } else { (d, c + d) }
    }
}

fn fib_fast(n: u32) -> felt252 {
    let (f, _) = fib_pair_fast(n);
    f
}
```

Characteristics:
- logarithmic recursion depth
- explicit reuse of intermediate products
- deterministic and easier to cost-model for larger `n`

## Measured benchmark (`n = 200`)

| Variant | Steps |
|---|---:|
| `bench_fib_naive` (`fib(0, 1, 200)`) | 1226 |
| `bench_fib_fast` (`fib_fast(200)`) | 299 |

Delta:
- Saved steps: `927`
- Improvement: `75.61%`
- Speedup: `4.10x`

## How this maps to Lean -> IR optimizer goals

- This benchmark now uses a realistic recursive baseline rather than exponential naive recursion.
- It still validates the core principle: algorithm/IR shape dominates performance.
- For the constrained Lean subset, this supports the same strategy:
  - lower to typed IR,
  - apply semantics-preserving IR-to-IR passes,
  - benchmark non-regression continuously.
