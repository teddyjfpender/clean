# Full Support Roadmap

This roadmap is the execution plan for complete language and runtime support with two tracks:

1. Primary: Lean -> Sierra -> CASM (function-first).
2. Secondary: Lean -> Cairo (human-facing source backend, parity target).

This plan treats `spec.md` and `spec2.md` as canonical constraints and assumes pinned upstream Cairo commit:

- `e56055c87a9db4e3dbb91c82ccb2ea751a8dc617`

## Scope Priority

1. Functions first, contracts second.
2. Lean -> Sierra correctness and performance first.
3. Lean -> Cairo parity and readability second.

## Roadmap Documents

- [`roadmap/00-charter-and-completion-definition.md`](00-charter-and-completion-definition.md): final success criteria and hard requirements.
- [`roadmap/01-canonical-upstream-surfaces.md`](01-canonical-upstream-surfaces.md): pinned upstream sources and extraction rules.
- [`roadmap/02-target-compiler-architecture.md`](02-target-compiler-architecture.md): end-state architecture and boundaries.
- [`roadmap/03-typed-ir-generalization-plan.md`](03-typed-ir-generalization-plan.md): generic typed IR required for full coverage.
- [`roadmap/04-semantics-proof-and-law-plan.md`](04-semantics-proof-and-law-plan.md): formal semantics and proof obligations.
- [`roadmap/05-track-a-lean-to-sierra-functions.md`](05-track-a-lean-to-sierra-functions.md): primary function compilation roadmap.
- [`roadmap/06-track-b-lean-to-cairo-functions.md`](06-track-b-lean-to-cairo-functions.md): secondary Cairo backend roadmap.
- [`roadmap/07-low-level-optimization-sierra-casm.md`](07-low-level-optimization-sierra-casm.md): optimization plan at IR/Sierra/CASM levels.
- [`roadmap/08-quality-gates-bench-and-release.md`](08-quality-gates-bench-and-release.md): deterministic gates and release criteria.
- [`roadmap/09-milestones-and-execution-order.md`](09-milestones-and-execution-order.md): phased delivery order.
- [`roadmap/10-risk-register-and-mitigations.md`](10-risk-register-and-mitigations.md): risk control plan.
- [`roadmap/11-evaluator-type-domain-separation.md`](11-evaluator-type-domain-separation.md): typed evaluator domains, fail-fast semantics, and proof closure for non-interference.
- [`roadmap/12-direct-sierra-subset-coverage-ledger.md`](12-direct-sierra-subset-coverage-ledger.md): strict completed/pending subset ledger for the direct Sierra emitter lane.
- [`roadmap/13-function-subset-expansion-engine.md`](13-function-subset-expansion-engine.md): capability-driven engine for rapid, formally constrained subset growth.
- [`roadmap/14-complex-function-corpus-and-benchmarking-lab.md`](14-complex-function-corpus-and-benchmarking-lab.md): manifest-driven complex corpus generation and benchmark scaling.
- [`roadmap/15-proof-obligation-and-gate-scaling.md`](15-proof-obligation-and-gate-scaling.md): automated proof/gate governance for large capability growth.
- [`roadmap/16-capability-registry-schema-and-projection-system.md`](16-capability-registry-schema-and-projection-system.md): canonical capability schema and projection system for support-state governance.
- [`roadmap/17-type-system-and-semantics-closure-program.md`](17-type-system-and-semantics-closure-program.md): full type-family semantic closure program.
- [`roadmap/18-effects-control-flow-and-resource-semantics.md`](18-effects-control-flow-and-resource-semantics.md): effect/control/resource semantics closure for complex kernels.
- [`roadmap/19-track-a-sierra-family-closure-execution-plan.md`](19-track-a-sierra-family-closure-execution-plan.md): strict Track-A family closure execution plan.
- [`roadmap/20-track-b-cairo-parity-and-reviewability-plan.md`](20-track-b-cairo-parity-and-reviewability-plan.md): strict Track-B parity and reviewability plan.
- [`roadmap/21-function-corpus-and-baseline-expansion-program.md`](21-function-corpus-and-baseline-expansion-program.md): complex corpus and baseline expansion program.
- [`roadmap/22-benchmarking-cost-model-and-profiling-governance.md`](22-benchmarking-cost-model-and-profiling-governance.md): benchmarking/profiling governance and cost-model calibration plan.
- [`roadmap/23-verified-optimizing-compiler-escalation-plan.md`](23-verified-optimizing-compiler-escalation-plan.md): escalation path to verified optimizing compiler behavior.
- [`roadmap/24-ci-gate-orchestration-and-release-automation.md`](24-ci-gate-orchestration-and-release-automation.md): CI gate orchestration and release automation scaling.
- [`roadmap/25-full-function-compiler-completion-matrix.md`](25-full-function-compiler-completion-matrix.md): final completion matrix and certification program.
- [`roadmap/inventory/corelib-src-inventory.md`](inventory/corelib-src-inventory.md): pinned corelib source inventory.
- [`roadmap/inventory/sierra-extensions-inventory.md`](inventory/sierra-extensions-inventory.md): pinned Sierra module inventory.
- [`roadmap/inventory/compiler-crates-inventory.md`](inventory/compiler-crates-inventory.md): pinned compiler crate focus inventory.

## Executable Tracking

- [`roadmap/executable-issues/INDEX.md`](executable-issues/INDEX.md): strict one-to-one mapping of roadmap files to executable issue files.
- Issue files live under [`roadmap/executable-issues`](executable-issues) and use status values:
1. `NOT DONE`
2. `DONE - <commit>`

## Non-Negotiables

1. No handwritten one-off type/libfunc lists as source of truth.
2. No silent fallback lowering for unsupported semantics.
3. No optimization claim without benchmark evidence.
4. No pass integration without explicit semantic preservation obligations.

## Current Baseline (as of 2026-02-20)

1. Direct Sierra subset lane exists and is validated end-to-end.
2. Supported direct Sierra subset and pending closure items are tracked in:
- [`roadmap/12-direct-sierra-subset-coverage-ledger.md`](12-direct-sierra-subset-coverage-ledger.md)
3. Explicit fail-fast exists for unsupported families such as range-checked integer arithmetic and `u256` lowering.
