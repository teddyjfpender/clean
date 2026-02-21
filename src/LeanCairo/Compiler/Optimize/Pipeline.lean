import LeanCairo.Compiler.Optimize.Expr
import LeanCairo.Compiler.Optimize.Canonicalize
import LeanCairo.Compiler.Optimize.Pass
import LeanCairo.Compiler.Proof.OptimizeSound

namespace LeanCairo.Compiler.Optimize

open LeanCairo.Compiler.IR

def algebraicFoldPass : VerifiedExprPass where
  name := "algebraic-fold"
  legality :=
    {
      preconditions :=
        [
          "input expression is well-typed",
          "algebraic identities apply only to matching typed operators"
        ]
      postconditions :=
        [
          "output expression preserves evaluator semantics",
          "constant/control simplifications are deterministic"
        ]
      resourceSideConditions :=
        [
          "resource-sensitive operators keep original ordering semantics"
        ]
    }
  run := fun expr => optimizeExpr expr
  sound := by
    intro ctx ty expr
    simpa using LeanCairo.Compiler.Proof.optimizeExprSound ctx expr

def optimizerPasses : List VerifiedExprPass :=
  [algebraicFoldPass, canonicalizePass]

def optimizerPipelineContractCheck : Except String Unit :=
  VerifiedExprPass.validatePipelineContracts optimizerPasses

def optimizerPipelineContractsOk : Bool :=
  match optimizerPipelineContractCheck with
  | .ok _ => true
  | .error _ => false

def optimizerPass : VerifiedExprPass :=
  VerifiedExprPass.composeMany optimizerPasses

def optimizeExprPipeline (expr : IRExpr ty) : IRExpr ty :=
  optimizerPass.run expr

theorem optimizeExprPipelineSound (ctx : LeanCairo.Compiler.Semantics.EvalContext) (expr : IRExpr ty) :
    LeanCairo.Compiler.Semantics.evalExpr ctx (optimizeExprPipeline expr) =
      LeanCairo.Compiler.Semantics.evalExpr ctx expr := by
  simpa [optimizeExprPipeline] using optimizerPass.sound ctx expr

end LeanCairo.Compiler.Optimize
