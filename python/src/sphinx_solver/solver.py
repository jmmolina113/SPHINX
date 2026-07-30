"""Rolling split-map solver matching the current MATLAB implementation."""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np
from scipy import sparse
from scipy.sparse.linalg import spsolve

from .model import PreparedSimulation
from .operators import all_operators
from .ordering import flatten, pack_vector


@dataclass
class SolverDiagnostics:
    em_flag: np.ndarray
    em_relative_residual: np.ndarray
    em_iterations: np.ndarray
    qm_flag: np.ndarray
    qm_relative_residual: np.ndarray
    qm_iterations: np.ndarray
    converged: bool
    maximum_relative_residual: float
    linear_solver: str = "scipy.sparse.linalg.spsolve"

    def to_dict(self) -> dict[str, object]:
        return {
            "emFlag": self.em_flag.tolist(),
            "emRelativeResidual": self.em_relative_residual.tolist(),
            "emIterations": self.em_iterations.tolist(),
            "qmFlag": self.qm_flag.tolist(),
            "qmRelativeResidual": self.qm_relative_residual.tolist(),
            "qmIterations": self.qm_iterations.tolist(),
            "converged": self.converged,
            "maximumRelativeResidual": self.maximum_relative_residual,
            "linearSolver": self.linear_solver,
        }


@dataclass
class SolverOutput:
    saved_steps: list[int]
    S: list[np.ndarray]
    F: list[np.ndarray]
    V: np.ndarray
    diagnostics: SolverDiagnostics


def calculate_current(
    psi_r: np.ndarray,
    psi_i: np.ndarray,
    A: np.ndarray,
    operators: dict[str, sparse.csr_matrix],
    prepared: PreparedSimulation,
) -> np.ndarray:
    """Evaluate the three-component discrete quantum current."""
    n = psi_r.size
    psi_squared = psi_r**2 + psi_i**2
    currents = []
    for component, name in enumerate(("Dx", "Dy", "Dz")):
        derivative = operators[name]
        grad_r = derivative @ psi_r
        grad_i = derivative @ psi_i
        current = (
            prepared.sim["C_JQ"] * (psi_r * grad_i - psi_i * grad_r)
            - prepared.sim["C_JA"] * psi_squared * A[component * n : (component + 1) * n]
        )
        currents.append(np.asarray(current))
    return np.concatenate(currents)


def _residual(matrix: sparse.spmatrix, value: np.ndarray, rhs: np.ndarray) -> float:
    denominator = np.linalg.norm(rhs)
    numerator = np.linalg.norm(matrix @ value - rhs)
    return float(numerator if denominator == 0 else numerator / denominator)


def _quantum_map(
    S: np.ndarray,
    F: np.ndarray,
    dt: float,
    operators: dict[str, sparse.csr_matrix],
    prepared: PreparedSimulation,
    V: np.ndarray,
) -> tuple[np.ndarray, int, float, int]:
    if prepared.problem.model == "EM":
        return S.copy(), 0, 0.0, 0
    n = V.size
    A = F[: 3 * n]
    G, L, T = operators["G"], operators["L"], operators["T"]
    a_dot_g = sparse.csr_matrix((n, n))
    h_matrix = sparse.csr_matrix((n, n))
    for component in range(3):
        values = A[component * n : (component + 1) * n]
        block = G[component * n : (component + 1) * n, :]
        diagonal = sparse.diags(values)
        a_dot_g = a_dot_g + diagonal @ block
        h_matrix = h_matrix + block.T @ diagonal
    a_squared = sum(A[component * n : (component + 1) * n] ** 2 for component in range(3))
    o_parallel = prepared.sim["C1"] * (a_dot_g - h_matrix)
    o_perpendicular = prepared.sim["C2"] * (L + T) - (
        prepared.sim["C3"] * sparse.diags(a_squared) + prepared.sim["C4"] * sparse.diags(V)
    )
    omega = sparse.bmat(
        [[o_parallel, -o_perpendicular], [o_perpendicular, o_parallel]],
        format="csc",
    )
    identity = sparse.eye(2 * n, format="csc")
    minus = identity - 0.5 * dt * omega
    rhs = (identity + 0.5 * dt * omega) @ S
    new_state = np.asarray(spsolve(minus, rhs))
    residual = _residual(minus, new_state, np.asarray(rhs))
    return new_state, int(not np.isfinite(residual)), residual, 1


