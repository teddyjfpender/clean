# Executable Issue: `roadmap/09-milestones-and-execution-order.md`

- Source roadmap file: [`roadmap/09-milestones-and-execution-order.md`](../09-milestones-and-execution-order.md)
- Issue class: Program scheduling and dependency control
- Priority: P0
- Overall status: NOT DONE

## Objective

Run milestone delivery in dependency order and prevent out-of-order completion claims.

## Implementation loci

1. `roadmap/09-milestones-and-execution-order.md`
2. `roadmap/executable-issues/*.issue.md`
3. `scripts/roadmap/check_milestone_dependencies.py` (new)
4. `scripts/roadmap/report_issue_progress.sh` (new)

## Formal method requirements

1. Milestone DAG must be explicit and acyclic.
2. A milestone cannot be marked done if any dependency milestone is not done.
3. Completion states must be script-checkable.

## Milestones

### X1 Dependency graph encoding
- Status: NOT DONE
- Acceptance tests:
1. `scripts/roadmap/check_milestone_dependencies.py --validate-dag` exits `0`.
2. Introducing a cycle causes non-zero exit.

### X2 Dependency-aware status checker
- Status: NOT DONE
- Acceptance tests:
1. Marking child `DONE - <commit>` while parent `NOT DONE` fails checker.
2. Valid topological completion passes checker.

### X3 Progress reporting
- Status: NOT DONE
- Acceptance tests:
1. Progress report includes totals by milestone and track.
2. Report is deterministic and diff-stable.

## Completion criteria

1. Milestone ordering is enforced by tooling.
2. Status changes are dependency-checked in CI.
3. Progress reporting is automated.

