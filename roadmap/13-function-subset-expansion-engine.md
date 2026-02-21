# 13. Function Subset Expansion Engine

## Objective

Create a capability-driven expansion engine that allows rapid, formally constrained growth of function-level support for both tracks:

1. Primary: Lean -> Sierra -> CASM.
2. Secondary: Lean -> Cairo.

This roadmap item turns subset growth from manual one-off implementation into a reproducible system.

## Why This Is Needed

Current subset expansion is still implementation-heavy per family. To scale into vastly more complex kernels, we need:

1. single-source capability metadata,
2. generated lowering scaffolds,
3. explicit fail-fast contracts by capability state,
4. shared MIR semantics across both backends.

## Required Inputs

1. `roadmap/inventory/sierra-extensions-inventory.md`
2. `roadmap/inventory/corelib-src-inventory.md`
3. `roadmap/inventory/sierra-coverage-matrix.json`
4. `roadmap/12-direct-sierra-subset-coverage-ledger.md`
5. `src/LeanCairo/Core/Domain/Ty.lean`
6. `src/LeanCairo/Compiler/IR/**`

## Capability Model

Each feature unit is represented by a typed capability record:

1. `capability_id` (stable identifier)
2. source family (MIR operator/construct)
3. Sierra target family and libfunc set
4. Cairo target emission form
5. resource requirements (`RangeCheck`, gas, AP, segment arena, panic channel)
6. semantic class (pure/effectful/partial)
7. support state:
- `implemented`
- `fail_fast`
- `planned`
8. proof obligation class
9. benchmark obligation class

## Architecture Requirements

### 13-A. Capability Registry (single source of truth)

1. Machine-readable registry file for feature status and semantics metadata.
2. No handwritten backend support lists outside registry projections.
3. Registry must project to:
- Sierra coverage reports
- Cairo parity reports
- fail-fast policy checks

### 13-B. Typed MIR Family Expansion

1. MIR operator coverage must be family-complete by declared capability set.
2. Integer/sign/width/field semantics must be explicit at MIR level.
3. Aggregate and control-flow nodes must encode effects/resources, not backend hidden state.

### 13-C. Generated Lowering Scaffolds

1. Generate emitter scaffolds from capability registry.
2. Generated scaffolds include explicit TODO/fail-fast stubs for non-implemented states.
3. Manual emitter code is only for semantic logic, not support-map bookkeeping.

### 13-D. Bidirectional Backend Projection

1. Every implemented MIR capability projects to Sierra and Cairo mappings.
2. Divergence must be recorded as explicit capability constraints.
3. No capability can be marked implemented for one backend without explicit state for the other.

## Non-Negotiable Invariants

1. Unsupported capability paths fail fast with stable error contracts.
2. No implicit coercion between integer widths/signs/field domains.
3. Resource threading is explicit in MIR and preserved through lowering.
4. Capability closure metrics are generated, not manually edited.

## Delivery Phases

### Phase SXP0: Capability registry schema and projection tooling

1. Define schema and validator.
2. Generate human reports and machine matrices.
3. Gate drift in CI.

### Phase SXP1: MIR family closure for scalar/integer/field core

1. Close missing typed ops for integer width/sign variants and `qm31` families.
2. Encode legality and failure modes in MIR.
3. Keep evaluator, optimizer, and proof contracts synchronized.

### Phase SXP2: MIR closure for aggregates, collections, and effects

1. Add typed constructors/destructors for tuple/struct/enum.
2. Add array/span/nullable/box/dict MIR families.
3. Explicit effect/resource lanes for calls/control/data operations.

### Phase SXP3: Lowering scaffold generator and backend wiring

1. Emit Sierra and Cairo lowering skeletons from capability registry.
2. Enforce fail-fast stubs for non-implemented capabilities.
3. Add sync checks between generated scaffolds and registry.

### Phase SXP4: Closure gates and capability SLOs

1. Define closure targets by family group and milestone.
2. Gate merges on monotonic capability-coverage increase.
3. Publish closure dashboard artifacts for release candidates.

## Acceptance Criteria

1. Registry projections and coverage reports are deterministic.
2. Capability status is auditable per family with linked implementation/proof/test artifacts.
3. Adding a new family requires updating registry and generated scaffolds before implementation compiles.
4. Track-A/Track-B expansion planning references capability IDs, not ad-hoc text lists.
