import LeanCairo.Compiler.IR.Expr
import LeanCairo.Core.Domain.Ty

namespace LeanCairo.Compiler.Semantics

open LeanCairo.Compiler.IR
open LeanCairo.Core.Domain

namespace IntegerDomains

def pow2 (bits : Nat) : Nat :=
  Nat.pow 2 bits

def normalizeUnsigned (bits : Nat) (value : Nat) : Nat :=
  value % pow2 bits

def unsignedAdd (bits : Nat) (lhs rhs : Nat) : Nat :=
  normalizeUnsigned bits (lhs + rhs)

def unsignedSub (bits : Nat) (lhs rhs : Nat) : Nat :=
  let modulus := pow2 bits
  (lhs + (modulus - (rhs % modulus))) % modulus

def unsignedMul (bits : Nat) (lhs rhs : Nat) : Nat :=
  normalizeUnsigned bits (lhs * rhs)

def unsignedDiv (bits : Nat) (lhs rhs : Nat) : Nat :=
  if rhs = 0 then
    0
  else
    normalizeUnsigned bits (lhs / rhs)

def unsignedMod (bits : Nat) (lhs rhs : Nat) : Nat :=
  if rhs = 0 then
    0
  else
    normalizeUnsigned bits (lhs % rhs)

def unsignedBitAnd (bits : Nat) (lhs rhs : Nat) : Nat :=
  normalizeUnsigned bits (Nat.land lhs rhs)

def unsignedBitOr (bits : Nat) (lhs rhs : Nat) : Nat :=
  normalizeUnsigned bits (Nat.lor lhs rhs)

def unsignedBitXor (bits : Nat) (lhs rhs : Nat) : Nat :=
  normalizeUnsigned bits (Nat.xor lhs rhs)

def unsignedShl (bits : Nat) (lhs : Nat) (shift : Nat) : Nat :=
  normalizeUnsigned bits (Nat.shiftLeft lhs shift)

def unsignedShr (bits : Nat) (lhs : Nat) (shift : Nat) : Nat :=
  normalizeUnsigned bits (Nat.shiftRight lhs shift)

def normalizeSigned (bits : Nat) (value : Int) : Int :=
  let modulusNat := pow2 bits
  let halfNat := pow2 (bits - 1)
  let modulus := Int.ofNat modulusNat
  let half := Int.ofNat halfNat
  let residue := Int.emod value modulus
  if residue < half then residue else residue - modulus

def signedAdd (bits : Nat) (lhs rhs : Int) : Int :=
  normalizeSigned bits (lhs + rhs)

def signedSub (bits : Nat) (lhs rhs : Int) : Int :=
  normalizeSigned bits (lhs - rhs)

def signedMul (bits : Nat) (lhs rhs : Int) : Int :=
  normalizeSigned bits (lhs * rhs)

def qm31Modulus : Nat := 2 ^ 31 - 1

def normalizeQm31 (value : Nat) : Nat :=
  value % qm31Modulus

def qm31Add (lhs rhs : Nat) : Nat :=
  normalizeQm31 (lhs + rhs)

def qm31Sub (lhs rhs : Nat) : Nat :=
  let rhsNorm := normalizeQm31 rhs
  (normalizeQm31 lhs + (qm31Modulus - rhsNorm)) % qm31Modulus

def qm31Mul (lhs rhs : Nat) : Nat :=
  normalizeQm31 (lhs * rhs)

def signedDiv (bits : Nat) (lhs rhs : Int) : Int :=
  if rhs = 0 then
    0
  else
    normalizeSigned bits (Int.ediv lhs rhs)

def signedMod (bits : Nat) (lhs rhs : Int) : Int :=
  if rhs = 0 then
    0
  else
    normalizeSigned bits (Int.emod lhs rhs)

def signedToUnsignedTwos (bits : Nat) (value : Int) : Nat :=
  let modulus := Int.ofNat (pow2 bits)
  let residue := Int.emod (normalizeSigned bits value) modulus
  residue.toNat

def unsignedTwosToSigned (bits : Nat) (value : Nat) : Int :=
  normalizeSigned bits (Int.ofNat (normalizeUnsigned bits value))

def signedBitAnd (bits : Nat) (lhs rhs : Int) : Int :=
  let lhsNat := signedToUnsignedTwos bits lhs
  let rhsNat := signedToUnsignedTwos bits rhs
  unsignedTwosToSigned bits (Nat.land lhsNat rhsNat)

def signedBitOr (bits : Nat) (lhs rhs : Int) : Int :=
  let lhsNat := signedToUnsignedTwos bits lhs
  let rhsNat := signedToUnsignedTwos bits rhs
  unsignedTwosToSigned bits (Nat.lor lhsNat rhsNat)

def signedBitXor (bits : Nat) (lhs rhs : Int) : Int :=
  let lhsNat := signedToUnsignedTwos bits lhs
  let rhsNat := signedToUnsignedTwos bits rhs
  unsignedTwosToSigned bits (Nat.xor lhsNat rhsNat)

def signedShl (bits : Nat) (lhs : Int) (shift : Nat) : Int :=
  normalizeSigned bits (lhs * Int.ofNat (pow2 shift))

def signedShr (bits : Nat) (lhs : Int) (shift : Nat) : Int :=
  normalizeSigned bits (Int.ediv lhs (Int.ofNat (pow2 shift)))

def u256LimbModulus : Nat := pow2 128

def u256FromLimbs (low high : Nat) : Nat :=
  normalizeUnsigned 256 (normalizeUnsigned 128 low + normalizeUnsigned 128 high * u256LimbModulus)

def u256Low (value : Nat) : Nat :=
  normalizeUnsigned 128 value

def u256High (value : Nat) : Nat :=
  normalizeUnsigned 128 (value / u256LimbModulus)

end IntegerDomains

namespace IntTySemantics

def isSupportedIntTy : Ty -> Bool
  | .i8 | .i16 | .i32 | .i64 | .i128 => true
  | .u8 | .u16 | .u32 | .u64 | .u128 | .u256 | .u512 => true
  | .qm31 => true
  | _ => false

def supportsDivMod : Ty -> Bool
  | .qm31 => false
  | .i8 | .i16 | .i32 | .i64 | .i128 => true
  | .u8 | .u16 | .u32 | .u64 | .u128 | .u256 | .u512 => true
  | _ => false

def supportsBitwise : Ty -> Bool
  | .qm31 => false
  | .i8 | .i16 | .i32 | .i64 | .i128 => true
  | .u8 | .u16 | .u32 | .u64 | .u128 | .u256 | .u512 => true
  | _ => false

def normalize : (ty : Ty) -> Ty.denote ty -> Ty.denote ty
  | .i8 => IntegerDomains.normalizeSigned 8
  | .i16 => IntegerDomains.normalizeSigned 16
  | .i32 => IntegerDomains.normalizeSigned 32
  | .i64 => IntegerDomains.normalizeSigned 64
  | .i128 => IntegerDomains.normalizeSigned 128
  | .u8 => IntegerDomains.normalizeUnsigned 8
  | .u16 => IntegerDomains.normalizeUnsigned 16
  | .u32 => IntegerDomains.normalizeUnsigned 32
  | .u64 => IntegerDomains.normalizeUnsigned 64
  | .u128 => IntegerDomains.normalizeUnsigned 128
  | .u256 => IntegerDomains.normalizeUnsigned 256
  | .u512 => IntegerDomains.normalizeUnsigned 512
  | .qm31 => IntegerDomains.normalizeQm31
  | _ => id

