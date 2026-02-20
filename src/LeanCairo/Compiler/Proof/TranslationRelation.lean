import LeanCairo.Compiler.IR.Lowering

namespace LeanCairo.Compiler.Proof

open LeanCairo.Compiler.IR
open LeanCairo.Core.Syntax

def SourceToMIRRel (src : Expr ty) (ir : IRExpr ty) : Prop :=
  lowerExpr src = ir

def MIRToSourceRel (ir : IRExpr ty) (src : Expr ty) : Prop :=
  raiseExpr ir = src

def SourceMIRRoundTripRel (src : Expr ty) : Prop :=
  MIRToSourceRel (lowerExpr src) src

def MIRSourceRoundTripRel (ir : IRExpr ty) : Prop :=
  SourceToMIRRel (raiseExpr ir) ir

theorem sourceToMIRRel_lowerExpr (src : Expr ty) :
    SourceToMIRRel src (lowerExpr src) := rfl

theorem mirToSourceRel_raiseExpr (ir : IRExpr ty) :
    MIRToSourceRel ir (raiseExpr ir) := rfl

theorem sourceMIRRoundTrip_holds (src : Expr ty) :
    SourceMIRRoundTripRel src := by
  simpa [SourceMIRRoundTripRel, MIRToSourceRel] using raiseLowerExpr src

theorem mirSourceRoundTrip_holds (ir : IRExpr ty) :
    MIRSourceRoundTripRel ir := by
  simpa [MIRSourceRoundTripRel, SourceToMIRRel] using lowerRaiseExpr ir

end LeanCairo.Compiler.Proof
