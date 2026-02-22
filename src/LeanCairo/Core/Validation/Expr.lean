import LeanCairo.Core.Domain.Identifier
import LeanCairo.Core.Syntax.Expr
import LeanCairo.Core.Validation.Context
import LeanCairo.Core.Validation.Errors

namespace LeanCairo.Core.Validation

open LeanCairo.Core.Domain
open LeanCairo.Core.Syntax

partial def validateExpr (varEnv : TypeEnv) (storageEnv : TypeEnv) : Expr ty -> List ValidationError
  | @Expr.var expectedTy name =>
      match lookupType varEnv name with
      | none => [.unboundVariable name]
      | some actualTy =>
          if actualTy == expectedTy then
            []
          else
            [.variableTypeMismatch name expectedTy actualTy]
  | @Expr.storageRead expectedTy name =>
      match lookupType storageEnv name with
      | none => [.unknownStorageField name]
      | some actualTy =>
          if actualTy == expectedTy then
            []
          else
            [.storageFieldTypeMismatch name expectedTy actualTy]
  | .litU128 _ => []
  | .litU256 _ => []
  | .litBool _ => []
  | .litFelt252 _ => []
  | .litInt _ _ => []
  | .addFelt252 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .subFelt252 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .mulFelt252 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .addInt _ lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .subInt _ lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .mulInt _ lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .divInt _ lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .modInt _ lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .bitAndInt _ lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .bitOrInt _ lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .bitXorInt _ lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .shlInt _ lhs _ => validateExpr varEnv storageEnv lhs
  | .shrInt _ lhs _ => validateExpr varEnv storageEnv lhs
  | .addU128 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .subU128 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .mulU128 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .divU128 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .modU128 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .bitAndU128 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .bitOrU128 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .bitXorU128 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .shlU128 lhs _ => validateExpr varEnv storageEnv lhs
  | .shrU128 lhs _ => validateExpr varEnv storageEnv lhs
  | .addU256 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .subU256 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .mulU256 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .divU256 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .modU256 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .bitAndU256 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .bitOrU256 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .bitXorU256 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .shlU256 lhs _ => validateExpr varEnv storageEnv lhs
  | .shrU256 lhs _ => validateExpr varEnv storageEnv lhs
  | .u256FromLimbs low high => validateExpr varEnv storageEnv low ++ validateExpr varEnv storageEnv high
  | .u256Low value => validateExpr varEnv storageEnv value
  | .u256High value => validateExpr varEnv storageEnv value
  | .eq lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .ltInt _ lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .leInt _ lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .ltU128 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .leU128 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .ltU256 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .leU256 lhs rhs => validateExpr varEnv storageEnv lhs ++ validateExpr varEnv storageEnv rhs
  | .ite cond thenBranch elseBranch =>
      validateExpr varEnv storageEnv cond ++
        validateExpr varEnv storageEnv thenBranch ++
        validateExpr varEnv storageEnv elseBranch
  | .letE name boundTy bound body =>
      let idErrors :=
        if !isValidIdentifier name then
          [.invalidIdentifier "let binding" name]
        else if isReservedInternalIdentifier name then
          [.reservedIdentifier "let binding" name]
        else
          []
      let bindingErrors := validateExpr varEnv storageEnv bound
      let duplicateErrors :=
        if hasBinding varEnv name then
          [.duplicateLetBinding name]
        else
          []
      let bodyErrors := validateExpr (bindType varEnv name boundTy) storageEnv body
      idErrors ++ bindingErrors ++ duplicateErrors ++ bodyErrors

end LeanCairo.Core.Validation
