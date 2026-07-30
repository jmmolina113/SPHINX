"""Manifest-backed SPHINX import, diagnostics, and post-production products."""

from __future__ import annotations

import csv
from dataclasses import dataclass
import json
from pathlib import Path
import re
from typing import Iterable

import numpy as np

from .config import Problem, problem_from_dict
from .model import PreparedSimulation, VectorField, prepare
from .operators import all_operators
from .ordering import flatten, unflatten
from .solver import calculate_current


@dataclass
class RunData:
    """A complete manifested run. Histories use ``[time, y, x, z]``."""

    source_folder: str
    problem: Problem
    prepared: PreparedSimulation
    saved_steps: np.ndarray
    time: np.ndarray
    S: np.ndarray
    F: np.ndarray
    V_flat: np.ndarray
    psi_r: np.ndarray
    psi_i: np.ndarray
    probability: np.ndarray
    A: VectorField
    Y: VectorField
    B: VectorField | None = None
    E: VectorField | None = None
    J: VectorField | None = None
    probability_current: VectorField | None = None
    canonical_momentum: VectorField | None = None
    poynting: VectorField | None = None
    probability_current_divergence: np.ndarray | None = None
    poynting_divergence: np.ndarray | None = None


@dataclass
class Analysis:
    """Selected diagnostics evaluated on an imported run."""

    saved_steps: np.ndarray
    time: np.ndarray
    probability: dict[str, np.ndarray] | None = None
    energy: dict[str, np.ndarray] | None = None
    field_statistics: dict[str, dict[str, np.ndarray]] | None = None
    integration_box: np.ndarray | None = None


PRODUCTS = (
    "summary", "conservation", "energy_breakdown", "snapshot", "lineout",
    "movie", "workspace",
)
FIELDS = (
    "probability", "psiR", "psiI", "Ax", "Ay", "Az", "Yx", "Yy", "Yz",
    "Bx", "By", "Bz", "Ex", "Ey", "Ez", "Jx", "Jy", "Jz",
    "poyntingX", "poyntingY", "poyntingZ",
)


def options() -> dict[str, tuple[str, ...]]:
    """Return the supported Python post-production catalog."""
    return {
        "import": ("snapshots", "derived", "verify_order"),
        "diagnostics": ("probability", "energy", "field_statistics"),
        "products": PRODUCTS,
        "fields": FIELDS,
    }


def _snapshot_files(folder: Path, prefix: str) -> tuple[np.ndarray, list[Path]]:
    pairs = []
    for path in folder.glob(f"{prefix}_*.txt"):
        match = re.search(r"_(\d+)\.txt$", path.name)
        if match:
            pairs.append((int(match.group(1)), path))
    if not pairs:
        raise FileNotFoundError(f"No {prefix} snapshots found in {folder}")
    pairs.sort()
    return np.asarray([p[0] for p in pairs]), [p[1] for p in pairs]


def _read_vector(path: Path) -> np.ndarray:
    return np.loadtxt(path, delimiter=",").reshape(-1)


def _history_to_vector(flat: np.ndarray, grid: tuple[int, int, int]) -> VectorField:
    ntime, width = flat.shape
    n = width // 3
    shape = (ntime, grid[1], grid[0], grid[2])
    values = []
    for component in range(3):
        history = np.empty(shape, dtype=flat.dtype)
        for index in range(ntime):
            history[index] = unflatten(flat[index, component * n : (component + 1) * n], grid)
        values.append(history)
    return VectorField(*values)


def _pack_vector(vector: VectorField, index: int) -> np.ndarray:
    return np.concatenate([flatten(getattr(vector, component)[index]) for component in "xyz"])


def _select_snapshots(request: str | Iterable[int], steps: np.ndarray) -> np.ndarray:
    if request == "all":
        return np.arange(steps.size)
    wanted = np.asarray(list(request), dtype=int).reshape(-1)
    selected = []
    for value in wanted:
        matches = np.flatnonzero(steps == value)
        if matches.size:
            selected.append(int(matches[0]))
        elif 0 <= value < steps.size:
            selected.append(int(value))
        else:
            raise ValueError(f"{value} is neither a saved step nor a zero-based snapshot index")
    return np.asarray(selected, dtype=int)


