import LeanCairo.Backend.Cairo.Ast
import LeanCairo.Backend.Cairo.EmitIRFunction
import LeanCairo.Compiler.IR.Spec

open LeanCairo.Backend.Cairo
open LeanCairo.Compiler.IR
open LeanCairo.Core.Domain
open LeanCairo.Core.Spec

private def assertCondition (ok : Bool) (message : String) : IO Unit := do
  if ok then
    pure ()
  else
    throw <| IO.userError message

private def containsFragment (text fragment : String) : Bool :=
  match text.splitOn fragment with
  | [] => false
  | [_] => false
  | _ => true

private def decisionExpr : IRExpr .u128 :=
  .ite
    (.ltU128 (.var (ty := .u128) "lhs") (.var (ty := .u128) "rhs"))
    (.var (ty := .u128) "rhs")
    (.var (ty := .u128) "lhs")

private def sampleFunction : IRFuncSpec :=
  {
    name := "updateCounter"
    args := [{ name := "lhs", ty := .u128 }, { name := "rhs", ty := .u128 }]
    ret := .u128
    body := decisionExpr
    mutability := .externalMutable
    writes :=
      [
        {
          field := "counter"
          ty := .u128
          value := decisionExpr
        }
      ]
  }

#eval do
  let ast := emitIRImplFunctionAst sampleFunction
  let renderedAtDepth := renderFunctionAt 2 ast
  let renderedAtDepthAgain := renderFunctionAt 2 ast
  let renderedViaEmitter := emitIRImplFunction 2 sampleFunction

  assertCondition (renderedAtDepth = renderedAtDepthAgain)
    "Cairo AST pretty-printer must be deterministic for fixed AST input"
  assertCondition (renderedAtDepth = renderedViaEmitter)
    "AST rendering and emitIRImplFunction output must remain identical"
  assertCondition (containsFragment renderedAtDepth "let __leancairo_internal_write_0: u128 = (")
    "multiline write binding should use structured parenthesized let formatting"