def solve(prepared: PreparedSimulation) -> SolverOutput:
    """Advance one prepared simulation using two rolling state vectors."""
    problem = prepared.problem
    nx, ny, nz = problem.domain.grid
    n = nx * ny * nz
    nv = 3 * n
    operators = all_operators(prepared)
    S = np.concatenate([flatten(prepared.psi_r), flatten(prepared.psi_i)])
    F = np.concatenate([pack_vector(prepared.A), pack_vector(prepared.Y)])
    V = flatten(prepared.V)
    zero = sparse.csr_matrix((nv, nv))
    q_matrix = sparse.bmat(
        [
            [zero, prepared.sim["C_Y"] * sparse.eye(nv)],
            [-prepared.sim["C_A"] * operators["CtC"], zero],
        ],
        format="csc",
    )
    dt = prepared.phys["delt_norm"]
    identity_f = sparse.eye(2 * nv, format="csc")
    q_minus = identity_f - 0.5 * dt * q_matrix
    q_plus = identity_f + 0.5 * dt * q_matrix

    boundary_mask = np.zeros(n, dtype=bool)
    if problem.boundary == "fixed":
        for row in range(ny):
            for column in range(nx):
                if column < 2 or row < 2:
                    boundary_mask[column + row * nx] = True
    full_boundary_mask = np.tile(boundary_mask, 6)
    boundary_values = F[full_boundary_mask].copy()

    number_of_steps = problem.time.steps - 1
    em_flag = np.zeros(number_of_steps, dtype=int)
    em_residual = np.zeros(number_of_steps)
    em_iterations = np.zeros(number_of_steps)
    qm_flag = np.zeros(number_of_steps, dtype=int)
    qm_residual = np.zeros(number_of_steps)
    qm_iterations = np.zeros(number_of_steps)
    saved_steps = [0]
    saved_s = [S.copy()]
    saved_f = [F.copy()]

    for step in range(1, problem.time.steps):
        old_s = S
        if problem.model == "QM":
            new_f = F.copy()
        else:
            rhs = q_plus @ F
            new_f = np.asarray(spsolve(q_minus, rhs))
            em_residual[step - 1] = _residual(q_minus, new_f, np.asarray(rhs))
            em_iterations[step - 1] = 1
            em_flag[step - 1] = int(not np.isfinite(em_residual[step - 1]))
        if problem.boundary == "fixed":
            new_f[full_boundary_mask] = boundary_values

        S, qm_flag[step - 1], qm_residual[step - 1], qm_iterations[step - 1] = _quantum_map(
            old_s, new_f, dt, operators, prepared, V
        )
        if problem.model == "both":
            midpoint_r = 0.5 * (old_s[:n] + S[:n])
            midpoint_i = 0.5 * (old_s[n:] + S[n:])
            current = calculate_current(midpoint_r, midpoint_i, new_f[:nv], operators, prepared)
            new_f[nv:] += dt * current
        F = new_f
        if step % problem.output.every == 0:
            saved_steps.append(step)
            saved_s.append(S.copy())
            saved_f.append(F.copy())

    all_residuals = np.concatenate([em_residual, qm_residual])
    diagnostics = SolverDiagnostics(
        em_flag,
        em_residual,
        em_iterations,
        qm_flag,
        qm_residual,
        qm_iterations,
        bool(np.all(em_flag == 0) and np.all(qm_flag == 0)),
        float(np.max(all_residuals)) if all_residuals.size else 0.0,
    )
    return SolverOutput(saved_steps, saved_s, saved_f, V, diagnostics)
