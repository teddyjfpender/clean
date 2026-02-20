namespace LeanCairo.Core.Domain

abbrev Ident := String

private def isIdentStart (c : Char) : Bool :=
  c.isAlpha || c = '_'

private def isIdentContinue (c : Char) : Bool :=
  c.isAlphanum || c = '_'

def isValidIdentifier (value : String) : Bool :=
  match value.toList with
  | [] => false
  | head :: tail => isIdentStart head && tail.all isIdentContinue

def isValidModuleName (value : String) : Bool :=
  let parts := value.splitOn "."
  !parts.isEmpty && parts.all (fun part => part != "" && isValidIdentifier part)

end LeanCairo.Core.Domain