def add : (ty : Ty) -> Ty.denote ty -> Ty.denote ty -> Ty.denote ty
  | .i8 => IntegerDomains.signedAdd 8
  | .i16 => IntegerDomains.signedAdd 16
  | .i32 => IntegerDomains.signedAdd 32
  | .i64 => IntegerDomains.signedAdd 64
  | .i128 => IntegerDomains.signedAdd 128
  | .u8 => IntegerDomains.unsignedAdd 8
  | .u16 => IntegerDomains.unsignedAdd 16
  | .u32 => IntegerDomains.unsignedAdd 32
  | .u64 => IntegerDomains.unsignedAdd 64
  | .u128 => IntegerDomains.unsignedAdd 128
  | .u256 => IntegerDomains.unsignedAdd 256
  | .u512 => IntegerDomains.unsignedAdd 512
  | .qm31 => IntegerDomains.qm31Add
  | _ => fun lhs _ => lhs

def sub : (ty : Ty) -> Ty.denote ty -> Ty.denote ty -> Ty.denote ty
  | .i8 => IntegerDomains.signedSub 8
  | .i16 => IntegerDomains.signedSub 16
  | .i32 => IntegerDomains.signedSub 32
  | .i64 => IntegerDomains.signedSub 64
  | .i128 => IntegerDomains.signedSub 128
  | .u8 => IntegerDomains.unsignedSub 8
  | .u16 => IntegerDomains.unsignedSub 16
  | .u32 => IntegerDomains.unsignedSub 32
  | .u64 => IntegerDomains.unsignedSub 64
  | .u128 => IntegerDomains.unsignedSub 128
  | .u256 => IntegerDomains.unsignedSub 256
  | .u512 => IntegerDomains.unsignedSub 512
  | .qm31 => IntegerDomains.qm31Sub
  | _ => fun lhs _ => lhs

def mul : (ty : Ty) -> Ty.denote ty -> Ty.denote ty -> Ty.denote ty
  | .i8 => IntegerDomains.signedMul 8
  | .i16 => IntegerDomains.signedMul 16
  | .i32 => IntegerDomains.signedMul 32
  | .i64 => IntegerDomains.signedMul 64
  | .i128 => IntegerDomains.signedMul 128
  | .u8 => IntegerDomains.unsignedMul 8
  | .u16 => IntegerDomains.unsignedMul 16
  | .u32 => IntegerDomains.unsignedMul 32
  | .u64 => IntegerDomains.unsignedMul 64
  | .u128 => IntegerDomains.unsignedMul 128
  | .u256 => IntegerDomains.unsignedMul 256
  | .u512 => IntegerDomains.unsignedMul 512
  | .qm31 => IntegerDomains.qm31Mul
  | _ => fun lhs _ => lhs

def div : (ty : Ty) -> Ty.denote ty -> Ty.denote ty -> Ty.denote ty
  | .i8 => IntegerDomains.signedDiv 8
  | .i16 => IntegerDomains.signedDiv 16
  | .i32 => IntegerDomains.signedDiv 32
  | .i64 => IntegerDomains.signedDiv 64
  | .i128 => IntegerDomains.signedDiv 128
  | .u8 => IntegerDomains.unsignedDiv 8
  | .u16 => IntegerDomains.unsignedDiv 16
  | .u32 => IntegerDomains.unsignedDiv 32
  | .u64 => IntegerDomains.unsignedDiv 64
  | .u128 => IntegerDomains.unsignedDiv 128
  | .u256 => IntegerDomains.unsignedDiv 256
  | .u512 => IntegerDomains.unsignedDiv 512
  | .qm31 => fun lhs rhs => if rhs = 0 then 0 else IntegerDomains.normalizeQm31 (lhs / rhs)
  | _ => fun lhs _ => lhs

def mod : (ty : Ty) -> Ty.denote ty -> Ty.denote ty -> Ty.denote ty
  | .i8 => IntegerDomains.signedMod 8
  | .i16 => IntegerDomains.signedMod 16
  | .i32 => IntegerDomains.signedMod 32
  | .i64 => IntegerDomains.signedMod 64
  | .i128 => IntegerDomains.signedMod 128
  | .u8 => IntegerDomains.unsignedMod 8
  | .u16 => IntegerDomains.unsignedMod 16
  | .u32 => IntegerDomains.unsignedMod 32
  | .u64 => IntegerDomains.unsignedMod 64
  | .u128 => IntegerDomains.unsignedMod 128
  | .u256 => IntegerDomains.unsignedMod 256
  | .u512 => IntegerDomains.unsignedMod 512
  | .qm31 => fun lhs rhs => if rhs = 0 then 0 else IntegerDomains.normalizeQm31 (lhs % rhs)
  | _ => fun lhs _ => lhs

def bitAnd : (ty : Ty) -> Ty.denote ty -> Ty.denote ty -> Ty.denote ty
  | .i8 => IntegerDomains.signedBitAnd 8
  | .i16 => IntegerDomains.signedBitAnd 16
  | .i32 => IntegerDomains.signedBitAnd 32
  | .i64 => IntegerDomains.signedBitAnd 64
  | .i128 => IntegerDomains.signedBitAnd 128
  | .u8 => IntegerDomains.unsignedBitAnd 8
  | .u16 => IntegerDomains.unsignedBitAnd 16
  | .u32 => IntegerDomains.unsignedBitAnd 32
  | .u64 => IntegerDomains.unsignedBitAnd 64
  | .u128 => IntegerDomains.unsignedBitAnd 128
  | .u256 => IntegerDomains.unsignedBitAnd 256
  | .u512 => IntegerDomains.unsignedBitAnd 512
  | .qm31 => fun lhs rhs => IntegerDomains.normalizeQm31 (Nat.land lhs rhs)
  | _ => fun lhs _ => lhs

def bitOr : (ty : Ty) -> Ty.denote ty -> Ty.denote ty -> Ty.denote ty
  | .i8 => IntegerDomains.signedBitOr 8
  | .i16 => IntegerDomains.signedBitOr 16
  | .i32 => IntegerDomains.signedBitOr 32
  | .i64 => IntegerDomains.signedBitOr 64
  | .i128 => IntegerDomains.signedBitOr 128
  | .u8 => IntegerDomains.unsignedBitOr 8
  | .u16 => IntegerDomains.unsignedBitOr 16
  | .u32 => IntegerDomains.unsignedBitOr 32
  | .u64 => IntegerDomains.unsignedBitOr 64
  | .u128 => IntegerDomains.unsignedBitOr 128
  | .u256 => IntegerDomains.unsignedBitOr 256
  | .u512 => IntegerDomains.unsignedBitOr 512
  | .qm31 => fun lhs rhs => IntegerDomains.normalizeQm31 (Nat.lor lhs rhs)
  | _ => fun lhs _ => lhs

def bitXor : (ty : Ty) -> Ty.denote ty -> Ty.denote ty -> Ty.denote ty
  | .i8 => IntegerDomains.signedBitXor 8
  | .i16 => IntegerDomains.signedBitXor 16
  | .i32 => IntegerDomains.signedBitXor 32
  | .i64 => IntegerDomains.signedBitXor 64
  | .i128 => IntegerDomains.signedBitXor 128
  | .u8 => IntegerDomains.unsignedBitXor 8
  | .u16 => IntegerDomains.unsignedBitXor 16
  | .u32 => IntegerDomains.unsignedBitXor 32
  | .u64 => IntegerDomains.unsignedBitXor 64
  | .u128 => IntegerDomains.unsignedBitXor 128
  | .u256 => IntegerDomains.unsignedBitXor 256
  | .u512 => IntegerDomains.unsignedBitXor 512
  | .qm31 => fun lhs rhs => IntegerDomains.normalizeQm31 (Nat.xor lhs rhs)
  | _ => fun lhs _ => lhs

