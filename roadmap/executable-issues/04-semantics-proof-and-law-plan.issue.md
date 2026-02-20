# Executable Issue: `roadmap/04-semantics-proof-and-law-plan.md`

- Source roadmap file: [`roadmap/04-semantics-proof-and-law-plan.md`](../04-semantics-proof-and-law-plan.md)
- Issue class: Formal semantics and proof closure
- Priority: P0
- Overall status: DONE - 6647c8f
- Completion evidence tests: `scripts/test/semantic_state_regression.sh`; `scripts/roadmap/check_proof_obligations.sh`; `scripts/test/proof_obligations_negative.sh`
- Completion evidence proofs: `src/LeanCairo/Compiler/Semantics/Eval.lean`; `src/LeanCairo/Compiler/Proof/TranslationRelation.lean`

## Objective

Establish compositional semantics and proof obligations for source/MIR/target translations and optimization passes.

## Implementation loci

1. `src/LeanCairo/Compiler/Semantics/*.lean`
2. `src/LeanCairo/Compiler/Proof/*.lean`
3. `src/LeanCairo/Compiler/Optimize/Pass.lean`
4. `scripts/roadmap/check_proof_obligations.sh` (new)

## Formal method requirements

1. Every pass declares pre/postconditions and preserved invariants.
2. Translation relations are explicit and reusable.
3. No unsupported theorem placeholders in completed milestones.

## Milestones

### M-04-1: Resource-aware state semantics
- Status: DONE - 6647c8f
- Evidence tests: `scripts/test/semantic_state_regression.sh`; `scripts/test/effect_resource_regression.sh`
- Evidence proofs: `src/LeanCairo/Compiler/Semantics/Eval.lean`
- Required work:
1. Define canonical semantic state including values, resources, and failure channel.
2. Refactor evaluators to use this state.
- Acceptance tests:
1. Semantic tests for success/failure/resource transitions pass.
2. State model is used by evaluator and theorem statements consistently.

### M-04-2: Translation relation library
- Status: DONE - 6647c8f
- Evidence tests: `scripts/roadmap/check_proof_obligations.sh`; `scripts/workflow/run-sierra-checks.sh`
- Evidence proofs: `src/LeanCairo/Compiler/Proof/TranslationRelation.lean`; `src/LeanCairo/Compiler/IR/Lowering.lean`
- Required work:
1. Implement source->MIR and MIR->target relation definitions.
2. Reuse relations in lowering correctness theorems.
- Acceptance tests:
1. Theorems compile for all enabled families.
2. No duplicated ad-hoc relation definitions in proof modules.

### M-04-3: Proof CI gating
- Status: DONE - 6647c8f
- Evidence tests: `scripts/roadmap/check_proof_obligations.sh`; `scripts/test/proof_obligations_negative.sh`; `scripts/workflow/run-mvp-checks.sh`
- Evidence proofs: `src/LeanCairo/Compiler/Proof/OptimizeSound.lean`; `src/LeanCairo/Compiler/Proof/CSELetNormSound.lean`
- Required work:
1. Add CI script verifying proof stubs/theorems for new passes and families.
2. Fail CI on missing obligations.
- Acceptance tests:
1. `scripts/roadmap/check_proof_obligations.sh` passes on compliant tree.
2. Simulated missing theorem causes CI failure.

## Completion criteria

1. Semantic model is unified across runtime and proofs.
2. Pass and lowering correctness obligations are enforced by CI.
3. Proof coverage grows with feature coverage and is auditable.
