<p align="center">
  <img src="../assets/sphinx-mark.png" alt="SPHINX" width="180">
</p>

# SPHINX Python

This directory is the Python conversion of the current MATLAB SPHINX API,
rolling solver, output contract, and numerical post-production layer. It is
not a conversion of the historical Python or MATLAB scripts.

## Install

From the repository root:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -e ./python
```

Run the Python demonstration:

```bash
sphinx-demo
```

or use the API:

```python
from sphinx_solver import configure, run, import_run, analyze

sim = configure(
    "cyclotron",
    resolution="3d_demo",
    run_name="python_3d_demo",
)

result = run(sim)
data = import_run(result)
diagnostics = analyze(data)
```

## Post-production suite

The Python package now implements the supported MATLAB `sphinx.post` workflow:

```python
from sphinx_solver import analyze, import_run, produce

data = import_run("output/Runs/my_run/20260728_120000_000")
analysis = analyze(data)
files = produce(
    data,
    analysis,
    ["summary", "conservation", "energy_breakdown", "snapshot", "lineout", "workspace"],
    field="probability",
    plane="z",
    coordinate=0,
    snapshot="last",
)
```

Run the complete example with:

```bash
python python/examples/postproduction.py RUN_FOLDER
```

Add `--movie` to create an MP4. Plot and movie products require installation
with `python -m pip install -e './python[plots]'`; this extra includes a private
FFmpeg executable, so a separate system installation is not required.

The conversion includes complete-run or subset import; ordering verification;
`B`, `E`, `J`, probability current, canonical momentum, Poynting flux, and both
divergences; probability, Hamiltonian, conservation, integration-box, and field
statistics diagnostics; and all seven MATLAB product categories. Python
workspaces use compressed `.npz` rather than MATLAB `.mat` files.

## Compatibility contract

- Problem presets and resolution profiles match `sphinx.configure`.
- Structured fields use `[y,x,z]`; histories use `[time,y,x,z]`.
- Flat fields use x-fastest, then y, then z ordering.
- `S`, `F`, and `V` text files can be imported by either implementation.
- Python reads MATLAB manifests and MATLAB reads Python snapshot files once
  the recorded problem schema is used.
- Periodic and original fixed-boundary sparse operators are preserved exactly.
- The split-map order and current coupling are preserved exactly.

The linear algebra backends differ intentionally at this stage. MATLAB uses
preconditioned `bicgstab`; Python currently uses SciPy's deterministic sparse
direct solve. Small validation cases agree at approximately `1e-11` or better
in relative state norm after three coupled steps. The direct solve generally
reduces equation residuals but does not reproduce MATLAB iteration counts.

## Test

Self-contained Python tests:

```bash
PYTHONPATH=python/src python -m unittest discover -s python/tests -p 'test_core.py'
```

MATLAB-versus-Python equivalence test:

```bash
PYTHONPATH=python/src python -m unittest python/tests/test_cross_language.py
```

The cross-language test uses MATLAB R2025b when found at its default macOS
location. Set `MATLAB_BIN` to another MATLAB executable when needed. It runs
fixed 2D and nonsquare periodic 3D cases, then compares every raw snapshot and
the probability, electromagnetic, quantum, and total-energy diagnostics.

## Sharing boundary

This branch contains the supported Python implementation and tests. Historical
experiment-specific analysis remains in the private source repository and is
not part of the advisor distribution.
