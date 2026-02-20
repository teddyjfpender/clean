import Lean.Data.Json
import LeanCairo.Backend.Sierra.Generated.Surface
import LeanCairo.Compiler.IR.Spec

namespace LeanCairo.Backend.Sierra.Emit

open Lean
open LeanCairo.Backend.Sierra.Generated
open LeanCairo.Compiler.IR
open LeanCairo.Core.Domain
open LeanCairo.Core.Spec

/-
Sierra subset backend invariants (phase-2 direct Lean -> Sierra lane):
- storage must be empty,
- functions must be view-only and write-free,
- supported function signature types: felt252, u128, bool,
- supported expressions:
  - vars / letE,
  - literals: felt252, u128, bool,
  - felt252 arithmetic: add/sub/mul,
  - top-level equality returns for felt252/u128.

Unsupported nodes fail fast with explicit errors.

Important semantic guardrails:
- u128/u256 arithmetic is still rejected in this lane until explicit RangeCheck and u256
  struct-semantics threading is modeled end-to-end.
- no implicit coercions are inserted.
-/

private abbrev EmitError := String

private def fnvOffset : UInt64 := 14695981039346656037
private def fnvPrime : UInt64 := 1099511628211

private def fnvStep (hash : UInt64) (byte : UInt8) : UInt64 :=
  (hash ^^^ UInt64.ofNat byte.toNat) * fnvPrime

private def fnv1a64 (value : String) : UInt64 :=
  value.toUTF8.foldl fnvStep fnvOffset

private def jsonU64 (value : UInt64) : Json :=
  Json.num (JsonNumber.fromNat value.toNat)

private def idJson (debugName : String) : Json :=
  Json.mkObj
    [
      ("id", jsonU64 (fnv1a64 debugName)),
      ("debug_name", Json.str debugName)
    ]

private def u32Modulus : Nat := 2 ^ 32

private def userTypeIdWords (debugName : String) : Array Nat :=
  (List.range 8).map (fun idx => (fnv1a64 s!"{debugName}#{idx}").toNat % u32Modulus) |>.toArray

private def userTypeArgJson (debugName : String) : Json :=
  Json.mkObj
    [
      ( "UserType",
        Json.mkObj
          [
            ("id", Json.arr (userTypeIdWords debugName |>.map (fun word => Json.num (JsonNumber.fromNat word)))),
            ("debug_name", Json.str debugName)
          ] )
    ]

private def unitTypeDebugName : String := "Unit"
private def boolTypeDebugName : String := "core::bool"
private def tupleUserTypeDebugName : String := "Tuple"

private def ensureKnownGenericTypeId (genericId : String) : Except EmitError Unit :=
  if genericTypeIds.contains genericId then
    .ok ()
  else
    .error s!"pinned Sierra surface does not contain generic type id '{genericId}'"

private def ensureKnownGenericLibfuncId (genericId : String) : Except EmitError Unit :=
  if genericLibfuncIds.contains genericId then
    .ok ()
  else
    .error s!"pinned Sierra surface does not contain generic libfunc id '{genericId}'"

private def tyGenericTypeId : Ty -> Except EmitError String
  | .felt252 => do
      ensureKnownGenericTypeId "felt252"
      pure "felt252"
  | .u128 => do
      ensureKnownGenericTypeId "u128"
      pure "u128"
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

private def tyDebugName (ty : Ty) : Except EmitError String := do
  match ty with
  | .bool => pure boolTypeDebugName
  | .nonZero innerTag => pure s!"NonZero<{innerTag}>"
  | _ =>
      let genericId <- tyGenericTypeId ty
      pure genericId

private def typeIdJson (ty : Ty) : Except EmitError Json := do
  let debugName <- tyDebugName ty
  pure (idJson debugName)

private def typeArgJson (tyId : Json) : Json :=
  Json.mkObj [("Type", tyId)]

private def innerTyOfNonZeroTag (innerTag : String) : Except EmitError Ty :=
  match innerTag with
  | "felt252" => .ok .felt252
  | "u128" => .ok .u128
  | "u256" => .ok .u256
  | "bool" => .ok .bool
  | _ => .error s!"unsupported NonZero inner tag '{innerTag}' in direct Sierra subset backend"

