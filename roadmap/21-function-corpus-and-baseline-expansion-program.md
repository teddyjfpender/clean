# 21. Function Corpus And Baseline Expansion Program

## Objective

Scale a high-complexity function corpus with mirrored Lean/Sierra/Cairo/Baseline/Benchmark artifacts to drive capability expansion, regression detection, and optimization truth.

## Scope

1. manifest-defined corpus items
2. upstream baseline ingestion and governance
3. deterministic vector generation and replay tools
4. capability-to-corpus coverage mapping

## Corpus Contract

Each corpus item must define:

1. `corpus_id`
2. domain/family classification
3. Lean canonical source module
4. generated Sierra and Cairo mirror targets
5. baseline source references and sync scripts
6. equivalence vectors (normal/boundary/failure)
7. benchmark configuration (rounds/metrics/thresholds)
8. linked capability IDs

## Baseline Governance

1. baseline imports must be scripted and pinned
2. any baseline patch requires rationale and reproducible patching script
3. baseline/generator signatures must be aligned for fair comparisons

## Delivery Phases

### Phase COR0: Corpus manifest v2 and validation

1. extend schema for baselines, benchmarks, capability mapping
2. validate completeness and mirror alignment
3. deterministic regeneration checks

### Phase COR1: Baseline sync automation

1. add source-pull scripts for each baseline family
2. add patch manifests and integrity checks
3. enforce source provenance metadata

### Phase COR2: Vector generation and replay tooling

1. declarative vector specs per corpus item
2. generated tests for evaluator/Sierra/Cairo equivalence
3. replay CLI for mismatch diagnosis

### Phase COR3: Complex corpus scale-out by family

1. integer-width and range-check stress kernels
2. fixed-point iterative kernels
3. aggregate/data/control-flow kernels
4. field/crypto/circuit kernels

### Phase COR4: Corpus-capability reporting

1. map each capability to at least one corpus item
2. detect uncovered implemented capabilities
3. publish coverage trend artifacts

## Required Gates

1. examples structure and generation checks
2. baseline sync reproducibility checks
3. corpus differential suites
4. corpus freshness and coverage report checks

## Acceptance Criteria

1. Corpus growth is manifest-driven and reproducible.
2. Complex families are represented with real kernels and baseline comparisons.
3. Capability promotion requires corpus evidence.
4. Coverage gaps are machine-detected and auditable.
