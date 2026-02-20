import LeanCairo.Backend.Cairo.EmitIRFunction
import LeanCairo.Backend.Cairo.Naming
import LeanCairo.Backend.Cairo.Pretty
import LeanCairo.Compiler.IR.Spec
import LeanCairo.Compiler.IR.Expr

namespace LeanCairo.Backend.Cairo

open LeanCairo.Compiler.IR
open LeanCairo.Core.Domain

private def interfaceName (contractName : String) : String :=
  "I" ++ toCairoContractName contractName

private def implName (contractName : String) : String :=
  toCairoContractName contractName ++ "Impl"

private def emitInterface (spec : IRContractSpec) : String :=
  let traitName := interfaceName spec.contractName
  let fnLines := spec.functions.map (fun fnSpec => indent 1 ++ emitIRTraitFunctionSignature fnSpec)
  String.intercalate "\n"
    ([
      "#[starknet::interface]",
      "pub trait " ++ traitName ++ "<TContractState> {"
    ] ++ fnLines ++ ["}"])

private def emitStorageStructLines (spec : IRContractSpec) : List String :=
  if spec.storage.isEmpty then
    [
      "    #[storage]",
      "    struct Storage {}"
    ]
  else
    [
      "    #[storage]",
      "    struct Storage {"
    ] ++
      spec.storage.map
        (fun field =>
          "        "
            ++ toCairoStorageFieldName field.name
            ++ ": "
            ++ Ty.toCairo field.ty
            ++ ",") ++
      ["    }"]

private partial def exprUsesStorageRead : IRExpr ty -> Bool
  | .var _ => false
  | .storageRead _ => true
  | .litU128 _ => false
  | .litU256 _ => false
  | .litBool _ => false
  | .litFelt252 _ => false
  | .addU128 lhs rhs => exprUsesStorageRead lhs || exprUsesStorageRead rhs
  | .subU128 lhs rhs => exprUsesStorageRead lhs || exprUsesStorageRead rhs
  | .mulU128 lhs rhs => exprUsesStorageRead lhs || exprUsesStorageRead rhs
  | .addU256 lhs rhs => exprUsesStorageRead lhs || exprUsesStorageRead rhs
  | .subU256 lhs rhs => exprUsesStorageRead lhs || exprUsesStorageRead rhs
  | .mulU256 lhs rhs => exprUsesStorageRead lhs || exprUsesStorageRead rhs
  | .eq lhs rhs => exprUsesStorageRead lhs || exprUsesStorageRead rhs
  | .ltU128 lhs rhs => exprUsesStorageRead lhs || exprUsesStorageRead rhs
  | .leU128 lhs rhs => exprUsesStorageRead lhs || exprUsesStorageRead rhs
  | .ltU256 lhs rhs => exprUsesStorageRead lhs || exprUsesStorageRead rhs
  | .leU256 lhs rhs => exprUsesStorageRead lhs || exprUsesStorageRead rhs
  | .ite cond thenBranch elseBranch =>
      exprUsesStorageRead cond || exprUsesStorageRead thenBranch || exprUsesStorageRead elseBranch
  | .letE _ _ bound body => exprUsesStorageRead bound || exprUsesStorageRead body

private def functionNeedsReadTrait (fnSpec : IRFuncSpec) : Bool :=
  exprUsesStorageRead fnSpec.body ||
    fnSpec.writes.any (fun writeSpec => exprUsesStorageRead writeSpec.value)

private def functionNeedsWriteTrait (fnSpec : IRFuncSpec) : Bool :=
  !fnSpec.writes.isEmpty

private def emitStorageTraitImports (spec : IRContractSpec) : List String :=
  let needsRead := spec.functions.any functionNeedsReadTrait
  let needsWrite := spec.functions.any functionNeedsWriteTrait
  let imports :=
    (if needsRead then ["StoragePointerReadAccess"] else []) ++
      (if needsWrite then ["StoragePointerWriteAccess"] else [])
  if imports.isEmpty then
    []
  else
    ["    use starknet::storage::{" ++ String.intercalate ", " imports ++ "};", ""]

private def emitContractModule (spec : IRContractSpec) : String :=
  let moduleName := toCairoContractName spec.contractName
  let traitName := interfaceName spec.contractName
  let generatedImplName := implName spec.contractName
  let implFunctions := spec.functions.map (emitIRImplFunction 2)
  String.intercalate "\n"
    ([
      "#[starknet::contract]",
      "mod " ++ moduleName ++ " {"
    ] ++
      emitStorageTraitImports spec ++
      emitStorageStructLines spec ++
      [
        "",
        "    #[abi(embed_v0)]",
        "    impl " ++ generatedImplName ++ " of super::" ++ traitName ++ "<ContractState> {"
      ] ++
      (if implFunctions.isEmpty then [] else [String.intercalate "\n\n" implFunctions]) ++
      [
        "    }",
        "}"
      ])

def renderIRContract (spec : IRContractSpec) : String :=
  String.intercalate "\n\n" [emitInterface spec, emitContractModule spec]

end LeanCairo.Backend.Cairo
