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

partial def emitU128MulWrapping
    (fnName : String)
    (env : Env)
    (lhs rhs : IRExpr .u128) : EmitM (Env × Json) := do
  let (envAfterLhs, lhsVar) <- emitExpr fnName env lhs
  let (envAfterRhs, rhsVar) <- emitExpr fnName envAfterLhs rhs
  let rcIn <- requireRangeCheckVar fnName
  let _ <- registerTypeDecl .rangeCheck
  let _ <- registerTypeDecl .u128
  let _ <- registerU128MulGuaranteeTypeDecl

  let mulLibfuncId <- registerLibfuncDecl "u128_guarantee_mul" "u128_guarantee_mul" []
  let highRaw <- freshVarId fnName "u128_mul_high_raw"
  let lowRaw <- freshVarId fnName "u128_mul_low_raw"
  let guaranteeRaw <- freshVarId fnName "u128_mul_guarantee_raw"
  pushStmt (invocationStmtJson mulLibfuncId [lhsVar, rhsVar] [highRaw, lowRaw, guaranteeRaw])

  -- Wrapping semantics retain only the low limb (`mod 2^128`) and explicitly drop the high limb.
  emitDrop fnName .u128 highRaw
  let verifyLibfuncId <-
    registerLibfuncDecl "u128_mul_guarantee_verify" "u128_mul_guarantee_verify" []
  let rcOut <- freshVarId fnName "u128_mul_range_check_out"
  pushStmt (invocationStmtJson verifyLibfuncId [rcIn, guaranteeRaw] [rcOut])
  setRangeCheckVar rcOut

  let outVar <- emitStoreTemp fnName .u128 lowRaw
  pure (envAfterRhs, outVar)

partial def emitU64OverflowingWrapping
    (fnName : String)
    (env : Env)
    (lhs rhs : IRExpr .u64)
    (genericId : String)
    (opTag : String) : EmitM (Env × Json) := do
  let (envAfterLhs, lhsVar) <- emitExpr fnName env lhs
  let (envAfterRhs, rhsVar) <- emitExpr fnName envAfterLhs rhs
  let rcIn <- requireRangeCheckVar fnName
  let _ <- registerTypeDecl .rangeCheck
  let _ <- registerTypeDecl .u64
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
  emitStoreTempTo .u64 valueNonOverflow mergedValue
  emitJump (invocationIdx + 8)

  emitBranchAlign
  emitStoreTempTo .rangeCheck rcOverflow mergedRangeCheck
  emitStoreTempTo .u64 valueOverflow mergedValue
  setRangeCheckVar mergedRangeCheck
  pure (envAfterRhs, mergedValue)

