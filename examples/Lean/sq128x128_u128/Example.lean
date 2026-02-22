import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Syntax.Expr

namespace sq128x128_u128.Example

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec
open LeanCairo.Core.Syntax

private abbrev sqLaneTy : Ty := .u128

private def varSqLane (name : String) : Expr sqLaneTy :=
  Expr.var (ty := sqLaneTy) name

private def addSqLane (lhs rhs : Expr sqLaneTy) : Expr sqLaneTy :=
  Expr.addInt sqLaneTy lhs rhs

private def subSqLane (lhs rhs : Expr sqLaneTy) : Expr sqLaneTy :=
  Expr.subInt sqLaneTy lhs rhs

private def mulSqLane (lhs rhs : Expr sqLaneTy) : Expr sqLaneTy :=
  Expr.mulInt sqLaneTy lhs rhs

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

private def addRawBody : Expr sqLaneTy :=
  addSqLane (varSqLane "aLane") (varSqLane "bLane")

private def subRawBody : Expr sqLaneTy :=
  subSqLane (varSqLane "aLane") (varSqLane "bLane")

private def mulRawBody : Expr sqLaneTy :=
  mulSqLane (varSqLane "aLane") (varSqLane "bLane")

private def deltaRawBody : Expr sqLaneTy :=
  subSqLane (varSqLane "bLane") (varSqLane "aLane")

private def affineKernelBody : Expr sqLaneTy :=
  Expr.letE
    "sum_ab"
    sqLaneTy
    (addSqLane (varSqLane "aLane") (varSqLane "bLane"))
    (Expr.letE
      "delta_cd"
      sqLaneTy
      (subSqLane (varSqLane "cLane") (varSqLane "dLane"))
      (Expr.letE
        "mul_term"
        sqLaneTy
        (mulSqLane
          (Expr.var (ty := sqLaneTy) "sum_ab")
          (Expr.var (ty := sqLaneTy) "delta_cd"))
        (addSqLane
          (Expr.var (ty := sqLaneTy) "mul_term")
          (varSqLane "eLane"))))

def contract : ContractSpec :=
  {
    contractName := "SQ128x128TypedLaneContract"
    storage := []
    functions :=
      [
        {
          name := "sq128x128AddRaw"
          args := [{ name := "aLane", ty := sqLaneTy }, { name := "bLane", ty := sqLaneTy }]
          ret := sqLaneTy
          body := addRawBody
        },
        {
          name := "sq128x128SubRaw"
          args := [{ name := "aLane", ty := sqLaneTy }, { name := "bLane", ty := sqLaneTy }]
          ret := sqLaneTy
          body := subRawBody
        },
        {
          name := "sq128x128MulRaw"
          args := [{ name := "aLane", ty := sqLaneTy }, { name := "bLane", ty := sqLaneTy }]
          ret := sqLaneTy
          body := mulRawBody
        },
        {
          name := "sq128x128DeltaRaw"
          args := [{ name := "aLane", ty := sqLaneTy }, { name := "bLane", ty := sqLaneTy }]
          ret := sqLaneTy
          body := deltaRawBody
        },
        {
          name := "sq128x128AffineKernel"
          args :=
            [
              { name := "aLane", ty := sqLaneTy },
              { name := "bLane", ty := sqLaneTy },
              { name := "cLane", ty := sqLaneTy },
              { name := "dLane", ty := sqLaneTy },
              { name := "eLane", ty := sqLaneTy }
            ]
          ret := sqLaneTy
          body := affineKernelBody
        }
      ]
  }

end sq128x128_u128.Example
