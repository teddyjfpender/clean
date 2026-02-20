# LeanCairoMVP Design Note

Date: 2026-02-20
Status: Active implementation baseline
Authority: `spec.md` (canonical)

## 1. Scope

This repository implements the `spec.md` MVP pipeline end-to-end:

1. Lean author writes `def contract : ContractSpec` in module `<ModuleName>`.
2. `lake exe leancairo-gen --module <ModuleName> --out <dir> [--emit-casm true|false]` generates a Scarb contract package.
3. `scarb build` compiles the generated package to Starknet artifacts.
4. CI verifies deterministic codegen and ABI surface conformance.

Out-of-scope behavior follows `spec.md` non-goals (stateful storage semantics, events, syscalls, loops/recursion extraction, direct Sierra emission).

## 2. Inputs and outputs

### Inputs

- CLI argument `--module <LeanModule>` with `def contract : ContractSpec`
- CLI argument `--out <Directory>`
- Optional CLI argument `--emit-casm <true|false>` default `false`

### Outputs

The generator writes a Scarb project under `<Directory>`:

- `Scarb.toml`
- `src/lib.cairo`
- `README.md`
- `scripts/find_contract_artifact.py`

Expected downstream build artifacts (via `scarb build`):

- `target/dev/<target>_<contract>.contract_class.json`
- `target/dev/<target>.starknet_artifacts.json`
- Optional CASM artifact when `casm = true`

## 3. Invariants

### AST/validation invariants

- Contract name and function names are valid identifiers.
- No duplicate function names in a contract.
- No duplicate argument names inside a function.
- Every variable reference is bound in lexical scope (`args` + `let`).
- Variable references use the same type as their binding.
- Storage reads/writes must reference declared storage fields with matching types.
- View functions cannot declare storage writes.

### Codegen invariants

- Generated Cairo shape is fixed:
  - `#[starknet::interface]`
  - `#[starknet::contract]`
  - `#[abi(embed_v0)] impl ...`
- Function ordering matches Lean spec ordering.
- Expression lowering is total over supported AST constructors.
- Name mangling is deterministic and keyword-safe.

### Build invariants

- Generated `Scarb.toml` always includes `[[target.starknet-contract]]`.
- `sierra = true` always.
- `casm = <emit-casm flag>` exactly.

## 4. Failure modes

- CLI argument parse failure: missing/invalid flags.
- Invalid module token (unsafe import path characters).
- Module import or `contract` symbol resolution failure.
- Contract validation failure (duplicate names, unbound vars, type mismatch, invalid storage access/write declarations).
- File system write failure.
- `scarb build` failure in downstream checks.
- ABI mismatch against expected signatures.

All failures are represented as explicit diagnostic errors and non-zero process exit codes.

## 5. Determinism and effect isolation

- Pure layers: AST, validation, codegen, manifest rendering, expected ABI derivation.
- Effect boundary: file I/O and process invocations are isolated in CLI/workflow scripts.
- Snapshot test asserts deterministic generated Cairo for fixed input.

## 6. Minimal stable interfaces

- `ContractSpec`, `FuncSpec`, `Expr`, `Ty` are public DSL surface.
- `validateContract` is public validation entrypoint.
- `renderContract` and `renderScarbManifest` are public rendering entrypoints.
- `generateProject` is public end-to-end library entrypoint.

Internal formatting details, script templates, and naming helper internals remain private modules.

## 7. Security/correctness constraints

- Felt arithmetic is restricted to pass-through and equality in MVP semantics policy.
- Allowed-libfunc constraints are delegated to Scarb default validation.
- No hidden network dependencies in tests.
- ABI checks consume the generated artifacts index and do not hardcode class filenames.
