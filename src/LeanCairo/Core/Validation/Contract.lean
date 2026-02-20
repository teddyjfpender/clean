import LeanCairo.Core.Spec.ContractSpec
import LeanCairo.Core.Spec.Storage
import LeanCairo.Core.Validation.Errors
import LeanCairo.Core.Validation.Function
import LeanCairo.Core.Validation.Utils

namespace LeanCairo.Core.Validation

open LeanCairo.Core.Domain
open LeanCairo.Core.Spec

private def validateContractName (contractName : String) : List ValidationError :=
  if isValidIdentifier contractName then
    []
  else
    [.invalidIdentifier "contract name" contractName]

private def validateFunctionList (spec : ContractSpec) : List ValidationError :=
  if spec.functions.isEmpty then
    [.emptyFunctionList spec.contractName]
  else
    []

private def duplicateFunctionErrors (spec : ContractSpec) : List ValidationError :=
  (duplicateNames <| spec.functions.map (fun fnSpec => fnSpec.name)).map ValidationError.duplicateFunctionName

private def validateStorageFieldNames (fields : List StorageField) : List ValidationError :=
  let invalidNameErrors :=
    fields.foldl
      (fun errors field =>
        if isValidIdentifier field.name then
          errors
        else
          errors ++ [.invalidIdentifier "storage field" field.name])
      []
  let duplicateErrors :=
    (duplicateNames <| fields.map (fun field => field.name)).map ValidationError.duplicateStorageFieldName
  invalidNameErrors ++ duplicateErrors

def validateContractErrors (spec : ContractSpec) : List ValidationError :=
  validateContractName spec.contractName ++
    validateFunctionList spec ++
    validateStorageFieldNames spec.storage ++
    duplicateFunctionErrors spec ++
    spec.functions.foldl (fun errors fnSpec => errors ++ validateFunction spec.storage fnSpec) []

def validateContract (spec : ContractSpec) : Except (List ValidationError) ContractSpec :=
  let errors := validateContractErrors spec
  if errors.isEmpty then
    .ok spec
  else
    .error errors

end LeanCairo.Core.Validation
