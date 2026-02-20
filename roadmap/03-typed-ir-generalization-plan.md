# 03. Typed IR Generalization Plan

## Goal

Evolve current typed IR from narrow numeric subset into a generic, law-driven representation able to express full function-level Sierra/corelib semantics.

## Required IR Extensions

1. Type universe expansion
- scalar numerics: signed/unsigned families, felt, bounded int, qm31
- compound: tuple, struct, enum, array/span, nullable, box, dict
- proof/resource carriers: non-zero wrappers, range-check related carriers, gas/accounting carriers
2. Effect system expansion
- pure expression effects
- state effects (memory/storage where applicable)
- panic/error effects
- resource effects (range-check, gas, segment arena, builtin usage)
3. Control-flow forms
- typed branching with explicit join typing
- loops/recursion representation with termination/resource contracts
- short-circuit and pattern-match forms

## IR Laws (Must Hold)

1. Type preservation under transformation.
2. Resource accounting soundness under transformation.
3. Alpha-equivalence stability for bindings.
4. Deterministic normalization ordering.

## Work Packages

### WP-IR-1: Type And Constructor Closure

Inputs:
- pinned Sierra type/libfunc inventories
- corelib source inventory

Outputs:
- exhaustive IR constructor/type mapping spec
- missing constructor list and implementation plan

Acceptance:
- every covered upstream family mapped or explicitly excluded with fail-fast reason

### WP-IR-2: Explicit Effects And Resources

Outputs:
- effect-annotated MIR nodes
- explicit resource tokens/threads where required

Acceptance:
- no backend pass reads implicit global state for resource constraints

### WP-IR-3: Canonical Normal Forms

Outputs:
- ANF/let-normalized canonical form specification
- dominance-safe binding placement rules

Acceptance:
- canonicalizer deterministic snapshot tests

### WP-IR-4: Typeclass/Trait Lowering Strategy

Outputs:
- trait resolution and monomorphization policy in MIR
- generic instantiation constraints

Acceptance:
- no ad-hoc backend special casing for trait behavior

## Failure Modes

1. Backend-specific data leaking into core MIR.
2. Resource semantics encoded as comments/conventions instead of types.
3. Control-flow encoded via textual emission tricks.

## Deliverables

1. `docs/design` spec for MIR typing/effects.
2. MIR constructor implementation.
3. exhaustive match updates + compile-time completeness checks.
4. regression tests for each new constructor family.

