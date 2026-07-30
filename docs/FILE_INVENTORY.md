# File inventory

This inventory describes the supported advisor-facing SPHINX branch.

Historical working scripts, autosaves, figures, run archives, and inactive
solver support remain in the private source repository and are intentionally not
included here.

## Public API and examples

| File | Purpose |
|---|---|
| `setupSPHINX.m` | Add the repository root to the MATLAB path |
| `+sphinx/problem.m` | Create named problem definitions |
| `+sphinx/configure.m` | Build problems using plain-language name-value choices |
| `+sphinx/options.m` | Display the supported simulation option catalog |
| `+sphinx/describe.m` | Translate a problem into an advisor-readable description |
| `+sphinx/validateProblem.m` | Validate configuration before allocation |
| `+sphinx/preview.m` | Estimate scale without running |
| `+sphinx/prepare.m` | Build parameters, grids, and initial fields |
| `+sphinx/plotInitialization.m` | Display initialized fields in 1D, 2D, or 3D |
| `+sphinx/run.m` | Execute and record a simulation |
| `+sphinx/+post/importRun.m` | Import and validate every selected run snapshot |
| `+sphinx/+post/flatten.m`, `unflatten.m` | Canonical solver/field ordering transforms |
| `+sphinx/+post/analyze.m` | Probability, energy, conservation, and field diagnostics |
| `+sphinx/+post/produce.m` | Tables, plots, slices, lineouts, movies, and workspaces |
| `+sphinx/+post/options.m` | Display the post-production option catalog |
| `examples/cyclotron_quickstart.m` | Small runnable API example |
| `examples/advisor_simulation_setup.m` | Edit-only-one-block setup form |
| `examples/advisor_postproduction.m` | Import-first, choose-products-second analysis form |
| `SPHINX_demo.m` | One-command simulation, import, analysis, and product demonstration |
| `assets/` | Repository wordmark and compact SPHINX mark |
| `.github/` | Public issue and pull-request contribution forms |
| `python/` | Current Python conversion, package metadata, examples, and cross-language tests |
| `distribution/`, `tools/build_distributions.py` | Separate MATLAB/Python release-bundle specification and builder |
| `.github/workflows/build-downloads.yml` | GitHub artifact and tagged-release automation |

## Active numerical solver

| File | Purpose |
|---|---|
| `schrodingerMaxwellSolver_v16.m` | Split-map orchestration and diagnostics |
| `flattenFields.m` | Pack structured fields into rolling rows |
| `M_em_v2.m` | Electromagnetic Cayley map |
| `M_qm_quantumFields_v3.m` | Quantum Cayley map |
| `M_qm_electromagneticFields_v3.m` | Midpoint-current feedback map |
| `calculateJ.m` | Three-component quantum current |
| `makeHmatrix_v4.m` | A-weighted gradient contribution |
| `importDifferentialOperators.m` | Operator assembly coordinator |
| `gradientOperator_v3.m` | Sparse gradient |
| `laplacianOperator_v3.m` | Sparse Laplacian |
| `curlOperator_v3.m` | Periodic curl |
| `fixedBoundaryCurlOperator_2D.m` | Fixed 2D curl |
| `fixedBoundaryCurlCurlOperator_2D.m` | Fixed 2D curl-curl |
| `importParams_phys.m` | Atomic-unit defaults |
| `importParams_sim.m` | Derived scales and map coefficients |
| `saveTimeStep.m` | Text snapshot writer |
| `writeSimParamsToFile.m` | Legacy XML metadata writer |
| `displayIntialization.m` | Legacy initialization plots |

## Tests

| File | Purpose |
|---|---|
| `SPHINX_user_api_test.m` | End-to-end API and output-contract test |
| `SPHINX_configuration_options_test.m` | Advisor-facing configuration interface test |
| `SPHINX_postproduction_test.m` | Nonsquare full-3D save/import orientation and product test |
| `SPHINX_V_full_integration_test.m` | Six-case numerical regression suite |
| `reference/reference_flattenFields.m` | Original history allocation fixture |
| `reference/reference_M_em_v2.m` | Original EM map fixture |
| `reference/reference_M_qm_quantumFields_v3.m` | Original QM map fixture |
| `reference/reference_M_qm_electromagneticFields_v3.m` | Original current-feedback fixture |

## Sharing boundary

Historical working scripts, autosaves, figures, run archives, and inactive
solver support remain in the private source repository. This branch contains
only the supported API, selected examples, tests, and documentation needed for
advisor review.
