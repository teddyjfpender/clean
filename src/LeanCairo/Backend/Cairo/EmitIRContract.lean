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

private def appendTyIfMissing (tys : List Ty) (ty : Ty) : List Ty :=
  if tys.contains ty then tys else tys ++ [ty]

private partial def collectExprTypes (expr : IRExpr ty) (acc : List Ty) : List Ty :=
  match expr with
  | .var _ => acc
  | .storageRead _ => acc
  | .litU128 _ => appendTyIfMissing acc .u128
  | .litU256 _ => appendTyIfMissing acc .u256
  | .litBool _ => appendTyIfMissing acc .bool
  | .litFelt252 _ => appendTyIfMissing acc .felt252
  | .addFelt252 lhs rhs
  | .subFelt252 lhs rhs
  | .mulFelt252 lhs rhs =>
      collectExprTypes rhs (collectExprTypes lhs (appendTyIfMissing acc .felt252))
  | .addU128 lhs rhs
  | .subU128 lhs rhs
  | .mulU128 lhs rhs =>
      collectExprTypes rhs (collectExprTypes lhs (appendTyIfMissing acc .u128))
  | .addU256 lhs rhs
  | .subU256 lhs rhs
  | .mulU256 lhs rhs =>
      collectExprTypes rhs (collectExprTypes lhs (appendTyIfMissing acc .u256))
  | .eq lhs rhs =>
      collectExprTypes rhs (collectExprTypes lhs (appendTyIfMissing acc .bool))
  | .ltU128 lhs rhs
  | .leU128 lhs rhs =>
      collectExprTypes rhs (collectExprTypes lhs (appendTyIfMissing acc .bool))
  | .ltU256 lhs rhs
  | .leU256 lhs rhs =>
      collectExprTypes rhs (collectExprTypes lhs (appendTyIfMissing acc .bool))
  | .ite cond thenBranch elseBranch =>
      collectExprTypes elseBranch (collectExprTypes thenBranch (collectExprTypes cond acc))
  | .letE _ boundTy bound body =>
      collectExprTypes body (collectExprTypes bound (appendTyIfMissing acc boundTy))

private def collectAllTypes (spec : IRContractSpec) : List Ty :=
  spec.functions.foldl
    (fun acc fnSpec =>
      let withArgs := fnSpec.args.foldl (fun accInner arg => appendTyIfMissing accInner arg.ty) acc
      let withRet := appendTyIfMissing withArgs fnSpec.ret
      let withWrites :=
        fnSpec.writes.foldl (fun accWrite writeSpec => appendTyIfMissing accWrite writeSpec.ty) withRet
      let withBody := collectExprTypes fnSpec.body withWrites
      fnSpec.writes.foldl (fun accWriteExpr writeSpec => collectExprTypes writeSpec.value accWriteExpr) withBody)
    []

private def customTypeStubLines (ty : Ty) : List String :=
  match ty with
  | .tuple arity =>
      [
        "#[derive(Copy, Drop, Serde)]",
        "struct " ++ Ty.toCairo (.tuple arity) ++ " {}"
      ]
  | .structTy name =>
      [
        "#[derive(Copy, Drop, Serde)]",
        "struct " ++ name ++ " {}"
      ]
  | .enumTy name =>
      [
        "#[derive(Copy, Drop, Serde)]",
        "enum " ++ name ++ " {",
        "    Variant0: (),",
        "    Variant1: (),",
        "}"
      ]
  | _ => []

private def customTypeName? (ty : Ty) : Option String :=
  match ty with
  | .tuple arity => some (Ty.toCairo (.tuple arity))
  | .structTy name => some name
  | .enumTy name => some name
  | _ => none

private def collectCustomTypeNames (spec : IRContractSpec) : List String :=
  (collectAllTypes spec).foldl
    (fun acc ty =>
      match customTypeName? ty with
      | some name =>
          if acc.contains name then acc else acc ++ [name]
      | none => acc)
    []

private def collectCustomTypeStubs (spec : IRContractSpec) : List String :=
  let allTypes := collectAllTypes spec
  let customTypes := allTypes.filter (fun ty =>
    match ty with
    | .tuple _ | .structTy _ | .enumTy _ => true
    | _ => false)
  let blocks := customTypes.map customTypeStubLines |>.filter (fun lines => !lines.isEmpty)
  blocks.map (String.intercalate "\n")

private partial def exprUsesStorageRead : IRExpr ty -> Bool
  | .var _ => false
  | .storageRead _ => true
  | .litU128 _ => false
  | .litU256 _ => false
  | .litBool _ => false
  | .litFelt252 _ => false
  | .addFelt252 lhs rhs => exprUsesStorageRead lhs || exprUsesStorageRead rhs
  | .subFelt252 lhs rhs => exprUsesStorageRead lhs || exprUsesStorageRead rhs
  | .mulFelt252 lhs rhs => exprUsesStorageRead lhs || exprUsesStorageRead rhs
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

private def emitCustomTypeImports (spec : IRContractSpec) : List String :=
  let customTypeNames := collectCustomTypeNames spec
  if customTypeNames.isEmpty then
    []
  else
    ["    use super::{" ++ String.intercalate ", " customTypeNames ++ "};", ""]

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
      emitCustomTypeImports spec ++
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
  let customTypeBlocks := collectCustomTypeStubs spec
  String.intercalate "\n\n" (customTypeBlocks ++ [emitInterface spec, emitContractModule spec])

end LeanCairo.Backend.Cairo
