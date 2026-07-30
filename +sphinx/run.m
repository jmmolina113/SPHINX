function result = run(sim)
%SPHINX.RUN Validate, prepare, execute, and record a SPHINX simulation.
%   RESULT = SPHINX.RUN(SIM) runs a problem structure created by
%   SPHINX.PROBLEM. RESULT contains completion status, output location,
%   timing, Git revision, snapshot count, and iterative-solver diagnostics.
%
%   RESULT = SPHINX.RUN("cyclotron") runs the named preset directly.
%   Each run writes a timestamped folder containing manifest.json,
%   result.json, and S, F, and V snapshots. Nonzero BICGSTAB flags produce
%   status "completed_with_solver_warnings" and a MATLAB warning.

if nargin == 0
    sim = sphinx.problem("cyclotron");
elseif ischar(sim) || isstring(sim)
    sim = sphinx.problem(sim);
end

sim = sphinx.validateProblem(sim);
previewReport = sphinx.preview(sim,false);
rootFolder = fileparts(fileparts(mfilename('fullpath')));
solverFolder = fullfile(rootFolder,'matlabSolver');
addpath(solverFolder)
coreProvenance = sphinx.coreIntegrity(rootFolder);
if coreProvenance.classification ~= "SPHINX-CERTIFIED"
    warning('SPHINX:CoreIntegrity', ...
        '%s: %s. Results must not be represented as produced by the official SPHINX numerical core.', ...
        coreProvenance.classification,coreProvenance.reason)
end

[psi,A,Y,V,R,params] = sphinx.prepare(sim);

runIdentifier = string(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
params.save.saveLocation = string(sim.output.root) + filesep;
params.save.simName = string(sim.output.name) + filesep;
params.save.saveDate = runIdentifier;
params.save.saveFrequency = sim.output.every;

outputFolder = fullfile(sim.output.root,"Runs",sim.output.name,runIdentifier);
mkdir(outputFolder)
mkdir(fullfile(outputFolder,"S"))
mkdir(fullfile(outputFolder,"F"))
mkdir(fullfile(outputFolder,"V"))

startedAt = string(datetime('now','Format','yyyy-MM-dd''T''HH:mm:ss.SSSXXX'));

if sim.output.writeManifest
    manifest.schemaVersion = sim.schemaVersion;
    manifest.status = "running";
    manifest.startedAt = startedAt;
    manifest.problem = sim;
    manifest.preview = previewReport;
    manifest.matlabVersion = string(version);
    manifest.sourceRevision = gitRevision(rootFolder);
    manifest.coreProvenance = coreProvenance;
    writeJson(fullfile(outputFolder,"manifest.json"),manifest)
end

startTimer = tic;
solverResult = schrodingerMaxwellSolver_v16(psi,A,Y,V,R,params);
elapsedSeconds = toc(startTimer);

if solverResult.converged
    result.status = "completed";
else
    result.status = "completed_with_solver_warnings";
end

result.problem = sim.name;
result.outputFolder = string(outputFolder);
result.startedAt = startedAt;
result.finishedAt = string(datetime('now','Format','yyyy-MM-dd''T''HH:mm:ss.SSSXXX'));
result.elapsedSeconds = elapsedSeconds;
result.stepsCompleted = length(R.t)-1;
result.savedSnapshots = 1 + floor((length(R.t)-1)/sim.output.every);
result.sourceRevision = gitRevision(rootFolder);
result.coreProvenance = coreProvenance;
result.solver = solverResult;
result.postProductionCommand = "data = sphinx.post.importRun(result);";

if ~solverResult.converged
    warning('SPHINX:SolverConvergence', ...
        'One or more iterative solves did not converge. Inspect result.solver and manifest.json.')
end

if sim.output.writeManifest
    manifest.status = result.status;
    manifest.finishedAt = result.finishedAt;
    manifest.elapsedSeconds = result.elapsedSeconds;
    manifest.stepsCompleted = result.stepsCompleted;
    manifest.savedSnapshots = result.savedSnapshots;
    writeJson(fullfile(outputFolder,"manifest.json"),manifest)
    writeJson(fullfile(outputFolder,"result.json"),result)
end

fprintf('SPHINX run stored at:\n%s\n',outputFolder)
fprintf('Next: data = sphinx.post.importRun(result);\n')

end

function revision = gitRevision(rootFolder)
%GITREVISION Return the short Git revision for provenance reporting.

[status,output] = system('git -C "' + string(rootFolder) + '" rev-parse --short HEAD');

if status == 0
    revision = strtrim(string(output));
else
    revision = "unknown";
end

end

function writeJson(filePath,value)
%WRITEJSON Serialize a MATLAB value as indented UTF-8 JSON text.

jsonText = jsonencode(value,'PrettyPrint',true);
fileIdentifier = fopen(filePath,'w');
assert(fileIdentifier ~= -1,'Unable to open manifest file: %s',filePath)
cleanupObject = onCleanup(@() fclose(fileIdentifier));
fprintf(fileIdentifier,'%s\n',jsonText);
clear cleanupObject

end
