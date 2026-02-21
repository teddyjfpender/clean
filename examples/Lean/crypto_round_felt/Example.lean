import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Syntax.Expr

namespace crypto_round_felt.Example

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec
open LeanCairo.Core.Syntax

private def cryptoRoundBody : Expr .felt252 :=
  Expr.letE
    "t0"
    .felt252
    (Expr.mulFelt252
      (Expr.addFelt252
        (Expr.var (ty := .felt252) "x")
        (Expr.var (ty := .felt252) "y"))
      (Expr.subFelt252
        (Expr.var (ty := .felt252) "z")
        (Expr.var (ty := .felt252) "x")))
    (Expr.letE
      "t1"
      .felt252
      (Expr.mulFelt252
        (Expr.addFelt252
          (Expr.var (ty := .felt252) "t0")
          (Expr.litFelt252 17))
        (Expr.addFelt252
          (Expr.var (ty := .felt252) "y")
          (Expr.litFelt252 3)))
      (Expr.subFelt252
        (Expr.var (ty := .felt252) "t1")
        (Expr.mulFelt252
          (Expr.var (ty := .felt252) "x")
          (Expr.var (ty := .felt252) "z"))))

def contract : ContractSpec :=
  {
    contractName := "CryptoRoundContract"
    storage := []
    functions :=
      [
        {
          name := "cryptoRound"
          args :=
            [
              { name := "x", ty := .felt252 },
              { name := "y", ty := .felt252 },
              { name := "z", ty := .felt252 }
            ]
          ret := .felt252
          body := cryptoRoundBody
        }
      ]
  }

end crypto_round_felt.Example
