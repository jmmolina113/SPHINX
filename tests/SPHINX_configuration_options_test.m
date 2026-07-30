function results = SPHINX_configuration_options_test()
%SPHINX_CONFIGURATION_OPTIONS_TEST Verify the advisor-facing setup helpers.

catalog = sphinx.options(false);
assert(height(catalog.models) == 3)
assert(height(catalog.boundaries) == 2)
assert(height(catalog.resolutions) == 4)

quickProblem = sphinx.configure("cyclotron", ...
    "Resolution","quick", ...
    "Model","QM", ...
    "Hbar",0.01, ...
    "RunName","configuration_test");

assert(quickProblem.model == "QM")
assert(quickProblem.physics.hbar == 0.01)
assert(isequal(quickProblem.domain.grid,[31,31,1]))
assert(quickProblem.time.steps == 31)

lightweightPreview = sphinx.preview(quickProblem,0);
assert(~isfield(lightweightPreview,'initializationFigures'))

summary = sphinx.describe(quickProblem,false);
assert(summary.dimension == 2)
assert(summary.outputName == "configuration_test")

twoDimensionalPreview = sphinx.preview(quickProblem,false, ...
    "ShowFields",true,"FigureVisible","off");
assert(length(twoDimensionalPreview.initializationFigures) == 2)
assert(all(isgraphics(twoDimensionalPreview.initializationFigures,'figure')))
close(twoDimensionalPreview.initializationFigures)

threeDimensionalProblem = sphinx.configure("cyclotron", ...
    "Resolution","3d_demo", ...
    "RunName","configuration_3d_test");

assert(threeDimensionalProblem.boundary == "periodic")
assert(isequal(threeDimensionalProblem.domain.grid,[9,9,9]))
assert(threeDimensionalProblem.physics.hbar == 1)

threeDimensionalPreview = sphinx.preview(threeDimensionalProblem,false, ...
    "ShowFields",true,"FigureVisible","off");
assert(length(threeDimensionalPreview.initializationFigures) == 2)
assert(all(isgraphics(threeDimensionalPreview.initializationFigures,'figure')))
close(threeDimensionalPreview.initializationFigures)

oneDimensionalProblem = sphinx.problem("cyclotron");
oneDimensionalProblem.boundary = "periodic";
oneDimensionalProblem.physics.q = 1;
oneDimensionalProblem.physics.hbar = 1;
oneDimensionalProblem.domain.grid = [9,1,1];
oneDimensionalProblem.domain.extentLambda = [-2,2;0,0;0,0];
oneDimensionalProblem.time.endTime = 1e-4;
oneDimensionalProblem.time.steps = 5;

oneDimensionalPreview = sphinx.preview(oneDimensionalProblem,false, ...
    "ShowFields",true,"FigureVisible","off");
assert(oneDimensionalPreview.dimension == 1)
assert(length(oneDimensionalPreview.initializationFigures) == 2)
assert(all(isgraphics(oneDimensionalPreview.initializationFigures,'figure')))
close(oneDimensionalPreview.initializationFigures)

results.quick = quickProblem;
results.periodic_1D = oneDimensionalProblem;
results.periodic_3D = threeDimensionalProblem;
results.pass = true;

end
