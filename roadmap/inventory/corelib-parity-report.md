# Corelib Parity Report (Pinned)

- Commit: `e56055c87a9db4e3dbb91c82ccb2ea751a8dc617`
- Source inventory: `roadmap/inventory/corelib-src-inventory.md`
- Coverage matrix input: `roadmap/inventory/sierra-coverage-matrix.json`
- Total corelib files classified: `160`
- `supported`: `1`
- `partial`: `2`
- `excluded`: `157`

## Classification Rules

1. Files under Starknet/test/prelude prefixes are classified as `excluded` for current function-first scope.
2. Mapped files are classified from Sierra extension module status:
   - `implemented` -> `supported`
   - `fail_fast` -> `partial`
   - any other status -> `excluded`
3. Files without a direct mapping rule are `excluded` until explicit mapping is added.

## File Classification

| Corelib file | Status | Sierra module | Reason |
| --- | --- | --- | --- |
| `corelib/src/array.cairo` | `excluded` | `array` | mapped Sierra module status is 'unresolved' (not yet in supported/partial lane) |
| `corelib/src/blake.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/boolean.cairo` | `partial` | `boolean` | mapped Sierra module is fail-fast bounded in current direct backend lane |
| `corelib/src/box.cairo` | `excluded` | `boxing` | mapped Sierra module status is 'unresolved' (not yet in supported/partial lane) |
| `corelib/src/byte_array.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/bytes_31.cairo` | `excluded` | `bytes31` | mapped Sierra module status is 'unresolved' (not yet in supported/partial lane) |
| `corelib/src/circuit.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/clone.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/cmp.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/debug.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/dict.cairo` | `excluded` | `felt252_dict` | mapped Sierra module status is 'unresolved' (not yet in supported/partial lane) |
| `corelib/src/ec.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/ecdsa.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/felt_252.cairo` | `supported` | `felt252` | mapped Sierra module is implemented in current direct backend lane |
| `corelib/src/fixed_size_array.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/fmt.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/gas.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/hash.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/integer.cairo` | `partial` | `int/mod` | mapped Sierra module is fail-fast bounded in current direct backend lane |
| `corelib/src/internal.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/internal/bounded_int.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/internal/num.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/iter.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/iter/adapters.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/iter/adapters/chain.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/iter/adapters/enumerate.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/iter/adapters/filter.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/iter/adapters/map.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/iter/adapters/peekable.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/iter/adapters/take.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/iter/adapters/zip.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/iter/traits.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/iter/traits/accum.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/iter/traits/collect.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/iter/traits/iterator.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/keccak.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/keyword_docs.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/lib.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/math.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/metaprogramming.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/nullable.cairo` | `excluded` | `nullable` | mapped Sierra module status is 'unresolved' (not yet in supported/partial lane) |
| `corelib/src/num.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/num/traits.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/num/traits/bit_size.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/num/traits/bounded.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/num/traits/one.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/num/traits/ops.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/num/traits/ops/checked.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/num/traits/ops/divrem.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/num/traits/ops/overflowing.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/num/traits/ops/pow.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/num/traits/ops/saturating.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/num/traits/ops/split.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/num/traits/ops/sqrt.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/num/traits/ops/widemul.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/num/traits/ops/widesquare.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/num/traits/ops/wrapping.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/num/traits/zero.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/ops.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/ops/arith.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/ops/deref.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/ops/function.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/ops/get.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/ops/index.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/ops/range.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/option.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/panics.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/pedersen.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/poseidon.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/prelude.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/prelude/v2023_01.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/prelude/' |
| `corelib/src/prelude/v2023_10.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/prelude/' |
| `corelib/src/prelude/v2024_07.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/prelude/' |
| `corelib/src/qm31.cairo` | `excluded` | `qm31` | mapped Sierra module status is 'unresolved' (not yet in supported/partial lane) |
| `corelib/src/result.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/serde.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/sha256.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/starknet.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/starknet/account.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/starknet/' |
| `corelib/src/starknet/class_hash.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/starknet/' |
| `corelib/src/starknet/contract_address.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/starknet/' |
| `corelib/src/starknet/deployment.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/starknet/' |
| `corelib/src/starknet/eth_address.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/starknet/' |
| `corelib/src/starknet/eth_signature.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/starknet/' |
| `corelib/src/starknet/event.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/starknet/' |
| `corelib/src/starknet/info.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/starknet/' |
| `corelib/src/starknet/secp256_trait.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/starknet/' |
| `corelib/src/starknet/secp256k1.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/starknet/' |
| `corelib/src/starknet/secp256r1.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/starknet/' |
| `corelib/src/starknet/storage.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/starknet/' |
| `corelib/src/starknet/storage/map.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/starknet/' |
| `corelib/src/starknet/storage/storage_base.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/starknet/' |
| `corelib/src/starknet/storage/storage_node.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/starknet/' |
| `corelib/src/starknet/storage/sub_pointers.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/starknet/' |
| `corelib/src/starknet/storage/vec.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/starknet/' |
| `corelib/src/starknet/storage_access.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/starknet/' |
| `corelib/src/starknet/syscalls.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/starknet/' |
| `corelib/src/starknet/testing.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/starknet/' |
| `corelib/src/string.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/test.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/test/array_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/bool_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/box_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/byte_array_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/bytes31_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/circuit_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/clone_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/cmp_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/coupon_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/deref_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/dict_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/ec_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/felt_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/fmt_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/gas_reserve_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/hash_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/integer_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/iter_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/keccak_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/language_features/block_level_items_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/language_features/box_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/language_features/closure_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/language_features/const_folding_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/language_features/const_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/language_features/early_return_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/language_features/for_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/language_features/glob_use_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/language_features/macro_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/language_features/match_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/language_features/other_paths/a.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/language_features/other_paths/b.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/language_features/other_paths/c.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/language_features/other_paths/define_c.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/language_features/other_paths/inner/a.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/language_features/other_paths/inner/b.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/language_features/panics_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/language_features/path_attr_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/language_features/trait_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/language_features/while_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/let_else_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/math_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/nullable_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/num_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/option_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/plugins_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/print_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/qm31_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/range_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/result_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/secp256k1_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/secp256r1_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/sha256_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/test_utils.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/testing_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/test/to_byte_array_test.cairo` | `excluded` | `-` | excluded by scope prefix 'corelib/src/test/' |
| `corelib/src/testing.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/to_byte_array.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/traits.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/tuple.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
| `corelib/src/zeroable.cairo` | `excluded` | `-` | no direct Sierra module mapping in current parity rules |
