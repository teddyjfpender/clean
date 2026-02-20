# 06. Track B: Lean -> Cairo Functions (Secondary)

## Track Goal

Provide full function-level Cairo emission parity from shared MIR, while keeping Lean -> Sierra as the optimization/correctness anchor.

## Role Of This Track

1. Human-readable output for review.
2. Ecosystem compatibility where Cairo source is required.
3. Differential oracle against primary Sierra path.

## Non-Goal

Do not re-center the compiler around Cairo-only lowering. Cairo emission must remain a backend from shared MIR.

## Corelib Parity Objective

Cover function-level constructs needed to express pinned `corelib/src` usage patterns, not just minimal contract scaffolding.

## Phases

### B0: Cairo AST Emitter Foundation

Steps:
1. move from string-template heavy emission to structured Cairo AST emission boundaries
2. preserve deterministic formatting policy
3. define canonical naming and hygiene policy

Exit criteria:
1. snapshot-stable deterministic output
2. formatter changes do not alter semantics

### B1: Scalar And Integer Family Parity

Steps:
1. map scalar/int MIR nodes to canonical corelib usage
2. support overflow/checked/saturating/wrapping variants via explicit lowering strategy
3. align trait calls with resolved MIR instantiations

Exit criteria:
1. parity tests with primary Sierra backend pass for scalar/int corpus

### B2: Aggregates And Collections Parity

Steps:
1. tuples, structs, enums, pattern matches
2. arrays/spans/nullable/box/dict patterns
3. iterator and adapter lowering where representable from MIR

Exit criteria:
1. collection-heavy parity corpus green

### B3: Error, Panic, And Control Flow Parity

Steps:
1. panic/error channel mapping
2. loop/branch/call lowering
3. explicit early-return and match-flow semantics parity

Exit criteria:
1. no differential behavior against Sierra primary corpus

### B4: Numeric/Math/Crypto/Circuit Parity

Steps:
1. integer traits and advanced numeric ops
2. crypto and circuit call forms as functions
3. resource-sensitive forms guarded by backend capability checks

Exit criteria:
1. representative advanced corpus passes differential testing

### B5: Corelib Surface Closure Report

Steps:
1. derive usage coverage against pinned `corelib/src` inventory
2. classify each file as:
- fully representable from current MIR
- partially representable (missing MIR feature)
- intentionally excluded from function-domain scope
3. gate merges on increasing closure percentage

Exit criteria:
1. closure report reaches target threshold defined in milestone plan

## Required Equivalence Checks

1. Lean -> Sierra -> CASM execution vs Lean -> Cairo execution on same test vectors.
2. ABI/signature parity where contract wrappers exist.
3. panic and edge-case parity for overflow/null/invalid inputs.

## Core Requirement

Any feature added first in Cairo backend without corresponding MIR design and Sierra plan is rejected unless explicitly marked temporary and tracked.

