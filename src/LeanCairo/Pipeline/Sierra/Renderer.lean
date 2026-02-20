import LeanCairo.Backend.Sierra.Emit.SubsetProgram
import LeanCairo.Compiler.IR.Spec
import LeanCairo.Pipeline.Sierra.BuildPlan

namespace LeanCairo.Pipeline.Sierra

open LeanCairo.Compiler.IR
open LeanCairo.Backend.Sierra.Emit

private def boolString (value : Bool) : String :=
  if value then "true" else "false"

private def renderReadme (spec : IRContractSpec) (optimized : Bool) : String :=
  String.intercalate "\n"
    [
      "# Generated Sierra Program (Subset Backend)",
      "",
      s!"Contract source: `{spec.contractName}`",
      s!"Optimizer enabled: `{boolString optimized}`",
      "",
      "## Outputs",
      "",
      "- `sierra/program.sierra.json`: Versioned Sierra program JSON",
      "",
      "## Validate / Compile",
      "",
      "```bash",
      "cargo run --manifest-path tools/sierra_toolchain/Cargo.toml -- validate --input sierra/program.sierra.json",
      "cargo run --manifest-path tools/sierra_toolchain/Cargo.toml -- compile --input sierra/program.sierra.json --out-casm sierra/program.casm",
      "```",
      ""
    ]

def renderSierraProjectFromIR
    (spec : IRContractSpec)
    (optimized : Bool) : Except String GeneratedSierraProject := do
  let programJson <- renderSubsetProgramJson spec
  pure
    {
      programJson := programJson ++ "\n"
      readme := renderReadme spec optimized
    }

end LeanCairo.Pipeline.Sierra
