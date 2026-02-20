# Executable Issue: `roadmap/01-canonical-upstream-surfaces.md`

- Source roadmap file: [`roadmap/01-canonical-upstream-surfaces.md`](../01-canonical-upstream-surfaces.md)
- Issue class: Source-of-truth and pin discipline
- Priority: P0
- Overall status: NOT DONE

## Objective

Guarantee all coverage and compatibility claims are derived from pinned upstream inventories and generated bindings.

## Implementation loci

1. `scripts/sierra/generate_surface_bindings.py`
2. `scripts/roadmap/generate_inventory_docs.py`
3. `generated/sierra/surface/pinned_surface.json`
4. `src/LeanCairo/Backend/Sierra/Generated/Surface.lean`
5. `roadmap/inventory/*.md`
6. `scripts/test/sierra_surface_codegen.sh`

## Formal method requirements

1. Inventory generation must be deterministic (sorted inputs and outputs).
2. Commit pin must be a single source of truth across generators.
3. Compatibility reports must reference generated data only.

## Milestones

### M-01-1: Unified pin configuration
- Status: DONE - 3c0770a
- Required work:
1. Centralize pin in one config file consumed by all generators.
2. Detect mismatched pins across artifacts.
- Acceptance tests:
1. `scripts/roadmap/check_pin_consistency.sh` exits `0` only when all pin references match.
2. Artificial pin mismatch is detected and fails.

### M-01-2: Inventory drift gate
- Status: DONE - 569a0bf
- Required work:
1. Add snapshot gate for all `roadmap/inventory/*.md` files.
2. Add CI target that regenerates and diffs inventories.
- Acceptance tests:
1. `python3 scripts/roadmap/generate_inventory_docs.py && git diff --exit-code roadmap/inventory` passes when up to date.
2. Manual edit to inventory file causes gate failure.

### M-01-3: Coverage matrix bootstrap
- Status: NOT DONE
- Required work:
1. Generate machine-readable coverage matrix from inventory + implementation map.
2. Publish unresolved IDs/families with explicit statuses.
- Acceptance tests:
1. `scripts/roadmap/render_coverage_matrix.py` generates deterministic output.
2. Matrix counts match pinned inventory counts exactly.

## Completion criteria

1. All source surfaces are generated, pinned, and drift-gated.
2. Coverage reporting is inventory-derived and reproducible.
3. No handwritten ID list is treated as authoritative.
