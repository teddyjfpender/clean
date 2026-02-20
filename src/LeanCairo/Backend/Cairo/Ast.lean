import LeanCairo.Backend.Cairo.Pretty

namespace LeanCairo.Backend.Cairo

/-!
Structured Cairo emission boundary used by the secondary backend:
- keep function signatures and body statements typed,
- keep formatting deterministic and centralized.
-/

structure CairoFunctionSignature where
  name : String
  params : List String
  ret : String
  deriving Repr, DecidableEq

inductive CairoStmt where
  | expr (source : String)
  | letDecl (name : String) (ty : String) (value : String)
  deriving Repr, DecidableEq

structure CairoFunction where
  signature : CairoFunctionSignature
  body : List CairoStmt
  deriving Repr, DecidableEq

def renderFunctionSignature (signature : CairoFunctionSignature) : String :=
  "fn "
    ++ signature.name
    ++ "("
    ++ String.intercalate ", " signature.params
    ++ ") -> "
    ++ signature.ret

private def renderLetDeclAt (depth : Nat) (name : String) (ty : String) (value : String) : String :=
  if value.contains '\n' then
    String.intercalate "\n"
      [
        indent depth ++ "let " ++ name ++ ": " ++ ty ++ " = (",
        indentLines (depth + 1) value,
        indent depth ++ ");"
      ]
  else
    indent depth ++ "let " ++ name ++ ": " ++ ty ++ " = " ++ value ++ ";"

def renderStmtAt (depth : Nat) : CairoStmt -> String
  | .expr source => indentLines depth source
  | .letDecl name ty value => renderLetDeclAt depth name ty value

def renderFunctionAt (depth : Nat) (fnDef : CairoFunction) : String :=
  let header := indent depth ++ renderFunctionSignature fnDef.signature ++ " {"
  let body :=
    if fnDef.body.isEmpty then
      [indent (depth + 1) ++ "()"]
    else
      fnDef.body.map (renderStmtAt (depth + 1))
  let footer := indent depth ++ "}"
  String.intercalate "\n" ([header] ++ body ++ [footer])

def renderFunction (fnDef : CairoFunction) : String :=
  renderFunctionAt 0 fnDef

theorem renderFunctionAtDeterministic (depth : Nat) (fnDef : CairoFunction) :
    renderFunctionAt depth fnDef = renderFunctionAt depth fnDef := rfl

end LeanCairo.Backend.Cairo
