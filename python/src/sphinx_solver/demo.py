"""Command-line first run for the Python implementation."""

from pathlib import Path

from .config import configure, describe
from .io import run
from .post import analyze, import_run


def main() -> None:
    sim = configure(
        "cyclotron",
        resolution="quick",
        run_name="python_demo",
        output_root=Path.cwd() / "output",
    )
    print(describe(sim))
    result = run(sim)
    data = import_run(result)
    analysis = analyze(data)
    print(f"Run folder: {result.output_folder}")
    print(f"Maximum probability drift: {abs(analysis.probability['relativeDrift']).max():.3e}")
    print(f"Maximum total-energy drift: {abs(analysis.energy['totalRelativeDrift']).max():.3e}")


if __name__ == "__main__":
    main()