private def unitTypeDeclJson : Except EmitError Json := do
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

private def boolTypeDeclJson : Except EmitError Json := do
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

private def typeDeclJson (ty : Ty) : Except EmitError Json := do
  match ty with
  | .bool =>
      boolTypeDeclJson
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

private def bigIntJson (value : Int) : Json :=
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

private def valueArgJson (value : Int) : Json :=
  Json.mkObj [("Value", bigIntJson value)]

private def fallthroughTargetJson : Json :=
  Json.str "Fallthrough"

private def statementTargetJson (statementIdx : Nat) : Json :=
  Json.mkObj [("Statement", Json.num (JsonNumber.fromNat statementIdx))]

private def branchJson (target : Json) (results : List Json) : Json :=
  Json.mkObj [("target", target), ("results", Json.arr results.toArray)]

private def invocationStmtBranchesJson
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

private def invocationStmtJson (libfuncId : Json) (args : List Json) (results : List Json) : Json :=
  invocationStmtBranchesJson libfuncId args [(fallthroughTargetJson, results)]

private def returnStmtJson (results : List Json) : Json :=
  Json.mkObj [("Return", Json.arr results.toArray)]

private def paramVarDebugName (fnName : String) (paramName : String) : String :=
  s!"{fnName}::param::{paramName}"

private def insertDeclIfMissing
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
  deriving Inhabited

abbrev EmitM := StateT EmitState (Except EmitError)

private def liftExcept {α : Type} (value : Except EmitError α) : EmitM α := do
  match value with
  | .ok result => pure result
  | .error err => throw err

private def pushStmt (stmt : Json) : EmitM Unit :=
  modify (fun st => { st with statementsRev := stmt :: st.statementsRev })

private def freshVarId (fnName : String) (purpose : String) : EmitM Json := do
  let st <- get
  let idx := st.tempCounter
  set { st with tempCounter := idx + 1 }
  pure (idJson s!"{fnName}::tmp::{purpose}::{idx}")

private def registerTypeDecl (ty : Ty) : EmitM Json := do
  match ty with
  | .bool =>
      let unitDecl <- liftExcept unitTypeDeclJson
      modify (fun st => { st with typeDecls := insertDeclIfMissing st.typeDecls unitTypeDebugName unitDecl })
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

private def registerLibfuncDecl (debugName : String) (genericId : String) (genericArgs : List Json) : EmitM Json := do
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

private def storeTempDebugName (ty : Ty) : Except EmitError String := do
  let typeName <- tyDebugName ty
  pure s!"store_temp_{typeName}"

private def dupDebugName (ty : Ty) : Except EmitError String := do
  let typeName <- tyDebugName ty
  pure s!"dup_{typeName}"

private def dropDebugName (ty : Ty) : Except EmitError String := do
  let typeName <- tyDebugName ty
  pure s!"drop_{typeName}"

private def emitStoreTemp (fnName : String) (ty : Ty) (valueVar : Json) : EmitM Json := do
  let tyId <- registerTypeDecl ty
  let debugName <- liftExcept (storeTempDebugName ty)
  let libfuncId <- registerLibfuncDecl debugName "store_temp" [typeArgJson tyId]
  let outVar <- freshVarId fnName "store_temp"
  pushStmt (invocationStmtJson libfuncId [valueVar] [outVar])
  pure outVar

private def emitDrop (fnName : String) (ty : Ty) (valueVar : Json) : EmitM Unit := do
  let tyId <- registerTypeDecl ty
  let debugName <- liftExcept (dropDebugName ty)
  let libfuncId <- registerLibfuncDecl debugName "drop" [typeArgJson tyId]
  let _ <- freshVarId fnName "drop"
  pushStmt (invocationStmtJson libfuncId [valueVar] [])

private def nextStatementIdx : EmitM Nat := do
  pure (←get).statementsRev.length

private def emitBranchAlign : EmitM Unit := do
  let branchAlignLibfuncId <- registerLibfuncDecl "branch_align" "branch_align" []
  pushStmt (invocationStmtJson branchAlignLibfuncId [] [])

private def emitJump (targetIdx : Nat) : EmitM Unit := do
  let jumpLibfuncId <- registerLibfuncDecl "jump" "jump" []
  pushStmt (invocationStmtBranchesJson jumpLibfuncId [] [(statementTargetJson targetIdx, [])])

