#!/usr/bin/env python3
"""Generate the canonical SPHINX numerical-core integrity manifest."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CORE_GLOBS = (
    "matlabSolver/*.m",
    "python/src/sphinx_solver/model.py",
    "python/src/sphinx_solver/operators.py",
    "python/src/sphinx_solver/ordering.py",
    "python/src/sphinx_solver/solver.py",
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--release", default="development")
    parser.add_argument("--output", type=Path, default=ROOT / "SPHINX_CORE_MANIFEST.json")
    args = parser.parse_args()

    files = sorted({path for pattern in CORE_GLOBS for path in ROOT.glob(pattern)})
    payload = {
        "schemaVersion": 1,
        "product": "SPHINX",
        "release": args.release,
        "classification": "SPHINX-CERTIFIED",
        "coreFiles": [
            {"path": path.relative_to(ROOT).as_posix(), "sha256": sha256(path)}
            for path in files
        ],
    }
    args.output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(args.output)


if __name__ == "__main__":
    main()
