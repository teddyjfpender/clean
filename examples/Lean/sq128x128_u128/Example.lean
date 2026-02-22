import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Syntax.Expr

namespace sq128x128_u128.Example

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec
open LeanCairo.Core.Syntax

private abbrev sqLaneTy : Ty := .u128
private abbrev sqLaneTyU64 : Ty := .u64
private abbrev sqLaneTyU32 : Ty := .u32
private abbrev sqLaneTyU16 : Ty := .u16

private def varSqLane (name : String) : Expr sqLaneTy :=
  Expr.var (ty := sqLaneTy) name

private def varSqLaneU64 (name : String) : Expr sqLaneTyU64 :=
  Expr.var (ty := sqLaneTyU64) name

private def varSqLaneU32 (name : String) : Expr sqLaneTyU32 :=
  Expr.var (ty := sqLaneTyU32) name

private def varSqLaneU16 (name : String) : Expr sqLaneTyU16 :=
  Expr.var (ty := sqLaneTyU16) name

private def addSqLane (lhs rhs : Expr sqLaneTy) : Expr sqLaneTy :=
  Expr.addInt sqLaneTy lhs rhs

private def subSqLane (lhs rhs : Expr sqLaneTy) : Expr sqLaneTy :=
  Expr.subInt sqLaneTy lhs rhs

private def mulSqLane (lhs rhs : Expr sqLaneTy) : Expr sqLaneTy :=
  Expr.mulInt sqLaneTy lhs rhs

private def addSqLaneU64 (lhs rhs : Expr sqLaneTyU64) : Expr sqLaneTyU64 :=
  Expr.addInt sqLaneTyU64 lhs rhs

private def subSqLaneU64 (lhs rhs : Expr sqLaneTyU64) : Expr sqLaneTyU64 :=
  Expr.subInt sqLaneTyU64 lhs rhs

private def mulSqLaneU64 (lhs rhs : Expr sqLaneTyU64) : Expr sqLaneTyU64 :=
  Expr.mulInt sqLaneTyU64 lhs rhs

private def addSqLaneU32 (lhs rhs : Expr sqLaneTyU32) : Expr sqLaneTyU32 :=
  Expr.addInt sqLaneTyU32 lhs rhs

private def subSqLaneU32 (lhs rhs : Expr sqLaneTyU32) : Expr sqLaneTyU32 :=
  Expr.subInt sqLaneTyU32 lhs rhs

private def mulSqLaneU32 (lhs rhs : Expr sqLaneTyU32) : Expr sqLaneTyU32 :=
  Expr.mulInt sqLaneTyU32 lhs rhs

private def addSqLaneU16 (lhs rhs : Expr sqLaneTyU16) : Expr sqLaneTyU16 :=
  Expr.addInt sqLaneTyU16 lhs rhs

private def subSqLaneU16 (lhs rhs : Expr sqLaneTyU16) : Expr sqLaneTyU16 :=
  Expr.subInt sqLaneTyU16 lhs rhs

private def mulSqLaneU16 (lhs rhs : Expr sqLaneTyU16) : Expr sqLaneTyU16 :=
  Expr.mulInt sqLaneTyU16 lhs rhs

/-
Reduced SQ128x128 raw-lane model over typed integer lanes:
- Represents the SQ raw magnitude in a constrained `u128` domain.
- Mirrors the unchecked fast path style from upstream SQ128 arithmetic:
  add, sub, mul, delta.
- Caller preconditions:
  1) arithmetic does not overflow `u128`;
  2) subtraction arguments satisfy lhs >= rhs.

Extended lane contract:
- `u64` lane uses strict wrapping semantics for add/sub/mul (`mod 2^64`).
- `u64` affine kernel composes those wrapped ops:
  `((a + b) * (c - d) + e) mod 2^64`.
- `u32` lane uses strict wrapping semantics for add/sub/mul (`mod 2^32`).
- `u32` affine kernel composes those wrapped ops:
  `((a + b) * (c - d) + e) mod 2^32`.
- `u16` lane uses strict wrapping semantics for add/sub/mul (`mod 2^16`).
- `u16` affine kernel composes those wrapped ops:
  `((a + b) * (c - d) + e) mod 2^16`.

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

private def addRawBodyU64 : Expr sqLaneTyU64 :=
  addSqLaneU64 (varSqLaneU64 "aLane") (varSqLaneU64 "bLane")