def import_run(
    source: str | Path | object,
    *,
    snapshots: str | Iterable[int] = "all",
    derived: bool = True,
    verify_order: bool = True,
) -> RunData:
    """Import a current MATLAB or Python SPHINX run with identical ordering."""
    folder = Path(getattr(source, "output_folder", source))
    manifest_path = folder / "manifest.json"
    if not manifest_path.is_file():
        raise FileNotFoundError(f"manifest.json is required in {folder}")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    problem = problem_from_dict(manifest["problem"])
    prepared = prepare(problem)
    steps, sfiles = _snapshot_files(folder / "S", "S")
    fsteps, ffiles = _snapshot_files(folder / "F", "F")
    if not np.array_equal(steps, fsteps):
        raise ValueError("S and F snapshot steps do not match")
    selection = _select_snapshots(snapshots, steps)
    steps = steps[selection]
    sfiles = [sfiles[i] for i in selection]
    ffiles = [ffiles[i] for i in selection]
    S = np.vstack([_read_vector(path) for path in sfiles])
    F = np.vstack([_read_vector(path) for path in ffiles])
    V_flat = _read_vector(folder / "V" / "V.txt")
    grid = problem.domain.grid
    n = int(np.prod(grid))
    if S.shape[1] != 2 * n or F.shape[1] != 6 * n or V_flat.size != n:
        raise ValueError("snapshot size does not match the manifest grid")
    shape = (steps.size, grid[1], grid[0], grid[2])
    psi_r = np.empty(shape)
    psi_i = np.empty(shape)
    for index in range(steps.size):
        psi_r[index] = unflatten(S[index, :n], grid)
        psi_i[index] = unflatten(S[index, n:], grid)
    A = _history_to_vector(F[:, : 3 * n], grid)
    Y = _history_to_vector(F[:, 3 * n :], grid)
    if verify_order:
        for index in range(steps.size):
            if not np.array_equal(flatten(psi_r[index]), S[index, :n]):
                raise ValueError(f"psi_r ordering round-trip failed at snapshot {index}")
            if not np.array_equal(flatten(psi_i[index]), S[index, n:]):
                raise ValueError(f"psi_i ordering round-trip failed at snapshot {index}")
            if not np.array_equal(np.concatenate((_pack_vector(A, index), _pack_vector(Y, index))), F[index]):
                raise ValueError(f"electromagnetic ordering round-trip failed at snapshot {index}")
        if not np.array_equal(flatten(unflatten(V_flat, grid)), V_flat):
            raise ValueError("potential ordering round-trip failed")
    data = RunData(
        str(folder.resolve()), problem, prepared, steps,
        np.asarray(prepared.coordinates["t"])[steps], S, F, V_flat,
        psi_r, psi_i, psi_r**2 + psi_i**2, A, Y,
    )
    if derived:
        _derive_fields(data)
    return data


def _derive_fields(data: RunData) -> None:
    operators = all_operators(data.prepared)
    G, C = operators["G"], operators["C"]
    n = data.V_flat.size
    bflat = np.vstack([C @ row[: 3 * n] for row in data.F])
    jflat = np.vstack([
        calculate_current(data.S[i, :n], data.S[i, n:], data.F[i, : 3 * n], operators, data.prepared)
        for i in range(data.saved_steps.size)
    ])
    probability_current = jflat / data.prepared.phys["q"]
    canonical = np.empty((data.saved_steps.size, 3 * n), dtype=complex)
    poynting = np.empty_like(bflat)
    probability_divergence = np.empty((data.saved_steps.size, n))
    poynting_divergence = np.empty((data.saved_steps.size, n))
    scale = data.prepared.phys["q"] * data.prepared.phys["A_0"] / (
        data.prepared.phys["hbar"] / data.prepared.phys["lambda"]
    )
    for index in range(data.saved_steps.size):
        psi = data.S[index, :n] + 1j * data.S[index, n:]
        aflat = data.F[index, : 3 * n]
        yflat = data.F[index, 3 * n :]
        canonical[index] = -1j * (G @ psi) - scale * aflat * np.tile(psi, 3)
        left = -yflat.reshape(3, n)
        right = bflat[index].reshape(3, n)
        poynting[index] = np.cross(left.T, right.T).T.reshape(-1)
        probability_divergence[index] = sum(
            G[c * n : (c + 1) * n] @ probability_current[index, c * n : (c + 1) * n]
            for c in range(3)
        )
        poynting_divergence[index] = sum(
            G[c * n : (c + 1) * n] @ poynting[index, c * n : (c + 1) * n]
            for c in range(3)
        )
    data.B = _history_to_vector(bflat, data.problem.domain.grid)
    data.E = VectorField(
        -data.Y.x / data.prepared.phys["eps_0"],
        -data.Y.y / data.prepared.phys["eps_0"],
        -data.Y.z / data.prepared.phys["eps_0"],
    )
    data.J = _history_to_vector(jflat, data.problem.domain.grid)
    data.probability_current = _history_to_vector(probability_current, data.problem.domain.grid)
    data.canonical_momentum = _history_to_vector(canonical, data.problem.domain.grid)
    data.poynting = _history_to_vector(poynting, data.problem.domain.grid)
    data.probability_current_divergence = np.stack([
        unflatten(row, data.problem.domain.grid) for row in probability_divergence
    ])
    data.poynting_divergence = np.stack([
        unflatten(row, data.problem.domain.grid) for row in poynting_divergence
    ])


