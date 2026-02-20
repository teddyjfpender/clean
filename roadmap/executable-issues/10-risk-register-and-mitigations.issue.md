# Executable Issue: `roadmap/10-risk-register-and-mitigations.md`

- Source roadmap file: [`roadmap/10-risk-register-and-mitigations.md`](../10-risk-register-and-mitigations.md)
- Issue class: Risk control and escalation
- Priority: P0
- Overall status: NOT DONE

## Objective

Operationalize risk controls so critical failure modes are detected early and gated.

## Implementation loci

1. `roadmap/10-risk-register-and-mitigations.md`
2. `scripts/roadmap/check_risk_controls.sh` (new)
3. `scripts/workflow/run-mvp-checks.sh`
4. `scripts/workflow/run-sierra-checks.sh`

## Formal method requirements

1. Every risk must map to concrete preventive/detective controls.
2. Controls must be executable checks when feasible.
3. Unmitigated high-risk items block release-candidate status.

## Milestones

### R1 Risk-to-control mapping file
- Status: DONE - 1607761
- Acceptance tests:
1. `scripts/roadmap/check_risk_controls.sh --validate-mapping` exits `0` only when every risk ID has at least one control.

### R2 Control implementation coverage
- Status: DONE - 1607761
- Acceptance tests:
1. Missing mandatory control script causes checker failure.
2. Checker output lists unresolved controls by risk ID.

### R3 Release risk gate
- Status: DONE - 1607761
- Acceptance tests:
1. `scripts/workflow/run-release-candidate-checks.sh` fails when unresolved high-risk items remain.
2. Gate passes only when risk controls are active and green.

## Completion criteria

1. Risk register is linked to executable controls.
2. Risk status is included in release reports.
3. High-risk unresolved items block release.
