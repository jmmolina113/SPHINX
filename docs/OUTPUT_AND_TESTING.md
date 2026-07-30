# Output and testing

## Run layout

For `output.root`, `output.name`, and timestamp `ID`, the API writes:

```text
output.root/
  Runs/
    output.name/
      ID/
        manifest.json
        result.json
        S/S_0000000.txt
        F/F_0000000.txt
        V/V.txt
```

Additional `S` and `F` snapshots use seven-digit zero-based timestep labels. `V` is written once because it is static in the current solver.

## Manifest

`manifest.json` records the complete problem definition, preview estimates, MATLAB version, Git revision, start and finish timestamps, elapsed time, saved-snapshot count, and solver diagnostics.

`result.json` is a compact serialization of the returned MATLAB result structure.

## Test suites

### `SPHINX_user_api_test`

This is an end-to-end interface test. It creates temporary output roots and runs:

- a small fixed-boundary coupled 2D problem;
- a small periodic coupled 3D problem.

It verifies successful status, directories, manifests, result metadata, and final S, F, and V files.

### `SPHINX_V_full_integration_test`

This is a numerical regression test. It compares the rolling solver with copied original reference maps over three steps for:

- fixed 2D: EM, QM, both;
- periodic 3D: EM, QM, both.

It compares final electromagnetic and quantum states with a solver-aware relative tolerance and verifies the saved rolling-buffer result.

## Running tests

```matlab
setupSPHINX
addpath('tests')

apiResults = SPHINX_user_api_test();
integrationResults = SPHINX_V_full_integration_test();
```

## What passing does not establish

The current tests do not establish production-scale memory or runtime, long-time conservation, physical validity of every parameter combination, restart correctness, fixed-boundary 3D behavior, or text-output performance. Those require separate scientific validation campaigns.

