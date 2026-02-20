import LeanCairo.Compiler.Optimize.IRSpec
import LeanCairo.Compiler.Optimize.Pipeline
import LeanCairo.Compiler.Semantics.ContractEval

open LeanCairo.Compiler.IR
open LeanCairo.Compiler.Optimize
open LeanCairo.Compiler.Semantics
open LeanCairo.Core.Domain
open LeanCairo.Core.Spec

private def assertCondition (ok : Bool) (message : String) : IO Unit := do
  if ok then
    pure ()
  else
    throw <| IO.userError message

private def feltExpr : IRExpr .felt252 :=
  .letE "sum" .felt252
    (.addFelt252 (.var (ty := .felt252) "x") (.var (ty := .felt252) "x"))
    (.subFelt252 (.var (ty := .felt252) "sum") (.litFelt252 4))

private def u128Expr : IRExpr .u128 :=
  .letE "tmp" .u128
    (.addU128 (.var (ty := .u128) "lhs") (.var (ty := .u128) "lhs"))
    (.mulU128 (.var (ty := .u128) "tmp") (.litU128 3))

private def u256Expr : IRExpr .u256 :=
  .addU256
    (.mulU256 (.var (ty := .u256) "x") (.var (ty := .u256) "x"))
    (.litU256 1)

private def boolExpr : IRExpr .bool :=
  .ite
    (.eq (.var (ty := .u128) "lhs") (.var (ty := .u128) "rhs"))
    (.litBool true)
    (.litBool false)

private def optimizerFixtureContext : EvalContext :=
  {
    feltVars := fun name => if name = "x" then 11 else 0
    u128Vars := fun name =>
      if name = "lhs" then IntegerDomains.pow2 128 - 1
      else if name = "rhs" then IntegerDomains.pow2 128 - 1
      else 0
    u256Vars := fun name => if name = "x" then 9 else 0
  }

private def fixtureFunction : IRFuncSpec :=
  {
    name := "optFixture"
    args := [{ name := "lhs", ty := .u128 }, { name := "rhs", ty := .u128 }]
    ret := .u128
    body := u128Expr
  }

private def fixtureContract : IRContractSpec :=
  {
    contractName := "OptFixtureContract"
    storage := [{ name := "counter", ty := .u128 }]
    functions := [fixtureFunction]
  }

#eval do
  let passNames := optimizerPasses.map (fun (pass : VerifiedExprPass) => pass.name)
  assertCondition (passNames = ["algebraic-fold", "canonicalize"])
    s!"unexpected optimizer pass stack order: {passNames}"

  let feltBefore := evalExpr optimizerFixtureContext feltExpr
  let feltAfter := evalExpr optimizerFixtureContext (optimizeExprPipeline feltExpr)
  assertCondition (feltBefore = feltAfter) "felt optimizer pipeline changed semantics"

  let u128Before := evalExpr optimizerFixtureContext u128Expr
  let u128After := evalExpr optimizerFixtureContext (optimizeExprPipeline u128Expr)
  assertCondition (u128Before = u128After) "u128 optimizer pipeline changed semantics"

  let u256Before := evalExpr optimizerFixtureContext u256Expr
  let u256After := evalExpr optimizerFixtureContext (optimizeExprPipeline u256Expr)
  assertCondition (u256Before = u256After) "u256 optimizer pipeline changed semantics"

  let boolBefore := evalExpr optimizerFixtureContext boolExpr
  let boolAfter := evalExpr optimizerFixtureContext (optimizeExprPipeline boolExpr)
  assertCondition (boolBefore = boolAfter) "bool optimizer pipeline changed semantics"

  let fnBefore := evalFunc optimizerFixtureContext fixtureFunction
  let fnAfter := evalFunc optimizerFixtureContext (optimizeIRFuncSpec fixtureFunction)
  assertCondition (decide (fnBefore.result = fnAfter.result))
    "optimizeIRFuncSpec changed function result denotation"

  let optimizedContract := optimizeIRContract fixtureContract
  assertCondition (optimizedContract.contractName = fixtureContract.contractName)
    "optimizeIRContract changed contract name"
  assertCondition (optimizedContract.storage = fixtureContract.storage)
    "optimizeIRContract changed storage layout"
  assertCondition (optimizedContract.functions.length = fixtureContract.functions.length)
    "optimizeIRContract changed function count"
