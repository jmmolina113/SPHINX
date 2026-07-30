<p align="center">
  <img src="assets/sphinx-logo.png" alt="SPHINX" width="520">
</p>

# SPHINX for MATLAB

This download contains the supported MATLAB simulation and post-production
implementation without the Python package or historical research scripts.

## One-click start

1. Unzip `SPHINX-MATLAB.zip`.
2. Open the extracted folder in MATLAB.
3. Open `START_HERE.m` and press **Run**.

The demonstration performs a small coupled simulation, imports its complete
output, computes standard diagnostics, and prints the saved run folder.

To configure a simulation directly:

```matlab
setupSPHINX
sphinx.options

sim = sphinx.configure("cyclotron", ...
    "Resolution","quick", ...
    "Model","both", ...
    "RunName","my_run");

result = sphinx.run(sim);
```

Post-production begins with:

```matlab
data = sphinx.post.importRun(result);
analysis = sphinx.post.analyze(data);
sphinx.post.options
```

See `docs/README.md` for the complete user, numerical, theory, output, and
post-production documentation.
