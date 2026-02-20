# Example: Lean -> Optimized Cairo vs Hand-Written Cairo

Status note (2026-02-20):

1. This file is a visual comparison example for the Lean -> Cairo backend.
2. It is not the canonical feature-coverage contract for the Lean -> Sierra primary track.
3. For roadmap status and strict coverage tracking, use:
- `roadmap/README.md`
- `roadmap/executable-issues/INDEX.md`
4. For benchmarked fixed-point/fibonacci function comparisons, use:
- `docs/fixed-point/benchmark-results.md`
- `docs/fixed-point/code-comparisons.md`

This example shows a medium-complexity pricing-style function with nested `let` bindings, branching, and repeated arithmetic subexpressions.

## Lean DSL Source

```lean
import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Syntax.Expr
import LeanCairo.Core.Domain.Ty

open LeanCairo.Core.Domain
open LeanCairo.Core.Syntax
open LeanCairo.Core.Spec

namespace Examples.MediumVisual

private def netQuoteBody : Expr .u128 :=
  Expr.letE
    "gross"
    .u128
    (Expr.addU128
      (Expr.var (ty := .u128) "base")
      (Expr.var (ty := .u128) "spread"))
    (Expr.letE
      "riskAdj"
      .u128
      (Expr.mulU128
        (Expr.var (ty := .u128) "gross")
        (Expr.var (ty := .u128) "riskFactor"))
      (Expr.letE
        "totalPenalty"
        .u128
        (Expr.addU128
          (Expr.var (ty := .u128) "riskAdj")
          (Expr.addU128
            (Expr.mulU128
              (Expr.var (ty := .u128) "gross")
              (Expr.var (ty := .u128) "rebateRate"))
            (Expr.mulU128
              (Expr.var (ty := .u128) "gross")
              (Expr.var (ty := .u128) "rebateRate"))))
        (Expr.ite
          (Expr.leU128
            (Expr.var (ty := .u128) "totalPenalty")
            (Expr.var (ty := .u128) "riskAdj"))
          (Expr.subU128
            (Expr.var (ty := .u128) "riskAdj")
            (Expr.var (ty := .u128) "totalPenalty"))
          (Expr.subU128
            (Expr.var (ty := .u128) "totalPenalty")
            (Expr.var (ty := .u128) "riskAdj")))))

end Examples.MediumVisual
```

## Final Cairo (Generated, Optimized)

```cairo
fn net_quote(self: @ContractState, base: u128, spread: u128, risk_factor: u128, rebate_rate: u128) -> u128 {
    {
        let gross: u128 = (base + spread);
        {
            let risk_adj: u128 = (gross * risk_factor);
            {
                let total_penalty: u128 = (risk_adj + {
                    let __leancairo_internal_cse_u128: u128 = (gross * rebate_rate);
                    (__leancairo_internal_cse_u128 + __leancairo_internal_cse_u128)
                });
                if (total_penalty <= risk_adj) {
                    (risk_adj - total_penalty)
                } else {
                    (total_penalty - risk_adj)
                }
            }
        }
    }
}
```

## Final Cairo (General Hand-Written)

```cairo
fn net_quote(self: @ContractState, base: u128, spread: u128, risk_factor: u128, rebate_rate: u128) -> u128 {
    let gross: u128 = (base + spread);
    let risk_adj: u128 = (gross * risk_factor);
    let total_penalty: u128 = (risk_adj + ((gross * rebate_rate) + (gross * rebate_rate)));
    if (total_penalty <= risk_adj) {
        (risk_adj - total_penalty)
    } else {
        (total_penalty - risk_adj)
    }
}
```

## Visual Diff (Optimized vs Hand-Written)

```diff
 fn net_quote(self: @ContractState, base: u128, spread: u128, risk_factor: u128, rebate_rate: u128) -> u128 {
-    let gross: u128 = (base + spread);
-    let risk_adj: u128 = (gross * risk_factor);
-    let total_penalty: u128 = (risk_adj + ((gross * rebate_rate) + (gross * rebate_rate)));
-    if (total_penalty <= risk_adj) {
-        (risk_adj - total_penalty)
-    } else {
-        (total_penalty - risk_adj)
-    }
+    {
+        let gross: u128 = (base + spread);
+        {
+            let risk_adj: u128 = (gross * risk_factor);
+            {
+                let total_penalty: u128 = (risk_adj + {
+                    let __leancairo_internal_cse_u128: u128 = (gross * rebate_rate);
+                    (__leancairo_internal_cse_u128 + __leancairo_internal_cse_u128)
+                });
+                if (total_penalty <= risk_adj) {
+                    (risk_adj - total_penalty)
+                } else {
+                    (total_penalty - risk_adj)
+                }
+            }
+        }
+    }
 }
```

Key visible change: repeated subexpression `(gross * rebate_rate)` is shared through an internal temporary in the optimized output instead of being duplicated inline.
