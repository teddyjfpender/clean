import LeanCairo.Core.Domain.Identifier
import LeanCairo.Core.Spec.FuncSpec
import LeanCairo.Core.Spec.Storage

namespace LeanCairo.Core.Spec

open LeanCairo.Core.Domain

structure ContractSpec where
  contractName : Ident
  storage : List StorageField := []
  functions : List FuncSpec
  deriving Repr

end LeanCairo.Core.Spec
