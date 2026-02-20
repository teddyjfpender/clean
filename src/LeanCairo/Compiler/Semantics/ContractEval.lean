import LeanCairo.Compiler.IR.Spec
import LeanCairo.Compiler.Semantics.Eval

namespace LeanCairo.Compiler.Semantics

open LeanCairo.Compiler.IR
open LeanCairo.Core.Domain

structure FuncEvalOutcome (ret : Ty) where
  result : Ty.denote ret
  postCtx : EvalContext

def evalWritesFromSnapshot (entryCtx : EvalContext) : EvalContext -> List IRStorageWrite -> EvalContext
  | storageCtx, [] => storageCtx
  | storageCtx, writeSpec :: rest =>
      let value := evalExpr entryCtx writeSpec.value
      let storageCtx' := EvalContext.bindStorage storageCtx writeSpec.ty writeSpec.field value
      evalWritesFromSnapshot entryCtx storageCtx' rest

def evalWrites (entryCtx : EvalContext) (writes : List IRStorageWrite) : EvalContext :=
  evalWritesFromSnapshot entryCtx entryCtx writes

def evalFunc (entryCtx : EvalContext) (fnSpec : IRFuncSpec) : FuncEvalOutcome fnSpec.ret :=
  {
    result := evalExpr entryCtx fnSpec.body
    postCtx := evalWrites entryCtx fnSpec.writes
  }

def evalFuncSigma (entryCtx : EvalContext) (fnSpec : IRFuncSpec) : Sigma FuncEvalOutcome :=
  ⟨fnSpec.ret, evalFunc entryCtx fnSpec⟩

end LeanCairo.Compiler.Semantics
