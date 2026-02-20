import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Syntax.Expr

namespace Examples.SierraU128RangeChecked

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec
open LeanCairo.Core.Syntax

private def addBody : Expr .u128 :=
  Expr.addU128
    (Expr.var (ty := .u128) "lhs")
    (Expr.var (ty := .u128) "rhs")

private def subBody : Expr .u128 :=
  Expr.subU128
    (Expr.var (ty := .u128) "lhs")
    (Expr.var (ty := .u128) "rhs")

private def mulBody : Expr .u128 :=
  Expr.mulU128
    (Expr.var (ty := .u128) "lhs")
    (Expr.var (ty := .u128) "rhs")

def contract : ContractSpec :=
  {
    contractName := "SierraU128RangeCheckedContract"
    storage := []
    functions :=
      [
        {
          name := "addU128Wrapping"
          args := [{ name := "lhs", ty := .u128 }, { name := "rhs", ty := .u128 }]
          ret := .u128
          body := addBody
        },
        {
          name := "subU128Wrapping"
          args := [{ name := "lhs", ty := .u128 }, { name := "rhs", ty := .u128 }]
          ret := .u128
          body := subBody
        },
        {
          name := "mulU128Wrapping"
          args := [{ name := "lhs", ty := .u128 }, { name := "rhs", ty := .u128 }]
          ret := .u128
          body := mulBody
        }
      ]
  }

end Examples.SierraU128RangeChecked
