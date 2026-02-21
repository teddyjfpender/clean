# Executable Issue: `roadmap/16-capability-registry-schema-and-projection-system.md`

- Source roadmap file: [`roadmap/16-capability-registry-schema-and-projection-system.md`](../16-capability-registry-schema-and-projection-system.md)
- Issue class: Capability registry formalization
- Priority: P0
- Overall status: NOT DONE

## Objective

Implement a canonical capability registry and projection pipeline as the single support source of truth for function-domain expansion.

## Implementation loci

1. `roadmap/16-capability-registry-schema-and-projection-system.md`
2. `roadmap/inventory/sierra-coverage-matrix.json`
3. `roadmap/inventory/corelib-parity-report.json`
4. `scripts/roadmap/**`
5. `src/LeanCairo/Core/**`
6. `src/LeanCairo/Backend/**`

## Formal method requirements

1. Capability schema is machine-validated and versioned.
2. Status transition legality is enforced.
3. Registry projections are deterministic and drift-checked.
4. Backends rely on generated projections, not handwritten support maps.

## Milestone status ledger

### CREG-1 Registry schema and validator
- Status: DONE - ff05fdf
- Evidence tests: `python3 scripts/roadmap/validate_capability_registry.py --registry roadmap/capabilities/registry.json`; `scripts/test/capability_registry_negative.sh`; `scripts/roadmap/check_capability_registry.sh`
- Evidence proofs: `roadmap/capabilities/schema.md`; `roadmap/capabilities/registry.json`; `scripts/roadmap/validate_capability_registry.py`
- Acceptance tests:
1. Invalid capability entries fail schema validation.
2. Duplicate capability IDs are rejected.
3. Illegal status transitions fail validation.

### CREG-2 Projection generators and report sync
- Status: DONE - ff05fdf
- Evidence tests: `scripts/roadmap/check_capability_registry.sh`; `scripts/roadmap/list_quality_gates.sh --validate-workflows`; `scripts/roadmap/check_issue_evidence.sh`
- Evidence proofs: `scripts/roadmap/project_capability_reports.py`; `roadmap/inventory/capability-coverage-report.json`; `roadmap/inventory/capability-coverage-report.md`
- Acceptance tests:
1. Sierra and Cairo coverage reports generate deterministically from registry.
2. Drift between registry and generated reports fails checks.
3. Projection outputs are sorted and diff-stable.

### CREG-3 Backend scaffold/projection integration
- Status: NOT DONE
- Acceptance tests:
1. Backend support lookups consume generated projections.
2. Unregistered capabilities fail fast.
3. Handwritten duplicated support maps are detected by checks.

### CREG-4 Closure ratio and SLO gates
- Status: NOT DONE
- Acceptance tests:
1. Capability closure metrics generate from registry data.
2. Monotonicity checks fail on regression in implemented capability counts.
3. Release snapshots include capability closure artifacts.

## Global strict acceptance tests

1. `scripts/roadmap/check_inventory_reproducibility.sh`
2. `scripts/roadmap/check_inventory_freshness.sh`
3. `scripts/roadmap/check_sierra_coverage_report_freshness.sh`
4. `scripts/roadmap/check_corelib_parity_freshness.sh`

## Completion criteria

1. CREG-1 through CREG-4 are `DONE - <commit>`.
2. Capability registry is authoritative and enforced in CI.
3. Coverage and parity reports are projection-only artifacts.