partial def emitU64MulWrapping
    (fnName : String)
    (env : Env)
    (lhs rhs : IRExpr .u64) : EmitM (Env × Json) := do
  let (envAfterLhs, lhsVar) <- emitExpr fnName env lhs
  let (envAfterRhs, rhsVar) <- emitExpr fnName envAfterLhs rhs
  let rcIn <- requireRangeCheckVar fnName
  let _ <- registerTypeDecl .rangeCheck
  let _ <- registerTypeDecl .u64
  let _ <- registerTypeDecl .u128
  let _ <- registerTypeDecl (.nonZero "u128")

  let wideMulLibfuncId <- registerLibfuncDecl "u64_wide_mul" "u64_wide_mul" []
  let wideProductRaw <- freshVarId fnName "u64_mul_wide_product_raw"
  pushStmt (invocationStmtJson wideMulLibfuncId [lhsVar, rhsVar] [wideProductRaw])
  let wideProduct <- emitStoreTemp fnName .u128 wideProductRaw

  let modulusNonZero <- emitNonZeroU128Const fnName (2 ^ 64)

  let safeDivmodLibfuncId <- registerLibfuncDecl "u128_safe_divmod" "u128_safe_divmod" []
  let rcAfterDiv <- freshVarId fnName "u64_mul_range_check_after_divmod"
  let quotientRaw <- freshVarId fnName "u64_mul_quotient_raw"
  let remainderRaw <- freshVarId fnName "u64_mul_remainder_raw"
  pushStmt <|
    invocationStmtJson
      safeDivmodLibfuncId
      [rcIn, wideProduct, modulusNonZero]
      [rcAfterDiv, quotientRaw, remainderRaw]
  emitDrop fnName .u128 quotientRaw

  let u128TyId <- registerTypeDecl .u128
  let u64TyId <- registerTypeDecl .u64
  let downcastLibfuncId <-
    registerLibfuncDecl
      "downcast_u128_to_u64"
      "downcast"
      [typeArgJson u128TyId, typeArgJson u64TyId]

  let downcastInvocationIdx <- nextAbsoluteStatementIdx
  let downcastOverflowTarget := downcastInvocationIdx + 5

  let rcDowncastOk <- freshVarId fnName "u64_mul_range_check_downcast_ok"
  let valueDowncastOk <- freshVarId fnName "u64_mul_value_downcast_ok"
  let rcDowncastOverflow <- freshVarId fnName "u64_mul_range_check_downcast_overflow"
  pushStmt <|
    invocationStmtBranchesJson
      downcastLibfuncId
      [rcAfterDiv, remainderRaw]
      [
        (fallthroughTargetJson, [rcDowncastOk, valueDowncastOk]),
        (statementTargetJson downcastOverflowTarget, [rcDowncastOverflow])
      ]

  emitBranchAlign
  let mergedRangeCheck <- freshVarId fnName "u64_mul_range_check_merged"
  let mergedValue <- freshVarId fnName "u64_mul_value_merged"
  emitStoreTempTo .rangeCheck rcDowncastOk mergedRangeCheck
  emitStoreTempTo .u64 valueDowncastOk mergedValue
  emitJump (downcastInvocationIdx + 10)

  emitBranchAlign
  -- `remainderRaw` is mathematically `< 2^64`; overflow branch is unreachable.
  -- Keep branch shape total by materializing a deterministic placeholder.
  let unreachableFallback <- emitU64Const fnName 0
  emitStoreTempTo .rangeCheck rcDowncastOverflow mergedRangeCheck
  emitStoreTempTo .u64 unreachableFallback mergedValue
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
  | .litInt .u128 value => do
      let outVar <- emitU128Const fnName value
      pure (env, outVar)
  | .litInt .u64 value => do
      let outVar <- emitU64Const fnName value
      pure (env, outVar)
  | .litInt ty _ =>
      unsupportedExpr fnName s!"typed literal lowering is not yet implemented for '{Ty.toCairo ty}'"
  | .addFelt252 lhs rhs =>
      emitFeltBinary fnName "felt252_add" "felt_add" env lhs rhs
  | .subFelt252 lhs rhs =>
      emitFeltBinary fnName "felt252_sub" "felt_sub" env lhs rhs
  | .mulFelt252 lhs rhs =>
      emitFeltBinary fnName "felt252_mul" "felt_mul" env lhs rhs
  | .addInt .u128 lhs rhs =>
      emitU128OverflowingWrapping fnName env lhs rhs "u128_overflowing_add" "u128_add"
  | .addInt .u64 lhs rhs =>
      emitU64OverflowingWrapping fnName env lhs rhs "u64_overflowing_add" "u64_add"
  | .addInt ty _ _ =>
      unsupportedExpr fnName s!"typed integer add lowering is not yet implemented for '{Ty.toCairo ty}'"
  | .subInt .u128 lhs rhs =>
      emitU128OverflowingWrapping fnName env lhs rhs "u128_overflowing_sub" "u128_sub"
  | .subInt .u64 lhs rhs =>
      emitU64OverflowingWrapping fnName env lhs rhs "u64_overflowing_sub" "u64_sub"
  | .subInt ty _ _ =>
      unsupportedExpr fnName s!"typed integer sub lowering is not yet implemented for '{Ty.toCairo ty}'"
  | .mulInt .u128 lhs rhs =>
      emitU128MulWrapping fnName env lhs rhs
  | .mulInt .u64 lhs rhs =>
      emitU64MulWrapping fnName env lhs rhs
  | .mulInt ty _ _ =>
      unsupportedExpr fnName s!"typed integer mul lowering is not yet implemented for '{Ty.toCairo ty}'"
  | .divInt ty _ _ =>
      unsupportedExpr fnName s!"typed integer div lowering is not yet implemented for '{Ty.toCairo ty}'"
  | .modInt ty _ _ =>
      unsupportedExpr fnName s!"typed integer mod lowering is not yet implemented for '{Ty.toCairo ty}'"
  | .bitAndInt ty _ _ =>
      unsupportedExpr fnName s!"typed integer bit-and lowering is not yet implemented for '{Ty.toCairo ty}'"
  | .bitOrInt ty _ _ =>
      unsupportedExpr fnName s!"typed integer bit-or lowering is not yet implemented for '{Ty.toCairo ty}'"
  | .bitXorInt ty _ _ =>
      unsupportedExpr fnName s!"typed integer bit-xor lowering is not yet implemented for '{Ty.toCairo ty}'"
  | .shlInt ty _ _ =>
      unsupportedExpr fnName s!"typed integer shl lowering is not yet implemented for '{Ty.toCairo ty}'"
  | .shrInt ty _ _ =>
      unsupportedExpr fnName s!"typed integer shr lowering is not yet implemented for '{Ty.toCairo ty}'"
  | .addU128 lhs rhs =>
      emitU128OverflowingWrapping fnName env lhs rhs "u128_overflowing_add" "u128_add"
  | .subU128 lhs rhs =>
      emitU128OverflowingWrapping fnName env lhs rhs "u128_overflowing_sub" "u128_sub"
  | .mulU128 lhs rhs =>
      emitU128MulWrapping fnName env lhs rhs
  | .divU128 _ _ =>
      u128ArithUnsupported fnName "div"
  | .modU128 _ _ =>
      u128ArithUnsupported fnName "mod"
  | .bitAndU128 _ _ =>
      u128ArithUnsupported fnName "bit_and"
  | .bitOrU128 _ _ =>
      u128ArithUnsupported fnName "bit_or"
  | .bitXorU128 _ _ =>
      u128ArithUnsupported fnName "bit_xor"
  | .shlU128 _ _ =>
      u128ArithUnsupported fnName "shl"
  | .shrU128 _ _ =>
      u128ArithUnsupported fnName "shr"
  | .addU256 _ _ =>
      u256ArithUnsupported fnName "add"
  | .subU256 _ _ =>
      u256ArithUnsupported fnName "sub"
  | .mulU256 _ _ =>
      u256ArithUnsupported fnName "mul"
  | .divU256 _ _ =>
      u256ArithUnsupported fnName "div"
  | .modU256 _ _ =>
      u256ArithUnsupported fnName "mod"
  | .bitAndU256 _ _ =>
      u256ArithUnsupported fnName "bit_and"
  | .bitOrU256 _ _ =>
      u256ArithUnsupported fnName "bit_or"
  | .bitXorU256 _ _ =>
      u256ArithUnsupported fnName "bit_xor"
  | .shlU256 _ _ =>
      u256ArithUnsupported fnName "shl"
  | .shrU256 _ _ =>
      u256ArithUnsupported fnName "shr"
  | .u256FromLimbs _ _ =>
      u256ArithUnsupported fnName "from_limbs"
  | .u256Low _ =>
      u256ArithUnsupported fnName "low"
  | .u256High _ =>
      u256ArithUnsupported fnName "high"
  | .eq _ _ =>
      unsupportedExpr fnName "equality lowering is currently supported only for top-level return expressions"
  | .ltInt ty _ _ =>
      unsupportedExpr fnName s!"typed integer lt lowering is not yet implemented for '{Ty.toCairo ty}'"
  | .leInt ty _ _ =>
      unsupportedExpr fnName s!"typed integer le lowering is not yet implemented for '{Ty.toCairo ty}'"
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