def _integration_selection(data: RunData, box: np.ndarray | None) -> tuple[tuple[np.ndarray, ...], list[np.ndarray]]:
    xyz = [np.asarray(data.prepared.coordinates[name]) for name in "xyz"]
    if box is None:
        xyz_indices = [np.arange(values.size) for values in xyz]
    else:
        limits = np.asarray(box, dtype=float)
        if limits.shape != (3, 2):
            raise ValueError("integration_box must be [xmin xmax; ymin ymax; zmin zmax]")
        xyz_indices = [np.flatnonzero((values >= low) & (values <= high)) for values, (low, high) in zip(xyz, limits)]
        if any(indices.size == 0 for indices in xyz_indices):
            raise ValueError("integration_box excludes an entire coordinate axis")
    indices = (xyz_indices[1], xyz_indices[0], xyz_indices[2])
    coordinates = [xyz[1][indices[0]], xyz[0][indices[1]], xyz[2][indices[2]]]
    return indices, coordinates


def _integrate(field: np.ndarray, data: RunData, box: np.ndarray | None) -> float:
    indices, coordinates = _integration_selection(data, box)
    value = np.asarray(field)[np.ix_(*indices)]
    for axis in range(2, -1, -1):
        if coordinates[axis].size > 1:
            value = np.trapezoid(value, coordinates[axis], axis=axis)
    return float(np.asarray(value).reshape(-1)[0])


def _vector_square(vector: VectorField, index: int) -> np.ndarray:
    return vector.x[index] ** 2 + vector.y[index] ** 2 + vector.z[index] ** 2


def _relative(values: np.ndarray) -> np.ndarray:
    return np.full_like(values, np.nan) if values.size == 0 or values[0] == 0 else (values - values[0]) / values[0]


def _resolve_field(data: RunData, name: str) -> np.ndarray:
    token = name.lower()
    if token == "probability":
        return data.probability
    if token == "psir":
        return data.psi_r
    if token == "psii":
        return data.psi_i
    match = re.fullmatch(r"(a|y|b|e|j)(x|y|z)", token)
    if match:
        vector = getattr(data, match.group(1).upper())
        if vector is None:
            raise ValueError(f"{name} requires import_run(..., derived=True)")
        return getattr(vector, match.group(2))
    match = re.fullmatch(r"poynting(x|y|z)", token)
    if match and data.poynting is not None:
        return getattr(data.poynting, match.group(1))
    raise ValueError(f"unknown field {name!r}; choose one of {', '.join(FIELDS)}")


