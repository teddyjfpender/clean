namespace LeanCairo.Core.Domain

inductive Ty where
  | felt252
  | u128
  | u256
  | bool
  | i8
  | i16
  | i32
  | i64
  | i128
  | u8
  | u16
  | u32
  | u64
  | qm31
  | tuple (arity : Nat)
  | structTy (name : String)
  | enumTy (name : String)
  | array (elemTag : String)
  | span (elemTag : String)
  | nullable (elemTag : String)
  | boxed (elemTag : String)
  | dict (keyTag : String) (valueTag : String)
  | nonZero (innerTag : String)
  | rangeCheck
  | gasBuiltin
  | segmentArena
  | panicSignal
  deriving Repr, DecidableEq, BEq, Inhabited

namespace Ty

def toCairo : Ty -> String
  | .felt252 => "felt252"
  | .u128 => "u128"
  | .u256 => "u256"
  | .bool => "bool"
  | .i8 => "i8"
  | .i16 => "i16"
  | .i32 => "i32"
  | .i64 => "i64"
  | .i128 => "i128"
  | .u8 => "u8"
  | .u16 => "u16"
  | .u32 => "u32"
  | .u64 => "u64"
  | .qm31 => "qm31"
  | .tuple arity => s!"Tuple{arity}"
  | .structTy name => name
  | .enumTy name => name
  | .array elemTag => "Array<" ++ elemTag ++ ">"
  | .span elemTag => "Span<" ++ elemTag ++ ">"
  | .nullable elemTag => "Nullable<" ++ elemTag ++ ">"
  | .boxed elemTag => "Box<" ++ elemTag ++ ">"
  | .dict keyTag valueTag => "Felt252Dict<" ++ keyTag ++ ", " ++ valueTag ++ ">"
  | .nonZero innerTag => "NonZero<" ++ innerTag ++ ">"
  | .rangeCheck => "RangeCheck"
  | .gasBuiltin => "GasBuiltin"
  | .segmentArena => "SegmentArena"
  | .panicSignal => "PanicSignal"

def toAbiCanonical : Ty -> String
  | .felt252 => "core::felt252"
  | .u128 => "core::integer::u128"
  | .u256 => "core::integer::u256"
  | .bool => "core::bool"
  | .i8 => "core::integer::i8"
  | .i16 => "core::integer::i16"
  | .i32 => "core::integer::i32"
  | .i64 => "core::integer::i64"
  | .i128 => "core::integer::i128"
  | .u8 => "core::integer::u8"
  | .u16 => "core::integer::u16"
  | .u32 => "core::integer::u32"
  | .u64 => "core::integer::u64"
  | .qm31 => "core::qm31"
  | .tuple arity => s!"core::tuple::Tuple{arity}"
  | .structTy name => "core::struct::" ++ name
  | .enumTy name => "core::enum::" ++ name
  | .array elemTag => "core::array::Array<" ++ elemTag ++ ">"
  | .span elemTag => "core::array::Span<" ++ elemTag ++ ">"
  | .nullable elemTag => "core::nullable::Nullable<" ++ elemTag ++ ">"
  | .boxed elemTag => "core::box::Box<" ++ elemTag ++ ">"
  | .dict keyTag valueTag => "core::dict::Felt252Dict<" ++ keyTag ++ ", " ++ valueTag ++ ">"
  | .nonZero innerTag => "core::zeroable::NonZero<" ++ innerTag ++ ">"
  | .rangeCheck => "core::range_check::RangeCheck"
  | .gasBuiltin => "core::gas::GasBuiltin"
  | .segmentArena => "core::segment_arena::SegmentArena"
  | .panicSignal => "core::panic::PanicSignal"

def familyTag : Ty -> String
  | .felt252 | .u128 | .u256 | .bool => "legacy-scalar"
  | .i8 | .i16 | .i32 | .i64 | .i128 => "signed-int"
  | .u8 | .u16 | .u32 | .u64 => "unsigned-int"
  | .qm31 => "field"
  | .tuple _ => "tuple"
  | .structTy _ => "struct"
  | .enumTy _ => "enum"
  | .array _ => "array"
  | .span _ => "span"
  | .nullable _ => "nullable"
  | .boxed _ => "box"
  | .dict _ _ => "dict"
  | .nonZero _ => "nonzero-wrapper"
  | .rangeCheck => "resource-range-check"
  | .gasBuiltin => "resource-gas"
  | .segmentArena => "resource-segment-arena"
  | .panicSignal => "resource-panic"

def isMvpBackendSupported : Ty -> Bool
  | .felt252 | .u128 | .u256 | .bool => true
  | _ => false

abbrev denote : Ty -> Type
  | .felt252 => Int
  | .u128 => Nat
  | .u256 => Nat
  | .bool => Bool
  | .i8 => Int
  | .i16 => Int
  | .i32 => Int
  | .i64 => Int
  | .i128 => Int
  | .u8 => Nat
  | .u16 => Nat
  | .u32 => Nat
  | .u64 => Nat
  | .qm31 => Nat
  | .tuple _ => Unit
  | .structTy _ => Unit
  | .enumTy _ => Unit
  | .array _ => Unit
  | .span _ => Unit
  | .nullable _ => Unit
  | .boxed _ => Unit
  | .dict _ _ => Unit
  | .nonZero _ => Unit
  | .rangeCheck => Unit
  | .gasBuiltin => Unit
  | .segmentArena => Unit
  | .panicSignal => Unit

instance denoteDecidableEq (ty : Ty) : DecidableEq (Ty.denote ty) := by
  cases ty <;> infer_instance

end Ty
end LeanCairo.Core.Domain
