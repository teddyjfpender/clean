#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="$HOME/.elan/bin:$PATH"

"$ROOT_DIR/scripts/roadmap/list_quality_gates.sh" --validate-workflows
"$ROOT_DIR/scripts/workflow/run-mvp-checks.sh"
"$ROOT_DIR/scripts/roadmap/check_risk_controls.sh" --validate-mapping
"$ROOT_DIR/scripts/roadmap/generate_release_reports.py"
"$ROOT_DIR/scripts/roadmap/check_release_reports_freshness.sh"
"$ROOT_DIR/scripts/roadmap/check_risk_controls.sh" --run-controls --fail-on-high-risk

echo "all release-candidate checks passed"
