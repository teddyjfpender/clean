# Executable Issue: `roadmap/README.md`

- Source roadmap file: [`roadmap/README.md`](../README.md)
- Issue class: Program orchestration
- Priority: P0
- Overall status: NOT DONE

## Objective

Execute the complete roadmap as an auditable program of work where every milestone item has explicit implementation scope, formal constraints, deterministic tests, and status tracking.

## Implementation loci

1. `roadmap/executable-issues/` (issue definitions and status ledger)
2. `scripts/workflow/` (gates and orchestration)
3. `scripts/test/` and `scripts/bench/` (verification + performance gates)
4. `src/LeanCairo/**` (compiler implementation)

## Formal execution rules

1. Every deliverable must map to one issue item with status `NOT DONE` or `DONE - <commit>`.
2. No item can move to `DONE - <commit>` without passing its acceptance tests.
3. Status format is strict and machine-parseable.
4. Every `DONE - <commit>` entry must reference a reachable git commit hash.

## Milestones

### M-README-1: Status governance and machine-readability
- Status: DONE - 7544a63
- Required work:
1. Add status parser script for `roadmap/executable-issues/**/*.issue.md`.
2. Reject invalid status tokens in CI.
- Acceptance tests:
1. `rg -n "Overall status: (NOT DONE|DONE - [0-9a-f]{7,40})" roadmap/executable-issues`
2. `scripts/roadmap/check_issue_statuses.sh` exits `0` only when all statuses are valid.

### M-README-2: End-to-end roadmap closure report
- Status: NOT DONE
- Required work:
1. Add generated closure report summarizing completed vs pending issues.
2. Add strict dependency ordering checks.
- Acceptance tests:
1. `scripts/roadmap/report_issue_progress.sh` emits deterministic markdown.
2. CI fails if a dependent issue is `NOT DONE` while parent is `DONE - <commit>`.

## Completion criteria

1. All roadmap issue files exist and are linked from `roadmap/README.md`.
2. Status and progress scripts are integrated into workflow CI.
3. No invalid status states are present.
