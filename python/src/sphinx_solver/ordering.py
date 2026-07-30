"""Canonical MATLAB-compatible field flattening."""

from __future__ import annotations

import numpy as np


def flatten(field_yxz: np.ndarray) -> np.ndarray:
    """Pack ``[y,x,z]`` with x fastest, then y, then z."""
    return np.asarray(field_yxz).transpose(1, 0, 2).reshape(-1, order="F")


def unflatten(vector: np.ndarray, grid: tuple[int, int, int]) -> np.ndarray:
    """Restore a flat solver scalar to ``[y,x,z]``."""
    nx, ny, nz = grid
    return np.asarray(vector).reshape((nx, ny, nz), order="F").transpose(1, 0, 2)


def pack_vector(vector: object) -> np.ndarray:
    """Pack an object with x, y, and z structured components."""
    return np.concatenate([flatten(vector.x), flatten(vector.y), flatten(vector.z)])
