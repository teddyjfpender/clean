import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Syntax.Expr

namespace fast_power_u128.Example

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec
open LeanCairo.Core.Syntax

private def varU128 (name : String) : Expr .u128 :=
  Expr.var (ty := .u128) name

/-
Alexandria reference family:
https://github.com/keep-starknet-strange/alexandria/blob/main/packages/math/src/fast_power.cairo

This Lean kernel is the specialization of `fast_power(base, power)` for `power = 13`:
  x^13 = x^(8+4+1) = (x^8) * (x^4) * x
with explicit let-binding staging.
-/
private def pow13Body : Expr .u128 :=
  Expr.letE
    "x2"
    .u128
    (Expr.mulU128 (varU128 "x") (varU128 "x"))
    (Expr.letE
      "x4"
      .u128
      (Expr.mulU128 (Expr.var (ty := .u128) "x2") (Expr.var (ty := .u128) "x2"))
      (Expr.letE
        "x8"
        .u128
        (Expr.mulU128 (Expr.var (ty := .u128) "x4") (Expr.var (ty := .u128) "x4"))
        (Expr.letE
          "x12"
          .u128
          (Expr.mulU128 (Expr.var (ty := .u128) "x8") (Expr.var (ty := .u128) "x4"))
          (Expr.mulU128 (Expr.var (ty := .u128) "x12") (varU128 "x")))) )

def contract : ContractSpec :=
  {
    contractName := "FastPowerU128Contract"
    storage := []
    functions :=
      [
        {
          name := "pow13U128"
          args := [{ name := "x", ty := .u128 }]
          ret := .u128
          body := pow13Body
        }
      ]
  }

end fast_power_u128.Example
