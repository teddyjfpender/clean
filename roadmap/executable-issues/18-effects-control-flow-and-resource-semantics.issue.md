# Executable Issue: `roadmap/18-effects-control-flow-and-resource-semantics.md`

- Source roadmap file: [`roadmap/18-effects-control-flow-and-resource-semantics.md`](../18-effects-control-flow-and-resource-semantics.md)
- Issue class: Effect and control/resource semantics closure
- Priority: P0
- Overall status: NOT DONE

## Objective

Close effect/resource-aware control-flow semantics in MIR and lowering pipelines to safely support complex high-step function kernels.

## Implementation loci

1. `src/LeanCairo/Compiler/IR/**`
2. `src/LeanCairo/Compiler/Semantics/**`
3. `src/LeanCairo/Compiler/Optimize/**`
4. `src/LeanCairo/Compiler/Proof/**`
5. `src/LeanCairo/Backend/Sierra/**`
6. `src/LeanCairo/Backend/Cairo/**`
7. `roadmap/18-effects-control-flow-and-resource-semantics.md`

## Formal method requirements

1. Effect metadata is explicit and validated.
2. Control-flow normalization preserves semantics.
3. Resource-sensitive legality checks gate optimizations.
4. Panic/failure channels are explicit and test-covered.

## Milestone status ledger

### EFF-1 Effect algebra and metadata schema
- Status: NOT DONE
- Acceptance tests:
1. Missing effect metadata fails validation.
2. Illegal effect class combinations are rejected.
3. Effect-isolation checks pass.

### EFF-2 Control-flow MIR normalization closure
- Status: NOT DONE
- Acceptance tests:
1. Structured branch/join normalization tests pass.
2. Loop/call control tests pass with deterministic outputs.
3. Differential control-flow suites pass.

### EFF-3 Call, recursion, and panic channel semantics
- Status: NOT DONE
- Acceptance tests:
1. Call/recursion fixtures pass semantics and lowering checks.
2. Panic/failure propagation tests pass.
3. Unsupported call modes fail fast.

### EFF-4 Resource legality and optimization-side-condition gates
- Status: NOT DONE
- Acceptance tests:
1. Gas/AP/resource legality checks block unsafe transforms.
2. Negative legality tests pass.
3. Resource-sensitive benchmark suites are non-regressive.

## Global strict acceptance tests

1. `scripts/test/effect_resource_regression.sh`
2. `scripts/test/semantic_state_regression.sh`
3. `scripts/roadmap/check_effect_isolation.sh`
4. `scripts/test/proof_obligations_negative.sh`

## Completion criteria

1. EFF-1 through EFF-4 are `DONE - <commit>`.
2. Effect/control/resource semantics are explicit and enforceable.
3. Complex control-flow support is legal, tested, and auditable.