private def subRawBodyU64 : Expr sqLaneTyU64 :=
  subSqLaneU64 (varSqLaneU64 "aLane") (varSqLaneU64 "bLane")

private def mulRawBodyU64 : Expr sqLaneTyU64 :=
  mulSqLaneU64 (varSqLaneU64 "aLane") (varSqLaneU64 "bLane")

private def deltaRawBodyU64 : Expr sqLaneTyU64 :=
  subSqLaneU64 (varSqLaneU64 "bLane") (varSqLaneU64 "aLane")

private def affineKernelBodyU64 : Expr sqLaneTyU64 :=
  Expr.letE
    "sum_ab"
    sqLaneTyU64
    (addSqLaneU64 (varSqLaneU64 "aLane") (varSqLaneU64 "bLane"))
    (Expr.letE
      "delta_cd"
      sqLaneTyU64
      (subSqLaneU64 (varSqLaneU64 "cLane") (varSqLaneU64 "dLane"))
      (Expr.letE
        "mul_term"
        sqLaneTyU64
        (mulSqLaneU64
          (Expr.var (ty := sqLaneTyU64) "sum_ab")
          (Expr.var (ty := sqLaneTyU64) "delta_cd"))
        (addSqLaneU64
          (Expr.var (ty := sqLaneTyU64) "mul_term")
          (varSqLaneU64 "eLane"))))

private def addRawBodyU32 : Expr sqLaneTyU32 :=
  addSqLaneU32 (varSqLaneU32 "aLane") (varSqLaneU32 "bLane")

private def subRawBodyU32 : Expr sqLaneTyU32 :=
  subSqLaneU32 (varSqLaneU32 "aLane") (varSqLaneU32 "bLane")

private def mulRawBodyU32 : Expr sqLaneTyU32 :=
  mulSqLaneU32 (varSqLaneU32 "aLane") (varSqLaneU32 "bLane")

private def deltaRawBodyU32 : Expr sqLaneTyU32 :=
  subSqLaneU32 (varSqLaneU32 "bLane") (varSqLaneU32 "aLane")

private def affineKernelBodyU32 : Expr sqLaneTyU32 :=
  Expr.letE
    "sum_ab"
    sqLaneTyU32
    (addSqLaneU32 (varSqLaneU32 "aLane") (varSqLaneU32 "bLane"))
    (Expr.letE
      "delta_cd"
      sqLaneTyU32
      (subSqLaneU32 (varSqLaneU32 "cLane") (varSqLaneU32 "dLane"))
      (Expr.letE
        "mul_term"
        sqLaneTyU32
        (mulSqLaneU32
          (Expr.var (ty := sqLaneTyU32) "sum_ab")
          (Expr.var (ty := sqLaneTyU32) "delta_cd"))
        (addSqLaneU32
          (Expr.var (ty := sqLaneTyU32) "mul_term")
          (varSqLaneU32 "eLane"))))

private def addRawBodyU16 : Expr sqLaneTyU16 :=
  addSqLaneU16 (varSqLaneU16 "aLane") (varSqLaneU16 "bLane")

private def subRawBodyU16 : Expr sqLaneTyU16 :=
  subSqLaneU16 (varSqLaneU16 "aLane") (varSqLaneU16 "bLane")

private def mulRawBodyU16 : Expr sqLaneTyU16 :=
  mulSqLaneU16 (varSqLaneU16 "aLane") (varSqLaneU16 "bLane")

private def deltaRawBodyU16 : Expr sqLaneTyU16 :=
  subSqLaneU16 (varSqLaneU16 "bLane") (varSqLaneU16 "aLane")

