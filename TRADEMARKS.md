# SPHINX name and scientific provenance

SPHINX is the name of the canonical simulation software distributed from this
repository. The license permits modification, study, and redistribution, but
it does not grant permission to imply that a modified numerical core is an
official SPHINX release or that its results have been reviewed or endorsed by
the SPHINX authors.

Analysis scripts, plotting code, problem definitions, and parameter files may
be changed without renaming the software. If any file listed in
`SPHINX_CORE_MANIFEST.json` is changed, the resulting software and publications
must identify it as a modified SPHINX derivative and must not describe its
outputs as `SPHINX-CERTIFIED`.

Official releases are those published by this repository with an intact core
manifest. The runtime classification embedded in each output is:

- `SPHINX-CERTIFIED`: every numerical-core file matches the official manifest.
- `SPHINX-MODIFIED`: at least one numerical-core file differs or is missing.
- `SPHINX-UNVERIFIED`: the manifest is missing or invalid.

Scientific citation credits provenance; it does not imply endorsement. Users
publishing results from a modified or unverified core should state that fact,
identify the derivative, and archive the exact source revision used.
