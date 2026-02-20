import LeanCairo.Backend.Cairo.EmitContract
import LeanCairo.Backend.Cairo.Naming
import LeanCairo.Backend.Scarb.ArtifactHelper
import LeanCairo.Backend.Scarb.Manifest
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Pipeline.Generation.BuildPlan

namespace LeanCairo.Pipeline.Generation

open LeanCairo.Backend.Cairo
open LeanCairo.Backend.Scarb
open LeanCairo.Core.Spec

private def boolString (value : Bool) : String :=
  if value then "true" else "false"

private def renderReadme (spec : ContractSpec) (emitCasm : Bool) : String :=
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

def renderProject (spec : ContractSpec) (emitCasm : Bool) : GeneratedProject :=
  {
    scarbToml := renderScarbManifest spec emitCasm
    cairoLib := renderContract spec ++ "\n"
    readme := renderReadme spec emitCasm
    artifactHelperScript := artifactLocatorScript
  }

end LeanCairo.Pipeline.Generation
