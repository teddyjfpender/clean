import LeanCairo.Backend.Cairo.EmitExpr
import LeanCairo.Backend.Cairo.Naming
import LeanCairo.Backend.Cairo.Pretty
import LeanCairo.Core.Spec.FuncSpec

namespace LeanCairo.Backend.Cairo

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec

private def renderParam (param : Param) : String :=
  toCairoLocalName param.name ++ ": " ++ Ty.toCairo param.ty

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
  let body := indentLines (indentDepth + 1) <| emitExpr fnSpec.body
  let footer := indent indentDepth ++ "}"
  String.intercalate "\n" [header, body, footer]

end LeanCairo.Backend.Cairo
