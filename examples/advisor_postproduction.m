%% SPHINX advisor-ready post-production
% First select a completed simulation. Then select only the products you
% want to create. SPHINX imports and validates the entire run before any
% analysis begins.

rootFolder = fileparts(fileparts(mfilename('fullpath')));
addpath(rootFolder)
setupSPHINX;

%% EDIT ONLY THIS BLOCK

runFolder = fullfile(rootFolder,"output","Runs", ...
    "advisor_cyclotron_demo","REPLACE_WITH_RUN_TIMESTAMP");

products = ["summary","conservation","energy_breakdown","snapshot"];

field = "probability";      % Run sphinx.post.options to see all fields
plane = "z";                % "x", "y", or "z"
planeCoordinate = 0;
snapshot = "last";          % "first", "middle", "last", step, or index

%% IMPORT THE COMPLETE RUN

data = sphinx.post.importRun(runFolder);

%% CHOOSE AND COMPUTE DIAGNOSTICS

analysis = sphinx.post.analyze(data,"Diagnostics","all");

%% CREATE THE REQUESTED FILES

files = sphinx.post.produce(data,analysis,products, ...
    "Field",field, ...
    "Plane",plane, ...
    "Coordinate",planeCoordinate, ...
    "Snapshot",snapshot);

disp(files)
