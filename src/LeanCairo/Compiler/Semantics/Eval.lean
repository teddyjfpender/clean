import LeanCairo.Compiler.IR.Expr
import LeanCairo.Core.Domain.Ty

namespace LeanCairo.Compiler.Semantics

open LeanCairo.Compiler.IR
open LeanCairo.Core.Domain

structure EvalContext where
  feltVars : String -> Int := fun _ => 0
  u128Vars : String -> Nat := fun _ => 0
  u256Vars : String -> Nat := fun _ => 0
  boolVars : String -> Bool := fun _ => false
  feltStorage : String -> Int := fun _ => 0
  u128Storage : String -> Nat := fun _ => 0
  u256Storage : String -> Nat := fun _ => 0
  boolStorage : String -> Bool := fun _ => false

namespace EvalContext

def readVar (ctx : EvalContext) (ty : Ty) (name : String) : Ty.denote ty :=
  match ty with
  | .felt252 | .i8 | .i16 | .i32 | .i64 | .i128 => ctx.feltVars name
  | .u128 | .u8 | .u16 | .u32 | .u64 | .qm31 => ctx.u128Vars name
  | .u256 => ctx.u256Vars name
  | .bool => ctx.boolVars name
  | .tuple _ => ()
  | .structTy _ => ()
  | .enumTy _ => ()
  | .array _ => ()
  | .span _ => ()
  | .nullable _ => ()
  | .boxed _ => ()
  | .dict _ _ => ()
  | .nonZero _ => ()
  | .rangeCheck => ()
  | .gasBuiltin => ()
  | .segmentArena => ()
  | .panicSignal => ()

def readStorage (ctx : EvalContext) (ty : Ty) (name : String) : Ty.denote ty :=
  match ty with
  | .felt252 | .i8 | .i16 | .i32 | .i64 | .i128 => ctx.feltStorage name
  | .u128 | .u8 | .u16 | .u32 | .u64 | .qm31 => ctx.u128Storage name
  | .u256 => ctx.u256Storage name
  | .bool => ctx.boolStorage name
  | .tuple _ => ()
  | .structTy _ => ()
  | .enumTy _ => ()
  | .array _ => ()
  | .span _ => ()
  | .nullable _ => ()
  | .boxed _ => ()
  | .dict _ _ => ()
  | .nonZero _ => ()
  | .rangeCheck => ()
  | .gasBuiltin => ()
  | .segmentArena => ()
  | .panicSignal => ()

def bindVar (ctx : EvalContext) (ty : Ty) (name : String) (value : Ty.denote ty) : EvalContext :=
  match ty with
  | .felt252 | .i8 | .i16 | .i32 | .i64 | .i128 =>
      { ctx with feltVars := fun n => if n = name then value else ctx.feltVars n }
  | .u128 | .u8 | .u16 | .u32 | .u64 | .qm31 =>
      { ctx with u128Vars := fun n => if n = name then value else ctx.u128Vars n }
  | .u256 => { ctx with u256Vars := fun n => if n = name then value else ctx.u256Vars n }
  | .bool => { ctx with boolVars := fun n => if n = name then value else ctx.boolVars n }
  | .tuple _ => ctx
  | .structTy _ => ctx
  | .enumTy _ => ctx
  | .array _ => ctx
  | .span _ => ctx
  | .nullable _ => ctx
  | .boxed _ => ctx
  | .dict _ _ => ctx
  | .nonZero _ => ctx
  | .rangeCheck => ctx
  | .gasBuiltin => ctx
  | .segmentArena => ctx
  | .panicSignal => ctx

def bindStorage (ctx : EvalContext) (ty : Ty) (name : String) (value : Ty.denote ty) : EvalContext :=
  match ty with
  | .felt252 | .i8 | .i16 | .i32 | .i64 | .i128 =>
      { ctx with feltStorage := fun n => if n = name then value else ctx.feltStorage n }
  | .u128 | .u8 | .u16 | .u32 | .u64 | .qm31 =>
      { ctx with u128Storage := fun n => if n = name then value else ctx.u128Storage n }
  | .u256 => { ctx with u256Storage := fun n => if n = name then value else ctx.u256Storage n }
  | .bool => { ctx with boolStorage := fun n => if n = name then value else ctx.boolStorage n }
  | .tuple _ => ctx
  | .structTy _ => ctx
  | .enumTy _ => ctx
  | .array _ => ctx
  | .span _ => ctx
  | .nullable _ => ctx
  | .boxed _ => ctx
  | .dict _ _ => ctx
  | .nonZero _ => ctx
  | .rangeCheck => ctx
  | .gasBuiltin => ctx
  | .segmentArena => ctx
  | .panicSignal => ctx

theorem readVar_bindVar_same (ctx : EvalContext) (ty : Ty) (name : String) (value : Ty.denote ty) :
    readVar (bindVar ctx ty name value) ty name = value := by
  cases ty <;> simp [readVar, bindVar]

end EvalContext

namespace ResourceCarriers

def merge (lhs rhs : ResourceCarriers) : ResourceCarriers :=
  {
    rangeCheck := lhs.rangeCheck + rhs.rangeCheck
    gas := lhs.gas + rhs.gas
    segmentArena := lhs.segmentArena + rhs.segmentArena
    panicChannel :=
      match rhs.panicChannel with
      | some value => some value
      | none => lhs.panicChannel
  }

def bumpGas (state : ResourceCarriers) (delta : Nat := 1) : ResourceCarriers :=
  { state with gas := state.gas + delta }

