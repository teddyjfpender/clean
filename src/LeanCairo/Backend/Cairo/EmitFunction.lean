import LeanCairo.Backend.Cairo.EmitExpr
import LeanCairo.Backend.Cairo.Naming
import LeanCairo.Backend.Cairo.Pretty
import LeanCairo.Core.Spec.FuncSpec

namespace LeanCairo.Backend.Cairo

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec

private def renderParam (param : Param) : String :=
  toCairoLocalName param.name ++ ": " ++ Ty.toCairo param.ty

private def renderStorageWriteStatement (writeSpec : StorageWrite) : String :=
  "self."
    ++ toCairoStorageFieldName writeSpec.field
    ++ ".write("
    ++ emitExpr writeSpec.value
    ++ ");"

def emitTraitFunctionSignature (fnSpec : FuncSpec) : String :=
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

def emitImplFunction (indentDepth : Nat) (fnSpec : FuncSpec) : String :=
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
  let writeLines :=
    fnSpec.writes.map (fun writeSpec =>
      indent (indentDepth + 1) ++ renderStorageWriteStatement writeSpec)
  let returnExprLines := indentLines (indentDepth + 1) (emitExpr fnSpec.body)
  let body := String.intercalate "\n" <| writeLines ++ [returnExprLines]
  let footer := indent indentDepth ++ "}"
  String.intercalate "\n" [header, body, footer]

end LeanCairo.Backend.Cairo
