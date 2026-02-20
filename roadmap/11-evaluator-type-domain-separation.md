# 11. Evaluator Type-Domain Separation And Semantic Closure

## Objective

Eliminate semantic type-collapsing in evaluator state and enforce typed, fail-fast behavior so the evaluator is a sound proof and optimization substrate for Lean -> Sierra.

## Problem Statement

Current evaluator bindings collapse multiple distinct Cairo type families into shared stores (for example signed integer families into `felt252` storage and unsigned/qm31 families into `u128` storage). This violates strict representation separation and permits cross-family aliasing that is not part of Cairo/Sierra semantics.

## Scope

In scope:
1. Typed variable and storage state separation for all currently declared scalar families (`felt252`, `bool`, `u128`, `u256`, `u8/u16/u32/u64`, `i8/i16/i32/i64/i128`, `qm31`).
2. Fail-fast evaluator APIs for unsupported runtime domains (compound wrappers/resources) so no silent fallback state behavior is used as semantic evidence.
3. Proof obligations and deterministic regression tests for isolation and preservation laws.
4. Integration with primary Track-A gates so unsupported or unsound evaluator behavior cannot be marked complete.

Out of scope:
1. Full operational semantics for all compound/container families in this phase.
2. Arbitrary Lean-to-Cairo semantics closure (handled by broader track milestones).

## Formal Contracts

### Inputs

1. `Ty` universe definitions and family tags.
2. `IRExpr` typed expression constructors.
3. Existing semantic state and proof modules.

### Outputs

1. A typed evaluator context with no cross-family aliasing.
2. Fail-fast `Except String` evaluator state transitions for unsupported semantic domains.
3. Law theorems and CI gates that reject regression to type-collapsing or silent fallbacks.

## Mandatory Invariants

1. Type-indexed read/write isolation:
- For `ty₁ ≠ ty₂`, updating `ty₁` bindings must not affect reads for `ty₂`.
2. No silent semantic coercion:
- Unsupported evaluator domains must return explicit errors in fail-fast APIs.
3. Deterministic evaluation:
- Fail-fast outcomes are deterministic and message-stable for a fixed input program.
4. Proof-path hygiene:
- No theorem about pass correctness may rely on collapsed cross-family store behavior.

## Work Packages

### WP-EVAL-1: Typed Scalar Domain Separation

Deliverables:
1. Distinct state slots for each scalar family in variable and storage contexts.
2. `readVar/readStorage/bindVar/bindStorage` definitions with one-to-one type-domain mapping.
3. Isolation regression tests that demonstrate no cross-family aliasing.

Acceptance:
1. Tests fail if any family is remapped onto another family store.
2. Existing evaluator preservation lemmas continue to compile.

### WP-EVAL-2: Fail-Fast Unsupported Domain APIs

Deliverables:
1. Fail-fast evaluator entry points (`Except String`) for unsupported domains.
2. Stable error contracts including function/path/type context.
3. Gate scripts that lock unsupported-domain behavior.

Acceptance:
1. Unsupported domain access is never represented as successful `Unit` semantics in fail-fast mode.
2. Negative tests verify error identity and determinism.

### WP-EVAL-3: Width/Sign Domain Semantics

Deliverables:
1. Family-specific semantic modules for signed/unsigned widths and `qm31`.
2. Range and overflow policy definitions for each integer family.
3. Law suite for arithmetic and comparison consistency with selected backend semantics.

Acceptance:
1. Differential tests cover width/sign boundary behavior per family.
2. Proof obligations for arithmetic preservation include width/sign side conditions.

### WP-EVAL-4: Resource/State Integration

Deliverables:
1. Explicit integration of evaluator type domains with resource/failure channels.
2. No hidden global state coupling between typed variable domains and resource counters.
3. State-transition tests covering mixed type/resource workloads.

Acceptance:
1. Resource transitions remain unchanged under domain-separation refactors.
2. State semantics remain deterministic under fail-fast paths.

### WP-EVAL-5: Proof And CI Closure

Deliverables:
1. Theorems for read-after-write correctness and cross-family non-interference.
2. Proof-obligation checker extensions requiring new evaluator laws.
3. CI integration in `run-sierra-checks` and `run-mvp-checks`.

Acceptance:
1. Missing evaluator law theorem fails proof gate.
2. Milestones cannot be marked complete without passing new evaluator gates.

## Failure Modes

1. Reintroducing shared stores for distinct type families.
2. Treating unsupported families as successful no-op semantics in fail-fast paths.
3. Proving pass soundness over an evaluator model that aliases unrelated domains.

## Completion Criteria

1. No scalar family maps to another family’s variable or storage domain.
2. Unsupported domains are explicit fail-fast in strict APIs.
3. Law theorems and regression tests are integrated into workflow scripts.
4. Track-A milestones that depend on evaluator correctness are dependency-gated on this roadmap item.
