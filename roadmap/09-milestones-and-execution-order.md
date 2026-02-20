# 09. Milestones And Execution Order

This sequence is dependency-ordered and assumes function-first priorities.

## M0: Baseline Freeze And Inventory Closure

Deliverables:
1. pinned inventories committed and gated
2. coverage dashboard skeleton created
3. fail-fast matrix documented

Depends on:
- existing pin and surface generators

## M1: MIR Generalization Foundation

Deliverables:
1. expanded type/effect MIR schema
2. constructor-level tests
3. migration of existing passes to new interfaces

Depends on:
- M0

## M2: Formal Semantics Foundation

Deliverables:
1. resource-aware state semantics
2. pass contract template and theorem scaffolds
3. proof CI wiring

Depends on:
- M1

## M2.5: Evaluator Type-Domain Separation

Deliverables:
1. scalar type-domain isolated evaluator context (no cross-family collapsing)
2. strict fail-fast evaluator path for unsupported domains
3. non-interference law tests and proof-gate wiring

Depends on:
- M2

## M3: Scalar Family Completion (Primary)

Deliverables:
1. full felt/boolean/is-zero/casts coverage in primary backend
2. proof obligations for scalar pass/lowering paths
3. differential scalar test suite

Depends on:
- M2.5

## M4: Integer Family Completion (Primary)

Deliverables:
1. range-check aware integer lowering (`u*`, `i*`, `u128/u256/u512`, bounded)
2. explicit resource threading semantics
3. integer benchmark suite and non-regression gates

Depends on:
- M3

## M5: Aggregate And Collection Completion (Primary)

Deliverables:
1. struct/enum/tuple lowering
2. array/span/nullable/box/dict lowering
3. associated proof and differential suites

Depends on:
- M4

## M6: Control-Flow And Callgraph Completion (Primary)

Deliverables:
1. complete branching/loop/call lowering
2. panic/error propagation model
3. large callgraph benchmark suite

Depends on:
- M5

## M7: Crypto/Circuit/Advanced Builtins (Primary)

Deliverables:
1. pedersen/poseidon/blake/ec/circuit/qm31 families
2. builtin/resource correctness checks
3. performance + correctness corpus for advanced domains

Depends on:
- M6

## M8: Function-Domain Closure Report (Primary)

Deliverables:
1. 100% closure report for targeted non-Starknet function families
2. full proof and benchmark status report
3. removal of temporary fail-fast guards for completed families

Depends on:
- M7

## M9: Secondary Cairo Backend Parity Expansion

Deliverables:
1. structured Cairo AST emitter
2. parity for completed primary feature sets
3. differential backend parity dashboard
4. Sierra -> Cairo review lift prototype with statement-anchor traceability

Depends on:
- M5 onward; finalized at M8

## M10: Optional Starknet/Contract Layer Reintegration

Deliverables:
1. Starknet module families and contract wrappers isolated as adapter layer
2. contract tests separated from function-core tests

Depends on:
- M8

## M11: Stabilization And Release

Deliverables:
1. final compatibility/proof/benchmark reports
2. reproducible release scripts
3. roadmap closure or next-pin migration plan

Depends on:
- M9 and M10

## Sequencing Rule

Primary track milestones M0-M8 are mandatory before claiming complete support for the function-first vision.
