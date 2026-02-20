# 04. Semantics, Proof, And Law Plan

## Objective

Provide end-to-end semantic discipline for source IR, optimizer passes, and backend lowering to Sierra/Cairo.

## Semantic Layers

1. Source semantics in Lean
- deterministic evaluation for typed expressions
- explicit effect/resource transitions
2. MIR semantics
- small-step or big-step semantics with effect/resource state
3. Target semantics
- Sierra operational semantics subset (extended as coverage grows)
- Cairo expression/statement semantics for secondary backend

## Proof Obligations By Layer

1. Lowering correctness:
- source IR -> MIR preserves function meaning
2. Optimization correctness:
- each pass preserves MIR semantics
- composed pipeline preservation theorem
3. Backend correctness:
- MIR -> Sierra translation relation preserves semantics for covered families
- MIR -> Cairo translation relation preserves semantics for covered families

## Mandatory Formal Interfaces

Every pass must declare:

1. preconditions
2. postconditions
3. preserved invariants
4. non-goals
5. theorem skeleton linked to implementation

## Work Packages

### WP-SEM-1: Define Resource-Aware State

Outputs:
- formal state model including values, memory/resource tokens, and failure/panic channel

Acceptance:
- evaluator and theorem statements consume same state model

### WP-SEM-2: Sierra Family Semantics Modules

Outputs:
- semantics modules for each Sierra family as they are enabled

Acceptance:
- no enabled family without corresponding semantics definition

### WP-SEM-3: Translation Relation Library

Outputs:
- relational predicates connecting MIR programs with target programs

Acceptance:
- relation reused across backend theorems, not duplicated ad hoc

### WP-SEM-4: Proof CI Gates

Outputs:
- CI target that fails on missing theorem wiring for new passes/families

Acceptance:
- adding a new pass/family without proof stub fails CI

## Progression Rule

A feature family moves from "experimental" to "supported" only when all three are green:

1. implementation
2. tests
3. proof obligations

## Allowed Exceptions

Temporary proof debt is allowed only with:

1. explicit debt file entry
2. owner and deadline
3. fail-fast runtime guard preventing unsound optimization path

