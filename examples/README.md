# Examples Mirror

This directory is the canonical examples workspace for formal end-to-end checks.

1. `examples/Lean/<example-id>/`:
   canonical Lean source of truth.
2. `examples/Sierra/<example-id>/`:
   generated Sierra artifacts.
3. `examples/Cairo/<example-id>/`:
   generated Cairo project artifacts.

Rules:
1. Example source belongs in `examples/Lean/`, not `src/`.
2. Every `<example-id>` must exist in all three roots with the same name.
3. `examples/Sierra/` and `examples/Cairo/` are generated outputs.

## Regenerate

```bash
./scripts/examples/generate_examples.sh
```

The generator uses formal CLI commands from this repository:

1. `lake exe leancairo-sierra-gen --module <module> --out examples/Sierra/<id> --optimize true`
2. `lake exe leancairo-gen --module <module> --out examples/Cairo/<id> --emit-casm false --optimize true`

`<module>` values are declared in `config/examples-manifest.json` and map to Lean modules under `examples/Lean/`.

## Validate Structure

```bash
./scripts/test/examples_structure.sh
```

## Add A New Example

1. Add Lean source under `examples/Lean/<new-id>/`.
2. Add a module entrypoint file under `examples/Lean/<new-id>.lean`.
3. Register the example in `config/examples-manifest.json`.
4. Run:
   ```bash
   ./scripts/examples/generate_examples.sh
   ./scripts/test/examples_structure.sh
   ```
