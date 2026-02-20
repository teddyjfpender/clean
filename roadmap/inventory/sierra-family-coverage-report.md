# Sierra Family Coverage Report (Pinned)

- Commit: `e56055c87a9db4e3dbb91c82ccb2ea751a8dc617`
- Source matrix: `roadmap/inventory/sierra-coverage-matrix.json`
- Extension modules: `62`
- `implemented`: `4`
- `fail_fast`: `13`
- `unresolved`: `45`

## Family Status and Evidence

| Module | Status | Source file | Evidence refs |
| --- | --- | --- | --- |
| `ap_tracking` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/ap_tracking.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `array` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/array.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `bitwise` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/bitwise.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `blake` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/blake.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `boolean` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/boolean.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `bounded_int` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/bounded_int.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `boxing` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/boxing.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `branch_align` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/branch_align.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `bytes31` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/bytes31.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `casts` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/casts.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `circuit` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/circuit.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `const_type` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/const_type.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `consts` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/consts.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `coupon` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/coupon.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `debug` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/debug.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `drop` | `implemented` | `crates/cairo-lang-sierra/src/extensions/modules/drop.rs` | `src/LeanCairo/Backend/Sierra/Emit/SubsetProgram.lean`, `scripts/test/sierra_e2e.sh`, `scripts/test/sierra_scalar_e2e.sh` |
| `duplicate` | `implemented` | `crates/cairo-lang-sierra/src/extensions/modules/duplicate.rs` | `src/LeanCairo/Backend/Sierra/Emit/SubsetProgram.lean`, `scripts/test/sierra_e2e.sh`, `scripts/test/sierra_scalar_e2e.sh` |
| `ec` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/ec.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `enm` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/enm.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `felt252` | `implemented` | `crates/cairo-lang-sierra/src/extensions/modules/felt252.rs` | `src/LeanCairo/Backend/Sierra/Emit/SubsetProgram.lean`, `scripts/test/sierra_e2e.sh`, `scripts/test/sierra_scalar_e2e.sh` |
| `felt252_dict` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/felt252_dict.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `function_call` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/function_call.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `gas` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/gas.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `gas_reserve` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/gas_reserve.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `int/mod` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/int/mod.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `int/signed` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/int/signed.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `int/signed128` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/int/signed128.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `int/unsigned` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/int/unsigned.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `int/unsigned128` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/int/unsigned128.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `int/unsigned256` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/int/unsigned256.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `int/unsigned512` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/int/unsigned512.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `is_zero` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/is_zero.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `mem` | `implemented` | `crates/cairo-lang-sierra/src/extensions/modules/mem.rs` | `src/LeanCairo/Backend/Sierra/Emit/SubsetProgram.lean`, `scripts/test/sierra_e2e.sh`, `scripts/test/sierra_scalar_e2e.sh` |
| `mod` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/mod.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `non_zero` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/non_zero.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `nullable` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/nullable.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `pedersen` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/pedersen.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `poseidon` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/poseidon.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `qm31` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/qm31.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `range` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/range.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `range_check` | `fail_fast` | `crates/cairo-lang-sierra/src/extensions/modules/range_check.rs` | `scripts/test/sierra_failfast_unsupported.sh`, `scripts/roadmap/check_failfast_policy_lock.sh` |
| `segment_arena` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/segment_arena.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `snapshot` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/snapshot.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `span` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/span.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `squashed_felt252_dict` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/squashed_felt252_dict.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
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
| `trace` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/trace.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `try_from_felt252` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/try_from_felt252.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `unconditional_jump` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/unconditional_jump.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `uninitialized` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/uninitialized.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `unsafe_panic` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/unsafe_panic.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
| `utils` | `unresolved` | `crates/cairo-lang-sierra/src/extensions/modules/utils.rs` | `roadmap/05-track-a-lean-to-sierra-functions.md` |
