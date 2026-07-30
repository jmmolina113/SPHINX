# SPHINX downloadable distributions

Run the repository packaging command from the project root:

```bash
python3 tools/build_distributions.py
```

It creates two deliberately separate archives under `dist/`:

- `SPHINX-MATLAB.zip` contains the MATLAB API, numerical solver,
  post-production suite, examples, tests, documentation, and `START_HERE.m`.
- `SPHINX-Python.zip` contains the installable Python package, Python examples,
  tests, documentation, and macOS/Linux/Windows install-and-run launchers.

`SHA256SUMS.txt` records both archive hashes. Generated archives are not
committed to Git. GitHub Actions builds them from each `main` revision and
attaches them permanently to tagged releases.

The full repository continues to contain both implementations, historical
provenance, and cross-language tests. The downloadable archives contain only
the implementation selected by the user.
