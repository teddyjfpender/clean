import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Syntax.Expr

namespace aggregate_payload_mix.Example

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec
open LeanCairo.Core.Syntax

private def payloadMixBody : Expr .u128 :=
  Expr.letE
    "lane0"
    .u128
    (Expr.addU128
      (Expr.var (ty := .u128) "f0")
      (Expr.var (ty := .u128) "f1"))
    (Expr.letE
      "lane1"
      .u128
      (Expr.addU128
        (Expr.var (ty := .u128) "f2")
        (Expr.var (ty := .u128) "f3"))
      (Expr.letE
        "mix"
        .u128
        (Expr.mulU128
          (Expr.var (ty := .u128) "lane0")
          (Expr.var (ty := .u128) "lane1"))
        (Expr.letE
          "checksum"
          .u128
          (Expr.addU128
            (Expr.var (ty := .u128) "mix")
            (Expr.var (ty := .u128) "lane0"))
          (Expr.subU128
            (Expr.var (ty := .u128) "checksum")
            (Expr.var (ty := .u128) "lane1")))))

def contract : ContractSpec :=
  {
    contractName := "AggregatePayloadContract"
    storage := []
    functions :=
      [
        {
          name := "payloadMix"
          args :=
            [
              { name := "f0", ty := .u128 },
              { name := "f1", ty := .u128 },
              { name := "f2", ty := .u128 },
              { name := "f3", ty := .u128 }
            ]
          ret := .u128
          body := payloadMixBody
        }
      ]
  }

end aggregate_payload_mix.Example
