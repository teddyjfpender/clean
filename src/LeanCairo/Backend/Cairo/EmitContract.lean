import LeanCairo.Backend.Cairo.EmitFunction
import LeanCairo.Backend.Cairo.Naming
import LeanCairo.Backend.Cairo.Pretty
import LeanCairo.Core.Spec.ContractSpec

namespace LeanCairo.Backend.Cairo

open LeanCairo.Core.Spec

private def interfaceName (contractName : String) : String :=
  "I" ++ toCairoContractName contractName

private def implName (contractName : String) : String :=
  toCairoContractName contractName ++ "Impl"

private def emitInterface (spec : ContractSpec) : String :=
  let traitName := interfaceName spec.contractName
  let fnLines := spec.functions.map (fun fnSpec => indent 1 ++ emitTraitFunctionSignature fnSpec)
  String.intercalate "\n"
    ([
      "#[starknet::interface]",
      "pub trait " ++ traitName ++ "<TContractState> {"
    ] ++ fnLines ++ ["}"])

private def emitContractModule (spec : ContractSpec) : String :=
  let moduleName := toCairoContractName spec.contractName
  let traitName := interfaceName spec.contractName
  let generatedImplName := implName spec.contractName
  let implFunctions := spec.functions.map (emitImplFunction 2)
  String.intercalate "\n"
    ([
      "#[starknet::contract]",
      "mod " ++ moduleName ++ " {",
      "    #[storage]",
      "    struct Storage {}",
      "",
      "    #[abi(embed_v0)]",
      "    impl " ++ generatedImplName ++ " of super::" ++ traitName ++ "<ContractState> {"
    ] ++
      (if implFunctions.isEmpty then [] else [String.intercalate "\n\n" implFunctions]) ++
      [
        "    }",
        "}"
      ])

def renderContract (spec : ContractSpec) : String :=
  String.intercalate "\n\n" [emitInterface spec, emitContractModule spec]

end LeanCairo.Backend.Cairo
