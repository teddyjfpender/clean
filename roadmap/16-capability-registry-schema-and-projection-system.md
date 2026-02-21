# 16. Capability Registry Schema And Projection System

## Objective

Define and enforce a single machine-readable capability registry that is the canonical source of truth for function-family support across:

1. Lean MIR features,
2. Lean -> Sierra lowering,
3. Lean -> Cairo emission,
4. proof obligations,
5. test/benchmark obligations.

## Scope

This roadmap item formalizes how support is declared, tracked, projected, and gated. It does not implement family semantics itself; it governs the expansion mechanism.

## Required Artifacts

1. capability registry schema (versioned)
2. capability registry data file(s)
3. schema validators
4. projection generators to human and machine reports
5. drift checks between registry and generated projections

## Canonical Data Model

Each capability entry must include:

1. `capability_id` (stable, immutable once published)
2. `family_group` (`scalar`, `integer`, `aggregate`, `collection`, `control`, `resource`, `crypto`, `circuit`, `runtime`)
3. `mir_nodes` (source constructs)
4. `sierra_targets` (generic type/libfunc families)
5. `cairo_targets` (corelib surface forms)
6. `resource_requirements` (`range_check`, `gas`, `ap_tracking`, `segment_arena`, `panic_signal`, etc.)
7. `semantic_class` (`pure`, `effectful`, `partial`)
8. `support_state` (`planned`, `fail_fast`, `implemented`)
9. `proof_class` and `proof_status`
10. `test_class` and `benchmark_class`
11. version and changelog metadata

## Invariants

1. No backend may claim implementation of a capability absent from registry.
2. No capability may be marked `implemented` without linked proof/test obligations.
3. `fail_fast` capabilities must have explicit error contract references.
4. Registry projections are generated artifacts; manual edits to projections are rejected.

## Projection Outputs

1. Sierra coverage matrix projection
2. Cairo parity matrix projection
3. capability debt report (proof/test/benchmark)
4. release closure snapshot keyed by capability IDs

## Failure Modes To Reject

1. duplicated capability IDs
2. incompatible status transitions (`planned -> implemented` without fail-fast or explicit policy bypass)
3. backend coverage claims not backed by capability state
4. inconsistent resource requirements between MIR and lowering metadata

## Delivery Phases

### Phase CREG0: Schema and transition rules

1. schema definition and versioning policy
2. status transition rules and validator
3. migration rules for schema evolution

### Phase CREG1: Registry bootstrap from existing coverage

1. bootstrap entries for currently tracked families
2. map existing subset ledger milestones to capability IDs
3. tag unknown/legacy areas as explicit debt entries

### Phase CREG2: Projection generators and drift checks

1. generate roadmap inventory projections from registry
2. add freshness/drift CI checks
3. add deterministic ordering guarantees

### Phase CREG3: Backend integration contracts

1. require backend support checks to query registry projections
2. ban handwritten capability maps in emitters
3. fail build on unsupported unregistered capabilities

### Phase CREG4: Closure dashboards and SLO gates

1. closure ratio by family and backend
2. monotonicity gates for implemented capability growth
3. release snapshot artifact generation

## Acceptance Criteria

1. Capability registry is authoritative and validated in CI.
2. Coverage/parity reports derive solely from registry projections.
3. Status transitions are enforced by tooling.
4. Capability-driven expansion is auditable and reproducible.
