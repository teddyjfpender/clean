Short answer: go straight Lean -> Sierra for the optimizing compiler path, and keep Lean -> Cairo as a secondary review/debug backend.

  Why this is the better fit for your goal:

  1. cairo-lang-sierra is already the canonical typed IR surface (program structure, ids, specialization, validation), so targeting it avoids
     frontend duplication.
      - Program / artifact model: https://raw.githubusercontent.com/starkware-libs/cairo/e56055c87a9db4e3dbb91c82ccb2ea751a8dc617/crates/cairo-lang-
        sierra/src/program.rs
      - Registry/validation layer: https://raw.githubusercontent.com/starkware-libs/cairo/e56055c87a9db4e3dbb91c82ccb2ea751a8dc617/crates/cairo-lang-
        sierra/src/program_registry.rs
  2. The Sierra core surface is large and explicit (many modules/libfunc families), and it is already organized for specialization by IDs/signatures.
      - Core type/libfunc hierarchy: https://raw.githubusercontent.com/starkware-libs/cairo/e56055c87a9db4e3dbb91c82ccb2ea751a8dc617/crates/cairo-
        lang-sierra/src/extensions/core.rs
      - Hierarchy macros (good codegen anchor): https://raw.githubusercontent.com/starkware-libs/cairo/e56055c87a9db4e3dbb91c82ccb2ea751a8dc617/
        crates/cairo-lang-sierra/src/extensions/lib_func.rs
      - Type hierarchy macro: https://raw.githubusercontent.com/starkware-libs/cairo/e56055c87a9db4e3dbb91c82ccb2ea751a8dc617/crates/cairo-lang-
        sierra/src/extensions/types.rs
  3. “Add all Cairo types” in Lean->Cairo means re-implementing huge corelib/frontend behavior, then still relying on Cairo lowering to Sierra. That
     is slower and less controllable for optimization goals.
      - Corelib scope: https://github.com/starkware-libs/cairo/tree/e56055c87a9db4e3dbb91c82ccb2ea751a8dc617/corelib/src
      - Example breadth (integer.cairo, circuit.cairo):
        https://raw.githubusercontent.com/starkware-libs/cairo/e56055c87a9db4e3dbb91c82ccb2ea751a8dc617/corelib/src/integer.cairo
        https://raw.githubusercontent.com/starkware-libs/cairo/e56055c87a9db4e3dbb91c82ccb2ea751a8dc617/corelib/src/circuit.cairo
  4. The downstream toolchain is already Sierra-native (gas, ap-change, CASM compilation).
      - Sierra -> CASM: https://raw.githubusercontent.com/starkware-libs/cairo/e56055c87a9db4e3dbb91c82ccb2ea751a8dc617/crates/cairo-lang-sierra-to-
        casm/src/compiler.rs
      - Gas/AP change:
        https://raw.githubusercontent.com/starkware-libs/cairo/e56055c87a9db4e3dbb91c82ccb2ea751a8dc617/crates/cairo-lang-sierra-gas/src/lib.rs
        https://raw.githubusercontent.com/starkware-libs/cairo/e56055c87a9db4e3dbb91c82ccb2ea751a8dc617/crates/cairo-lang-sierra-ap-change/src/lib.rs

  What to do (not handwritten):

  1. Auto-generate Lean Sierra schema/bindings from pinned cairo-lang-sierra sources (extensions/core.rs + extensions/modules/* + ids/signatures).
  2. Emit Sierra Program directly from Lean IR.
  3. Validate against ProgramRegistry at the same pinned commit.
  4. Compile to CASM with official Sierra crates.
  5. Keep optional Cairo output only for human review, not as the primary lowering path.

  Inference: for your stated objective (“maximize on-chain efficiency and optimize Sierra/CASM directly”), this architecture is the highest-leverage
  path.