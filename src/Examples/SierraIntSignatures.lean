import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Syntax.Expr

namespace Examples.SierraIntSignatures

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec
open LeanCairo.Core.Syntax

def contract : ContractSpec :=
  {
    contractName := "SierraIntSignaturesContract"
    storage := []
    functions :=
      [
        {
          name := "identityI8"
          args := [{ name := "x", ty := .i8 }]
          ret := .i8
          body := Expr.var (ty := .i8) "x"
        },
        {
          name := "identityI16"
          args := [{ name := "x", ty := .i16 }]
          ret := .i16
          body := Expr.var (ty := .i16) "x"
        },
        {
          name := "identityI32"
          args := [{ name := "x", ty := .i32 }]
          ret := .i32
          body := Expr.var (ty := .i32) "x"
        },
        {
          name := "identityI64"
          args := [{ name := "x", ty := .i64 }]
          ret := .i64
          body := Expr.var (ty := .i64) "x"
        },
        {
          name := "identityI128"
          args := [{ name := "x", ty := .i128 }]
          ret := .i128
          body := Expr.var (ty := .i128) "x"
        },
        {
          name := "identityU8"
          args := [{ name := "x", ty := .u8 }]
          ret := .u8
          body := Expr.var (ty := .u8) "x"
        },
        {
          name := "identityU16"
          args := [{ name := "x", ty := .u16 }]
          ret := .u16
          body := Expr.var (ty := .u16) "x"
        },
        {
          name := "identityU32"
          args := [{ name := "x", ty := .u32 }]
          ret := .u32
          body := Expr.var (ty := .u32) "x"
        },
        {
          name := "identityU64"
          args := [{ name := "x", ty := .u64 }]
          ret := .u64
          body := Expr.var (ty := .u64) "x"
        },
        {
          name := "eqI8"
          args := [{ name := "lhs", ty := .i8 }, { name := "rhs", ty := .i8 }]
          ret := .bool
          body := Expr.eq
            (Expr.var (ty := .i8) "lhs")
            (Expr.var (ty := .i8) "rhs")
        },
        {
          name := "eqU64"
          args := [{ name := "lhs", ty := .u64 }, { name := "rhs", ty := .u64 }]
          ret := .bool
          body := Expr.eq
            (Expr.var (ty := .u64) "lhs")
            (Expr.var (ty := .u64) "rhs")
        }
      ]
  }

end Examples.SierraIntSignatures
