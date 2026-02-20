import LeanCairo.Core.Domain.Identifier
import LeanCairo.Core.Spec.FuncSpec

namespace LeanCairo.Core.Spec

open LeanCairo.Core.Domain

structure ContractSpec where
  contractName : Ident
  functions : List FuncSpec
  deriving Repr

end LeanCairo.Core.Spec