private def affineKernelBodyU16 : Expr sqLaneTyU16 :=
  Expr.letE
    "sum_ab"
    sqLaneTyU16
    (addSqLaneU16 (varSqLaneU16 "aLane") (varSqLaneU16 "bLane"))
    (Expr.letE
      "delta_cd"
      sqLaneTyU16
      (subSqLaneU16 (varSqLaneU16 "cLane") (varSqLaneU16 "dLane"))
      (Expr.letE
        "mul_term"
        sqLaneTyU16
        (mulSqLaneU16
          (Expr.var (ty := sqLaneTyU16) "sum_ab")
          (Expr.var (ty := sqLaneTyU16) "delta_cd"))
        (addSqLaneU16
          (Expr.var (ty := sqLaneTyU16) "mul_term")
          (varSqLaneU16 "eLane"))))

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
        },
        {
          name := "sq128x128AddRawU64"
          args := [{ name := "aLane", ty := sqLaneTyU64 }, { name := "bLane", ty := sqLaneTyU64 }]
          ret := sqLaneTyU64
          body := addRawBodyU64
        },
        {
          name := "sq128x128SubRawU64"
          args := [{ name := "aLane", ty := sqLaneTyU64 }, { name := "bLane", ty := sqLaneTyU64 }]
          ret := sqLaneTyU64
          body := subRawBodyU64
        },
        {
          name := "sq128x128MulRawU64"
          args := [{ name := "aLane", ty := sqLaneTyU64 }, { name := "bLane", ty := sqLaneTyU64 }]
          ret := sqLaneTyU64
          body := mulRawBodyU64
        },
        {
          name := "sq128x128DeltaRawU64"
          args := [{ name := "aLane", ty := sqLaneTyU64 }, { name := "bLane", ty := sqLaneTyU64 }]
          ret := sqLaneTyU64
          body := deltaRawBodyU64
        },
        {
          name := "sq128x128AffineKernelU64"
          args :=
            [
              { name := "aLane", ty := sqLaneTyU64 },
              { name := "bLane", ty := sqLaneTyU64 },
              { name := "cLane", ty := sqLaneTyU64 },
              { name := "dLane", ty := sqLaneTyU64 },
              { name := "eLane", ty := sqLaneTyU64 }
            ]
          ret := sqLaneTyU64
          body := affineKernelBodyU64
        },
        {
          name := "sq128x128AddRawU32"
          args := [{ name := "aLane", ty := sqLaneTyU32 }, { name := "bLane", ty := sqLaneTyU32 }]
          ret := sqLaneTyU32
          body := addRawBodyU32
        },
        {
          name := "sq128x128SubRawU32"
          args := [{ name := "aLane", ty := sqLaneTyU32 }, { name := "bLane", ty := sqLaneTyU32 }]
          ret := sqLaneTyU32
          body := subRawBodyU32
        },
        {
          name := "sq128x128MulRawU32"
          args := [{ name := "aLane", ty := sqLaneTyU32 }, { name := "bLane", ty := sqLaneTyU32 }]
          ret := sqLaneTyU32
          body := mulRawBodyU32
        },
        {
          name := "sq128x128DeltaRawU32"
          args := [{ name := "aLane", ty := sqLaneTyU32 }, { name := "bLane", ty := sqLaneTyU32 }]
          ret := sqLaneTyU32
          body := deltaRawBodyU32
        },
        {
          name := "sq128x128AffineKernelU32"
          args :=
            [
              { name := "aLane", ty := sqLaneTyU32 },
              { name := "bLane", ty := sqLaneTyU32 },
              { name := "cLane", ty := sqLaneTyU32 },
              { name := "dLane", ty := sqLaneTyU32 },
              { name := "eLane", ty := sqLaneTyU32 }
            ]
          ret := sqLaneTyU32
          body := affineKernelBodyU32
        },
        {
          name := "sq128x128AddRawU16"
          args := [{ name := "aLane", ty := sqLaneTyU16 }, { name := "bLane", ty := sqLaneTyU16 }]
          ret := sqLaneTyU16
          body := addRawBodyU16
        },
        {
          name := "sq128x128SubRawU16"
          args := [{ name := "aLane", ty := sqLaneTyU16 }, { name := "bLane", ty := sqLaneTyU16 }]
          ret := sqLaneTyU16
          body := subRawBodyU16
        },
        {
          name := "sq128x128MulRawU16"
          args := [{ name := "aLane", ty := sqLaneTyU16 }, { name := "bLane", ty := sqLaneTyU16 }]
          ret := sqLaneTyU16
          body := mulRawBodyU16
        },
        {
          name := "sq128x128DeltaRawU16"
          args := [{ name := "aLane", ty := sqLaneTyU16 }, { name := "bLane", ty := sqLaneTyU16 }]
          ret := sqLaneTyU16
          body := deltaRawBodyU16
        },
        {
          name := "sq128x128AffineKernelU16"
          args :=
            [
              { name := "aLane", ty := sqLaneTyU16 },
              { name := "bLane", ty := sqLaneTyU16 },
              { name := "cLane", ty := sqLaneTyU16 },
              { name := "dLane", ty := sqLaneTyU16 },
              { name := "eLane", ty := sqLaneTyU16 }
            ]
          ret := sqLaneTyU16
          body := affineKernelBodyU16
        }
      ]
  }

end sq128x128_u128.Example
