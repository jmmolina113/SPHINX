# Public distribution

This is the clean-history public distribution of the SPHINX research software.
It contains the supported API, selected examples, tests, and
documentation; private working scripts, run data, credentials, and source
repository history are intentionally excluded.

## Keeping the distribution current

The public tree is refreshed from the private source `main` tree by the
maintainer. Before each refresh, run the repository tests, inspect the
allowlisted release contents, scan for private paths and credentials, and
publish a new single-snapshot update here. Do not configure this public
repository with credentials that can read a private upstream repository.

Because the upstream source is private, GitHub cannot safely mirror it
automatically without a separately governed credential. This boundary keeps
the public distribution shareable without exposing private history or access
tokens.