private def boolVariantDebugName (value : Bool) : String :=
  if value then
    s!"enum_init<{boolTypeDebugName}, 1>"
  else
    s!"enum_init<{boolTypeDebugName}, 0>"

private def emitBoolConst (fnName : String) (value : Bool) : EmitM Json := do
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

private def feltConstDebugName (value : Int) : String :=
  if value < 0 then
    s!"felt252_const_neg_{value.natAbs}"
  else
    s!"felt252_const_pos_{value.natAbs}"

private def emitFeltConst (fnName : String) (value : Int) : EmitM Json := do
  let _ <- registerTypeDecl .felt252
  let debugName := feltConstDebugName value
  let libfuncId <- registerLibfuncDecl debugName "felt252_const" [valueArgJson value]
  let rawVar <- freshVarId fnName "felt_const_raw"
  pushStmt (invocationStmtJson libfuncId [] [rawVar])
  emitStoreTemp fnName .felt252 rawVar

private def u128ConstDebugName (value : Nat) : String :=
  s!"u128_const_{value}"

private def emitU128Const (fnName : String) (value : Nat) : EmitM Json := do
  let _ <- registerTypeDecl .u128
  let libfuncId <- registerLibfuncDecl (u128ConstDebugName value) "u128_const" [valueArgJson (Int.ofNat value)]
  let rawVar <- freshVarId fnName "u128_const_raw"
  pushStmt (invocationStmtJson libfuncId [] [rawVar])
  emitStoreTemp fnName .u128 rawVar

private structure LinearVar where
  ty : Ty
  remaining : Nat
  current? : Option Json
  deriving Inhabited

private abbrev Env := List (String × LinearVar)

private partial def pendingDropCount (env : Env) : Except EmitError Nat := do
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

private partial def countVarUses (target : String) : IRExpr ty -> Nat
  | .var name => if name = target then 1 else 0
  | .storageRead _ => 0
  | .litU128 _ => 0
  | .litU256 _ => 0
  | .litBool _ => 0
  | .litFelt252 _ => 0
  | .addFelt252 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .subFelt252 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .mulFelt252 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .addU128 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .subU128 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .mulU128 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .addU256 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .subU256 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .mulU256 lhs rhs => countVarUses target lhs + countVarUses target rhs
  | .eq lhs rhs => countVarUses target lhs + countVarUses target rhs
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

private partial def consumeVar
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

private def u128ArithUnsupported (fnName : String) (opName : String) : EmitM α :=
  throw
    s!"unsupported u128 arithmetic ({opName}) in function '{fnName}': direct Sierra backend does not yet model RangeCheck threading for semantics-preserving lowering"

private def u256ArithUnsupported (fnName : String) (opName : String) : EmitM α :=
  throw
    s!"unsupported u256 arithmetic ({opName}) in function '{fnName}': direct Sierra backend does not yet model struct-based u256 lowering and required helper semantics"

private def unsupportedExpr (fnName : String) (msg : String) : EmitM α :=
  throw s!"unsupported expression in function '{fnName}': {msg}"

mutual

private partial def emitFeltBinary
    (fnName : String)
    (genericId : String)
    (purpose : String)
    (env : Env)
    (lhs rhs : IRExpr .felt252) : EmitM (Env × Json) := do
  let (envAfterLhs, lhsVar) <- emitExpr fnName env lhs
  let (envAfterRhs, rhsVar) <- emitExpr fnName envAfterLhs rhs
  let _ <- registerTypeDecl .felt252
  let libfuncId <- registerLibfuncDecl genericId genericId []
  let rawVar <- freshVarId fnName s!"{purpose}_raw"
  pushStmt (invocationStmtJson libfuncId [lhsVar, rhsVar] [rawVar])
  let materialized <- emitStoreTemp fnName .felt252 rawVar
  pure (envAfterRhs, materialized)

