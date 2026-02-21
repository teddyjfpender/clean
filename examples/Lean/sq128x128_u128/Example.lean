import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Syntax.Expr

namespace sq128x128_u128.Example

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec
open LeanCairo.Core.Syntax

private def varU128 (name : String) : Expr .u128 :=
  Expr.var (ty := .u128) name

/-
Reduced SQ128x128 raw-lane model over `u128`:
- Represents the SQ raw magnitude in a constrained `u128` domain.
- Mirrors the unchecked fast path style from upstream SQ128 arithmetic:
  add, sub, mul, delta.
- Caller preconditions:
  1) arithmetic does not overflow `u128`;
  2) subtraction arguments satisfy lhs >= rhs.

Reference source family:
https://github.com/teddyjfpender/the-situation/tree/main/contracts/src/types/sq128
-/

private def addRawBody : Expr .u128 :=
  Expr.addU128 (varU128 "aRaw") (varU128 "bRaw")

private def subRawBody : Expr .u128 :=
  Expr.subU128 (varU128 "aRaw") (varU128 "bRaw")

private def mulRawBody : Expr .u128 :=
  Expr.mulU128 (varU128 "aRaw") (varU128 "bRaw")

private def deltaRawBody : Expr .u128 :=
  Expr.subU128 (varU128 "bRaw") (varU128 "aRaw")

private def affineKernelBody : Expr .u128 :=
  Expr.letE
    "sum_ab"
    .u128
    (Expr.addU128 (varU128 "aRaw") (varU128 "bRaw"))
    (Expr.letE
      "delta_cd"
      .u128
      (Expr.subU128 (varU128 "cRaw") (varU128 "dRaw"))
      (Expr.letE
        "mul_term"
        .u128
        (Expr.mulU128
          (Expr.var (ty := .u128) "sum_ab")
          (Expr.var (ty := .u128) "delta_cd"))
        (Expr.addU128
          (Expr.var (ty := .u128) "mul_term")
          (varU128 "eRaw"))))

def contract : ContractSpec :=
  {
    contractName := "SQ128x128U128Contract"
    storage := []
    functions :=
      [
        {
          name := "sq128x128AddRaw"
          args := [{ name := "aRaw", ty := .u128 }, { name := "bRaw", ty := .u128 }]
          ret := .u128
          body := addRawBody
        },
        {
          name := "sq128x128SubRaw"
          args := [{ name := "aRaw", ty := .u128 }, { name := "bRaw", ty := .u128 }]
          ret := .u128
          body := subRawBody
        },
        {
          name := "sq128x128MulRaw"
          args := [{ name := "aRaw", ty := .u128 }, { name := "bRaw", ty := .u128 }]
          ret := .u128
          body := mulRawBody
        },
        {
          name := "sq128x128DeltaRaw"
          args := [{ name := "aRaw", ty := .u128 }, { name := "bRaw", ty := .u128 }]
          ret := .u128
          body := deltaRawBody
        },
        {
          name := "sq128x128AffineKernel"
          args :=
            [
              { name := "aRaw", ty := .u128 },
              { name := "bRaw", ty := .u128 },
              { name := "cRaw", ty := .u128 },
              { name := "dRaw", ty := .u128 },
              { name := "eRaw", ty := .u128 }
            ]
          ret := .u128
          body := affineKernelBody
        }
      ]
  }

end sq128x128_u128.Example
