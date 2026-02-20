# LeanCairoMVP

Lean 4 EDSL -> Cairo Starknet contract generator (MVP), aligned to `spec.md`.

Status: Lean -> Cairo -> Scarb is wired and passing end-to-end in this repository.

## What You Can Do Now

1. Define pure contract behavior in Lean as `ContractSpec` data.
2. Generate Starknet Cairo contract source deterministically from that Lean spec.
3. Compile generated Cairo with Scarb to Sierra artifacts.
4. Optionally emit CASM by passing `--emit-casm true`.
5. Validate generated ABI surface automatically against expected signatures.
6. Run a full quality gate (`./scripts/workflow/run-mvp-checks.sh`) covering lint + snapshot + build + ABI checks.

## Current MVP Limits

- View-only functions (no state mutation support yet).
- No storage modeling beyond empty boilerplate, no events, no syscalls, no cross-contract calls.
- Expression language is intentionally small and pure (no loops, no recursion, no dynamic memory structures).
- Felt arithmetic is restricted to pass-through/equality semantics in this MVP.

## Quick start

Run the fully wired example pipeline:

```bash
./scripts/workflow/generate-example.sh
```

Or run the steps manually:

```bash
lake exe leancairo-gen --module MyLeanContract --out ./generated_contract --emit-casm false
cd generated_contract
scarb build
```

Expected outputs after build:

- `target/dev/<target>_<contract>.contract_class.json`
- `target/dev/<target>.starknet_artifacts.json`

## CLI

```bash
lake exe leancairo-gen \
  --module <LeanModule> \
  --out <OutputDirectory> \
  [--emit-casm true|false]
```

`<LeanModule>` must define:

```lean
import LeanCairo.Core.Spec.ContractSpec

namespace MyContract

def contract : LeanCairo.Core.Spec.ContractSpec := ...

end MyContract
```

Example module in this repo: `src/MyLeanContract.lean`.

## Workflow scripts

- `scripts/workflow/generate-example.sh` runs the canonical `MyLeanContract` flow
- `scripts/workflow/generate-from-lean.sh`
- `scripts/workflow/build-generated-contract.sh`
- `scripts/workflow/run-mvp-checks.sh`

## Test and verification scripts

- `scripts/test/codegen_snapshot.sh` checks deterministic Cairo output.
- `scripts/test/e2e.sh` runs Lean generation + `scarb build` + ABI checks.
- `scripts/test/abi_surface.sh` validates ABI against expected signatures.

## Linting

`./scripts/lint/pedantic.sh` enforces strict repository hygiene:

- trailing whitespace / tabs / CRLF rejection
- shell script strict mode checks
- Python syntax parsing
- shell script linting via `shellcheck`

## Repository layout

- `src/LeanCairo/Core/...`: DSL types, syntax, spec structures, validator
- `src/LeanCairo/Backend/Cairo/...`: Cairo rendering backend
- `src/LeanCairo/Backend/Scarb/...`: manifest and helper script rendering
- `src/LeanCairo/Pipeline/Generation/...`: render plan and write boundary
- `src/LeanCairo/CLI/...`: argument parser + module invocation flow
- `src/Examples/Hello.lean`, `src/MyLeanContract.lean`: example contracts
- `tests/golden/...`, `tests/fixtures/...`: snapshot and ABI fixtures
- `docs/design/...`: design note and invariants

## Notes

- MVP mutability is restricted to `view`.
- Felt arithmetic is limited to pass-through/equality semantics in this MVP.
- Artifact location uses `*.starknet_artifacts.json` instead of hardcoded filenames.