partial def emitExpr (fnName : String) (env : Env) : IRExpr ty -> EmitM (Env × Json)
  | .var name =>
      consumeVar fnName env ty name
  | .storageRead _ =>
      unsupportedExpr fnName "storage reads are not supported in direct Sierra subset backend"
  | .litU128 value => do
      let outVar <- emitU128Const fnName value
      pure (env, outVar)
  | .litU256 _ =>
      unsupportedExpr fnName "u256 literals are not yet supported"
  | .litBool value => do
      let outVar <- emitBoolConst fnName value
      pure (env, outVar)
  | .litFelt252 value => do
      let outVar <- emitFeltConst fnName value
      pure (env, outVar)
  | .addFelt252 lhs rhs =>
      emitFeltBinary fnName "felt252_add" "felt_add" env lhs rhs
  | .subFelt252 lhs rhs =>
      emitFeltBinary fnName "felt252_sub" "felt_sub" env lhs rhs
  | .mulFelt252 lhs rhs =>
      emitFeltBinary fnName "felt252_mul" "felt_mul" env lhs rhs
  | .addU128 _ _ =>
      u128ArithUnsupported fnName "add"
  | .subU128 _ _ =>
      u128ArithUnsupported fnName "sub"
  | .mulU128 _ _ =>
      u128ArithUnsupported fnName "mul"
  | .addU256 _ _ =>
      u256ArithUnsupported fnName "add"
  | .subU256 _ _ =>
      u256ArithUnsupported fnName "sub"
  | .mulU256 _ _ =>
      u256ArithUnsupported fnName "mul"
  | .eq _ _ =>
      unsupportedExpr fnName "equality lowering is currently supported only for top-level return expressions"
  | .ltU128 _ _ =>
      unsupportedExpr fnName "ltU128 lowering is not yet implemented"
  | .leU128 _ _ =>
      unsupportedExpr fnName "leU128 lowering is not yet implemented"
  | .ltU256 _ _ =>
      unsupportedExpr fnName "ltU256 lowering is not yet implemented"
  | .leU256 _ _ =>
      unsupportedExpr fnName "leU256 lowering is not yet implemented"
  | .ite _ _ _ =>
      unsupportedExpr fnName "ite lowering is not yet implemented"
  | .letE name boundTy bound body => do
      let (envAfterBound, boundVar) <- emitExpr fnName env bound
      let useCount := countVarUses name body
      if useCount = 0 then
        emitDrop fnName boundTy boundVar
        emitExpr fnName envAfterBound body
      else
        let boundState : LinearVar := { ty := boundTy, remaining := useCount, current? := some boundVar }
        let (envAfterBody, bodyVar) <- emitExpr fnName ((name, boundState) :: envAfterBound) body
        match envAfterBody with
        | [] =>
            throw s!"internal error: let-binding scope lost for '{name}' in function '{fnName}'"
        | (boundName, finalBoundState) :: rest =>
            if boundName != name then
              throw s!"internal error: let-binding stack mismatch for '{name}' in function '{fnName}'"
            else if finalBoundState.remaining != 0 then
              throw s!"internal error: let-binding '{name}' has non-zero remaining uses in function '{fnName}'"
            else if finalBoundState.current?.isSome then
              throw s!"internal error: let-binding '{name}' still has live value after body in function '{fnName}'"
            else
              pure (rest, bodyVar)

end

private partial def dropRemainingEnv (fnName : String) (env : Env) : EmitM Unit := do
  match env with
  | [] => pure ()
  | (_, entry) :: rest =>
      if entry.remaining != 0 then
        throw s!"internal error: remaining variable uses are non-zero at function end ('{fnName}')"
      else
        match entry.current? with
        | some valueVar =>
            emitDrop fnName entry.ty valueVar
            dropRemainingEnv fnName rest
        | none =>
            dropRemainingEnv fnName rest

private def emitBoolReturnBranch
    (fnName : String)
    (env : Env)
    (value : Bool)
    (extraDrops : List (Ty × Json) := []) : EmitM Unit := do
  emitBranchAlign
  for dropSpec in extraDrops do
    emitDrop fnName dropSpec.fst dropSpec.snd
  dropRemainingEnv fnName env
  let boolVar <- emitBoolConst fnName value
  pushStmt (returnStmtJson [boolVar])

