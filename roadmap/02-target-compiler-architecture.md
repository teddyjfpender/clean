# 02. Target Compiler Architecture

## Architecture Principle

Primary compilation path must be:

`Lean Typed Source -> Typed MIR -> Verified Optimizer -> Sierra Program -> CASM`

Secondary path is:

`Lean Typed Source -> Typed MIR -> Cairo AST/Source`

Primary path is the optimization and correctness anchor. Secondary path is for reviewability, ecosystem compatibility, and differential validation.

## Boundary Layers

1. Frontend boundary (Lean DSL ingestion)
- parse/evaluate typed Lean declarations into source IR values
- enforce naming/binding/type constraints
2. Typed MIR boundary (shared internal form)
- generic types and effects explicit
- no backend-specific artifacts in core MIR
3. Optimization boundary
- all optimizations are MIR-to-MIR or Sierra-to-Sierra with explicit laws
4. Backend boundary A (Sierra)
- deterministic VersionedProgram generation
- explicit resource threading where required
5. Backend boundary B (Cairo)
- deterministic Cairo source emission from MIR

## Required IR Stack

1. Source IR (high-level typed expression language)
2. Core MIR (backend-neutral typed functional core)
3. Effect MIR (explicit state/resource/effect annotations)
4. Sierra MIR (typed linear form suitable for direct Sierra emission)

## Why This Stack

1. Prevents IR -> DSL -> IR round-trips.
2. Enables optimizer reuse across both backends.
3. Keeps proof obligations local and compositional.

## Determinism Requirements

1. Stable symbol/hash assignment across runs.
2. Stable statement ordering and declaration ordering.
3. Stable generated file layout and formatting.

## Error Contract Requirements

1. Unsupported constructs must fail before emission.
2. Error messages must identify:
- function name
- expression family
- missing semantic model or unsupported resource model
3. Errors are treated as compatibility surface and tested.

## End-State Components

1. `LeanCairo.Compiler.IR`:
- fully generic type/effect IR
2. `LeanCairo.Compiler.Optimize`:
- verified pass framework with pass contracts
3. `LeanCairo.Backend.Sierra`:
- complete function-level Sierra emitter
4. `LeanCairo.Backend.Cairo`:
- complete function-level Cairo emitter
5. `LeanCairo.Compiler.Proof`:
- compositional semantics-preserving proofs

