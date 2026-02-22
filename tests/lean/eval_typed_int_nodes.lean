import LeanCairo.Compiler.Semantics.Eval

open LeanCairo.Compiler.IR
open LeanCairo.Compiler.Semantics
open LeanCairo.Core.Domain

private def assertCondition (ok : Bool) (message : String) : IO Unit := do
  if ok then
    pure ()
  else
    throw <| IO.userError message

#eval do
  let state : SemanticState := { context := {}, resources := {}, failure := none }

  -- Signed typed-int lane wraps with i8 semantics.
  let i8Expr : IRExpr .i8 := .addInt .i8 (.litInt .i8 120) (.litInt .i8 20)
  match evalExprStateStrict state i8Expr with
  | .error err =>
      throw <| IO.userError s!"unexpected strict i8 add failure: {err}"
  | .ok (value, _) =>
      assertCondition (value = -116) "typed-int i8 add should wrap in two's complement domain"

  -- Unsigned typed-int lane supports u512 modular arithmetic.
  let maxU512 : Nat := IntegerDomains.pow2 512 - 1
  let u512Expr : IRExpr .u512 := .addInt .u512 (.litInt .u512 maxU512) (.litInt .u512 1)
  match evalExprStateStrict state u512Expr with
  | .error err =>
      throw <| IO.userError s!"unexpected strict u512 add failure: {err}"
  | .ok (value, _) =>
      assertCondition (value = 0) "typed-int u512 add should wrap modulo 2^512"

  -- Typed-int comparisons evaluate in-lane.
  let cmpExpr : IRExpr .bool := .ltInt .u64 (.litInt .u64 7) (.litInt .u64 9)
  match evalExprStateStrict state cmpExpr with
  | .error err =>
      throw <| IO.userError s!"unexpected strict u64 lt failure: {err}"
  | .ok (value, _) =>
      assertCondition value "typed-int u64 lt should evaluate to true"

  -- qm31 div/mod/bitwise remain explicit fail-fast in strict mode.
  let qmDivExpr : IRExpr .qm31 := .divInt .qm31 (.litInt .qm31 3) (.litInt .qm31 2)
  match evalExprStateStrict state qmDivExpr with
  | .ok _ =>
      throw <| IO.userError "qm31 division should fail-fast in strict mode"
  | .error err =>
      assertCondition (err.contains "unsupported division operation for type 'qm31'")
        "qm31 division fail-fast message changed unexpectedly"

  let qmBitExpr : IRExpr .qm31 := .bitAndInt .qm31 (.litInt .qm31 1) (.litInt .qm31 1)
  match evalExprStateStrict state qmBitExpr with
  | .ok _ =>
      throw <| IO.userError "qm31 bitwise-and should fail-fast in strict mode"
  | .error err =>
      assertCondition (err.contains "unsupported bitwise-and operation for type 'qm31'")
        "qm31 bitwise-and fail-fast message changed unexpectedly"

  -- Division by zero remains fail-fast for integer lanes.
  let divZeroExpr : IRExpr .u16 := .divInt .u16 (.litInt .u16 1) (.litInt .u16 0)
  match evalExprStateStrict state divZeroExpr with
  | .ok _ =>
      throw <| IO.userError "typed-int u16 division by zero should fail-fast in strict mode"
  | .error err =>
      assertCondition (err.contains "division by zero in u16 lane")
        "typed-int u16 division-by-zero fail-fast message changed unexpectedly"