def analyze(
    data: RunData,
    *,
    diagnostics: str | Iterable[str] = "all",
    integration_box: np.ndarray | None = None,
) -> Analysis:
    """Compute selected probability, energy, and field-statistics diagnostics."""
    selected = {"probability", "energy", "field_statistics"} if diagnostics == "all" else {str(x).lower() for x in diagnostics}
    valid = {"probability", "energy", "field_statistics"}
    if not selected <= valid:
        raise ValueError(f"unknown diagnostics: {sorted(selected - valid)}")
    probability_result = None
    energy = None
    statistics = None
    count = data.saved_steps.size
    if "probability" in selected:
        probability = np.asarray([
            data.prepared.phys["psi_0"] ** 2 * _integrate(data.probability[i], data, integration_box)
            for i in range(count)
        ])
        probability_result = {
            "integral": probability,
            "normAmplitude": np.sqrt(np.maximum(probability, 0)),
            "relativeDrift": _relative(probability),
        }
    if "energy" in selected:
        if data.B is None:
            raise ValueError("energy diagnostics require import_run(..., derived=True)")
        operators = all_operators(data.prepared)
        G, L = operators["G"], operators["L"]
        n = data.V_flat.size
        phys = data.prepared.phys
        names = ("magnetic", "electric", "electromagnetic", "quantumGradient", "quantumCoupling", "quantumPotential", "quantum", "total")
        energy = {name: np.zeros(count) for name in names}
        for index in range(count):
            psi_r, psi_i = data.S[index, :n], data.S[index, n:]
            A = data.F[index, : 3 * n]
            grad_r, grad_i = G @ psi_r, G @ psi_i
            lap_r, lap_i = L @ psi_r, L @ psi_i
            coupling_r = np.zeros(n)
            coupling_i = np.zeros(n)
            a_squared = np.zeros(n)
            for component in range(3):
                sl = slice(component * n, (component + 1) * n)
                coupling_r += A[sl] * grad_r[sl]
                coupling_i += A[sl] * grad_i[sl]
                a_squared += A[sl] ** 2
            psi_squared = psi_r**2 + psi_i**2
            gradient_density = -phys["hbar"] ** 2 * phys["psi_0"] ** 2 / (4 * phys["m"] * phys["lambda"] ** 2) * (psi_r * lap_r + psi_i * lap_i)
            coupling_density = phys["q"] * phys["hbar"] * phys["A_0"] * phys["psi_0"] ** 2 / (2 * phys["m"] * phys["lambda"]) * (psi_i * coupling_r - psi_r * coupling_i)
            potential_density = phys["psi_0"] ** 2 / 2 * (phys["q"] ** 2 * phys["A_0"] ** 2 / (2 * phys["m"]) * a_squared * psi_squared + phys["Epsilon"] / phys["m"] * data.V_flat * psi_squared)
            energy["magnetic"][index] = _integrate(0.5 * phys["B_0"] ** 2 / phys["mu"] * _vector_square(data.B, index), data, integration_box)
            energy["electric"][index] = _integrate(0.5 * phys["Y_0"] ** 2 / phys["eps_0"] * _vector_square(data.Y, index), data, integration_box)
            for name, density in (("quantumGradient", gradient_density), ("quantumCoupling", coupling_density), ("quantumPotential", potential_density)):
                energy[name][index] = _integrate(unflatten(density, data.problem.domain.grid), data, integration_box)
            energy["electromagnetic"][index] = energy["magnetic"][index] + energy["electric"][index]
            energy["quantum"][index] = energy["quantumGradient"][index] + energy["quantumCoupling"][index] + energy["quantumPotential"][index]
            energy["total"][index] = energy["electromagnetic"][index] + energy["quantum"][index]
        for name in ("electromagnetic", "quantum", "total", "magnetic", "electric"):
            energy[f"{name}RelativeDrift"] = _relative(energy[name])
    if "field_statistics" in selected:
        statistics = {}
        for name in FIELDS[:18]:
            history = _resolve_field(data, name)
            axes = tuple(range(1, history.ndim))
            statistics[name] = {
                "minimum": np.min(history, axis=axes),
                "maximum": np.max(history, axis=axes),
                "rms": np.sqrt(np.mean(np.abs(history) ** 2, axis=axes)),
            }
    box = None if integration_box is None else np.asarray(integration_box, dtype=float)
    return Analysis(data.saved_steps, data.time, probability_result, energy, statistics, box)


