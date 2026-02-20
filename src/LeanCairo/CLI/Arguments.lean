import LeanCairo.Core.Domain.Identifier
import LeanCairo.Pipeline.Generation.InliningStrategy

namespace LeanCairo.CLI

open LeanCairo.Core.Domain
open LeanCairo.Pipeline.Generation

structure CliOptions where
  moduleName : String
  outDir : String
  emitCasm : Bool
  optimize : Bool
  inliningStrategy : InliningStrategy
  deriving Repr

private structure PartialCliOptions where
  moduleName : Option String := none
  outDir : Option String := none
  emitCasm : Bool := false
  optimize : Bool := true
  inliningStrategy : InliningStrategy := .default

private def parseBoolLiteral (flagName : String) (value : String) : Except String Bool :=
  match value with
  | "true" => .ok true
  | "false" => .ok false
  | _ => .error s!"invalid value for {flagName}: '{value}' (expected true or false)"

private def parseTokens (tokens : List String) (state : PartialCliOptions) : Except String PartialCliOptions :=
  match tokens with
  | [] => .ok state
  | "--module" :: value :: rest => parseTokens rest { state with moduleName := some value }
  | "--out" :: value :: rest => parseTokens rest { state with outDir := some value }
  | "--emit-casm" :: value :: rest =>
      match parseBoolLiteral "--emit-casm" value with
      | .ok parsed => parseTokens rest { state with emitCasm := parsed }
      | .error err => .error err
  | "--optimize" :: value :: rest =>
      match parseBoolLiteral "--optimize" value with
      | .ok parsed => parseTokens rest { state with optimize := parsed }
      | .error err => .error err
  | "--inlining-strategy" :: value :: rest =>
      match InliningStrategy.parse value with
      | .ok parsed => parseTokens rest { state with inliningStrategy := parsed }
      | .error err => .error err
  | "--module" :: [] => .error "missing value for --module"
  | "--out" :: [] => .error "missing value for --out"
  | "--emit-casm" :: [] => .error "missing value for --emit-casm"
  | "--optimize" :: [] => .error "missing value for --optimize"
  | "--inlining-strategy" :: [] => .error "missing value for --inlining-strategy"
  | unknown :: _ => .error s!"unknown argument: {unknown}"

def usage : String :=
  String.intercalate "\n"
    [
      "Usage:",
      "  lake exe leancairo-gen --module <LeanModule> --out <Directory> [--emit-casm true|false] [--optimize true|false] [--inlining-strategy default|avoid|<n>]",
      "",
      "Requirements:",
      "  <LeanModule> must define: def contract : ContractSpec",
      ""
    ]

def parseCliOptions (args : List String) : Except String CliOptions := do
  let parsed <- parseTokens args {}
  let moduleName <-
    match parsed.moduleName with
    | some value => .ok value
    | none => .error "missing required argument --module"
  let outDir <-
    match parsed.outDir with
    | some value => .ok value
    | none => .error "missing required argument --out"
  if !isValidModuleName moduleName then
    .error s!"invalid module name '{moduleName}'"
  else
    .ok
      {
        moduleName := moduleName
        outDir := outDir
        emitCasm := parsed.emitCasm
        optimize := parsed.optimize
        inliningStrategy := parsed.inliningStrategy
      }

end LeanCairo.CLI
