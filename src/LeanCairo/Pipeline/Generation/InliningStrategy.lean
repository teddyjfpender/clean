namespace LeanCairo.Pipeline.Generation

inductive InliningStrategy where
  | default
  | avoid
  | bounded (value : Nat)
  deriving Repr, DecidableEq, Inhabited

namespace InliningStrategy

def parse (value : String) : Except String InliningStrategy :=
  match value with
  | "default" => .ok .default
  | "avoid" => .ok .avoid
  | _ =>
      match value.toNat? with
      | some n => .ok (.bounded n)
      | none =>
          .error
            s!"invalid value for --inlining-strategy: '{value}' (expected 'default', 'avoid', or a non-negative integer)"

def toTomlLiteral : InliningStrategy -> String
  | .default => "\"default\""
  | .avoid => "\"avoid\""
  | .bounded value => toString value

def toLeanExpr : InliningStrategy -> String
  | .default => "(LeanCairo.Pipeline.Generation.InliningStrategy.default)"
  | .avoid => "(LeanCairo.Pipeline.Generation.InliningStrategy.avoid)"
  | .bounded value => s!"(LeanCairo.Pipeline.Generation.InliningStrategy.bounded {value})"

end InliningStrategy

end LeanCairo.Pipeline.Generation
