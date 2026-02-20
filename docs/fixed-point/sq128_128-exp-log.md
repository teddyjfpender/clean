# SQ128.128 Exp and Log

This note shows fixed-step, deterministic patterns for `exp` and `log` under SQ128.128 arithmetic.

## 1) `exp(x)` strategy

Standard stable pattern:

1. range-reduce: `x = k * ln(2) + r`
2. constrain `r` to a small interval
3. approximate `exp(r)` with low-order polynomial/rational
4. rescale by `2^k`

### Pseudo-Cairo skeleton

```cairo
// PSEUDO-CODE, fixed-step
fn qexp(x_q128: i256) -> i256 {
    // k = round(x / ln2)
    let k: i256 = qdiv_round_nearest(x_q128, LN2_Q128);

    // r = x - k*ln2
    let r: i256 = qsub(x_q128, qmul_floor(k, LN2_Q128));

    // p(r) ~= exp(r) around 0, e.g. degree-5
    // p(r) = 1 + r + r^2/2 + r^3/6 + r^4/24 + r^5/120
    let r2 = qmul_floor(r, r);
    let r3 = qmul_floor(r2, r);
    let r4 = qmul_floor(r2, r2);
    let r5 = qmul_floor(r4, r);

    let p = qadd(ONE_Q128,
            qadd(r,
            qadd(qdiv_floor(r2, TWO_Q128),
            qadd(qdiv_floor(r3, SIX_Q128),
            qadd(qdiv_floor(r4, TWENTY_FOUR_Q128),
                 qdiv_floor(r5, ONE_TWENTY_Q128))))));

    // result = p * 2^k
    qscale_pow2(p, k)
}
```

## 2) `log(x)` strategy

For `x > 0`:

1. normalize `x = m * 2^k` with `m in [1,2)`
2. compute `log(m)` by a bounded approximation
3. return `k*ln2 + log(m)`

Useful transform:

- `y = (m-1)/(m+1)`
- `log(m) = 2 * (y + y^3/3 + y^5/5 + ...)`

### Pseudo-Cairo skeleton

```cairo
// PSEUDO-CODE, fixed-step odd-series
fn qlog(x_q128: i256) -> i256 {
    assert!(x_q128 > 0, 'LOG_DOMAIN');

    let (m_q128, k): (i256, i256) = qnormalize_to_1_2(x_q128);

    let y   = qdiv_floor(qsub(m_q128, ONE_Q128), qadd(m_q128, ONE_Q128));
    let y2  = qmul_floor(y, y);
    let y3  = qmul_floor(y2, y);
    let y5  = qmul_floor(y3, y2);
    let y7  = qmul_floor(y5, y2);

    let series = qadd(y,
                 qadd(qdiv_floor(y3, THREE_Q128),
                 qadd(qdiv_floor(y5, FIVE_Q128),
                      qdiv_floor(y7, SEVEN_Q128))));

    let log_m = qmul_floor(TWO_Q128, series);
    qadd(qmul_floor(k, LN2_Q128), log_m)
}
```

## 3) High-step cost notes

`exp/log` are high-step because they repeatedly invoke:

- fixed-point multiply/divide,
- constants,
- normalization branches.

This is exactly where IR-to-IR passes matter:

- CSE over repeated powers (`r2`, `r3`, `y2`, `y3`, ...)
- let-normalization on repeated temporary usage
- invariant hoisting for constants and shared subexpressions

## 4) Verification notes

Pass-level proof structure should separate:

1. arithmetic-kernel correctness (`qmul`, `qdiv`, `qscale_pow2`)
2. approximation error bound proof/validation
3. composition proof for the full routine

