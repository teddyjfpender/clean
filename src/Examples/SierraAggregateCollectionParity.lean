import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Syntax.Expr

namespace Examples.SierraAggregateCollectionParity

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec
open LeanCairo.Core.Syntax

private def tuplePassthroughBody : Expr (.tuple 2) :=
  Expr.var (ty := .tuple 2) "value"

private def structPassthroughBody : Expr (.structTy "AggPair") :=
  Expr.var (ty := .structTy "AggPair") "value"

private def enumPassthroughBody : Expr (.enumTy "AggChoice") :=
  Expr.var (ty := .enumTy "AggChoice") "value"

private def arrayPassthroughBody : Expr (.array "felt252") :=
  Expr.var (ty := .array "felt252") "value"

def contract : ContractSpec :=
  {
    contractName := "SierraAggregateCollectionParityContract"
    storage := []
    functions :=
      [
        {
          name := "tuplePassthrough"
          args := [{ name := "value", ty := .tuple 2 }]
          ret := .tuple 2
          body := tuplePassthroughBody
        },
        {
          name := "structPassthrough"
          args := [{ name := "value", ty := .structTy "AggPair" }]
          ret := .structTy "AggPair"
          body := structPassthroughBody
        },
        {
          name := "enumPassthrough"
          args := [{ name := "value", ty := .enumTy "AggChoice" }]
          ret := .enumTy "AggChoice"
          body := enumPassthroughBody
        },
        {
          name := "arrayPassthrough"
          args := [{ name := "value", ty := .array "felt252" }]
          ret := .array "felt252"
          body := arrayPassthroughBody
        }
      ]
  }

end Examples.SierraAggregateCollectionParity
