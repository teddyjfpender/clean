# Corpus Coverage Report

- Manifest: `config/examples-manifest.json`
- Capability registry: `roadmap/capabilities/registry.json`
- Kernels: `10`

## Kernel Mapping

| Kernel | Complexity | Families | Capability IDs |
| --- | --- | --- | --- |
| `aggregate_payload_mix` | `medium` | `aggregate` | `cap.aggregate.tuple_struct_enum` |
| `circuit_gate_felt` | `medium` | `circuit` | `cap.circuit.constraint_gate` |
| `crypto_round_felt` | `high` | `crypto` | `cap.crypto.round_mix, cap.scalar.felt252.sub` |
| `fast_power_u128` | `high` | `integer` | `cap.integer.u128.add.wrapping, cap.integer.u128.mul.wrapping` |
| `fast_power_u128_p63` | `high` | `integer` | `cap.integer.u128.add.wrapping, cap.integer.u128.mul.wrapping` |
| `karatsuba_u128` | `high` | `integer` | `cap.integer.u128.add.wrapping, cap.integer.u128.mul.wrapping, cap.integer.u128.sub.wrapping` |
| `newton_u128` | `high` | `control_flow, fixed_point` | `cap.control.calls_loops_panic, cap.integer.u128.mul.wrapping, cap.integer.u128.sub.wrapping` |
| `scalar_core` | `medium` | `scalar` | `cap.scalar.bool.literal, cap.scalar.felt252.add, cap.scalar.felt252.mul` |
| `sq128x128_u128` | `high` | `fixed_point` | `cap.integer.u128.add.wrapping, cap.integer.u128.mul.wrapping` |
| `u128_range_checked` | `medium` | `integer` | `cap.integer.u128.add.wrapping, cap.integer.u128.mul.wrapping, cap.integer.u128.sub.wrapping` |

## Implemented Capability Coverage

- Implemented capabilities in registry: `7`
- Implemented capabilities covered by corpus: `7`
- Coverage ratio: `1.0`
- Missing: `none`

## Required Family Coverage

| Family | Satisfied | Medium | High | Total |
| --- | --- | ---: | ---: | ---: |
| `integer` | `true` | `1` | `3` | `4` |
| `fixed_point` | `true` | `0` | `2` | `2` |
| `control_flow` | `true` | `0` | `1` | `1` |
| `aggregate` | `true` | `1` | `0` | `1` |
| `crypto` | `true` | `0` | `1` | `1` |
| `circuit` | `true` | `1` | `0` | `1` |
