import LeanCairo.Core.Domain.Mutability
import LeanCairo.Core.Domain.Ty

namespace LeanCairo.Core.Validation

open LeanCairo.Core.Domain

inductive ValidationError where
  | invalidIdentifier (scope : String) (name : String)
  | duplicateFunctionName (name : String)
  | duplicateArgumentName (functionName : String) (argumentName : String)
  | duplicateLetBinding (name : String)
  | unboundVariable (name : String)
  | variableTypeMismatch (name : String) (expected : Ty) (actual : Ty)
  | unsupportedMutability (functionName : String) (mutability : Mutability)
  | emptyFunctionList (contractName : String)
  deriving Repr, DecidableEq

namespace ValidationError

def render : ValidationError -> String
  | .invalidIdentifier scope name =>
      s!"invalid identifier '{name}' in {scope}; only [A-Za-z_][A-Za-z0-9_]* is allowed"
  | .duplicateFunctionName name =>
      s!"duplicate function name '{name}'"
  | .duplicateArgumentName fnName argName =>
      s!"duplicate argument name '{argName}' in function '{fnName}'"
  | .duplicateLetBinding name =>
      s!"duplicate let-binding name '{name}' in lexical scope"
  | .unboundVariable name =>
      s!"unbound variable '{name}'"
  | .variableTypeMismatch name expected actual =>
      s!"variable '{name}' used with type '{Ty.toCairo expected}' but binding has type '{Ty.toCairo actual}'"
  | .unsupportedMutability fnName mutability =>
      s!"function '{fnName}' uses unsupported MVP mutability '{reprStr mutability}'"
  | .emptyFunctionList contractName =>
      s!"contract '{contractName}' has no functions"

def renderMany (errors : List ValidationError) : String :=
  String.intercalate "\n" <| errors.map (fun err => s!"- {render err}")

end ValidationError
end LeanCairo.Core.Validation