def shl : (ty : Ty) -> Ty.denote ty -> Nat -> Ty.denote ty
  | .i8 => IntegerDomains.signedShl 8
  | .i16 => IntegerDomains.signedShl 16
  | .i32 => IntegerDomains.signedShl 32
  | .i64 => IntegerDomains.signedShl 64
  | .i128 => IntegerDomains.signedShl 128
  | .u8 => IntegerDomains.unsignedShl 8
  | .u16 => IntegerDomains.unsignedShl 16
  | .u32 => IntegerDomains.unsignedShl 32
  | .u64 => IntegerDomains.unsignedShl 64
  | .u128 => IntegerDomains.unsignedShl 128
  | .u256 => IntegerDomains.unsignedShl 256
  | .u512 => IntegerDomains.unsignedShl 512
  | .qm31 => fun lhs shift => IntegerDomains.normalizeQm31 (Nat.shiftLeft lhs shift)
  | _ => fun lhs _ => lhs

def shr : (ty : Ty) -> Ty.denote ty -> Nat -> Ty.denote ty
  | .i8 => IntegerDomains.signedShr 8
  | .i16 => IntegerDomains.signedShr 16
  | .i32 => IntegerDomains.signedShr 32
  | .i64 => IntegerDomains.signedShr 64
  | .i128 => IntegerDomains.signedShr 128
  | .u8 => IntegerDomains.unsignedShr 8
  | .u16 => IntegerDomains.unsignedShr 16
  | .u32 => IntegerDomains.unsignedShr 32
  | .u64 => IntegerDomains.unsignedShr 64
  | .u128 => IntegerDomains.unsignedShr 128
  | .u256 => IntegerDomains.unsignedShr 256
  | .u512 => IntegerDomains.unsignedShr 512
  | .qm31 => fun lhs shift => IntegerDomains.normalizeQm31 (Nat.shiftRight lhs shift)
  | _ => fun lhs _ => lhs

def lt : (ty : Ty) -> Ty.denote ty -> Ty.denote ty -> Bool
  | .i8 => (· < ·)
  | .i16 => (· < ·)
  | .i32 => (· < ·)
  | .i64 => (· < ·)
  | .i128 => (· < ·)
  | .u8 => (· < ·)
  | .u16 => (· < ·)
  | .u32 => (· < ·)
  | .u64 => (· < ·)
  | .u128 => (· < ·)
  | .u256 => (· < ·)
  | .u512 => (· < ·)
  | .qm31 => (· < ·)
  | _ => fun _ _ => false

def le : (ty : Ty) -> Ty.denote ty -> Ty.denote ty -> Bool
  | .i8 => (· ≤ ·)
  | .i16 => (· ≤ ·)
  | .i32 => (· ≤ ·)
  | .i64 => (· ≤ ·)
  | .i128 => (· ≤ ·)
  | .u8 => (· ≤ ·)
  | .u16 => (· ≤ ·)
  | .u32 => (· ≤ ·)
  | .u64 => (· ≤ ·)
  | .u128 => (· ≤ ·)
  | .u256 => (· ≤ ·)
  | .u512 => (· ≤ ·)
  | .qm31 => (· ≤ ·)
  | _ => fun _ _ => false

def isZero : (ty : Ty) -> Ty.denote ty -> Bool
  | .i8 => (· = 0)
  | .i16 => (· = 0)
  | .i32 => (· = 0)
  | .i64 => (· = 0)
  | .i128 => (· = 0)
  | .u8 => (· = 0)
  | .u16 => (· = 0)
  | .u32 => (· = 0)
  | .u64 => (· = 0)
  | .u128 => (· = 0)
  | .u256 => (· = 0)
  | .u512 => (· = 0)
  | .qm31 => (· = 0)
  | .bool => (!·)
  | _ => fun _ => false

end IntTySemantics

structure EvalContext where
  feltVars : String -> Int := fun _ => 0
  i8Vars : String -> Int := fun _ => 0
  i16Vars : String -> Int := fun _ => 0
  i32Vars : String -> Int := fun _ => 0
  i64Vars : String -> Int := fun _ => 0
  i128Vars : String -> Int := fun _ => 0
  u128Vars : String -> Nat := fun _ => 0
  u512Vars : String -> Nat := fun _ => 0
  u8Vars : String -> Nat := fun _ => 0
  u16Vars : String -> Nat := fun _ => 0
  u32Vars : String -> Nat := fun _ => 0
  u64Vars : String -> Nat := fun _ => 0
  u256Vars : String -> Nat := fun _ => 0
  qm31Vars : String -> Nat := fun _ => 0
  boolVars : String -> Bool := fun _ => false
  feltStorage : String -> Int := fun _ => 0
  i8Storage : String -> Int := fun _ => 0
  i16Storage : String -> Int := fun _ => 0
  i32Storage : String -> Int := fun _ => 0
  i64Storage : String -> Int := fun _ => 0
  i128Storage : String -> Int := fun _ => 0
  u128Storage : String -> Nat := fun _ => 0
  u512Storage : String -> Nat := fun _ => 0
  u8Storage : String -> Nat := fun _ => 0
  u16Storage : String -> Nat := fun _ => 0
  u32Storage : String -> Nat := fun _ => 0
  u64Storage : String -> Nat := fun _ => 0
  u256Storage : String -> Nat := fun _ => 0
  qm31Storage : String -> Nat := fun _ => 0
  boolStorage : String -> Bool := fun _ => false

namespace EvalContext

def supportsRuntimeBinding : Ty -> Bool
  | .felt252 | .u128 | .u256 | .u512 | .bool => true
  | .i8 | .i16 | .i32 | .i64 | .i128 => true
  | .u8 | .u16 | .u32 | .u64 => true
  | .qm31 => true
  | _ => false

def unsupportedDomainMessage (op : String) (ty : Ty) (name : String) : String :=
  s!"unsupported evaluator {op} for type '{Ty.toCairo ty}' (family '{Ty.familyTag ty}') at symbol '{name}'"

def normalizeRuntimeValue (ty : Ty) : Ty.denote ty -> Ty.denote ty :=
  match ty with
  | .felt252 => id
  | .i8 => IntegerDomains.normalizeSigned 8
  | .i16 => IntegerDomains.normalizeSigned 16
  | .i32 => IntegerDomains.normalizeSigned 32
  | .i64 => IntegerDomains.normalizeSigned 64
  | .i128 => IntegerDomains.normalizeSigned 128
  | .u128 => IntegerDomains.normalizeUnsigned 128
  | .u512 => IntegerDomains.normalizeUnsigned 512
  | .u8 => IntegerDomains.normalizeUnsigned 8
  | .u16 => IntegerDomains.normalizeUnsigned 16
  | .u32 => IntegerDomains.normalizeUnsigned 32
  | .u64 => IntegerDomains.normalizeUnsigned 64
  | .u256 => IntegerDomains.normalizeUnsigned 256
  | .qm31 => IntegerDomains.normalizeQm31
  | .bool => id
  | .tuple _ => id
  | .structTy _ => id
  | .enumTy _ => id
  | .array _ => id
  | .span _ => id
  | .nullable _ => id
  | .boxed _ => id
  | .dict _ _ => id
  | .nonZero _ => id
  | .rangeCheck => id
  | .gasBuiltin => id
  | .segmentArena => id
  | .panicSignal => id

