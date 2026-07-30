"""Validated, plain-language SPHINX problem definitions."""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any

import numpy as np


@dataclass
class Physics:
    q: float = -1.0
    m: float = 1.0
    hbar: float = 1.0
    c: float = 0.01
    eps_0: float = 1.0 / (4.0 * np.pi)
    N_particles: float = 1.0
    B_mag: float = 10.0


@dataclass
class Domain:
    grid: tuple[int, int, int] = (251, 251, 1)
    extent_lambda: tuple[tuple[float, float], ...] = (
        (-4.0, 4.0),
        (-4.0, 4.0),
        (0.0, 0.0),
    )


@dataclass
class Time:
    cycles: float = 7.0
    end_time: float | None = None
    steps: int = 35001


@dataclass
class Output:
    root: str = "output"
    name: str = "cyclotron"
    every: int = 100
    write_manifest: bool = True


@dataclass
class Problem:
    schema_version: int = 1
    name: str = "cyclotron"
    model: str = "both"
    boundary: str = "fixed"
    initial_condition: str = "cyclotron"
    physics: Physics = field(default_factory=Physics)
    domain: Domain = field(default_factory=Domain)
    time: Time = field(default_factory=Time)
    output: Output = field(default_factory=Output)

    def to_dict(self) -> dict[str, Any]:
        """Return a manifest-ready dictionary using MATLAB field names."""
        value = asdict(self)
        value["schemaVersion"] = value.pop("schema_version")
        value["initialCondition"] = value.pop("initial_condition")
        value["domain"]["extentLambda"] = value["domain"].pop("extent_lambda")
        value["time"]["endTime"] = value["time"].pop("end_time")
        value["output"]["writeManifest"] = value["output"].pop("write_manifest")
        return value


def problem(name: str = "cyclotron", *, output_root: str | Path | None = None) -> Problem:
    """Create the same cyclotron preset as ``sphinx.problem`` in MATLAB."""
    if name.lower() != "cyclotron":
        raise ValueError(f"Unknown SPHINX problem preset: {name}")
    result = Problem()
    if output_root is not None:
        result.output.root = str(output_root)
    return validate_problem(result)


def problem_from_dict(value: dict[str, Any]) -> Problem:
    """Restore a problem from either a MATLAB or Python manifest."""
    physics_value = dict(value["physics"])
    physics_value.setdefault("B_mag", 1.0)
    result = Problem(
        schema_version=int(value.get("schemaVersion", value.get("schema_version", 1))),
        name=value["name"],
        model=value["model"],
        boundary=value["boundary"],
        initial_condition=value.get("initialCondition", value.get("initial_condition", "cyclotron")),
        physics=Physics(**physics_value),
        domain=Domain(
            grid=tuple(value["domain"]["grid"]),
            extent_lambda=tuple(tuple(row) for row in value["domain"].get("extentLambda", value["domain"].get("extent_lambda"))),
        ),
        time=Time(
            cycles=value["time"]["cycles"],
            end_time=value["time"].get("endTime", value["time"].get("end_time")),
            steps=int(value["time"]["steps"]),
        ),
        output=Output(
            root=value["output"]["root"],
            name=value["output"]["name"],
            every=int(value["output"]["every"]),
            write_manifest=value["output"].get("writeManifest", value["output"].get("write_manifest", True)),
        ),
    )
    return validate_problem(result)


_RESOLUTIONS: dict[str, dict[str, Any]] = {
    "quick": {
        "grid": (31, 31, 1),
        "extent": ((-5, 5), (-5, 5), (0, 0)),
        "q": 1.0,
        "hbar": 1.0,
        "B_mag": 1.0,
        "end_time": 1e-4,
        "steps": 31,
        "every": 5,
    },
    "standard": {
        "grid": (101, 101, 1),
        "extent": ((-10, 10), (-10, 10), (0, 0)),
        "cycles": 0.25,
        "end_time": None,
        "steps": 501,
        "every": 25,
    },
    "original": {
        "grid": (251, 251, 1),
        "extent": ((-4, 4), (-4, 4), (0, 0)),
        "cycles": 7.0,
        "end_time": None,
        "steps": 35001,
        "every": 100,
    },
    "3d_demo": {
        "boundary": "periodic",
        "grid": (9, 9, 9),
        "extent": ((-2, 2), (-2, 2), (-2, 2)),
        "q": 1.0,
        "hbar": 1.0,
        "B_mag": 1.0,
        "end_time": 1e-4,
        "steps": 11,
        "every": 2,
    },
}


