import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Syntax.Expr

namespace Examples.SierraSubsetUnsupportedU256Sig

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec
open LeanCairo.Core.Syntax

private def passthroughBody : Expr .felt252 :=
  Expr.var (ty := .felt252) "seed"

def contract : ContractSpec :=
  {
    contractName := "SierraSubsetUnsupportedU256Sig"
    storage := []
    functions :=
      [
        {
          name := "unsupportedU256Arg"
          args := [{ name := "value", ty := .u256 }, { name := "seed", ty := .felt252 }]
          ret := .felt252
          body := passthroughBody
        }
      ]
  }

end Examples.SierraSubsetUnsupportedU256Sig
