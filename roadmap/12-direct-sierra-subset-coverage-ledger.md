# 12. Direct Sierra Subset Coverage Ledger

## Purpose

Track exactly what the direct Sierra emitter subset currently supports, what is completed with evidence, and what remains for full Track A closure.

This file is a strict status ledger for `src/LeanCairo/Backend/Sierra/Emit/SubsetProgram.lean`, not a replacement for the full implementation plan in:

1. `roadmap/05-track-a-lean-to-sierra-functions.md`
2. `roadmap/03-typed-ir-generalization-plan.md`
3. `roadmap/04-semantics-proof-and-law-plan.md`

## Canonical Constraints

1. `spec.md` and `spec2.md` are canonical.
2. Primary path remains `Lean -> Typed MIR -> Sierra -> CASM`.
3. Any unsupported subset item must fail fast with explicit error contracts.
4. No subset item is marked completed without validation, compilation, and differential evidence.

## Status Legend

1. `DONE - <commit>`
2. `NOT DONE`

## Completed Subsets

### S0 Surface-pinned subset lane
- Status: DONE - 6a1f5ce
- Scope:
1. Pinned Sierra type/libfunc IDs are generated and checked.
2. Emitter refuses unknown generic IDs.
3. Subset lane is constrained by explicit guardrails.

### S1 Scalar lane (current implemented core)
- Status: DONE - 8e775a3
- Scope:
1. Signature types: `felt252`, `u128`, `bool`.
2. Expression support: `var`, `letE`, `litFelt252`, `litU128`, `litBool`, `felt252 add/sub/mul`.
3. Top-level equality returns for `felt252` and `u128`.
4. ProgramRegistry and Sierra -> CASM e2e gates wired and passing.

## Pending Subsets

### S2 Range-checked integer arithmetic families
- Status: DONE - 6833a1a
- Target:
1. `u8`, `u16`, `u32`, `u64`, `u128`, signed integer families with explicit `RangeCheck` threading.
2. Overflow/checked arithmetic paths with typed panic/result handling where required.
3. Differential tests for overflow boundary behavior.
- Evidence:
1. `scripts/test/sierra_u128_range_checked_e2e.sh`
2. `scripts/test/sierra_u128_wrapping_differential.sh`
3. `scripts/test/sierra_failfast_unsupported.sh`
4. `scripts/workflow/run-sierra-checks.sh`

### S3 Multi-limb integers and struct semantics
- Status: NOT DONE
- Target:
1. `u256` and `u512` semantics via explicit aggregate representation.
2. No erased or implicit limb coercions.
3. Proof obligations for limb-wise correctness relations.

### S4 Field/math scalar extensions
- Status: NOT DONE
- Target:
1. `qm31` family and related semantics.
2. Stable fail-fast coverage for unimplemented variants.

### S5 Aggregates and control/data structures
- Status: NOT DONE
- Target:
1. `structure`, `enm`, tuple lowering and typed branch joins.
2. `array`, `span`, `nullable`, `box`, `felt252_dict` families.
3. Resource and ownership semantics are explicit and test-covered.

### S6 Calls, control flow, and runtime families
- Status: NOT DONE
- Target:
1. `function_call`, recursion, panic propagation.
2. `gas`, `ap_tracking`, `segment_arena`, diagnostics families.
3. Optimization legality gates under metadata/resource constraints.

### S7 Non-Starknet closure
- Status: NOT DONE
- Target:
1. Full non-Starknet family closure from pinned inventory.
2. `Coverage = implemented_families / targeted_families = 1.0`.

## Closure Metric Snapshot

This snapshot is machine-checked against `roadmap/inventory/sierra-coverage-matrix.json`.
Values must be updated in the same commit as coverage/status changes and must satisfy
`python3 scripts/roadmap/check_subset_ledger_sync.py`.

- `pinned_surface_commit`: `e56055c87a9db4e3dbb91c82ccb2ea751a8dc617`
- `target_non_starknet_extension_modules`: `52`
- `implemented_non_starknet_extension_modules`: `4`
- `fail_fast_non_starknet_extension_modules`: `13`
- `unresolved_non_starknet_extension_modules`: `35`
- `implemented_non_starknet_closure_ratio`: `0.076923`
- `bounded_non_starknet_closure_ratio`: `0.326923`
- `done_subset_milestones`: `3`
- `total_subset_milestones`: `8`
- `subset_milestone_progress_ratio`: `0.375000`

## Required Evidence For Status Promotion

Each subset item can move from `NOT DONE` to `DONE - <commit>` only when all are present:

1. Implementation evidence in backend/IR/proof files.
2. Validation evidence: ProgramRegistry pass.
3. Compilation evidence: Sierra -> CASM pass.
4. Differential evidence against reference semantics where applicable.
5. Benchmark evidence for optimization-affecting changes.

## Synchronization Rules

1. Update this ledger in the same commit that changes subset capability.
2. Mirror milestone status updates in `roadmap/executable-issues/05-track-a-lean-to-sierra-functions.issue.md`.
3. Keep statuses in this file and `roadmap/executable-issues/12-direct-sierra-subset-coverage-ledger.issue.md` consistent.
