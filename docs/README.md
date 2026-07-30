# SPHINX documentation

<img src="../assets/sphinx-mark.png" alt="SPHINX mark" width="140">

This directory documents the supported advisor-facing SPHINX workflow.

For a first checkout, return to the repository root and run `SPHINX_demo`.

## Reading order

1. [User guide](USER_GUIDE.md) — configure, preview, run, and inspect a simulation.
2. [Problem schema](PROBLEM_SCHEMA.md) — every supported problem-definition field.
3. [Architecture](ARCHITECTURE.md) — how the API, initialization, operators, maps, and output system connect.
4. [Theory and algorithms](THEORY_AND_ALGORITHMS.md) — continuum Hamiltonian, discrete bracket, normalized sparse maps, Cayley solves, current feedback, invariants, and equation-to-code correspondence.
5. [Numerical solver](NUMERICAL_SOLVER.md) — field ordering, split maps, dimensional branches, rolling buffers, and convergence diagnostics.
6. [Output and testing](OUTPUT_AND_TESTING.md) — folder layout, manifests, test coverage, and interpretation.
7. [Known issues](KNOWN_ISSUES.md) — current scientific, numerical, performance, and maintenance qualifications.
8. [File inventory](FILE_INVENTORY.md) — file-by-file ownership and purpose for this sharing branch.
10. [Simulation options](SIMULATION_OPTIONS.md) — advisor-facing choices, profiles, recipes, and safe starting points.
11. [Post-production suite](POST_PRODUCTION.md) — complete-run import, exact 3D ordering, diagnostics, figures, tables, and movies.

MATLAB-native help is also available:

```matlab
help sphinx.problem
help sphinx.preview
help sphinx.prepare
help sphinx.run
help sphinx.post.importRun
help sphinx.post.analyze
help sphinx.post.produce
help schrodingerMaxwellSolver_v16
```

## Repository map

| Path | Purpose | Status |
|---|---|---|
| `+sphinx/` | Public configuration and execution API | Active |
| `matlabSolver/` | Numerical operators and split maps | Active |
| `examples/` | Runnable examples | Active |
| `tests/` | API and numerical-equivalence tests | Active |
| `distribution/` | Separate MATLAB/Python release-bundle specification | Active |
| `python/` | Current Python implementation and tests | Active |
