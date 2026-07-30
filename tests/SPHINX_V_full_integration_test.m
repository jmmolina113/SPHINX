function results = SPHINX_V_full_integration_test()
%SPHINX_V_FULL_INTEGRATION_TEST Compare rolling and reference map sequences.
%   The suite advances fixed-2D and periodic-3D problems in EM, QM, and both
%   modes for three steps and compares final states and saved output.

rootFolder = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(rootFolder,'matlabSolver'))
addpath(fullfile(rootFolder,'tests','reference'))

rng(17,'twister');

testCases = {
    struct('name',"fixed_2D",'numDim',2,'boundaryCondition',"fixed",'Ngrid',struct('x',5,'y',5,'z',1)), ...
    struct('name',"periodic_3D",'numDim',3,'boundaryCondition',"periodic",'Ngrid',struct('x',4,'y',4,'z',4)) ...
};

simulationKinds = ["EM","QM","both"];
results = struct('caseName',{},'simulationKind',{},'em_error',{},'qm_error',{},'pass',{});
resultIndex = 0;

for caseIndex = 1:length(testCases)
    for simulationIndex = 1:length(simulationKinds)
        resultIndex = resultIndex + 1;
        results(resultIndex) = runCase(testCases{caseIndex},simulationKinds(simulationIndex),resultIndex);
    end
end

assert(all([results.pass]),'SPHINX_V full integration test failed')

end

function result = runCase(testCase,simulationKind,resultIndex)
%RUNCASE Execute one reference-versus-rolling regression case.

params.sim.numDim = testCase.numDim;
params.sim.whatKindOfSim = simulationKind;
params.sim.boundaryCondition = testCase.boundaryCondition;
params.sim.Ngrid = testCase.Ngrid;
params = importParams_phys(params);
params = importParams_sim(params);

N = params.sim.Ngrid;

R.x = linspace(-1,1,N.x);
R.y = linspace(-1,1,N.y);

if N.z == 1
    R.z = 0;
    R.delz = 1;
else
    R.z = linspace(-1,1,N.z);
    R.delz = abs(R.z(end)-R.z(end-1));
end

R.t = 0:3;
R.delx = abs(R.x(end)-R.x(end-1));
R.dely = abs(R.y(end)-R.y(end-1));
R.delt = 1e-4;

params.phys.delx_norm = R.delx/params.phys.lambda;
params.phys.dely_norm = R.dely/params.phys.lambda;
params.phys.delz_norm = R.delz/params.phys.lambda;
params.phys.delt_norm = R.delt/params.phys.tau;

shape = [N.y,N.x,N.z];
psi.R = rand(shape);
psi.I = rand(shape);
A.x = rand(shape);
A.y = rand(shape);
A.z = rand(shape);
Y.x = rand(shape);
Y.y = rand(shape);
Y.z = rand(shape);
V = rand(shape);

[S_reference,F_reference,V_flat,V_op] = reference_flattenFields(psi,A,Y,V,R);

fFL = N.x*N.y*N.z;
fVFL = 3*fFL;
[G,C,L,T,D] = importDifferentialOperators(N,params,fFL);

if params.sim.boundaryCondition == "fixed"
    CtC = fixedBoundaryCurlCurlOperator_2D(N,params);
else
    CtC = transpose(C)*C;
end

zeroMat = sparse(fVFL,fVFL);
Q = [zeroMat,params.sim.C_Y*speye(fVFL);-params.sim.C_A*CtC,zeroMat];

[boundaryValueIndices,F_boundaryVals] = boundaryValues(F_reference,N,params);

for time = 2:length(R.t)
    F_reference = reference_M_em_v2(F_reference,Q,2*fVFL,params.phys.delt_norm,time,params);

    if params.sim.boundaryCondition == "fixed"
        F_reference(time,boundaryValueIndices) = F_boundaryVals;
    end

    S_reference = reference_M_qm_quantumFields_v3(S_reference,F_reference,G,L,T,V_op,fFL,fVFL,params.phys.delt_norm,time,params);
    F_reference = reference_M_qm_electromagneticFields_v3(F_reference,S_reference,D,params.phys.delt_norm,time,params);
end

testFolder = string(tempname);
mkdir(testFolder)
cleanupObject = onCleanup(@() rmdir(testFolder,'s'));

params.save.saveLocation = testFolder + "/";
params.save.simName = "case_" + resultIndex + "/";
params.save.saveDate = "test";
params.save.saveFrequency = 1;

schrodingerMaxwellSolver_v16(psi,A,Y,V,R,params)

outputFolder = testFolder + "/Runs/" + params.save.simName + params.save.saveDate;
S_optimized = readmatrix(outputFolder + "/S/S_0000003.txt");
F_optimized = readmatrix(outputFolder + "/F/F_0000003.txt");

result.caseName = testCase.name;
result.simulationKind = simulationKind;
result.em_error = norm(F_reference(end,:)-F_optimized)/max(1,norm(F_reference(end,:)));
result.qm_error = norm(S_reference(end,:)-S_optimized)/max(1,norm(S_reference(end,:)));
result.pass = result.em_error < 1e-7 && result.qm_error < 1e-7;

fprintf('%s %s EM relative error: %.3e QM relative error: %.3e PASS: %d\n', ...
    result.caseName,result.simulationKind,result.em_error,result.qm_error,result.pass);

clear cleanupObject

end

function [boundaryValueIndices,F_boundaryVals] = boundaryValues(F,N,params)
%BOUNDARYVALUES Reproduce the original fixed-2D boundary mask for testing.

Nsqr = N.x*N.y;
logicalIndices = zeros(Nsqr,"logical");

for col = 1:N.x
    for row = 1:N.y
        if (col<3)||(row<3)
            linearIndex = col + (row-1)*N.x;
            logicalIndices(linearIndex) = true;
        end
    end
end

boundaryValueIndices = [logicalIndices;logicalIndices;logicalIndices;logicalIndices;logicalIndices;logicalIndices;];

if params.sim.boundaryCondition == "fixed"
    F_boundaryVals = F(1,boundaryValueIndices);
else
    F_boundaryVals = [];
end

end
