# Artifact Optimization Lane (IR-Native + CASM Metrics)

Date: 2026-02-20
Status: Implemented (phase 1)

## Objective

Increase real on-chain efficiency by optimizing and measuring at the compilation artifact boundary
(Sierra/CASM), while keeping a human-reviewable Cairo view.

## Implemented architecture

1. Lean source is lowered to a typed IR contract model.
2. IR-to-IR optimization rewrites expressions.
3. Cairo is emitted directly from IR (no `IR -> DSL` round-trip in generation).
4. Scarb compiles to Sierra and optional CASM.
5. Benchmark gates compare optimized vs baseline using artifact metrics.
6. Post-build artifact passes run under semantic-signature guards before acceptance.

## Inputs / outputs

- Inputs:
  - `ContractSpec` from Lean module.
  - Compiler tuning flags (`--optimize`, `--inlining-strategy`, `--emit-casm`).
- Outputs:
  - Generated Cairo project.
  - Sierra/CASM artifacts from Scarb.
  - Benchmark metrics (`score`, `sierra_program_len`, `casm_bytecode_len`, hint count).
  - Review bundle (`expanded.cairo`, metrics JSON).

## Invariants

- IR optimizer does not mutate contract signatures or mutability.
- Mutable entrypoint semantics are snapshot-based at evaluation time: return/write RHS are computed in pre-state then writes commit.
- Benchmark gate rejects performance regressions under selected scoring model.
- Generation remains deterministic for a fixed input + options tuple.
- Artifact passes must preserve hashes of critical semantic fields:
  - Sierra program
  - Sierra entry points
  - ABI
  - CASM bytecode + entry points (if CASM present)

## Known limits

- No custom post-compilation mutation pass over Sierra/CASM yet.
- No semantics-preserving proof for future Sierra/CASM rewrites yet.
- Scoring is still proxy-based; it is not a full execution-cost oracle.