private def emitTailEqReturnBool
    (baseStatementIdx : Nat)
    (fnName : String)
    (env : Env)
    (lhs rhs : IRExpr eqTy) : EmitM Unit := do
  match eqTy with
  | .felt252 => do
      let (envAfterLhs, lhsVar) <- emitExpr fnName env lhs
      let (envAfterRhs, rhsVar) <- emitExpr fnName envAfterLhs rhs
      let _ <- registerTypeDecl .felt252
      let subLibfuncId <- registerLibfuncDecl "felt252_sub" "felt252_sub" []
      let diffRawVar <- freshVarId fnName "eq_felt_diff_raw"
      pushStmt (invocationStmtJson subLibfuncId [lhsVar, rhsVar] [diffRawVar])
      let diffVar <- emitStoreTemp fnName .felt252 diffRawVar

      let currentIdx <- nextStatementIdx
      let dropCount <- liftExcept (pendingDropCount envAfterRhs)
      let trueBranchLen := dropCount + 5
      let falseBranchTarget := baseStatementIdx + currentIdx + 1 + trueBranchLen

      let isZeroLibfuncId <- registerLibfuncDecl "felt252_is_zero" "felt252_is_zero" []
      let nonZeroDiffVar <- freshVarId fnName "eq_felt_non_zero"
      pushStmt <|
        invocationStmtBranchesJson
          isZeroLibfuncId
          [diffVar]
          [
            (fallthroughTargetJson, []),
            (statementTargetJson falseBranchTarget, [nonZeroDiffVar])
          ]

      emitBoolReturnBranch fnName envAfterRhs true
      emitBoolReturnBranch fnName envAfterRhs false [(.nonZero "felt252", nonZeroDiffVar)]
  | .u128 => do
      let (envAfterLhs, lhsVar) <- emitExpr fnName env lhs
      let (envAfterRhs, rhsVar) <- emitExpr fnName envAfterLhs rhs
      let _ <- registerTypeDecl .u128
      let currentIdx <- nextStatementIdx
      let dropCount <- liftExcept (pendingDropCount envAfterRhs)
      let falseBranchLen := dropCount + 5
      let trueBranchTarget := baseStatementIdx + currentIdx + 1 + falseBranchLen

      let u128EqLibfuncId <- registerLibfuncDecl "u128_eq" "u128_eq" []
      pushStmt <|
        invocationStmtBranchesJson
          u128EqLibfuncId
          [lhsVar, rhsVar]
          [
            (fallthroughTargetJson, []),
            (statementTargetJson trueBranchTarget, [])
          ]

      emitBoolReturnBranch fnName envAfterRhs false
      emitBoolReturnBranch fnName envAfterRhs true
  | _ =>
      unsupportedExpr fnName s!"equality lowering for type '{Ty.toCairo eqTy}' is not yet implemented"

private def ensureFunctionTySupported (fnName : String) (whereLabel : String) (ty : Ty) : Except EmitError Unit := do
  match ty with
  | .felt252 => pure ()
  | .u128 => pure ()
  | .bool => pure ()
  | _ =>
      .error s!"unsupported {whereLabel} type '{Ty.toCairo ty}' in function '{fnName}'"

private def ensureViewNoWrites (fnSpec : IRFuncSpec) : Except EmitError Unit :=
  if fnSpec.mutability != .view then
    .error s!"Sierra subset backend currently supports view functions only ('{fnSpec.name}')"
  else if !fnSpec.writes.isEmpty then
    .error s!"Sierra subset backend currently forbids storage writes ('{fnSpec.name}')"
  else
    .ok ()

private structure EmittedFunction where
  funcJson : Json
  statements : List Json
  typeDecls : List (String × Json)
  libfuncDecls : List (String × Json)

