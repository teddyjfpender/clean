# 00. Charter And Completion Definition

## Objective

Deliver complete function-level support for pinned Cairo surfaces with primary Lean -> Sierra -> CASM generation, and secondary Lean -> Cairo generation, under explicit formal and testing constraints.

## Inputs

1. Baseline scope in `spec.md` (historical MVP specification).
2. Active architecture direction in `spec2.md` (Lean -> Sierra primary, Lean -> Cairo secondary).
3. Executable plan and status tracker in `roadmap/executable-issues/INDEX.md`.
2. Pinned upstream Cairo sources at commit `e56055c87a9db4e3dbb91c82ccb2ea751a8dc617`.
3. Existing Lean typed DSL and optimizer infrastructure.

## Document Authority

When documents differ, use this precedence:

1. `roadmap/executable-issues/INDEX.md` and corresponding `*.issue.md` files (active execution contract)
2. `roadmap/*.md` (program-level roadmap and milestones)
3. `spec2.md` (architecture direction note)
4. `spec.md` (historical baseline context)

## Outputs

1. A function compiler that covers full targeted Sierra/corelib surfaces with measurable compatibility.
2. A formal semantics and proof pipeline where every optimization/lowering pass has explicit obligations.
3. Deterministic CI gates for correctness, compatibility, and performance.

## Completion Definition: Primary Track (Lean -> Sierra -> CASM)

The primary track is complete only when all conditions hold:

1. Surface closure:
- 100% of pinned `generic_type_ids` and supported `generic_libfunc_ids` are accounted for by one of:
- implemented lowering
- intentionally unsupported with documented proof of exclusion and fail-fast path
- deferred by explicit feature gate with tracking issue
2. Semantic closure:
- typed source semantics defined in Lean for the full supported source subset
- target Sierra operational semantics defined for covered libfunc families
- translation relation defined and machine-checked for covered nodes
3. Proof closure:
- every optimization pass and lowering stage has a compositional preservation theorem over declared semantics
- proof CI fails on any uncovered new pass or changed theorem assumptions
4. Toolchain closure:
- all generated Sierra validates under pinned `ProgramRegistry`
- all generated Sierra compiles to CASM with pinned `cairo-lang-sierra-to-casm`
- deterministic generation checksum gates pass
5. Performance closure:
- benchmark suite covers arithmetic, control-flow, data-structure, and crypto/circuit kernels
- no-regression gate is green
- any claimed improvement has before/after artifact metrics

## Completion Definition: Secondary Track (Lean -> Cairo)

The secondary track is complete only when all conditions hold:

1. Source closure:
- emitted Cairo source can express all function-level features covered by primary track
- corelib function usage parity is demonstrated for covered domains
2. Equivalence closure:
- Lean -> Cairo and Lean -> Sierra outputs are differentially tested on shared corpus
- mismatches are either fixed or documented as intentional with proof/tests
3. Usability closure:
- emitted Cairo remains deterministic and reviewable
- formatting/structure is stable for diff-based review

## Hard Invariants

1. Function-first precedence over contract plumbing.
2. Fail-fast on unsupported semantics; no best-effort unsound lowering.
3. No direct IR -> DSL -> IR loops in primary compilation path.
4. Effects, mutation, and resource constraints must be explicit in typed IR.

## Failure Modes To Reject

1. Hidden implicit coercions that alter semantics.
2. Optimization passes that depend on unstated side conditions.
3. Backend-specific behavior divergence without tests and written rationale.
4. Any benchmark report not reproducible from committed scripts.

## Required Governance

1. Every roadmap item maps to:
- implementation artifact
- proof artifact or explicit proof debt record
- test artifact
2. Every unsupported surface item must have:
- fail-fast behavior
- error message contract
- tracking issue and milestone assignment
