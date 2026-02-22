import LeanCairo.Core.Domain.Ty

namespace LeanCairo.Core.Domain

inductive IntLane where
  | i8
  | i16
  | i32
  | i64
  | i128
  | u8
  | u16
  | u32
  | u64
  | u128
  | u256
  | u512
  | qm31
  deriving Repr, DecidableEq, BEq, Inhabited

namespace IntLane

def toTy : IntLane -> Ty
  | .i8 => .i8
  | .i16 => .i16
  | .i32 => .i32
  | .i64 => .i64
  | .i128 => .i128
  | .u8 => .u8
  | .u16 => .u16
  | .u32 => .u32
  | .u64 => .u64
  | .u128 => .u128
  | .u256 => .u256
  | .u512 => .u512
  | .qm31 => .qm31

def ofTy? : Ty -> Option IntLane
  | .i8 => some .i8
  | .i16 => some .i16
  | .i32 => some .i32
  | .i64 => some .i64
  | .i128 => some .i128
  | .u8 => some .u8
  | .u16 => some .u16
  | .u32 => some .u32
  | .u64 => some .u64
  | .u128 => some .u128
  | .u256 => some .u256
  | .u512 => some .u512
  | .qm31 => some .qm31
  | _ => none

def isSigned : IntLane -> Bool
  | .i8 | .i16 | .i32 | .i64 | .i128 => true
  | _ => false

def isUnsigned : IntLane -> Bool :=
  not ∘ isSigned

def bitWidth : IntLane -> Nat
  | .i8 | .u8 => 8
  | .i16 | .u16 => 16
  | .i32 | .u32 => 32
  | .i64 | .u64 => 64
  | .i128 | .u128 => 128
  | .u256 => 256
  | .u512 => 512
  | .qm31 => 31

def supportsBitwise : IntLane -> Bool
  | .qm31 => false
  | _ => true

def supportsDivMod : IntLane -> Bool
  | .qm31 => false
  | _ => true

abbrev denote (lane : IntLane) : Type := Ty.denote lane.toTy

def toCairo (lane : IntLane) : String := Ty.toCairo lane.toTy

@[simp] theorem toTy_injective : Function.Injective toTy := by
  intro a b h
  cases a <;> cases b <;> simp [toTy] at h <;> cases h <;> rfl

@[simp] theorem toTy_eq_toTy_iff (a b : IntLane) : toTy a = toTy b ↔ a = b := by
  constructor
  · intro h
    exact toTy_injective h
  · intro h
    simp [h]

instance denoteDecidableEq (lane : IntLane) : DecidableEq (IntLane.denote lane) := by
  simpa [IntLane.denote] using (Ty.denoteDecidableEq lane.toTy)

instance denoteRepr (lane : IntLane) : Repr (IntLane.denote lane) := by
  simpa [IntLane.denote] using (Ty.denoteRepr lane.toTy)

end IntLane
end LeanCairo.Core.Domain
