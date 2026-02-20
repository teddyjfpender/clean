import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Syntax.Expr
import LeanCairo.Core.Spec.ContractSpec

namespace Examples.FixedPointBench

open LeanCairo.Core.Domain
open LeanCairo.Core.Syntax
open LeanCairo.Core.Spec

private def varU256 (name : String) : Expr .u256 :=
  Expr.var (ty := .u256) name

private def qmulKernelBody : Expr .u256 :=
  let ab := Expr.mulU256 (varU256 "a") (varU256 "b")
  let abc := Expr.mulU256 ab (varU256 "c")
  Expr.addU256 abc abc

private def qexpTaylorBody : Expr .u256 :=
  let x := varU256 "x"
  let x2 := Expr.mulU256 x x
  let x4 := Expr.mulU256 x2 x2
  let x8 := Expr.mulU256 x4 x4
  Expr.addU256 x8 x8

private def qlog1pTaylorBody : Expr .u256 :=
  let z := varU256 "z"
  let z2 := Expr.mulU256 z z
  let z4 := Expr.mulU256 z2 z2
  let diff := Expr.subU256 z4 z2
  Expr.addU256 diff diff

private def qnewtonRecipBody : Expr .u256 :=
  let x := varU256 "x"
  let x2 := Expr.mulU256 x x
  let x4 := Expr.mulU256 x2 x2
  let x5 := Expr.mulU256 x4 x
  let delta := Expr.subU256 x5 x2
  Expr.addU256 delta delta

def contract : ContractSpec :=
  {
    contractName := "FixedPointBenchKernelContract"
    functions :=
      [
        {
          name := "qmulKernel"
          args :=
            [
              { name := "a", ty := .u256 },
              { name := "b", ty := .u256 },
              { name := "c", ty := .u256 }
            ]
          ret := .u256
          body := qmulKernelBody
        },
        {
          name := "qexpTaylor"
          args := [{ name := "x", ty := .u256 }]
          ret := .u256
          body := qexpTaylorBody
        },
        {
          name := "qlog1pTaylor"
          args := [{ name := "z", ty := .u256 }]
          ret := .u256
          body := qlog1pTaylorBody
        },
        {
          name := "qnewtonRecip"
          args := [{ name := "x", ty := .u256 }]
          ret := .u256
          body := qnewtonRecipBody
        }
      ]
  }

end Examples.FixedPointBench
