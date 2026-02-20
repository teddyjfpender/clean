import LeanCairo.Core.Domain.Identifier

namespace LeanCairo.Core.Validation

open LeanCairo.Core.Domain

def duplicateNames (names : List Ident) : List Ident :=
  let rec go (seen : List Ident) (dups : List Ident) (remaining : List Ident) : List Ident :=
    match remaining with
    | [] => dups.reverse
    | head :: tail =>
        if seen.contains head then
          if dups.contains head then
            go seen dups tail
          else
            go seen (head :: dups) tail
        else
          go (head :: seen) dups tail
  go [] [] names

end LeanCairo.Core.Validation
