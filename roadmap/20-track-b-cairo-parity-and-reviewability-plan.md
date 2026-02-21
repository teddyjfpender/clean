# 20. Track B Cairo Parity And Reviewability Plan

## Objective

Deliver full function-domain Lean -> Cairo parity from shared MIR while preserving deterministic, review-grade output and strict alignment with the primary Lean -> Sierra semantics.

## Scope

1. parity across all implemented function capabilities
2. explicit divergence governance when Cairo representation differs
3. reviewability guarantees, including Sierra-anchor traceability

## Core Requirement

Cairo backend is secondary and must remain a projection from shared MIR. No Cairo-only semantic forks without tracked capability constraints.

## Parity Dimensions

1. value/result parity on shared vectors
2. failure/panic parity on boundary vectors
3. resource-sensitive behavior parity where representable
4. signature/ABI parity for function wrappers

## Reviewability Requirements

1. deterministic formatting and naming
2. stable source structure under repeated generation
3. trace mapping from Cairo output back to MIR/Sierra anchors for audits

## Delivery Phases

### Phase CPL0: AST coverage closure for shared MIR

1. extend AST emitter to cover all MIR family nodes
2. ensure deterministic source rendering contracts
3. enforce backend capability guards from registry

### Phase CPL1: Corelib mapping and divergence policies

1. formal mapping rules for corelib usage patterns
2. explicit divergence tags where backend representations differ
3. policy checks for undocumented divergence

### Phase CPL2: Differential equivalence harness expansion

1. evaluator vs Sierra vs Cairo triple-comparison suites
2. boundary/failure parity vectors
3. diagnostics for mismatch root-cause classification

### Phase CPL3: Review lift and audit traceability

1. strengthen Sierra/CASM review-lift mappings
2. cross-link generated Cairo and review-lift traces
3. ensure review tools remain non-authoritative for compilation

## Required Gates

1. deterministic Cairo codegen snapshot tests
2. backend parity differential suites
3. review-lift consistency checks
4. drift checks against capability registry projections

## Acceptance Criteria

1. Cairo backend parity is evidence-backed across implemented capabilities.
2. Divergence is explicit, governed, and tested.
3. Output remains deterministic and review-friendly.
4. Track B remains secondary and cannot regress Track A purity.
