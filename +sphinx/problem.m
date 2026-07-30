function sim = problem(problemName)
%SPHINX.PROBLEM Create a complete SPHINX experiment definition.
%   SIM = SPHINX.PROBLEM("cyclotron") returns the validated configuration
%   schema used by SPHINX.PREVIEW, SPHINX.PREPARE, and SPHINX.RUN. Edit the
%   returned structure to define a particular experiment; the preset itself
%   remains unchanged.
%
%   See also SPHINX.PREVIEW, SPHINX.PREPARE, SPHINX.RUN,
%   SPHINX.VALIDATEPROBLEM.

if nargin == 0
    problemName = "cyclotron";
end

problemName = lower(string(problemName));
rootFolder = fileparts(fileparts(mfilename('fullpath')));

switch problemName
    case "cyclotron"
        sim.schemaVersion = 1;
        sim.name = "cyclotron";
        sim.model = "both";
        sim.boundary = "fixed";
        sim.initialCondition = "cyclotron";

        sim.physics.q = -1;
        sim.physics.m = 1;
        sim.physics.hbar = 1;
        sim.physics.c = 0.01;
        sim.physics.eps_0 = 1/(4*pi);
        sim.physics.N_particles = 1;
        sim.physics.B_mag = 10;

        sim.domain.grid = [251,251,1];
        sim.domain.extentLambda = [-4,4;-4,4;0,0];

        sim.time.cycles = 7;
        sim.time.endTime = [];
        sim.time.steps = 35001;

        sim.output.root = fullfile(rootFolder,"output");
        sim.output.name = "cyclotron";
        sim.output.every = 100;
        sim.output.writeManifest = true;

    otherwise
        error('Unknown SPHINX problem preset: %s',problemName)
end

end
