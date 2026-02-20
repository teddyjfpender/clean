# Compiler Crate Dependency Matrix (Pinned)

- Commit: `e56055c87a9db4e3dbb91c82ccb2ea751a8dc617`
- Source inventory: `roadmap/inventory/compiler-crates-inventory.md`
- Tooling manifest: `tools/sierra_toolchain/Cargo.toml`
- Required focused crates: `3`
- Optional focused crates: `16`

## Classification Rules

1. A focused crate is `required` iff it is a direct `cairo-lang-*` dependency in `tools/sierra_toolchain/Cargo.toml`.
2. All other focused crates are `optional` context references for roadmap alignment.

## Matrix

| Crate | File count | Requirement | Role |
| --- | ---: | --- | --- |
| `cairo-lang-compiler` | `7` | `optional` | optional context |
| `cairo-lang-parser` | `84` | `optional` | optional context |
| `cairo-lang-syntax` | `21` | `optional` | optional context |
| `cairo-lang-defs` | `11` | `optional` | optional context |
| `cairo-lang-semantic` | `160` | `optional` | optional context |
| `cairo-lang-lowering` | `155` | `optional` | optional context |
| `cairo-lang-sierra-generator` | `84` | `optional` | optional context |
| `cairo-lang-sierra` | `97` | `required` | authoritative semantic reference |
| `cairo-lang-sierra-gas` | `14` | `optional` | optional context |
| `cairo-lang-sierra-ap-change` | `6` | `optional` | optional context |
| `cairo-lang-sierra-type-size` | `2` | `required` | implementation reference |
| `cairo-lang-sierra-to-casm` | `61` | `required` | implementation reference |
| `cairo-lang-casm` | `19` | `optional` | optional context |
| `cairo-lang-runner` | `17` | `optional` | optional context |
| `cairo-lang-starknet` | `185` | `optional` | optional context |
| `cairo-lang-test-plugin` | `6` | `optional` | optional context |
| `cairo-lang-utils` | `28` | `optional` | optional context |
| `cairo-lang-filesystem` | `13` | `optional` | optional context |
| `cairo-lang-diagnostics` | `5` | `optional` | optional context |
