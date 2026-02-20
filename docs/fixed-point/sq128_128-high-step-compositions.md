# SQ128.128 High-Step Compositions

This note shows how to compose primitive kernels into realistic on-chain math routines while keeping optimization and review tractable.

## 1) Example composite kernel: risk-adjusted quote

Conceptual formula:

- `gross = base + spread`
- `vol = sqrt(var)`
- `decay = exp(-lambda * t)`
- `penalty = gross * vol * decay`
- `out = gross - penalty`

Every term is SQ128.128.

## 2) Hand-written Cairo style (typical)

```cairo
// PSEUDO-CODE, hand-written style
fn risk_quote(base: i256, spread: i256, var: i256, lambda: i256, t: i256) -> i256 {
    let gross = qadd(base, spread);
    let vol = qsqrt_newton(var);
    let decay = qexp(qneg(qmul_floor(lambda, t)));
    let penalty = qmul_floor(qmul_floor(gross, vol), decay);
    qsub(gross, penalty)
}
```

## 3) Lean->IR optimized style (target shape)

The generated shape should make sharing explicit:

```cairo
// PSEUDO-CODE, optimized shape
fn risk_quote(...) -> i256 {
    let gross = qadd(base, spread);

    let lambda_t = qmul_floor(lambda, t);
    let neg_lambda_t = qneg(lambda_t);
    let decay = qexp(neg_lambda_t);

    let vol = qsqrt_newton(var);

    // shared product staging
    let gross_vol = qmul_floor(gross, vol);
    let penalty = qmul_floor(gross_vol, decay);

    qsub(gross, penalty)
}
```

This style gives IR passes concrete anchors for:

- CSE on repeated products,
- let-normalization and dead-binding elimination,
- potential specialization/inlining choices.

## 4) `exp(log(x))` and `log(exp(x))` caveats

Do not assume exact identities under fixed-point approximations.

Expected practical contract:

- `exp(log(x)) ~= x` within epsilon for domain `x > 0`.
- `log(exp(x)) ~= x` within epsilon for bounded `x` range where approximation is calibrated.

Always publish domain + epsilon, not symbolic equalities.

## 5) Testing matrix for composed kernels

For each composed routine:

1. deterministic fixtures (small/medium/large magnitudes)
2. boundary domains (`x -> 0+`, max safe magnitudes)
3. monotonicity checks where expected
4. relative-error thresholds vs reference model
5. gas/size regression gates (CASM/Sierra metrics)

## 6) What to formalize first

A pragmatic formal sequence:

1. prove primitive kernel pass-preservation (`qmul`, `qdiv`, Newton step rewrites)
2. prove composition rewrites preserve evaluator semantics
3. attach numeric error bounds as explicit assumptions/lemmas
4. integrate benchmark gate thresholds into CI acceptance

