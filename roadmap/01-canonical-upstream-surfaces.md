# 01. Canonical Upstream Surfaces

## Pin Policy

All roadmap work uses this fixed upstream commit:

- `e56055c87a9db4e3dbb91c82ccb2ea751a8dc617`

Any pin change is a controlled migration with full regeneration of inventories, snapshots, and compatibility reports.

## Canonical Source Surfaces

1. Corelib source surface (Lean -> Cairo parity target):
- `https://github.com/starkware-libs/cairo/tree/e56055c87a9db4e3dbb91c82ccb2ea751a8dc617/corelib/src`
2. Sierra language model (Lean -> Sierra primary target):
- `https://github.com/starkware-libs/cairo/tree/e56055c87a9db4e3dbb91c82ccb2ea751a8dc617/crates/cairo-lang-sierra`
3. Sierra program model and validation:
- `crates/cairo-lang-sierra/src/program.rs`
- `crates/cairo-lang-sierra/src/program_registry.rs`
4. Sierra core type/libfunc hierarchy:
- `crates/cairo-lang-sierra/src/extensions/core.rs`
- `crates/cairo-lang-sierra/src/extensions/lib_func.rs`
- `crates/cairo-lang-sierra/src/extensions/types.rs`
- `crates/cairo-lang-sierra/src/ids.rs`
5. Sierra -> CASM backend and metadata:
- `crates/cairo-lang-sierra-to-casm`
- `crates/cairo-lang-sierra-gas`
- `crates/cairo-lang-sierra-ap-change`
- `crates/cairo-lang-sierra-type-size`

## Inventory Artifacts In This Repository

1. `generated/sierra/surface/pinned_surface.json`
- extracted generic IDs from pinned Sierra sources
- current counts: `68` generic types, `279` generic libfunc IDs
2. `src/LeanCairo/Backend/Sierra/Generated/Surface.lean`
- generated Lean bindings from pinned sources
3. Roadmap appendices:
- [`roadmap/inventory/corelib-src-inventory.md`](inventory/corelib-src-inventory.md)
- [`roadmap/inventory/sierra-extensions-inventory.md`](inventory/sierra-extensions-inventory.md)
- [`roadmap/inventory/compiler-crates-inventory.md`](inventory/compiler-crates-inventory.md)

## Source-Of-Truth Rules

1. Upstream inventories are generated, not handwritten.
2. Coverage matrices are derived from generated inventories plus implementation status.
3. Any missing upstream ID/file in generated inventory is a generator defect and blocks release.

## Required Automation

1. Regenerate Sierra surface bindings as part of quality checks.
2. Regenerate roadmap inventory docs when pin changes.
3. Fail CI if generated inventories differ from committed snapshots.

## Drift Detection

A pin migration is complete only when all pass:

1. inventory regeneration clean
2. lowering coverage report regenerated
3. proof/test suite green
4. performance baseline refreshed

