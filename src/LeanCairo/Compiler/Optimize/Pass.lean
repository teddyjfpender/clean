import LeanCairo.Compiler.IR.Spec
import LeanCairo.Compiler.Semantics.ContractEval

namespace LeanCairo.Compiler.Optimize

open LeanCairo.Compiler.IR
open LeanCairo.Compiler.Semantics
open LeanCairo.Core.Domain

structure VerifiedExprPass where
  name : String
  run : {ty : Ty} -> IRExpr ty -> IRExpr ty
  sound : ∀ (ctx : EvalContext) {ty : Ty} (expr : IRExpr ty), evalExpr ctx (run expr) = evalExpr ctx expr

namespace VerifiedExprPass

def id : VerifiedExprPass where
  name := "id"
  run := fun expr => expr
  sound := by
    intro ctx ty expr
    rfl

def applyStorageWrite (pass : VerifiedExprPass) (writeSpec : IRStorageWrite) : IRStorageWrite :=
  { writeSpec with value := pass.run writeSpec.value }

def applyFuncSpec (pass : VerifiedExprPass) (fnSpec : IRFuncSpec) : IRFuncSpec :=
  {
    fnSpec with
    body := pass.run fnSpec.body
    writes := fnSpec.writes.map pass.applyStorageWrite
  }

def applyContract (pass : VerifiedExprPass) (spec : IRContractSpec) : IRContractSpec :=
  { spec with functions := spec.functions.map pass.applyFuncSpec }

theorem applyStorageWritePreservesField (pass : VerifiedExprPass) (writeSpec : IRStorageWrite) :
    (pass.applyStorageWrite writeSpec).field = writeSpec.field := by
  rfl

theorem applyStorageWritePreservesType (pass : VerifiedExprPass) (writeSpec : IRStorageWrite) :
    (pass.applyStorageWrite writeSpec).ty = writeSpec.ty := by
  rfl

theorem applyFuncSpecPreservesInterface (pass : VerifiedExprPass) (fnSpec : IRFuncSpec) :
    (pass.applyFuncSpec fnSpec).name = fnSpec.name
      ∧ (pass.applyFuncSpec fnSpec).args = fnSpec.args
      ∧ (pass.applyFuncSpec fnSpec).ret = fnSpec.ret
      ∧ (pass.applyFuncSpec fnSpec).mutability = fnSpec.mutability
      ∧ (pass.applyFuncSpec fnSpec).writes.length = fnSpec.writes.length := by
  cases fnSpec with
  | mk name args ret body mutability writes =>
      simp [applyFuncSpec]

theorem applyContractPreservesShape (pass : VerifiedExprPass) (spec : IRContractSpec) :
    (pass.applyContract spec).contractName = spec.contractName
      ∧ (pass.applyContract spec).storage = spec.storage
      ∧ (pass.applyContract spec).functions.length = spec.functions.length := by
  cases spec with
  | mk contractName storage functions =>
      simp [applyContract]

theorem applyStorageWriteSound
    (pass : VerifiedExprPass)
    (ctx : EvalContext)
    (writeSpec : IRStorageWrite) :
    evalExpr ctx (pass.applyStorageWrite writeSpec).value = evalExpr ctx writeSpec.value := by
  simpa [applyStorageWrite] using pass.sound ctx writeSpec.value

theorem applyWritesFromSnapshotSound
    (pass : VerifiedExprPass)
    (entryCtx storageCtx : EvalContext)
    (writes : List IRStorageWrite) :
    evalWritesFromSnapshot entryCtx storageCtx (writes.map pass.applyStorageWrite) =
      evalWritesFromSnapshot entryCtx storageCtx writes := by
  induction writes generalizing storageCtx with
  | nil =>
      simp [evalWritesFromSnapshot]
  | cons writeSpec rest ih =>
      simp [evalWritesFromSnapshot, applyStorageWrite, pass.sound, ih]

theorem applyWritesSound
    (pass : VerifiedExprPass)
    (entryCtx : EvalContext)
    (writes : List IRStorageWrite) :
    evalWrites entryCtx (writes.map pass.applyStorageWrite) = evalWrites entryCtx writes := by
  simpa [evalWrites] using pass.applyWritesFromSnapshotSound entryCtx entryCtx writes

theorem applyFuncSpecSound
    (pass : VerifiedExprPass)
    (entryCtx : EvalContext)
    (fnSpec : IRFuncSpec) :
    evalFunc entryCtx (pass.applyFuncSpec fnSpec) = evalFunc entryCtx fnSpec := by
  cases fnSpec with
  | mk name args ret body mutability writes =>
      simp [applyFuncSpec, evalFunc, pass.applyWritesSound, pass.sound]

theorem applyFuncSpecSigmaSound
    (pass : VerifiedExprPass)
    (entryCtx : EvalContext)
    (fnSpec : IRFuncSpec) :
    evalFuncSigma entryCtx (pass.applyFuncSpec fnSpec) = evalFuncSigma entryCtx fnSpec := by
  cases fnSpec with
  | mk name args ret body mutability writes =>
      simp [evalFuncSigma, applyFuncSpec, evalFunc, pass.applyWritesSound, pass.sound]

theorem applyContractSound
    (pass : VerifiedExprPass)
    (entryCtx : EvalContext)
    (spec : IRContractSpec) :
    (pass.applyContract spec).functions.map (evalFuncSigma entryCtx) =
      spec.functions.map (evalFuncSigma entryCtx) := by
  cases spec with
  | mk contractName storage functions =>
      simp [applyContract, pass.applyFuncSpecSigmaSound]

def compose (next prev : VerifiedExprPass) : VerifiedExprPass where
  name := prev.name ++ " |> " ++ next.name
  run := fun expr => next.run (prev.run expr)
  sound := by
    intro ctx ty expr
    calc
      evalExpr ctx (next.run (prev.run expr)) = evalExpr ctx (prev.run expr) := by
        simpa using next.sound ctx (prev.run expr)
      _ = evalExpr ctx expr := by
        simpa using prev.sound ctx expr

def composeMany (passes : List VerifiedExprPass) : VerifiedExprPass :=
  passes.foldl (fun acc pass => compose pass acc) id

end VerifiedExprPass
end LeanCairo.Compiler.Optimize
