-- This file is generated. Do not edit manually.

-- Regenerate with: python3 scripts/roadmap/generate_lowering_scaffolds.py ...



namespace LeanCairo.Backend.Sierra.Generated

def sierraLoweringImplementedCapabilityIds : List String :=
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

def sierraLoweringFailFastStubs : List (String × String) :=
[
  ("cap.circuit.constraint_gate", "capability 'cap.circuit.constraint_gate' is not implemented for Sierra lowering (state: planned)"),
  ("cap.control.calls_loops_panic", "capability 'cap.control.calls_loops_panic' is not implemented for Sierra lowering (state: planned)"),
  ("cap.crypto.round_mix", "capability 'cap.crypto.round_mix' is not implemented for Sierra lowering (state: planned)"),
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
