# Spec Compliance Matrix (`spec.md`)

## Required deliverables

- `leancairo-gen` CLI executable: `lakefile.lean`, `src/LeanCairo/CLI/Main.lean`
- Lean EDSL + validator: `src/LeanCairo/Core/**`
- Cairo codegen with interface/contract/embed ABI impl: `src/LeanCairo/Backend/Cairo/**`
- Scarb project generator: `src/LeanCairo/Backend/Scarb/**`, `src/LeanCairo/Pipeline/Generation/**`
- Example contract: `src/Examples/Hello.lean`, `src/MyLeanContract.lean`
- CI checks: `.github/workflows/ci.yml`, `scripts/test/**`, `scripts/lint/pedantic.sh`

## Section mapping

- Goal G1 (Lean DSL): `src/LeanCairo/Core/Domain/Ty.lean`, `src/LeanCairo/Core/Syntax/Expr.lean`, `src/LeanCairo/Core/Spec/*.lean`
- Goal G2 (deterministic Cairo codegen shape): `src/LeanCairo/Backend/Cairo/EmitContract.lean`
- Goal G3 (Scarb compilation artifacts): `src/LeanCairo/Backend/Scarb/Manifest.lean`
- Goal G4 (ABI + compilation checks in CI): `scripts/test/e2e.sh`, `scripts/utils/check_abi_surface.py`, `.github/workflows/ci.yml`
- Name mangling + keyword escaping: `src/LeanCairo/Backend/Cairo/Naming.lean`, `src/LeanCairo/Backend/Cairo/ReservedWords.lean`
- Expression lowering: `src/LeanCairo/Backend/Cairo/EmitExpr.lean`
- Artifact discovery helper: `scripts/utils/find_contract_artifact.py`, generated helper from `src/LeanCairo/Backend/Scarb/ArtifactHelper.lean`
- Snapshot determinism test: `scripts/test/codegen_snapshot.sh`, `tests/golden/hello/lib.cairo`

## Explicit non-goal enforcement

- Extension note: stateful mutation is now supported via `externalMutable` + explicit storage writes in `FuncSpec.writes`.
- No unsupported constructs (loops/recursion/etc.): AST surface in `Expr` excludes them by construction.
