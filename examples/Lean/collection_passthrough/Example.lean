import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Syntax.Expr

namespace collection_passthrough.Example

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec
open LeanCairo.Core.Syntax

private def arrayPassthroughBody : Expr (.array "felt252") :=
  Expr.var (ty := .array "felt252") "value"

private def spanPassthroughBody : Expr (.span "felt252") :=
  Expr.var (ty := .span "felt252") "value"

private def nullablePassthroughBody : Expr (.nullable "felt252") :=
  Expr.var (ty := .nullable "felt252") "value"

private def boxedPassthroughBody : Expr (.boxed "felt252") :=
  Expr.var (ty := .boxed "felt252") "value"

def contract : ContractSpec :=
  {
    contractName := "CollectionPassthroughContract"
    storage := []
    functions :=
      [
        {
          name := "arrayPassthrough"
          args := [{ name := "value", ty := .array "felt252" }]
          ret := .array "felt252"
          body := arrayPassthroughBody
        },
        {
          name := "spanPassthrough"
          args := [{ name := "value", ty := .span "felt252" }]
          ret := .span "felt252"
          body := spanPassthroughBody
        },
        {
          name := "nullablePassthrough"
          args := [{ name := "value", ty := .nullable "felt252" }]
          ret := .nullable "felt252"
          body := nullablePassthroughBody
        },
        {
          name := "boxedPassthrough"
          args := [{ name := "value", ty := .boxed "felt252" }]
          ret := .boxed "felt252"
          body := boxedPassthroughBody
        }
      ]
  }

end collection_passthrough.Example
