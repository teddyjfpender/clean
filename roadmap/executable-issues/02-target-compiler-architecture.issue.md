# Executable Issue: `roadmap/02-target-compiler-architecture.md`

- Source roadmap file: [`roadmap/02-target-compiler-architecture.md`](../02-target-compiler-architecture.md)
- Issue class: Architecture enforcement
- Priority: P0
- Overall status: NOT DONE

## Objective

Enforce the intended compilation topology:

1. Primary: `Lean -> Typed MIR -> Verified Optimizer -> Sierra -> CASM`
2. Secondary: `Lean -> Typed MIR -> Cairo`

without reintroducing IR -> DSL -> IR loops.

## Implementation loci

1. `src/LeanCairo/Compiler/IR/**`
2. `src/LeanCairo/Compiler/Optimize/**`
3. `src/LeanCairo/Backend/Sierra/**`
4. `src/LeanCairo/Backend/Cairo/**`
5. `src/LeanCairo/Pipeline/**`
6. `scripts/roadmap/check_architecture_boundaries.sh` (new)

## Formal method requirements

1. Backend-agnostic MIR must not import backend modules.
2. Optimizer passes must operate over MIR/Sierra IR, not text.
3. Side effects/resources must be explicit in IR types.

## Milestones

### M-02-1: Module boundary policy
- Status: DONE - b37260d
- Required work:
1. Define allowed import DAG by layer.
2. Add automated boundary checker.
- Acceptance tests:
1. `scripts/roadmap/check_architecture_boundaries.sh` passes on allowed imports.
2. Introducing forbidden import edge fails checker.

### M-02-2: Primary path purity
- Status: DONE - cfcce6d
- Required work:
1. Ensure primary path never depends on Cairo textual emission.
2. Add regression test to prevent accidental coupling.
- Acceptance tests:
1. Disable Cairo backend module build; primary Sierra pipeline still passes.
2. Any primary-path dependency on Cairo emitter fails boundary checks.

### M-02-3: Deterministic output contracts
- Status: DONE - 208e39b
- Required work:
1. Stable symbol and declaration ordering policy.
2. Deterministic hashing policy and tests.
- Acceptance tests:
1. Repeated generation in clean dirs produces byte-identical outputs.
2. Snapshot tests detect any unstable order drift.

## Completion criteria

1. Architecture boundaries are machine-enforced.
2. Primary pipeline is isolated from secondary backend.
3. Determinism guarantees are tested and stable.
