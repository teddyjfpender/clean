import LeanCairo.Backend.Cairo.Naming
import LeanCairo.Core.Spec.ContractSpec

namespace LeanCairo.Backend.Scarb

open LeanCairo.Backend.Cairo
open LeanCairo.Core.Spec

private def boolToml (value : Bool) : String :=
  if value then "true" else "false"

def renderScarbManifest (spec : ContractSpec) (emitCasm : Bool) : String :=
  let packageName := toScarbPackageName spec.contractName
  String.intercalate "\n"
    [
      "[package]",
      s!"name = \"{packageName}\"",
      "version = \"0.1.0\"",
      "edition = \"2024_07\"",
      "",
      "[dependencies]",
      "starknet = \">=2.14.0\"",
      "",
      "[[target.starknet-contract]]",
      "sierra = true",
      s!"casm = {boolToml emitCasm}",
      ""
    ]

end LeanCairo.Backend.Scarb
