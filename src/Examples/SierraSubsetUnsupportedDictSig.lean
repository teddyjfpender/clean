import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Syntax.Expr

namespace Examples.SierraSubsetUnsupportedDictSig

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec
open LeanCairo.Core.Syntax

private def passthroughBody : Expr .felt252 :=
  Expr.var (ty := .felt252) "seed"

def contract : ContractSpec :=
  {
    contractName := "SierraSubsetUnsupportedDictSig"
    storage := []
    functions :=
      [
        {
          name := "unsupportedDictArg"
          args := [{ name := "value", ty := .dict "felt252" "u128" }, { name := "seed", ty := .felt252 }]
          ret := .felt252
          body := passthroughBody
        }
      ]
  }

end Examples.SierraSubsetUnsupportedDictSig
