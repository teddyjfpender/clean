import LeanCairo.Backend.Cairo.Ast
import LeanCairo.Backend.Cairo.EmitIRExpr
import LeanCairo.Backend.Cairo.Naming
import LeanCairo.Compiler.IR.Spec
import LeanCairo.Core.Spec.FuncSpec

namespace LeanCairo.Backend.Cairo

open LeanCairo.Compiler.IR
open LeanCairo.Core.Domain
open LeanCairo.Core.Spec

private def renderParam (param : Param) : String :=
  toCairoLocalName param.name ++ ": " ++ Ty.toCairo param.ty

private def renderStorageWriteStatementFromLocal (writeSpec : IRStorageWrite) (localName : String) : String :=
  "self."
    ++ toCairoStorageFieldName writeSpec.field
    ++ ".write("
    ++ localName
    ++ ");"

private def writeValueTempName (index : Nat) : String :=
  s!"__leancairo_internal_write_{index}"

private def returnValueTempName : String :=
  "__leancairo_internal_return_value"

private def enumerateWrites (writes : List IRStorageWrite) : List (Nat × IRStorageWrite) :=
  (List.range writes.length).zip writes

def emitIRTraitFunctionSignature (fnSpec : IRFuncSpec) : String :=
  let functionName := toCairoFunctionName fnSpec.name
  let selfParam := Mutability.toInterfaceSelf fnSpec.mutability
  let signature : CairoFunctionSignature :=
    {
      name := functionName
      params := selfParam :: fnSpec.args.map renderParam
      ret := Ty.toCairo fnSpec.ret
    }
  renderFunctionSignature signature ++ ";"

def emitIRImplFunctionAst (fnSpec : IRFuncSpec) : CairoFunction :=
  let functionName := toCairoFunctionName fnSpec.name
  let selfParam := Mutability.toImplSelf fnSpec.mutability
  let signature : CairoFunctionSignature :=
    {
      name := functionName
      params := selfParam :: fnSpec.args.map renderParam
      ret := Ty.toCairo fnSpec.ret
    }
  let bodyStmts :=
    if fnSpec.writes.isEmpty then
      [CairoStmt.expr (emitIRExpr fnSpec.body)]
    else
      let indexedWrites := enumerateWrites fnSpec.writes
      let writeValueBindings :=
        indexedWrites.map (fun (index, writeSpec) =>
          CairoStmt.letDecl
            (writeValueTempName index)
            (Ty.toCairo writeSpec.ty)
            (emitIRExpr writeSpec.value))
      let returnValueBinding :=
        CairoStmt.letDecl returnValueTempName (Ty.toCairo fnSpec.ret) (emitIRExpr fnSpec.body)
      let writeLines :=
        indexedWrites.map (fun (index, writeSpec) =>
          CairoStmt.expr (renderStorageWriteStatementFromLocal writeSpec (writeValueTempName index)))
      writeValueBindings ++ [returnValueBinding] ++ writeLines ++ [CairoStmt.expr returnValueTempName]
  {
    signature := signature
    body := bodyStmts
  }

def emitIRImplFunction (indentDepth : Nat) (fnSpec : IRFuncSpec) : String :=
  renderFunctionAt indentDepth (emitIRImplFunctionAst fnSpec)

end LeanCairo.Backend.Cairo
