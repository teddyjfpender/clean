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
  | .felt252 => ctx.feltVars name
  | .u128 => ctx.u128Vars name
  | .u256 => ctx.u256Vars name
  | .bool => ctx.boolVars name

def readStorage (ctx : EvalContext) (ty : Ty) (name : String) : Ty.denote ty :=
  match ty with
  | .felt252 => ctx.feltStorage name
  | .u128 => ctx.u128Storage name
  | .u256 => ctx.u256Storage name
  | .bool => ctx.boolStorage name

def bindVar (ctx : EvalContext) (ty : Ty) (name : String) (value : Ty.denote ty) : EvalContext :=
  match ty with
  | .felt252 => { ctx with feltVars := fun n => if n = name then value else ctx.feltVars n }
  | .u128 => { ctx with u128Vars := fun n => if n = name then value else ctx.u128Vars n }
  | .u256 => { ctx with u256Vars := fun n => if n = name then value else ctx.u256Vars n }
  | .bool => { ctx with boolVars := fun n => if n = name then value else ctx.boolVars n }

def bindStorage (ctx : EvalContext) (ty : Ty) (name : String) (value : Ty.denote ty) : EvalContext :=
  match ty with
  | .felt252 => { ctx with feltStorage := fun n => if n = name then value else ctx.feltStorage n }
  | .u128 => { ctx with u128Storage := fun n => if n = name then value else ctx.u128Storage n }
  | .u256 => { ctx with u256Storage := fun n => if n = name then value else ctx.u256Storage n }
  | .bool => { ctx with boolStorage := fun n => if n = name then value else ctx.boolStorage n }

theorem readVar_bindVar_same (ctx : EvalContext) (ty : Ty) (name : String) (value : Ty.denote ty) :
    readVar (bindVar ctx ty name value) ty name = value := by
  cases ty <;> simp [readVar, bindVar]

end EvalContext

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
      match ty with
      | .felt252 => decide (evalExpr ctx lhs = evalExpr ctx rhs)
      | .u128 => decide (evalExpr ctx lhs = evalExpr ctx rhs)
      | .u256 => decide (evalExpr ctx lhs = evalExpr ctx rhs)
      | .bool => decide (evalExpr ctx lhs = evalExpr ctx rhs)
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

end LeanCairo.Compiler.Semantics
