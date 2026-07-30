"""Coordinate, normalization, and initial-field construction."""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from .config import Problem, validate_problem


@dataclass
class VectorField:
    x: np.ndarray
    y: np.ndarray
    z: np.ndarray


@dataclass
class PreparedSimulation:
    problem: Problem
    psi_r: np.ndarray
    psi_i: np.ndarray
    A: VectorField
    Y: VectorField
    V: np.ndarray
    coordinates: dict[str, np.ndarray | float]
    phys: dict[str, float]
    sim: dict[str, object]


def _physical_parameters(problem: Problem) -> tuple[dict[str, float], dict[str, object]]:
    p = problem.physics
    phys = {
        "q": p.q,
        "m": p.m,
        "hbar": p.hbar,
        "c": p.c,
        "eps_0": p.eps_0,
        "N_particles": p.N_particles,
        "B_mag": p.B_mag,
    }
    phys["lambda"] = 4 * np.pi * phys["eps_0"] * phys["hbar"] ** 2
    phys["Epsilon"] = (phys["hbar"] / phys["lambda"]) ** 2
    phys["tau"] = phys["hbar"] / phys["Epsilon"]
    phys["psi_0"] = 1 / phys["lambda"] ** 1.5
    phys["B_0"] = phys["hbar"] / phys["lambda"] ** 2
    phys["E_0"] = phys["Epsilon"] / phys["lambda"]
    phys["A_0"] = phys["B_0"] * phys["lambda"]
    phys["Y_0"] = phys["E_0"] * phys["eps_0"]
    phys["mu"] = 1 / (phys["c"] ** 2 * phys["eps_0"])
    sim: dict[str, object] = {
        "numDim": sum(v > 1 for v in problem.domain.grid),
        "whatKindOfSim": problem.model,
        "boundaryCondition": problem.boundary,
        "Ngrid": problem.domain.grid,
    }
    sim["C_Y"] = phys["tau"] * phys["Y_0"] / (phys["A_0"] * phys["eps_0"])
    sim["C_A"] = phys["tau"] * phys["A_0"] * phys["c"] ** 2 * phys["eps_0"] / (phys["lambda"] ** 2 * phys["Y_0"])
    sim["C1"] = phys["tau"] * phys["q"] * phys["A_0"] / (2 * phys["m"] * phys["lambda"])
    sim["C2"] = phys["hbar"] * phys["tau"] / (4 * phys["m"] * phys["lambda"] ** 2)
    sim["C3"] = phys["tau"] * phys["q"] ** 2 * phys["A_0"] ** 2 / (2 * phys["m"] * phys["hbar"])
    sim["C4"] = phys["tau"] * phys["Epsilon"] / phys["hbar"]
    sim["C_JQ"] = phys["q"] * phys["hbar"] * phys["psi_0"] ** 2 * phys["tau"] / (phys["m"] * phys["lambda"] * 2 * phys["Y_0"])
    sim["C_JA"] = phys["q"] ** 2 * phys["A_0"] * phys["psi_0"] ** 2 * phys["tau"] / (phys["m"] * 2 * phys["Y_0"])
    return phys, sim


def prepare(problem: Problem) -> PreparedSimulation:
    """Materialize exactly the fields produced by MATLAB ``sphinx.prepare``."""
    problem = validate_problem(problem)
    phys, sim = _physical_parameters(problem)
    coordinates: dict[str, np.ndarray | float] = {}
    for axis, count, limits in zip("xyz", problem.domain.grid, problem.domain.extent_lambda):
        scaled = np.asarray(limits) * phys["lambda"]
        if count == 1:
            values = np.asarray([scaled.mean()])
            spacing = phys["lambda"]
        else:
            values = np.linspace(scaled[0], scaled[1], count)
            spacing = abs(values[-1] - values[-2])
        coordinates[axis] = values
        coordinates[f"del{axis}"] = float(spacing)

    cyclotron_period = 2 * np.pi / (abs(phys["q"]) * (abs(phys["B_mag"]) * phys["A_0"] / phys["lambda"]) / phys["m"])
    final_time = problem.time.cycles * cyclotron_period if problem.time.end_time is None else problem.time.end_time
    t = np.linspace(0, final_time, problem.time.steps)
    coordinates["t"] = t
    coordinates["delt"] = float(abs(t[-1] - t[-2]))
    for axis in "xyz":
        phys[f"del{axis}_norm"] = float(coordinates[f"del{axis}"]) / phys["lambda"]
    phys["delt_norm"] = float(coordinates["delt"]) / phys["tau"]

    nx, ny, nz = problem.domain.grid
    shape = (ny, nx, nz)
    zeros = lambda: np.zeros(shape, dtype=float)
    A = VectorField(zeros(), zeros(), zeros())
    Y = VectorField(zeros(), zeros(), zeros())
    rx, ry = np.meshgrid(coordinates["x"], coordinates["y"])
    for k in range(nz):
        A.x[:, :, k] = -0.5 * phys["B_mag"] * phys["hbar"] / phys["lambda"] ** 2 * ry
        A.y[:, :, k] = 0.5 * phys["B_mag"] * phys["hbar"] / phys["lambda"] ** 2 * rx
    A.x /= phys["A_0"]
    A.y /= phys["A_0"]
    A.z /= phys["A_0"]
    V = zeros() / phys["Epsilon"]
    sim["zPos"] = int(np.ceil(nz / 2))
    sim["yPos"] = int(np.ceil(ny / 2))
    phys["delta"] = np.sqrt(phys["hbar"] / (abs(phys["q"]) * (abs(phys["B_mag"]) * phys["A_0"] / phys["lambda"])))
    phys["x0"] = 3.75 * float(np.max(coordinates["x"])) / 10
    phys["y0"] = 0.0
    exponent = rx**2 + ry**2 + phys["x0"] ** 2 + phys["y0"] ** 2 - 2 * (rx + 1j * ry) * (phys["x0"] - 1j * phys["y0"])
    psi_slice = np.exp(-exponent / (4 * phys["delta"] ** 2))
    psi = np.repeat(psi_slice[:, :, None], nz, axis=2)
    phys["N_norm"] = np.sqrt(phys["N_particles"]) / np.sqrt(np.pi * 2 * phys["hbar"] / (abs(phys["q"]) * (phys["A_0"] / phys["lambda"])))
    psi_r = np.sqrt(2) * phys["N_norm"] * psi.real / phys["psi_0"]
    psi_i = np.sqrt(2) * phys["N_norm"] * psi.imag / phys["psi_0"]
    return PreparedSimulation(problem, psi_r, psi_i, A, Y, V, coordinates, phys, sim)