def readVar (ctx : EvalContext) (ty : Ty) (name : String) : Ty.denote ty :=
  match ty with
  | .felt252 => ctx.feltVars name
  | .i8 => ctx.i8Vars name
  | .i16 => ctx.i16Vars name
  | .i32 => ctx.i32Vars name
  | .i64 => ctx.i64Vars name
  | .i128 => ctx.i128Vars name
  | .u128 => ctx.u128Vars name
  | .u512 => ctx.u512Vars name
  | .u8 => ctx.u8Vars name
  | .u16 => ctx.u16Vars name
  | .u32 => ctx.u32Vars name
  | .u64 => ctx.u64Vars name
  | .u256 => ctx.u256Vars name
  | .qm31 => ctx.qm31Vars name
  | .bool => ctx.boolVars name
  | .tuple _ => ()
  | .structTy _ => ()
  | .enumTy _ => ()
  | .array _ => ()
  | .span _ => ()
  | .nullable _ => ()
  | .boxed _ => ()
  | .dict _ _ => ()
  | .nonZero _ => ()
  | .rangeCheck => ()
  | .gasBuiltin => ()
  | .segmentArena => ()
  | .panicSignal => ()

def readVarStrict (ctx : EvalContext) (ty : Ty) (name : String) : Except String (Ty.denote ty) :=
  if supportsRuntimeBinding ty then
    .ok (normalizeRuntimeValue ty (readVar ctx ty name))
  else
    .error (unsupportedDomainMessage "variable read" ty name)

def readStorage (ctx : EvalContext) (ty : Ty) (name : String) : Ty.denote ty :=
  match ty with
  | .felt252 => ctx.feltStorage name
  | .i8 => ctx.i8Storage name
  | .i16 => ctx.i16Storage name
  | .i32 => ctx.i32Storage name
  | .i64 => ctx.i64Storage name
  | .i128 => ctx.i128Storage name
  | .u128 => ctx.u128Storage name
  | .u512 => ctx.u512Storage name
  | .u8 => ctx.u8Storage name
  | .u16 => ctx.u16Storage name
  | .u32 => ctx.u32Storage name
  | .u64 => ctx.u64Storage name
  | .u256 => ctx.u256Storage name
  | .qm31 => ctx.qm31Storage name
  | .bool => ctx.boolStorage name
  | .tuple _ => ()
  | .structTy _ => ()
  | .enumTy _ => ()
  | .array _ => ()
  | .span _ => ()
  | .nullable _ => ()
  | .boxed _ => ()
  | .dict _ _ => ()
  | .nonZero _ => ()
  | .rangeCheck => ()
  | .gasBuiltin => ()
  | .segmentArena => ()
  | .panicSignal => ()

def readStorageStrict (ctx : EvalContext) (ty : Ty) (name : String) : Except String (Ty.denote ty) :=
  if supportsRuntimeBinding ty then
    .ok (normalizeRuntimeValue ty (readStorage ctx ty name))
  else
    .error (unsupportedDomainMessage "storage read" ty name)

def bindVar (ctx : EvalContext) (ty : Ty) (name : String) (value : Ty.denote ty) : EvalContext :=
  match ty with
  | .felt252 =>
      { ctx with feltVars := fun n => if n = name then value else ctx.feltVars n }
  | .i8 =>
      { ctx with i8Vars := fun n => if n = name then value else ctx.i8Vars n }
  | .i16 =>
      { ctx with i16Vars := fun n => if n = name then value else ctx.i16Vars n }
  | .i32 =>
      { ctx with i32Vars := fun n => if n = name then value else ctx.i32Vars n }
  | .i64 =>
      { ctx with i64Vars := fun n => if n = name then value else ctx.i64Vars n }
  | .i128 =>
      { ctx with i128Vars := fun n => if n = name then value else ctx.i128Vars n }
  | .u128 =>
      { ctx with u128Vars := fun n => if n = name then value else ctx.u128Vars n }
  | .u512 =>
      { ctx with u512Vars := fun n => if n = name then value else ctx.u512Vars n }
  | .u8 =>
      { ctx with u8Vars := fun n => if n = name then value else ctx.u8Vars n }
  | .u16 =>
      { ctx with u16Vars := fun n => if n = name then value else ctx.u16Vars n }
  | .u32 =>
      { ctx with u32Vars := fun n => if n = name then value else ctx.u32Vars n }
  | .u64 =>
      { ctx with u64Vars := fun n => if n = name then value else ctx.u64Vars n }
  | .u256 => { ctx with u256Vars := fun n => if n = name then value else ctx.u256Vars n }
  | .qm31 => { ctx with qm31Vars := fun n => if n = name then value else ctx.qm31Vars n }
  | .bool => { ctx with boolVars := fun n => if n = name then value else ctx.boolVars n }
  | .tuple _ => ctx
  | .structTy _ => ctx
  | .enumTy _ => ctx
  | .array _ => ctx
  | .span _ => ctx
  | .nullable _ => ctx
  | .boxed _ => ctx
  | .dict _ _ => ctx
  | .nonZero _ => ctx
  | .rangeCheck => ctx
  | .gasBuiltin => ctx
  | .segmentArena => ctx
  | .panicSignal => ctx

def bindVarStrict (ctx : EvalContext) (ty : Ty) (name : String) (value : Ty.denote ty) :
    Except String EvalContext :=
  if supportsRuntimeBinding ty then
    .ok (bindVar ctx ty name (normalizeRuntimeValue ty value))
  else
    .error (unsupportedDomainMessage "variable bind" ty name)

def bindStorage (ctx : EvalContext) (ty : Ty) (name : String) (value : Ty.denote ty) : EvalContext :=
  match ty with
  | .felt252 =>
      { ctx with feltStorage := fun n => if n = name then value else ctx.feltStorage n }
  | .i8 =>
      { ctx with i8Storage := fun n => if n = name then value else ctx.i8Storage n }
  | .i16 =>
      { ctx with i16Storage := fun n => if n = name then value else ctx.i16Storage n }
  | .i32 =>
      { ctx with i32Storage := fun n => if n = name then value else ctx.i32Storage n }
  | .i64 =>
      { ctx with i64Storage := fun n => if n = name then value else ctx.i64Storage n }
  | .i128 =>
      { ctx with i128Storage := fun n => if n = name then value else ctx.i128Storage n }
  | .u128 =>
      { ctx with u128Storage := fun n => if n = name then value else ctx.u128Storage n }
  | .u512 =>
      { ctx with u512Storage := fun n => if n = name then value else ctx.u512Storage n }
  | .u8 =>
      { ctx with u8Storage := fun n => if n = name then value else ctx.u8Storage n }
  | .u16 =>
      { ctx with u16Storage := fun n => if n = name then value else ctx.u16Storage n }
  | .u32 =>
      { ctx with u32Storage := fun n => if n = name then value else ctx.u32Storage n }
  | .u64 =>
      { ctx with u64Storage := fun n => if n = name then value else ctx.u64Storage n }
  | .u256 => { ctx with u256Storage := fun n => if n = name then value else ctx.u256Storage n }
  | .qm31 =>
      { ctx with qm31Storage := fun n => if n = name then value else ctx.qm31Storage n }
  | .bool => { ctx with boolStorage := fun n => if n = name then value else ctx.boolStorage n }
  | .tuple _ => ctx
  | .structTy _ => ctx
  | .enumTy _ => ctx
  | .array _ => ctx
  | .span _ => ctx
  | .nullable _ => ctx
  | .boxed _ => ctx
  | .dict _ _ => ctx
  | .nonZero _ => ctx
  | .rangeCheck => ctx
  | .gasBuiltin => ctx
  | .segmentArena => ctx
  | .panicSignal => ctx

