"""Verify whether the numerical core matches an official SPHINX manifest."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify_core(root: Path) -> dict[str, Any]:
    manifest_path = root / "SPHINX_CORE_MANIFEST.json"
    if not manifest_path.is_file():
        return {
            "classification": "SPHINX-UNVERIFIED",
            "release": "unknown",
            "manifestSha256": "unavailable",
            "modifiedFiles": [],
            "reason": "core manifest is missing",
        }

    raw = manifest_path.read_bytes()
    try:
        manifest = json.loads(raw)
        expected = manifest["coreFiles"]
    except (json.JSONDecodeError, KeyError, TypeError):
        return {
            "classification": "SPHINX-UNVERIFIED",
            "release": "unknown",
            "manifestSha256": hashlib.sha256(raw).hexdigest(),
            "modifiedFiles": [],
            "reason": "core manifest is invalid",
        }

    modified = []
    for entry in expected:
        relative = entry["path"]
        expected_digest = entry["sha256"]
        path = root / relative
        if not path.is_file() or _sha256(path) != expected_digest:
            modified.append(relative)
    return {
        "classification": "SPHINX-CERTIFIED" if not modified else "SPHINX-MODIFIED",
        "release": manifest.get("release", "unknown"),
        "manifestSha256": hashlib.sha256(raw).hexdigest(),
        "modifiedFiles": modified,
        "reason": "official numerical core verified" if not modified else "numerical core differs from the official manifest",
    }
