# User guide

## Start MATLAB

```matlab
cd('path/to/SPHINX')
setupSPHINX
```

`setupSPHINX` adds the repository root to the current MATLAB path. The `+sphinx` package then becomes available without exposing internal solver functions globally.

## Create and edit a problem

```matlab
sim = sphinx.problem("cyclotron");

sim.physics.hbar = 0.0069;
sim.model = "both";
sim.boundary = "fixed";
sim.domain.grid = [51,51,1];
sim.domain.extentLambda = [-5,5;-5,5;0,0];
sim.time.cycles = 0.01;
sim.time.steps = 101;
sim.output.every = 10;
sim.output.name = "cyclotron_demo";
```

This preserves the original workflow of loading complete defaults and overriding only the experimental variables.

## Preview before allocating

```matlab
report = sphinx.preview(sim);
```

The preview checks the configuration and estimates rolling-state memory, eliminated history memory, snapshot count, and minimum numeric output. It does not build fields or sparse operators.

## Inspect initialization

```matlab
report = sphinx.preview(sim,"ShowFields",true);
```

This displays the quantum/scalar and electromagnetic initialization using line
plots in 1D, planar maps in 2D, and orthogonal center slices in 3D. It does not
advance the simulation or write output. The two figure handles are returned in
`report.initializationFigures`.

The default `sphinx.preview(sim)` remains a lightweight storage preview and does
not allocate fields. For direct programmatic access to the initialized arrays:

```matlab
[psi,A,Y,V,R,params] = sphinx.prepare(sim);
```

## Run

```matlab
result = sphinx.run(sim);
```

Important returned fields:

```matlab
result.status
result.outputFolder
result.elapsedSeconds
result.stepsCompleted
result.savedSnapshots
result.sourceRevision
result.solver.converged
result.solver.maximumRelativeResidual
```

If any iterative solve fails, `result.status` is `"completed_with_solver_warnings"`. Treat that run as numerically unverified until the failed timestep, residual, and configuration have been examined.

## Simulation modes

```matlab
sim.model = "EM";    % advance electromagnetic fields; hold psi fixed
sim.model = "QM";    % advance psi; hold electromagnetic fields fixed
sim.model = "both";  % coupled Schrodinger-Maxwell split evolution
```

## Boundaries and dimensions

```matlab
sim.boundary = "fixed";     % original fixed operator, 2D only
sim.boundary = "periodic";  % 1D, 2D, or 3D
```

The dimension is inferred from entries of `sim.domain.grid` greater than one. Fixed-boundary runs require `[Nx,Ny,1]` with `Nx == Ny`.

## Small periodic 3D example

```matlab
sim = sphinx.problem("cyclotron");
sim.boundary = "periodic";
sim.domain.grid = [9,9,9];
sim.domain.extentLambda = [-2,2;-2,2;-2,2];
sim.physics.q = 1;
sim.physics.hbar = 1;
sim.time.endTime = 1e-4;
sim.time.steps = 11;
sim.output.every = 2;
sim.output.name = "periodic_3D_demo";

sphinx.preview(sim);
result = sphinx.run(sim);
```

## Recommended working pattern

1. Create a preset with `sphinx.problem`.
2. Override only the desired scientific variables.
3. Call `sphinx.preview` and inspect the scale.
4. Use `sphinx.prepare` if the initialization needs visual inspection.
5. Run and check `result.status` and `result.solver.converged`.
6. Preserve `manifest.json` with any figures or derived results.
