import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Syntax.Expr

namespace Examples.SierraSubsetUnsupportedU128Arith

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec
open LeanCairo.Core.Syntax

private def unsupportedBody : Expr .bool :=
  Expr.ltU128
    (Expr.var (ty := .u128) "lhs")
    (Expr.var (ty := .u128) "rhs")

def contract : ContractSpec :=
  {
    contractName := "SierraSubsetUnsupportedU128Arith"
    storage := []
    functions :=
      [
        {
          name := "unsupportedU128Lt"
          args := [{ name := "lhs", ty := .u128 }, { name := "rhs", ty := .u128 }]
          ret := .bool
          body := unsupportedBody
        }
      ]
  }

end Examples.SierraSubsetUnsupportedU128Arith
