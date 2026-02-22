# Benchmark: sq128x128_u128 (Function-Only)

This benchmark compares Lean-generated SQ128 lanes against wrappers over freshly pulled
upstream SQ128 sources from:

- https://github.com/teddyjfpender/the-situation/tree/main/contracts/src/types/sq128

Compared lanes:
- `sq128x128_add_raw`
- `sq128x128_sub_raw`
- `sq128x128_mul_raw`
- `sq128x128_delta_raw`
- `sq128x128_affine_kernel`
- `sq128x128_add_raw_u8`
- `sq128x128_sub_raw_u8`
- `sq128x128_mul_raw_u8`
- `sq128x128_delta_raw_u8`
- `sq128x128_affine_kernel_u8`
- `sq128x128_add_raw_u16`
- `sq128x128_sub_raw_u16`
- `sq128x128_mul_raw_u16`
- `sq128x128_delta_raw_u16`
- `sq128x128_affine_kernel_u16`
- `sq128x128_add_raw_u32`
- `sq128x128_sub_raw_u32`
- `sq128x128_mul_raw_u32`
- `sq128x128_delta_raw_u32`
- `sq128x128_affine_kernel_u32`
- `sq128x128_add_raw_u64`
- `sq128x128_sub_raw_u64`
- `sq128x128_mul_raw_u64`
- `sq128x128_delta_raw_u64`
- `sq128x128_affine_kernel_u64`

Pipeline (`run_gas_comparison.sh`):
1. Pull latest upstream SQ128 files from `main` via `gh`.
2. Sync benchmark sources:
   - copy upstream `common.cairo`, `sq128.cairo`, and `sq128/*` directly into this package.
   - extract generated functions from `examples/Cairo/sq128x128_u128/src/lib.cairo`.
3. Run `snforge` gas tests and compare baseline vs generated per lane.
   - Emit lane-level CSV rows for local analysis.
   - Emit aggregate `key=value` totals (`baseline/generated` Sierra + L2 and improvement %) for the manifest benchmark harness contract.

Run:

```bash
cd examples/Benchmark/sq128x128_u128
./scripts/run_gas_comparison.sh
```

Offline mode (skip `gh` pull):

```bash
cd examples/Benchmark/sq128x128_u128
SQ128_SKIP_UPSTREAM_PULL=1 ./scripts/run_gas_comparison.sh
```

## Latest Snapshot

From the current harness (`./scripts/run_gas_comparison.sh`):

| Lane | Baseline gas | Generated gas | Improvement |
|---|---:|---:|---:|
| `add_case` | 158,066,266 | 15,048,630 | 90.48% |
| `sub_case` | 161,752,666 | 15,048,630 | 90.70% |
| `mul_case` | 753,903,194 | 26,353,590 | 96.50% |
| `delta_case` | 161,752,666 | 15,048,630 | 90.70% |
| `affine_case` | 1,183,401,672 | 32,128,950 | 97.29% |

## Technical Interpretation

### 1) Equivalence: is generated truly equivalent to baseline?

Current status:

- Yes for the tested benchmark vectors and accumulators (`test_equivalence_vectors` and the lane gas tests).
- Not yet a full formal equivalence proof across the entire SQ128 domain.

What is currently checked:

- Point-wise equality on fixed input vectors for `add/sub/mul/delta/affine`.
- Deterministic loop accumulators over 4096 rounds.

Important scope limit:

- The generated path is a typed `u128` arithmetic lane (typed-int expressions lowered to `u128` Cairo primitives).
- The baseline path is full upstream SQ128 machinery, then projected back to integer form.
- So equivalence here is scoped to the benchmark input domain (non-negative integer-like values and non-overflowing arithmetic in the chosen vectors), not all signed/fractional SQ128 behavior.

### 2) Why there is a difference

The generated implementation is lower-level and narrower:

- It executes direct `u128` expressions from generated Cairo (`+`, `-`, `*`) with minimal call depth.
- It does not materialize full SQ128 signed fixed-point structures for each operation in this benchmark lane.

The baseline implementation is broader and more defensive:

- It converts `u128 -> SQ128x128` and then runs through upstream Option-first arithmetic APIs and helpers.
- It carries generalized fixed-point representation concerns (sign, limb layout, rounding-capable arithmetic paths, validation boundaries).
- It converts back using `to_raw` and asserts integer-form invariants (`neg == false`, fractional limbs zero).

This is expected software-engineering tradeoff:

- Generated lane: specialized fast path for the constrained domain.
- Baseline lane: generalized reusable library path with stronger abstraction and safety contracts.

### 3) Why baseline has so many additional steps

The baseline incurs systematic overhead per call:

- Representation overhead: repeated construction/deconstruction of `SQ128x128`.
- Indirection overhead: wrapper -> upstream API -> internal helpers.
- Validation/branch overhead: Option-first flow and `_unchecked` expectations.
- Arithmetic width overhead: internal multi-limb (`U256`/`I256`/`U512`) style operations rather than single-lane raw arithmetic.

`mul_case` and `affine_case` amplify this most because multiplication in the upstream SQ128 path is significantly heavier than plain raw `u128` multiply, and `affine` composes multiple ops.

## Bottom Line

These benchmark deltas are real for this scoped workload, but they compare:

- specialized generated integer-lane arithmetic
- against generalized upstream SQ128 arithmetic infrastructure.

For broader claims, add domain-wide differential/property tests and (eventually) formal pass-level equivalence for the covered subset.
