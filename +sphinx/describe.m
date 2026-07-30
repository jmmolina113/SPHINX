function summary = describe(sim,displaySummary)
%SPHINX.DESCRIBE Explain a simulation configuration in plain language.
%   SUMMARY = SPHINX.DESCRIBE(SIM) validates SIM, prints an advisor-readable
%   description, and returns the same interpreted information as a structure.
%
%   SUMMARY = SPHINX.DESCRIBE(SIM,FALSE) suppresses terminal output.

if nargin < 2
    displaySummary = true;
end

if ischar(sim) || isstring(sim)
    sim = sphinx.problem(sim);
end

sim = sphinx.validateProblem(sim);
previewReport = sphinx.preview(sim,false);

modelDescriptions.EM = "electromagnetic fields only; the wavefunction is frozen";
modelDescriptions.QM = "the quantum wavefunction only; electromagnetic fields are frozen";
modelDescriptions.both = "the coupled Schrodinger-Maxwell system";

if sim.boundary == "fixed"
    boundaryDescription = "fixed boundaries using the original 2D operator";
else
    boundaryDescription = "periodic boundaries";
end

if isempty(sim.time.endTime)
    durationDescription = sprintf('%.6g cyclotron periods',sim.time.cycles);
else
    durationDescription = sprintf('physical time %.6g',sim.time.endTime);
end

summary.problem = sim.name;
summary.evolution = modelDescriptions.(char(sim.model));
summary.boundary = boundaryDescription;
summary.dimension = previewReport.dimension;
summary.grid = sim.domain.grid;
summary.extentLambda = sim.domain.extentLambda;
summary.duration = string(durationDescription);
summary.timePoints = sim.time.steps;
summary.saveEvery = sim.output.every;
summary.snapshots = previewReport.snapshots;
summary.outputName = sim.output.name;
summary.outputRoot = sim.output.root;
summary.estimatedRollingMemory = previewReport.rollingStateBytes;
summary.estimatedAvoidedHistory = previewReport.avoidedHistoryBytes;

if displaySummary
    fprintf('\nSPHINX EXPERIMENT DESCRIPTION\n')
    fprintf('=============================\n')
    fprintf('This simulation evolves %s.\n',summary.evolution)
    fprintf('It uses %s in %d spatial dimensions.\n',summary.boundary,summary.dimension)
    fprintf('The grid contains %d x %d x %d points.\n',summary.grid)
    fprintf('The x domain is [%.4g, %.4g] lambda.\n',summary.extentLambda(1,:))
    fprintf('The y domain is [%.4g, %.4g] lambda.\n',summary.extentLambda(2,:))
    fprintf('The z domain is [%.4g, %.4g] lambda.\n',summary.extentLambda(3,:))
    fprintf('The duration is %s using %d time points.\n',summary.duration,summary.timePoints)
    fprintf('A snapshot is requested every %d integration steps (%d total).\n',summary.saveEvery,summary.snapshots)
    fprintf('The run will be stored as "%s" under:\n%s\n',summary.outputName,summary.outputRoot)
    fprintf('Run sphinx.preview(sim) for detailed memory estimates.\n\n')
end

end
