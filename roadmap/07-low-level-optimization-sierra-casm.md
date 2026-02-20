# 07. Low-Level Optimization: MIR, Sierra, CASM

## Objective

Make Lean-generated functions consistently competitive by optimizing on typed MIR and Sierra/CASM-relevant representations with measured evidence.

## Optimization Stack

1. MIR-level semantic optimizations (proof-friendly).
2. Sierra-level structural optimizations (type/resource aware).
3. CASM-aware selection and scheduling decisions via cost model.

## Required Principle

No optimization is accepted without:

1. semantics preservation argument/proof obligations
2. benchmark evidence on representative corpus

## MIR-Level Pass Roadmap

1. Canonicalization and ANF normalization.
2. constant folding and algebraic simplification.
3. common subexpression elimination and let normalization.
4. dead code/value elimination.
5. inlining and specialization with size/cost heuristics.
6. loop and recursion transforms where semantically justified.
7. effect-aware reorderings under explicit side conditions.

## Sierra-Level Pass Roadmap

1. declaration and statement canonical ordering.
2. libfunc selection optimization (const-specialized vs generic forms).
3. branch simplification and jump threading.
4. resource-flow simplification (dup/drop/store_temp minimization where legal).
5. gas/AP-aware transformations respecting metadata constraints.

## CASM-Oriented Decisions

1. use Sierra metadata (`ap-change`, gas, type-size) as cost features.
2. track bytecode length, hints, estimated step counts, and runtime traces.
3. calibrate cost model against measured runs, not heuristics only.

## Benchmark Program Families

1. scalar arithmetic kernels
2. fixed-point and high-step numerics
3. branch-heavy control kernels
4. data-structure kernels
5. crypto/circuit kernels

## Required Benchmark Gates

1. non-regression gate: optimized score <= baseline score
2. per-family percentile gate to prevent hidden regressions
3. deterministic seed and fixed toolchain pin

## Proof Requirements

1. MIR-level passes: full semantic preservation theorem expected.
2. Sierra-level passes: either theorem or constrained transformation schema with executable checker and differential tests until theorem is added.

## Deliverables

1. cost model document and calibration artifacts
2. benchmark harness scripts with reproducible command set
3. optimization report artifact for each release candidate