private def emitFunction (entryPoint : Nat) (fnSpec : IRFuncSpec) : Except EmitError EmittedFunction := do
  ensureViewNoWrites fnSpec
  fnSpec.args.forM (fun arg => ensureFunctionTySupported fnSpec.name "parameter" arg.ty)
  ensureFunctionTySupported fnSpec.name "return" fnSpec.ret

  let paramTypeIds <- fnSpec.args.mapM (fun arg => typeIdJson arg.ty)
  let retTypeId <- typeIdJson fnSpec.ret

  let initialEnv : Env :=
    fnSpec.args.map (fun param =>
      ( param.name,
        {
          ty := param.ty
          remaining := countVarUses param.name fnSpec.body
          current? := some (idJson (paramVarDebugName fnSpec.name param.name))
        } ))

  let emitAction : EmitM Unit := do
    for arg in fnSpec.args do
      let _ <- registerTypeDecl arg.ty
    let _ <- registerTypeDecl fnSpec.ret
    if hRet : fnSpec.ret = .bool then
      let bodyBool : IRExpr .bool := by
        simpa [hRet] using fnSpec.body
      match bodyBool with
      | .eq lhs rhs =>
          emitTailEqReturnBool entryPoint fnSpec.name initialEnv lhs rhs
      | _ =>
          let (envAfterBody, bodyValueVar) <- emitExpr fnSpec.name initialEnv fnSpec.body
          dropRemainingEnv fnSpec.name envAfterBody
          let retTemp <- emitStoreTemp fnSpec.name fnSpec.ret bodyValueVar
          pushStmt (returnStmtJson [retTemp])
    else
      let (envAfterBody, bodyValueVar) <- emitExpr fnSpec.name initialEnv fnSpec.body
      dropRemainingEnv fnSpec.name envAfterBody
      let retTemp <- emitStoreTemp fnSpec.name fnSpec.ret bodyValueVar
      pushStmt (returnStmtJson [retTemp])

  match emitAction.run {} with
  | .error err => .error err
  | .ok (_, st) =>
      let signatureJson :=
        Json.mkObj
          [
            ("param_types", Json.arr paramTypeIds.toArray),
            ("ret_types", Json.arr #[retTypeId])
          ]
      let paramsJson :=
        Json.arr
          (fnSpec.args.map (fun param =>
              Json.mkObj
                [
                  ("id", idJson (paramVarDebugName fnSpec.name param.name)),
                  ("ty", (typeIdJson param.ty).toOption.getD Json.null)
                ])).toArray
      let funcJson :=
        Json.mkObj
          [
            ("id", idJson fnSpec.name),
            ("signature", signatureJson),
            ("params", paramsJson),
            ("entry_point", Json.num (JsonNumber.fromNat entryPoint))
          ]
      pure
        {
          funcJson := funcJson
          statements := st.statementsRev.reverse
          typeDecls := st.typeDecls
          libfuncDecls := st.libfuncDecls
        }

private def mergeDecls
    (base : List (String × Json))
    (extra : List (String × Json)) : List (String × Json) :=
  extra.foldl (fun acc entry => insertDeclIfMissing acc entry.fst entry.snd) base

def renderSubsetProgramJson (spec : IRContractSpec) : Except EmitError String := do
  if !spec.storage.isEmpty then
    .error "Sierra subset backend currently requires empty storage declaration"
  else if spec.functions.isEmpty then
    .error "Sierra subset backend requires at least one function"
  else
    let rec emitFunctions
        (entryPoint : Nat)
        (remaining : List IRFuncSpec)
        (funcsAcc : List Json)
        (stmtsAcc : List Json)
        (typeDeclsAcc : List (String × Json))
        (libDeclsAcc : List (String × Json)) :
        Except EmitError (List Json × List Json × List (String × Json) × List (String × Json)) := do
      match remaining with
      | [] =>
          pure (funcsAcc.reverse, stmtsAcc.reverse, typeDeclsAcc, libDeclsAcc)
      | fnSpec :: rest =>
          let emitted <- emitFunction entryPoint fnSpec
          let newEntryPoint := entryPoint + emitted.statements.length
          emitFunctions
            newEntryPoint
            rest
            (emitted.funcJson :: funcsAcc)
            (emitted.statements.reverse ++ stmtsAcc)
            (mergeDecls typeDeclsAcc emitted.typeDecls)
            (mergeDecls libDeclsAcc emitted.libfuncDecls)

    let (funcsJson, statementsJson, typeDecls, libDecls) <-
      emitFunctions 0 spec.functions [] [] [] []
    let programJson :=
      Json.mkObj
        [
          ("version", Json.num (JsonNumber.fromNat 1)),
          ("type_declarations", Json.arr (typeDecls.map Prod.snd).toArray),
          ("libfunc_declarations", Json.arr (libDecls.map Prod.snd).toArray),
          ("statements", Json.arr statementsJson.toArray),
          ("funcs", Json.arr funcsJson.toArray)
        ]
    pure (toString programJson)

end LeanCairo.Backend.Sierra.Emit
