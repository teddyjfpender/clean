# 19. Track A Sierra Family Closure Execution Plan

## Objective

Provide a strict execution program to close all targeted function-domain Sierra families for Lean -> Sierra -> CASM with formal semantics, fail-fast guarantees, and benchmark evidence.

## Scope

1. direct function compilation families (non-Starknet first)
2. staged closure from scalar/int to advanced/runtime families
3. explicit optional Starknet interop isolation

## Family Closure Order

1. scalar and integer families (including range-checked and multi-limb)
2. aggregate and collection families
3. control-flow/call/runtime families
4. math/crypto/circuit/EC families
5. optional Starknet interop families

## Architecture Requirements

1. emitter modules remain decomposed by family (no monolith growth)
2. each family has typed lowering contracts and fail-fast stubs for unsupported variants
3. resource threading is explicit per family

## Formal Requirements Per Family

1. MIR capability mapping
2. lowering law/specification
3. fail-fast behavior for unsupported variants
4. differential tests and boundary tests
5. validation (`ProgramRegistry`) and CASM compilation evidence

## Delivery Phases

### Phase SCL0: Emitter architecture and scaffold readiness

1. family-scoped emitter module decomposition
2. generated scaffolds from capability registry
3. fail-fast consistency checks across families

### Phase SCL1: Scalar/integer/field closure

1. close integer width/sign families and checked/wrapping modes
2. close `u256`/multi-limb pathways and field-family forms
3. verify range-check/resource contracts

### Phase SCL2: Aggregate/collection closure

1. tuple/struct/enum family lowering
2. array/span/nullable/box/dict family lowering
3. ownership/alias and construction/destruction law checks

### Phase SCL3: Control/runtime closure

1. call/recursion/control-flow normalization closure
2. panic and partial-result channel closure
3. gas/AP/segment-arena legality constraints

### Phase SCL4: Advanced family closure

1. crypto/math/circuit/ec family lowering
2. builtin/resource constraints and diagnostics
3. benchmark and hotspot evidence collection

### Phase SCL5: Non-Starknet closure certification

1. closure ratio reaches 1.0 for targeted non-Starknet families
2. unresolved families are either optional/deferred with explicit policy
3. release-ready closure report generated

## Required Gates

1. Sierra surface/codegen snapshot checks
2. Sierra e2e validation and CASM compile checks
3. differential suites for each closed family group
4. fail-fast policy lock checks

## Acceptance Criteria

1. All targeted non-Starknet function families are closed or explicitly fail-fast tracked.
2. Family support claims are evidence-backed by validation + CASM compilation + tests.
3. Emitter architecture remains modular and auditable.
4. Closure reporting is generated and reproducible.
