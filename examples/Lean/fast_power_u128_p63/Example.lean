import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Syntax.Expr

namespace fast_power_u128_p63.Example

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec
open LeanCairo.Core.Syntax

private def varU128 (name : String) : Expr .u128 :=
  Expr.var (ty := .u128) name

/-
Alexandria reference family:
https://github.com/keep-starknet-strange/alexandria/blob/main/packages/math/src/fast_power.cairo

Specialization of `fast_power(base, power)` for `power = 63`.
Addition-chain staging:
  x2, x4, x8, x16, x32,
  x48 = x32*x16,
  x56 = x48*x8,
  x60 = x56*x4,
  x62 = x60*x2,
  x63 = x62*x.
-/
private def pow63Body : Expr .u128 :=
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
          "x16"
          .u128
          (Expr.mulU128 (Expr.var (ty := .u128) "x8") (Expr.var (ty := .u128) "x8"))
          (Expr.letE
            "x32"
            .u128
            (Expr.mulU128 (Expr.var (ty := .u128) "x16") (Expr.var (ty := .u128) "x16"))
            (Expr.letE
              "x48"
              .u128
              (Expr.mulU128 (Expr.var (ty := .u128) "x32") (Expr.var (ty := .u128) "x16"))
              (Expr.letE
                "x56"
                .u128
                (Expr.mulU128 (Expr.var (ty := .u128) "x48") (Expr.var (ty := .u128) "x8"))
                (Expr.letE
                  "x60"
                  .u128
                  (Expr.mulU128 (Expr.var (ty := .u128) "x56") (Expr.var (ty := .u128) "x4"))
                  (Expr.letE
                    "x62"
                    .u128
                    (Expr.mulU128 (Expr.var (ty := .u128) "x60") (Expr.var (ty := .u128) "x2"))
                    (Expr.mulU128 (Expr.var (ty := .u128) "x62") (varU128 "x"))))))))))

def contract : ContractSpec :=
  {
    contractName := "FastPowerU128P63Contract"
    storage := []
    functions :=
      [
        {
          name := "pow63U128"
          args := [{ name := "x", ty := .u128 }]
          ret := .u128
          body := pow63Body
        }
      ]
  }

end fast_power_u128_p63.Example
