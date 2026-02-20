# S2 Start: Range-Checked `u128` Lowering Plan

Date: 2026-02-20

## Scope

This document defines the first strict S2 step for the direct Sierra emitter:

1. Add explicit range-checked integer lowering for `u128` arithmetic.
2. Keep unsupported integer forms fail-fast until semantics and proofs are complete.

This is a design/start note, not a completion claim.

## Inputs / Outputs

### Inputs

1. `IRExpr` nodes:
  - `.addU128`
  - `.subU128`
  - `.mulU128` (wrapping path)
2. Existing direct Sierra emitter state and linear environment.
3. Pinned Sierra surface at commit:
  - `e56055c87a9db4e3dbb91c82ccb2ea751a8dc617`

### Outputs

1. Validated Sierra for supported `u128` arithmetic forms.
2. CASM-compilable Sierra (not only ProgramRegistry-valid).
3. Stable fail-fast error contracts for unsupported forms.

## Required Invariants

1. Resource threading is explicit; no hidden range-check values.
2. No implicit coercions or semantic fallback rewrites.
3. Branch shaping must satisfy Sierra->CASM reference and AP-change constraints.
4. Unsupported forms fail with exact, deterministic error strings.

## Verified Upstream Constraints (from pinned Sierra signatures)

`u128_overflowing_add` / `u128_overflowing_sub` require:

1. Input: `(RangeCheck, u128, u128)`
2. Two branches, each returning `(RangeCheck, u128)`
3. AP-change model: branch signatures are not free-form and must satisfy merge/return rules accepted by Sierra->CASM.

## Observed Blocker During Initial Attempt

A direct lowering attempt that merged/returned branch `u128` outputs as plain `u128` produced:

1. ProgramRegistry validation success.
2. Sierra->CASM compile failure with AP-change/reference constraints (`Return arguments are not on the stack` / `should not have ap-change variables` depending on branch shape).

This indicates that a naive "overflowing op -> wrapped `u128` return" form is not sufficient in this lane.

## Implication

S2 cannot be completed by adding only libfunc calls; it requires one of:

1. A checked/panic result model for `u128` arithmetic return forms compatible with Sierra lowering rules.
2. A proven branch canonicalization strategy that yields a legal non-panic wrapped return form under Sierra->CASM constraints.

## Status Update (Implemented Slice)

The second path above was implemented for wrapping `add/sub/mul`:

1. `u128_overflowing_*` branches now normalize through:
  - `branch_align`,
  - `store_temp<RangeCheck>` / `store_temp<u128>` on both branches to shared output ids,
  - `jump` to a single join/return point.
2. Direct emitter function signatures with `u128 add/sub/mul` now include explicit `RangeCheck` in/out lanes.
3. Gate script added and wired:
  - `scripts/test/sierra_u128_range_checked_e2e.sh`
4. Wrapping `mul` lowering now uses pinned Sierra semantics:
  - `u128_guarantee_mul` to obtain `(high, low, guarantee)`,
  - explicit `drop<u128>` on `high`,
  - `u128_mul_guarantee_verify` to consume guarantee and thread `RangeCheck`,
  - returned value is `low` (`mod 2^128` wrapping result).

This satisfies a first CASM-legal wrapping lane, but does not close S2.

## Next Implementation Steps

1. Extend IR semantics to distinguish checked vs wrapping integer operations.
2. Implement checked/panic-aware integer result typing and lowering shape (pinned-signature-compatible).
3. Add differential tests over overflow boundaries for checked behavior.
4. Extend from `u128` wrapping operations to additional integer families.

## Gate Criteria For The Next S2 Code Slice

1. New `u128` corpus passes:
  - ProgramRegistry validation
  - Sierra->CASM compilation
2. Existing scalar corpus remains green.
3. Fail-fast fixtures still pass for unmodeled integer variants (`u256`, non-enabled integer families, unsupported expression placements).
