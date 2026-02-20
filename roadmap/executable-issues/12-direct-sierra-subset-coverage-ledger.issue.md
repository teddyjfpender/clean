# Executable Issue: `roadmap/12-direct-sierra-subset-coverage-ledger.md`

- Source roadmap file: [`roadmap/12-direct-sierra-subset-coverage-ledger.md`](../12-direct-sierra-subset-coverage-ledger.md)
- Issue class: Subset tracking and evidence discipline
- Priority: P0
- Overall status: DONE - 00057f5
- Completion evidence tests: `scripts/workflow/run-sierra-checks.sh`; `scripts/workflow/run-mvp-checks.sh`; `scripts/roadmap/check_issue_statuses.sh`; `scripts/roadmap/check_issue_evidence.sh`; `scripts/roadmap/check_subset_ledger_sync.py`
- Completion evidence proofs: `roadmap/12-direct-sierra-subset-coverage-ledger.md`; `roadmap/05-track-a-lean-to-sierra-functions.md`; `src/LeanCairo/Backend/Sierra/Emit/SubsetProgram.lean`

## Objective

Maintain a strict, auditable ledger of direct Sierra subset coverage with completed and pending items, each tied to acceptance gates and commit evidence.

## Implementation loci

1. `roadmap/12-direct-sierra-subset-coverage-ledger.md`
2. `roadmap/05-track-a-lean-to-sierra-functions.md`
3. `roadmap/executable-issues/05-track-a-lean-to-sierra-functions.issue.md`
4. `roadmap/executable-issues/INDEX.md`
5. `src/LeanCairo/Backend/Sierra/Emit/SubsetProgram.lean`

## Formal method requirements

1. Status labels must be explicit and canonical (`NOT DONE` or `DONE - <commit>`).
2. Promotion to `DONE` requires linked evidence for validation and compilation gates.
3. Pending scope must stay fail-fast in implementation until promoted.

## Milestone status ledger

### DSR-1 Create dedicated subset coverage ledger
- Status: DONE - a6374f8
- Acceptance tests:
1. Ledger file exists with completed and pending subset sections.
2. Ledger status lines use strict status format.
3. Scope and synchronization rules are explicit.

### DSR-2 Keep subset and Track-A statuses synchronized
- Status: DONE - 00057f5
- Acceptance tests:
1. Subset status updates and Track-A milestone updates land in the same commit.
2. Status drift between subset ledger and Track-A issue file is rejected in review.

### DSR-3 Add closure metric for subset progression
- Status: DONE - 00057f5
- Acceptance tests:
1. Ledger includes measurable closure progress toward non-Starknet family completion.
2. Progress references the pinned inventory outputs under `roadmap/inventory`.
