# Known issues and qualifications

This register separates known limitations from verified behavior. Inclusion does not imply that a warning changes numerical output; it identifies work that should be resolved deliberately rather than hidden during documentation.

## Scientific validation

- The cyclotron preset now mirrors the prime fixed-2D reference setup (`B=10`, `q=-1`, `c=0.01`, `251 x 251`, seven periods). Its use as a physical 3D initial state requires a separate normalization and invariant review.
- Fixed-boundary operators exist only for 2D. Fixed-boundary 3D has not been derived or implemented.
- Long-time conservation, convergence in grid spacing and timestep, production-scale runtime, and production-scale memory remain to be benchmarked.
- Text snapshots are not a validated restart format.

## Solver configuration

- BICGSTAB tolerance and maximum iterations remain hard-coded at `1e-8` and `1000` inside the historical maps.
- The EM ILU factors are reused because the EM matrix is constant. The A-dependent quantum ILU is rebuilt every timestep.
- The solver now exposes all convergence flags and residuals, but it still writes snapshots when a solve returns a nonzero flag. Such runs are marked `completed_with_solver_warnings`.

## MATLAB Code Analyzer findings

MATLAB R2025b reports twelve findings across the active solver and regression fixtures:

- `M_qm_quantumFields_v3.m`: an initial sparse `O` allocation is overwritten before use; the skew-symmetry comparison is logically valid but more verbose than `~isequal(...)`.
- `fixedBoundaryCurlCurlOperator_2D.m`: three sparse indexed-assignment performance warnings.
- `fixedBoundaryCurlOperator_2D.m`: two sparse indexed-assignment performance warnings.
- `flattenFields.m`: the historical local variable `t` is now unused after conversion to two rolling rows.
- `makeHmatrix_v4.m`: the initial sparse `Hprime` allocation is overwritten.
- `SPHINX_V_full_integration_test.m`: one intentionally ignored returned value could use MATLAB's `~` placeholder.
- `reference_M_qm_quantumFields_v3.m`: the two corresponding historical reference-map findings are intentionally preserved.

These findings were documented rather than mechanically changed because several occur in regression-reference or structure-sensitive numerical code. They should be addressed in a dedicated cleanup branch with the full equivalence suite run before and after each change.

## Sharing boundary

Historical experiment-specific analysis is outside this advisor branch and is
not covered by the active API tests. It remains preserved in the private source
repository rather than being included in the sharing artifact.
