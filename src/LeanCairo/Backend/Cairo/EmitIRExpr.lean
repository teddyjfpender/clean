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

partial def emitIRExpr : IRExpr ty -> String
  | .var name => toCairoLocalName name
  | .storageRead name => "self." ++ toCairoStorageFieldName name ++ ".read()"
  | .litU128 value => s!"{value}_u128"
  | .litU256 value => renderU256Literal value
  | .litBool value => if value then "true" else "false"
  | .litFelt252 value => toString value
  | .litInt ty value => renderIntLiteral ty value
  | .addFelt252 lhs rhs => s!"({emitIRExpr lhs} + {emitIRExpr rhs})"
  | .subFelt252 lhs rhs => s!"({emitIRExpr lhs} - {emitIRExpr rhs})"
  | .mulFelt252 lhs rhs => s!"({emitIRExpr lhs} * {emitIRExpr rhs})"
  | .addInt _ lhs rhs => s!"({emitIRExpr lhs} + {emitIRExpr rhs})"
  | .subInt _ lhs rhs => s!"({emitIRExpr lhs} - {emitIRExpr rhs})"
  | .mulInt _ lhs rhs => s!"({emitIRExpr lhs} * {emitIRExpr rhs})"
  | .divInt _ lhs rhs => s!"({emitIRExpr lhs} / {emitIRExpr rhs})"
  | .modInt _ lhs rhs => s!"({emitIRExpr lhs} % {emitIRExpr rhs})"
  | .bitAndInt _ lhs rhs => s!"({emitIRExpr lhs} & {emitIRExpr rhs})"
  | .bitOrInt _ lhs rhs => s!"({emitIRExpr lhs} | {emitIRExpr rhs})"
  | .bitXorInt _ lhs rhs => s!"({emitIRExpr lhs} ^ {emitIRExpr rhs})"
  | .shlInt _ lhs shift => s!"({emitIRExpr lhs} << {shift})"
  | .shrInt _ lhs shift => s!"({emitIRExpr lhs} >> {shift})"
  | .addU128 lhs rhs => s!"({emitIRExpr lhs} + {emitIRExpr rhs})"
  | .subU128 lhs rhs => s!"({emitIRExpr lhs} - {emitIRExpr rhs})"
  | .mulU128 lhs rhs => s!"({emitIRExpr lhs} * {emitIRExpr rhs})"
  | .divU128 lhs rhs => s!"({emitIRExpr lhs} / {emitIRExpr rhs})"
  | .modU128 lhs rhs => s!"({emitIRExpr lhs} % {emitIRExpr rhs})"
  | .bitAndU128 lhs rhs => s!"({emitIRExpr lhs} & {emitIRExpr rhs})"
  | .bitOrU128 lhs rhs => s!"({emitIRExpr lhs} | {emitIRExpr rhs})"
  | .bitXorU128 lhs rhs => s!"({emitIRExpr lhs} ^ {emitIRExpr rhs})"
  | .shlU128 lhs shift => s!"({emitIRExpr lhs} << {shift})"
  | .shrU128 lhs shift => s!"({emitIRExpr lhs} >> {shift})"
  | .addU256 lhs rhs => s!"({emitIRExpr lhs} + {emitIRExpr rhs})"
  | .subU256 lhs rhs => s!"({emitIRExpr lhs} - {emitIRExpr rhs})"
  | .mulU256 lhs rhs => s!"({emitIRExpr lhs} * {emitIRExpr rhs})"
  | .divU256 lhs rhs => s!"({emitIRExpr lhs} / {emitIRExpr rhs})"
  | .modU256 lhs rhs => s!"({emitIRExpr lhs} % {emitIRExpr rhs})"
  | .bitAndU256 lhs rhs => s!"({emitIRExpr lhs} & {emitIRExpr rhs})"
  | .bitOrU256 lhs rhs => s!"({emitIRExpr lhs} | {emitIRExpr rhs})"
  | .bitXorU256 lhs rhs => s!"({emitIRExpr lhs} ^ {emitIRExpr rhs})"
  | .shlU256 lhs shift => s!"({emitIRExpr lhs} << {shift})"
  | .shrU256 lhs shift => s!"({emitIRExpr lhs} >> {shift})"
  | .u256FromLimbs low high =>
      "u256 { low: " ++ emitIRExpr low ++ ", high: " ++ emitIRExpr high ++ " }"
  | .u256Low value => s!"({emitIRExpr value}).low"
  | .u256High value => s!"({emitIRExpr value}).high"
  | .eq lhs rhs => s!"({emitIRExpr lhs} == {emitIRExpr rhs})"
  | .ltInt _ lhs rhs => s!"({emitIRExpr lhs} < {emitIRExpr rhs})"
  | .leInt _ lhs rhs => s!"({emitIRExpr lhs} <= {emitIRExpr rhs})"
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
