import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Syntax.Expr

namespace Examples.SierraScalar

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec
open LeanCairo.Core.Syntax

private def feltAffineBody : Expr .felt252 :=
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

private def eqFeltBody : Expr .bool :=
  Expr.eq
    (Expr.var (ty := .felt252) "lhs")
    (Expr.var (ty := .felt252) "rhs")

private def eqU128Body : Expr .bool :=
  Expr.eq
    (Expr.var (ty := .u128) "lhs")
    (Expr.var (ty := .u128) "rhs")

private def trueLiteralBody : Expr .bool :=
  Expr.litBool true

private def boolIdentityBody : Expr .bool :=
  Expr.var (ty := .bool) "flag"

def contract : ContractSpec :=
  {
    contractName := "SierraScalarContract"
    storage := []
    functions :=
      [
        {
          name := "feltAffine"
          args := [{ name := "x", ty := .felt252 }, { name := "y", ty := .felt252 }]
          ret := .felt252
          body := feltAffineBody
        },
        {
          name := "eqFelt252"
          args := [{ name := "lhs", ty := .felt252 }, { name := "rhs", ty := .felt252 }]
          ret := .bool
          body := eqFeltBody
        },
        {
          name := "eqU128"
          args := [{ name := "lhs", ty := .u128 }, { name := "rhs", ty := .u128 }]
          ret := .bool
          body := eqU128Body
        },
        {
          name := "literalTrue"
          args := []
          ret := .bool
          body := trueLiteralBody
        },
        {
          name := "identityBool"
          args := [{ name := "flag", ty := .bool }]
          ret := .bool
          body := boolIdentityBody
        }
      ]
  }

end Examples.SierraScalar
