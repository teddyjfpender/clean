# Executable Issue: `roadmap/inventory/sierra-extensions-inventory.md`

- Source roadmap file: [`roadmap/inventory/sierra-extensions-inventory.md`](../../inventory/sierra-extensions-inventory.md)
- Issue class: Primary-track family inventory integrity
- Priority: P0
- Overall status: DONE - cf583c8
- Completion evidence tests: `scripts/test/sierra_surface_codegen.sh`; `scripts/roadmap/check_inventory_freshness.sh`; `scripts/roadmap/check_coverage_matrix_freshness.sh`; `scripts/roadmap/check_sierra_coverage_report_freshness.sh`; `scripts/test/sierra_primary_closure_negative.sh`; `scripts/workflow/run-sierra-checks.sh`; `scripts/workflow/run-mvp-checks.sh`
- Completion evidence proofs: `roadmap/inventory/sierra-extensions-inventory.md`; `roadmap/inventory/sierra-coverage-matrix.json`; `roadmap/inventory/sierra-family-coverage-report.md`; `scripts/roadmap/render_sierra_coverage_report.py`; `scripts/roadmap/check_sierra_primary_closure.sh`

## Objective

Use the Sierra module inventory as the authoritative closure set for Lean -> Sierra function-family support tracking.

## Implementation loci

1. `scripts/sierra/generate_surface_bindings.py`
2. `generated/sierra/surface/pinned_surface.json`
3. `scripts/roadmap/generate_inventory_docs.py`
4. `roadmap/inventory/sierra-extensions-inventory.md`
5. `scripts/roadmap/render_sierra_coverage_report.py` (new)

## Formal method requirements

1. Coverage percentages must be computed from generated inventory and machine-readable implementation map.
2. Family status transitions must require acceptance test pass records.

## Milestones

### I-SIERRA-1 Inventory exactness and freshness
- Status: DONE - cf583c8
- Acceptance tests:
1. `./scripts/test/sierra_surface_codegen.sh` passes.
2. Regenerated inventory matches committed snapshot.

### I-SIERRA-2 Family coverage report
- Status: DONE - cf583c8
- Acceptance tests:
1. Report includes all 62 extension module files and extracted ID counts.
2. Each family has status and evidence references.

### I-SIERRA-3 Closure gate
- Status: DONE - cf583c8
- Acceptance tests:
1. Primary closure checker fails until all targeted non-Starknet families are complete.
2. Checker passes only when all required families are `DONE - <commit>` with evidence.

## Completion criteria

1. Sierra inventory and coverage are fully automated.
2. Family closure claims are machine-verifiable.
