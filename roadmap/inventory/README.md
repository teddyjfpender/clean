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
- `capability-coverage-report.json`
- `capability-coverage-report.md`
- `capability-obligation-report.json`
- `capability-obligation-report.md`

## Capability Coverage Generator

Run:

```bash
python3 scripts/roadmap/project_capability_reports.py \
  --registry roadmap/capabilities/registry.json \
  --out-json roadmap/inventory/capability-coverage-report.json \
  --out-md roadmap/inventory/capability-coverage-report.md
```

Capability closure SLO gate:

```bash
scripts/roadmap/check_capability_closure_slo.sh
```

## Capability Obligation Generator

Run:

```bash
python3 scripts/roadmap/project_capability_obligations.py \
  --registry roadmap/capabilities/registry.json \
  --obligations roadmap/capabilities/obligations.json \
  --out-json roadmap/inventory/capability-obligation-report.json \
  --out-md roadmap/inventory/capability-obligation-report.md
```

Capability obligation gate:

```bash
scripts/roadmap/check_capability_obligations.sh
```
