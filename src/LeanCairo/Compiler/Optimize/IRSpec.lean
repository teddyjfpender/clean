import LeanCairo.Compiler.IR.Spec
import LeanCairo.Compiler.Optimize.Pipeline

namespace LeanCairo.Compiler.Optimize

open LeanCairo.Compiler.IR

def optimizeIRStorageWrite (writeSpec : IRStorageWrite) : IRStorageWrite :=
  optimizerPass.applyStorageWrite writeSpec

def optimizeIRFuncSpec (fnSpec : IRFuncSpec) : IRFuncSpec :=
  optimizerPass.applyFuncSpec fnSpec

def optimizeIRContract (spec : IRContractSpec) : IRContractSpec :=
  optimizerPass.applyContract spec

end LeanCairo.Compiler.Optimize
