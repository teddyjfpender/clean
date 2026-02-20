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
  let maxU8 : Nat := IntegerDomains.pow2 8 - 1
  let maxU128 : Nat := IntegerDomains.pow2 128 - 1

  -- Unsigned normalization is width-bounded.
  assertCondition (IntegerDomains.normalizeUnsigned 8 (maxU8 + 1) = 0)
    "u8 normalization should wrap by 2^8"
  assertCondition (IntegerDomains.normalizeUnsigned 16 (IntegerDomains.pow2 16 + 9) = 9)
    "u16 normalization should preserve residue modulo 2^16"

  -- Signed normalization follows two's-complement range.
  assertCondition (IntegerDomains.normalizeSigned 8 130 = -126)
    "i8 normalization should map 130 to -126"
  assertCondition (IntegerDomains.normalizeSigned 8 (-129) = 127)
    "i8 normalization should map -129 to 127"

  -- Strict bind/read path enforces width semantics for integer families.
  let baseCtx : EvalContext := {}
  let ctxI8 <- match EvalContext.bindVarStrict baseCtx .i8 "x" 130 with
    | .ok next => pure next
    | .error err => throw <| IO.userError s!"unexpected i8 bind error: {err}"
  let readI8 <- match EvalContext.readVarStrict ctxI8 .i8 "x" with
    | .ok value => pure value
    | .error err => throw <| IO.userError s!"unexpected i8 read error: {err}"
  assertCondition (readI8 = -126) "strict i8 bind/read should preserve normalized i8 domain value"

  let ctxU8 <- match EvalContext.bindVarStrict baseCtx .u8 "n" (maxU8 + 3) with
    | .ok next => pure next
    | .error err => throw <| IO.userError s!"unexpected u8 bind error: {err}"
  let readU8 <- match EvalContext.readVarStrict ctxU8 .u8 "n" with
    | .ok value => pure value
    | .error err => throw <| IO.userError s!"unexpected u8 read error: {err}"
  assertCondition (readU8 = 2) "strict u8 bind/read should wrap values modulo 2^8"

  -- Strict expression semantics for u128 uses modular arithmetic.
  let state : SemanticState := { context := {}, resources := {}, failure := none }
  let wrapAddExpr : IRExpr .u128 := .addU128 (.litU128 maxU128) (.litU128 1)
  match evalExprStateStrict state wrapAddExpr with
  | .error err =>
      throw <| IO.userError s!"unexpected strict add failure: {err}"
  | .ok (value, _) =>
      assertCondition (value = 0) "strict u128 addition should wrap modulo 2^128"

  let wrapSubExpr : IRExpr .u128 := .subU128 (.litU128 0) (.litU128 1)
  match evalExprStateStrict state wrapSubExpr with
  | .error err =>
      throw <| IO.userError s!"unexpected strict sub failure: {err}"
  | .ok (value, _) =>
      assertCondition (value = maxU128) "strict u128 subtraction should wrap on underflow"

  let wrapMulExpr : IRExpr .u128 := .mulU128 (.litU128 maxU128) (.litU128 maxU128)
  match evalExprStateStrict state wrapMulExpr with
  | .error err =>
      throw <| IO.userError s!"unexpected strict mul failure: {err}"
  | .ok (value, _) =>
      assertCondition (value = 1) "strict u128 multiplication should wrap modulo 2^128"
