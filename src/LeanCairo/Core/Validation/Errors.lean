import LeanCairo.Core.Domain.Ty

namespace LeanCairo.Core.Validation

open LeanCairo.Core.Domain

inductive ValidationError where
  | invalidIdentifier (scope : String) (name : String)
  | duplicateFunctionName (name : String)
  | duplicateArgumentName (functionName : String) (argumentName : String)
  | duplicateStorageFieldName (fieldName : String)
  | duplicateLetBinding (name : String)
  | unboundVariable (name : String)
  | variableTypeMismatch (name : String) (expected : Ty) (actual : Ty)
  | unknownStorageField (fieldName : String)
  | storageFieldTypeMismatch (fieldName : String) (expected : Ty) (actual : Ty)
  | duplicateStorageWriteField (functionName : String) (fieldName : String)
  | writesNotAllowedInViewFunction (functionName : String)
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
  | .duplicateStorageFieldName fieldName =>
      s!"duplicate storage field name '{fieldName}'"
  | .duplicateLetBinding name =>
      s!"duplicate let-binding name '{name}' in lexical scope"
  | .unboundVariable name =>
      s!"unbound variable '{name}'"
  | .variableTypeMismatch name expected actual =>
      s!"variable '{name}' used with type '{Ty.toCairo expected}' but binding has type '{Ty.toCairo actual}'"
  | .unknownStorageField fieldName =>
      s!"unknown storage field '{fieldName}'"
  | .storageFieldTypeMismatch fieldName expected actual =>
      s!"storage field '{fieldName}' used with type '{Ty.toCairo expected}' but declaration has type '{Ty.toCairo actual}'"
  | .duplicateStorageWriteField fnName fieldName =>
      s!"function '{fnName}' declares multiple writes to storage field '{fieldName}'"
  | .writesNotAllowedInViewFunction fnName =>
      s!"function '{fnName}' is view but declares storage writes"
  | .emptyFunctionList contractName =>
      s!"contract '{contractName}' has no functions"

def renderMany (errors : List ValidationError) : String :=
  String.intercalate "\n" <| errors.map (fun err => s!"- {render err}")

end ValidationError
end LeanCairo.Core.Validation
