function sim = configure(problemName,varargin)
%SPHINX.CONFIGURE Create a problem using plain-language name-value options.
%   SIM = SPHINX.CONFIGURE("cyclotron","Resolution","quick",...) creates a
%   complete validated problem without requiring direct structure editing.
%
%   Common options include Model, Boundary, Resolution, Grid, ExtentLambda,
%   Charge, Mass, Hbar, MagneticField, Cycles, EndTime, TimePoints, SaveEvery,
%   RunName, and OutputRoot. Run SPHINX.OPTIONS to see the complete catalog.
%
%   Example:
%       sim = sphinx.configure("cyclotron", ...
%           "Resolution","quick", ...
%           "Model","both", ...
%           "Hbar",0.0069, ...
%           "RunName","advisor_demo");

if nargin == 0
    problemName = "cyclotron";
end

sim = sphinx.problem(problemName);

parser = inputParser;
parser.FunctionName = 'sphinx.configure';
parser.CaseSensitive = false;
parser.PartialMatching = false;

addParameter(parser,'Resolution',"original")
addParameter(parser,'Model',sim.model)
addParameter(parser,'Boundary',sim.boundary)
addParameter(parser,'Grid',sim.domain.grid)
addParameter(parser,'ExtentLambda',sim.domain.extentLambda)
addParameter(parser,'Charge',sim.physics.q)
addParameter(parser,'Mass',sim.physics.m)
addParameter(parser,'Hbar',sim.physics.hbar)
addParameter(parser,'SpeedOfLight',sim.physics.c)
addParameter(parser,'Permittivity',sim.physics.eps_0)
addParameter(parser,'ParticleNumber',sim.physics.N_particles)
addParameter(parser,'MagneticField',sim.physics.B_mag)
addParameter(parser,'Cycles',sim.time.cycles)
addParameter(parser,'EndTime',sim.time.endTime)
addParameter(parser,'TimePoints',sim.time.steps)
addParameter(parser,'SaveEvery',sim.output.every)
addParameter(parser,'RunName',sim.output.name)
addParameter(parser,'OutputRoot',sim.output.root)
addParameter(parser,'WriteManifest',sim.output.writeManifest)

parse(parser,varargin{:})
values = parser.Results;
provided = setdiff(string(fieldnames(values)),string(parser.UsingDefaults));

if ~ismember("Resolution",string(parser.UsingDefaults))
    sim = applyResolution(sim,string(values.Resolution));
end

if ismember("Model",provided), sim.model = string(values.Model); end
if ismember("Boundary",provided), sim.boundary = string(values.Boundary); end
if ismember("Grid",provided), sim.domain.grid = values.Grid; end
if ismember("ExtentLambda",provided), sim.domain.extentLambda = values.ExtentLambda; end
if ismember("Charge",provided), sim.physics.q = values.Charge; end
if ismember("Mass",provided), sim.physics.m = values.Mass; end
if ismember("Hbar",provided), sim.physics.hbar = values.Hbar; end
if ismember("SpeedOfLight",provided), sim.physics.c = values.SpeedOfLight; end
if ismember("Permittivity",provided), sim.physics.eps_0 = values.Permittivity; end
if ismember("ParticleNumber",provided), sim.physics.N_particles = values.ParticleNumber; end
if ismember("MagneticField",provided), sim.physics.B_mag = values.MagneticField; end
if ismember("Cycles",provided), sim.time.cycles = values.Cycles; end
if ismember("EndTime",provided), sim.time.endTime = values.EndTime; end
if ismember("TimePoints",provided), sim.time.steps = values.TimePoints; end
if ismember("SaveEvery",provided), sim.output.every = values.SaveEvery; end
if ismember("RunName",provided), sim.output.name = string(values.RunName); end
if ismember("OutputRoot",provided), sim.output.root = string(values.OutputRoot); end
if ismember("WriteManifest",provided), sim.output.writeManifest = logical(values.WriteManifest); end

sim = sphinx.validateProblem(sim);

end

function sim = applyResolution(sim,resolution)
%APPLYRESOLUTION Apply a documented grid/time convenience profile.

switch lower(resolution)
    case "quick"
        sim.domain.grid = [31,31,1];
        sim.domain.extentLambda = [-5,5;-5,5;0,0];
        sim.physics.q = 1;
        sim.physics.hbar = 1;
        sim.physics.B_mag = 1;
        sim.time.endTime = 1e-4;
        sim.time.steps = 31;
        sim.output.every = 5;

    case "standard"
        sim.domain.grid = [101,101,1];
        sim.domain.extentLambda = [-10,10;-10,10;0,0];
        sim.time.cycles = 0.25;
        sim.time.endTime = [];
        sim.time.steps = 501;
        sim.output.every = 25;

    case "original"
        sim.domain.grid = [251,251,1];
        sim.domain.extentLambda = [-4,4;-4,4;0,0];
        sim.time.cycles = 7;
        sim.time.endTime = [];
        sim.time.steps = 35001;
        sim.output.every = 100;

    case "3d_demo"
        sim.boundary = "periodic";
        sim.domain.grid = [9,9,9];
        sim.domain.extentLambda = [-2,2;-2,2;-2,2];
        sim.physics.q = 1;
        sim.physics.hbar = 1;
        sim.physics.B_mag = 1;
        sim.time.endTime = 1e-4;
        sim.time.steps = 11;
        sim.output.every = 2;

    otherwise
        error('Unknown resolution profile: %s. Use quick, standard, original, or 3d_demo.',resolution)
end

end
