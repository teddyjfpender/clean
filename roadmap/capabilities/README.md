# Capability Registry

This directory contains the canonical capability registry for function-domain compiler support.

Authoritative files:

1. `schema.md`: structural and semantic constraints.
2. `registry.json`: capability entries and support status.
3. `capability-closure-slo-baseline.json`: monotonic implemented-capability SLO minimums.
4. `mir-family-contract.json`: MIR node coverage and fail-fast contract references.

Derived artifacts (generated):

1. `roadmap/inventory/capability-coverage-report.json`
2. `roadmap/inventory/capability-coverage-report.md`
3. `src/LeanCairo/Backend/Sierra/Generated/CapabilityProjection.lean`

Validation and projection commands:

```bash
python3 scripts/roadmap/validate_capability_registry.py --registry roadmap/capabilities/registry.json
python3 scripts/roadmap/project_capability_reports.py \
  --registry roadmap/capabilities/registry.json \
  --out-json roadmap/inventory/capability-coverage-report.json \
  --out-md roadmap/inventory/capability-coverage-report.md
python3 scripts/roadmap/generate_capability_projection_lean.py \
  --registry roadmap/capabilities/registry.json \
  --out src/LeanCairo/Backend/Sierra/Generated/CapabilityProjection.lean
scripts/roadmap/check_capability_closure_slo.sh
python3 scripts/roadmap/validate_mir_family_contract.py \
  --contract roadmap/capabilities/mir-family-contract.json \
  --ir-expr src/LeanCairo/Compiler/IR/Expr.lean \
  --eval src/LeanCairo/Compiler/Semantics/Eval.lean \
  --optimize src/LeanCairo/Compiler/Optimize/Expr.lean
```
