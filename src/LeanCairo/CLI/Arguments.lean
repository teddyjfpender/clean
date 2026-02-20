import LeanCairo.Core.Domain.Identifier

namespace LeanCairo.CLI

open LeanCairo.Core.Domain

structure CliOptions where
  moduleName : String
  outDir : String
  emitCasm : Bool
  deriving Repr

private structure PartialCliOptions where
  moduleName : Option String := none
  outDir : Option String := none
  emitCasm : Bool := false

private def parseBoolLiteral (value : String) : Except String Bool :=
  match value with
  | "true" => .ok true
  | "false" => .ok false
  | _ => .error s!"invalid value for --emit-casm: '{value}' (expected true or false)"

private def parseTokens (tokens : List String) (state : PartialCliOptions) : Except String PartialCliOptions :=
  match tokens with
  | [] => .ok state
  | "--module" :: value :: rest => parseTokens rest { state with moduleName := some value }
  | "--out" :: value :: rest => parseTokens rest { state with outDir := some value }
  | "--emit-casm" :: value :: rest =>
      match parseBoolLiteral value with
      | .ok parsed => parseTokens rest { state with emitCasm := parsed }
      | .error err => .error err
  | "--module" :: [] => .error "missing value for --module"
  | "--out" :: [] => .error "missing value for --out"
  | "--emit-casm" :: [] => .error "missing value for --emit-casm"
  | unknown :: _ => .error s!"unknown argument: {unknown}"

def usage : String :=
  String.intercalate "\n"
    [
      "Usage:",
      "  lake exe leancairo-gen --module <LeanModule> --out <Directory> [--emit-casm true|false]",
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
      }

end LeanCairo.CLI