def configure(name: str = "cyclotron", *, resolution: str = "original", **options: Any) -> Problem:
    """Create a problem with Pythonic equivalents of MATLAB name-value options."""
    sim = problem(name)
    try:
        profile = _RESOLUTIONS[resolution.lower()]
    except KeyError as exc:
        raise ValueError("resolution must be quick, standard, original, or 3d_demo") from exc

    sim.domain.grid = tuple(profile["grid"])
    sim.domain.extent_lambda = tuple(tuple(v) for v in profile["extent"])
    for key in ("q", "hbar", "B_mag"):
        if key in profile:
            setattr(sim.physics, key, profile[key])
    for key in ("cycles", "end_time", "steps"):
        if key in profile:
            setattr(sim.time, key, profile[key])
    sim.output.every = profile["every"]
    if "boundary" in profile:
        sim.boundary = profile["boundary"]

    aliases = {
        "grid": (sim.domain, "grid"),
        "extent_lambda": (sim.domain, "extent_lambda"),
        "model": (sim, "model"),
        "boundary": (sim, "boundary"),
        "charge": (sim.physics, "q"),
        "mass": (sim.physics, "m"),
        "hbar": (sim.physics, "hbar"),
        "speed_of_light": (sim.physics, "c"),
        "permittivity": (sim.physics, "eps_0"),
        "particle_number": (sim.physics, "N_particles"),
        "magnetic_field": (sim.physics, "B_mag"),
        "cycles": (sim.time, "cycles"),
        "end_time": (sim.time, "end_time"),
        "time_points": (sim.time, "steps"),
        "save_every": (sim.output, "every"),
        "run_name": (sim.output, "name"),
        "output_root": (sim.output, "root"),
        "write_manifest": (sim.output, "write_manifest"),
    }
    unknown = set(options) - set(aliases)
    if unknown:
        raise TypeError(f"Unknown configuration options: {', '.join(sorted(unknown))}")
    for key, value in options.items():
        target, attribute = aliases[key]
        setattr(target, attribute, value)
    return validate_problem(sim)


def validate_problem(sim: Problem) -> Problem:
    """Validate the same public constraints enforced by MATLAB."""
    if sim.model not in {"EM", "QM", "both"}:
        raise ValueError('model must be "EM", "QM", or "both"')
    if sim.boundary not in {"fixed", "periodic"}:
        raise ValueError('boundary must be "fixed" or "periodic"')
    if sim.initial_condition != "cyclotron":
        raise ValueError('only the "cyclotron" initializer is supported')
    grid = tuple(int(v) for v in sim.domain.grid)
    if len(grid) != 3 or any(v < 1 for v in grid):
        raise ValueError("domain.grid must contain three positive integers")
    dimensions = sum(v > 1 for v in grid)
    if dimensions < 1:
        raise ValueError("at least one grid dimension must contain multiple points")
    if sim.boundary == "fixed" and not (dimensions == 2 and grid[2] == 1 and grid[0] == grid[1]):
        raise ValueError("fixed boundaries require a square 2D grid with Nz = 1")
    extent = np.asarray(sim.domain.extent_lambda, dtype=float)
    if extent.shape != (3, 2) or not np.isfinite(extent).all():
        raise ValueError("extent_lambda must be a finite 3-by-2 array")
    for axis, count in enumerate(grid):
        if count > 1 and extent[axis, 1] <= extent[axis, 0]:
            raise ValueError("active dimensions require maximum > minimum")
    if int(sim.time.steps) != sim.time.steps or sim.time.steps < 2:
        raise ValueError("time.steps must be an integer greater than one")
    if sim.time.cycles <= 0 or (sim.time.end_time is not None and sim.time.end_time <= 0):
        raise ValueError("simulation duration must be positive")
    if int(sim.output.every) != sim.output.every or sim.output.every < 1:
        raise ValueError("output.every must be a positive integer")
    if not sim.output.name.isidentifier():
        raise ValueError("output.name must be a Python/MATLAB-style identifier")
    for name in ("q", "m", "hbar", "c", "eps_0", "N_particles", "B_mag"):
        if not np.isfinite(getattr(sim.physics, name)):
            raise ValueError(f"physics.{name} must be finite")
    if sim.physics.q == 0 or sim.physics.B_mag == 0 or min(sim.physics.m, sim.physics.hbar, sim.physics.c, sim.physics.eps_0, sim.physics.N_particles) <= 0:
        raise ValueError("mass, hbar, c, eps_0, and particle count must be positive; q cannot be zero")
    sim.domain.grid = grid
    sim.domain.extent_lambda = tuple(tuple(float(v) for v in row) for row in extent)
    sim.output.root = str(sim.output.root)
    return sim


def preview(sim: Problem) -> dict[str, Any]:
    """Return the same allocation and snapshot estimates as MATLAB."""
    sim = validate_problem(sim)
    points = int(np.prod(sim.domain.grid))
    snapshots = 1 + (sim.time.steps - 1) // sim.output.every
    rolling = 8 * 16 * points
    history = 8 * 8 * points * sim.time.steps
    return {
        "name": sim.name,
        "model": sim.model,
        "boundary": sim.boundary,
        "dimension": sum(v > 1 for v in sim.domain.grid),
        "grid": sim.domain.grid,
        "timePoints": sim.time.steps,
        "snapshots": snapshots,
        "rollingStateBytes": rolling,
        "originalHistoryBytes": history,
        "avoidedHistoryBytes": max(0, history - rolling),
        "minimumSnapshotBytes": 8 * 8 * points * snapshots,
        "outputRoot": sim.output.root,
        "valid": True,
    }


def describe(sim: Problem) -> str:
    """Return a compact plain-language experiment description."""
    report = preview(sim)
    evolution = {
        "EM": "electromagnetic fields only",
        "QM": "the quantum wavefunction only",
        "both": "the coupled Schrodinger-Maxwell system",
    }[sim.model]
    return (
        f"SPHINX will evolve {evolution} on a "
        f"{report['grid'][0]} x {report['grid'][1]} x {report['grid'][2]} "
        f"{sim.boundary} grid and save {report['snapshots']} snapshots."
    )
