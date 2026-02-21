#!/usr/bin/env python3
"""Generate deterministic differential harness artifacts from examples manifest."""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path
from typing import Dict, List


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate manifest differential harness")
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--out-script", required=True)
    parser.add_argument("--out-json", required=True)
    return parser.parse_args()


def validate_manifest(root: Path, manifest: Path) -> None:
    validator = root / "scripts" / "examples" / "validate_examples_manifest.py"
    subprocess.run(
        ["python3", str(validator), "--manifest", str(manifest)],
        check=True,
        cwd=root,
    )


def load_composite_cases(manifest: Path) -> List[Dict[str, object]]:
    payload = json.loads(manifest.read_text(encoding="utf-8"))
    examples = payload.get("examples", [])
    if not isinstance(examples, list):
        raise ValueError(f"invalid examples list in manifest: {manifest}")

    cases: List[Dict[str, object]] = []
    for entry in examples:
        if not isinstance(entry, dict):
            continue
        example_id = str(entry.get("id", "")).strip()
        differential = entry.get("differential", {})
        if not example_id or not isinstance(differential, dict):
            continue
        if differential.get("kind") != "composite":
            continue

        cases.append(
            {
                "id": example_id,
                "vector_profiles": list(differential.get("vector_profiles", [])),
                "replay_command": str(differential.get("replay_command", "")),
                "lean_test_file": str(differential.get("lean_test_file", "")),
                "backend_module": str(differential.get("backend_module", "")),
                "backend_contract": str(differential.get("backend_contract", "")),
            }
        )

    return sorted(cases, key=lambda row: str(row["id"]))


def render_script(cases: List[Dict[str, object]]) -> str:
    lines: List[str] = []
    lines.extend(
        [
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            "",
            "ROOT_DIR=\"$(cd \"$(dirname \"${BASH_SOURCE[0]}\")/../../..\" && pwd)\"",
            "export PATH=\"$HOME/.elan/bin:$PATH\"",
            "",
            "run_case() {",
            "  local case_id=\"$1\"",
            "  local lean_test_file=\"$2\"",
            "  local backend_module=\"$3\"",
            "  local backend_contract=\"$4\"",
            "  local replay_command=\"$5\"",
            "",
            "  echo \"running manifest differential case '$case_id'\"",
            "  if ! (",
            "    cd \"$ROOT_DIR\"",
            "    lake build LeanCairo.Compiler.Semantics.Eval",
            "    lake env lean \"$lean_test_file\"",
            "  ); then",
            "    echo \"manifest differential mismatch in evaluator lane for '$case_id'\"",
            "    echo \"replay: $replay_command\"",
            "    exit 1",
            "  fi",
            "",
            "  if ! \"$ROOT_DIR/scripts/test/run_backend_parity_case.sh\" \"$backend_module\" \"$backend_contract\" \"manifest differential $case_id\"; then",
            "    echo \"manifest differential mismatch in backend parity lane for '$case_id'\"",
            "    echo \"replay: $replay_command\"",
            "    exit 1",
            "  fi",
            "}",
            "",
        ]
    )

    for case in cases:
        lines.append(
            "run_case "
            f"\"{case['id']}\" "
            f"\"{case['lean_test_file']}\" "
            f"\"{case['backend_module']}\" "
            f"\"{case['backend_contract']}\" "
            f"\"{case['replay_command']}\""
        )

    lines.extend(["", "echo \"manifest differential checks passed\""])
    return "\n".join(lines) + "\n"


def main() -> int:
    args = parse_args()
    manifest = Path(args.manifest).resolve()
    out_script = Path(args.out_script).resolve()
    out_json = Path(args.out_json).resolve()
    root = Path(__file__).resolve().parents[2]

    if not manifest.is_file():
        raise SystemExit(f"missing manifest: {manifest}")

    validate_manifest(root, manifest)
    cases = load_composite_cases(manifest)
    payload = {
        "version": 1,
        "manifest": str(manifest.relative_to(root)),
        "cases": cases,
    }

    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    out_script.parent.mkdir(parents=True, exist_ok=True)
    out_script.write_text(render_script(cases), encoding="utf-8")
    out_script.chmod(0o755)

    print(f"wrote: {out_json}")
    print(f"wrote: {out_script}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
