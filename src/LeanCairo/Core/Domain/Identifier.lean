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

def internalReservedPrefix : String :=
  "__leancairo_internal_"

private def hasPrefix (pref value : List Char) : Bool :=
  match pref, value with
  | [], _ => true
  | _, [] => false
  | pHead :: pTail, vHead :: vTail => pHead = vHead && hasPrefix pTail vTail

def isReservedInternalIdentifier (value : String) : Bool :=
  hasPrefix internalReservedPrefix.toList value.toList

def isValidModuleName (value : String) : Bool :=
  let parts := value.splitOn "."
  !parts.isEmpty && parts.all (fun part => part != "" && isValidIdentifier part)

end LeanCairo.Core.Domain
