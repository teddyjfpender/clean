# 23. Verified Optimizing Compiler Escalation Plan

## Objective

Escalate from structural generator to verified optimizing compiler for a constrained but expanding Lean subset, with semantics-preserving passes from MIR through Sierra/CASM-relevant representations.

## Scope

1. typed optimization-pass interface and composition laws
2. MIR optimization expansion with proofs
3. Sierra/CASM-aware optimization layers with legality constraints
4. optimization closure reporting tied to benchmark outcomes

## Core Principle

No optimization pass enters default pipeline without:

1. explicit legality contract,
2. semantic preservation obligation,
3. deterministic regression tests,
4. benchmark non-regression evidence.

## Pass Program Layers

1. MIR canonicalization, CSE, DCE, inlining/specialization, arithmetic simplification
2. effect/resource-aware transforms with legality guards
3. Sierra structural transforms (ordering, branches, resource-flow simplification)
4. CASM-oriented selection heuristics and scheduling hints

## Delivery Phases

### Phase OPTX0: Pass contract framework closure

1. typed pre/post-condition interface
2. compositional proof obligation tracking
3. pipeline contract checker for missing obligations

### Phase OPTX1: MIR pass expansion with proofs

1. implement high-value MIR passes under contract framework
2. prove semantic preservation (or record bounded checker-based debt)
3. gate on deterministic regression suites

### Phase OPTX2: Sierra optimization layer

1. implement Sierra-safe transforms under explicit legality checks
2. differential semantic checks against unoptimized outputs
3. maintain ProgramRegistry and CASM compile validity

### Phase OPTX3: Cost-guided backend decisions

1. connect cost model signals into pass/selection policy
2. calibrate and gate on measured outcomes
3. avoid overfitting with corpus diversity checks

### Phase OPTX4: Verified optimization closure report

1. aggregate proof coverage and debt
2. aggregate benchmark deltas by family
3. publish readiness status for release decisions

## Required Gates

1. optimizer pass regression tests
2. proof obligation checks
3. Sierra validation/compile checks post-optimization
4. benchmark non-regression and threshold checks

## Acceptance Criteria

1. Optimization pipeline is contract-driven and auditable.
2. Proof/evidence debt is explicit and bounded.
3. Performance improvements are measured, not assumed.
4. Compiler evolution remains semantics-first under increased complexity.
