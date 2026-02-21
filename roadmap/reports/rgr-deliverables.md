# RGR Deliverables

- Pinned commit: `e56055c87a9db4e3dbb91c82ccb2ea751a8dc617`
- Spec: `config/rgr-deliverable-spec.json`
- Matrix: `roadmap/inventory/sierra-coverage-matrix.json`

## Summary

- Deliverables: `7`
- `NOT DONE`: `6`
- `DONE`: `1`

## Catalog

| ID | Priority | Policy | Modules | Remaining | Ready | Status |
| --- | ---: | --- | ---: | ---: | --- | --- |
| `d00-non-starknet-closure-guard` | `0` | `implemented_or_failfast` | `52` | `0` | `yes` | `DONE - e36bd15` |
| `d01-range-and-integer-families` | `1` | `implemented_only` | `14` | `14` | `no` | `NOT DONE` |
| `d02-aggregate-and-collection-families` | `2` | `implemented_only` | `9` | `9` | `no` | `NOT DONE` |
| `d03-control-and-call-families` | `3` | `implemented_only` | `6` | `6` | `no` | `NOT DONE` |
| `d04-resource-and-runtime-families` | `4` | `implemented_only` | `10` | `10` | `no` | `NOT DONE` |
| `d05-crypto-field-circuit-families` | `5` | `implemented_only` | `9` | `9` | `no` | `NOT DONE` |
| `d06-starknet-unresolved-families` | `6` | `implemented_only` | `10` | `10` | `no` | `NOT DONE` |

## Deliverable Details

### `d00-non-starknet-closure-guard` Non-Starknet closure guard
- Priority: `0`
- Policy: `implemented_or_failfast`
- Status: `DONE - e36bd15`
- Computed ready: `True`
- Module count: `52`
- Remaining count: `0`
- Gates:
- RED: `scripts/test/sierra_primary_closure_negative.sh`
- GREEN: `scripts/roadmap/check_sierra_primary_closure.sh`
- REFACTOR: `scripts/roadmap/check_coverage_matrix_freshness.sh`, `scripts/roadmap/check_sierra_coverage_report_freshness.sh`

### `d01-range-and-integer-families` Range-checked and integer family expansion
- Priority: `1`
- Policy: `implemented_only`
- Status: `NOT DONE`
- Computed ready: `False`
- Module count: `14`
- Remaining count: `14`
- Gates:
- RED: `scripts/test/sierra_failfast_unsupported.sh`, `scripts/test/eval_unsupported_domain_failfast.sh`
- GREEN: `scripts/test/eval_integer_width_semantics.sh`, `scripts/test/eval_conversion_legality.sh`, `scripts/test/sierra_u128_range_checked_e2e.sh`, `scripts/test/sierra_u128_wrapping_differential.sh`
- REFACTOR: `scripts/test/sierra_structural_optimization_reproducibility.sh`, `scripts/bench/check_optimizer_family_thresholds.sh`
- Remaining modules:
- `bounded_int`
- `casts`
- `int/mod`
- `int/signed`
- `int/signed128`
- `int/unsigned`
- `int/unsigned128`
- `int/unsigned256`
- `int/unsigned512`
- `is_zero`
- `non_zero`
- `range`
- `range_check`
- `try_from_felt252`

### `d02-aggregate-and-collection-families` Aggregate and collection expansion
- Priority: `2`
- Policy: `implemented_only`
- Status: `NOT DONE`
- Computed ready: `False`
- Module count: `9`
- Remaining count: `9`
- Gates:
- RED: `scripts/test/sierra_failfast_unsupported.sh`, `scripts/test/eval_aggregate_wrapper_semantics.sh`
- GREEN: `scripts/test/sierra_aggregate_collection_e2e.sh`, `scripts/test/sierra_aggregate_branch_typing.sh`, `scripts/test/backend_parity_aggregate_collection.sh`
- REFACTOR: `scripts/test/sierra_structural_optimization_reproducibility.sh`, `scripts/test/examples_regeneration_deterministic.sh`
- Remaining modules:
- `array`
- `boxing`
- `enm`
- `felt252_dict`
- `nullable`
- `snapshot`
- `span`
- `squashed_felt252_dict`
- `structure`

