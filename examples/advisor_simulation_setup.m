%% SPHINX advisor-ready simulation setup
% Edit only the choices in the block below. The rest of this file validates,
% explains, previews, and runs the requested quantum simulation.

rootFolder = fileparts(fileparts(mfilename('fullpath')));
addpath(rootFolder)
setupSPHINX;

%% EDIT ONLY THIS BLOCK

problemType = "cyclotron";

resolution = "quick";       % "quick", "standard", "original", or "3d_demo"
model = "both";              % "EM", "QM", or "both"
boundary = "fixed";          % Use "periodic" with resolution = "3d_demo"

charge = -1;                 % Prime cyclotron reference value
mass = 1;
hbar = 1;
magneticField = 10;         % Prime cyclotron reference value

runName = "advisor_cyclotron_demo";

%% BUILD AND EXPLAIN THE SIMULATION

sim = sphinx.configure(problemType, ...
    "Resolution",resolution, ...
    "Model",model, ...
    "Boundary",boundary, ...
    "Charge",charge, ...
    "Mass",mass, ...
    "Hbar",hbar, ...
    "MagneticField",magneticField, ...
    "RunName",runName);

sphinx.describe(sim);
sphinx.preview(sim);

%% RUN
% Comment out the next line if you only want to inspect the proposed setup.

result = sphinx.run(sim);

%% CHECK THE RESULT

disp(result.status)
disp(result.outputFolder)
disp(result.solver.converged)
