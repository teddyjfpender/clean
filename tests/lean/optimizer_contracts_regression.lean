import LeanCairo.Compiler.Optimize.Pipeline

open LeanCairo.Compiler.IR
open LeanCairo.Compiler.Optimize
open LeanCairo.Compiler.Semantics

private def assertCondition (ok : Bool) (message : String) : IO Unit := do
  if ok then
    pure ()
  else
    throw <| IO.userError message

#eval do
  -- Pipeline-level contract validation must pass for registered optimizer passes.
  match optimizerPipelineContractCheck with
  | .ok _ =>
      pure ()
  | .error err =>
      throw <| IO.userError s!"optimizer pipeline contract check failed unexpectedly: {err}"

  assertCondition optimizerPipelineContractsOk
    "optimizer pipeline contracts flag must be true for registered pass set"

  -- Missing legality metadata must fail pass integration checks.
  let invalidPass : VerifiedExprPass :=
    {
      name := "invalid-contract-pass"
      legality := { preconditions := [], postconditions := ["identity"], resourceSideConditions := [] }
      run := fun expr => expr
      sound := by
        intro ctx ty expr
        rfl
    }
  match VerifiedExprPass.validatePipelineContracts [invalidPass] with
  | .ok _ =>
      throw <| IO.userError "expected invalid pass contract to fail integration checks"
  | .error err =>
      assertCondition (err.contains "missing required legality metadata")
        "invalid pass contract should fail with legality-metadata diagnostic"
