import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Syntax.Expr
import LeanCairo.Core.Spec.ContractSpec

namespace Examples.Hello

open LeanCairo.Core.Domain
open LeanCairo.Core.Syntax
open LeanCairo.Core.Spec

private def addU128Body : Expr .u128 :=
  Expr.addU128
    (Expr.var (ty := .u128) "lhs")
    (Expr.var (ty := .u128) "rhs")

private def addU256Body : Expr .u256 :=
  Expr.addU256
    (Expr.var (ty := .u256) "lhs")
    (Expr.var (ty := .u256) "rhs")

private def eqFeltBody : Expr .bool :=
  Expr.eq
    (Expr.var (ty := .felt252) "lhs")
    (Expr.var (ty := .felt252) "rhs")

private def maxU128Body : Expr .u128 :=
  Expr.letE
    "lhsLessOrEqual"
    .bool
    (Expr.leU128
      (Expr.var (ty := .u128) "lhs")
      (Expr.var (ty := .u128) "rhs"))
    (Expr.ite
      (Expr.var (ty := .bool) "lhsLessOrEqual")
      (Expr.var (ty := .u128) "rhs")
      (Expr.var (ty := .u128) "lhs"))

def contract : ContractSpec :=
  {
    contractName := "HelloContract"
    functions :=
      [
        {
          name := "addU128"
          args := [{ name := "lhs", ty := .u128 }, { name := "rhs", ty := .u128 }]
          ret := .u128
          body := addU128Body
        },
        {
          name := "addU256"
          args := [{ name := "lhs", ty := .u256 }, { name := "rhs", ty := .u256 }]
          ret := .u256
          body := addU256Body
        },
        {
          name := "eqFelt252"
          args := [{ name := "lhs", ty := .felt252 }, { name := "rhs", ty := .felt252 }]
          ret := .bool
          body := eqFeltBody
        },
        {
          name := "maxU128"
          args := [{ name := "lhs", ty := .u128 }, { name := "rhs", ty := .u128 }]
          ret := .u128
          body := maxU128Body
        }
      ]
  }

end Examples.Hello
