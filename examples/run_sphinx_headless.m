function result = run_sphinx_headless
%RUN_SPHINX_HEADLESS Run SPHINX without a desktop or display server.
%   Set SPHINX_OUTPUT_ROOT before launching MATLAB. Set
%   SPHINX_PREVIEW_ONLY=1 to export initialized fields without advancing.

exampleFolder = fileparts(mfilename('fullpath'));
rootFolder = fileparts(exampleFolder);
addpath(rootFolder)
setupSPHINX;

outputRoot = string(getenv('SPHINX_OUTPUT_ROOT'));
assert(strlength(outputRoot) > 0, ...
    ['SPHINX_OUTPUT_ROOT is required. Point it to writable scratch or ' ...
     'project storage before launching the job.'])

previewOnlyValue = lower(strtrim(string(getenv('SPHINX_PREVIEW_ONLY'))));
previewOnly = any(previewOnlyValue == ["1","true","yes"]);

%% EDIT THE SCIENTIFIC SETUP HERE
sim = sphinx.configure("cyclotron", ...
    "Resolution","standard", ...
    "Model","both", ...
    "Boundary","fixed", ...
    "RunName","headless_cyclotron", ...
    "OutputRoot",outputRoot, ...
    "WriteManifest",true);

%% VALIDATE, PREVIEW, AND EXPORT INITIAL FIELDS
sim = sphinx.validateProblem(sim);
sphinx.describe(sim);
storageReport = sphinx.preview(sim);
fieldReport = sphinx.preview(sim,false, ...
    "ShowFields",true, "FigureVisible","off");

jobIdentifier = string(getenv('SLURM_JOB_ID'));
if strlength(jobIdentifier) == 0
    jobIdentifier = string(datetime('now','Format','yyyyMMdd_HHmmss'));
end
previewFolder = fullfile(outputRoot,"initialization_preview", ...
    sim.output.name + "_" + jobIdentifier);
if ~isfolder(previewFolder), mkdir(previewFolder), end

figureCleanup = onCleanup(@() closeValidFigures(fieldReport.initializationFigures));
exportgraphics(fieldReport.initializationFigures(1), ...
    fullfile(previewFolder,"quantum_initialization.png"), "Resolution",200);
exportgraphics(fieldReport.initializationFigures(2), ...
    fullfile(previewFolder,"electromagnetic_initialization.png"), "Resolution",200);
save(fullfile(previewFolder,"initialization_preview.mat"), ...
    "sim","storageReport")
fprintf('Initialization preview stored at:\n%s\n',previewFolder)

if previewOnly
    result.status = "preview_only";
    result.problem = sim.name;
    result.previewFolder = string(previewFolder);
    result.outputFolder = "";
    fprintf('SPHINX_PREVIEW_ONLY is enabled; the solver was not advanced.\n')
else
    result = sphinx.run(sim);
    fprintf('SPHINX status: %s\n',result.status)
    fprintf('SPHINX output: %s\n',result.outputFolder)
    if ~result.solver.converged
        error('SPHINX:HeadlessSolverWarnings', ...
            'The run completed with solver warnings. Inspect the run manifest.')
    end
end
clear figureCleanup
end

function closeValidFigures(figures)
validFigures = figures(isgraphics(figures,'figure'));
if ~isempty(validFigures), close(validFigures), end
end
