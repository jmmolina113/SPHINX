"""Sparse operators that reproduce the current MATLAB discretization."""

from __future__ import annotations

import numpy as np
from scipy import sparse

from .model import PreparedSimulation


def _backward_periodic(size: int, spacing: float) -> sparse.csr_matrix:
    rows = np.arange(size)
    previous = (rows - 1) % size
    return sparse.csr_matrix(
        (np.concatenate([np.ones(size), -np.ones(size)]) / spacing,
         (np.concatenate([rows, rows]), np.concatenate([rows, previous]))),
        shape=(size, size),
    )


def derivative_blocks(prepared: PreparedSimulation) -> tuple[sparse.csr_matrix, sparse.csr_matrix, sparse.csr_matrix]:
    """Return MATLAB-compatible backward-periodic x, y, z blocks."""
    nx, ny, nz = prepared.problem.domain.grid
    ix, iy, iz = sparse.eye(nx, format="csr"), sparse.eye(ny, format="csr"), sparse.eye(nz, format="csr")
    zero = sparse.csr_matrix((nx * ny * nz, nx * ny * nz))
    active = [nx > 1, ny > 1, nz > 1]
    dx = sparse.kron(iz, sparse.kron(iy, _backward_periodic(nx, prepared.phys["delx_norm"]), format="csr"), format="csr") if active[0] else zero
    dy = sparse.kron(iz, sparse.kron(_backward_periodic(ny, prepared.phys["dely_norm"]), ix, format="csr"), format="csr") if active[1] else zero
    dz = sparse.kron(_backward_periodic(nz, prepared.phys["delz_norm"]), sparse.kron(iy, ix, format="csr"), format="csr") if active[2] else zero
    return dx.tocsr(), dy.tocsr(), dz.tocsr()


def gradient(prepared: PreparedSimulation) -> sparse.csr_matrix:
    """Build the stacked gradient ``[Dx; Dy; Dz]``."""
    return sparse.vstack(derivative_blocks(prepared), format="csr")


def laplacian(prepared: PreparedSimulation) -> sparse.csr_matrix:
    """Reproduce MATLAB's sum of squared backward-difference blocks."""
    dx, dy, dz = derivative_blocks(prepared)
    return (dx @ dx + dy @ dy + dz @ dz).tocsr()


def curl(prepared: PreparedSimulation) -> sparse.csr_matrix:
    """Build the periodic curl on contiguous x, y, z components."""
    dx, dy, dz = derivative_blocks(prepared)
    zero = sparse.csr_matrix(dx.shape)
    return sparse.bmat(
        [[zero, -dz, dy], [dz, zero, -dx], [-dy, dx, zero]],
        format="csr",
    )


def fixed_curl_2d(prepared: PreparedSimulation) -> tuple[sparse.csr_matrix, sparse.csr_matrix, sparse.csr_matrix]:
    """Reproduce ``fixedBoundaryCurlOperator_2D`` index for index."""
    nx, ny, nz = prepared.problem.domain.grid
    if nz != 1:
        raise ValueError("fixed curl is 2D only")
    n = nx * ny
    rows = []
    matlab_start = 2 * nx + 2
    for j in range(1, ny - 1):
        rows.extend((np.arange(1, nx - 1) + matlab_start + (j - 1) * nx).tolist())
    rows = np.asarray(rows, dtype=int) - 1
    dx = sparse.coo_matrix(
        (np.concatenate([np.full(rows.size, 1 / prepared.phys["delx_norm"]), np.full(rows.size, -1 / prepared.phys["delx_norm"])]),
         (np.concatenate([rows, rows]), np.concatenate([rows, rows - 1]))), shape=(n, n)
    ).tocsr()
    dy = sparse.coo_matrix(
        (np.concatenate([np.full(rows.size, 1 / prepared.phys["dely_norm"]), np.full(rows.size, -1 / prepared.phys["dely_norm"])]),
         (np.concatenate([rows, rows]), np.concatenate([rows, rows - nx]))), shape=(n, n)
    ).tocsr()
    zero = sparse.csr_matrix((n, n))
    c = sparse.bmat([[zero, zero, dy], [zero, zero, -dx], [-dy, dx, zero]], format="csr")
    return c, dx, dy


def fixed_curl_curl_2d(prepared: PreparedSimulation) -> sparse.csr_matrix:
    """Reproduce ``fixedBoundaryCurlCurlOperator_2D`` index for index."""
    nx, ny, nz = prepared.problem.domain.grid
    if nz != 1:
        raise ValueError("fixed curl-curl is 2D only")
    n = nx * ny
    rows = []
    matlab_start = 2 * nx + 2
    for j in range(1, ny - 1):
        rows.extend((np.arange(1, nx - 1) + matlab_start + (j - 1) * nx).tolist())
    rows = np.asarray(rows, dtype=int) - 1

    def matrix(offsets: list[int], values: list[float]) -> sparse.csr_matrix:
        all_rows = np.concatenate([rows for _ in offsets])
        all_cols = np.concatenate([rows + offset for offset in offsets])
        all_values = np.concatenate([np.full(rows.size, value) for value in values])
        return sparse.coo_matrix((all_values, (all_rows, all_cols)), shape=(n, n)).tocsr()

    dx2 = prepared.phys["delx_norm"] ** 2
    dy2 = prepared.phys["dely_norm"] ** 2
    dxx = matrix([0, -1, -2], [1 / dx2, -2 / dx2, 1 / dx2])
    dyy = matrix([0, -nx, -2 * nx], [1 / dy2, -2 / dy2, 1 / dy2])
    cross = prepared.phys["delx_norm"] * prepared.phys["dely_norm"]
    dxy = matrix([0, -1, -nx, -nx - 1], [1 / cross, -1 / cross, -1 / cross, 1 / cross])
    zero = sparse.csr_matrix((n, n))
    return sparse.bmat([[dyy, -dxy, zero], [-dxy, dxx, zero], [zero, zero, dxx + dyy]], format="csr")


def all_operators(prepared: PreparedSimulation) -> dict[str, sparse.csr_matrix]:
    """Build the operator set consumed by the split solver."""
    g = gradient(prepared)
    l = laplacian(prepared)
    if prepared.problem.boundary == "fixed":
        c, dx, dy = fixed_curl_2d(prepared)
        ctc = fixed_curl_curl_2d(prepared)
        dz = sparse.csr_matrix(dx.shape)
    else:
        dx, dy, dz = derivative_blocks(prepared)
        c = curl(prepared)
        ctc = (c.T @ c).tocsr()
    return {"G": g, "L": l, "T": l.T.tocsr(), "C": c, "CtC": ctc, "Dx": dx, "Dy": dy, "Dz": dz}
