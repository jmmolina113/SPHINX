from __future__ import annotations

import hashlib
import json
from pathlib import Path

from sphinx_solver.integrity import verify_core


def test_core_integrity_classifies_certified_and_modified(tmp_path: Path) -> None:
    core = tmp_path / "solver.py"
    core.write_text("official\n", encoding="utf-8")
    manifest = {
        "release": "test",
        "coreFiles": [
            {"path": "solver.py", "sha256": hashlib.sha256(core.read_bytes()).hexdigest()}
        ],
    }
    (tmp_path / "SPHINX_CORE_MANIFEST.json").write_text(json.dumps(manifest), encoding="utf-8")
    assert verify_core(tmp_path)["classification"] == "SPHINX-CERTIFIED"

    core.write_text("modified\n", encoding="utf-8")
    report = verify_core(tmp_path)
    assert report["classification"] == "SPHINX-MODIFIED"
    assert report["modifiedFiles"] == ["solver.py"]
