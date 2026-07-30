rootFolder = fileparts(fileparts(mfilename('fullpath')));
addpath(rootFolder)

sim = sphinx.problem("cyclotron");

sim.domain.grid = [51,51,1];
sim.time.steps = 101;
sim.output.every = 10;
sim.output.name = "cyclotron_quickstart";

sphinx.preview(sim);
result = sphinx.run(sim);

disp(result)
