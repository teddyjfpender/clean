import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Syntax.Expr

namespace karatsuba_u128.Example

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec
open LeanCairo.Core.Syntax

private def varU128 (name : String) : Expr .u128 :=
  Expr.var (ty := .u128) name

private def base10Pow9 : Expr .u128 :=
  Expr.litU128 1000000000

private def base10Pow18 : Expr .u128 :=
  Expr.litU128 1000000000000000000

/-
Alexandria reference family:
https://github.com/keep-starknet-strange/alexandria/blob/main/packages/math/src/karatsuba.cairo

One-level Karatsuba combine over pre-split decimal limbs:
  x = x1*10^9 + x0
  y = y1*10^9 + y0
  z0 = x0*y0
  z1 = x1*y1
  z2 = (x0+x1)*(y0+y1)
  x*y = z0 + (z2 - z0 - z1)*10^9 + z1*10^18
-/
private def karatsubaCombineBody : Expr .u128 :=
  Expr.letE
    "z0"
    .u128
    (Expr.mulU128 (varU128 "x0") (varU128 "y0"))
    (Expr.letE
      "z1"
      .u128
      (Expr.mulU128 (varU128 "x1") (varU128 "y1"))
      (Expr.letE
        "z2"
        .u128
        (Expr.mulU128
          (Expr.addU128 (varU128 "x0") (varU128 "x1"))
          (Expr.addU128 (varU128 "y0") (varU128 "y1")))
        (Expr.letE
          "cross"
          .u128
          (Expr.subU128
            (Expr.subU128 (varU128 "z2") (varU128 "z0"))
            (varU128 "z1"))
          (Expr.addU128
            (Expr.addU128
              (varU128 "z0")
              (Expr.mulU128 (varU128 "cross") base10Pow9))
            (Expr.mulU128 (varU128 "z1") base10Pow18)))))

def contract : ContractSpec :=
  {
    contractName := "KaratsubaU128Contract"
    storage := []
    functions :=
      [
        {
          name := "karatsubaCombine"
          args :=
            [
              { name := "x0", ty := .u128 },
              { name := "x1", ty := .u128 },
              { name := "y0", ty := .u128 },
              { name := "y1", ty := .u128 }
            ]
          ret := .u128
          body := karatsubaCombineBody
        }
      ]
  }

end karatsuba_u128.Example
