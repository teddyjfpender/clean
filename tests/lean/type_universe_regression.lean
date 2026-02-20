import LeanCairo.Core.Domain.Ty

open LeanCairo.Core.Domain

private def assertCondition (ok : Bool) (message : String) : IO Unit := do
  if ok then
    pure ()
  else
    throw <| IO.userError message

#eval do
  -- Scalar family expansion.
  assertCondition (Ty.familyTag .i8 = "signed-int") "i8 should map to signed-int family"
  assertCondition (Ty.familyTag .u64 = "unsigned-int") "u64 should map to unsigned-int family"
  assertCondition (Ty.familyTag .qm31 = "field") "qm31 should map to field family"

  -- Compound family expansion.
  assertCondition (Ty.familyTag (.tuple 2) = "tuple") "tuple should map to tuple family"
  assertCondition (Ty.familyTag (.structTy "Point") = "struct") "structTy should map to struct family"
  assertCondition (Ty.familyTag (.enumTy "Result") = "enum") "enumTy should map to enum family"
  assertCondition (Ty.familyTag (.array "felt252") = "array") "array should map to array family"
  assertCondition (Ty.familyTag (.span "u128") = "span") "span should map to span family"
  assertCondition (Ty.familyTag (.nullable "u128") = "nullable") "nullable should map to nullable family"
  assertCondition (Ty.familyTag (.boxed "u256") = "box") "boxed should map to box family"
  assertCondition (Ty.familyTag (.dict "felt252" "u128") = "dict") "dict should map to dict family"

  -- Wrapper and resource families.
  assertCondition (Ty.familyTag (.nonZero "u128") = "nonzero-wrapper") "nonZero should map to wrapper family"
  assertCondition (Ty.familyTag .rangeCheck = "resource-range-check") "rangeCheck should map to resource family"
  assertCondition (Ty.familyTag .gasBuiltin = "resource-gas") "gasBuiltin should map to resource family"
  assertCondition (Ty.familyTag .segmentArena = "resource-segment-arena") "segmentArena should map to resource family"
  assertCondition (Ty.familyTag .panicSignal = "resource-panic") "panicSignal should map to resource family"

  -- MVP support boundary contract.
  assertCondition (Ty.isMvpBackendSupported .felt252) "felt252 should remain MVP-supported"
  assertCondition (!Ty.isMvpBackendSupported (.tuple 1)) "tuple should remain outside MVP support boundary"

  -- Deterministic rendering for nested forms.
  assertCondition (Ty.toCairo (.dict "felt252" "NonZero<u128>") = "Felt252Dict<felt252, NonZero<u128>>")
    "nested toCairo rendering should remain deterministic"
  assertCondition (Ty.toAbiCanonical (.array "core::integer::u128") = "core::array::Array<core::integer::u128>")
    "array ABI canonical rendering should remain deterministic"
