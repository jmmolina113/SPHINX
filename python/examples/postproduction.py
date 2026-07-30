"""Analyze a manifested MATLAB or Python SPHINX run."""

from __future__ import annotations

import argparse

from sphinx_solver import analyze, import_run, produce


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run_folder", help="folder containing manifest.json, S/, F/, and V/")
    parser.add_argument("--field", default="probability")
    parser.add_argument("--movie", action="store_true")
    arguments = parser.parse_args()

    data = import_run(arguments.run_folder)
    diagnostics = analyze(data)
    products = ["summary", "conservation", "energy_breakdown", "snapshot", "lineout", "workspace"]
    if arguments.movie:
        products.append("movie")
    for path in produce(data, diagnostics, products, field=arguments.field):
        print(path)


if __name__ == "__main__":
    main()
