# 10. Risk Register And Mitigations

## R1: Surface Drift And Incomplete Coverage Tracking

Risk:
- upstream surface changes or extraction gaps cause silent incompatibility

Mitigation:
1. generated inventory snapshots and drift gates
2. pin migration checklist
3. coverage reports from generated data only

## R2: Unsound Resource Handling (Range-Check/Gas/AP)

Risk:
- semantics mismatch when resource-sensitive families are lowered

Mitigation:
1. explicit resource tokens in MIR state
2. fail-fast until resource model exists
3. dedicated resource-sensitive differential tests

## R3: Proof Debt Accumulation

Risk:
- implementation outruns formal guarantees

Mitigation:
1. proof debt registry with owner/deadline
2. CI check on missing proof stubs for new passes/families
3. release blocked on high-severity proof debt

## R4: Performance Regressions Hidden By Sparse Benchmarks

Risk:
- optimizations regress real workloads despite synthetic gains

Mitigation:
1. benchmark suite diversification by family
2. percentile-based gates, not single-score gates only
3. mandatory before/after artifact reports

## R5: Backend Divergence (Sierra vs Cairo)

Risk:
- Lean -> Cairo and Lean -> Sierra behave differently on edge cases

Mitigation:
1. differential testing across backends
2. shared MIR as single semantic source
3. backend-specific feature gating and explicit divergence docs

## R6: Over-Coupling To Contract Concerns

Risk:
- contract-specific requirements block function-core progress

Mitigation:
1. keep function-domain milestones independent
2. isolate contract adapter layer
3. separate CI lanes for function core vs contract wrappers

## R7: Over-Engineering Without Delivery

Risk:
- too much framework work before feature closure

Mitigation:
1. milestone exit criteria are implementation + tests + proof increments
2. no milestone completion without measurable coverage increase
3. monthly burn-down of remaining unsupported families

