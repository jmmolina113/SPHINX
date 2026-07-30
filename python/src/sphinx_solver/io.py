"""Run orchestration and MATLAB-compatible on-disk output."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
import json
from pathlib import Path
import subprocess
import time
from typing import Any

import numpy as np

from .config import Problem, preview, validate_problem
from .model import prepare
from .solver import SolverDiagnostics, solve
from .integrity import verify_core


@dataclass
class RunResult:
    status: str
    problem: str
    output_folder: str
    started_at: str
    finished_at: str
    elapsed_seconds: float
    steps_completed: int
    saved_snapshots: int
    source_revision: str
    solver: SolverDiagnostics
    core_provenance: dict[str, Any]

    def to_dict(self) -> dict[str, Any]:
        return {
            "status": self.status,
            "problem": self.problem,
            "outputFolder": self.output_folder,
            "startedAt": self.started_at,
            "finishedAt": self.finished_at,
            "elapsedSeconds": self.elapsed_seconds,
            "stepsCompleted": self.steps_completed,
            "savedSnapshots": self.saved_snapshots,
            "sourceRevision": self.source_revision,
            "solver": self.solver.to_dict(),
            "coreProvenance": self.core_provenance,
        }


def _timestamp() -> str:
    return datetime.now().astimezone().isoformat(timespec="milliseconds")


def _revision(root: Path) -> str:
    try:
        return subprocess.check_output(
            ["git", "-C", str(root), "rev-parse", "--short", "HEAD"],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except (OSError, subprocess.CalledProcessError):
        return "unknown"


def _write_json(path: Path, value: dict[str, Any]) -> None:
    path.write_text(json.dumps(value, indent=2, allow_nan=False) + "\n", encoding="utf-8")


def run(problem: Problem) -> RunResult:
    """Validate, execute, and record a Python SPHINX simulation."""
    problem = validate_problem(problem)
    prepared = prepare(problem)
    source_path = Path(__file__).resolve()
    root = next(
        (parent for parent in source_path.parents if (parent / "SPHINX_CORE_MANIFEST.json").is_file()),
        source_path.parents[3],
    )
    run_identifier = datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:19]
    folder = Path(problem.output.root) / "Runs" / problem.output.name / run_identifier
    for child in (folder / "S", folder / "F", folder / "V"):
        child.mkdir(parents=True, exist_ok=True)
    started = _timestamp()
    revision = _revision(root)
    core_provenance = verify_core(root)
    if core_provenance["classification"] != "SPHINX-CERTIFIED":
        import warnings

        warnings.warn(
            f'{core_provenance["classification"]}: {core_provenance["reason"]}. '
            "Results must not be represented as produced by the official SPHINX numerical core.",
            RuntimeWarning,
            stacklevel=2,
        )
    manifest = {
        "schemaVersion": problem.schema_version,
        "implementation": "python",
        "status": "running",
        "startedAt": started,
        "problem": problem.to_dict(),
        "preview": preview(problem),
        "pythonVersion": __import__("sys").version.split()[0],
        "sourceRevision": revision,
        "coreProvenance": core_provenance,
    }
    if problem.output.write_manifest:
        _write_json(folder / "manifest.json", manifest)

    timer = time.perf_counter()
    output = solve(prepared)
    elapsed = time.perf_counter() - timer
    for step, state_s, state_f in zip(output.saved_steps, output.S, output.F):
        np.savetxt(folder / "S" / f"S_{step:07d}.txt", state_s[None, :], delimiter=",", fmt="%.17g")
        np.savetxt(folder / "F" / f"F_{step:07d}.txt", state_f[None, :], delimiter=",", fmt="%.17g")
    np.savetxt(folder / "V" / "V.txt", output.V[:, None], delimiter=",", fmt="%.17g")

    finished = _timestamp()
    result = RunResult(
        "completed" if output.diagnostics.converged else "completed_with_solver_warnings",
        problem.name,
        str(folder.resolve()),
        started,
        finished,
        elapsed,
        problem.time.steps - 1,
        len(output.saved_steps),
        revision,
        output.diagnostics,
        core_provenance,
    )
    if problem.output.write_manifest:
        manifest.update(
            status=result.status,
            finishedAt=finished,
            elapsedSeconds=elapsed,
            stepsCompleted=result.steps_completed,
            savedSnapshots=result.saved_snapshots,
        )
        _write_json(folder / "manifest.json", manifest)
        _write_json(folder / "result.json", result.to_dict())
    return result
