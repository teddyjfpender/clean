import LeanCairo.Core.Spec.FuncSpec
import LeanCairo.Core.Spec.Storage
import LeanCairo.Core.Validation.Context
import LeanCairo.Core.Validation.Errors
import LeanCairo.Core.Validation.Expr
import LeanCairo.Core.Validation.Utils

namespace LeanCairo.Core.Validation

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec

private def argEnv (args : List Param) : TypeEnv :=
  args.map (fun arg => (arg.name, arg.ty))

private def storageEnv (fields : List StorageField) : TypeEnv :=
  fields.map (fun field => (field.name, field.ty))

private def validateArgumentNames (fnName : String) (args : List Param) : List ValidationError :=
  let invalidNameErrors :=
    args.foldl
      (fun errors arg =>
        if !isValidIdentifier arg.name then
          errors ++ [.invalidIdentifier s!"function '{fnName}' argument" arg.name]
        else if isReservedInternalIdentifier arg.name then
          errors ++ [.reservedIdentifier s!"function '{fnName}' argument" arg.name]
        else
          errors)
      []
  let duplicateErrors :=
    (duplicateNames <| args.map (fun arg => arg.name)).map (fun dup =>
      ValidationError.duplicateArgumentName fnName dup)
  invalidNameErrors ++ duplicateErrors

private def validateWrite (knownStorage : TypeEnv) (writeSpec : StorageWrite) : List ValidationError :=
  let fieldNameErrors :=
    if !isValidIdentifier writeSpec.field then
      [.invalidIdentifier "storage write field name" writeSpec.field]
    else if isReservedInternalIdentifier writeSpec.field then
      [.reservedIdentifier "storage write field name" writeSpec.field]
    else
      []
  let fieldTypeErrors :=
    match lookupType knownStorage writeSpec.field with
    | none => [.unknownStorageField writeSpec.field]
    | some declaredTy =>
        if declaredTy == writeSpec.ty then
          []
        else
          [.storageFieldTypeMismatch writeSpec.field writeSpec.ty declaredTy]
  fieldNameErrors ++ fieldTypeErrors

def validateFunction (storageFields : List StorageField) (fnSpec : FuncSpec) : List ValidationError :=
  let knownStorage := storageEnv storageFields
  let nameErrors :=
    if !isValidIdentifier fnSpec.name then
      [.invalidIdentifier "function name" fnSpec.name]
    else if isReservedInternalIdentifier fnSpec.name then
      [.reservedIdentifier "function name" fnSpec.name]
    else
      []
  let argErrors := validateArgumentNames fnSpec.name fnSpec.args
  let bodyErrors := validateExpr (argEnv fnSpec.args) knownStorage fnSpec.body
  let writeSpecErrors :=
    fnSpec.writes.foldl
      (fun errors writeSpec =>
        errors ++ validateWrite knownStorage writeSpec ++ validateExpr (argEnv fnSpec.args) knownStorage writeSpec.value)
      []
  let duplicateWriteFieldErrors :=
    (duplicateNames <| fnSpec.writes.map (fun writeSpec => writeSpec.field)).map (fun dup =>
      ValidationError.duplicateStorageWriteField fnSpec.name dup)
  let writeMutabilityErrors :=
    match fnSpec.mutability with
    | .view =>
        if fnSpec.writes.isEmpty then
          []
        else
          [.writesNotAllowedInViewFunction fnSpec.name]
    | .externalMutable =>
        []
  nameErrors ++ argErrors ++ bodyErrors ++ writeSpecErrors ++ duplicateWriteFieldErrors ++ writeMutabilityErrors

end LeanCairo.Core.Validation
