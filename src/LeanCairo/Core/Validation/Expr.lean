import LeanCairo.Core.Domain.Identifier
import LeanCairo.Core.Syntax.Expr
import LeanCairo.Core.Validation.Context
import LeanCairo.Core.Validation.Errors

namespace LeanCairo.Core.Validation

open LeanCairo.Core.Domain
open LeanCairo.Core.Syntax

partial def validateExpr (env : TypeEnv) : Expr ty -> List ValidationError
  | @Expr.var expectedTy name =>
      match lookupType env name with
      | none => [.unboundVariable name]
      | some actualTy =>
          if actualTy == expectedTy then
            []
          else
            [.variableTypeMismatch name expectedTy actualTy]
  | .litU128 _ => []
  | .litU256 _ => []
  | .litBool _ => []
  | .litFelt252 _ => []
  | .addU128 lhs rhs => validateExpr env lhs ++ validateExpr env rhs
  | .subU128 lhs rhs => validateExpr env lhs ++ validateExpr env rhs
  | .mulU128 lhs rhs => validateExpr env lhs ++ validateExpr env rhs
  | .addU256 lhs rhs => validateExpr env lhs ++ validateExpr env rhs
  | .subU256 lhs rhs => validateExpr env lhs ++ validateExpr env rhs
  | .mulU256 lhs rhs => validateExpr env lhs ++ validateExpr env rhs
  | .eq lhs rhs => validateExpr env lhs ++ validateExpr env rhs
  | .ltU128 lhs rhs => validateExpr env lhs ++ validateExpr env rhs
  | .leU128 lhs rhs => validateExpr env lhs ++ validateExpr env rhs
  | .ltU256 lhs rhs => validateExpr env lhs ++ validateExpr env rhs
  | .leU256 lhs rhs => validateExpr env lhs ++ validateExpr env rhs
  | .ite cond thenBranch elseBranch =>
      validateExpr env cond ++ validateExpr env thenBranch ++ validateExpr env elseBranch
  | .letE name boundTy bound body =>
      let idErrors :=
        if isValidIdentifier name then
          []
        else
          [.invalidIdentifier "let binding" name]
      let bindingErrors := validateExpr env bound
      let duplicateErrors :=
        if hasBinding env name then
          [.duplicateLetBinding name]
        else
          []
      let bodyErrors := validateExpr (bindType env name boundTy) body
      idErrors ++ bindingErrors ++ duplicateErrors ++ bodyErrors

end LeanCairo.Core.Validation
