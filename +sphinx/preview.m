function report = preview(sim,varargin)
%SPHINX.PREVIEW Validate a problem and estimate its storage requirements.
%   REPORT = SPHINX.PREVIEW(SIM) prints and returns grid, time, snapshot,
%   rolling-state memory, avoided-history memory, and minimum numeric-output
%   estimates. It does not allocate simulation fields or operators.
%
%   REPORT = SPHINX.PREVIEW(SIM,FALSE) suppresses terminal output.
%   REPORT = SPHINX.PREVIEW(SIM,"ShowFields",TRUE) also materializes and
%   displays the initialized fields. The plots adapt to 1D, 2D, and 3D.
%   Figure handles are returned in REPORT.initializationFigures.
%   "FigureVisible" may be "on" or "off" for scripted use.
%   SIM may be a problem structure or a preset name accepted by
%   SPHINX.PROBLEM.

displayReport = true;

if ~isempty(varargin) && isBooleanScalar(varargin{1})
    displayReport = logical(varargin{1});
    varargin(1) = [];
end

parser = inputParser;
parser.FunctionName = 'sphinx.preview';
addParameter(parser,'ShowFields',false,@isBooleanScalar)
addParameter(parser,'FigureVisible',"on",@(value) any(strcmpi(string(value),["on","off"])))
parse(parser,varargin{:})
options = parser.Results;

if ischar(sim) || isstring(sim)
    sim = sphinx.problem(sim);
end

sim = sphinx.validateProblem(sim);

gridSize = sim.domain.grid;
numberOfGridPoints = prod(gridSize);
numberOfTimePoints = sim.time.steps;
numberOfSnapshots = 1 + floor((numberOfTimePoints-1)/sim.output.every);

rollingStateBytes = 8 * 16 * numberOfGridPoints;
originalHistoryBytes = 8 * 8 * numberOfGridPoints * numberOfTimePoints;
minimumSnapshotBytes = 8 * 8 * numberOfGridPoints * numberOfSnapshots;

report.name = sim.name;
report.model = sim.model;
report.boundary = sim.boundary;
report.dimension = sum(gridSize > 1);
report.grid = gridSize;
report.timePoints = numberOfTimePoints;
report.snapshots = numberOfSnapshots;
report.rollingStateBytes = rollingStateBytes;
report.originalHistoryBytes = originalHistoryBytes;
report.avoidedHistoryBytes = max(0,originalHistoryBytes-rollingStateBytes);
report.minimumSnapshotBytes = minimumSnapshotBytes;
report.outputRoot = sim.output.root;
report.valid = true;

if options.ShowFields
    report.initializationFigures = sphinx.plotInitialization(sim, ...
        "FigureVisible",options.FigureVisible);
end

if displayReport
    fprintf('\nSPHINX PREVIEW\n')
    fprintf('==============\n')
    fprintf('Problem:                 %s\n',sim.name)
    fprintf('Model:                   %s\n',sim.model)
    fprintf('Boundary:                %s\n',sim.boundary)
    fprintf('Grid:                    %d x %d x %d\n',gridSize)
    fprintf('Time points:             %d\n',numberOfTimePoints)
    fprintf('Saved snapshots:         %d\n',numberOfSnapshots)
    fprintf('Rolling state memory:    %s\n',formatBytes(rollingStateBytes))
    fprintf('Original history memory: %s\n',formatBytes(originalHistoryBytes))
    fprintf('Avoided history memory:  %s\n',formatBytes(report.avoidedHistoryBytes))
    fprintf('Minimum numeric output:  %s\n',formatBytes(minimumSnapshotBytes))
    fprintf('Output root:             %s\n\n',sim.output.root)
end

end

function valid = isBooleanScalar(value)
%ISBOOLEANSCALAR Accept logical values and numeric zero or one.

valid = isscalar(value) && (islogical(value) || ...
    (isnumeric(value) && isfinite(value) && any(value == [0,1])));

end

function output = formatBytes(numberOfBytes)
%FORMATBYTES Convert a byte count to a compact binary-unit string.

units = ["B","KiB","MiB","GiB","TiB"];
unitIndex = 1;
value = double(numberOfBytes);

while value >= 1024 && unitIndex < length(units)
    value = value/1024;
    unitIndex = unitIndex + 1;
end

output = sprintf('%.2f %s',value,units(unitIndex));

end
