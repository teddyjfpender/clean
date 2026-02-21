# Generated Sierra Program (Subset Backend)

Contract source: `SQ128x128U128Contract`
Optimizer enabled: `true`

## Outputs

- `sierra/program.sierra.json`: Versioned Sierra program JSON

## Validate / Compile

```bash
cargo run --manifest-path tools/sierra_toolchain/Cargo.toml -- validate --input sierra/program.sierra.json
cargo run --manifest-path tools/sierra_toolchain/Cargo.toml -- compile --input sierra/program.sierra.json --out-casm sierra/program.casm
```
