import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Validation.Contract
import LeanCairo.Core.Validation.Errors
import LeanCairo.Pipeline.Generation.Renderer
import LeanCairo.Pipeline.Generation.WriteProject

namespace LeanCairo.Pipeline.Generation

open LeanCairo.Core.Spec
open LeanCairo.Core.Validation

def generateProjectUnchecked (spec : ContractSpec) (outDir : String) (emitCasm : Bool) : IO Unit := do
  let rendered := renderProject spec emitCasm
  writeGeneratedProject (System.FilePath.mk outDir) rendered

def generateProjectChecked (spec : ContractSpec) (outDir : String) (emitCasm : Bool) : IO Unit := do
  match validateContract spec with
  | .ok _ =>
      generateProjectUnchecked spec outDir emitCasm
  | .error errors =>
      throw <| IO.userError s!"contract validation failed:\n{ValidationError.renderMany errors}"

end LeanCairo.Pipeline.Generation
