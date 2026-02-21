#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT_FILE="$ROOT_DIR/roadmap/inventory/capability-coverage-report.json"
BASELINE_FILE="$ROOT_DIR/roadmap/capabilities/capability-closure-slo-baseline.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --report)
      REPORT_FILE="$2"
      shift 2
      ;;
    --baseline)
      BASELINE_FILE="$2"
      shift 2
      ;;
    *)
      echo "unknown argument: $1"
      exit 1
      ;;
  esac
done

python3 - "$REPORT_FILE" "$BASELINE_FILE" <<'PY'
import json
import sys
from pathlib import Path

report_path = Path(sys.argv[1])
baseline_path = Path(sys.argv[2])

if not report_path.is_file():
    print(f"missing capability coverage report: {report_path}")
    raise SystemExit(1)
if not baseline_path.is_file():
    print(f"missing capability closure baseline: {baseline_path}")
    raise SystemExit(1)

report = json.loads(report_path.read_text(encoding="utf-8"))
baseline = json.loads(baseline_path.read_text(encoding="utf-8"))

minimums = baseline.get("minimums")
if not isinstance(minimums, dict):
    print(f"invalid baseline minimums object: {baseline_path}")
    raise SystemExit(1)

report_overall = report.get("overall_status_counts", {})
report_sierra = report.get("sierra_status_counts", {})
report_cairo = report.get("cairo_status_counts", {})
report_families = report.get("families", {})

violations = []

checks = [
    ("overall implemented", int(report_overall.get("implemented", -1)), int(minimums.get("overall_implemented", -1))),
    ("sierra implemented", int(report_sierra.get("implemented", -1)), int(minimums.get("sierra_implemented", -1))),
    ("cairo implemented", int(report_cairo.get("implemented", -1)), int(minimums.get("cairo_implemented", -1))),
]
for label, current, required in checks:
    if current < required:
        violations.append(f"{label}: current={current} required_min={required}")

family_minimums = minimums.get("family_overall_implemented", {})
if not isinstance(family_minimums, dict):
    print(f"invalid family_overall_implemented object in baseline: {baseline_path}")
    raise SystemExit(1)

for family, required in sorted(family_minimums.items()):
    family_payload = report_families.get(family)
    if not isinstance(family_payload, dict):
        violations.append(f"family '{family}' missing from report")
        continue
    overall_payload = family_payload.get("overall", {})
    if not isinstance(overall_payload, dict):
        violations.append(f"family '{family}' missing overall counts")
        continue
    current = int(overall_payload.get("implemented", -1))
    if current < int(required):
        violations.append(
            f"family '{family}' overall implemented: current={current} required_min={required}"
        )

if violations:
    print("capability closure SLO regression detected:")
    for item in violations:
        print(f"- {item}")
    raise SystemExit(1)

print("capability closure SLO checks passed")
PY