def bindStorageStrict (ctx : EvalContext) (ty : Ty) (name : String) (value : Ty.denote ty) :
    Except String EvalContext :=
  if supportsRuntimeBinding ty then
    .ok (bindStorage ctx ty name (normalizeRuntimeValue ty value))
  else
    .error (unsupportedDomainMessage "storage bind" ty name)

def castUnsupportedMessage (srcTy dstTy : Ty) : String :=
  s!"unsupported evaluator cast from '{Ty.toCairo srcTy}' to '{Ty.toCairo dstTy}'"

def castDomainViolationMessage (srcTy dstTy : Ty) (detail : String) : String :=
  s!"invalid cast from '{Ty.toCairo srcTy}' to '{Ty.toCairo dstTy}': {detail}"

def isCastLegal (srcTy dstTy : Ty) : Bool :=
  supportsRuntimeBinding srcTy && supportsRuntimeBinding dstTy

def runtimeValueToInt (srcTy : Ty) (value : Ty.denote srcTy) : Except String Int :=
  match srcTy with
  | .felt252 => .ok value
  | .i8 => .ok value
  | .i16 => .ok value
  | .i32 => .ok value
  | .i64 => .ok value
  | .i128 => .ok value
  | .u128 => .ok (Int.ofNat value)
  | .u512 => .ok (Int.ofNat value)
  | .u8 => .ok (Int.ofNat value)
  | .u16 => .ok (Int.ofNat value)
  | .u32 => .ok (Int.ofNat value)
  | .u64 => .ok (Int.ofNat value)
  | .u256 => .ok (Int.ofNat value)
  | .qm31 => .ok (Int.ofNat value)
  | .bool => .ok (if value then 1 else 0)
  | _ => .error (castUnsupportedMessage srcTy srcTy)

def requireNonNegativeNat (srcTy dstTy : Ty) (raw : Int) : Except String Nat :=
  if raw < 0 then
    .error (castDomainViolationMessage srcTy dstTy s!"negative source value '{raw}'")
  else
    .ok raw.toNat

def castIntToRuntime (srcTy dstTy : Ty) (raw : Int) : Except String (Ty.denote dstTy) :=
  match dstTy with
  | .felt252 => .ok raw
  | .i8 => .ok (IntegerDomains.normalizeSigned 8 raw)
  | .i16 => .ok (IntegerDomains.normalizeSigned 16 raw)
  | .i32 => .ok (IntegerDomains.normalizeSigned 32 raw)
  | .i64 => .ok (IntegerDomains.normalizeSigned 64 raw)
  | .i128 => .ok (IntegerDomains.normalizeSigned 128 raw)
  | .u8 => do
      let natValue <- requireNonNegativeNat srcTy dstTy raw
      pure (IntegerDomains.normalizeUnsigned 8 natValue)
  | .u16 => do
      let natValue <- requireNonNegativeNat srcTy dstTy raw
      pure (IntegerDomains.normalizeUnsigned 16 natValue)
  | .u32 => do
      let natValue <- requireNonNegativeNat srcTy dstTy raw
      pure (IntegerDomains.normalizeUnsigned 32 natValue)
  | .u64 => do
      let natValue <- requireNonNegativeNat srcTy dstTy raw
      pure (IntegerDomains.normalizeUnsigned 64 natValue)
  | .u128 => do
      let natValue <- requireNonNegativeNat srcTy dstTy raw
      pure (IntegerDomains.normalizeUnsigned 128 natValue)
  | .u512 => do
      let natValue <- requireNonNegativeNat srcTy dstTy raw
      pure (IntegerDomains.normalizeUnsigned 512 natValue)
  | .u256 => do
      let natValue <- requireNonNegativeNat srcTy dstTy raw
      pure (IntegerDomains.normalizeUnsigned 256 natValue)
  | .qm31 =>
      let modulus : Int := Int.ofNat IntegerDomains.qm31Modulus
      let residue := Int.emod raw modulus
      .ok residue.toNat
  | .bool =>
      if raw = 0 then
        .ok false
      else if raw = 1 then
        .ok true
      else
        .error (castDomainViolationMessage srcTy dstTy s!"expected canonical boolean value 0 or 1, got '{raw}'")
  | _ => .error (castUnsupportedMessage srcTy dstTy)

def castStrict (srcTy dstTy : Ty) (value : Ty.denote srcTy) : Except String (Ty.denote dstTy) := do
  if isCastLegal srcTy dstTy then
    let raw <- runtimeValueToInt srcTy value
    castIntToRuntime srcTy dstTy raw
  else
    .error (castUnsupportedMessage srcTy dstTy)

theorem castStrict_illegal_failfast
    (srcTy dstTy : Ty)
    (value : Ty.denote srcTy)
    (hIllegal : isCastLegal srcTy dstTy = false) :
    castStrict srcTy dstTy value = .error (castUnsupportedMessage srcTy dstTy) := by
  simp [castStrict, hIllegal]

theorem readVar_bindVar_same (ctx : EvalContext) (ty : Ty) (name : String) (value : Ty.denote ty) :
    readVar (bindVar ctx ty name value) ty name = value := by
  cases ty <;> simp [readVar, bindVar]

theorem readVar_bindVar_type_non_interference
    (ctx : EvalContext)
    (tyWrite tyRead : Ty)
    (nameWrite nameRead : String)
    (value : Ty.denote tyWrite)
    (hTy : tyRead ≠ tyWrite) :
    readVar (bindVar ctx tyWrite nameWrite value) tyRead nameRead = readVar ctx tyRead nameRead := by
  cases tyWrite <;> cases tyRead <;> simp [readVar, bindVar] at hTy ⊢ <;> contradiction

theorem readStorage_bindStorage_type_non_interference
    (ctx : EvalContext)
    (tyWrite tyRead : Ty)
    (nameWrite nameRead : String)
    (value : Ty.denote tyWrite)
    (hTy : tyRead ≠ tyWrite) :
    readStorage (bindStorage ctx tyWrite nameWrite value) tyRead nameRead = readStorage ctx tyRead nameRead := by
  cases tyWrite <;> cases tyRead <;> simp [readStorage, bindStorage] at hTy ⊢ <;> contradiction

theorem readVarStrict_unsupported_failfast
    (ctx : EvalContext)
    (ty : Ty)
    (name : String)
    (hUnsupported : supportsRuntimeBinding ty = false) :
    readVarStrict ctx ty name = .error (unsupportedDomainMessage "variable read" ty name) := by
  simp [readVarStrict, hUnsupported]

theorem readStorageStrict_unsupported_failfast
    (ctx : EvalContext)
    (ty : Ty)
    (name : String)
    (hUnsupported : supportsRuntimeBinding ty = false) :
    readStorageStrict ctx ty name = .error (unsupportedDomainMessage "storage read" ty name) := by
  simp [readStorageStrict, hUnsupported]

theorem bindVarStrict_unsupported_failfast
    (ctx : EvalContext)
    (ty : Ty)
    (name : String)
    (value : Ty.denote ty)
    (hUnsupported : supportsRuntimeBinding ty = false) :
    bindVarStrict ctx ty name value = .error (unsupportedDomainMessage "variable bind" ty name) := by
  simp [bindVarStrict, hUnsupported]

