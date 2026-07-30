# Simulation options

This page is intended for a researcher who understands the intended physics but has not read the SPHINX implementation.

## Simplest entry point

Open:

```matlab
edit examples/advisor_simulation_setup.m
```

Edit only the marked block, then press **Run**. The script explains and previews the simulation before starting it.

To inspect every option inside MATLAB:

```matlab
sphinx.options
```

## Configuration function

```matlab
sim = sphinx.configure("cyclotron", ...
    "Resolution","quick", ...
    "Model","both", ...
    "Boundary","fixed", ...
    "Charge",-1, ...
    "Mass",1, ...
    "Hbar",0.0069, ...
    "RunName","my_experiment");
```

`sphinx.configure` accepts options in any order and validates the finished problem.

## Evolution modes

| Choice | What evolves | Use when |
|---|---|---|
| `"EM"` | A and Y | Testing Maxwell evolution with a frozen quantum state |
| `"QM"` | Real and imaginary wavefunction components | Testing quantum evolution in a frozen electromagnetic background |
| `"both"` | Quantum and electromagnetic states | Studying the coupled Schrodinger-Maxwell system |

## Boundaries

| Choice | Support | Meaning |
|---|---|---|
| `"fixed"` | Square 2D grids only | Uses the historical fixed-boundary curl and curl-curl operators |
| `"periodic"` | 1D, 2D, or 3D | Uses periodic derivative branches in the sparse operators |

There is no fixed-boundary 3D operator in the current code.

## Resolution profiles

| Profile | Grid | Time points | Intended use |
|---|---:|---:|---|
| `"quick"` | 31 x 31 x 1 | 31 | Validated unit-scale interface demonstration |
| `"standard"` | 101 x 101 x 1 | 501 | Moderate 2D exploration |
| `"original"` | 251 x 251 x 1 | 35001 | Prime cyclotron configuration; preview first |
| `"3d_demo"` | 9 x 9 x 9 | 11 | Small periodic 3D demonstration |

Profiles are starting points, not scientific convergence claims. Explicit options supplied after `Resolution` override the profile.

The `quick` profile uses `q = 1`, `hbar = 1`, and `EndTime = 1e-4`. These are validated demonstration values, not a replacement for a research parameter study. The `original` profile mirrors the prime cyclotron setup: `q = -1`, `c = 0.01`, `B = 10`, a `251 x 251` fixed-boundary grid over `[-4,4] lambda`, and seven cyclotron periods sampled at 35,001 time points.

The `3d_demo` profile automatically selects periodic boundaries, `q = 1`, `hbar = 1`, and a short explicit end time that is suitable for a small interface demonstration.

## Physics options

| Configuration name | Problem field | Meaning |
|---|---|---|
| `Charge` | `physics.q` | Particle charge in the solver convention |
| `Mass` | `physics.m` | Particle mass |
| `Hbar` | `physics.hbar` | Reduced Planck parameter |
| `SpeedOfLight` | `physics.c` | Speed-of-light parameter |
| `Permittivity` | `physics.eps_0` | Permittivity parameter |
| `ParticleNumber` | `physics.N_particles` | Wavefunction normalization parameter |
| `MagneticField` | `physics.B_mag` | Uniform magnetic-field scale in the cyclotron initializer |

Changing these values also changes derived normalization scales and coupling coefficients. Always inspect `sphinx.describe(sim)` and `sphinx.preview(sim)` after changing them.

The historical small-`hbar` cyclotron configuration can require a substantially smaller timestep or different linear-solver treatment. SPHINX will preserve the output but mark the run `completed_with_solver_warnings` when BICGSTAB does not converge.

## Space and time options

| Name | Form | Meaning |
|---|---|---|
| `Grid` | `[Nx,Ny,Nz]` | Number of spatial points |
| `ExtentLambda` | `[xmin,xmax; ymin,ymax; zmin,zmax]` | Domain limits in units of lambda |
| `Cycles` | positive scalar | Cyclotron periods when `EndTime` is empty |
| `EndTime` | empty or positive scalar | Explicit physical final time |
| `TimePoints` | integer >= 2 | Initial state plus integration time points |

Increasing spatial points increases field memory linearly and sparse-operator cost substantially. Increasing time points does not increase rolling-state memory, but it increases runtime and potential output volume.

## Output options

| Name | Meaning |
|---|---|
| `SaveEvery` | Integration steps between snapshots |
| `RunName` | Safe run-family folder name |
| `OutputRoot` | Parent directory for `Runs/` |
| `WriteManifest` | Save JSON configuration, provenance, and diagnostics |

Keep `WriteManifest = true` for scientific work.

## Explain before running

```matlab
sphinx.describe(sim);
sphinx.preview(sim);
```

`describe` explains the selected physics and geometry in prose. `preview` reports storage estimates. Neither command runs the solver.

To include the exact initialized fields in the preview:

```matlab
report = sphinx.preview(sim,"ShowFields",true);
```

This produces line plots in 1D, planar maps in 2D, and orthogonal center
slices in 3D. It prepares the fields but does not advance time or write output.

## Recipes

### Fast coupled 2D demonstration

```matlab
sim = sphinx.configure("cyclotron", ...
    "Resolution","quick", ...
    "Model","both", ...
    "RunName","coupled_2D_demo");
```

### Quantum evolution in a frozen field

```matlab
sim = sphinx.configure("cyclotron", ...
    "Resolution","quick", ...
    "Model","QM", ...
    "RunName","quantum_only_demo");
```

### Small periodic 3D demonstration

```matlab
sim = sphinx.configure("cyclotron", ...
    "Resolution","3d_demo", ...
    "Model","both", ...
    "RunName","periodic_3D_demo");
```

## Result check

```matlab
result = sphinx.run(sim);

result.status
result.solver.converged
result.solver.maximumRelativeResidual
result.outputFolder
```

Do not treat `completed_with_solver_warnings` as a validated physical result. Inspect the manifest and reduce the timestep or reconsider the conditioning before analysis.
