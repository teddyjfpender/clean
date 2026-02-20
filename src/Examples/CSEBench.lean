import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Syntax.Expr
import LeanCairo.Core.Spec.ContractSpec

namespace Examples.CSEBench

open LeanCairo.Core.Domain
open LeanCairo.Core.Syntax
open LeanCairo.Core.Spec

private def repeatedU128 : Expr .u128 :=
  Expr.addU128
    (Expr.var (ty := .u128) "lhs")
    (Expr.var (ty := .u128) "rhs")

private def repeatedU256 : Expr .u256 :=
  Expr.addU256
    (Expr.var (ty := .u256) "lhs")
    (Expr.var (ty := .u256) "rhs")

private def cseAddBody : Expr .u128 :=
  Expr.addU128 repeatedU128 repeatedU128

private def cseMulBody : Expr .u256 :=
  Expr.mulU256 repeatedU256 repeatedU256

private def cseEqBody : Expr .bool :=
  Expr.eq repeatedU128 repeatedU128

def contract : ContractSpec :=
  {
    contractName := "CSEBenchContract"
    functions :=
      [
        {
          name := "doubleRepeatedU128"
          args := [{ name := "lhs", ty := .u128 }, { name := "rhs", ty := .u128 }]
          ret := .u128
          body := cseAddBody
        },
        {
          name := "squareRepeatedU256"
          args := [{ name := "lhs", ty := .u256 }, { name := "rhs", ty := .u256 }]
          ret := .u256
          body := cseMulBody
        },
        {
          name := "eqRepeatedU128"
          args := [{ name := "lhs", ty := .u128 }, { name := "rhs", ty := .u128 }]
          ret := .bool
          body := cseEqBody
        }
      ]
  }

end Examples.CSEBench
