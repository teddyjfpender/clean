# 08. Quality Gates, Benchmarks, And Release Rules

## Gate Categories

1. Static hygiene gates
- pedantic linting and strict script checks
2. Build gates
- Lean build closure for all modules
- toolchain helper build closure
3. Determinism gates
- codegen snapshots
- generated inventory snapshots
4. Semantic gates
- unit, regression, and differential tests
- fail-fast behavior assertions
5. Artifact gates
- ProgramRegistry validation
- Sierra -> CASM compilation
6. Performance gates
- optimizer non-regression and workload benchmarks
7. Proof gates
- theorem compilation and required proof stub checks

## Test Taxonomy

1. Constructor-level tests for each IR node family.
2. Feature-level tests for each Sierra/corelib family.
3. End-to-end function corpus tests.
4. Cross-backend differential tests.
5. Failure-mode tests for unsupported/incomplete families.

## Determinism Requirements

1. fixed upstream pin and toolchain versions.
2. stable file ordering in all generators.
3. reproducible benchmark seeds and configuration.

## CI Matrix

1. fast lane:
- lint + build + targeted regression tests
2. full lane:
- full differential suite + all snapshots + e2e Sierra/CASM + benchmark gates
3. release lane:
- full lane + proof closure report + compatibility coverage reports

## Release Artifacts

1. compatibility report:
- Sierra family coverage
- corelib parity coverage
2. proof report:
- implemented theorems
- open proof debt with owners and deadlines
3. benchmark report:
- baseline vs optimized metrics by family

## Definition Of Release Candidate

A commit is release-candidate eligible only when:

1. all full-lane CI checks pass
2. no unapproved proof debt on changed families
3. no benchmark regressions beyond threshold
4. generated inventories and coverage reports are up to date