theorem bindStorageStrict_unsupported_failfast
    (ctx : EvalContext)
    (ty : Ty)
    (name : String)
    (value : Ty.denote ty)
    (hUnsupported : supportsRuntimeBinding ty = false) :
    bindStorageStrict ctx ty name value = .error (unsupportedDomainMessage "storage bind" ty name) := by
  simp [bindStorageStrict, hUnsupported]

end EvalContext

namespace ResourceCarriers

def merge (lhs rhs : ResourceCarriers) : ResourceCarriers :=
  {
    rangeCheck := lhs.rangeCheck + rhs.rangeCheck
    gas := lhs.gas + rhs.gas
    segmentArena := lhs.segmentArena + rhs.segmentArena
    panicChannel :=
      match rhs.panicChannel with
      | some value => some value
      | none => lhs.panicChannel
  }

def bumpGas (state : ResourceCarriers) (delta : Nat := 1) : ResourceCarriers :=
  { state with gas := state.gas + delta }

def bumpRangeCheck (state : ResourceCarriers) (delta : Nat := 1) : ResourceCarriers :=
  { state with rangeCheck := state.rangeCheck + delta }

end ResourceCarriers

def evalExpr (ctx : EvalContext) : IRExpr ty -> Ty.denote ty
  | .var name => EvalContext.readVar ctx ty name
  | .storageRead name => EvalContext.readStorage ctx ty name
  | .litU128 value => value
  | .litU256 value => value
  | .litBool value => value
  | .litFelt252 value => value
  | .litInt ty value => IntTySemantics.normalize ty value
  | .addFelt252 lhs rhs => evalExpr ctx lhs + evalExpr ctx rhs
  | .subFelt252 lhs rhs => evalExpr ctx lhs - evalExpr ctx rhs
  | .mulFelt252 lhs rhs => evalExpr ctx lhs * evalExpr ctx rhs
  | .addInt ty lhs rhs => IntTySemantics.add ty (evalExpr ctx lhs) (evalExpr ctx rhs)
  | .subInt ty lhs rhs => IntTySemantics.sub ty (evalExpr ctx lhs) (evalExpr ctx rhs)
  | .mulInt ty lhs rhs => IntTySemantics.mul ty (evalExpr ctx lhs) (evalExpr ctx rhs)
  | .divInt ty lhs rhs => IntTySemantics.div ty (evalExpr ctx lhs) (evalExpr ctx rhs)
  | .modInt ty lhs rhs => IntTySemantics.mod ty (evalExpr ctx lhs) (evalExpr ctx rhs)
  | .bitAndInt ty lhs rhs => IntTySemantics.bitAnd ty (evalExpr ctx lhs) (evalExpr ctx rhs)
  | .bitOrInt ty lhs rhs => IntTySemantics.bitOr ty (evalExpr ctx lhs) (evalExpr ctx rhs)
  | .bitXorInt ty lhs rhs => IntTySemantics.bitXor ty (evalExpr ctx lhs) (evalExpr ctx rhs)
  | .shlInt ty lhs shift => IntTySemantics.shl ty (evalExpr ctx lhs) shift
  | .shrInt ty lhs shift => IntTySemantics.shr ty (evalExpr ctx lhs) shift
  | .addU128 lhs rhs => evalExpr ctx lhs + evalExpr ctx rhs
  | .subU128 lhs rhs => evalExpr ctx lhs - evalExpr ctx rhs
  | .mulU128 lhs rhs => evalExpr ctx lhs * evalExpr ctx rhs
  | .divU128 lhs rhs => IntegerDomains.unsignedDiv 128 (evalExpr ctx lhs) (evalExpr ctx rhs)
  | .modU128 lhs rhs => IntegerDomains.unsignedMod 128 (evalExpr ctx lhs) (evalExpr ctx rhs)
  | .bitAndU128 lhs rhs => IntegerDomains.unsignedBitAnd 128 (evalExpr ctx lhs) (evalExpr ctx rhs)
  | .bitOrU128 lhs rhs => IntegerDomains.unsignedBitOr 128 (evalExpr ctx lhs) (evalExpr ctx rhs)
  | .bitXorU128 lhs rhs => IntegerDomains.unsignedBitXor 128 (evalExpr ctx lhs) (evalExpr ctx rhs)
  | .shlU128 lhs shift => IntegerDomains.unsignedShl 128 (evalExpr ctx lhs) shift
  | .shrU128 lhs shift => IntegerDomains.unsignedShr 128 (evalExpr ctx lhs) shift
  | .addU256 lhs rhs => evalExpr ctx lhs + evalExpr ctx rhs
  | .subU256 lhs rhs => evalExpr ctx lhs - evalExpr ctx rhs
  | .mulU256 lhs rhs => evalExpr ctx lhs * evalExpr ctx rhs
  | .divU256 lhs rhs => IntegerDomains.unsignedDiv 256 (evalExpr ctx lhs) (evalExpr ctx rhs)
  | .modU256 lhs rhs => IntegerDomains.unsignedMod 256 (evalExpr ctx lhs) (evalExpr ctx rhs)
  | .bitAndU256 lhs rhs => IntegerDomains.unsignedBitAnd 256 (evalExpr ctx lhs) (evalExpr ctx rhs)
  | .bitOrU256 lhs rhs => IntegerDomains.unsignedBitOr 256 (evalExpr ctx lhs) (evalExpr ctx rhs)
  | .bitXorU256 lhs rhs => IntegerDomains.unsignedBitXor 256 (evalExpr ctx lhs) (evalExpr ctx rhs)
  | .shlU256 lhs shift => IntegerDomains.unsignedShl 256 (evalExpr ctx lhs) shift
  | .shrU256 lhs shift => IntegerDomains.unsignedShr 256 (evalExpr ctx lhs) shift
  | .u256FromLimbs low high => IntegerDomains.u256FromLimbs (evalExpr ctx low) (evalExpr ctx high)
  | .u256Low value => IntegerDomains.u256Low (evalExpr ctx value)
  | .u256High value => IntegerDomains.u256High (evalExpr ctx value)
  | @IRExpr.eq ty lhs rhs =>
      by
        let _ : DecidableEq (Ty.denote ty) := Ty.denoteDecidableEq ty
        exact decide (evalExpr ctx lhs = evalExpr ctx rhs)
  | .ltInt ty lhs rhs => IntTySemantics.lt ty (evalExpr ctx lhs) (evalExpr ctx rhs)
  | .leInt ty lhs rhs => IntTySemantics.le ty (evalExpr ctx lhs) (evalExpr ctx rhs)
  | .ltU128 lhs rhs => evalExpr ctx lhs < evalExpr ctx rhs
  | .leU128 lhs rhs => evalExpr ctx lhs <= evalExpr ctx rhs
  | .ltU256 lhs rhs => evalExpr ctx lhs < evalExpr ctx rhs
  | .leU256 lhs rhs => evalExpr ctx lhs <= evalExpr ctx rhs
  | .ite cond thenBranch elseBranch =>
      if evalExpr ctx cond then evalExpr ctx thenBranch else evalExpr ctx elseBranch
  | .letE name boundTy bound body =>
      let value := evalExpr ctx bound
      let ctx' := EvalContext.bindVar ctx boundTy name value
      evalExpr ctx' body

def unsupportedLaneOpMessage (opName : String) (ty : Ty) : String :=
  s!"unsupported {opName} operation for type '{Ty.toCairo ty}'"

def divisionByZeroLaneMessage (ty : Ty) : String :=
  s!"division by zero in {Ty.toCairo ty} lane"

