# Fibonacci: Naive Recursion vs Fast Doubling

This example is a high-step control-flow benchmark that complements the SQ128.128 arithmetic kernels.

## Why this example is included

- It is not fixed-point arithmetic by itself.
- It is useful for validating optimizer behavior on deep call trees and repeated subproblems.
- It demonstrates a large asymptotic win from IR-level algorithm selection.

## Input/output contract

- Input: `n : u32`
- Output: `F(n) : u128`
- Invariant: both implementations return the same `F(n)` for the tested domain.
- Failure mode: if outputs diverge, benchmark numbers must be discarded.

## Baseline shape (handwritten naive recursion)

```cairo
fn fib_naive(n: u32) -> u128 {
    if n <= 1 {
        n.into()
    } else {
        fib_naive(n - 1) + fib_naive(n - 2)
    }
}
```

Characteristics:
- straightforward
- exponential call growth
- very high Cairo step count for medium `n`

## Optimized shape (fast doubling)

```cairo
fn fib_pair_fast(n: u32) -> (u128, u128) {
    if n == 0 {
        (0, 1)
    } else {
        let (a, b) = fib_pair_fast(n / 2);
        let c = a * (2 * b - a);
        let d = a * a + b * b;
        if n % 2 == 0 { (c, d) } else { (d, c + d) }
    }
}

fn fib_fast(n: u32) -> u128 {
    let (f, _) = fib_pair_fast(n);
    f
}
```

Characteristics:
- logarithmic recursion depth
- explicit reuse of intermediate products
- deterministic and easier to cost-model

## Measured benchmark (`n = 22`)

| Variant | Steps |
|---|---:|
| `bench_fib_naive` | 1117620 |
| `bench_fib_fast` | 711 |

Delta:
- Saved steps: `1116909`
- Improvement: `99.94%`
- Speedup: `1571.90x`

## How this maps to Lean -> IR optimizer goals

- The large gain comes from representation and algorithm shape, not cosmetic rewrites.
- This is exactly the direction for constrained Lean subset compilation:
  - lower to typed IR,
  - apply semantics-preserving IR-to-IR passes,
  - benchmark non-regression continuously.
