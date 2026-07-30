# Problem-definition schema

`sphinx.problem` returns a plain MATLAB structure. It is intentionally editable and serializable.

## Identity and model

| Field | Meaning | Allowed values |
|---|---|---|
| `schemaVersion` | Configuration schema revision | Currently `1` |
| `name` | Human-readable preset identity | String |
| `model` | Evolved subsystem | `"EM"`, `"QM"`, `"both"` |
| `boundary` | Spatial boundary implementation | `"fixed"`, `"periodic"` |
| `initialCondition` | Initializer selection | The bundled interface currently exposes `"cyclotron"`; the solver core accepts general initialized fields |

## Physics

| Field | Meaning |
|---|---|
| `physics.q` | Charge in the solver's atomic-unit convention; nonzero for the cyclotron preset |
| `physics.m` | Particle mass; positive |
| `physics.hbar` | Reduced Planck constant parameter; positive |
| `physics.c` | Speed-of-light parameter; positive |
| `physics.eps_0` | Permittivity parameter; positive |
| `physics.N_particles` | Particle-number normalization parameter; positive |

`sphinx.prepare` passes these values through the original `importParams_sim` normalization formulas. Derived values include `lambda`, `Epsilon`, `tau`, `psi_0`, `A_0`, `Y_0`, and the map coefficients `C_Y`, `C_A`, `C1`–`C4`, `C_JQ`, and `C_JA`.

## Domain

`domain.grid = [Nx,Ny,Nz]` contains positive integer point counts.

`domain.extentLambda` is a `3 x 2` matrix:

```matlab
[xmin,xmax;
 ymin,ymax;
 zmin,zmax]
```

Limits are expressed in multiples of the derived length scale `lambda`. A dimension with one grid point is inactive; its coordinate is placed at the midpoint of its limits and its effective spacing is one `lambda`.

## Time

| Field | Meaning |
|---|---|
| `time.cycles` | Number of cyclotron periods when `endTime` is empty |
| `time.endTime` | Explicit physical final time; overrides `cycles` when nonempty |
| `time.steps` | Total time points, including the initial state |

The solver timestep is `(finalTime)/(steps-1)` and is normalized by `tau` before the maps are applied.

## Output

| Field | Meaning |
|---|---|
| `output.root` | Parent directory containing `Runs/` |
| `output.name` | Run-family directory; must be a valid MATLAB-style name |
| `output.every` | Number of integration steps between snapshots |
| `output.writeManifest` | Whether JSON provenance and result files are written |

Output names deliberately exclude path separators. Directory construction belongs to the API, not the scientific configuration.

## Validation behavior

`sphinx.validateProblem` rejects incomplete structures, unsupported modes, invalid physical scalars, inconsistent fixed-boundary grids, malformed extents, invalid timing, and unsafe output names before field or operator allocation.
