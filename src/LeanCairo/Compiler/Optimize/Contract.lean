import LeanCairo.Compiler.IR.SpecLowering
import LeanCairo.Compiler.Optimize.IRSpec
import LeanCairo.Core.Spec.ContractSpec

namespace LeanCairo.Compiler.Optimize

open LeanCairo.Compiler.IR
open LeanCairo.Core.Spec

def optimizeContract (spec : ContractSpec) : ContractSpec :=
  raiseContractSpec (optimizeIRContract (lowerContractSpec spec))

end LeanCairo.Compiler.Optimize
