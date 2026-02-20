# Lean -> Sierra Subset Backend (Phase 2)

This document defines the current direct Lean -> Sierra backend contract.

## Inputs

- Input object: `IRContractSpec`.
- Source path: lower from Lean `ContractSpec` using validator/lowering/optimizer pipeline.

## Outputs

- A versioned Sierra JSON program (`version = 1`) written to `sierra/program.sierra.json`.
- Output shape matches Sierra `VersionedProgram` consumed by pinned upstream `cairo-lang-sierra`.

## Required Invariants

The backend currently accepts only this subset:

1. Storage is empty (`IRContractSpec.storage = []`).
2. Every function is `view`.
3. Every function has no writes (`writes = []`).
4. Function parameter/return types are restricted to `felt252` and `u128`.
5. Supported expression forms:
- `IRExpr.var`
- `IRExpr.letE`
- `IRExpr.litFelt252`
- `IRExpr.litU128`
- `IRExpr.addFelt252`
- `IRExpr.subFelt252`
- `IRExpr.mulFelt252`
6. Emitted Sierra preserves linear-use discipline via explicit `dup`/`drop` handling and materializes deferred values with `store_temp` before reuse.

## Failure Modes (Fail-Fast)

The backend returns explicit errors for:

1. Non-empty storage declarations.
2. Mutable functions or functions with writes.
3. Unsupported signature types (`u256`, `bool`).
4. Unsupported expression forms (storage reads, comparisons, `ite`, etc.).
5. Unsupported arithmetic families where semantics are not fully modeled yet:
- `u128` arithmetic (`addU128`, `subU128`, `mulU128`) due pending range-check threading model.
- `u256` arithmetic (`addU256`, `subU256`, `mulU256`) due pending struct-level lowering model.
6. Unbound variables or internal linearity-state inconsistencies.

## Validation/Compilation Contract

- Validation: generated Sierra is checked with upstream `ProgramRegistry<CoreType, CoreLibfunc>`.
- Compilation: generated Sierra is compiled to CASM using upstream `cairo-lang-sierra-to-casm`.
- Pin: Cairo commit `e56055c87a9db4e3dbb91c82ccb2ea751a8dc617`.

## Determinism and Coverage Checks

- Surface binding generation determinism:
  - `scripts/test/sierra_surface_codegen.sh`
- Sierra JSON snapshot determinism:
  - `scripts/test/sierra_codegen_snapshot.sh`
- Fail-fast regression checks for unsupported families:
  - `scripts/test/sierra_failfast_unsupported.sh`
- End-to-end validation + CASM compilation:
  - `scripts/test/sierra_e2e.sh`

## Rationale

This phase keeps the direct Lean -> Sierra path semantics-preserving for the supported subset,
while explicitly rejecting unsupported forms until their typing/resource semantics are modeled and verified.
