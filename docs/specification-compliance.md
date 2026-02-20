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
- Typed IR + optimizer: `src/LeanCairo/Compiler/IR/*.lean`, `src/LeanCairo/Compiler/Optimize/*.lean`
- Expression/contract semantics + optimizer proofs: `src/LeanCairo/Compiler/Semantics/Eval.lean`, `src/LeanCairo/Compiler/Semantics/ContractEval.lean`, `src/LeanCairo/Compiler/Proof/OptimizeSound.lean`, `src/LeanCairo/Compiler/Proof/IRSpecSound.lean`
- Verified pass interface + composition obligations: `src/LeanCairo/Compiler/Optimize/Pass.lean`, `src/LeanCairo/Compiler/Optimize/Pipeline.lean`
- Non-trivial CSE + let-normalization pass + proof: `src/LeanCairo/Compiler/Optimize/CSELetNorm.lean`, `src/LeanCairo/Compiler/Proof/CSELetNormSound.lean`
- IR-native generation path: `src/LeanCairo/Compiler/IR/SpecLowering.lean`, `src/LeanCairo/Pipeline/Generation/IRRenderer.lean`, `src/LeanCairo/Backend/Cairo/EmitIR*.lean`
- Contract lowering/raising isomorphism laws: `src/LeanCairo/Compiler/IR/SpecLowering.lean`
- Cost/benchmark gate: `scripts/bench/compute_sierra_cost.py`, `scripts/bench/check_optimizer_non_regression.sh`
- CSE-specific benchmark gate target: `src/Examples/CSEBench.lean`, `src/MyLeanContractCSEBench.lean`, `scripts/workflow/run-mvp-checks.sh`
- Compiler-level inlining strategy control: `src/LeanCairo/Pipeline/Generation/InliningStrategy.lean`, `src/LeanCairo/Backend/Scarb/Manifest.lean`
- Review bundle generation (expanded Cairo + metrics): `scripts/bench/generate_review_bundle.sh`
- Post-build artifact optimization + validation: `scripts/bench/optimize_artifacts.py`, `scripts/bench/check_artifact_passes.sh`

## Explicit non-goal enforcement

- Extension note: stateful mutation is now supported via `externalMutable` + explicit storage writes in `FuncSpec.writes`.
- Mutable execution law: write RHS and return expressions are evaluated once in pre-state, then writes are committed.
- Duplicate writes to the same storage field in a function are rejected by validator.
- Internal compiler namespace safety: user identifiers with reserved prefix `__leancairo_internal_` are rejected.
- No unsupported constructs (loops/recursion/etc.): AST surface in `Expr` excludes them by construction.
- `spec.md` non-goal "direct Sierra emission" still holds for MVP path; current low-level tuning is done via Scarb/Cairo compiler configuration and artifact analysis.
- Explicitly out-of-scope today: arbitrary post-compilation mutation of emitted Sierra/CASM with formal semantics-preservation guarantees.
- Optimizer is now pass-composed over typed IR; no optimizer stage re-raises through source DSL during generation.