def bumpRangeCheck (state : ResourceCarriers) (delta : Nat := 1) : ResourceCarriers :=
  { state with rangeCheck := state.rangeCheck + delta }

end ResourceCarriers

def evalExpr (ctx : EvalContext) : IRExpr ty -> Ty.denote ty
  | .var name => EvalContext.readVar ctx ty name
  | .storageRead name => EvalContext.readStorage ctx ty name
  | .litU128 value => value
  | .litU256 value => value
  | .litBool value => value
  | .litFelt252 value => value
  | .addFelt252 lhs rhs => evalExpr ctx lhs + evalExpr ctx rhs
  | .subFelt252 lhs rhs => evalExpr ctx lhs - evalExpr ctx rhs
  | .mulFelt252 lhs rhs => evalExpr ctx lhs * evalExpr ctx rhs
  | .addU128 lhs rhs => evalExpr ctx lhs + evalExpr ctx rhs
  | .subU128 lhs rhs => evalExpr ctx lhs - evalExpr ctx rhs
  | .mulU128 lhs rhs => evalExpr ctx lhs * evalExpr ctx rhs
  | .addU256 lhs rhs => evalExpr ctx lhs + evalExpr ctx rhs
  | .subU256 lhs rhs => evalExpr ctx lhs - evalExpr ctx rhs
  | .mulU256 lhs rhs => evalExpr ctx lhs * evalExpr ctx rhs
  | @IRExpr.eq ty lhs rhs =>
      by
        let _ : DecidableEq (Ty.denote ty) := Ty.denoteDecidableEq ty
        exact decide (evalExpr ctx lhs = evalExpr ctx rhs)
  | .ltU128 lhs rhs => evalExpr ctx lhs < evalExpr ctx rhs
  | .leU128 lhs rhs => evalExpr ctx lhs <= evalExpr ctx rhs
  | .ltU256 lhs rhs => evalExpr ctx lhs < evalExpr ctx rhs
  | .leU256 lhs rhs => evalExpr ctx lhs <= evalExpr ctx rhs
  | .ite cond thenBranch elseBranch =>
      if evalExpr ctx cond then evalExpr ctx thenBranch else evalExpr ctx elseBranch
  | .letE name boundTy bound body =>
      let value := evalExpr ctx bound
      let ctx' := EvalContext.bindVar ctx boundTy name value
      evalExpr ctx' body

def resourceCost : IRExpr ty -> ResourceCarriers
  | .var _ => {}
  | .storageRead _ => {}
  | .litU128 _ => {}
  | .litU256 _ => {}
  | .litBool _ => {}
  | .litFelt252 _ => {}
  | .addFelt252 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .subFelt252 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .mulFelt252 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .addU128 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .subU128 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .mulU128 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .addU256 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .subU256 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .mulU256 lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .eq lhs rhs =>
      ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .ltU128 lhs rhs =>
      ResourceCarriers.bumpRangeCheck <| ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .leU128 lhs rhs =>
      ResourceCarriers.bumpRangeCheck <| ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .ltU256 lhs rhs =>
      ResourceCarriers.bumpRangeCheck <| ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .leU256 lhs rhs =>
      ResourceCarriers.bumpRangeCheck <| ResourceCarriers.bumpGas <| ResourceCarriers.merge (resourceCost lhs) (resourceCost rhs)
  | .ite cond thenBranch elseBranch =>
      ResourceCarriers.bumpGas <|
        ResourceCarriers.merge
          (resourceCost cond)
          (ResourceCarriers.merge (resourceCost thenBranch) (resourceCost elseBranch))
  | .letE _ _ bound body =>
      ResourceCarriers.merge (resourceCost bound) (resourceCost body)

def evalExprWithResources (ctx : EvalContext) (resources : ResourceCarriers) (expr : IRExpr ty) :
    Ty.denote ty × ResourceCarriers :=
  let value := evalExpr ctx expr
  let consumed := resourceCost expr
  (value, ResourceCarriers.merge resources consumed)

def evalEffectExpr (ctx : EvalContext) (effectExpr : EffectExpr ty) :
    Ty.denote ty × ResourceCarriers :=
  evalExprWithResources ctx effectExpr.resources effectExpr.expr

structure SemanticState where
  context : EvalContext
  resources : ResourceCarriers := {}
  failure : Option String := none

def evalExprState (state : SemanticState) (expr : IRExpr ty) :
    Except String (Ty.denote ty × SemanticState) := do
  match state.failure with
  | some err => .error err
  | none =>
      let value := evalExpr state.context expr
      let consumed := resourceCost expr
      let nextState : SemanticState :=
        { state with resources := ResourceCarriers.merge state.resources consumed }
      .ok (value, nextState)

def evalEffectExprState (state : SemanticState) (effectExpr : EffectExpr ty) :
    Except String (Ty.denote ty × SemanticState) :=
  evalExprState
    { state with resources := ResourceCarriers.merge state.resources effectExpr.resources }
    effectExpr.expr

theorem evalExprState_success_transition
    (state : SemanticState)
    (expr : IRExpr ty)
    (h : state.failure = none) :
    evalExprState state expr =
      .ok
        ( evalExpr state.context expr,
          { state with resources := ResourceCarriers.merge state.resources (resourceCost expr) } ) := by
  simp [evalExprState, h]

theorem evalExprState_failure_channel
    (state : SemanticState)
    (expr : IRExpr ty)
    (err : String)
    (h : state.failure = some err) :
    evalExprState state expr = .error err := by
  unfold evalExprState
  simp [h]

end LeanCairo.Compiler.Semantics
