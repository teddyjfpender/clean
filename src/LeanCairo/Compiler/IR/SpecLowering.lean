import LeanCairo.Compiler.IR.Lowering
import LeanCairo.Compiler.IR.Spec
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Spec.FuncSpec

namespace LeanCairo.Compiler.IR

open LeanCairo.Core.Spec

private def lowerStorageWrite (writeSpec : StorageWrite) : IRStorageWrite :=
  {
    field := writeSpec.field
    ty := writeSpec.ty
    value := lowerExpr writeSpec.value
  }

private def raiseStorageWrite (writeSpec : IRStorageWrite) : StorageWrite :=
  {
    field := writeSpec.field
    ty := writeSpec.ty
    value := raiseExpr writeSpec.value
  }

private def lowerFuncSpec (fnSpec : FuncSpec) : IRFuncSpec :=
  {
    name := fnSpec.name
    args := fnSpec.args
    ret := fnSpec.ret
    body := lowerExpr fnSpec.body
    mutability := fnSpec.mutability
    writes := fnSpec.writes.map lowerStorageWrite
  }

private def raiseFuncSpec (fnSpec : IRFuncSpec) : FuncSpec :=
  {
    name := fnSpec.name
    args := fnSpec.args
    ret := fnSpec.ret
    body := raiseExpr fnSpec.body
    mutability := fnSpec.mutability
    writes := fnSpec.writes.map raiseStorageWrite
  }

def lowerContractSpec (spec : ContractSpec) : IRContractSpec :=
  {
    contractName := spec.contractName
    storage := spec.storage
    functions := spec.functions.map lowerFuncSpec
  }

def raiseContractSpec (spec : IRContractSpec) : ContractSpec :=
  {
    contractName := spec.contractName
    storage := spec.storage
    functions := spec.functions.map raiseFuncSpec
  }

private theorem raiseLowerStorageWrite (writeSpec : StorageWrite) :
    raiseStorageWrite (lowerStorageWrite writeSpec) = writeSpec := by
  cases writeSpec with
  | mk field ty value =>
      simp [lowerStorageWrite, raiseStorageWrite, raiseLowerExpr]

private theorem lowerRaiseStorageWrite (writeSpec : IRStorageWrite) :
    lowerStorageWrite (raiseStorageWrite writeSpec) = writeSpec := by
  cases writeSpec with
  | mk field ty value =>
      simp [lowerStorageWrite, raiseStorageWrite, lowerRaiseExpr]

private theorem raiseLowerStorageWrites (writes : List StorageWrite) :
    writes.map (fun writeSpec => raiseStorageWrite (lowerStorageWrite writeSpec)) = writes := by
  induction writes with
  | nil =>
      simp
  | cons writeSpec rest ih =>
      simp [raiseLowerStorageWrite]

private theorem lowerRaiseStorageWrites (writes : List IRStorageWrite) :
    writes.map (fun writeSpec => lowerStorageWrite (raiseStorageWrite writeSpec)) = writes := by
  induction writes with
  | nil =>
      simp
  | cons writeSpec rest ih =>
      simp [lowerRaiseStorageWrite]

private theorem raiseLowerFuncSpec (fnSpec : FuncSpec) :
    raiseFuncSpec (lowerFuncSpec fnSpec) = fnSpec := by
  cases fnSpec with
  | mk name args ret body mutability writes =>
      have hwrites : writes.map (raiseStorageWrite ∘ lowerStorageWrite) = writes := by
        simpa [Function.comp] using raiseLowerStorageWrites writes
      simp [lowerFuncSpec, raiseFuncSpec, raiseLowerExpr, hwrites]

private theorem lowerRaiseFuncSpec (fnSpec : IRFuncSpec) :
    lowerFuncSpec (raiseFuncSpec fnSpec) = fnSpec := by
  cases fnSpec with
  | mk name args ret body mutability writes =>
      have hwrites : writes.map (lowerStorageWrite ∘ raiseStorageWrite) = writes := by
        simpa [Function.comp] using lowerRaiseStorageWrites writes
      simp [lowerFuncSpec, raiseFuncSpec, lowerRaiseExpr, hwrites]

private theorem raiseLowerFuncSpecs (functions : List FuncSpec) :
    functions.map (fun fnSpec => raiseFuncSpec (lowerFuncSpec fnSpec)) = functions := by
  induction functions with
  | nil =>
      simp
  | cons fnSpec rest ih =>
      simp [raiseLowerFuncSpec]

private theorem lowerRaiseFuncSpecs (functions : List IRFuncSpec) :
    functions.map (fun fnSpec => lowerFuncSpec (raiseFuncSpec fnSpec)) = functions := by
  induction functions with
  | nil =>
      simp
  | cons fnSpec rest ih =>
      simp [lowerRaiseFuncSpec]

theorem raiseLowerContractSpec (spec : ContractSpec) :
    raiseContractSpec (lowerContractSpec spec) = spec := by
  cases spec with
  | mk contractName storage functions =>
      have hfunctions : functions.map (raiseFuncSpec ∘ lowerFuncSpec) = functions := by
        simpa [Function.comp] using raiseLowerFuncSpecs functions
      simp [lowerContractSpec, raiseContractSpec, hfunctions]

theorem lowerRaiseContractSpec (spec : IRContractSpec) :
    lowerContractSpec (raiseContractSpec spec) = spec := by
  cases spec with
  | mk contractName storage functions =>
      have hfunctions : functions.map (lowerFuncSpec ∘ raiseFuncSpec) = functions := by
        simpa [Function.comp] using lowerRaiseFuncSpecs functions
      simp [lowerContractSpec, raiseContractSpec, hfunctions]

end LeanCairo.Compiler.IR
