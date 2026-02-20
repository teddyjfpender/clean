import LeanCairo.Backend.Cairo.Naming
import LeanCairo.Backend.Cairo.Pretty
import LeanCairo.Compiler.IR.Expr
import LeanCairo.Core.Domain.Ty

namespace LeanCairo.Backend.Cairo

open LeanCairo.Compiler.IR
open LeanCairo.Core.Domain

private def renderU256Literal (value : Nat) : String :=
  let base := Nat.pow 2 128
  let low := value % base
  let high := value / base
  "u256 { low: " ++ toString low ++ "_u128, high: " ++ toString high ++ "_u128 }"

partial def emitIRExpr : IRExpr ty -> String
  | .var name => toCairoLocalName name
  | .storageRead name => "self." ++ toCairoStorageFieldName name ++ ".read()"
  | .litU128 value => s!"{value}_u128"
  | .litU256 value => renderU256Literal value
  | .litBool value => if value then "true" else "false"
  | .litFelt252 value => toString value
  | .addU128 lhs rhs => s!"({emitIRExpr lhs} + {emitIRExpr rhs})"
  | .subU128 lhs rhs => s!"({emitIRExpr lhs} - {emitIRExpr rhs})"
  | .mulU128 lhs rhs => s!"({emitIRExpr lhs} * {emitIRExpr rhs})"
  | .addU256 lhs rhs => s!"({emitIRExpr lhs} + {emitIRExpr rhs})"
  | .subU256 lhs rhs => s!"({emitIRExpr lhs} - {emitIRExpr rhs})"
  | .mulU256 lhs rhs => s!"({emitIRExpr lhs} * {emitIRExpr rhs})"
  | .eq lhs rhs => s!"({emitIRExpr lhs} == {emitIRExpr rhs})"
  | .ltU128 lhs rhs => s!"({emitIRExpr lhs} < {emitIRExpr rhs})"
  | .leU128 lhs rhs => s!"({emitIRExpr lhs} <= {emitIRExpr rhs})"
  | .ltU256 lhs rhs => s!"({emitIRExpr lhs} < {emitIRExpr rhs})"
  | .leU256 lhs rhs => s!"({emitIRExpr lhs} <= {emitIRExpr rhs})"
  | .ite cond thenBranch elseBranch =>
      let condRendered := emitIRExpr cond
      let thenRendered := emitIRExpr thenBranch
      let elseRendered := emitIRExpr elseBranch
      "if " ++ condRendered ++ " {\n"
        ++ indentLines 1 thenRendered
        ++ "\n} else {\n"
        ++ indentLines 1 elseRendered
        ++ "\n}"
  | .letE name boundTy bound body =>
      let boundName := toCairoLocalName name
      let boundRendered := emitIRExpr bound
      let bodyRendered := emitIRExpr body
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
