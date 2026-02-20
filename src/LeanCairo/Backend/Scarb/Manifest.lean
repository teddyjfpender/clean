import LeanCairo.Backend.Cairo.Naming
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Pipeline.Generation.InliningStrategy

namespace LeanCairo.Backend.Scarb

open LeanCairo.Backend.Cairo
open LeanCairo.Core.Spec
open LeanCairo.Pipeline.Generation

private def boolToml (value : Bool) : String :=
  if value then "true" else "false"

private def renderScarbManifestWithPackageName
    (packageName : String)
    (emitCasm : Bool)
    (inliningStrategy : InliningStrategy) : String :=
  let strategyToml := InliningStrategy.toTomlLiteral inliningStrategy
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
      "",
      "[profile.dev.cairo]",
      s!"inlining-strategy = {strategyToml}",
      "",
      "[profile.release.cairo]",
      s!"inlining-strategy = {strategyToml}",
      ""
    ]

def renderScarbManifestForPackageName
    (packageName : String)
    (emitCasm : Bool)
    (inliningStrategy : InliningStrategy) : String :=
  renderScarbManifestWithPackageName packageName emitCasm inliningStrategy

def renderScarbManifest (spec : ContractSpec) (emitCasm : Bool) (inliningStrategy : InliningStrategy) : String :=
  renderScarbManifestWithPackageName (toScarbPackageName spec.contractName) emitCasm inliningStrategy

end LeanCairo.Backend.Scarb