def _snapshot_index(data: RunData, request: str | int) -> int:
    if isinstance(request, str):
        choices = {"first": 0, "middle": data.time.size // 2, "last": data.time.size - 1}
        if request.lower() not in choices:
            raise ValueError("snapshot must be first, middle, last, a saved step, or an index")
        return choices[request.lower()]
    matches = np.flatnonzero(data.saved_steps == int(request))
    if matches.size:
        return int(matches[0])
    if 0 <= int(request) < data.time.size:
        return int(request)
    raise ValueError("requested snapshot was not imported")


def _plane_slice(data: RunData, history: np.ndarray, index: int, plane: str, coordinate: float):
    R = data.prepared.coordinates
    field = history[index]
    plane = plane.lower()
    if plane == "x":
        point = int(np.argmin(np.abs(np.asarray(R["x"]) - coordinate)))
        return field[:, point, :].T, R["y"], R["z"], ("y", "z"), R["x"][point]
    if plane == "y":
        point = int(np.argmin(np.abs(np.asarray(R["y"]) - coordinate)))
        return field[point, :, :].T, R["x"], R["z"], ("x", "z"), R["y"][point]
    if plane == "z":
        point = int(np.argmin(np.abs(np.asarray(R["z"]) - coordinate)))
        return field[:, :, point], R["x"], R["y"], ("x", "y"), R["z"][point]
    raise ValueError("plane must be x, y, or z")


def _lineout(data: RunData, history: np.ndarray, index: int, axis: str, fixed_point: Iterable[float]):
    R = data.prepared.coordinates
    point = np.asarray(tuple(fixed_point), dtype=float)
    if point.shape != (3,):
        raise ValueError("fixed_point must be [x, y, z]")
    ix, iy, iz = [int(np.argmin(np.abs(np.asarray(R[name]) - value))) for name, value in zip("xyz", point)]
    nearest = np.asarray([R["x"][ix], R["y"][iy], R["z"][iz]])
    field = history[index]
    if axis == "x":
        return field[iy, :, iz], R["x"], nearest
    if axis == "y":
        return field[:, ix, iz], R["y"], nearest
    if axis == "z":
        return field[iy, ix, :], R["z"], nearest
    raise ValueError("line_axis must be x, y, or z")


def _plotting():
    try:
        import imageio_ffmpeg
        import matplotlib as mpl
        import matplotlib.pyplot as plt
        from matplotlib.animation import FFMpegWriter
    except ImportError as exc:
        raise RuntimeError("plot products require: python -m pip install -e './python[plots]'") from exc
    mpl.rcParams["animation.ffmpeg_path"] = imageio_ffmpeg.get_ffmpeg_exe()
    return plt, FFMpegWriter


def produce(
    data: RunData,
    analysis: Analysis,
    products: str | Iterable[str],
    *,
    output_folder: str | Path | None = None,
    field: str = "probability",
    plane: str = "z",
    coordinate: float = 0.0,
    snapshot: str | int = "last",
    line_axis: str = "x",
    fixed_point: Iterable[float] = (0.0, 0.0, 0.0),
    frame_rate: float = 8.0,
) -> list[Path]:
    """Create selected CSV, PNG, MP4, or compressed-workspace products."""
    requested = [products] if isinstance(products, str) else list(products)
    requested = [item.lower() for item in requested]
    unknown = set(requested) - set(PRODUCTS)
    if unknown:
        raise ValueError(f"unknown products: {sorted(unknown)}")
    destination = Path(output_folder) if output_folder else Path(data.source_folder) / "processedData"
    destination.mkdir(parents=True, exist_ok=True)
    files: list[Path] = []
    for product in requested:
        if product == "summary":
            path = destination / "diagnostics.csv"
            columns = {"Step": analysis.saved_steps, "Time": analysis.time}
            if analysis.probability is not None:
                columns.update(Probability=analysis.probability["integral"], ProbabilityRelativeDrift=analysis.probability["relativeDrift"])
            if analysis.energy is not None:
                columns.update(ElectromagneticEnergy=analysis.energy["electromagnetic"], QuantumEnergy=analysis.energy["quantum"], TotalEnergy=analysis.energy["total"], TotalEnergyRelativeDrift=analysis.energy["totalRelativeDrift"])
            with path.open("w", newline="", encoding="utf-8") as stream:
                writer = csv.writer(stream)
                writer.writerow(columns)
                writer.writerows(zip(*columns.values()))
        elif product == "workspace":
            path = destination / "postproduction.npz"
            payload = {"saved_steps": data.saved_steps, "time": data.time, "S": data.S, "F": data.F, "V": data.V_flat}
            if analysis.probability:
                payload.update({f"probability_{key}": value for key, value in analysis.probability.items()})
            if analysis.energy:
                payload.update({f"energy_{key}": value for key, value in analysis.energy.items()})
            np.savez_compressed(path, **payload)
        else:
            plt, writer_class = _plotting()
            if product == "conservation":
                if analysis.probability is None or analysis.energy is None:
                    raise ValueError("conservation requires probability and energy diagnostics")
                path = destination / "conservation.png"
                figure, axes = plt.subplots(2, 2, figsize=(12, 7), constrained_layout=True)
                axes[0, 0].plot(analysis.time, analysis.probability["integral"], "k", lw=1.8)
                for name, color in (("electromagnetic", "b"), ("quantum", "r"), ("total", "k")):
                    axes[0, 1].plot(analysis.time, analysis.energy[name], color, lw=1.6, label=name)
                axes[0, 1].legend()
                axes[1, 0].plot(analysis.time, analysis.probability["relativeDrift"], "k", lw=1.8)
                axes[1, 1].plot(analysis.time, analysis.energy["totalRelativeDrift"], "k", lw=1.8)
                for axis, ylabel in zip(axes.flat, ("probability", "energy", "(P-P0)/P0", "(H-H0)/H0")):
                    axis.set(xlabel="time", ylabel=ylabel); axis.grid(True)
                figure.suptitle("SPHINX conservation diagnostics")
                figure.savefig(path, dpi=180); plt.close(figure)
            elif product == "energy_breakdown":
                if analysis.energy is None:
                    raise ValueError("energy_breakdown requires energy diagnostics")
                path = destination / "energy_breakdown.png"
                figure, axes = plt.subplots(1, 2, figsize=(12, 5.2), constrained_layout=True)
                for name, color in (("magnetic", "b"), ("electric", "r"), ("electromagnetic", "k")):
                    axes[0].plot(analysis.time, analysis.energy[name], color, label=name)
                for name, color in (("quantumGradient", "b"), ("quantumCoupling", "r"), ("quantumPotential", "g"), ("quantum", "k")):
                    axes[1].plot(analysis.time, analysis.energy[name], color, label=name)
                for axis, title in zip(axes, ("Electromagnetic energy", "Quantum energy")):
                    axis.set(xlabel="time", ylabel="energy", title=title); axis.grid(True); axis.legend()
                figure.savefig(path, dpi=180); plt.close(figure)
            elif product == "snapshot":
                path = destination / f"{field}_snapshot.png"
                index = _snapshot_index(data, snapshot)
                image, horizontal, vertical, labels, selected_coordinate = _plane_slice(data, _resolve_field(data, field), index, plane, coordinate)
                figure, axis_object = plt.subplots(figsize=(7.6, 6.5), constrained_layout=True)
                mesh = axis_object.pcolormesh(horizontal, vertical, image, shading="auto")
                figure.colorbar(mesh, ax=axis_object)
                axis_object.set(xlabel=labels[0], ylabel=labels[1], title=f"{field} at t = {data.time[index]:.6g}, {plane} = {selected_coordinate:.6g}")
                axis_object.set_aspect("equal"); figure.savefig(path, dpi=180); plt.close(figure)
            elif product == "lineout":
                path = destination / f"{field}_lineout.png"
                index = _snapshot_index(data, snapshot)
                values, abscissa, selected = _lineout(data, _resolve_field(data, field), index, line_axis.lower(), fixed_point)
                figure, axis_object = plt.subplots(figsize=(8.5, 4.8), constrained_layout=True)
                axis_object.plot(abscissa, values, "k", lw=1.8); axis_object.grid(True)
                axis_object.set(xlabel=line_axis, ylabel=field, title=f"{field} lineout at t = {data.time[index]:.6g} through ({selected[0]:.4g}, {selected[1]:.4g}, {selected[2]:.4g})")
                figure.savefig(path, dpi=180); plt.close(figure)
            else:
                path = destination / f"{field}_{plane}_movie.mp4"
                history = _resolve_field(data, field)
                figure, axis_object = plt.subplots(figsize=(7.6, 6.5), constrained_layout=True)
                writer = writer_class(fps=frame_rate)
                try:
                    with writer.saving(figure, str(path), dpi=140):
                        limits = (float(np.min(history)), float(np.max(history)))
                        for index in range(data.time.size):
                            axis_object.clear()
                            image, horizontal, vertical, labels, _ = _plane_slice(data, history, index, plane, coordinate)
                            axis_object.pcolormesh(horizontal, vertical, image, shading="auto", vmin=limits[0], vmax=limits[1])
                            axis_object.set(xlabel=labels[0], ylabel=labels[1], title=f"{field} at t = {data.time[index]:.6g}")
                            axis_object.set_aspect("equal"); writer.grab_frame()
                except FileNotFoundError as exc:
                    raise RuntimeError("movie production requires an ffmpeg executable") from exc
                finally:
                    plt.close(figure)
        files.append(path)
    return files
