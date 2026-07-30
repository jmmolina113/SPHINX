"""Small Python simulation and complete numerical analysis."""

from sphinx_solver import analyze, configure, describe, import_run, run


simulation = configure(
    "cyclotron",
    resolution="quick",
    model="both",
    boundary="fixed",
    run_name="python_conference_demo",
)

print(describe(simulation))
result = run(simulation)
data = import_run(result)
analysis = analyze(data)

print(f"Run folder: {result.output_folder}")
print(f"Maximum probability drift: {abs(analysis.probability['relativeDrift']).max():.3e}")
print(f"Maximum total-energy drift: {abs(analysis.energy['totalRelativeDrift']).max():.3e}")
