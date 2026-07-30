function [psi,A,Y,V,R,params] = prepare(sim)
%SPHINX.PREPARE Materialize fields, coordinates, and normalized parameters.
%   [PSI,A,Y,V,R,PARAMS] = SPHINX.PREPARE(SIM) validates SIM, derives the
%   physical and numerical coefficients, builds the space-time grid, and
%   constructs the selected initial condition. It does not advance time or
%   write output.
%
%   PSI contains real and imaginary wavefunction components. A and Y contain
%   x, y, and z electromagnetic components. V is the scalar potential, R is
%   the coordinate structure, and PARAMS is the legacy solver structure.

if ischar(sim) || isstring(sim)
    sim = sphinx.problem(sim);
end

sim = sphinx.validateProblem(sim);
rootFolder = fileparts(fileparts(mfilename('fullpath')));
solverFolder = fullfile(rootFolder,'matlabSolver');
addpath(solverFolder)

params.sim.numDim = sum(sim.domain.grid > 1);
params.sim.whatKindOfSim = sim.model;
params.sim.boundaryCondition = sim.boundary;

params = importParams_phys(params);
physicsFields = fieldnames(sim.physics);

for fieldIndex = 1:length(physicsFields)
    fieldName = physicsFields{fieldIndex};
    params.phys.(fieldName) = sim.physics.(fieldName);
end

params = importParams_sim(params);

params.sim.Ngrid.x = sim.domain.grid(1);
params.sim.Ngrid.y = sim.domain.grid(2);
params.sim.Ngrid.z = sim.domain.grid(3);

coordinateNames = ["x","y","z"];

for dimensionIndex = 1:3
    coordinateName = coordinateNames(dimensionIndex);
    numberOfPoints = sim.domain.grid(dimensionIndex);
    limits = sim.domain.extentLambda(dimensionIndex,:)*params.phys.lambda;

    if numberOfPoints == 1
        R.(coordinateName) = mean(limits);
        R.("del" + coordinateName) = params.phys.lambda;
    else
        R.(coordinateName) = linspace(limits(1),limits(2),numberOfPoints);
        R.("del" + coordinateName) = abs(R.(coordinateName)(end)-R.(coordinateName)(end-1));
    end
end

cyclotronPeriod = 2*pi/(abs(params.phys.q)*(abs(sim.physics.B_mag)*params.phys.A_0/params.phys.lambda)/params.phys.m);

if isempty(sim.time.endTime)
    finalTime = sim.time.cycles*cyclotronPeriod;
else
    finalTime = sim.time.endTime;
end

R.t = linspace(0,finalTime,sim.time.steps);
R.delt = abs(R.t(end)-R.t(end-1));

params.phys.delx_norm = R.delx/params.phys.lambda;
params.phys.dely_norm = R.dely/params.phys.lambda;
params.phys.delz_norm = R.delz/params.phys.lambda;
params.phys.delt_norm = R.delt/params.phys.tau;

[psi,A,Y,V,params] = initializeCyclotron(R,params);

end

function [psi,A,Y,V,params] = initializeCyclotron(R,params)
%INITIALIZECYCLOTRON Construct the cyclotron preset's initial fields.
%   The vector potential uses the symmetric gauge, Y and V begin at zero,
%   and the complex wave packet is extruded uniformly through active z
%   slices. Returned fields use the solver's normalized units.

shape = [length(R.y),length(R.x),length(R.z)];

A.x = zeros(shape);
A.y = zeros(shape);
A.z = zeros(shape);

Y.x = zeros(shape);
Y.y = zeros(shape);
Y.z = zeros(shape);

[Rx,Ry] = meshgrid(R.x,R.y);

for k = 1:length(R.z)
    A.x(:,:,k) = -1/2 * params.phys.B_mag * params.phys.hbar/(params.phys.lambda^2) * Ry;
    A.y(:,:,k) =  1/2 * params.phys.B_mag * params.phys.hbar/(params.phys.lambda^2) * Rx;
end

A.x = A.x/params.phys.A_0;
A.y = A.y/params.phys.A_0;
A.z = A.z/params.phys.A_0;

Y.x = Y.x/params.phys.Y_0;
Y.y = Y.y/params.phys.Y_0;
Y.z = Y.z/params.phys.Y_0;

V = zeros(shape);
V = V/params.phys.Epsilon;

params.sim.zPos = ceil(length(R.z)/2);
params.sim.yPos = ceil(length(R.y)/2);
params.phys.delta = sqrt(params.phys.hbar/(abs(params.phys.q)*(abs(params.phys.B_mag)*params.phys.A_0/params.phys.lambda)));
params.phys.x0 = 3.75*max(R.x)/10;
params.phys.y0 = 0;

expArg = Rx.^2 + Ry.^2 + params.phys.x0^2 + params.phys.y0^2 ...
    - 2*(Rx+1i*Ry)*(params.phys.x0-1i*params.phys.y0);
psiSlice = exp(-1/(4*params.phys.delta^2)*expArg);
psiFull = zeros(shape);

for k = 1:length(R.z)
    psiFull(:,:,k) = psiSlice;
end

params.phys.N_norm = sqrt(params.phys.N_particles) ...
    / sqrt(pi*2*params.phys.hbar/(abs(params.phys.q)*(params.phys.A_0/params.phys.lambda)));

psi.R = sqrt(2)*params.phys.N_norm*real(psiFull)/params.phys.psi_0;
psi.I = sqrt(2)*params.phys.N_norm*imag(psiFull)/params.phys.psi_0;

end
