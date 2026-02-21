# 18. Effects, Control-Flow, And Resource Semantics

## Objective

Define and implement a full effect/resource-aware function semantics layer for MIR and lowering so complex control-flow and runtime constraints can scale safely.

## Scope

1. effect algebra for pure/effectful/partial operations
2. explicit control-flow graph forms in MIR
3. call, recursion, panic, and early-exit semantics
4. resource threading semantics (`RangeCheck`, gas, AP tracking, segment arena)

## Effect Model

Every MIR function and node must declare:

1. effect signature
2. resource read/write requirements
3. partiality/failure channel behavior
4. reordering legality class for optimizations

## Control-Flow Model

1. structured branches and join semantics
2. loop/iteration canonical forms
3. recursion/mutual-call semantics with explicit call effects
4. panic and error-channel propagation semantics

## Resource Semantics

1. explicit resource state in MIR function signatures where required
2. no implicit resource acquisition in lowering
3. legality checks for resource-sensitive transformations

## Invariants

1. Pure nodes cannot consume/produce hidden resources.
2. Effectful nodes cannot be reordered without legality proof/check.
3. Control-flow normalization must preserve resource and panic behavior.
4. Backend-specific resource handling must trace back to MIR effect metadata.

## Delivery Phases

### Phase EFF0: Effect algebra and metadata schema

1. effect classes and resource annotations
2. metadata validators
3. fail-fast on missing effect metadata

### Phase EFF1: Control-flow MIR closure

1. explicit CFG node forms
2. branch/join normalization contracts
3. loop canonicalization contracts

### Phase EFF2: Call and failure semantics

1. direct/indirect call semantics (as scoped)
2. recursion contracts and stack behavior assumptions
3. panic/partial-result propagation rules

### Phase EFF3: Resource legality gates

1. static legality checks for gas/AP/resource-sensitive transforms
2. negative tests for illegal optimization behavior
3. gate integration into workflows

## Required Gates

1. effect-resource regression tests
2. semantic-state regression suites
3. control-flow differential suites
4. optimization legality negative suites

## Acceptance Criteria

1. Effect/resource semantics are explicit and enforceable in MIR.
2. Complex control-flow lowering is semantics-preserving and test-covered.
3. Resource-sensitive optimizations are legality-gated.
4. Both backends share a single effect semantics contract.