def emitTailTypedEqReturnBool
    (baseStatementIdx : Nat)
    (fnName : String)
    (env : Env)
    (eqTy : Ty)
    (eqLibfuncGenericId : String)
    (lhs rhs : IRExpr eqTy) : EmitM Unit := do
  let (envAfterLhs, lhsVar) <- emitExpr fnName env lhs
  let (envAfterRhs, rhsVar) <- emitExpr fnName envAfterLhs rhs
  let _ <- registerTypeDecl eqTy
  let currentIdx <- nextStatementIdx
  let dropCount <- liftExcept (pendingDropCount envAfterRhs)
  let falseBranchLen := dropCount + 5
  let trueBranchTarget := baseStatementIdx + currentIdx + 1 + falseBranchLen

  let eqLibfuncId <- registerLibfuncDecl eqLibfuncGenericId eqLibfuncGenericId []
  pushStmt <|
    invocationStmtBranchesJson
      eqLibfuncId
      [lhsVar, rhsVar]
      [
        (fallthroughTargetJson, []),
        (statementTargetJson trueBranchTarget, [])
      ]

  emitBoolReturnBranch fnName envAfterRhs false
  emitBoolReturnBranch fnName envAfterRhs true

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
  | .u8 =>
      emitTailTypedEqReturnBool baseStatementIdx fnName env .u8 "u8_eq" lhs rhs
  | .u16 =>
      emitTailTypedEqReturnBool baseStatementIdx fnName env .u16 "u16_eq" lhs rhs
  | .u32 =>
      emitTailTypedEqReturnBool baseStatementIdx fnName env .u32 "u32_eq" lhs rhs
  | .u64 =>
      emitTailTypedEqReturnBool baseStatementIdx fnName env .u64 "u64_eq" lhs rhs
  | .u128 =>
      emitTailTypedEqReturnBool baseStatementIdx fnName env .u128 "u128_eq" lhs rhs
  | .i8 =>
      emitTailTypedEqReturnBool baseStatementIdx fnName env .i8 "i8_eq" lhs rhs
  | .i16 =>
      emitTailTypedEqReturnBool baseStatementIdx fnName env .i16 "i16_eq" lhs rhs
  | .i32 =>
      emitTailTypedEqReturnBool baseStatementIdx fnName env .i32 "i32_eq" lhs rhs
  | .i64 =>
      emitTailTypedEqReturnBool baseStatementIdx fnName env .i64 "i64_eq" lhs rhs
  | .i128 =>
      emitTailTypedEqReturnBool baseStatementIdx fnName env .i128 "i128_eq" lhs rhs
  | _ =>
      unsupportedExpr fnName s!"equality lowering for type '{Ty.toCairo eqTy}' is not yet implemented"

end LeanCairo.Backend.Sierra.Emit.Subset
