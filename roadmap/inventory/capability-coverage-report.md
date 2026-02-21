# Capability Coverage Report

Source registry: `roadmap/capabilities/registry.json`

## Totals

- Total capabilities: `15`
- overall_status_counts: `implemented=7`, `fail_fast=1`, `planned=7`
- sierra_status_counts: `implemented=7`, `fail_fast=1`, `planned=7`
- cairo_status_counts: `implemented=7`, `fail_fast=0`, `planned=8`
- proof_status_counts: `complete=0`, `partial=7`, `planned=8`
- closure_ratios: `overall=0.466667`, `sierra=0.466667`, `cairo=0.466667`

## Family Matrix

| Family | Total | Overall implemented | Overall fail_fast | Overall planned |
| --- | ---: | ---: | ---: | ---: |
| `aggregate` | 1 | 0 | 0 | 1 |
| `circuit` | 1 | 0 | 0 | 1 |
| `collection` | 1 | 0 | 0 | 1 |
| `control` | 1 | 0 | 0 | 1 |
| `crypto` | 1 | 0 | 0 | 1 |
| `field` | 1 | 0 | 0 | 1 |
| `integer` | 4 | 3 | 1 | 0 |
| `resource` | 1 | 0 | 0 | 1 |
| `scalar` | 4 | 4 | 0 | 0 |

## Family Closure Ratios

| Family | Overall implemented ratio | Sierra implemented ratio | Cairo implemented ratio |
| --- | ---: | ---: | ---: |
| `aggregate` | 0.0 | 0.0 | 0.0 |
| `circuit` | 0.0 | 0.0 | 0.0 |
| `collection` | 0.0 | 0.0 | 0.0 |
| `control` | 0.0 | 0.0 | 0.0 |
| `crypto` | 0.0 | 0.0 | 0.0 |
| `field` | 0.0 | 0.0 | 0.0 |
| `integer` | 0.75 | 0.75 | 0.75 |
| `resource` | 0.0 | 0.0 | 0.0 |
| `scalar` | 1.0 | 1.0 | 1.0 |

## Capability State Matrix

| Capability ID | Family | Overall | Sierra | Cairo | Diverges | Divergence constraints |
| --- | --- | --- | --- | --- | --- | --- |
| `cap.aggregate.tuple_struct_enum` | `aggregate` | `planned` | `planned` | `planned` | `false` | none |
| `cap.circuit.constraint_gate` | `circuit` | `planned` | `planned` | `planned` | `false` | none |
| `cap.collection.array_span_dict` | `collection` | `planned` | `planned` | `planned` | `false` | none |
| `cap.control.calls_loops_panic` | `control` | `planned` | `planned` | `planned` | `false` | none |
| `cap.crypto.round_mix` | `crypto` | `planned` | `planned` | `planned` | `false` | none |
| `cap.field.qm31` | `field` | `planned` | `planned` | `planned` | `false` | none |
| `cap.integer.family.non_u128` | `integer` | `fail_fast` | `fail_fast` | `planned` | `true` | Sierra lane requires explicit fail-fast until range-checked non-u128 arithmetic lowering is implemented; Cairo backend remains planned until parity closure. |
| `cap.integer.u128.add.wrapping` | `integer` | `implemented` | `implemented` | `implemented` | `false` | none |
| `cap.integer.u128.mul.wrapping` | `integer` | `implemented` | `implemented` | `implemented` | `false` | none |
| `cap.integer.u128.sub.wrapping` | `integer` | `implemented` | `implemented` | `implemented` | `false` | none |
| `cap.resource.gas_ap_segment` | `resource` | `planned` | `planned` | `planned` | `false` | none |
| `cap.scalar.bool.literal` | `scalar` | `implemented` | `implemented` | `implemented` | `false` | none |
| `cap.scalar.felt252.add` | `scalar` | `implemented` | `implemented` | `implemented` | `false` | none |
| `cap.scalar.felt252.mul` | `scalar` | `implemented` | `implemented` | `implemented` | `false` | none |
| `cap.scalar.felt252.sub` | `scalar` | `implemented` | `implemented` | `implemented` | `false` | none |

## Capability IDs

### implemented_capability_ids
- `cap.integer.u128.add.wrapping`
- `cap.integer.u128.mul.wrapping`
- `cap.integer.u128.sub.wrapping`
- `cap.scalar.bool.literal`
- `cap.scalar.felt252.add`
- `cap.scalar.felt252.mul`
- `cap.scalar.felt252.sub`

### fail_fast_capability_ids
- `cap.integer.family.non_u128`

### planned_capability_ids
- `cap.aggregate.tuple_struct_enum`
- `cap.circuit.constraint_gate`
- `cap.collection.array_span_dict`
- `cap.control.calls_loops_panic`
- `cap.crypto.round_mix`
- `cap.field.qm31`
- `cap.resource.gas_ap_segment`
