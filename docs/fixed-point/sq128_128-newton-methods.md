# SQ128.128 Newton Methods

Newton iteration gives deterministic, fixed-step kernels for inverse, sqrt, and inverse-sqrt when loops are explicitly unrolled.

## 1) Reciprocal via Newton

Target: `inv = 1/x` for `x > 0`.

Iteration form:

- `y_{n+1} = y_n * (2 - x*y_n)`

In fixed-point:

```cairo
// PSEUDO-CODE
fn qinv_newton(x_q128: i256) -> i256 {
    assert!(x_q128 > 0, 'INV_DOMAIN');

    // domain-normalized initial guess
    let y0 = qinitial_guess_inv(x_q128);

    // unrolled fixed iterations
    let y1 = qmul_floor(y0, qsub(TWO_Q128, qmul_floor(x_q128, y0)));
    let y2 = qmul_floor(y1, qsub(TWO_Q128, qmul_floor(x_q128, y1)));
    let y3 = qmul_floor(y2, qsub(TWO_Q128, qmul_floor(x_q128, y2)));
    y3
}
```

## 2) Sqrt via Newton

Solve `f(y)=y^2-a`:

- `y_{n+1} = (y_n + a/y_n)/2`

```cairo
// PSEUDO-CODE
fn qsqrt_newton(a_q128: i256) -> i256 {
    assert!(a_q128 >= 0, 'SQRT_DOMAIN');

    let y0 = qinitial_guess_sqrt(a_q128);
    let y1 = qdiv_floor(qadd(y0, qdiv_floor(a_q128, y0)), TWO_Q128);
    let y2 = qdiv_floor(qadd(y1, qdiv_floor(a_q128, y1)), TWO_Q128);
    let y3 = qdiv_floor(qadd(y2, qdiv_floor(a_q128, y2)), TWO_Q128);
    y3
}
```

## 3) Inverse sqrt

Useful for normalization paths:

- `y_{n+1} = y_n * (3 - a*y_n^2) / 2`

Again use fixed-step unrolling; avoid data-dependent loop counts in contracts.

## 4) Lean/IR usage pattern

Given current DSL constraints (no loops), represent Newton with explicit staged lets:

- `y0`, `y1`, `y2`, ... as nested expressions,
- fixed iteration count chosen by target error bound,
- no hidden control flow.

This shape is optimizer-friendly and proof-friendly.

## 5) Correctness checklist

1. Domain checks before first division.
2. Initial guess range documented.
3. Iteration count fixed and justified.
4. Overflow checks around intermediate multiplies.
5. Error after `N` iterations bounded and tested.

