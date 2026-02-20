import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Validation.Contract
import LeanCairo.Core.Validation.Errors
import LeanCairo.Compiler.IR.SpecLowering
import LeanCairo.Compiler.Optimize.IRSpec
import LeanCairo.Pipeline.Generation.InliningStrategy
import LeanCairo.Pipeline.Generation.IRRenderer
import LeanCairo.Pipeline.Generation.WriteProject

namespace LeanCairo.Pipeline.Generation

open LeanCairo.Core.Spec
open LeanCairo.Core.Validation
open LeanCairo.Compiler.IR
open LeanCairo.Compiler.Optimize

def generateProjectUncheckedWithTuning
    (spec : ContractSpec)
    (outDir : String)
    (emitCasm : Bool)
    (enableOptimization : Bool)
    (inliningStrategy : InliningStrategy) : IO Unit := do
  let irSpec := lowerContractSpec spec
  let inputSpec := if enableOptimization then optimizeIRContract irSpec else irSpec
  let rendered := renderProjectFromIR inputSpec emitCasm inliningStrategy
  writeGeneratedProject (System.FilePath.mk outDir) rendered

def generateProjectUncheckedWithOptions
    (spec : ContractSpec)
    (outDir : String)
    (emitCasm : Bool)
    (enableOptimization : Bool) : IO Unit := do
  generateProjectUncheckedWithTuning spec outDir emitCasm enableOptimization .default

def generateProjectUnchecked (spec : ContractSpec) (outDir : String) (emitCasm : Bool) : IO Unit := do
  generateProjectUncheckedWithOptions spec outDir emitCasm true

def generateProjectCheckedWithTuning
    (spec : ContractSpec)
    (outDir : String)
    (emitCasm : Bool)
    (enableOptimization : Bool)
    (inliningStrategy : InliningStrategy) : IO Unit := do
  match validateContract spec with
  | .ok _ =>
      generateProjectUncheckedWithTuning spec outDir emitCasm enableOptimization inliningStrategy
  | .error errors =>
      throw <| IO.userError s!"contract validation failed:\n{ValidationError.renderMany errors}"

def generateProjectCheckedWithOptions
    (spec : ContractSpec)
    (outDir : String)
    (emitCasm : Bool)
    (enableOptimization : Bool) : IO Unit := do
  generateProjectCheckedWithTuning spec outDir emitCasm enableOptimization .default

def generateProjectChecked (spec : ContractSpec) (outDir : String) (emitCasm : Bool) : IO Unit := do
  generateProjectCheckedWithOptions spec outDir emitCasm true

end LeanCairo.Pipeline.Generation
