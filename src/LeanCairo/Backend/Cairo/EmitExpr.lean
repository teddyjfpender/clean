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

private def renderIntLiteral : (ty : Ty) -> Ty.denote ty -> String
  | .felt252, value => toString value
  | .i8, value => s!"({value} as i8)"
  | .i16, value => s!"({value} as i16)"
  | .i32, value => s!"({value} as i32)"
  | .i64, value => s!"({value} as i64)"
  | .i128, value => s!"({value} as i128)"
  | .u8, value => s!"({value} as u8)"
  | .u16, value => s!"({value} as u16)"
  | .u32, value => s!"({value} as u32)"
  | .u64, value => s!"({value} as u64)"
  | .u128, value => s!"{value}_u128"
  | .u256, value => renderU256Literal value
  | .u512, value => s!"({value} as u512)"
  | .qm31, value => s!"({value} as qm31)"
  | .bool, value => if value then "true" else "false"
  | _, _ => "0"

partial def emitExpr : Expr ty -> String
  | .var name => toCairoLocalName name
  | .storageRead name => "self." ++ toCairoStorageFieldName name ++ ".read()"
  | .litU128 value => s!"{value}_u128"
  | .litU256 value => renderU256Literal value
  | .litBool value => if value then "true" else "false"
  | .litFelt252 value => toString value
  | .litInt ty value => renderIntLiteral ty value
  | .addFelt252 lhs rhs => s!"({emitExpr lhs} + {emitExpr rhs})"
  | .subFelt252 lhs rhs => s!"({emitExpr lhs} - {emitExpr rhs})"
  | .mulFelt252 lhs rhs => s!"({emitExpr lhs} * {emitExpr rhs})"
  | .addInt _ lhs rhs => s!"({emitExpr lhs} + {emitExpr rhs})"
  | .subInt _ lhs rhs => s!"({emitExpr lhs} - {emitExpr rhs})"
  | .mulInt _ lhs rhs => s!"({emitExpr lhs} * {emitExpr rhs})"
  | .divInt _ lhs rhs => s!"({emitExpr lhs} / {emitExpr rhs})"
  | .modInt _ lhs rhs => s!"({emitExpr lhs} % {emitExpr rhs})"
  | .bitAndInt _ lhs rhs => s!"({emitExpr lhs} & {emitExpr rhs})"
  | .bitOrInt _ lhs rhs => s!"({emitExpr lhs} | {emitExpr rhs})"
  | .bitXorInt _ lhs rhs => s!"({emitExpr lhs} ^ {emitExpr rhs})"
  | .shlInt _ lhs shift => s!"({emitExpr lhs} << {shift})"
  | .shrInt _ lhs shift => s!"({emitExpr lhs} >> {shift})"
  | .addU128 lhs rhs => s!"({emitExpr lhs} + {emitExpr rhs})"
  | .subU128 lhs rhs => s!"({emitExpr lhs} - {emitExpr rhs})"
  | .mulU128 lhs rhs => s!"({emitExpr lhs} * {emitExpr rhs})"
  | .divU128 lhs rhs => s!"({emitExpr lhs} / {emitExpr rhs})"
  | .modU128 lhs rhs => s!"({emitExpr lhs} % {emitExpr rhs})"
  | .bitAndU128 lhs rhs => s!"({emitExpr lhs} & {emitExpr rhs})"
  | .bitOrU128 lhs rhs => s!"({emitExpr lhs} | {emitExpr rhs})"
  | .bitXorU128 lhs rhs => s!"({emitExpr lhs} ^ {emitExpr rhs})"
  | .shlU128 lhs shift => s!"({emitExpr lhs} << {shift})"
  | .shrU128 lhs shift => s!"({emitExpr lhs} >> {shift})"
  | .addU256 lhs rhs => s!"({emitExpr lhs} + {emitExpr rhs})"
  | .subU256 lhs rhs => s!"({emitExpr lhs} - {emitExpr rhs})"
  | .mulU256 lhs rhs => s!"({emitExpr lhs} * {emitExpr rhs})"
  | .divU256 lhs rhs => s!"({emitExpr lhs} / {emitExpr rhs})"
  | .modU256 lhs rhs => s!"({emitExpr lhs} % {emitExpr rhs})"
  | .bitAndU256 lhs rhs => s!"({emitExpr lhs} & {emitExpr rhs})"
  | .bitOrU256 lhs rhs => s!"({emitExpr lhs} | {emitExpr rhs})"
  | .bitXorU256 lhs rhs => s!"({emitExpr lhs} ^ {emitExpr rhs})"
  | .shlU256 lhs shift => s!"({emitExpr lhs} << {shift})"
  | .shrU256 lhs shift => s!"({emitExpr lhs} >> {shift})"
  | .u256FromLimbs low high =>
      "u256 { low: " ++ emitExpr low ++ ", high: " ++ emitExpr high ++ " }"
  | .u256Low value => s!"({emitExpr value}).low"
  | .u256High value => s!"({emitExpr value}).high"
  | .eq lhs rhs => s!"({emitExpr lhs} == {emitExpr rhs})"
  | .ltInt _ lhs rhs => s!"({emitExpr lhs} < {emitExpr rhs})"
  | .leInt _ lhs rhs => s!"({emitExpr lhs} <= {emitExpr rhs})"
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
