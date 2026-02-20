# 05. Track A: Lean -> Sierra Functions (Primary)

## Track Goal

Deliver full function-level compilation from Lean MIR to Sierra for the pinned upstream surface, with formal, fail-fast, and performance gates.

## Completion Metric

`Coverage = implemented_families / targeted_families`

Targeted families are derived from pinned Sierra modules inventory and generic IDs.

Direct-emitter subset progress tracking (completed vs pending) is maintained in:

1. `roadmap/12-direct-sierra-subset-coverage-ledger.md`

## Family Groups

1. Core control/memory:
- `mem`, `drop`, `duplicate`, `uninitialized`, `snapshot`, `unconditional_jump`, `branch_align`, `function_call`
2. Core scalar and comparisons:
- `felt252`, `boolean`, `is_zero`, `casts`, `try_from_felt252`
3. Integer families:
- `int/signed`, `int/signed128`, `int/unsigned`, `int/unsigned128`, `int/unsigned256`, `int/unsigned512`, `bounded_int`, `range_check`, `range`
4. Aggregates/collections:
- `structure`, `enm`, `array`, `span`, `nullable`, `boxing`, `felt252_dict`, `squashed_felt252_dict`
5. Math/crypto/circuit:
- `pedersen`, `poseidon`, `blake`, `ec`, `circuit`, `qm31`, `bytes31`, `bitwise`
6. Control/runtime:
- `consts`, `const_type`, `trace`, `debug`, `unsafe_panic`, `coupon`, `ap_tracking`, `segment_arena`, `gas`, `gas_reserve`
7. Starknet modules (deferred until function core is complete):
- `starknet/*`

## Phases

### A0: Surface Synchronization And Autogeneration

Steps:
1. Keep Sierra IDs and module inventories generated from pinned sources.
2. Generate typed Lean binding layer for types/libfunc declarations.
3. Add compatibility report: implemented vs missing IDs.

Exit criteria:
1. zero handwritten ID drift
2. deterministic snapshot check passes

### A1: Scalar Arithmetic Core (Current extension base)

Steps:
1. complete felt252 arithmetic and compare families
2. implement boolean and is-zero branch patterns
3. implement exact literal handling and const-specialized libfunc selection

Proof obligations:
1. arithmetic lowering semantic preservation
2. constant-fold compatibility with runtime semantics

Exit criteria:
1. scalar kernel corpus passes differential tests vs reference runner
2. ProgramRegistry + Sierra->CASM pass for all scalar kernels

### A2: Range-Checked Integer Families

Steps:
1. model range-check resources explicitly in MIR state
2. implement u8/u16/u32/u64/u128/signed families with overflow variants
3. implement u256/u512 helpers and multi-limb semantics

Current progress snapshot:
1. Direct emitter now supports `u128 add/sub` wrapping lowering with explicit `RangeCheck` signature threading and CASM-legal branch/join shaping.
2. Dedicated gate added: `scripts/test/sierra_u128_range_checked_e2e.sh`.
3. Remaining scope: checked/panic-aware integer result typing, `mulU128`, and non-`u128` integer families.

Proof obligations:
1. resource-threading preservation
2. overflow/checked op correctness relations

Exit criteria:
1. all integer module families enabled with no hidden implicit range-check use
2. fail-fast remains for any not-yet-modeled integer variant

### A3: Aggregates, Enums, Structs, Tuples

Steps:
1. add MIR constructors for tuple/struct/enum values and pattern destructure
2. lower to `structure` and `enm` module libfunc families
3. add branch-target typing and phi-like join normalization

Proof obligations:
1. constructor/destructor inversion laws
2. match/branch semantics equivalence

Exit criteria:
1. algebraic data type corpus compiles/executes equivalently across reference and generated targets

### A4: Arrays, Spans, Nullable, Box, Dict

Steps:
1. implement array/span memory model in MIR
2. implement nullable and boxing ownership semantics
3. implement felt252 dict and squashed dict workflows

Proof obligations:
1. aliasing and ownership invariants
2. dictionary operation semantic consistency

Exit criteria:
1. collection-heavy benchmarks compile and validate
2. resource effects are explicit and tested

### A5: Control Flow And Function Calls

Steps:
1. finalize function call lowering including recursive and mutual-call forms
2. implement panic propagation model and structured error lowering
3. support loops/iterative constructs via structured MIR control nodes

Proof obligations:
1. control-flow normalization preservation
2. call-stack semantics preservation

Exit criteria:
1. callgraph-heavy function suite passes
2. no textual control-flow hacks in backend

### A6: Crypto, Math, Circuit, EC

Steps:
1. implement hash/crypto families (`pedersen`, `poseidon`, `blake`)
2. implement `ec`, `circuit`, `qm31` families
3. validate special builtin/resource requirements

Proof obligations:
1. API-level semantic relation to reference implementations
2. resource/builtin threading invariants

Exit criteria:
1. deterministic crypto/circuit suite passes with artifact validation

### A7: Gas, AP Tracking, Segment Arena, Diagnostics

Steps:
1. model gas and AP-change-sensitive behavior in optimization legality checks
2. integrate segment arena semantics where required
3. enforce optimization side-condition checks based on metadata

Proof obligations:
1. optimization legality under gas/AP constraints

Exit criteria:
1. metadata-based non-regression gates pass for gas/AP-sensitive corpus

### A8: Full Family Closure (Function Domain)

Steps:
1. close all non-Starknet module families in inventory
2. produce coverage report proving closure
3. remove temporary fail-fast for families that reached full semantics and proofs

Exit criteria:
1. 100% closure of targeted non-Starknet function families

### A9: Optional Starknet Function Interop Layer

Steps:
1. add Starknet module families only after function core closure
2. keep contract concerns isolated from function core logic

Exit criteria:
1. contract interop does not regress function-only pipeline correctness/performance

### A10: Sierra -> Cairo Review Lift (Readability Layer)

Steps:
1. define a non-authoritative, review-only structured pretty-printer from Sierra/CASM-adjacent IR to Cairo-like code
2. keep this layer strictly out of semantic compilation path (no IR -> DSL -> IR feedback loop)
3. add fidelity checks that map review output back to Sierra statement anchors for audit traceability

Exit criteria:
1. reviewers can inspect generated low-level functions in Cairo-like syntax with source anchor mapping
2. no optimizer or lowering pass depends on this review lift output

## Required Gates Per Family

A family can move to "supported" only if all pass:

1. implementation tests
2. differential tests vs reference
3. proof obligations
4. benchmark and artifact gates
