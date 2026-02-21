# 17. Type System And Semantics Closure Program

## Objective

Fully close function-domain type semantics in Lean MIR and evaluation/proof layers so no backend relies on implicit coercions or type erasure shortcuts.

## Scope

Primary focus:

1. scalar, integer-width/sign families, field families, aggregates, collections, wrapper/resource types.
2. shared semantics consumed by both Lean -> Sierra and Lean -> Cairo tracks.

## Type Closure Targets

1. Scalar: `felt252`, `bool`
2. Integer signed: `i8`, `i16`, `i32`, `i64`, `i128`
3. Integer unsigned: `u8`, `u16`, `u32`, `u64`, `u128`, `u256`, `u512` (where representable through typed aggregates)
4. Field-like: `qm31`, `bytes31` and related constrained domains
5. Aggregates: tuple/struct/enum typed constructors/destructors
6. Collections: array/span/dict forms and nullable/box wrappers
7. Resource and control wrappers: range-check, gas/ap, segment-arena, panic channels

## Semantic Contracts

Each type family must declare:

1. value domain and normalization law
2. overflow/underflow behavior (wrapping/checked/panic policy)
3. conversion/cast semantics with legality conditions
4. equality/order semantics and partiality boundaries
5. resource constraints for operations requiring explicit threading

## Invariants

1. No type family maps to another family storage slot in evaluator/backends.
2. No implicit cross-width/sign coercions.
3. All casts are explicit MIR nodes with fail-fast on invalid conversions.
4. Semantics for unsupported types are explicit `fail_fast`, not silent fallback.

## Delivery Phases

### Phase TYC0: Type universe closure in Core + IR

1. align `Ty` universe with declared function-domain families
2. close MIR node coverage for all declared type families
3. enforce exhaustive pattern handling with fail-fast defaults

### Phase TYC1: Numeric semantics closure

1. finalize signed/unsigned width semantics
2. finalize multi-limb integer representation contracts
3. finalize field-family semantics (`qm31`, constrained domains)

### Phase TYC2: Cast and conversion closure

1. explicit conversion node taxonomy
2. legality tables for allowed conversions
3. failure-mode semantics and diagnostics

### Phase TYC3: Aggregate and wrapper semantics

1. tuple/struct/enum laws
2. nullable/box/nonzero wrapper laws
3. collection element typing and alias semantics

### Phase TYC4: Proof and differential closure

1. semantic evaluator laws for each family
2. backend differential tests per family
3. proof obligations and debt tracking integrated into CI

## Required Gates

1. type-universe regression tests
2. semantic domain isolation tests
3. integer-width and field semantics differential suites
4. fail-fast policy lock checks

## Acceptance Criteria

1. Type-family semantics are complete, explicit, and non-overlapping.
2. Both backends consume the same typed semantics contract.
3. Unsupported forms remain fail-fast with stable diagnostics.
4. No type-erasure shortcuts remain in function-domain compilation.
