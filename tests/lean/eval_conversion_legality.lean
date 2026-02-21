import LeanCairo.Compiler.Semantics.Eval

open LeanCairo.Compiler.Semantics
open LeanCairo.Core.Domain

private def assertCondition (ok : Bool) (message : String) : IO Unit := do
  if ok then
    pure ()
  else
    throw <| IO.userError message

private def expectErrorContains {α : Type} (result : Except String α) (needle : String) (context : String) : IO Unit := do
  match result with
  | .ok _ =>
      throw <| IO.userError s!"expected cast failure for {context}"
  | .error err =>
      assertCondition (err.contains needle) s!"expected error for {context} to contain '{needle}', got '{err}'"

private def expectOkEq [DecidableEq α] (result : Except String α) (expected : α) (context : String) : IO Unit := do
  match result with
  | .ok value =>
      assertCondition (value = expected) s!"unexpected cast value for {context}"
  | .error err =>
      throw <| IO.userError s!"expected successful cast for {context}, got '{err}'"

#eval do
  -- Matrix enforcement: runtime domains are cast-legal, non-runtime domains are rejected.
  assertCondition (EvalContext.isCastLegal .u8 .u128) "u8 -> u128 must be legal cast path"
  assertCondition (EvalContext.isCastLegal .bool .felt252) "bool -> felt252 must be legal cast path"
  assertCondition (!EvalContext.isCastLegal (.tuple 2) .u128) "tuple -> u128 must be illegal cast path"
  assertCondition (!EvalContext.isCastLegal .u128 (.dict "felt252" "u128")) "u128 -> dict must be illegal cast path"

  -- Invalid cast path fail-fast diagnostics remain stable.
  let illegalTupleCast : Except String Nat := EvalContext.castStrict (.tuple 2) .u128 ()
  match illegalTupleCast with
  | .ok _ =>
      throw <| IO.userError "expected tuple -> u128 cast to fail-fast"
  | .error err =>
      assertCondition
        (err = EvalContext.castUnsupportedMessage (.tuple 2) .u128)
        "illegal tuple cast should return stable unsupported-cast diagnostic"

  -- Oracle-aligned successful casts.
  let u16ToU8Oracle : Nat := IntegerDomains.normalizeUnsigned 8 65540
  expectOkEq (EvalContext.castStrict .u16 .u8 65540) u16ToU8Oracle "u16 -> u8 wrapping"

  let i16ToI8Oracle : Int := IntegerDomains.normalizeSigned 8 (-129)
  expectOkEq (EvalContext.castStrict .i16 .i8 (-129)) i16ToI8Oracle "i16 -> i8 wrapping"

  let feltToQm31Oracle : Nat := (Int.emod (-3) (Int.ofNat IntegerDomains.qm31Modulus)).toNat
  expectOkEq (EvalContext.castStrict .felt252 .qm31 (-3)) feltToQm31Oracle "felt252 -> qm31 residue"

  expectOkEq (EvalContext.castStrict .bool .u128 true) 1 "bool -> u128 true"
  expectOkEq (EvalContext.castStrict .bool .u128 false) 0 "bool -> u128 false"
  expectOkEq (EvalContext.castStrict .u128 .bool 1) true "u128 -> bool canonical true"
  expectOkEq (EvalContext.castStrict .u128 .bool 0) false "u128 -> bool canonical false"

  -- Domain violations fail fast with deterministic diagnostics.
  expectErrorContains (EvalContext.castStrict .i16 .u8 (-2)) "negative source value" "i16 -> u8 negative input"
  expectErrorContains (EvalContext.castStrict .u8 .bool 2) "canonical boolean value 0 or 1" "u8 -> bool non-canonical"

  -- Determinism contract: same input pair must yield same cast result.
  let runA := EvalContext.castStrict .felt252 .u64 42
  let runB := EvalContext.castStrict .felt252 .u64 42
  match runA, runB with
  | .ok valueA, .ok valueB =>
      assertCondition (decide (valueA = valueB)) "cast evaluation must be deterministic for equal inputs"
  | .error errA, .error errB =>
      assertCondition (decide (errA = errB)) "cast failure diagnostics must be deterministic for equal inputs"
  | _, _ =>
      throw <| IO.userError "cast evaluation determinism failed due to shape mismatch"
