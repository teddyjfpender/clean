import LeanCairo.Compiler.IR.SpecLowering
import LeanCairo.Compiler.Optimize.IRSpec
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Validation.Contract
import LeanCairo.Core.Validation.Errors
import LeanCairo.Pipeline.Sierra.Renderer
import LeanCairo.Pipeline.Sierra.WriteProject

namespace LeanCairo.Pipeline.Sierra

open LeanCairo.Compiler.IR
open LeanCairo.Compiler.Optimize
open LeanCairo.Core.Spec
open LeanCairo.Core.Validation

def generateSierraProjectUncheckedWithOptions
    (spec : ContractSpec)
    (outDir : String)
    (enableOptimization : Bool) : IO Unit := do
  let irSpec := lowerContractSpec spec
  let inputSpec := if enableOptimization then optimizeIRContract irSpec else irSpec
  match renderSierraProjectFromIR inputSpec enableOptimization with
  | .ok rendered =>
      writeGeneratedSierraProject (System.FilePath.mk outDir) rendered
  | .error err =>
      throw <| IO.userError s!"Sierra subset rendering failed:\n{err}"

def generateSierraProjectUnchecked (spec : ContractSpec) (outDir : String) : IO Unit := do
  generateSierraProjectUncheckedWithOptions spec outDir true

def generateSierraProjectCheckedWithOptions
    (spec : ContractSpec)
    (outDir : String)
    (enableOptimization : Bool) : IO Unit := do
  match validateContract spec with
  | .ok _ =>
      generateSierraProjectUncheckedWithOptions spec outDir enableOptimization
  | .error errors =>
      throw <| IO.userError s!"contract validation failed:\n{ValidationError.renderMany errors}"

def generateSierraProjectChecked (spec : ContractSpec) (outDir : String) : IO Unit := do
  generateSierraProjectCheckedWithOptions spec outDir true

end LeanCairo.Pipeline.Sierra
