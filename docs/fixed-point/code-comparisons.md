# Fixed-Point Code Comparisons

This file shows the exact benchmark-kernel comparisons in the same visual style as `EXAMPLE.md`.

## Provenance

- Lean source of kernel definitions: `src/Examples/FixedPointBench.lean`
- Baseline generation: `lake exe leancairo-gen --module MyLeanFixedPointBench --optimize false ...`
- Optimized generation: `lake exe leancairo-gen --module MyLeanFixedPointBench --optimize true ...`
- Extraction into benchmark package: `scripts/bench/build_fixedpoint_bench_from_lean.py`
- Final generated benchmark file: `packages/fixedpoint_bench/src/lib.cairo`

`hand` and `opt` variants below are therefore both derived from Lean IR; the only difference is optimizer configuration.

Scope note:
- These benchmark kernels are fixed-point-like structural `u256` arithmetic shapes within the current Lean subset, not full SQ128.128 intrinsic implementations (`qmul_floor/qdiv_floor`).

## 1) `qmul` kernel

Hand (Lean-generated, `--optimize false`):

```cairo
fn qmul_kernel_hand(a: u256, b: u256, c: u256) -> u256 {
    (((a * b) * c) + ((a * b) * c))
}
```

Optimized (Lean-generated, `--optimize true`):

```cairo
fn qmul_kernel_opt(a: u256, b: u256, c: u256) -> u256 {
    {
        let __leancairo_internal_cse_u256: u256 = ((a * b) * c);
        (__leancairo_internal_cse_u256 + __leancairo_internal_cse_u256)
    }
}
```

Visual diff:

```diff
 fn qmul_kernel_(a: u256, b: u256, c: u256) -> u256 {
-    (((a * b) * c) + ((a * b) * c))
+    {
+        let __leancairo_internal_cse_u256: u256 = ((a * b) * c);
+        (__leancairo_internal_cse_u256 + __leancairo_internal_cse_u256)
+    }
 }
```

## 2) `qexp` kernel

Hand:

```cairo
fn qexp_taylor_hand(x: u256) -> u256 {
    ((((x * x) * (x * x)) * ((x * x) * (x * x))) + (((x * x) * (x * x)) * ((x * x) * (x * x))))
}
```

Optimized:

```cairo
fn qexp_taylor_opt(x: u256) -> u256 {
    {
        let __leancairo_internal_cse_u256: u256 = {
            let __leancairo_internal_cse_u256: u256 = {
                let __leancairo_internal_cse_u256: u256 = {
                    let __leancairo_internal_cse_u256: u256 = x;
                    (__leancairo_internal_cse_u256 * __leancairo_internal_cse_u256)
                };
                (__leancairo_internal_cse_u256 * __leancairo_internal_cse_u256)
            };
            (__leancairo_internal_cse_u256 * __leancairo_internal_cse_u256)
        };
        (__leancairo_internal_cse_u256 + __leancairo_internal_cse_u256)
    }
}
```

## 3) `qlog` kernel

Hand:

```cairo
fn qlog1p_taylor_hand(z: u256) -> u256 {
    ((((z * z) * (z * z)) - (z * z)) + (((z * z) * (z * z)) - (z * z)))
}
```

Optimized:

```cairo
fn qlog1p_taylor_opt(z: u256) -> u256 {
    {
        let __leancairo_internal_cse_u256: u256 = ({
            let __leancairo_internal_cse_u256: u256 = {
                let __leancairo_internal_cse_u256: u256 = z;
                (__leancairo_internal_cse_u256 * __leancairo_internal_cse_u256)
            };
            (__leancairo_internal_cse_u256 * __leancairo_internal_cse_u256)
        } - {
            let __leancairo_internal_cse_u256: u256 = z;
            (__leancairo_internal_cse_u256 * __leancairo_internal_cse_u256)
        });
        (__leancairo_internal_cse_u256 + __leancairo_internal_cse_u256)
    }
}
```

## 4) `qnewton` kernel

Hand:

```cairo
fn qnewton_recip_hand(x: u256) -> u256 {
    (((((x * x) * (x * x)) * x) - (x * x)) + ((((x * x) * (x * x)) * x) - (x * x)))
}
```

Optimized:

```cairo
fn qnewton_recip_opt(x: u256) -> u256 {
    {
        let __leancairo_internal_cse_u256: u256 = (({
            let __leancairo_internal_cse_u256: u256 = {
                let __leancairo_internal_cse_u256: u256 = x;
                (__leancairo_internal_cse_u256 * __leancairo_internal_cse_u256)
            };
            (__leancairo_internal_cse_u256 * __leancairo_internal_cse_u256)
        } * x) - {
            let __leancairo_internal_cse_u256: u256 = x;
            (__leancairo_internal_cse_u256 * __leancairo_internal_cse_u256)
        });
        (__leancairo_internal_cse_u256 + __leancairo_internal_cse_u256)
    }
}
```

## 5) Fibonacci control benchmark

`fib` is not Lean-derived in this package (recursion is outside the current Lean DSL subset). It remains a direct Cairo control benchmark.

Hand:

```cairo
fn fib_naive(n: u32) -> u128 {
    if n <= 1 {
        n.into()
    } else {
        fib_naive(n - 1) + fib_naive(n - 2)
    }
}
```

Optimized:

```cairo
fn fib_pair_fast(n: u32) -> (u128, u128) {
    if n == 0 {
        (0, 1)
    } else {
        let (a, b) = fib_pair_fast(n / 2);
        let c = a * (2 * b - a);
        let d = a * a + b * b;
        if n % 2 == 0 {
            (c, d)
        } else {
            (d, c + d)
        }
    }
}

fn fib_fast(n: u32) -> u128 {
    let (f, _) = fib_pair_fast(n);
    f
}
```
