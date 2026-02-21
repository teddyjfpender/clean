# 14. Complex Function Corpus And Benchmarking Lab

## Objective

Establish a reproducible function corpus and benchmarking lab that scales from simple arithmetic to high-step kernels, feeding both compilation tracks:

1. Lean -> Sierra -> CASM (primary performance truth)
2. Lean -> Cairo (secondary parity/readability track)

## Why This Is Needed

Subset expansion without a growing complex corpus hides regressions. We need a pipeline where each newly supported capability is exercised by real, hard functions and measured continuously.

## Corpus Design

Each corpus item must include:

1. canonical function intent and domain constraints,
2. Lean source kernel,
3. generated Sierra artifacts,
4. generated Cairo artifacts,
5. handwritten baseline Cairo kernel where applicable,
6. deterministic test vectors (normal, boundary, failure),
7. benchmark harness and reproducible run commands.

## Corpus Families

1. Integer-width stress kernels (mixed width/sign and checked/wrapping variants)
2. Fixed-point kernels (SQ128.128 style operations, iterative numerics)
3. Control-flow kernels (branch-heavy, recursion, loop normalization)
4. Aggregate/data kernels (struct/enum/array/span/dict workflows)
5. Field/math/crypto/circuit kernels (`qm31`, hash, EC/circuit-adjacent forms)

## Pipeline Requirements

### 14-A. Corpus manifest and mirroring discipline

1. A manifest drives Lean/Sierra/Cairo/Baseline/Benchmark mirrors.
2. No manual benchmark package that is disconnected from manifest source definitions.
3. CI checks mirror completeness and deterministic regeneration.

### 14-B. Baseline ingestion pipeline

1. Baseline imports from upstream references are scripted and pinned.
2. Any baseline patch is explicit, justified, and reproducible.
3. Baseline and generated paths must be semantically aligned in benchmark harnesses.

### 14-C. Differential test matrix

1. Lean semantic evaluator oracle vs generated execution paths.
2. Sierra path vs Cairo path differential outputs.
3. Boundary/failure vectors for overflow, zero-div, invalid hints, and panic channels.

### 14-D. Benchmark matrix

1. Gas (`sierra`, `l2`) and step profiles by corpus family.
2. Hotspot artifacts (`pb.gz`, `png`) for baseline and generated implementations.
3. Non-regression gates per family, not only global aggregate scores.

## Benchmark Lab Rules

1. Benchmarks are function-only first; contract dispatch remains isolated.
2. Inputs and rounds are fixed by committed manifests.
3. All benchmark claims must link to generated artifacts and logs.
4. Any benchmark mismatch must block capability promotion to `implemented`.

## Delivery Phases

### Phase CFB0: Unified corpus manifest and generator

1. Extend manifest schema for baseline/benchmark definitions.
2. Add generator for mirrored package scaffolding.
3. Add structure and freshness checks.

### Phase CFB1: Differential harness autogeneration

1. Generate equivalence tests from manifest vectors.
2. Enforce same-signature comparison policies.
3. Add mismatch diagnostics with reproducible replay commands.

### Phase CFB2: Benchmark harness autogeneration

1. Generate benchmark packages/scripts from manifest kernels.
2. Produce standardized gas reports and profile artifacts.
3. Add per-family non-regression thresholds.

### Phase CFB3: Complex corpus scale-out

1. Add medium/high complexity kernels per family.
2. Keep Lean/Baseline/Generated parity synchronized.
3. Publish corpus capability coverage mapping.

### Phase CFB4: Release-grade reporting

1. Generate benchmark summary reports per release candidate.
2. Include family deltas, regressions, and hotspot evidence.
3. Integrate into quality-gate workflows.

## Acceptance Criteria

1. Complex corpus growth is manifest-driven and reproducible.
2. Every promoted capability has corresponding corpus and benchmark evidence.
3. Benchmark regression detection is deterministic and CI-enforced.
4. Reports are sufficient to explain where performance wins/losses come from.
