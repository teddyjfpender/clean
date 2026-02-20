# SQ128.128 Fixed-Point Examples

This folder contains worked examples for SQ128.128-style fixed-point math in the context of Lean->Cairo contract generation.

## Scope

- Goal: show how medium/high-step numeric kernels can be structured so they are reviewable, optimizable, and eventually verifiable.
- Focus: `mul`, `div`, `exp`, `log`, Newton iterations (`sqrt`, reciprocal), and composition patterns.
- Current repo status: benchmark kernel comparisons (`qmul/qexp/qlog/qnewton`) are generated from Lean IR; broader SQ128.128 notes still include forward-looking design blueprints.

## Why SQ128.128

SQ128.128 (signed Q128.128) is a common shape for deterministic on-chain math:

- large dynamic range,
- deterministic integer arithmetic,
- no floating-point nondeterminism,
- friendly to proof-oriented modeling.

## Files

1. `sq128_128-basics.md`: representation, scaling, encoding/decoding, invariants.
2. `sq128_128-mul-div.md`: multiplication/division kernels and rounding modes.
3. `sq128_128-exp-log.md`: fixed-step exponential/logarithm approximations.
4. `sq128_128-newton-methods.md`: Newton iterations for reciprocal/sqrt/inv-sqrt.
5. `sq128_128-high-step-compositions.md`: composite “real-world” kernels and optimization review points.
6. `code-comparisons.md`: full side-by-side handwritten vs optimized Cairo code and visual diffs.
7. `fibonacci-fast-doubling.md`: medium-complexity high-step example and optimization shape.
8. `benchmark-results.md`: measured hand-vs-optimized step counts with reproducible commands.

## Reading order

Read in numerical dependency order:

1. Basics
2. Mul/Div
3. Newton methods
4. Exp/Log
5. High-step compositions
6. Code comparisons
7. Fibonacci fast doubling
8. Benchmark results

## Notation

- `S = 2^128` is the fixed-point scale.
- Real value `r` is represented by integer `x = floor(r * S)` (or configured rounding).
- “Pseudo-Cairo” snippets use clear placeholder helpers when low-level details are version-specific.
