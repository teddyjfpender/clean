# Spec2: Architecture Direction (Pinned)

Date: 2026-02-20
Status: active architecture direction note

## Decision

Primary compiler direction is:

1. Lean -> Sierra -> CASM for optimization/correctness-critical compilation.
2. Lean -> Cairo as a secondary review/debug backend.

## Rationale

1. Sierra is the canonical typed IR surface used by upstream validation and CASM compilation.
2. Targeting Sierra directly avoids duplicating large frontend/corelib behavior before optimization.
3. Performance and low-level control objectives are best served by direct Sierra/CASM-aware optimization.

## Explicit non-goals (current stage)

1. Not a compiler from arbitrary Lean programs to Cairo.
2. Not formally verified semantics-preserving compilation for all families yet.

## Required next trajectory

1. Introduce and expand generic typed MIR.
2. Perform optimizations MIR-to-MIR and Sierra-aware, not via IR -> DSL -> IR loops.
3. Define semantics and prove pass/lowering preservation incrementally.
4. Keep benchmark and non-regression gates mandatory.

## Canonical execution plan

The actionable plan is tracked in:

1. `roadmap/README.md`
2. `roadmap/executable-issues/INDEX.md`

When this note and executable issues differ in operational detail, executable issues govern implementation sequencing.

