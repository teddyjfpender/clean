import LeanCairo.Backend.Sierra.Emit.Subset.Expr

namespace LeanCairo.Backend.Sierra.Emit.Subset

open Lean
open LeanCairo.Compiler.IR
open LeanCairo.Core.Domain
open LeanCairo.Core.Spec

def ensureFunctionTySupported (fnName : String) (whereLabel : String) (ty : Ty) : Except EmitError Unit := do
  match ty with
  | .felt252 => pure ()
  | .u128 => pure ()
  | .bool => pure ()
  | _ =>
      .error s!"unsupported {whereLabel} type '{Ty.toCairo ty}' in function '{fnName}'"

def ensureViewNoWrites (fnSpec : IRFuncSpec) : Except EmitError Unit :=
  if fnSpec.mutability != .view then
    .error s!"Sierra subset backend currently supports view functions only ('{fnSpec.name}')"
  else if !fnSpec.writes.isEmpty then
    .error s!"Sierra subset backend currently forbids storage writes ('{fnSpec.name}')"
  else
    .ok ()

structure EmittedFunction where
  funcJson : Json
  statements : List Json
  typeDecls : List (String × Json)
  libfuncDecls : List (String × Json)

def emitFunction (entryPoint : Nat) (fnSpec : IRFuncSpec) : Except EmitError EmittedFunction := do
  ensureViewNoWrites fnSpec
  fnSpec.args.forM (fun arg => ensureFunctionTySupported fnSpec.name "parameter" arg.ty)
  ensureFunctionTySupported fnSpec.name "return" fnSpec.ret
  let usesRangeCheckLane := exprUsesU128Arith fnSpec.body
  if usesRangeCheckLane && fnSpec.ret != .u128 then
    .error
      s!"unsupported return type '{Ty.toCairo fnSpec.ret}' in function '{fnSpec.name}': u128 arithmetic lane currently requires return type 'u128' for explicit RangeCheck threading"
  else
    pure ()

  let paramTypeIds <- fnSpec.args.mapM (fun arg => typeIdJson arg.ty)
  let retTypeId <- typeIdJson fnSpec.ret
  let rangeCheckTypeId? <-
    if usesRangeCheckLane then
      pure (some (← typeIdJson .rangeCheck))
    else
      pure none
  let signatureParamTypeIds :=
    match rangeCheckTypeId? with
    | some rangeCheckTypeId => rangeCheckTypeId :: paramTypeIds
    | none => paramTypeIds
  let signatureRetTypeIds :=
    match rangeCheckTypeId? with
    | some rangeCheckTypeId => [rangeCheckTypeId, retTypeId]
    | none => [retTypeId]
  let rangeCheckParamId := idJson (paramVarDebugName fnSpec.name "__range_check")

  let initialEnv : Env :=
    fnSpec.args.map (fun param =>
      ( param.name,
        {
          ty := param.ty
          remaining := countVarUses param.name fnSpec.body
          current? := some (idJson (paramVarDebugName fnSpec.name param.name))
        } ))

  let emitAction : EmitM Unit := do
    if usesRangeCheckLane then
      let _ <- registerTypeDecl .rangeCheck
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
      if usesRangeCheckLane then
        let rangeCheckVar <- requireRangeCheckVar fnSpec.name
        let rangeCheckTemp <- emitStoreTemp fnSpec.name .rangeCheck rangeCheckVar
        let retTemp <- emitStoreTemp fnSpec.name fnSpec.ret bodyValueVar
        pushStmt (returnStmtJson [rangeCheckTemp, retTemp])
      else
        let retTemp <- emitStoreTemp fnSpec.name fnSpec.ret bodyValueVar
        pushStmt (returnStmtJson [retTemp])

  let initialState : EmitState :=
    if usesRangeCheckLane then
      { entryPoint := entryPoint, rangeCheckVar? := some rangeCheckParamId }
    else
      { entryPoint := entryPoint }

  match emitAction.run initialState with
  | .error err => .error err
  | .ok (_, st) =>
      let signatureJson :=
        Json.mkObj
          [
            ("param_types", Json.arr signatureParamTypeIds.toArray),
            ("ret_types", Json.arr signatureRetTypeIds.toArray)
          ]
      let userParamsJson :=
        fnSpec.args.map (fun param =>
          Json.mkObj
            [
              ("id", idJson (paramVarDebugName fnSpec.name param.name)),
              ("ty", (typeIdJson param.ty).toOption.getD Json.null)
            ])
      let paramsJsonEntries :=
        match rangeCheckTypeId? with
        | some rangeCheckTypeId =>
            (Json.mkObj [("id", rangeCheckParamId), ("ty", rangeCheckTypeId)]) :: userParamsJson
        | none =>
            userParamsJson
      let paramsJson := Json.arr paramsJsonEntries.toArray
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

def mergeDecls
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

end LeanCairo.Backend.Sierra.Emit.Subset
