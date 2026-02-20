import LeanCairo.Core.Spec.FuncSpec
import LeanCairo.Core.Validation.Context
import LeanCairo.Core.Validation.Errors
import LeanCairo.Core.Validation.Expr
import LeanCairo.Core.Validation.Utils

namespace LeanCairo.Core.Validation

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec

private def argEnv (args : List Param) : TypeEnv :=
  args.map (fun arg => (arg.name, arg.ty))

private def validateArgumentNames (fnName : String) (args : List Param) : List ValidationError :=
  let invalidNameErrors :=
    args.foldl
      (fun errors arg =>
        if isValidIdentifier arg.name then
          errors
        else
          errors ++ [.invalidIdentifier s!"function '{fnName}' argument" arg.name])
      []
  let duplicateErrors :=
    (duplicateNames <| args.map (fun arg => arg.name)).map (fun dup =>
      ValidationError.duplicateArgumentName fnName dup)
  invalidNameErrors ++ duplicateErrors

def validateFunction (fnSpec : FuncSpec) : List ValidationError :=
  let nameErrors :=
    if isValidIdentifier fnSpec.name then
      []
    else
      [.invalidIdentifier "function name" fnSpec.name]
  let mutabilityErrors :=
    match fnSpec.mutability with
    | .view => []
    | other => [.unsupportedMutability fnSpec.name other]
  let argErrors := validateArgumentNames fnSpec.name fnSpec.args
  let bodyErrors := validateExpr (argEnv fnSpec.args) fnSpec.body
  nameErrors ++ mutabilityErrors ++ argErrors ++ bodyErrors

end LeanCairo.Core.Validation
