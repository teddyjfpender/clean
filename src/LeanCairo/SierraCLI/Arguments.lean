import LeanCairo.Core.Domain.Identifier

namespace LeanCairo.SierraCLI

open LeanCairo.Core.Domain

structure CliOptions where
  moduleName : String
  outDir : String
  optimize : Bool
  deriving Repr

private structure PartialCliOptions where
  moduleName : Option String := none
  outDir : Option String := none
  optimize : Bool := true

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
  | "--optimize" :: value :: rest =>
      match parseBoolLiteral "--optimize" value with
      | .ok parsed => parseTokens rest { state with optimize := parsed }
      | .error err => .error err
  | "--module" :: [] => .error "missing value for --module"
  | "--out" :: [] => .error "missing value for --out"
  | "--optimize" :: [] => .error "missing value for --optimize"
  | unknown :: _ => .error s!"unknown argument: {unknown}"

def usage : String :=
  String.intercalate "\n"
    [
      "Usage:",
      "  lake exe leancairo-sierra-gen --module <LeanModule> --out <Directory> [--optimize true|false]",
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
        optimize := parsed.optimize
      }

end LeanCairo.SierraCLI
