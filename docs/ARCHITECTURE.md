# Architecture

## Execution flow

```text
sphinx.problem
      |
      v
sphinx.validateProblem
      |
      +-----------------> sphinx.preview
      |
      v
sphinx.prepare
      |
      +--> physical defaults and derived coefficients
      +--> coordinate and time grids
      +--> selected initial-condition fields
      |
      v
sphinx.run
      |
      +--> manifest and output directories
      v
schrodingerMaxwellSolver_v16
      |
      +--> differential operators
      +--> rolling field flattening
      +--> EM Cayley map
      +--> QM Cayley map
      +--> midpoint-current EM map
      +--> snapshot writer
      |
      v
result structure and completed manifest
```

## Public API

- `sphinx.problem` defines reusable scientific defaults.
- `sphinx.validateProblem` is the allocation boundary: invalid work stops here.
- `sphinx.preview` estimates scale without materializing the simulation by
  default; `ShowFields=true` deliberately prepares and displays the initialized
  fields for 1D, 2D, or 3D inspection.
- `sphinx.plotInitialization` is the dimension-aware visualization layer used by
  the field-preview option.
- `sphinx.prepare` converts a user problem into legacy solver inputs.
- `sphinx.run` owns execution, provenance, output layout, and user-facing status.

## Compatibility layer

The numerical solver still consumes the original structures:

- `psi.R`, `psi.I`
- `A.x`, `A.y`, `A.z`
- `Y.x`, `Y.y`, `Y.z`
- scalar potential `V`
- coordinates and time in `R`
- normalized physics and simulation coefficients in `params`

This boundary lets the API improve without requiring a wholesale rewrite of the verified map implementation.

## Active numerical components

| Component | Responsibility |
|---|---|
| `importParams_phys` | Original atomic-unit defaults |
| `importParams_sim` | Derived scales and coupling coefficients |
| `importDifferentialOperators` | Operator orchestration and component gradient views |
| `gradientOperator_v3` | Stacked scalar-to-vector gradient |
| `laplacianOperator_v3` | Scalar Laplacian |
| `curlOperator_v3` | Periodic curl for 1D–3D branches |
| `fixedBoundaryCurlOperator_2D` | Fixed 2D curl |
| `fixedBoundaryCurlCurlOperator_2D` | Fixed 2D curl-curl |
| `flattenFields` | Structured-to-flat rolling state conversion |
| `M_em_v2` | Electromagnetic Cayley map |
| `M_qm_quantumFields_v3` | Quantum Cayley map |
| `M_qm_electromagneticFields_v3` | Midpoint-current feedback map |
| `makeHmatrix_v4` | A-weighted transposed-gradient term |
| `calculateJ` | Three-component discrete quantum current |
| `saveTimeStep` | Legacy text snapshots |
| `schrodingerMaxwellSolver_v16` | Time-loop orchestration and diagnostics |

## Extension points

The cleanest future additions are new problem presets, named initializers, configurable solver tolerances, binary checkpoint backends, diagnostics modules, and restart support. These should enter above or beside the numerical core rather than being added to experiment scripts.
