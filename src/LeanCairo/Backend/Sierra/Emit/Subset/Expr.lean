import LeanCairo.Backend.Sierra.Emit.Subset.Foundation

namespace LeanCairo.Backend.Sierra.Emit.Subset

open Lean
open LeanCairo.Compiler.IR
open LeanCairo.Core.Domain
open LeanCairo.Core.Spec

mutual

partial def emitFeltBinary
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

partial def emitU128OverflowingWrapping
    (fnName : String)
    (env : Env)
    (lhs rhs : IRExpr .u128)
    (genericId : String)
    (opTag : String) : EmitM (Env × Json) := do
  let (envAfterLhs, lhsVar) <- emitExpr fnName env lhs
  let (envAfterRhs, rhsVar) <- emitExpr fnName envAfterLhs rhs
  let rcIn <- requireRangeCheckVar fnName
  let _ <- registerTypeDecl .rangeCheck
  let _ <- registerTypeDecl .u128
  let invocationIdx <- nextAbsoluteStatementIdx
  let overflowTarget := invocationIdx + 5

  let overflowingLibfuncId <- registerLibfuncDecl genericId genericId []
  let rcNonOverflow <- freshVarId fnName s!"{opTag}_range_check_non_overflow"
  let valueNonOverflow <- freshVarId fnName s!"{opTag}_result_non_overflow"
  let rcOverflow <- freshVarId fnName s!"{opTag}_range_check_overflow"
  let valueOverflow <- freshVarId fnName s!"{opTag}_result_overflow"
  pushStmt <|
    invocationStmtBranchesJson
      overflowingLibfuncId
      [rcIn, lhsVar, rhsVar]
      [
        (fallthroughTargetJson, [rcNonOverflow, valueNonOverflow]),
        (statementTargetJson overflowTarget, [rcOverflow, valueOverflow])
      ]

  emitBranchAlign
  let mergedRangeCheck <- freshVarId fnName s!"{opTag}_range_check_merged"
  let mergedValue <- freshVarId fnName s!"{opTag}_result_merged"
  emitStoreTempTo .rangeCheck rcNonOverflow mergedRangeCheck
  emitStoreTempTo .u128 valueNonOverflow mergedValue
  emitJump (invocationIdx + 8)

  emitBranchAlign
  emitStoreTempTo .rangeCheck rcOverflow mergedRangeCheck
  emitStoreTempTo .u128 valueOverflow mergedValue
  setRangeCheckVar mergedRangeCheck
  pure (envAfterRhs, mergedValue)

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
  | .addU128 lhs rhs =>
      emitU128OverflowingWrapping fnName env lhs rhs "u128_overflowing_add" "u128_add"
  | .subU128 lhs rhs =>
      emitU128OverflowingWrapping fnName env lhs rhs "u128_overflowing_sub" "u128_sub"
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

partial def dropRemainingEnv (fnName : String) (env : Env) : EmitM Unit := do
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

def emitBoolReturnBranch
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

def emitTailEqReturnBool
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

end LeanCairo.Backend.Sierra.Emit.Subset