def moduloByZeroLaneMessage (ty : Ty) : String :=
  s!"modulo by zero in {Ty.toCairo ty} lane"

def evalExprStrict (ctx : EvalContext) : IRExpr ty -> Except String (Ty.denote ty)
  | .var name => EvalContext.readVarStrict ctx ty name
  | .storageRead name => EvalContext.readStorageStrict ctx ty name
  | .litU128 value => .ok (IntegerDomains.normalizeUnsigned 128 value)
  | .litU256 value => .ok (IntegerDomains.normalizeUnsigned 256 value)
  | .litBool value => .ok value
  | .litFelt252 value => .ok value
  | .litInt ty value => .ok (IntTySemantics.normalize ty value)
  | .addFelt252 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      pure (left + right)
  | .subFelt252 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      pure (left - right)
  | .mulFelt252 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      pure (left * right)
  | .addInt ty lhs rhs => do
      if !(IntTySemantics.isSupportedIntTy ty) then
        .error (unsupportedLaneOpMessage "add" ty)
      else
        let left <- evalExprStrict ctx lhs
        let right <- evalExprStrict ctx rhs
        pure (IntTySemantics.add ty left right)
  | .subInt ty lhs rhs => do
      if !(IntTySemantics.isSupportedIntTy ty) then
        .error (unsupportedLaneOpMessage "sub" ty)
      else
        let left <- evalExprStrict ctx lhs
        let right <- evalExprStrict ctx rhs
        pure (IntTySemantics.sub ty left right)
  | .mulInt ty lhs rhs => do
      if !(IntTySemantics.isSupportedIntTy ty) then
        .error (unsupportedLaneOpMessage "mul" ty)
      else
        let left <- evalExprStrict ctx lhs
        let right <- evalExprStrict ctx rhs
        pure (IntTySemantics.mul ty left right)
  | .divInt ty lhs rhs => do
      if !(IntTySemantics.supportsDivMod ty) then
        .error (unsupportedLaneOpMessage "division" ty)
      else
        let left <- evalExprStrict ctx lhs
        let right <- evalExprStrict ctx rhs
        if IntTySemantics.isZero ty right then
          .error (divisionByZeroLaneMessage ty)
        else
          pure (IntTySemantics.div ty left right)
  | .modInt ty lhs rhs => do
      if !(IntTySemantics.supportsDivMod ty) then
        .error (unsupportedLaneOpMessage "modulo" ty)
      else
        let left <- evalExprStrict ctx lhs
        let right <- evalExprStrict ctx rhs
        if IntTySemantics.isZero ty right then
          .error (moduloByZeroLaneMessage ty)
        else
          pure (IntTySemantics.mod ty left right)
  | .bitAndInt ty lhs rhs => do
      if !(IntTySemantics.supportsBitwise ty) then
        .error (unsupportedLaneOpMessage "bitwise-and" ty)
      else
        let left <- evalExprStrict ctx lhs
        let right <- evalExprStrict ctx rhs
        pure (IntTySemantics.bitAnd ty left right)
  | .bitOrInt ty lhs rhs => do
      if !(IntTySemantics.supportsBitwise ty) then
        .error (unsupportedLaneOpMessage "bitwise-or" ty)
      else
        let left <- evalExprStrict ctx lhs
        let right <- evalExprStrict ctx rhs
        pure (IntTySemantics.bitOr ty left right)
  | .bitXorInt ty lhs rhs => do
      if !(IntTySemantics.supportsBitwise ty) then
        .error (unsupportedLaneOpMessage "bitwise-xor" ty)
      else
        let left <- evalExprStrict ctx lhs
        let right <- evalExprStrict ctx rhs
        pure (IntTySemantics.bitXor ty left right)
  | .shlInt ty lhs shift => do
      if !(IntTySemantics.supportsBitwise ty) then
        .error (unsupportedLaneOpMessage "shift-left" ty)
      else
        let left <- evalExprStrict ctx lhs
        pure (IntTySemantics.shl ty left shift)
  | .shrInt ty lhs shift => do
      if !(IntTySemantics.supportsBitwise ty) then
        .error (unsupportedLaneOpMessage "shift-right" ty)
      else
        let left <- evalExprStrict ctx lhs
        pure (IntTySemantics.shr ty left shift)
  | .addU128 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      pure (IntegerDomains.unsignedAdd 128 left right)
  | .subU128 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      pure (IntegerDomains.unsignedSub 128 left right)
  | .mulU128 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      pure (IntegerDomains.unsignedMul 128 left right)
  | .divU128 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      if right = 0 then
        .error "division by zero in u128 lane"
      else
        pure (IntegerDomains.unsignedDiv 128 left right)
  | .modU128 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      if right = 0 then
        .error "modulo by zero in u128 lane"
      else
        pure (IntegerDomains.unsignedMod 128 left right)
  | .bitAndU128 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      pure (IntegerDomains.unsignedBitAnd 128 left right)
  | .bitOrU128 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      pure (IntegerDomains.unsignedBitOr 128 left right)
  | .bitXorU128 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      pure (IntegerDomains.unsignedBitXor 128 left right)
  | .shlU128 lhs shift => do
      let left <- evalExprStrict ctx lhs
      pure (IntegerDomains.unsignedShl 128 left shift)
  | .shrU128 lhs shift => do
      let left <- evalExprStrict ctx lhs
      pure (IntegerDomains.unsignedShr 128 left shift)
  | .addU256 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      pure (IntegerDomains.unsignedAdd 256 left right)
  | .subU256 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      pure (IntegerDomains.unsignedSub 256 left right)
  | .mulU256 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      pure (IntegerDomains.unsignedMul 256 left right)
  | .divU256 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      if right = 0 then
        .error "division by zero in u256 lane"
      else
        pure (IntegerDomains.unsignedDiv 256 left right)
  | .modU256 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      if right = 0 then
        .error "modulo by zero in u256 lane"
      else
        pure (IntegerDomains.unsignedMod 256 left right)
  | .bitAndU256 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      pure (IntegerDomains.unsignedBitAnd 256 left right)
  | .bitOrU256 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      pure (IntegerDomains.unsignedBitOr 256 left right)
  | .bitXorU256 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      pure (IntegerDomains.unsignedBitXor 256 left right)
  | .shlU256 lhs shift => do
      let left <- evalExprStrict ctx lhs
      pure (IntegerDomains.unsignedShl 256 left shift)
  | .shrU256 lhs shift => do
      let left <- evalExprStrict ctx lhs
      pure (IntegerDomains.unsignedShr 256 left shift)
  | .u256FromLimbs low high => do
      let lowValue <- evalExprStrict ctx low
      let highValue <- evalExprStrict ctx high
      pure (IntegerDomains.u256FromLimbs lowValue highValue)
  | .u256Low value => do
      let raw <- evalExprStrict ctx value
      pure (IntegerDomains.u256Low raw)
  | .u256High value => do
      let raw <- evalExprStrict ctx value
      pure (IntegerDomains.u256High raw)
  | @IRExpr.eq ty lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      let _ : DecidableEq (Ty.denote ty) := Ty.denoteDecidableEq ty
      pure (decide (left = right))
  | .ltInt ty lhs rhs => do
      if !(IntTySemantics.isSupportedIntTy ty) then
        .error (unsupportedLaneOpMessage "lt" ty)
      else
        let left <- evalExprStrict ctx lhs
        let right <- evalExprStrict ctx rhs
        pure (IntTySemantics.lt ty left right)
  | .leInt ty lhs rhs => do
      if !(IntTySemantics.isSupportedIntTy ty) then
        .error (unsupportedLaneOpMessage "le" ty)
      else
        let left <- evalExprStrict ctx lhs
        let right <- evalExprStrict ctx rhs
        pure (IntTySemantics.le ty left right)
  | .ltU128 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      pure (left < right)
  | .leU128 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      pure (left <= right)
  | .ltU256 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      pure (left < right)
  | .leU256 lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      pure (left <= right)
  | .ite cond thenBranch elseBranch => do
      let condition <- evalExprStrict ctx cond
      if condition then
        evalExprStrict ctx thenBranch
      else
        evalExprStrict ctx elseBranch
  | .letE name boundTy bound body => do
      let value <- evalExprStrict ctx bound
      let ctx' <- EvalContext.bindVarStrict ctx boundTy name value
      evalExprStrict ctx' body

