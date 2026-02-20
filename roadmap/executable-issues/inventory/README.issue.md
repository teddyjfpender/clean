# Executable Issue: `roadmap/inventory/README.md`

- Source roadmap file: [`roadmap/inventory/README.md`](../../inventory/README.md)
- Issue class: Inventory generation contract
- Priority: P1
- Overall status: DONE - f1f87d6
- Completion evidence tests: `scripts/roadmap/check_inventory_reproducibility.sh`; `scripts/roadmap/check_inventory_freshness.sh`; `scripts/workflow/run-sierra-checks.sh`; `scripts/workflow/run-mvp-checks.sh`
- Completion evidence proofs: `scripts/roadmap/generate_inventory_docs.py`; `roadmap/inventory/README.md`; `roadmap/inventory/corelib-src-inventory.md`; `roadmap/inventory/sierra-extensions-inventory.md`; `roadmap/inventory/compiler-crates-inventory.md`

## Objective

Keep roadmap inventory documents generated and reproducible, never manually edited as authoritative state.

## Implementation loci

1. `scripts/roadmap/generate_inventory_docs.py`
2. `roadmap/inventory/*.md`
3. `scripts/roadmap/check_inventory_freshness.sh` (new)

## Formal method requirements

1. Generator input sources are pinned and explicit.
2. Output ordering is deterministic.
3. Freshness check is CI-enforced.

## Milestones

### I-README-1 Generator reproducibility
- Status: DONE - f1f87d6
- Acceptance tests:
1. Two consecutive runs produce byte-identical outputs.
2. Generator exits non-zero on missing prerequisites.

### I-README-2 Freshness gate
- Status: DONE - f1f87d6
- Acceptance tests:
1. `scripts/roadmap/check_inventory_freshness.sh` passes only when inventories are up to date.
2. Manual inventory drift is detected.

## Completion criteria

1. Inventory generation and freshness checks are automated and gated.
2. Inventory docs remain strictly derived artifacts.
