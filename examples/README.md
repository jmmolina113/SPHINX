# SPHINX examples

Run `setupSPHINX` once after opening the repository in MATLAB.

| File | Best for |
|---|---|
| `SPHINX_demo` at the repository root | One-command simulation and analysis demonstration |
| `cyclotron_quickstart.m` | Minimal simulation-only example |
| `advisor_simulation_setup.m` | Plain-language simulation form with one edit block |
| `advisor_postproduction.m` | Import-first analysis and output-selection form |
| `run_sphinx_headless.m` | Headless driver with initialization export and preview-only mode |
| `sphinx_headless.slurm` | Portable single-node Slurm template |

For a conference demonstration, begin with:

```matlab
SPHINX_demo
```

For a full 3D demonstration without manually selecting the grid:

```matlab
sim = sphinx.configure("cyclotron", ...
    "Resolution","3d_demo", ...
    "RunName","conference_3d");
result = sphinx.run(sim);
data = sphinx.post.importRun(result);
```

## Slurm / cluster batch use

From the repository root on the target cluster, inspect the available MATLAB
modules first:

```bash
module avail matlab
```

Submit a full run with an explicit writable output location:

```bash
sbatch --export=ALL,SPHINX_OUTPUT_ROOT=/path/to/scratch/SPHINX_runs \
    examples/sphinx_headless.slurm
```

To export and inspect initialized fields without advancing the solver:

```bash
sbatch --export=ALL,SPHINX_OUTPUT_ROOT=/path/to/scratch/SPHINX_runs,SPHINX_PREVIEW_ONLY=1 \
    examples/sphinx_headless.slurm
```

If the cluster uses another MATLAB release, set it at submission time with
`SPHINX_MATLAB_MODULE=matlab/RELEASE`. Submit from the repository root because
the template uses `SLURM_SUBMIT_DIR`. Edit the scientific setup in
`run_sphinx_headless.m` and resource requests in `sphinx_headless.slurm`.

Cluster execution remains site-specific: verify the MATLAB module, allocation,
scratch location, and a preview-only job before launching a full run.
