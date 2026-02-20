import LeanCairo.Backend.Cairo.ReservedWords

namespace LeanCairo.Backend.Cairo

private def normalizeIdentifierChars (value : String) : String :=
  String.ofList <| value.toList.map (fun c => if c.isAlphanum || c = '_' then c else '_')

private def ensureLeadingNonDigit (value : String) : String :=
  match value.toList with
  | [] => "unnamed"
  | head :: _ => if head.isDigit then "_" ++ value else value

private def pushSnakeChar (acc : String) (c : Char) : String :=
  if c.isAlphanum || c = '_' then
    acc.push c
  else
    acc.push '_'

private partial def toSnakeCaseLoop (remaining : List Char) (isFirst : Bool) (previousUnderscore : Bool)
    (acc : String) : String :=
  match remaining with
  | [] => acc
  | c :: tail =>
      if c.isUpper then
        let acc :=
          if isFirst || previousUnderscore then
            acc
          else
            acc.push '_'
        toSnakeCaseLoop tail false false (acc.push c.toLower)
      else
        let mapped :=
          if c = '-' || c = ' ' || c = '.' then
            '_'
          else
            if c.isAlphanum || c = '_' then c else '_'
        toSnakeCaseLoop tail false (mapped = '_') (acc.push mapped)

def toSnakeCase (value : String) : String :=
  toSnakeCaseLoop value.toList true false ""

def sanitizeIdentifier (value : String) : String :=
  let normalized := normalizeIdentifierChars value
  let withLeader := ensureLeadingNonDigit normalized
  escapeReservedWord withLeader

def toCairoContractName (value : String) : String :=
  sanitizeIdentifier value

def toCairoFunctionName (value : String) : String :=
  sanitizeIdentifier <| toSnakeCase value

def toCairoLocalName (value : String) : String :=
  sanitizeIdentifier <| toSnakeCase value

def toCairoStorageFieldName (value : String) : String :=
  sanitizeIdentifier <| toSnakeCase value

def toScarbPackageName (contractName : String) : String :=
  String.ofList <| (toSnakeCase contractName).toList.map Char.toLower

end LeanCairo.Backend.Cairo
