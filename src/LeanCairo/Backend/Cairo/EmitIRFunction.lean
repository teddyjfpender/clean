import LeanCairo.Backend.Cairo.EmitIRExpr
import LeanCairo.Backend.Cairo.Naming
import LeanCairo.Backend.Cairo.Pretty
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

private def renderTempBinding (name : String) (ty : Ty) (valueExpr : String) : String :=
  "let " ++ name ++ ": " ++ Ty.toCairo ty ++ " = " ++ valueExpr ++ ";"

private def writeValueTempName (index : Nat) : String :=
  s!"__leancairo_write_{index}"

private def returnValueTempName : String :=
  "__leancairo_return_value"

private def enumerateWrites (writes : List IRStorageWrite) : List (Nat × IRStorageWrite) :=
  (List.range writes.length).zip writes

def emitIRTraitFunctionSignature (fnSpec : IRFuncSpec) : String :=
  let functionName := toCairoFunctionName fnSpec.name
  let selfParam := Mutability.toInterfaceSelf fnSpec.mutability
  let params := selfParam :: fnSpec.args.map renderParam
  "fn "
    ++ functionName
    ++ "("
    ++ String.intercalate ", " params
    ++ ") -> "
    ++ Ty.toCairo fnSpec.ret
    ++ ";"

def emitIRImplFunction (indentDepth : Nat) (fnSpec : IRFuncSpec) : String :=
  let functionName := toCairoFunctionName fnSpec.name
  let selfParam := Mutability.toImplSelf fnSpec.mutability
  let params := selfParam :: fnSpec.args.map renderParam
  let header :=
    indent indentDepth
      ++ "fn "
      ++ functionName
      ++ "("
      ++ String.intercalate ", " params
      ++ ") -> "
      ++ Ty.toCairo fnSpec.ret
      ++ " {"
  let bodyLines :=
    if fnSpec.writes.isEmpty then
      [indentLines (indentDepth + 1) (emitIRExpr fnSpec.body)]
    else
      let indexedWrites := enumerateWrites fnSpec.writes
      let writeValueBindings :=
        indexedWrites.map (fun (index, writeSpec) =>
          indent (indentDepth + 1)
            ++ renderTempBinding
                (writeValueTempName index)
                writeSpec.ty
                (emitIRExpr writeSpec.value))
      let returnValueBinding :=
        indent (indentDepth + 1)
          ++ renderTempBinding returnValueTempName fnSpec.ret (emitIRExpr fnSpec.body)
      let writeLines :=
        indexedWrites.map (fun (index, writeSpec) =>
          indent (indentDepth + 1)
            ++ renderStorageWriteStatementFromLocal writeSpec (writeValueTempName index))
      writeValueBindings ++ [returnValueBinding] ++ writeLines ++ [indent (indentDepth + 1) ++ returnValueTempName]
  let body := String.intercalate "\n" bodyLines
  let footer := indent indentDepth ++ "}"
  String.intercalate "\n" [header, body, footer]

end LeanCairo.Backend.Cairo
