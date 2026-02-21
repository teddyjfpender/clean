#!/usr/bin/env python3
"""Generate deterministic quality-gate manifest from core policy + capability obligations."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict, List, Set

CORE_GATES: List[str] = [
    "scripts/lint/pedantic.sh",
    "scripts/roadmap/check_issue_statuses.sh",
    "scripts/roadmap/check_issue_dependencies.sh",
    "scripts/roadmap/check_milestone_dependencies.py",
    "scripts/roadmap/check_issue_evidence.sh",
    "scripts/roadmap/check_pin_consistency.sh",
    "scripts/roadmap/check_inventory_reproducibility.sh",
    "scripts/roadmap/check_inventory_freshness.sh",
    "scripts/roadmap/check_gate_manifest_sync.sh",
    "scripts/roadmap/check_gate_sharding_pipeline.sh",
    "scripts/roadmap/check_capability_registry.sh",
    "scripts/roadmap/check_capability_obligations.sh",
    "scripts/roadmap/check_capability_projection_usage.sh",
    "scripts/roadmap/check_capability_closure_slo.sh",
    "scripts/roadmap/check_mir_family_contract.sh",
    "scripts/roadmap/check_lowering_scaffold_sync.sh",
    "scripts/roadmap/check_examples_manifest_schema.sh",
    "scripts/roadmap/check_baseline_provenance.sh",
    "scripts/roadmap/check_differential_harness_sync.sh",
    "scripts/roadmap/check_benchmark_harness_sync.sh",
    "scripts/roadmap/check_corpus_coverage_report_sync.sh",
    "scripts/roadmap/check_corpus_coverage_trend_sync.sh",
    "scripts/roadmap/check_profile_artifacts_freshness.sh",
    "scripts/roadmap/check_cost_model_calibration_freshness.sh",
    "scripts/roadmap/check_corelib_parity_freshness.sh",
    "scripts/roadmap/check_corelib_parity_trend.sh",
    "scripts/roadmap/check_optimization_closure_report.sh",
    "scripts/roadmap/check_completion_matrix.sh",
    "scripts/roadmap/check_crate_dependency_matrix_freshness.sh",
    "scripts/roadmap/check_coverage_matrix_freshness.sh",
    "scripts/roadmap/check_sierra_coverage_report_freshness.sh",
    "scripts/roadmap/check_subset_ledger_sync.py",
    "scripts/roadmap/check_risk_controls.sh",
    "scripts/roadmap/check_effect_metadata.sh",
    "scripts/roadmap/check_proof_debt_policy.sh",
    "scripts/roadmap/check_release_go_no_go.sh",
    "scripts/roadmap/check_release_reports_freshness.sh",
    "scripts/test/gate_manifest_reproducibility.sh",
    "scripts/test/gate_manifest_negative.sh",
    "scripts/test/gate_sharding_reproducibility.sh",
    "scripts/test/gate_shard_aggregation_reproducibility.sh",
    "scripts/test/gate_retry_determinism.sh",
    "scripts/test/sierra_e2e.sh",
    "scripts/test/sierra_scalar_e2e.sh",
    "scripts/test/sierra_u128_range_checked_e2e.sh",
    "scripts/test/sierra_advanced_family_e2e.sh",
    "scripts/test/sierra_structural_optimization_e2e.sh",
    "scripts/test/sierra_structural_optimization_reproducibility.sh",
    "scripts/test/sierra_differential.sh",
    "scripts/test/sierra_u128_wrapping_differential.sh",
    "scripts/test/sierra_review_lift_complex.sh",
    "scripts/test/backend_parity.sh",
    "scripts/test/eval_conversion_legality.sh",
    "scripts/test/eval_aggregate_wrapper_semantics.sh",
    "scripts/test/control_flow_normalization_regression.sh",
    "scripts/test/call_panic_semantics_regression.sh",
    "scripts/test/optimizer_pass_regression.sh",
    "scripts/test/optimizer_contracts_regression.sh",
    "scripts/test/capability_registry_negative.sh",
    "scripts/test/effect_metadata_negative.sh",
    "scripts/test/proof_debt_policy_negative.sh",
    "scripts/test/release_go_no_go_negative.sh",
    "scripts/test/capability_obligations_reproducibility.sh",
    "scripts/test/capability_obligations_negative.sh",
    "scripts/test/capability_closure_slo_negative.sh",
    "scripts/test/mir_family_contract_negative.sh",
    "scripts/test/lowering_scaffold_reproducibility.sh",
    "scripts/test/lowering_scaffold_sync_negative.sh",
    "scripts/examples/generate_examples.sh",
    "scripts/test/examples_structure.sh",
    "scripts/test/baseline_sync_reproducibility.sh",
    "scripts/test/baseline_provenance_negative.sh",
    "scripts/test/examples_manifest_mirror_negative.sh",
    "scripts/test/examples_regeneration_deterministic.sh",
    "scripts/test/differential_harness_reproducibility.sh",
    "scripts/test/examples_differential_vectors_negative.sh",
    "scripts/test/benchmark_harness_reproducibility.sh",
    "scripts/test/benchmark_family_thresholds_negative.sh",
    "scripts/test/profile_artifacts_reproducibility.sh",
    "scripts/test/profile_artifacts_negative.sh",
    "scripts/test/cost_model_calibration_reproducibility.sh",
    "scripts/test/cost_model_calibration_negative.sh",
    "scripts/test/corpus_coverage_reproducibility.sh",
    "scripts/test/corpus_coverage_trend_reproducibility.sh",
    "scripts/test/corpus_coverage_negative.sh",
    "scripts/bench/generated/run_manifest_benchmarks.sh",
    "scripts/test/sierra_failfast_unsupported.sh",
    "scripts/bench/check_optimizer_non_regression.sh",
    "scripts/bench/check_optimizer_family_thresholds.sh",
]

WORKFLOWS = [
    "scripts/workflow/run-sierra-checks.sh",
    "scripts/workflow/run-mvp-checks.sh",
    "scripts/workflow/run-release-candidate-checks.sh",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate quality gate manifest")
    parser.add_argument(
        "--obligations",
        default="roadmap/capabilities/obligations.json",
        help="Path to capability obligations JSON",
    )
    parser.add_argument(
        "--out",
        default="config/gate-manifest.json",
        help="Output manifest path",
    )
    return parser.parse_args()


def load_json(path: Path) -> Dict[str, object]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path}: top-level JSON must be object")
    return payload


def dedupe_preserving(values: List[str]) -> List[str]:
    out: List[str] = []
    seen: Set[str] = set()
    for value in values:
        if value in seen:
            continue
        seen.add(value)
        out.append(value)
    return out


def collect_obligation_derived_gates(obligations_payload: Dict[str, object]) -> List[str]:
    entries = obligations_payload.get("obligations", [])
    if not isinstance(entries, list):
        raise ValueError("obligations payload must contain list field 'obligations'")

    refs: Set[str] = set()
    for idx, entry in enumerate(entries):
        if not isinstance(entry, dict):
            raise ValueError(f"obligations[{idx}] must be object")
        for key in ("test_refs", "benchmark_refs"):
            raw = entry.get(key, [])
            if not isinstance(raw, list):
                raise ValueError(f"obligations[{idx}].{key} must be list")
            for ref in raw:
                if not isinstance(ref, str) or not ref.strip():
                    raise ValueError(f"obligations[{idx}].{key} entries must be non-empty strings")
                refs.add(ref.strip())

    return sorted(refs)


def main() -> int:
    args = parse_args()
    root = Path(__file__).resolve().parents[2]
    obligations_path = (root / args.obligations).resolve()
    out_path = (root / args.out).resolve()

    obligations_payload = load_json(obligations_path)
    derived_gates = collect_obligation_derived_gates(obligations_payload)

    mandatory = dedupe_preserving(CORE_GATES + derived_gates)

    payload = {
        "version": 1,
        "workflows": WORKFLOWS,
        "core_gates": CORE_GATES,
        "obligation_derived_gates": derived_gates,
        "mandatory_gates": mandatory,
        "sources": {
            "obligations": str(obligations_path.relative_to(root)),
        },
    }

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"wrote: {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
