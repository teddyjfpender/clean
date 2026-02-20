# Executable Issue: `roadmap/inventory/corelib-src-inventory.md`

- Source roadmap file: [`roadmap/inventory/corelib-src-inventory.md`](../../inventory/corelib-src-inventory.md)
- Issue class: Corelib inventory integrity
- Priority: P1
- Overall status: DONE - 7a6a63c
- Completion evidence tests: `scripts/roadmap/check_inventory_freshness.sh`; `scripts/roadmap/check_corelib_parity_freshness.sh`; `scripts/roadmap/check_pin_consistency.sh`; `scripts/workflow/run-sierra-checks.sh`; `scripts/workflow/run-mvp-checks.sh`
- Completion evidence proofs: `roadmap/inventory/corelib-src-inventory.md`; `roadmap/inventory/corelib-parity-report.json`; `roadmap/inventory/corelib-parity-report.md`; `scripts/roadmap/render_corelib_parity_report.py`

## Objective

Use pinned `corelib/src` inventory as a measurable parity target for secondary Lean -> Cairo track and a function-domain coverage reference.

## Implementation loci

1. `scripts/roadmap/generate_inventory_docs.py`
2. `roadmap/inventory/corelib-src-inventory.md`
3. `scripts/roadmap/render_corelib_parity_report.py` (new)

## Formal method requirements

1. Inventory count and file list must exactly match pinned upstream tree.
2. Parity classification must be generated from code mapping, not manual notes.

## Milestones

### I-CORE-1 Inventory exactness
- Status: DONE - 7a6a63c
- Acceptance tests:
1. Regenerated list matches committed list exactly.
2. Upstream pin mismatch triggers deterministic diff.

### I-CORE-2 Parity classification
- Status: DONE - 7a6a63c
- Acceptance tests:
1. Every corelib file has a status: `supported`, `partial`, or `excluded`.
2. Report generation is deterministic and CI-gated.

## Completion criteria

1. Corelib inventory is stable and exact.
2. Parity report is complete and reproducible.
