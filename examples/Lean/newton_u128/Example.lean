import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Syntax.Expr

namespace newton_u128.Example

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec
open LeanCairo.Core.Syntax

private def varU128 (name : String) : Expr .u128 :=
  Expr.var (ty := .u128) name

/-
Newton-style reciprocal refinement over wrapping `u128` arithmetic:
  x_{n+1} = x_n * (2 - a * x_n)

Reference inspiration (style only, not imported directly):
https://github.com/leanprover-community/mathlib4/blob/f2bcf8c5f461911481985df7c2a99cb09fa1ad5d/Mathlib/Dynamics/Newton.lean#L35-L48
-/
private def reciprocalStepExpr (a x : Expr .u128) : Expr .u128 :=
  Expr.letE
    "ax"
    .u128
    (Expr.mulU128 a x)
    (Expr.letE
      "two_minus_ax"
      .u128
      (Expr.subU128 (Expr.litU128 2) (Expr.var (ty := .u128) "ax"))
      (Expr.mulU128 x (Expr.var (ty := .u128) "two_minus_ax")))

private def reciprocalStepBody : Expr .u128 :=
  reciprocalStepExpr (varU128 "a") (varU128 "x")

private def reciprocalTwoStepsBody : Expr .u128 :=
  Expr.letE
    "x1"
    .u128
    (reciprocalStepExpr (varU128 "a") (varU128 "x0"))
    (reciprocalStepExpr (varU128 "a") (Expr.var (ty := .u128) "x1"))

private def reciprocalResidualAfterStepBody : Expr .u128 :=
  Expr.subU128
    (reciprocalStepExpr (varU128 "a") (varU128 "x0"))
    (varU128 "x0")

def contract : ContractSpec :=
  {
    contractName := "NewtonU128Contract"
    storage := []
    functions :=
      [
        {
          name := "newtonReciprocalStep"
          args := [{ name := "a", ty := .u128 }, { name := "x", ty := .u128 }]
          ret := .u128
          body := reciprocalStepBody
        },
        {
          name := "newtonReciprocalTwoSteps"
          args := [{ name := "a", ty := .u128 }, { name := "x0", ty := .u128 }]
          ret := .u128
          body := reciprocalTwoStepsBody
        },
        {
          name := "newtonReciprocalResidualAfterStep"
          args := [{ name := "a", ty := .u128 }, { name := "x0", ty := .u128 }]
          ret := .u128
          body := reciprocalResidualAfterStepBody
        }
      ]
  }

end newton_u128.Example
