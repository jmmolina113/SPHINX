# Numerical solver

For the full derivation—from the continuum Hamiltonian and discrete Poisson
bracket through the normalized sparse matrices and Cayley maps—see
[Theory and algorithms](THEORY_AND_ALGORITHMS.md).

## State ordering

Let `fFL = Nx*Ny*Nz` and `fVFL = 3*fFL`.

The quantum row is ordered as

```text
S = [psi_R, psi_I]
```

with length `2*fFL`.

The electromagnetic row is ordered as

```text
F = [A_x, A_y, A_z, Y_x, Y_y, Y_z]
```

with length `2*fVFL = 6*fFL`.

Flattening traverses each z slice and transposes each x-y plane before reshaping. Existing analysis code must preserve this ordering when reconstructing fields.

## Rolling storage

`flattenFields` allocates two rows for each state. Row 1 is the previous state and row 2 is the current work state. After each completed timestep, row 2 is copied to row 1.

The original implementation allocated one row per time point. The rolling design removes linear-in-time state-history memory while retaining snapshots on disk.

## Split sequence

For every timestep the solver applies:

1. `M_em_v2`: advance the electromagnetic subsystem using a Cayley transform of the constant EM generator.
2. Fixed-boundary replacement when the fixed 2D path is selected.
3. `M_qm_quantumFields_v3`: construct the A-dependent skew quantum generator and advance `S` by a Cayley solve.
4. `M_qm_electromagneticFields_v3`: compute midpoint `psi`, evaluate `J`, and update the Y components of `F`.
5. Save the requested global timestep and roll the state rows.

The selected `model` conditionally freezes the complementary subsystem.

## Linear solves

Both Cayley maps use `bicgstab` with an ILU preconditioner. The EM matrix is constant for a fixed grid and timestep, so its ILU factors are constructed once and reused. The quantum matrix depends on the evolving vector potential and is factorized each step.

The current tolerance and maximum iteration count remain the historical hard-coded values `1e-8` and `1000`. Solver flags, achieved relative residuals, and iteration counts are now retained for every step.

## Convergence status

`solverResult.converged` is true only when all EM and QM flags are zero. `maximumRelativeResidual` is the maximum returned residual across both maps. Frozen substeps report a zero flag, zero residual, and zero iterations.

`sphinx.run` converts any nonconvergence into `completed_with_solver_warnings`. Files may still exist for such a run; existence is not evidence of numerical validity.

## Boundaries

The original fixed-boundary discretization exists only for 2D and requires a square x-y grid. Periodic derivative operators have 1D, 2D, and 3D branches. The API validates this support boundary before operator creation.

## Known scientific qualifications

- The bundled cyclotron example uses the historical symmetric-gauge wave packet and is extruded uniformly through active z slices for 3D configurations; this is an initializer-specific choice, not a restriction of the numerical maps.
- The example's historical normalization formulas should be independently reviewed before treating arbitrary 3D cyclotron configurations as production physical states.
- Fixed-boundary masking and the fixed discrete operators are preserved from the original implementation rather than rederived here.
- Text output can dominate large runs and is not a restart format.
