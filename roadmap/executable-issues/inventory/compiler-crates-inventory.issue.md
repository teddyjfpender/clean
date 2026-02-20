# Executable Issue: `roadmap/inventory/compiler-crates-inventory.md`

- Source roadmap file: [`roadmap/inventory/compiler-crates-inventory.md`](../../inventory/compiler-crates-inventory.md)
- Issue class: Upstream crate dependency map
- Priority: P1
- Overall status: NOT DONE

## Objective

Track and constrain which upstream Cairo compiler crates are depended on for semantics, lowering, validation, and optimization alignment.

## Implementation loci

1. `roadmap/inventory/compiler-crates-inventory.md`
2. `scripts/roadmap/generate_inventory_docs.py`
3. `scripts/roadmap/render_crate_dependency_matrix.py` (new)
4. `tools/sierra_toolchain/Cargo.toml`

## Formal method requirements

1. Every focused crate must be classified as:
- authoritative semantic reference
- implementation reference
- optional context
2. Tooling dependencies must remain pinned and auditable.

## Milestones

### I-CRATES-1 Dependency matrix
- Status: NOT DONE
- Acceptance tests:
1. Matrix is generated and includes all focused crates.
2. Matrix differentiates required vs optional references.

### I-CRATES-2 Pin and drift checks
- Status: NOT DONE
- Acceptance tests:
1. Crate version drift in tooling dependencies is detected.
2. Pin mismatch blocks release-candidate checks.

## Completion criteria

1. Focus crate usage is explicit and reviewed.
2. Dependency drift is controlled by executable checks.

