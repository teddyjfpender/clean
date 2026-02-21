# Capability Registry Schema v1

Top-level object:

1. `version`: integer (must be `1`)
2. `capabilities`: non-empty array of capability objects

Capability object required keys:

1. `capability_id`: string, unique, pattern `cap.[a-z0-9_.-]+`
2. `family_group`: one of:
- `scalar`
- `integer`
- `field`
- `aggregate`
- `collection`
- `control`
- `resource`
- `crypto`
- `circuit`
- `runtime`
3. `mir_nodes`: non-empty array of unique strings
4. `sierra_targets`: object with:
- `generic_type_ids`: array of strings (possibly empty)
- `generic_libfunc_ids`: array of strings (possibly empty)
5. `cairo_targets`: object with:
- `forms`: non-empty array of strings
6. `resource_requirements`: array of strings (possibly empty)
7. `semantic_class`: one of `pure`, `effectful`, `partial`
8. `support_state`: object with keys `sierra`, `cairo`, `overall`, each one of:
- `planned`
- `fail_fast`
- `implemented`
9. `proof_class`: non-empty string
10. `proof_status`: one of `planned`, `partial`, `complete`
11. `test_class`: non-empty string
12. `benchmark_class`: non-empty string
13. `divergence_constraints`: optional array of non-empty strings
   Required (non-empty) when `support_state.sierra != support_state.cairo`.

Transition legality (old -> new):

1. `planned -> planned|fail_fast|implemented`
2. `fail_fast -> fail_fast|implemented`
3. `implemented -> implemented`

Additional invariants:

1. `overall` state must be <= backend state closure:
- if `overall == implemented`, both backend states must be `implemented`.
- if one backend state is `planned`, `overall` cannot be `implemented`.
2. `mir_nodes` entries are unique per capability.
3. capability IDs are globally unique in registry.
4. Backend divergence (`sierra != cairo`) must include explicit `divergence_constraints`.