### `d03-control-and-call-families` Control-flow and call-family expansion
- Priority: `3`
- Policy: `implemented_only`
- Status: `NOT DONE`
- Computed ready: `False`
- Module count: `6`
- Remaining count: `6`
- Gates:
- RED: `scripts/test/sierra_failfast_unsupported.sh`, `scripts/test/control_flow_normalization_regression.sh`
- GREEN: `scripts/test/call_panic_semantics_regression.sh`, `scripts/test/sierra_differential.sh`, `scripts/test/sierra_e2e.sh`
- REFACTOR: `scripts/test/canonicalization_regression.sh`, `scripts/test/sierra_structural_optimization_reproducibility.sh`
- Remaining modules:
- `branch_align`
- `coupon`
- `function_call`
- `mod`
- `unconditional_jump`
- `unsafe_panic`

### `d04-resource-and-runtime-families` Resource and runtime family expansion
- Priority: `4`
- Policy: `implemented_only`
- Status: `NOT DONE`
- Computed ready: `False`
- Module count: `10`
- Remaining count: `10`
- Gates:
- RED: `scripts/test/sierra_failfast_unsupported.sh`, `scripts/test/effect_resource_regression.sh`
- GREEN: `scripts/roadmap/check_effect_metadata.sh`, `scripts/test/effect_resource_regression.sh`, `scripts/test/sierra_e2e.sh`
- REFACTOR: `scripts/test/benchmark_family_thresholds_negative.sh`, `scripts/bench/check_optimizer_family_thresholds.sh`
- Remaining modules:
- `ap_tracking`
- `const_type`
- `consts`
- `debug`
- `gas`
- `gas_reserve`
- `segment_arena`
- `trace`
- `uninitialized`
- `utils`

### `d05-crypto-field-circuit-families` Crypto, field, and circuit family expansion
- Priority: `5`
- Policy: `implemented_only`
- Status: `NOT DONE`
- Computed ready: `False`
- Module count: `9`
- Remaining count: `9`
- Gates:
- RED: `scripts/test/sierra_failfast_unsupported.sh`, `scripts/test/eval_qm31_semantics.sh`
- GREEN: `scripts/test/sierra_advanced_family_e2e.sh`, `scripts/test/backend_parity_advanced_family.sh`, `scripts/test/eval_qm31_semantics.sh`
- REFACTOR: `scripts/bench/check_optimizer_non_regression.sh`, `scripts/bench/check_optimizer_family_thresholds.sh`
- Remaining modules:
- `bitwise`
- `blake`
- `boolean`
- `bytes31`
- `circuit`
- `ec`
- `pedersen`
- `poseidon`
- `qm31`

### `d06-starknet-unresolved-families` Starknet unresolved family expansion
- Priority: `6`
- Policy: `implemented_only`
- Status: `NOT DONE`
- Computed ready: `False`
- Module count: `10`
- Remaining count: `10`
- Gates:
- RED: `scripts/test/sierra_primary_cairo_coupling_guard.sh`
- GREEN: `scripts/test/e2e.sh`, `scripts/test/sierra_primary_without_cairo.sh`
- REFACTOR: `scripts/test/architecture_boundaries.sh`, `scripts/roadmap/check_architecture_boundaries.sh`
- Remaining modules:
- `starknet/emit_event`
- `starknet/getter`
- `starknet/interoperability`
- `starknet/mod`
- `starknet/secp256`
- `starknet/secp256k1`
- `starknet/secp256r1`
- `starknet/storage`
- `starknet/syscalls`
- `starknet/testing`
