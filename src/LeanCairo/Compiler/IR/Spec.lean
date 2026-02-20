import LeanCairo.Compiler.IR.Expr
import LeanCairo.Core.Domain.Identifier
import LeanCairo.Core.Domain.Mutability
import LeanCairo.Core.Domain.Ty
import LeanCairo.Core.Spec.FuncSpec
import LeanCairo.Core.Spec.Storage

namespace LeanCairo.Compiler.IR

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec

structure IRStorageWrite where
  field : Ident
  ty : Ty
  value : IRExpr ty
  deriving Repr

structure IRFuncSpec where
  name : Ident
  args : List Param
  ret : Ty
  body : IRExpr ret
  mutability : Mutability := .view
  writes : List IRStorageWrite := []
  deriving Repr

structure IRContractSpec where
  contractName : Ident
  storage : List StorageField := []
  functions : List IRFuncSpec
  deriving Repr

end LeanCairo.Compiler.IR
