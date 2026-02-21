import LeanCairo.Core.Domain.Ty

namespace LeanCairo.Backend.Sierra.Generated

open LeanCairo.Core.Domain

def sierraImplementedCapabilityIds : List String :=
[
  "cap.aggregate.tuple_struct_enum",
  "cap.collection.array_span_dict",
  "cap.integer.u128.add.wrapping",
  "cap.integer.u128.mul.wrapping",
  "cap.integer.u128.sub.wrapping",
  "cap.scalar.bool.literal",
  "cap.scalar.felt252.add",
  "cap.scalar.felt252.mul",
  "cap.scalar.felt252.sub",
]

def sierraFailFastCapabilityIds : List String :=
[
  "cap.integer.family.non_u128",
]

def sierraSupportedSignatureTys : List Ty :=
[
  .bool,
  .felt252,
  .u128,
]

def sierraSupportedSignatureTyFamilies : List String :=
[
  "array",
  "boxed",
  "enum",
  "nullable",
  "span",
  "struct",
]

def isSierraCapabilityImplemented (capabilityId : String) : Bool :=
  sierraImplementedCapabilityIds.contains capabilityId

def isSierraSignatureTyFamilySupported (ty : Ty) : Bool :=
  match ty with
  | .tuple _ => sierraSupportedSignatureTyFamilies.contains "struct"
  | .structTy _ => sierraSupportedSignatureTyFamilies.contains "struct"
  | .enumTy _ => sierraSupportedSignatureTyFamilies.contains "enum"
  | .array _ => sierraSupportedSignatureTyFamilies.contains "array"
  | .span _ => sierraSupportedSignatureTyFamilies.contains "span"
  | .nullable _ => sierraSupportedSignatureTyFamilies.contains "nullable"
  | .boxed _ => sierraSupportedSignatureTyFamilies.contains "boxed"
  | .dict _ _ => sierraSupportedSignatureTyFamilies.contains "dict"
  | .nonZero _ => sierraSupportedSignatureTyFamilies.contains "nonzero"
  | _ => false

def isSierraSignatureTySupported (ty : Ty) : Bool :=
  sierraSupportedSignatureTys.contains ty || isSierraSignatureTyFamilySupported ty

end LeanCairo.Backend.Sierra.Generated
