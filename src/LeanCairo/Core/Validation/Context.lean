import LeanCairo.Core.Domain.Identifier
import LeanCairo.Core.Domain.Ty

namespace LeanCairo.Core.Validation

open LeanCairo.Core.Domain

abbrev TypeEnv := List (Prod Ident Ty)

def lookupType (env : TypeEnv) (name : Ident) : Option Ty :=
  match env.find? (fun entry => entry.fst = name) with
  | some entry => some entry.snd
  | none => none

def bindType (env : TypeEnv) (name : Ident) (ty : Ty) : TypeEnv :=
  (name, ty) :: env

def hasBinding (env : TypeEnv) (name : Ident) : Bool :=
  match lookupType env name with
  | some _ => true
  | none => false

end LeanCairo.Core.Validation
