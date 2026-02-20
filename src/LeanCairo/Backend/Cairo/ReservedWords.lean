namespace LeanCairo.Backend.Cairo

private def reservedWords : List String :=
  [
    "as",
    "const",
    "else",
    "enum",
    "extern",
    "false",
    "fn",
    "for",
    "if",
    "impl",
    "implicits",
    "let",
    "loop",
    "match",
    "mod",
    "mut",
    "nopanic",
    "of",
    "pub",
    "ref",
    "return",
    "self",
    "static",
    "struct",
    "trait",
    "true",
    "type",
    "use",
    "where",
    "while"
  ]

def isReservedWord (name : String) : Bool :=
  reservedWords.contains name

def escapeReservedWord (name : String) : String :=
  if isReservedWord name then
    name ++ "_"
  else
    name

end LeanCairo.Backend.Cairo
