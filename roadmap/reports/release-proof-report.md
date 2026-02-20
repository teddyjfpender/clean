# Release Proof Report

- Commit: `e56055c87a9db4e3dbb91c82ccb2ea751a8dc617`
- Required theorem source: `scripts/roadmap/check_proof_obligations.sh`
- Required theorem count: `12`
- Missing required theorems: `0`
- Placeholder count (`sorry`/`admit`): `0`
- Open high-severity proof debt items: `0`

## Required Theorem Presence

| Theorem | Occurrences |
| --- | ---: |
| `optimizeExprSound` | `1` |
| `cseLetNormExprSound` | `1` |
| `optimizeExprPipelineSound` | `1` |
| `sourceMIRRoundTrip_holds` | `1` |
| `mirSourceRoundTrip_holds` | `1` |
| `readVar_bindVar_type_non_interference` | `1` |
| `readStorage_bindStorage_type_non_interference` | `1` |
| `readVarStrict_unsupported_failfast` | `1` |
| `evalExprState_success_transition` | `1` |
| `evalExprState_failure_channel` | `1` |
| `evalExprStateStrict_success_transition` | `1` |
| `evalExprStateStrict_failure_channel` | `1` |

## Open High-Severity Proof Debt

- none
