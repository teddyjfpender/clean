import LeanCairo.Core.Domain.Identifier
import LeanCairo.Core.Domain.Ty

namespace LeanCairo.Core.Spec

open LeanCairo.Core.Domain

structure StorageField where
  name : Ident
  ty : Ty
  deriving Repr, DecidableEq, BEq, Inhabited

end LeanCairo.Core.Spec
