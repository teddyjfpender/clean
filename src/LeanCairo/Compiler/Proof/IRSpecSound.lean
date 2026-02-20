import LeanCairo.Compiler.Optimize.IRSpec
import LeanCairo.Compiler.Semantics.ContractEval

namespace LeanCairo.Compiler.Proof

open LeanCairo.Compiler.IR
open LeanCairo.Compiler.Optimize
open LeanCairo.Compiler.Semantics

theorem optimizeIRWritesFromSnapshotSound
    (entryCtx storageCtx : EvalContext)
    (writes : List IRStorageWrite) :
    evalWritesFromSnapshot entryCtx storageCtx (writes.map optimizeIRStorageWrite) =
      evalWritesFromSnapshot entryCtx storageCtx writes := by
  simpa [optimizeIRStorageWrite] using
    optimizerPass.applyWritesFromSnapshotSound entryCtx storageCtx writes

theorem optimizeIRWritesSound
    (entryCtx : EvalContext)
    (writes : List IRStorageWrite) :
    evalWrites entryCtx (writes.map optimizeIRStorageWrite) = evalWrites entryCtx writes := by
  simpa [optimizeIRStorageWrite] using optimizerPass.applyWritesSound entryCtx writes

theorem optimizeIRFuncSpecSound
    (entryCtx : EvalContext)
    (fnSpec : IRFuncSpec) :
    evalFunc entryCtx (optimizeIRFuncSpec fnSpec) = evalFunc entryCtx fnSpec := by
  simpa [optimizeIRFuncSpec] using optimizerPass.applyFuncSpecSound entryCtx fnSpec

theorem optimizeIRFuncSpecSigmaSound
    (entryCtx : EvalContext)
    (fnSpec : IRFuncSpec) :
    evalFuncSigma entryCtx (optimizeIRFuncSpec fnSpec) = evalFuncSigma entryCtx fnSpec := by
  simpa [optimizeIRFuncSpec] using optimizerPass.applyFuncSpecSigmaSound entryCtx fnSpec

theorem optimizeIRContractPreservesShape (spec : IRContractSpec) :
    (optimizeIRContract spec).contractName = spec.contractName
      ∧ (optimizeIRContract spec).storage = spec.storage
      ∧ (optimizeIRContract spec).functions.length = spec.functions.length := by
  simpa [optimizeIRContract] using optimizerPass.applyContractPreservesShape spec

theorem optimizeIRContractSound
    (entryCtx : EvalContext)
    (spec : IRContractSpec) :
    (optimizeIRContract spec).functions.map (evalFuncSigma entryCtx) =
      spec.functions.map (evalFuncSigma entryCtx) := by
  simpa [optimizeIRContract] using optimizerPass.applyContractSound entryCtx spec

end LeanCairo.Compiler.Proof
