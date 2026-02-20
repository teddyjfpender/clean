# Inventory Docs

These files are generated snapshots of pinned upstream Cairo surfaces used by the roadmap.

## Generator

Run:

```bash
python3 scripts/roadmap/generate_inventory_docs.py
```

To refresh the pinned upstream tree cache:

```bash
python3 scripts/roadmap/generate_inventory_docs.py --refresh-tree-cache
```

Prerequisite:

1. `generated/sierra/surface/pinned_surface.json` must exist and match the pinned commit.
2. `roadmap/inventory/pinned-tree-paths.json` must exist and match the pinned commit (or regenerate it with `--refresh-tree-cache`).

## Files

- `corelib-src-inventory.md`
- `corelib-parity-report.json`
- `corelib-parity-report.md`
- `sierra-extensions-inventory.md`
- `compiler-crates-inventory.md`
- `compiler-crates-dependency-matrix.md`
- `pinned-tree-paths.json`
- `sierra-coverage-matrix.json`
- `sierra-coverage-summary.md`
- `sierra-family-coverage-report.json`
- `sierra-family-coverage-report.md`
