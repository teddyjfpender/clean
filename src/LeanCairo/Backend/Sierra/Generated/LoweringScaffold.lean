-- This file is generated. Do not edit manually.

-- Regenerate with: python3 scripts/roadmap/generate_lowering_scaffolds.py ...



namespace LeanCairo.Backend.Sierra.Generated

def sierraLoweringImplementedCapabilityIds : List String :=
[
  "cap.integer.u128.add.wrapping",
  "cap.integer.u128.mul.wrapping",
  "cap.integer.u128.sub.wrapping",
  "cap.scalar.bool.literal",
  "cap.scalar.felt252.add",
  "cap.scalar.felt252.mul",
  "cap.scalar.felt252.sub",
]

def sierraLoweringFailFastStubs : List (String × String) :=
[
  ("cap.aggregate.tuple_struct_enum", "capability 'cap.aggregate.tuple_struct_enum' is not implemented for Sierra lowering (state: planned)"),
  ("cap.collection.array_span_dict", "capability 'cap.collection.array_span_dict' is not implemented for Sierra lowering (state: planned)"),
  ("cap.control.calls_loops_panic", "capability 'cap.control.calls_loops_panic' is not implemented for Sierra lowering (state: planned)"),
  ("cap.field.qm31", "capability 'cap.field.qm31' is not implemented for Sierra lowering (state: planned)"),
  ("cap.integer.family.non_u128", "capability 'cap.integer.family.non_u128' is not implemented for Sierra lowering (state: fail_fast)"),
  ("cap.resource.gas_ap_segment", "capability 'cap.resource.gas_ap_segment' is not implemented for Sierra lowering (state: planned)"),
]

def sierraLoweringLookupStubMessage (capabilityId : String) : Option String :=
  (sierraLoweringFailFastStubs.find? (fun entry => entry.fst = capabilityId)).map Prod.snd

def sierraLoweringFailFastMessage (capabilityId : String) : String :=
  match sierraLoweringLookupStubMessage capabilityId with
  | some msg => msg
  | none => s!"unsupported unregistered capability '{capabilityId}' in Sierra lowering scaffold"

end LeanCairo.Backend.Sierra.Generated
