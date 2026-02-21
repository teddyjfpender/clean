# 22. Benchmarking, Cost Model, And Profiling Governance

## Objective

Establish a rigorous benchmarking and profiling governance layer that supports optimization decisions with reproducible evidence and prevents performance regressions during subset expansion.

## Scope

1. standardized benchmark manifests and runners
2. gas/steps/profile artifact generation
3. cost-model calibration workflows
4. family-level regression thresholds and release reporting

## Measurement Principles

1. same-signature, semantically equivalent comparisons only
2. deterministic toolchain and input vectors
3. artifact-backed claims (logs + profile outputs)
4. per-family interpretation, not only aggregate metrics

## Metric Set

1. Sierra gas
2. L2 gas (where applicable)
3. Cairo steps and builtin usage
4. call-graph hotspot profiles
5. compiled artifact size/shape metadata as secondary signals

## Cost Model Program

1. define candidate feature vector from Sierra/CASM metadata and runtime traces
2. calibrate model on corpus benchmark dataset
3. version calibration artifacts and validate drift

## Delivery Phases

### Phase BEN0: Benchmark schema and runner normalization

1. benchmark manifest schema for all corpus items
2. stable runners for gas and steps
3. deterministic parsing and summary artifacts

### Phase BEN1: Profiling pipeline standardization

1. standardized profile generation commands and output naming
2. baseline/generated profile pair generation
3. hotspot summary extraction and diff reports

### Phase BEN2: Cost model calibration bootstrap

1. initial model and calibration dataset
2. reproducibility checks for calibration outputs
3. mismatch diagnostics for model prediction vs measured ranking

### Phase BEN3: Family threshold gate hardening

1. per-family non-regression policies
2. percentile/outlier protection gates
3. strict failure behavior in CI for regressions

### Phase BEN4: Release benchmark dossier automation

1. aggregate release benchmark summary
2. per-family delta tables and hotspot evidence
3. tie reports to capability and milestone promotions

## Required Gates

1. optimizer non-regression checks
2. family threshold checks
3. profile artifact generation checks
4. release benchmark report freshness checks

## Acceptance Criteria

1. Performance claims are benchmark-backed and reproducible.
2. Cost model changes are calibrated and evidence-linked.
3. Family regressions are caught deterministically in CI.
4. Benchmark reports are release-grade and auditable.
