import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Syntax.Expr

namespace circuit_gate_felt.Example

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec
open LeanCairo.Core.Syntax

private def gateConstraintBody : Expr .bool :=
  Expr.eq
    (Expr.addFelt252
      (Expr.mulFelt252
        (Expr.var (ty := .felt252) "a")
        (Expr.var (ty := .felt252) "b"))
      (Expr.var (ty := .felt252) "c"))
    (Expr.addFelt252
      (Expr.mulFelt252
        (Expr.var (ty := .felt252) "c")
        (Expr.var (ty := .felt252) "c"))
      (Expr.litFelt252 5))

def contract : ContractSpec :=
  {
    contractName := "CircuitGateContract"
    storage := []
    functions :=
      [
        {
          name := "gateConstraint"
          args :=
            [
              { name := "a", ty := .felt252 },
              { name := "b", ty := .felt252 },
              { name := "c", ty := .felt252 }
            ]
          ret := .bool
          body := gateConstraintBody
        }
      ]
  }

end circuit_gate_felt.Example
