# Capability Coverage Report

Source registry: `roadmap/capabilities/registry.json`

## Totals

- Total capabilities: `12`
- overall_status_counts: `implemented=6`, `fail_fast=1`, `planned=5`
- sierra_status_counts: `implemented=6`, `fail_fast=1`, `planned=5`
- cairo_status_counts: `implemented=6`, `fail_fast=0`, `planned=6`
- proof_status_counts: `complete=0`, `partial=6`, `planned=6`

## Family Matrix

| Family | Total | Overall implemented | Overall fail_fast | Overall planned |
| --- | ---: | ---: | ---: | ---: |
| `aggregate` | 1 | 0 | 0 | 1 |
| `collection` | 1 | 0 | 0 | 1 |
| `control` | 1 | 0 | 0 | 1 |
| `field` | 1 | 0 | 0 | 1 |
| `integer` | 4 | 3 | 1 | 0 |
| `resource` | 1 | 0 | 0 | 1 |
| `scalar` | 3 | 3 | 0 | 0 |

## Capability IDs

### implemented_capability_ids
- `cap.integer.u128.add.wrapping`
- `cap.integer.u128.mul.wrapping`
- `cap.integer.u128.sub.wrapping`
- `cap.scalar.felt252.add`
- `cap.scalar.felt252.mul`
- `cap.scalar.felt252.sub`

### fail_fast_capability_ids
- `cap.integer.family.non_u128`

### planned_capability_ids
- `cap.aggregate.tuple_struct_enum`
- `cap.collection.array_span_dict`
- `cap.control.calls_loops_panic`
- `cap.field.qm31`
- `cap.resource.gas_ap_segment`
