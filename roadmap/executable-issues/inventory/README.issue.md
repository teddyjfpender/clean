# Executable Issue: `roadmap/inventory/README.md`

- Source roadmap file: [`roadmap/inventory/README.md`](../../inventory/README.md)
- Issue class: Inventory generation contract
- Priority: P1
- Overall status: NOT DONE

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
- Status: NOT DONE
- Acceptance tests:
1. Two consecutive runs produce byte-identical outputs.
2. Generator exits non-zero on missing prerequisites.

### I-README-2 Freshness gate
- Status: NOT DONE
- Acceptance tests:
1. `scripts/roadmap/check_inventory_freshness.sh` passes only when inventories are up to date.
2. Manual inventory drift is detected.

## Completion criteria

1. Inventory generation and freshness checks are automated and gated.
2. Inventory docs remain strictly derived artifacts.

