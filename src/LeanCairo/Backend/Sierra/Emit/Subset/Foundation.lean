import Lean.Data.Json
import LeanCairo.Backend.Sierra.Generated.Surface
import LeanCairo.Compiler.IR.Spec

namespace LeanCairo.Backend.Sierra.Emit.Subset

open Lean
open LeanCairo.Backend.Sierra.Generated
open LeanCairo.Compiler.IR
open LeanCairo.Core.Domain
open LeanCairo.Core.Spec

/-
Sierra subset backend invariants (phase-2 direct Lean -> Sierra lane):
- storage must be empty,
- functions must be view-only and write-free,
- supported user signature scalar types:
  felt252, bool, u128, u8/u16/u32/u64, i8/i16/i32/i64/i128,
- range-check lane: when range-checked integer arithmetic appears (currently u128/u64/u32/u16
- range-check lane: when range-checked integer arithmetic appears (currently u128/u64/u32/u16/u8/i16
  wrapping add/sub/mul), emitter injects explicit `RangeCheck` input/output in
  Sierra signatures,
- supported expressions:
  - vars / letE,
  - literals: felt252, u128, u64, u32, u16, u8, i16 (typed literal form), bool,
  - felt252 arithmetic: add/sub/mul,
  - top-level equality returns for felt252/u128.

Unsupported nodes fail fast with explicit errors.

Important semantic guardrails:
- u256 arithmetic is still rejected in this lane until explicit semantics are modeled end-to-end.
- no implicit coercions are inserted.
-/

abbrev EmitError := String

def fnvOffset : UInt64 := 14695981039346656037
def fnvPrime : UInt64 := 1099511628211

def fnvStep (hash : UInt64) (byte : UInt8) : UInt64 :=
  (hash ^^^ UInt64.ofNat byte.toNat) * fnvPrime

def fnv1a64 (value : String) : UInt64 :=
  value.toUTF8.foldl fnvStep fnvOffset

def jsonU64 (value : UInt64) : Json :=
  Json.num (JsonNumber.fromNat value.toNat)

def idJson (debugName : String) : Json :=
  Json.mkObj
    [
      ("id", jsonU64 (fnv1a64 debugName)),
      ("debug_name", Json.str debugName)
    ]

def u32Modulus : Nat := 2 ^ 32

def userTypeIdWords (debugName : String) : Array Nat :=
  (List.range 8).map (fun idx => (fnv1a64 s!"{debugName}#{idx}").toNat % u32Modulus) |>.toArray

def userTypeArgJson (debugName : String) : Json :=
  Json.mkObj
    [
      ( "UserType",
        Json.mkObj
          [
            ("id", Json.arr (userTypeIdWords debugName |>.map (fun word => Json.num (JsonNumber.fromNat word)))),
            ("debug_name", Json.str debugName)
          ] )
    ]

def unitTypeDebugName : String := "Unit"
def boolTypeDebugName : String := "core::bool"
def tupleUserTypeDebugName : String := "Tuple"

def tupleTypeDebugName (arity : Nat) : String := s!"Tuple{arity}"

def ensureKnownGenericTypeId (genericId : String) : Except EmitError Unit :=
  if genericTypeIds.contains genericId then
    .ok ()
  else
    .error s!"pinned Sierra surface does not contain generic type id '{genericId}'"

def ensureKnownGenericLibfuncId (genericId : String) : Except EmitError Unit :=
  if genericLibfuncIds.contains genericId then
    .ok ()
  else
    .error s!"pinned Sierra surface does not contain generic libfunc id '{genericId}'"

def tyGenericTypeId : Ty -> Except EmitError String
  | .felt252 => do
      ensureKnownGenericTypeId "felt252"
      pure "felt252"
  | .i8 => do
      ensureKnownGenericTypeId "i8"
      pure "i8"
  | .i16 => do
      ensureKnownGenericTypeId "i16"
      pure "i16"
  | .i32 => do
      ensureKnownGenericTypeId "i32"
      pure "i32"
  | .i64 => do
      ensureKnownGenericTypeId "i64"
      pure "i64"
  | .i128 => do
      ensureKnownGenericTypeId "i128"
      pure "i128"
  | .u8 => do
      ensureKnownGenericTypeId "u8"
      pure "u8"
  | .u16 => do
      ensureKnownGenericTypeId "u16"
      pure "u16"
  | .u32 => do
      ensureKnownGenericTypeId "u32"
      pure "u32"
  | .u64 => do
      ensureKnownGenericTypeId "u64"
      pure "u64"
  | .qm31 => do
      ensureKnownGenericTypeId "qm31"
      pure "qm31"
  | .u128 => do
      ensureKnownGenericTypeId "u128"
      pure "u128"
  | .u512 => do
      ensureKnownGenericTypeId "u512"
      pure "u512"
  | .rangeCheck => do
      ensureKnownGenericTypeId "RangeCheck"
      pure "RangeCheck"
  | .tuple _ | .structTy _ => do
      ensureKnownGenericTypeId "Struct"
      pure "Struct"
  | .enumTy _ => do
      ensureKnownGenericTypeId "Enum"
      pure "Enum"
  | .array _ => do
      ensureKnownGenericTypeId "Array"
      pure "Array"
  | .span _ => do
      ensureKnownGenericTypeId "Span"
      pure "Span"
  | .nullable _ => do
      ensureKnownGenericTypeId "Nullable"
      pure "Nullable"
  | .boxed _ => do
      ensureKnownGenericTypeId "Box"
      pure "Box"
  | .dict _ _ =>
      .error "felt252 dict is not yet supported in direct Sierra subset backend (typed dict operation lowering pending)"
  | .u256 =>
      .error "u256 is not yet supported in direct Sierra subset backend (struct-based lowering pending)"
  | .bool =>
      do
        ensureKnownGenericTypeId "Enum"
        pure "Enum"
  | .nonZero _ => do
      ensureKnownGenericTypeId "NonZero"
      pure "NonZero"
  | ty =>
      .error s!"type '{Ty.toCairo ty}' is not yet supported in direct Sierra subset backend"

def tyDebugName (ty : Ty) : Except EmitError String := do
  match ty with
  | .bool => pure boolTypeDebugName
  | .nonZero innerTag => pure s!"NonZero<{innerTag}>"
  | .tuple arity => pure (tupleTypeDebugName arity)
  | .structTy name => pure name
  | .enumTy name => pure name
  | .array elemTag => pure s!"Array<{elemTag}>"
  | .span elemTag => pure s!"Span<{elemTag}>"
  | .nullable elemTag => pure s!"Nullable<{elemTag}>"
  | .boxed elemTag => pure s!"Box<{elemTag}>"
  | .dict keyTag valueTag => pure s!"Felt252Dict<{keyTag}, {valueTag}>"
  | _ =>
      let genericId <- tyGenericTypeId ty
      pure genericId

def typeIdJson (ty : Ty) : Except EmitError Json := do
  let debugName <- tyDebugName ty
  pure (idJson debugName)

def typeArgJson (tyId : Json) : Json :=
  Json.mkObj [("Type", tyId)]

def innerTyOfNonZeroTag (innerTag : String) : Except EmitError Ty :=
  match innerTag with
  | "felt252" => .ok .felt252
  | "u128" => .ok .u128
  | "u256" => .ok .u256
  | "u512" => .ok .u512
  | "bool" => .ok .bool
  | "i8" => .ok .i8
  | "i16" => .ok .i16
  | "i32" => .ok .i32
  | "i64" => .ok .i64
  | "i128" => .ok .i128
  | "u8" => .ok .u8
  | "u16" => .ok .u16
  | "u32" => .ok .u32
  | "u64" => .ok .u64
  | "qm31" => .ok .qm31
  | _ => .error s!"unsupported NonZero inner tag '{innerTag}' in direct Sierra subset backend"

def tyOfElementTag (elemTag : String) : Except EmitError Ty :=
  match elemTag with
  | "felt252" => .ok .felt252
  | "u128" => .ok .u128
  | "u256" => .ok .u256
  | "u512" => .ok .u512
  | "bool" => .ok .bool
  | "i8" => .ok .i8
  | "i16" => .ok .i16
  | "i32" => .ok .i32
  | "i64" => .ok .i64
  | "i128" => .ok .i128
  | "u8" => .ok .u8
  | "u16" => .ok .u16
  | "u32" => .ok .u32
  | "u64" => .ok .u64
  | "qm31" => .ok .qm31
  | _ =>
      .error
        s!"unsupported collection element tag '{elemTag}' in direct Sierra subset backend"

def unitTypeDeclJson : Except EmitError Json := do
  ensureKnownGenericTypeId "Struct"
  pure <|
    Json.mkObj
      [
        ("id", idJson unitTypeDebugName),
        ( "long_id",
          Json.mkObj
            [
              ("generic_id", Json.str "Struct"),
              ("generic_args", Json.arr #[userTypeArgJson tupleUserTypeDebugName])
            ] ),
        ("declared_type_info", Json.null)
      ]

def boolTypeDeclJson : Except EmitError Json := do
  ensureKnownGenericTypeId "Enum"
  pure <|
    Json.mkObj
      [
        ("id", idJson boolTypeDebugName),
        ( "long_id",
          Json.mkObj
            [
              ("generic_id", Json.str "Enum"),
              ( "generic_args",
                Json.arr
                  #[
                    userTypeArgJson boolTypeDebugName,
                    typeArgJson (idJson unitTypeDebugName),
                    typeArgJson (idJson unitTypeDebugName)
                  ] )
            ] ),
        ("declared_type_info", Json.null)
      ]

def typeDeclJson (ty : Ty) : Except EmitError Json := do
  match ty with
  | .bool =>
      boolTypeDeclJson
  | .tuple arity => do
      ensureKnownGenericTypeId "Struct"
      let tyId <- typeIdJson ty
      let unitTyId := idJson unitTypeDebugName
      let fieldArgs := (List.replicate arity (typeArgJson unitTyId))
      pure <|
        Json.mkObj
          [
            ("id", tyId),
            ( "long_id",
              Json.mkObj
                [
                  ("generic_id", Json.str "Struct"),
                  ("generic_args", Json.arr (([userTypeArgJson (tupleTypeDebugName arity)] ++ fieldArgs).toArray))
                ] ),
            ("declared_type_info", Json.null)
          ]
  | .structTy typeName => do
      ensureKnownGenericTypeId "Struct"
      let tyId <- typeIdJson ty
      pure <|
        Json.mkObj
          [
            ("id", tyId),
            ( "long_id",
              Json.mkObj
                [
                  ("generic_id", Json.str "Struct"),
                  ("generic_args", Json.arr #[userTypeArgJson typeName])
                ] ),
            ("declared_type_info", Json.null)
          ]
  | .enumTy typeName => do
      ensureKnownGenericTypeId "Enum"
      let tyId <- typeIdJson ty
      let unitTyId := idJson unitTypeDebugName
      pure <|
        Json.mkObj
          [
            ("id", tyId),
            ( "long_id",
              Json.mkObj
                [
                  ("generic_id", Json.str "Enum"),
                  ("generic_args", Json.arr #[userTypeArgJson typeName, typeArgJson unitTyId, typeArgJson unitTyId])
                ] ),
            ("declared_type_info", Json.null)
          ]
  | .array elemTag => do
      ensureKnownGenericTypeId "Array"
      let elemTy <- tyOfElementTag elemTag
      let elemTyId <- typeIdJson elemTy
      let tyId <- typeIdJson ty
      pure <|
        Json.mkObj
          [
            ("id", tyId),
            ( "long_id",
              Json.mkObj
                [
                  ("generic_id", Json.str "Array"),
                  ("generic_args", Json.arr #[typeArgJson elemTyId])
                ] ),
            ("declared_type_info", Json.null)
          ]
  | .span elemTag => do
      ensureKnownGenericTypeId "Span"
      let elemTy <- tyOfElementTag elemTag
      let elemTyId <- typeIdJson elemTy
      let tyId <- typeIdJson ty
      pure <|
        Json.mkObj
          [
            ("id", tyId),
            ( "long_id",
              Json.mkObj
                [
                  ("generic_id", Json.str "Span"),
                  ("generic_args", Json.arr #[typeArgJson elemTyId])
                ] ),
            ("declared_type_info", Json.null)
          ]
  | .nullable elemTag => do
      ensureKnownGenericTypeId "Nullable"
      let elemTy <- tyOfElementTag elemTag
      let elemTyId <- typeIdJson elemTy
      let tyId <- typeIdJson ty
      pure <|
        Json.mkObj
          [
            ("id", tyId),
            ( "long_id",
              Json.mkObj
                [
                  ("generic_id", Json.str "Nullable"),
                  ("generic_args", Json.arr #[typeArgJson elemTyId])
                ] ),
            ("declared_type_info", Json.null)
          ]
  | .boxed elemTag => do
      ensureKnownGenericTypeId "Box"
      let elemTy <- tyOfElementTag elemTag
      let elemTyId <- typeIdJson elemTy
      let tyId <- typeIdJson ty
      pure <|
        Json.mkObj
          [
            ("id", tyId),
            ( "long_id",
              Json.mkObj
                [
                  ("generic_id", Json.str "Box"),
                  ("generic_args", Json.arr #[typeArgJson elemTyId])
                ] ),
            ("declared_type_info", Json.null)
          ]
  | .dict _ _ =>
      .error
        "felt252 dict type declarations are not yet supported in direct Sierra subset backend (typed dict operation lowering pending)"
  | .nonZero innerTag => do
      ensureKnownGenericTypeId "NonZero"
      let innerTy <- innerTyOfNonZeroTag innerTag
      let innerTyId <- typeIdJson innerTy
      let tyId <- typeIdJson (.nonZero innerTag)
      pure <|
        Json.mkObj
          [
            ("id", tyId),
            ( "long_id",
              Json.mkObj
                [
                  ("generic_id", Json.str "NonZero"),
                  ("generic_args", Json.arr #[typeArgJson innerTyId])
                ] ),
            ("declared_type_info", Json.null)
          ]
  | _ => do
      let genericId <- tyGenericTypeId ty
      let tyId <- typeIdJson ty
      pure <|
        Json.mkObj
          [
            ("id", tyId),
            ( "long_id",
              Json.mkObj
                [
                  ("generic_id", Json.str genericId),
                  ("generic_args", Json.arr #[])
                ] ),
            ("declared_type_info", Json.null)
          ]

partial def natToLeBytes (n : Nat) : List Nat :=
  if n = 0 then
    []
  else
    (n % 256) :: natToLeBytes (n / 256)

def bigIntJson (value : Int) : Json :=
  if value = 0 then
    Json.arr #[Json.num (JsonNumber.fromInt 0), Json.arr #[]]
  else
    let sign : Int := if value < 0 then -1 else 1
    let bytes := natToLeBytes value.natAbs
    Json.arr
      #[
        Json.num (JsonNumber.fromInt sign),
        Json.arr (bytes.map (fun b => Json.num (JsonNumber.fromNat b))).toArray
      ]

def valueArgJson (value : Int) : Json :=
  Json.mkObj [("Value", bigIntJson value)]

def fallthroughTargetJson : Json :=
  Json.str "Fallthrough"

def statementTargetJson (statementIdx : Nat) : Json :=
  Json.mkObj [("Statement", Json.num (JsonNumber.fromNat statementIdx))]

def branchJson (target : Json) (results : List Json) : Json :=
  Json.mkObj [("target", target), ("results", Json.arr results.toArray)]

def invocationStmtBranchesJson
    (libfuncId : Json)
    (args : List Json)
    (branches : List (Json × List Json)) : Json :=
  Json.mkObj
    [
      ( "Invocation",
        Json.mkObj
          [
            ("libfunc_id", libfuncId),
            ("args", Json.arr args.toArray),
            ("branches", Json.arr (branches.map (fun entry => branchJson entry.fst entry.snd)).toArray)
          ] )
    ]

def invocationStmtJson (libfuncId : Json) (args : List Json) (results : List Json) : Json :=
  invocationStmtBranchesJson libfuncId args [(fallthroughTargetJson, results)]

def returnStmtJson (results : List Json) : Json :=
  Json.mkObj [("Return", Json.arr results.toArray)]

def paramVarDebugName (fnName : String) (paramName : String) : String :=
  s!"{fnName}::param::{paramName}"

def insertDeclIfMissing
    (decls : List (String × Json))
    (key : String)
    (decl : Json) : List (String × Json) :=
  if decls.any (fun entry => entry.fst = key) then
    decls
  else
    decls ++ [(key, decl)]

structure EmitState where
  typeDecls : List (String × Json) := []
  libfuncDecls : List (String × Json) := []
  statementsRev : List Json := []
  tempCounter : Nat := 0
  entryPoint : Nat := 0
  rangeCheckVar? : Option Json := none
  deriving Inhabited

abbrev EmitM := StateT EmitState (Except EmitError)

def liftExcept {α : Type} (value : Except EmitError α) : EmitM α := do
  match value with
  | .ok result => pure result
  | .error err => throw err

def pushStmt (stmt : Json) : EmitM Unit :=
  modify (fun st => { st with statementsRev := stmt :: st.statementsRev })

def setRangeCheckVar (value : Json) : EmitM Unit :=
  modify (fun st => { st with rangeCheckVar? := some value })

def requireRangeCheckVar (fnName : String) : EmitM Json := do
  match (← get).rangeCheckVar? with
  | some value => pure value
  | none =>
      throw
        s!"unsupported range-checked integer arithmetic in function '{fnName}': missing explicit range-check resource lane in current emitter scope"

def nextAbsoluteStatementIdx : EmitM Nat := do
  let st <- get
  pure (st.entryPoint + st.statementsRev.length)

def freshVarId (fnName : String) (purpose : String) : EmitM Json := do
  let st <- get
  let idx := st.tempCounter
  set { st with tempCounter := idx + 1 }
  pure (idJson s!"{fnName}::tmp::{purpose}::{idx}")

def registerTypeDecl (ty : Ty) : EmitM Json := do
  match ty with
  | .bool =>
      let unitDecl <- liftExcept unitTypeDeclJson
      modify (fun st => { st with typeDecls := insertDeclIfMissing st.typeDecls unitTypeDebugName unitDecl })
  | .tuple _ | .structTy _ | .enumTy _ =>
      let unitDecl <- liftExcept unitTypeDeclJson
      modify (fun st => { st with typeDecls := insertDeclIfMissing st.typeDecls unitTypeDebugName unitDecl })
  | .array elemTag | .span elemTag | .nullable elemTag | .boxed elemTag =>
      let elemTy <- liftExcept (tyOfElementTag elemTag)
      let elemTyDecl <- liftExcept (typeDeclJson elemTy)
      let elemDebugName <- liftExcept (tyDebugName elemTy)
      modify (fun st => { st with typeDecls := insertDeclIfMissing st.typeDecls elemDebugName elemTyDecl })
  | .nonZero innerTag =>
      let innerTy <- liftExcept (innerTyOfNonZeroTag innerTag)
      let innerTyDecl <- liftExcept (typeDeclJson innerTy)
      let innerDebugName <- liftExcept (tyDebugName innerTy)
      modify (fun st => { st with typeDecls := insertDeclIfMissing st.typeDecls innerDebugName innerTyDecl })
  | _ =>
      pure ()
  let tyDecl <- liftExcept (typeDeclJson ty)
  let tyId <- liftExcept (typeIdJson ty)
  let debugName <- liftExcept (tyDebugName ty)
  modify (fun st => { st with typeDecls := insertDeclIfMissing st.typeDecls debugName tyDecl })
  pure tyId

def registerOpaqueNoArgTypeDecl (debugName genericId : String) : EmitM Json := do
  let _ <- liftExcept (ensureKnownGenericTypeId genericId)
  let tyId := idJson debugName
  let decl :=
    Json.mkObj
      [
        ("id", tyId),
        ( "long_id",
          Json.mkObj
            [
              ("generic_id", Json.str genericId),
              ("generic_args", Json.arr #[])
            ] ),
        ("declared_type_info", Json.null)
      ]
  modify (fun st => { st with typeDecls := insertDeclIfMissing st.typeDecls debugName decl })
  pure tyId

def registerU128MulGuaranteeTypeDecl : EmitM Json :=
  registerOpaqueNoArgTypeDecl "U128MulGuarantee" "U128MulGuarantee"

def registerConstTypeDecl (debugName : String) (valueTyId : Json) (constArg : Json) : EmitM Json := do
  let _ <- liftExcept (ensureKnownGenericTypeId "Const")
  let tyId := idJson debugName
  let decl :=
    Json.mkObj
      [
        ("id", tyId),
        ( "long_id",
          Json.mkObj
            [
              ("generic_id", Json.str "Const"),
              ("generic_args", Json.arr #[typeArgJson valueTyId, constArg])
            ] ),
        ("declared_type_info", Json.null)
      ]
  modify (fun st => { st with typeDecls := insertDeclIfMissing st.typeDecls debugName decl })
  pure tyId

def registerConstU128TypeDecl (value : Nat) : EmitM Json := do
  let u128TyId <- registerTypeDecl .u128
  registerConstTypeDecl s!"Const<u128, {value}>" u128TyId (valueArgJson (Int.ofNat value))

def registerConstU64TypeDecl (value : Nat) : EmitM Json := do
  let u64TyId <- registerTypeDecl .u64
  registerConstTypeDecl s!"Const<u64, {value}>" u64TyId (valueArgJson (Int.ofNat value))

def registerConstU32TypeDecl (value : Nat) : EmitM Json := do
  let u32TyId <- registerTypeDecl .u32
  registerConstTypeDecl s!"Const<u32, {value}>" u32TyId (valueArgJson (Int.ofNat value))

def registerConstU16TypeDecl (value : Nat) : EmitM Json := do
  let u16TyId <- registerTypeDecl .u16
  registerConstTypeDecl s!"Const<u16, {value}>" u16TyId (valueArgJson (Int.ofNat value))

def registerConstNonZeroU128TypeDecl (value : Nat) : EmitM Json := do
  if value = 0 then
    throw "internal error: NonZero<u128> constant requires value > 0"
  else
    pure ()
  let nonZeroTyId <- registerTypeDecl (.nonZero "u128")
  let constU128TyId <- registerConstU128TypeDecl value
  registerConstTypeDecl
    s!"Const<NonZero<u128>, Const<u128, {value}>>"
    nonZeroTyId
    (typeArgJson constU128TyId)

def registerConstNonZeroU64TypeDecl (value : Nat) : EmitM Json := do
  if value = 0 then
    throw "internal error: NonZero<u64> constant requires value > 0"
  else
    pure ()
  let nonZeroTyId <- registerTypeDecl (.nonZero "u64")
  let constU64TyId <- registerConstU64TypeDecl value
  registerConstTypeDecl
    s!"Const<NonZero<u64>, Const<u64, {value}>>"
    nonZeroTyId
    (typeArgJson constU64TyId)

def registerConstNonZeroU32TypeDecl (value : Nat) : EmitM Json := do
  if value = 0 then
    throw "internal error: NonZero<u32> constant requires value > 0"
  else
    pure ()
  let nonZeroTyId <- registerTypeDecl (.nonZero "u32")
  let constU32TyId <- registerConstU32TypeDecl value
  registerConstTypeDecl
    s!"Const<NonZero<u32>, Const<u32, {value}>>"
    nonZeroTyId
    (typeArgJson constU32TyId)

def registerConstNonZeroU16TypeDecl (value : Nat) : EmitM Json := do
  if value = 0 then
    throw "internal error: NonZero<u16> constant requires value > 0"
  else
    pure ()
  let nonZeroTyId <- registerTypeDecl (.nonZero "u16")
  let constU16TyId <- registerConstU16TypeDecl value
  registerConstTypeDecl
    s!"Const<NonZero<u16>, Const<u16, {value}>>"
    nonZeroTyId
    (typeArgJson constU16TyId)

def registerLibfuncDecl (debugName : String) (genericId : String) (genericArgs : List Json) : EmitM Json := do
  let _ <- liftExcept (ensureKnownGenericLibfuncId genericId)
  let libfuncId := idJson debugName
  let decl :=
    Json.mkObj
      [
        ("id", libfuncId),
        ( "long_id",
          Json.mkObj
            [
              ("generic_id", Json.str genericId),
              ("generic_args", Json.arr genericArgs.toArray)
            ] )
      ]
  modify (fun st => { st with libfuncDecls := insertDeclIfMissing st.libfuncDecls debugName decl })
  pure libfuncId

def storeTempDebugName (ty : Ty) : Except EmitError String := do
  let typeName <- tyDebugName ty
  pure s!"store_temp_{typeName}"

def dupDebugName (ty : Ty) : Except EmitError String := do
  let typeName <- tyDebugName ty
  pure s!"dup_{typeName}"

def dropDebugName (ty : Ty) : Except EmitError String := do
  let typeName <- tyDebugName ty
  pure s!"drop_{typeName}"

def emitStoreTemp (fnName : String) (ty : Ty) (valueVar : Json) : EmitM Json := do
  let tyId <- registerTypeDecl ty
  let debugName <- liftExcept (storeTempDebugName ty)
  let libfuncId <- registerLibfuncDecl debugName "store_temp" [typeArgJson tyId]
  let outVar <- freshVarId fnName "store_temp"
  pushStmt (invocationStmtJson libfuncId [valueVar] [outVar])
  pure outVar

def emitStoreTempTo (ty : Ty) (valueVar outVar : Json) : EmitM Unit := do
  let tyId <- registerTypeDecl ty
  let debugName <- liftExcept (storeTempDebugName ty)
  let libfuncId <- registerLibfuncDecl debugName "store_temp" [typeArgJson tyId]
  pushStmt (invocationStmtJson libfuncId [valueVar] [outVar])

def emitDrop (fnName : String) (ty : Ty) (valueVar : Json) : EmitM Unit := do
  let tyId <- registerTypeDecl ty
  let debugName <- liftExcept (dropDebugName ty)
  let libfuncId <- registerLibfuncDecl debugName "drop" [typeArgJson tyId]
  let _ <- freshVarId fnName "drop"
  pushStmt (invocationStmtJson libfuncId [valueVar] [])

def nextStatementIdx : EmitM Nat := do
  pure (←get).statementsRev.length

def emitBranchAlign : EmitM Unit := do
  let branchAlignLibfuncId <- registerLibfuncDecl "branch_align" "branch_align" []
  pushStmt (invocationStmtJson branchAlignLibfuncId [] [])

def emitJump (targetIdx : Nat) : EmitM Unit := do
  let jumpLibfuncId <- registerLibfuncDecl "jump" "jump" []
  pushStmt (invocationStmtBranchesJson jumpLibfuncId [] [(statementTargetJson targetIdx, [])])

def boolVariantDebugName (value : Bool) : String :=
  if value then
    s!"enum_init<{boolTypeDebugName}, 1>"
  else
    s!"enum_init<{boolTypeDebugName}, 0>"

def emitBoolConst (fnName : String) (value : Bool) : EmitM Json := do
  let boolTyId <- registerTypeDecl .bool
  let unitTyId := idJson unitTypeDebugName
  let structConstructDebugName := s!"struct_construct<{unitTypeDebugName}>"
  let structConstructLibfuncId <-
    registerLibfuncDecl structConstructDebugName "struct_construct" [typeArgJson unitTyId]
  let unitValueVar <- freshVarId fnName "bool_unit"
  pushStmt (invocationStmtJson structConstructLibfuncId [] [unitValueVar])

  let variantIdx : Int := if value then 1 else 0
  let enumInitLibfuncId <-
    registerLibfuncDecl
      (boolVariantDebugName value)
      "enum_init"
      [typeArgJson boolTyId, valueArgJson variantIdx]
  let rawBoolVar <- freshVarId fnName "bool_const_raw"
  pushStmt (invocationStmtJson enumInitLibfuncId [unitValueVar] [rawBoolVar])
  emitStoreTemp fnName .bool rawBoolVar

def feltConstDebugName (value : Int) : String :=
  if value < 0 then
    s!"felt252_const_neg_{value.natAbs}"
  else
    s!"felt252_const_pos_{value.natAbs}"

def emitFeltConst (fnName : String) (value : Int) : EmitM Json := do
  let _ <- registerTypeDecl .felt252
  let debugName := feltConstDebugName value
  let libfuncId <- registerLibfuncDecl debugName "felt252_const" [valueArgJson value]
  let rawVar <- freshVarId fnName "felt_const_raw"
  pushStmt (invocationStmtJson libfuncId [] [rawVar])
  emitStoreTemp fnName .felt252 rawVar

def u128ConstDebugName (value : Nat) : String :=
  s!"u128_const_{value}"

def emitU128Const (fnName : String) (value : Nat) : EmitM Json := do
  let _ <- registerTypeDecl .u128
  let libfuncId <- registerLibfuncDecl (u128ConstDebugName value) "u128_const" [valueArgJson (Int.ofNat value)]
  let rawVar <- freshVarId fnName "u128_const_raw"
  pushStmt (invocationStmtJson libfuncId [] [rawVar])
  emitStoreTemp fnName .u128 rawVar

def u64ConstDebugName (value : Nat) : String :=
  s!"u64_const_{value}"

def emitU64Const (fnName : String) (value : Nat) : EmitM Json := do
  let _ <- registerTypeDecl .u64
  let libfuncId <- registerLibfuncDecl (u64ConstDebugName value) "u64_const" [valueArgJson (Int.ofNat value)]
  let rawVar <- freshVarId fnName "u64_const_raw"
  pushStmt (invocationStmtJson libfuncId [] [rawVar])
  emitStoreTemp fnName .u64 rawVar

def u32ConstDebugName (value : Nat) : String :=
  s!"u32_const_{value}"

def u16ConstDebugName (value : Nat) : String :=
  s!"u16_const_{value}"

def u8ConstDebugName (value : Nat) : String :=
  s!"u8_const_{value}"

def i16ConstDebugName (value : Int) : String :=
  if value < 0 then
    s!"i16_const_neg_{value.natAbs}"
  else
    s!"i16_const_pos_{value.natAbs}"

def emitU16Const (fnName : String) (value : Nat) : EmitM Json := do
  let _ <- registerTypeDecl .u16
  let libfuncId <- registerLibfuncDecl (u16ConstDebugName value) "u16_const" [valueArgJson (Int.ofNat value)]
  let rawVar <- freshVarId fnName "u16_const_raw"
  pushStmt (invocationStmtJson libfuncId [] [rawVar])
  emitStoreTemp fnName .u16 rawVar

def emitU8Const (fnName : String) (value : Nat) : EmitM Json := do
  let _ <- registerTypeDecl .u8
  let libfuncId <- registerLibfuncDecl (u8ConstDebugName value) "u8_const" [valueArgJson (Int.ofNat value)]
  let rawVar <- freshVarId fnName "u8_const_raw"
  pushStmt (invocationStmtJson libfuncId [] [rawVar])
  emitStoreTemp fnName .u8 rawVar

def emitI16Const (fnName : String) (value : Int) : EmitM Json := do
  let _ <- registerTypeDecl .i16
  let libfuncId <- registerLibfuncDecl (i16ConstDebugName value) "i16_const" [valueArgJson value]
  let rawVar <- freshVarId fnName "i16_const_raw"
  pushStmt (invocationStmtJson libfuncId [] [rawVar])
  emitStoreTemp fnName .i16 rawVar

def emitU32Const (fnName : String) (value : Nat) : EmitM Json := do
  let _ <- registerTypeDecl .u32
  let libfuncId <- registerLibfuncDecl (u32ConstDebugName value) "u32_const" [valueArgJson (Int.ofNat value)]
  let rawVar <- freshVarId fnName "u32_const_raw"
  pushStmt (invocationStmtJson libfuncId [] [rawVar])
  emitStoreTemp fnName .u32 rawVar

def emitNonZeroU128Const (fnName : String) (value : Nat) : EmitM Json := do
  let constTyId <- registerConstNonZeroU128TypeDecl value
  let debugName := s!"const_as_immediate<Const<NonZero<u128>, Const<u128, {value}>>>"
  let libfuncId <- registerLibfuncDecl debugName "const_as_immediate" [typeArgJson constTyId]
  let rawVar <- freshVarId fnName "nonzero_u128_const_raw"
  pushStmt (invocationStmtJson libfuncId [] [rawVar])
  emitStoreTemp fnName (.nonZero "u128") rawVar

def emitNonZeroU64Const (fnName : String) (value : Nat) : EmitM Json := do
  let constTyId <- registerConstNonZeroU64TypeDecl value
  let debugName := s!"const_as_immediate<Const<NonZero<u64>, Const<u64, {value}>>>"
  let libfuncId <- registerLibfuncDecl debugName "const_as_immediate" [typeArgJson constTyId]
  let rawVar <- freshVarId fnName "nonzero_u64_const_raw"
  pushStmt (invocationStmtJson libfuncId [] [rawVar])
  emitStoreTemp fnName (.nonZero "u64") rawVar

def emitNonZeroU32Const (fnName : String) (value : Nat) : EmitM Json := do
  let constTyId <- registerConstNonZeroU32TypeDecl value
  let debugName := s!"const_as_immediate<Const<NonZero<u32>, Const<u32, {value}>>>"
  let libfuncId <- registerLibfuncDecl debugName "const_as_immediate" [typeArgJson constTyId]
  let rawVar <- freshVarId fnName "nonzero_u32_const_raw"
  pushStmt (invocationStmtJson libfuncId [] [rawVar])
  emitStoreTemp fnName (.nonZero "u32") rawVar

def emitNonZeroU16Const (fnName : String) (value : Nat) : EmitM Json := do
  let constTyId <- registerConstNonZeroU16TypeDecl value
  let debugName := s!"const_as_immediate<Const<NonZero<u16>, Const<u16, {value}>>>"
  let libfuncId <- registerLibfuncDecl debugName "const_as_immediate" [typeArgJson constTyId]
  let rawVar <- freshVarId fnName "nonzero_u16_const_raw"
  pushStmt (invocationStmtJson libfuncId [] [rawVar])
  emitStoreTemp fnName (.nonZero "u16") rawVar

structure LinearVar where
  ty : Ty
  remaining : Nat
  current? : Option Json
  deriving Inhabited

abbrev Env := List (String × LinearVar)

partial def pendingDropCount (env : Env) : Except EmitError Nat := do
  match env with
  | [] => pure 0
  | (_, entry) :: rest =>
      if entry.remaining != 0 then
        .error "internal error: non-zero remaining uses encountered while computing branch shape"
      else
        let restCount <- pendingDropCount rest
        if entry.current?.isSome then
          pure (restCount + 1)
        else
          pure restCount

partial def countVarUses (target : String) : IRExpr ty -> Nat
  | .var name => if name = target then 1 else 0
  | .storageRead _ => 0
  | .litU128 _ => 0
  | .litU256 _ => 0
  | .litBool _ => 0
  | .litFelt252 _ => 0
  | .litInt _ _ => 0
  | .addFelt252 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .subFelt252 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .mulFelt252 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .addInt _ lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .subInt _ lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .mulInt _ lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .divInt _ lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .modInt _ lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .bitAndInt _ lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .bitOrInt _ lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .bitXorInt _ lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .shlInt _ lhs _ => countVarUses target lhs
  | .shrInt _ lhs _ => countVarUses target lhs
  | .addU128 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .subU128 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .mulU128 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .divU128 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .modU128 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .bitAndU128 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .bitOrU128 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .bitXorU128 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .shlU128 lhs _ => countVarUses target lhs
  | .shrU128 lhs _ => countVarUses target lhs
  | .addU256 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .subU256 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .mulU256 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .divU256 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .modU256 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .bitAndU256 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .bitOrU256 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .bitXorU256 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .shlU256 lhs _ => countVarUses target lhs
  | .shrU256 lhs _ => countVarUses target lhs
  | .u256FromLimbs low high => countVarUses target low + countVarUses target high
  | .u256Low value => countVarUses target value
  | .u256High value => countVarUses target value
  | .eq lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .ltInt _ lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .leInt _ lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .ltU128 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .leU128 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .ltU256 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .leU256 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .ite cond thenBranch elseBranch =>
      countVarUses target cond + countVarUses target thenBranch + countVarUses target elseBranch
  | .letE name _ bound body =>
      let boundCount := countVarUses target bound
      if name = target then
        boundCount
      else
        boundCount + countVarUses target body

partial def consumeVar
    (fnName : String)
    (env : Env)
    (expectedTy : Ty)
    (name : String) : EmitM (Env × Json) := do
  match env with
  | [] =>
      throw s!"unbound variable '{name}' in function '{fnName}'"
  | (entryName, entryVar) :: rest =>
      if entryName = name then
        if entryVar.ty != expectedTy then
          throw s!"typed variable mismatch for '{name}' in function '{fnName}'"
        else
          match entryVar.current? with
          | none =>
              throw s!"variable '{name}' in function '{fnName}' was already consumed"
          | some currentValue =>
              if entryVar.remaining = 0 then
                throw s!"variable '{name}' in function '{fnName}' has zero remaining uses"
              else if entryVar.remaining = 1 then
                let updated : LinearVar := { entryVar with remaining := 0, current? := none }
                pure (((entryName, updated) :: rest), currentValue)
              else
                let tyId <- registerTypeDecl expectedTy
                let dupName <- liftExcept (dupDebugName expectedTy)
                let dupLibfuncId <- registerLibfuncDecl dupName "dup" [typeArgJson tyId]
                let keepVar <- freshVarId fnName "dup_keep"
                let useVar <- freshVarId fnName "dup_use"
                pushStmt (invocationStmtJson dupLibfuncId [currentValue] [keepVar, useVar])
                let updated : LinearVar := { entryVar with remaining := entryVar.remaining - 1, current? := some keepVar }
                pure (((entryName, updated) :: rest), useVar)
      else
        let (rest', consumed) <- consumeVar fnName rest expectedTy name
        pure (((entryName, entryVar) :: rest'), consumed)

def u128ArithUnsupported (fnName : String) (opName : String) : EmitM α :=
  throw
    s!"unsupported u128 arithmetic ({opName}) in function '{fnName}': direct Sierra backend currently implements only add/sub/mul wrapping paths with explicit RangeCheck threading"

partial def exprUsesRangeCheckedIntArith : IRExpr ty -> Bool
  | .var _ => false
  | .storageRead _ => false
  | .litU128 _ => false
  | .litU256 _ => false
  | .litBool _ => false
  | .litFelt252 _ => false
  | .litInt _ _ => false
  | .addFelt252 lhs rhs => exprUsesRangeCheckedIntArith lhs || exprUsesRangeCheckedIntArith rhs
  | .subFelt252 lhs rhs => exprUsesRangeCheckedIntArith lhs || exprUsesRangeCheckedIntArith rhs
  | .mulFelt252 lhs rhs => exprUsesRangeCheckedIntArith lhs || exprUsesRangeCheckedIntArith rhs
  | .addInt ty lhs rhs =>
      exprUsesRangeCheckedIntArith lhs ||
      exprUsesRangeCheckedIntArith rhs ||
      ty = .u128 || ty = .u64 || ty = .u32 || ty = .u16 || ty = .u8 || ty = .i16
  | .subInt ty lhs rhs =>
      exprUsesRangeCheckedIntArith lhs ||
      exprUsesRangeCheckedIntArith rhs ||
      ty = .u128 || ty = .u64 || ty = .u32 || ty = .u16 || ty = .u8 || ty = .i16
  | .mulInt ty lhs rhs =>
      exprUsesRangeCheckedIntArith lhs ||
      exprUsesRangeCheckedIntArith rhs ||
      ty = .u128 || ty = .u64 || ty = .u32 || ty = .u16 || ty = .u8 || ty = .i16
  | .divInt ty lhs rhs =>
      exprUsesRangeCheckedIntArith lhs ||
      exprUsesRangeCheckedIntArith rhs ||
      ty = .u128 || ty = .u64 || ty = .u32 || ty = .u16 || ty = .u8 || ty = .i16
  | .modInt ty lhs rhs =>
      exprUsesRangeCheckedIntArith lhs ||
      exprUsesRangeCheckedIntArith rhs ||
      ty = .u128 || ty = .u64 || ty = .u32 || ty = .u16 || ty = .u8 || ty = .i16
  | .bitAndInt ty lhs rhs =>
      exprUsesRangeCheckedIntArith lhs ||
      exprUsesRangeCheckedIntArith rhs ||
      ty = .u128 || ty = .u64 || ty = .u32 || ty = .u16 || ty = .u8 || ty = .i16
  | .bitOrInt ty lhs rhs =>
      exprUsesRangeCheckedIntArith lhs ||
      exprUsesRangeCheckedIntArith rhs ||
      ty = .u128 || ty = .u64 || ty = .u32 || ty = .u16 || ty = .u8 || ty = .i16
  | .bitXorInt ty lhs rhs =>
      exprUsesRangeCheckedIntArith lhs ||
      exprUsesRangeCheckedIntArith rhs ||
      ty = .u128 || ty = .u64 || ty = .u32 || ty = .u16 || ty = .u8 || ty = .i16
  | .shlInt ty lhs _ =>
      exprUsesRangeCheckedIntArith lhs || ty = .u128 || ty = .u64 || ty = .u32 || ty = .u16 || ty = .u8 || ty = .i16
  | .shrInt ty lhs _ =>
      exprUsesRangeCheckedIntArith lhs || ty = .u128 || ty = .u64 || ty = .u32 || ty = .u16 || ty = .u8 || ty = .i16
  | .addU128 _ _ => true
  | .subU128 _ _ => true
  | .mulU128 _ _ => true
  | .divU128 _ _ => true
  | .modU128 _ _ => true
  | .bitAndU128 _ _ => true
  | .bitOrU128 _ _ => true
  | .bitXorU128 _ _ => true
  | .shlU128 _ _ => true
  | .shrU128 _ _ => true
  | .addU256 lhs rhs => exprUsesRangeCheckedIntArith lhs || exprUsesRangeCheckedIntArith rhs
  | .subU256 lhs rhs => exprUsesRangeCheckedIntArith lhs || exprUsesRangeCheckedIntArith rhs
  | .mulU256 lhs rhs => exprUsesRangeCheckedIntArith lhs || exprUsesRangeCheckedIntArith rhs
  | .divU256 lhs rhs => exprUsesRangeCheckedIntArith lhs || exprUsesRangeCheckedIntArith rhs
  | .modU256 lhs rhs => exprUsesRangeCheckedIntArith lhs || exprUsesRangeCheckedIntArith rhs
  | .bitAndU256 lhs rhs => exprUsesRangeCheckedIntArith lhs || exprUsesRangeCheckedIntArith rhs
  | .bitOrU256 lhs rhs => exprUsesRangeCheckedIntArith lhs || exprUsesRangeCheckedIntArith rhs
  | .bitXorU256 lhs rhs => exprUsesRangeCheckedIntArith lhs || exprUsesRangeCheckedIntArith rhs
  | .shlU256 lhs _ => exprUsesRangeCheckedIntArith lhs
  | .shrU256 lhs _ => exprUsesRangeCheckedIntArith lhs
  | .u256FromLimbs low high => exprUsesRangeCheckedIntArith low || exprUsesRangeCheckedIntArith high
  | .u256Low value => exprUsesRangeCheckedIntArith value
  | .u256High value => exprUsesRangeCheckedIntArith value
  | .eq lhs rhs => exprUsesRangeCheckedIntArith lhs || exprUsesRangeCheckedIntArith rhs
  | .ltInt _ lhs rhs => exprUsesRangeCheckedIntArith lhs || exprUsesRangeCheckedIntArith rhs
  | .leInt _ lhs rhs => exprUsesRangeCheckedIntArith lhs || exprUsesRangeCheckedIntArith rhs
  | .ltU128 lhs rhs => exprUsesRangeCheckedIntArith lhs || exprUsesRangeCheckedIntArith rhs
  | .leU128 lhs rhs => exprUsesRangeCheckedIntArith lhs || exprUsesRangeCheckedIntArith rhs
  | .ltU256 lhs rhs => exprUsesRangeCheckedIntArith lhs || exprUsesRangeCheckedIntArith rhs
  | .leU256 lhs rhs => exprUsesRangeCheckedIntArith lhs || exprUsesRangeCheckedIntArith rhs
  | .ite cond thenBranch elseBranch =>
      exprUsesRangeCheckedIntArith cond ||
      exprUsesRangeCheckedIntArith thenBranch ||
      exprUsesRangeCheckedIntArith elseBranch
  | .letE _ _ bound body =>
      exprUsesRangeCheckedIntArith bound || exprUsesRangeCheckedIntArith body

def u256ArithUnsupported (fnName : String) (opName : String) : EmitM α :=
  throw
    s!"unsupported u256 arithmetic ({opName}) in function '{fnName}': direct Sierra backend does not yet model struct-based u256 lowering and required helper semantics"

def unsupportedExpr (fnName : String) (msg : String) : EmitM α :=
  throw s!"unsupported expression in function '{fnName}': {msg}"

end LeanCairo.Backend.Sierra.Emit.Subset
