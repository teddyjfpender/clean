import LeanCairo.Core.Domain.Identifier
import LeanCairo.Core.Domain.Mutability
import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.Storage
import LeanCairo.Core.Syntax.Expr

namespace LeanCairo.Core.Spec

open LeanCairo.Core.Domain
open LeanCairo.Core.Syntax

structure Param where
  name : Ident
  ty : Ty
  deriving Repr, DecidableEq, BEq, Inhabited

structure StorageWrite where
  field : Ident
  ty : Ty
  value : Expr ty
  deriving Repr

structure FuncSpec where
  name : Ident
  args : List Param
  ret : Ty
  body : Expr ret
  mutability : Mutability := .view
  writes : List StorageWrite := []
  deriving Repr

end LeanCairo.Core.Spec
