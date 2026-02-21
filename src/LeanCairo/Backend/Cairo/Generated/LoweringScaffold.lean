-- This file is generated. Do not edit manually.

-- Regenerate with: python3 scripts/roadmap/generate_lowering_scaffolds.py ...



namespace LeanCairo.Backend.Cairo.Generated

def cairoLoweringImplementedCapabilityIds : List String :=
[
  "cap.integer.u128.add.wrapping",
  "cap.integer.u128.mul.wrapping",
  "cap.integer.u128.sub.wrapping",
  "cap.scalar.bool.literal",
  "cap.scalar.felt252.add",
  "cap.scalar.felt252.mul",
  "cap.scalar.felt252.sub",
]

def cairoLoweringFailFastStubs : List (String × String) :=
[
  ("cap.aggregate.tuple_struct_enum", "capability 'cap.aggregate.tuple_struct_enum' is not implemented for Cairo lowering (state: planned)"),
  ("cap.circuit.constraint_gate", "capability 'cap.circuit.constraint_gate' is not implemented for Cairo lowering (state: planned)"),
  ("cap.collection.array_span_dict", "capability 'cap.collection.array_span_dict' is not implemented for Cairo lowering (state: planned)"),
  ("cap.control.calls_loops_panic", "capability 'cap.control.calls_loops_panic' is not implemented for Cairo lowering (state: planned)"),
  ("cap.crypto.round_mix", "capability 'cap.crypto.round_mix' is not implemented for Cairo lowering (state: planned)"),
  ("cap.field.qm31", "capability 'cap.field.qm31' is not implemented for Cairo lowering (state: planned)"),
  ("cap.integer.family.non_u128", "capability 'cap.integer.family.non_u128' is not implemented for Cairo lowering (state: planned)"),
  ("cap.resource.gas_ap_segment", "capability 'cap.resource.gas_ap_segment' is not implemented for Cairo lowering (state: planned)"),
]

def cairoLoweringLookupStubMessage (capabilityId : String) : Option String :=
  (cairoLoweringFailFastStubs.find? (fun entry => entry.fst = capabilityId)).map Prod.snd

def cairoLoweringFailFastMessage (capabilityId : String) : String :=
  match cairoLoweringLookupStubMessage capabilityId with
  | some msg => msg
  | none => s!"unsupported unregistered capability '{capabilityId}' in Cairo lowering scaffold"

end LeanCairo.Backend.Cairo.Generated
