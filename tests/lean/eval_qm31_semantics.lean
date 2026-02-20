import LeanCairo.Compiler.Semantics.Eval

open LeanCairo.Compiler.Semantics
open LeanCairo.Core.Domain

private def assertCondition (ok : Bool) (message : String) : IO Unit := do
  if ok then
    pure ()
  else
    throw <| IO.userError message

#eval do
  let modulus := IntegerDomains.qm31Modulus
  assertCondition (modulus = 2 ^ 31 - 1) "qm31 modulus should remain pinned to 2^31 - 1 policy"

  assertCondition (IntegerDomains.normalizeQm31 (modulus + 5) = 5)
    "qm31 normalization should reduce values modulo pinned modulus"
  assertCondition (IntegerDomains.qm31Add (modulus - 1) 2 = 1)
    "qm31 addition should wrap modulo pinned modulus"
  assertCondition (IntegerDomains.qm31Sub 0 1 = modulus - 1)
    "qm31 subtraction should wrap on underflow"
  assertCondition (IntegerDomains.qm31Mul (modulus - 1) (modulus - 1) = 1)
    "qm31 multiplication should wrap modulo pinned modulus"

  let ctx0 : EvalContext := {}
  let ctx1 <- match EvalContext.bindVarStrict ctx0 .qm31 "f" (modulus + 9) with
    | .ok next => pure next
    | .error err => throw <| IO.userError s!"unexpected qm31 bind error: {err}"
  let value <- match EvalContext.readVarStrict ctx1 .qm31 "f" with
    | .ok v => pure v
    | .error err => throw <| IO.userError s!"unexpected qm31 read error: {err}"

  assertCondition (value = 9) "strict qm31 bind/read should preserve normalized qm31 values"
  assertCondition (EvalContext.readVar ctx1 .u128 "f" = 0)
    "qm31 and u128 runtime domains must remain isolated"