def resourceCost : IRExpr ty -> ResourceCarriers
  | .var _ => {}
  | .storageRead _ => {}
  | .litU128 _ => {}
  | .litU256 _ => {}
  | .litBool _ => {}
  | .litFelt252 _ => {}
  | .litInt _ _ => {}
  | .addFelt252 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .subFelt252 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .mulFelt252 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .addInt _ lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .subInt _ lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .mulInt _ lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .divInt _ lhs rhs =>
      ResourceCarriers.bumpRangeCheck <| ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .modInt _ lhs rhs =>
      ResourceCarriers.bumpRangeCheck <| ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .bitAndInt _ lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .bitOrInt _ lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .bitXorInt _ lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .shlInt _ lhs _ =>
      ResourceCarriers.bumpGas <| resourceCost lhs
  | .shrInt _ lhs _ =>
      ResourceCarriers.bumpGas <| resourceCost lhs
  | .addU128 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .subU128 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .mulU128 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .divU128 lhs rhs =>
      ResourceCarriers.bumpRangeCheck <| ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .modU128 lhs rhs =>
      ResourceCarriers.bumpRangeCheck <| ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .bitAndU128 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .bitOrU128 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .bitXorU128 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .shlU128 lhs _ =>
      ResourceCarriers.bumpGas <| resourceCost lhs
  | .shrU128 lhs _ =>
      ResourceCarriers.bumpGas <| resourceCost lhs
  | .addU256 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .subU256 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .mulU256 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .divU256 lhs rhs =>
      ResourceCarriers.bumpRangeCheck <| ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .modU256 lhs rhs =>
      ResourceCarriers.bumpRangeCheck <| ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .bitAndU256 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .bitOrU256 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .bitXorU256 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .shlU256 lhs _ =>
      ResourceCarriers.bumpGas <| resourceCost lhs
  | .shrU256 lhs _ =>
      ResourceCarriers.bumpGas <| resourceCost lhs
  | .u256FromLimbs low high =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost low) (resourceCost high)
  | .u256Low value =>
      ResourceCarriers.bumpGas <| resourceCost value
  | .u256High value =>
      ResourceCarriers.bumpGas <| resourceCost value
  | .eq lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .ltInt _ lhs rhs =>
      ResourceCarriers.bumpRangeCheck <| ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .leInt _ lhs rhs =>
      ResourceCarriers.bumpRangeCheck <| ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .ltU128 lhs rhs =>
      ResourceCarriers.bumpRangeCheck <| ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .leU128 lhs rhs =>
      ResourceCarriers.bumpRangeCheck <| ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .ltU256 lhs rhs =>
      ResourceCarriers.bumpRangeCheck <| ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .leU256 lhs rhs =>
      ResourceCarriers.bumpRangeCheck <| ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .ite cond thenBranch elseBranch =>
      ResourceCarriers.bumpGas <|
        ResourceCarriers.merge
          (resourceCost cond)
          (ResourceCarriers.merge (resourceCost thenBranch) (resourceCost elseBranch))
  | .letE _ _ bound body =>
      ResourceCarriers.merge (resourceCost bound) (resourceCost body)

def evalExprWithResources (ctx : EvalContext) (resources : ResourceCarriers) (expr : IRExpr ty) :
    Ty.denote ty × ResourceCarriers :=
  let value := evalExpr ctx expr
  let consumed := resourceCost expr
  (value, ResourceCarriers.merge resources consumed)

def evalEffectExpr (ctx : EvalContext) (effectExpr : EffectExpr ty) :
    Ty.denote ty × ResourceCarriers :=
  evalExprWithResources ctx effectExpr.resources effectExpr.expr

structure SemanticState where
  context : EvalContext
  resources : ResourceCarriers := {}
  failure : Option String := none

def evalExprState (state : SemanticState) (expr : IRExpr ty) :
    Except String (Ty.denote ty × SemanticState) := do
  match state.failure with
  | some err => .error err
  | none =>
      let value := evalExpr state.context expr
      let consumed := resourceCost expr
      let nextState : SemanticState :=
        { state with resources := ResourceCarriers.merge state.resources consumed }
      .ok (value, nextState)

def evalExprStateStrict (state : SemanticState) (expr : IRExpr ty) :
    Except String (Ty.denote ty × SemanticState) := do
  match state.failure with
  | some err => .error err
  | none =>
      let value <- evalExprStrict state.context expr
      let consumed := resourceCost expr
      let nextState : SemanticState :=
        { state with resources := ResourceCarriers.merge state.resources consumed }
      .ok (value, nextState)

def evalEffectExprState (state : SemanticState) (effectExpr : EffectExpr ty) :
    Except String (Ty.denote ty × SemanticState) :=
  evalExprState
    { state with resources := ResourceCarriers.merge state.resources effectExpr.resources }
    effectExpr.expr

def evalEffectExprStateStrict (state : SemanticState) (effectExpr : EffectExpr ty) :
    Except String (Ty.denote ty × SemanticState) :=
  evalExprStateStrict
    { state with resources := ResourceCarriers.merge state.resources effectExpr.resources }
    effectExpr.expr

theorem evalExprState_success_transition
    (state : SemanticState)
    (expr : IRExpr ty)
    (h : state.failure = none) :
    evalExprState state expr =
      .ok
        ( evalExpr state.context expr,
          { state with resources := ResourceCarriers.merge state.resources (resourceCost expr) } ) := by
  simp [evalExprState, h]

theorem evalExprState_failure_channel
    (state : SemanticState)
    (expr : IRExpr ty)
    (err : String)
    (h : state.failure = some err) :
    evalExprState state expr = .error err := by
  unfold evalExprState
  simp [h]

theorem evalExprStateStrict_success_transition
    (state : SemanticState)
    (expr : IRExpr ty)
    (value : Ty.denote ty)
    (hFail : state.failure = none)
    (hEval : evalExprStrict state.context expr = .ok value) :
    evalExprStateStrict state expr =
      .ok
        ( value,
          { state with resources := ResourceCarriers.merge state.resources (resourceCost expr) } ) := by
  unfold evalExprStateStrict
  simp [hFail, hEval]
  rfl

theorem evalExprStateStrict_failure_channel
    (state : SemanticState)
    (expr : IRExpr ty)
    (err : String)
    (h : state.failure = some err) :
    evalExprStateStrict state expr = .error err := by
  unfold evalExprStateStrict
  simp [h]

theorem evalEffectExprStateStrict_seeded_resources
    (state : SemanticState)
    (effectExpr : EffectExpr ty) :
    evalEffectExprStateStrict state effectExpr =
      evalExprStateStrict
        { state with resources := ResourceCarriers.merge state.resources effectExpr.resources }
        effectExpr.expr := by
  rfl

end LeanCairo.Compiler.Semantics
