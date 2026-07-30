function result = SPHINX_demo
%SPHINX_DEMO Run a small simulation and its complete analysis workflow.
%   RESULT = SPHINX_DEMO configures a fast coupled 2D cyclotron run, previews
%   and executes it, imports every snapshot, computes all standard
%   diagnostics, and creates a CSV diagnostic summary. Plot and movie
%   products remain selectable through SPHINX.POST.PRODUCE afterward.

rootFolder = setupSPHINX();

sim = sphinx.configure("cyclotron", ...
    "Resolution","quick", ...
    "Model","both", ...
    "Boundary","fixed", ...
    "RunName","conference_demo", ...
    "OutputRoot",fullfile(rootFolder,"output"));

sphinx.describe(sim);
sphinx.preview(sim);
result = sphinx.run(sim);

data = sphinx.post.importRun(result);
analysis = sphinx.post.analyze(data);
result.postProductionFiles = sphinx.post.produce(data,analysis, ...
    "summary");

fprintf('\nSPHINX demo complete.\n')
fprintf('Run folder:\n%s\n',result.outputFolder)

end
