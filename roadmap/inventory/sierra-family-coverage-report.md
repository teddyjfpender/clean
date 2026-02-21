# Sierra Family Coverage Report (Pinned)

- Commit: `e56055c87a9db4e3dbb91c82ccb2ea751a8dc617`
- Source matrix: `roadmap/inventory/sierra-coverage-matrix.json`
- Extension modules: `62`
- `implemented`: `4`
- `fail_fast`: `48`
- `unresolved`: `10`

## Family Status and Evidence

| Module | Status | Source file | Evidence refs |
| --- | --- | --- | --- |
| `ap_tracking` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/ap_tracking.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `array` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/array.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `bitwise` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/bitwise.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `blake` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/blake.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `boolean` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/boolean.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `bounded_int` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/bounded_int.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `boxing` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/boxing.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `branch_align` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/branch_align.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `bytes31` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/bytes31.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `casts` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/casts.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `circuit` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/circuit.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `const_type` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/const_type.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `consts` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/consts.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `coupon` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/coupon.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `debug` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/debug.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `drop` | `implemented` | `crates/cairo-lang-sierra/src/extensions/modules/drop.rs` | `src/LeanCairo/Backend/Sierra/Emit/SubsetProgram.lean`, `scripts/test/sierra_e2e.sh`, `scripts/test/sierra_scalar_e2e.sh` |
| `duplicate` | `implemented` | `crates/cairo-lang-sierra/src/extensions/modules/duplicate.rs` | `src/LeanCairo/Backend/Sierra/Emit/SubsetProgram.lean`, `scripts/test/sierra_e2e.sh`, `scripts/test/sierra_scalar_e2e.sh` |
| `ec` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/ec.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `enm` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/enm.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `felt252` | `implemented` | `crates/cairo-lang-sierra/src/extensions/modules/felt252.rs` | `src/LeanCairo/Backend/Sierra/Emit/SubsetProgram.lean`, `scripts/test/sierra_e2e.sh`, `scripts/test/sierra_scalar_e2e.sh` |
| `felt252_dict` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/felt252_dict.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `function_call` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/function_call.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `gas` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/gas.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `gas_reserve` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/gas_reserve.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `int/mod` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/int/mod.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `int/signed` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/int/signed.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `int/signed128` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/int/signed128.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `int/unsigned` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/int/unsigned.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `int/unsigned128` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/int/unsigned128.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `int/unsigned256` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/int/unsigned256.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `int/unsigned512` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/int/unsigned512.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `is_zero` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/is_zero.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `mem` | `implemented` | `crates/cairo-lang-sierra/src/extensions/modules/mem.rs` | `src/LeanCairo/Backend/Sierra/Emit/SubsetProgram.lean`, `scripts/test/sierra_e2e.sh`, `scripts/test/sierra_scalar_e2e.sh` |
| `mod` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/mod.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `non_zero` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/non_zero.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `nullable` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/nullable.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `pedersen` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/pedersen.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `poseidon` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/poseidon.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `qm31` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/qm31.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `range` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/range.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `range_check` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/range_check.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `segment_arena` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/segment_arena.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `snapshot` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/snapshot.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `span` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/span.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `squashed_felt252_dict` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/squashed_felt252_dict.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `starknet/emit_event` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/starknet/emit_event.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `starknet/getter` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/starknet/getter.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `starknet/interoperability` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/starknet/interoperability.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `starknet/mod` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/starknet/mod.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `starknet/secp256` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/starknet/secp256.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `starknet/secp256k1` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/starknet/secp256k1.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `starknet/secp256r1` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/starknet/secp256r1.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `starknet/storage` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/starknet/storage.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `starknet/syscalls` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/starknet/syscalls.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `starknet/testing` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/starknet/testing.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `structure` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/structure.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `trace` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/trace.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `try_from_felt252` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/try_from_felt252.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `unconditional_jump` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/unconditional_jump.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `uninitialized` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/uninitialized.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `unsafe_panic` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/unsafe_panic.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `utils` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/utils.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
