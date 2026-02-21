import LeanCairo.Compiler.Optimize.CSELetNorm
import LeanCairo.Compiler.Optimize.Pass
import LeanCairo.Compiler.Proof.CSELetNormSound

namespace LeanCairo.Compiler.Optimize

open LeanCairo.Compiler.IR

/-!
Canonicalization policy:
1. Traverse expressions structurally and normalize `let` placement through `cseLetNormExpr`.
2. Do not depend on IO, clocks, or global mutable state.
3. Canonicalization result is deterministic for a fixed input expression.
-/

def normalizeStep (expr : IRExpr ty) : IRExpr ty :=
  cseLetNormExpr expr

def normalizeExprWithFuel (fuel : Nat) (expr : IRExpr ty) : IRExpr ty :=
  match fuel with
  | 0 => expr
  | n + 1 =>
      let next := normalizeStep expr
      if next = expr then
        expr
      else
        normalizeExprWithFuel n next

def normalizeExpr (expr : IRExpr ty) : IRExpr ty :=
  normalizeExprWithFuel 32 expr

def normalizeExprN (iterations : Nat) (expr : IRExpr ty) : IRExpr ty :=
  match iterations with
  | 0 => expr
  | n + 1 => normalizeExprN n (normalizeExpr expr)

theorem normalizeExprDeterministic (expr : IRExpr ty) :
    normalizeExpr expr = normalizeExpr expr := rfl

def canonicalizePass : VerifiedExprPass where
  name := "canonicalize"
  legality :=
    {
      preconditions :=
        [
          "input expression is well-typed",
          "let-binding scopes are explicit in MIR"
        ]
      postconditions :=
        [
          "output expression preserves evaluation semantics",
          "let-normalization and local CSE are deterministic"
        ]
      resourceSideConditions :=
        [
          "no control/resource reordering across effect boundaries"
        ]
    }
  run := normalizeStep
  sound := by
    intro ctx ty expr
    simpa [normalizeStep] using LeanCairo.Compiler.Proof.cseLetNormExprSound ctx expr

end LeanCairo.Compiler.Optimize
