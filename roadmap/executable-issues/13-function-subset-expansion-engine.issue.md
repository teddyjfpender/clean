# Executable Issue: `roadmap/13-function-subset-expansion-engine.md`

- Source roadmap file: [`roadmap/13-function-subset-expansion-engine.md`](../13-function-subset-expansion-engine.md)
- Issue class: Capability-driven expansion infrastructure
- Priority: P0
- Overall status: NOT DONE

## Objective

Implement the capability-driven expansion engine that systematizes function-family growth for both Lean -> Sierra and Lean -> Cairo backends.

## Implementation loci

1. `roadmap/13-function-subset-expansion-engine.md`
2. `roadmap/inventory/sierra-coverage-matrix.json`
3. `roadmap/inventory/corelib-parity-report.json`
4. `src/LeanCairo/Core/Domain/**`
5. `src/LeanCairo/Compiler/IR/**`
6. `src/LeanCairo/Backend/Sierra/**`
7. `src/LeanCairo/Backend/Cairo/**`
8. `scripts/roadmap/**`
9. `scripts/test/**`

## Formal method requirements

1. Capability metadata is authoritative and machine-validated.
2. Implemented capability status requires explicit semantics/lowering/proof/test links.
3. Unsupported capabilities remain fail-fast until obligations are satisfied.
4. Backend support matrices are projections, not handwritten duplicated lists.

## Milestone status ledger

### SXP-1 Capability registry schema and validators
- Status: DONE - ff05fdf
- Evidence tests: `python3 scripts/roadmap/validate_capability_registry.py --registry roadmap/capabilities/registry.json`; `scripts/test/capability_registry_negative.sh`; `scripts/roadmap/check_capability_registry.sh`
- Evidence proofs: `roadmap/capabilities/schema.md`; `roadmap/capabilities/registry.json`; `scripts/roadmap/validate_capability_registry.py`
- Acceptance tests:
1. Registry schema validator rejects malformed capability records.
2. Registry-to-report projection scripts are deterministic.
3. Drift between registry and projected reports fails CI.

### SXP-2 MIR family expansion contracts
- Status: DONE - cdd0bdd
- Evidence tests: `scripts/roadmap/check_mir_family_contract.sh`; `scripts/test/mir_family_contract_negative.sh`; `scripts/test/eval_unsupported_domain_failfast.sh`; `scripts/test/optimizer_pass_regression.sh`; `scripts/test/sierra_failfast_unsupported.sh`
- Evidence proofs: `roadmap/capabilities/mir-family-contract.json`; `scripts/roadmap/validate_mir_family_contract.py`; `src/LeanCairo/Compiler/IR/Expr.lean`; `src/LeanCairo/Compiler/Semantics/Eval.lean`; `src/LeanCairo/Compiler/Optimize/Expr.lean`; `scripts/roadmap/list_quality_gates.sh`
- Acceptance tests:
1. Expanded MIR family nodes compile and satisfy type/effect invariants.
2. Missing capability handlers fail fast with stable error messages.
3. Evaluator and optimizer recognize expanded MIR families without unsound fallback.

### SXP-3 Generated lowering scaffold pipeline
- Status: NOT DONE
- Acceptance tests:
1. Sierra and Cairo lowering scaffold generation is reproducible.
2. Non-implemented capabilities generate fail-fast stubs.
3. Manual edits in generated regions are detected and rejected.

### SXP-4 Cross-backend capability parity projection
- Status: NOT DONE
- Acceptance tests:
1. Capability report includes Sierra state and Cairo state per capability ID.
2. Unsupported divergence requires explicit documented constraint.
3. Capability closure metrics are monotonic under successful feature merges.

## Global strict acceptance tests

1. `scripts/roadmap/check_inventory_reproducibility.sh`
2. `scripts/roadmap/check_inventory_freshness.sh`
3. `scripts/roadmap/check_sierra_coverage_report_freshness.sh`
4. `scripts/roadmap/check_corelib_parity_freshness.sh`
5. `scripts/test/sierra_failfast_unsupported.sh`

## Completion criteria

1. SXP-1 through SXP-4 are `DONE - <commit>`.
2. Capability metadata is the unique support source of truth.
3. Both backends consume generated capability projections with fail-fast guarantees.
