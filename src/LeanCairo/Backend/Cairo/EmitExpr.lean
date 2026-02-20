import LeanCairo.Backend.Cairo.Naming
import LeanCairo.Backend.Cairo.Pretty
import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Syntax.Expr

namespace LeanCairo.Backend.Cairo

open LeanCairo.Core.Domain
open LeanCairo.Core.Syntax

private def renderU256Literal (value : Nat) : String :=
  let base := Nat.pow 2 128
  let low := value % base
  let high := value / base
  "u256 { low: " ++ toString low ++ "_u128, high: " ++ toString high ++ "_u128 }"

partial def emitExpr : Expr ty -> String
  | .var name => toCairoLocalName name
  | .storageRead name => "self." ++ toCairoStorageFieldName name ++ ".read()"
  | .litU128 value => s!"{value}_u128"
  | .litU256 value => renderU256Literal value
  | .litBool value => if value then "true" else "false"
  | .litFelt252 value => toString value
  | .addU128 lhs rhs => s!"({emitExpr lhs} + {emitExpr rhs})"
  | .subU128 lhs rhs => s!"({emitExpr lhs} - {emitExpr rhs})"
  | .mulU128 lhs rhs => s!"({emitExpr lhs} * {emitExpr rhs})"
  | .addU256 lhs rhs => s!"({emitExpr lhs} + {emitExpr rhs})"
  | .subU256 lhs rhs => s!"({emitExpr lhs} - {emitExpr rhs})"
  | .mulU256 lhs rhs => s!"({emitExpr lhs} * {emitExpr rhs})"
  | .eq lhs rhs => s!"({emitExpr lhs} == {emitExpr rhs})"
  | .ltU128 lhs rhs => s!"({emitExpr lhs} < {emitExpr rhs})"
  | .leU128 lhs rhs => s!"({emitExpr lhs} <= {emitExpr rhs})"
  | .ltU256 lhs rhs => s!"({emitExpr lhs} < {emitExpr rhs})"
  | .leU256 lhs rhs => s!"({emitExpr lhs} <= {emitExpr rhs})"
  | .ite cond thenBranch elseBranch =>
      let condRendered := emitExpr cond
      let thenRendered := emitExpr thenBranch
      let elseRendered := emitExpr elseBranch
      "if " ++ condRendered ++ " {\n"
        ++ indentLines 1 thenRendered
        ++ "\n} else {\n"
        ++ indentLines 1 elseRendered
        ++ "\n}"
  | .letE name boundTy bound body =>
      let boundName := toCairoLocalName name
      let boundRendered := emitExpr bound
      let bodyRendered := emitExpr body
      "{\n    let "
        ++ boundName
        ++ ": "
        ++ Ty.toCairo boundTy
        ++ " = "
        ++ boundRendered
        ++ ";\n"
        ++ indentLines 1 bodyRendered
        ++ "\n}"

end LeanCairo.Backend.Cairo
