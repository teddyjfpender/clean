import LeanCairo.Compiler.Optimize.Expr
import LeanCairo.Compiler.Optimize.CSELetNorm
import LeanCairo.Compiler.Optimize.Pass
import LeanCairo.Compiler.Proof.CSELetNormSound
import LeanCairo.Compiler.Proof.OptimizeSound

namespace LeanCairo.Compiler.Optimize

open LeanCairo.Compiler.IR

def algebraicFoldPass : VerifiedExprPass where
  name := "algebraic-fold"
  run := fun expr => optimizeExpr expr
  sound := by
    intro ctx ty expr
    simpa using LeanCairo.Compiler.Proof.optimizeExprSound ctx expr

def cseLetNormPass : VerifiedExprPass where
  name := "cse-let-normalization"
  run := fun expr => cseLetNormExpr expr
  sound := by
    intro ctx ty expr
    simpa using LeanCairo.Compiler.Proof.cseLetNormExprSound ctx expr

def optimizerPasses : List VerifiedExprPass :=
  [algebraicFoldPass, cseLetNormPass]

def optimizerPass : VerifiedExprPass :=
  VerifiedExprPass.composeMany optimizerPasses

def optimizeExprPipeline (expr : IRExpr ty) : IRExpr ty :=
  optimizerPass.run expr

theorem optimizeExprPipelineSound (ctx : LeanCairo.Compiler.Semantics.EvalContext) (expr : IRExpr ty) :
    LeanCairo.Compiler.Semantics.evalExpr ctx (optimizeExprPipeline expr) =
      LeanCairo.Compiler.Semantics.evalExpr ctx expr := by
  simpa [optimizeExprPipeline] using optimizerPass.sound ctx expr

end LeanCairo.Compiler.Optimize
