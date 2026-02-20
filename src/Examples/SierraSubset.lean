import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Syntax.Expr

namespace Examples.SierraSubset

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec
open LeanCairo.Core.Syntax

private def identityBody : Expr .felt252 :=
  Expr.var (ty := .felt252) "x"

private def feltArithBody : Expr .felt252 :=
  Expr.letE
    "sum"
    .felt252
    (Expr.addFelt252
      (Expr.var (ty := .felt252) "x")
      (Expr.litFelt252 7))
    (Expr.subFelt252
      (Expr.mulFelt252
        (Expr.var (ty := .felt252) "sum")
        (Expr.var (ty := .felt252) "y"))
      (Expr.var (ty := .felt252) "x"))

private def constU128Body : Expr .u128 :=
  Expr.litU128 42

def contract : ContractSpec :=
  {
    contractName := "SierraSubsetContract"
    storage := []
    functions :=
      [
        {
          name := "identityFelt"
          args := [{ name := "x", ty := .felt252 }]
          ret := .felt252
          body := identityBody
        },
        {
          name := "feltAffine"
          args := [{ name := "x", ty := .felt252 }, { name := "y", ty := .felt252 }]
          ret := .felt252
          body := feltArithBody
        },
        {
          name := "constU128"
          args := []
          ret := .u128
          body := constU128Body
        }
      ]
  }

end Examples.SierraSubset
