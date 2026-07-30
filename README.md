<p align="center">
  <img src="assets/sphinx-logo.png" alt="SPHINX" width="520">
</p>


<p align="center">
  A lightweight, structure-preserving MATLAB and Python platform for general
  coupled Schrödinger–Maxwell simulation, analysis, and algorithm development.
  Periodic boundaries support one, two, and three dimensions; the original
  fixed-boundary operator supports two dimensions.
</p>

This repository is the clean-history public distribution of SPHINX. For a note
on how updates are prepared, see
[`RELEASE_SYNC.md`](RELEASE_SYNC.md) for the update boundary and release policy.

I built SPHINX around a simple research habit: make the numerical choices
explicit, keep the solver honest about what it has actually tested, and leave
enough of a trail that another person can follow. Research software tends to
grow a small bureaucracy of defaults, warnings, and mysterious checkboxes, so
the project tries to keep that bureaucracy legible. It is meant to be used,
questioned, and improved. That is generally more useful than admiring it as a
black box.

## Download MATLAB or Python

The [GitHub Releases page](https://github.com/jmmolina113/SPHINX/releases) has
two independent downloads:

- **SPHINX-MATLAB.zip** — unzip, open `START_HERE.m`, and press **Run**.
- **SPHINX-Python.zip** — unzip and open `install_and_run.command` on macOS,
  `install_and_run.sh` on Linux, or `install_and_run.bat` on Windows.

The repository keeps both implementations together so the cross-language
equivalence tests remain reproducible. Each release archive is separate, so
you can download only the one you plan to use.

## Certified core and editable analysis

SPHINX keeps the numerical core separate from analysis and problem setup. You
can adapt analysis scripts, plots, initial conditions, parameters, and
post-production without changing the certified solver.

Every run checks the numerical core against `SPHINX_CORE_MANIFEST.json` and
records `SPHINX-CERTIFIED`, `SPHINX-MODIFIED`, or `SPHINX-UNVERIFIED` in the
manifest and result. A modified core can still be useful research software;
its outputs just should not be presented as results from the official SPHINX
numerical core. See [the name and provenance policy](TRADEMARKS.md).

SPHINX is distributed under the [Apache License 2.0](LICENSE). The license
permits use, study, modification, and redistribution. The separate provenance
policy covers claims that a derivative is an official SPHINX release.

## Run SPHINX in sixty seconds

SPHINX is validated with MATLAB R2025b. Clone or download the repository, make
it the current MATLAB folder, and run:

```matlab
setupSPHINX
SPHINX_demo
```

The demo runs a small validated 2D example, imports the saved fields, computes
probability and Hamiltonian diagnostics, and writes a diagnostic CSV under
`output/`. Figures and movies can be selected afterward, when you actually
want them.

Nothing is installed globally, and there are no absolute paths to edit.

## Configure your own simulation

The plain-language interface is the easiest place to start. The bundled
`cyclotron` preset is one example problem, not the whole point of the solver:

```matlab
sim = sphinx.configure("cyclotron", ...
    "Resolution","quick", ...
    "Model","both", ...
    "Boundary","fixed", ...
    "RunName","my_first_run");

sphinx.describe(sim);
sphinx.preview(sim);
result = sphinx.run(sim);
```

To materialize and display the initialized fields before running:

```matlab
report = sphinx.preview(sim,"ShowFields",true);
```

The field preview uses line plots in 1D, planar maps in 2D, and orthogonal
center slices in 3D. The default preview does not allocate the simulation.

Inspect every supported choice with:

```matlab
sphinx.options
```

Available resolution profiles are `quick`, `standard`, `original`, and
`3d_demo`. Available evolution modes are electromagnetic-only (`EM`),
quantum-only (`QM`), and the coupled system (`both`). Fixed boundaries use the
original 2D operator; periodic boundaries support 1D, 2D, and full 3D runs.

The numerical core works with user-supplied wavefunctions, vector potentials,
canonical electromagnetic momenta, scalar potentials, grids, and physical
coefficients. New initializers and named problem presets can be added on top of
the same structure-preserving maps without changing the solver underneath.

If you prefer a form with one clearly marked edit block, use
[`examples/advisor_simulation_setup.m`](examples/advisor_simulation_setup.m).

## Analyze a completed run

Post-production is split into three fairly ordinary steps: import, analysis,
and product selection:

```matlab
data = sphinx.post.importRun(result);
analysis = sphinx.post.analyze(data);

files = sphinx.post.produce(data,analysis, ...
    ["summary","conservation","snapshot"]);
```

The importer reconstructs the wavefunction, vector and electric potentials,
electromagnetic fields, currents, canonical momentum, and Poynting flux. It
also round-trip verifies the solver's full-3D flattening convention before
analysis, because axis-order bugs are not improved by optimism.

```matlab
sphinx.post.options
```

lists the available diagnostics, fields, figures, movies, tables, and workspace
outputs. The editable post-production form lives at
[`examples/advisor_postproduction.m`](examples/advisor_postproduction.m).

## What is included

| Path | Purpose |
|---|---|
| [`+sphinx/`](+sphinx) | Public simulation API |
| [`+sphinx/+post/`](+sphinx/+post) | Supported post-production API |
| [`matlabSolver/`](matlabSolver) | Numerical operators and split Hamiltonian maps |
| [`examples/`](examples) | Runnable demonstrations and editable setup forms |
| [`tests/`](tests) | 2D/3D API, equivalence, ordering, and analysis tests |
| [`docs/`](docs) | User, numerical, architectural, and output documentation |
| [`assets/`](assets) | SPHINX identity artwork |

## Numerical and output contract

SPHINX advances the electromagnetic and quantum Hamiltonian maps with rolling
state buffers instead of allocating the full time history. The solver reports
each iterative-solver flag, residual, and iteration count.

Each run receives a timestamped folder containing:

```text
manifest.json
result.json
S/
F/
V/
```

The manifest records the complete problem definition, MATLAB version, source
revision, timestamps, storage preview, completion status, and solver diagnostics.
Imported field histories use `[time,y,x,z]`; flat solver fields use `x` fastest,
then `y`, then `z`, with vector components stored contiguously. It is not the
most exciting part of the project, but it saves time later.

## Validate your checkout

Run the public test suite from MATLAB:

```matlab
addpath('tests')
SPHINX_configuration_options_test
SPHINX_user_api_test
SPHINX_V_full_integration_test
SPHINX_postproduction_test
```

The numerical integration test compares the rolling solver with preserved
reference maps for fixed 2D and periodic 3D runs in `EM`, `QM`, and `both`
modes. The post-production test uses a nonsquare `5 × 4 × 3` grid so axis-order
errors cannot hide behind a conveniently square mesh.

## Documentation

- [Documentation index](docs/README.md)
- [First-run user guide](docs/USER_GUIDE.md)
- [Simulation options](docs/SIMULATION_OPTIONS.md)
- [Post-production guide](docs/POST_PRODUCTION.md)
- [Theory and algorithms](docs/THEORY_AND_ALGORITHMS.md)
- [Numerical solver](docs/NUMERICAL_SOLVER.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Known issues and scientific qualifications](docs/KNOWN_ISSUES.md)
- [Python implementation](python/README.md)
- [Download packaging](distribution/README.md)

For low-level research access, `sphinx.prepare` exposes the initialized fields,
coordinates, and normalized solver parameters without advancing the system.
This public distribution contains the supported API and selected examples;
historical run scripts and experiment-specific analysis are intentionally left
out. For new work, start with the `sphinx` and `sphinx.post` interfaces.
