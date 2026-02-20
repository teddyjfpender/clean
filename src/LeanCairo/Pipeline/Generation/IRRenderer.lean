import LeanCairo.Backend.Cairo.EmitIRContract
import LeanCairo.Backend.Cairo.Naming
import LeanCairo.Backend.Scarb.ArtifactHelper
import LeanCairo.Backend.Scarb.Manifest
import LeanCairo.Compiler.IR.Spec
import LeanCairo.Pipeline.Generation.BuildPlan
import LeanCairo.Pipeline.Generation.InliningStrategy

namespace LeanCairo.Pipeline.Generation

open LeanCairo.Backend.Cairo
open LeanCairo.Backend.Scarb
open LeanCairo.Compiler.IR

private def boolString (value : Bool) : String :=
  if value then "true" else "false"

private def renderReadme (spec : IRContractSpec) (emitCasm : Bool) : String :=
  let packageName := toScarbPackageName spec.contractName
  String.intercalate "\n"
    [
      "# Generated Starknet Contract",
      "",
      s!"Contract: `{spec.contractName}`",
      s!"Package: `{packageName}`",
      s!"CASM enabled: `{boolString emitCasm}`",
      "",
      "## Build",
      "",
      "```bash",
      "scarb build",
      "```",
      "",
      "## Locate artifacts",
      "",
      "```bash",
      "python3 scripts/find_contract_artifact.py --index target/dev/*.starknet_artifacts.json",
      "```",
      ""
    ]

def renderProjectFromIR (spec : IRContractSpec) (emitCasm : Bool) (inliningStrategy : InliningStrategy) : GeneratedProject :=
  {
    scarbToml := renderScarbManifestForPackageName (toScarbPackageName spec.contractName) emitCasm inliningStrategy
    cairoLib := renderIRContract spec ++ "\n"
    readme := renderReadme spec emitCasm
    artifactHelperScript := artifactLocatorScript
  }

end LeanCairo.Pipeline.Generation
