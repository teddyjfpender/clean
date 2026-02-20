import LeanCairo.Compiler.Semantics.Eval

open LeanCairo.Compiler.Semantics
open LeanCairo.Core.Domain

private def assertCondition (ok : Bool) (message : String) : IO Unit := do
  if ok then
    pure ()
  else
    throw <| IO.userError message

#eval do
  let emptyCtx : EvalContext := {}

  -- Distinct signed domains do not alias felt252.
  let signedCtx := EvalContext.bindVar emptyCtx .i8 "x" (-5)
  assertCondition (EvalContext.readVar signedCtx .i8 "x" = -5) "i8 binding should be readable from i8 domain"
  assertCondition (EvalContext.readVar signedCtx .felt252 "x" = 0) "i8 binding must not alias felt252 domain"
  assertCondition (EvalContext.readVar signedCtx .i16 "x" = 0) "i8 binding must not alias i16 domain"

  -- Distinct unsigned domains do not alias u128.
  let unsignedCtx := EvalContext.bindVar emptyCtx .u8 "n" 7
  assertCondition (EvalContext.readVar unsignedCtx .u8 "n" = 7) "u8 binding should be readable from u8 domain"
  assertCondition (EvalContext.readVar unsignedCtx .u128 "n" = 0) "u8 binding must not alias u128 domain"
  assertCondition (EvalContext.readVar unsignedCtx .qm31 "n" = 0) "u8 binding must not alias qm31 domain"

  -- qm31 has its own isolated domain.
  let qm31Ctx := EvalContext.bindVar emptyCtx .qm31 "f" 19
  assertCondition (EvalContext.readVar qm31Ctx .qm31 "f" = 19) "qm31 binding should be readable from qm31 domain"
  assertCondition (EvalContext.readVar qm31Ctx .u128 "f" = 0) "qm31 binding must not alias u128 domain"

  -- Mixed writes under same name remain separated by type.
  let mixedCtx :=
    EvalContext.bindVar
      (EvalContext.bindVar emptyCtx .i8 "shared" (-11))
      .felt252
      "shared"
      42
  assertCondition (EvalContext.readVar mixedCtx .i8 "shared" = -11) "mixed context must preserve i8 value"
  assertCondition (EvalContext.readVar mixedCtx .felt252 "shared" = 42) "mixed context must preserve felt252 value"

  -- Storage domains also remain isolated.
  let storageCtx := EvalContext.bindStorage emptyCtx .u16 "slot" 99
  assertCondition (EvalContext.readStorage storageCtx .u16 "slot" = 99) "u16 storage write should be readable from u16 storage"
  assertCondition (EvalContext.readStorage storageCtx .u128 "slot" = 0) "u16 storage write must not alias u128 storage"

  let signedStorageCtx := EvalContext.bindStorage emptyCtx .i32 "slot2" (-3)
  assertCondition (EvalContext.readStorage signedStorageCtx .i32 "slot2" = -3) "i32 storage write should be readable from i32 storage"
  assertCondition (EvalContext.readStorage signedStorageCtx .felt252 "slot2" = 0) "i32 storage write must not alias felt252 storage"
