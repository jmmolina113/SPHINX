# SPHINX post-production suite

The post-production API replaces the experiment-specific `workingScript*`
workflow with three explicit stages:

```matlab
data = sphinx.post.importRun(runFolder);
analysis = sphinx.post.analyze(data);
files = sphinx.post.produce(data,analysis,["summary","conservation"]);
```

A run is completely imported and validated before the user chooses which
diagnostics, figures, tables, or movies to create.

## Start here

```matlab
setupSPHINX
sphinx.post.options
edit examples/advisor_postproduction.m
```

## Import

`sphinx.post.importRun` accepts either the result returned by `sphinx.run` or
the run folder. By default it imports every snapshot and derives the complex
wavefunction, probability, `A`, `Y`, `B`, `E`, electric and probability
currents, canonical momentum, and Poynting flux.

For a subset of a large run:

```matlab
data = sphinx.post.importRun(runFolder,"Snapshots",[0,100,200]);
```

## Exact 3D ordering

The convention is centralized in `sphinx.post.flatten` and
`sphinx.post.unflatten`:

- Scalar fields are `[Ny,Nx,Nz]`; histories are `[time,Ny,Nx,Nz]`.
- Flattened scalars have `x` varying fastest, followed by `y`, then `z`.
- Vector components are contiguous: `[x,y,z]`.
- `S = [psi_R,psi_I]` and `F = [A_x,A_y,A_z,Y_x,Y_y,Y_z]`.

The exact inverse is:

```matlab
field = permute(reshape(vector,[Nx,Ny,Nz]),[2,1,3]);
```

Several historical importers used a direct reshape whose orientation error
was hidden when `Nx == Ny`. The new importer round-trip checks every primary
field by default and fails if its order differs from the solver.

## Analyze

```matlab
analysis = sphinx.post.analyze(data,"Diagnostics", ...
    ["probability","energy","field_statistics"]);
```

The output contains probability and conservation drift; electromagnetic,
quantum, and total energies; magnetic, electric, quantum-gradient,
vector-potential-coupling, and potential terms; plus optional field statistics.
The default integral covers the full active domain. A physical-coordinate box
may be supplied as `[xmin xmax; ymin ymax; zmin zmax]`.

## Produce files

```matlab
files = sphinx.post.produce(data,analysis, ...
    ["summary","conservation","energy_breakdown", ...
     "snapshot","lineout","movie","workspace"], ...
    "Field","probability","Plane","z", ...
    "Coordinate",0,"Snapshot","last");
```

Outputs go to the run's `processedData` folder unless `OutputFolder` is given.
Run `help sphinx.post.produce` for all slice, lineout, and movie controls.

## Historical mapping

| Historical responsibility | Supported replacement |
|---|---|
| `importSimulationData_v*` | `sphinx.post.importRun` |
| `postProcessing_v3` | `sphinx.post.analyze` |
| `performancePlot` | `produce(...,"conservation")` |
| `breakdownPlot` | `produce(...,"energy_breakdown")` |
| `fieldMovies_2D*` | `produce(...,"movie")` with `Field` |
| lineout scripts | `produce(...,"lineout")` |
| `workingScript*` | `examples/advisor_postproduction.m` |

The original scripts remain unchanged as provenance. Experiment-specific
theory comparisons and hard-coded boundary studies remain historical until
their physical assumptions are promoted into named, validated modules.

## Python equivalent

The separate Python package exposes the same three stages:

```python
from sphinx_solver import analyze, import_run, produce

data = import_run(run_folder)
analysis = analyze(data)
files = produce(data, analysis, ["summary", "conservation"])
```

It supports the same imported field families, diagnostics, integration box,
field catalog, and seven product categories. Python uses snake-case keyword
arguments, zero-based snapshot indices when an integer is not a saved step,
and a compressed `postproduction.npz` workspace. Install `./python[plots]` for
PNG and MP4 products; the movie dependency supplies its own FFmpeg executable.
