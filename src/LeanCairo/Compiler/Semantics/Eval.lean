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

end IntegerDomains

structure EvalContext where
  feltVars : String -> Int := fun _ => 0
  i8Vars : String -> Int := fun _ => 0
  i16Vars : String -> Int := fun _ => 0
  i32Vars : String -> Int := fun _ => 0
  i64Vars : String -> Int := fun _ => 0
  i128Vars : String -> Int := fun _ => 0
  u128Vars : String -> Nat := fun _ => 0
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
  u8Storage : String -> Nat := fun _ => 0
  u16Storage : String -> Nat := fun _ => 0
  u32Storage : String -> Nat := fun _ => 0
  u64Storage : String -> Nat := fun _ => 0
  u256Storage : String -> Nat := fun _ => 0
  qm31Storage : String -> Nat := fun _ => 0
  boolStorage : String -> Bool := fun _ => false

namespace EvalContext

def supportsRuntimeBinding : Ty -> Bool
  | .felt252 | .u128 | .u256 | .bool => true
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
  | .addFelt252 lhs rhs => evalExpr ctx lhs + evalExpr ctx rhs
  | .subFelt252 lhs rhs => evalExpr ctx lhs - evalExpr ctx rhs
  | .mulFelt252 lhs rhs => evalExpr ctx lhs * evalExpr ctx rhs
  | .addU128 lhs rhs => evalExpr ctx lhs + evalExpr ctx rhs
  | .subU128 lhs rhs => evalExpr ctx lhs - evalExpr ctx rhs
  | .mulU128 lhs rhs => evalExpr ctx lhs * evalExpr ctx rhs
  | .addU256 lhs rhs => evalExpr ctx lhs + evalExpr ctx rhs
  | .subU256 lhs rhs => evalExpr ctx lhs - evalExpr ctx rhs
  | .mulU256 lhs rhs => evalExpr ctx lhs * evalExpr ctx rhs
  | @IRExpr.eq ty lhs rhs =>
      by
        let _ : DecidableEq (Ty.denote ty) := Ty.denoteDecidableEq ty
        exact decide (evalExpr ctx lhs = evalExpr ctx rhs)
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

def evalExprStrict (ctx : EvalContext) : IRExpr ty -> Except String (Ty.denote ty)
  | .var name => EvalContext.readVarStrict ctx ty name
  | .storageRead name => EvalContext.readStorageStrict ctx ty name
  | .litU128 value => .ok (IntegerDomains.normalizeUnsigned 128 value)
  | .litU256 value => .ok (IntegerDomains.normalizeUnsigned 256 value)
  | .litBool value => .ok value
  | .litFelt252 value => .ok value
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
  | @IRExpr.eq ty lhs rhs => do
      let left <- evalExprStrict ctx lhs
      let right <- evalExprStrict ctx rhs
      let _ : DecidableEq (Ty.denote ty) := Ty.denoteDecidableEq ty
      pure (decide (left = right))
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
  | .addFelt252 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .subFelt252 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .mulFelt252 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .addU128 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .subU128 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .mulU128 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .addU256 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .subU256 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .mulU256 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .eq lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
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
