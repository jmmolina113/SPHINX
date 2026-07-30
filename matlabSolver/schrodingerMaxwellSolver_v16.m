function solverResult = schrodingerMaxwellSolver_v16(psi,A,Y,V,R,params)
%SCHRODINGERMAXWELLSOLVER_V16 Advance the split Schrodinger-Maxwell system.
%   SOLVERRESULT = SCHRODINGERMAXWELLSOLVER_V16(PSI,A,Y,V,R,PARAMS) builds
%   the discrete operators, flattens the initial fields, applies the EM and
%   QM symplectic maps, enforces supported boundaries, and writes requested
%   snapshots. Two rolling state rows replace the original full history.
%
%   SOLVERRESULT records BICGSTAB flags, residuals, iterations, and aggregate
%   convergence. Fixed boundaries support 2D; periodic boundaries support
%   1D, 2D, and 3D.
%% Pre-simulation Assertions
logic = ((params.sim.boundaryCondition == "fixed") & (params.sim.numDim == 2)) | (params.sim.boundaryCondition == "periodic");
message = "This code only supports fixed boundary conditions in 2D and periodic boundary conditions in 1D, 2D, or 3D";
assert(logic,message)

if params.sim.Ngrid.x ~= params.sim.Ngrid.y
    logic = (params.sim.boundaryCondition ~= "fixed");
    message = "This code only supports non-uniform grids for periodic boundary conditions";
    assert(logic,message)
end



%% Dimensional Reshaping and Pre-Calculation

N.x = size(A.x,2);
N.y = size(A.x,1);
N.z = size(A.x,3);

Nsqr = N.x*N.y;
Ncube = N.x*N.y*N.z;

t = R.t;
fFL = Ncube; %fFL = flattened Field Length
fVFL = 3*fFL; %fVFL = flattened Vector Field Length

%%%%% Creation of Operator Matrices %%%%%

[G,C,L,T,D] = importDifferentialOperators(N,params,fFL);

if params.sim.boundaryCondition == "fixed"
    CtC = fixedBoundaryCurlCurlOperator_2D(N,params);
else
    CtC = transpose(C) * C;
end

%%%%% Flattening Fields %%%%%

[S,F,V_flat,V_op] = flattenFields(psi,A,Y,V,R);

%%%%% Creation of Relevant EM Stepping Matrices %%%%%
zeroMat = sparse(fVFL,fVFL);
upperRight = params.sim.C_Y * eye(fVFL,'like',sparse(fVFL));
lowerLeft = -1* params.sim.C_A * CtC;

Q = [zeroMat,upperRight;lowerLeft, zeroMat;];

Q_minus = (speye(2*fVFL)-params.phys.delt_norm*0.5*Q);

if params.sim.whatKindOfSim ~= "QM"
    [L_fac,U_fac] = ilu(Q_minus);
else
    L_fac = [];
    U_fac = [];
end

%Saving first timestep
saveTimeStep(params.save,1,S,F,V_flat)
saveStep = params.save.saveFrequency + 1;

%% Actual stepping section

logicalIndices = zeros(Nsqr,"logical");

for col = 1:length(R.x)
    for row = 1:length(R.y)
        if (col<3)||(row<3)
            % linearIndex = col + (row-1)*N.x + (slice-1) * N.y * N.x; % 3D Linear Index
            linearIndex = col + (row-1)*N.x;
            logicalIndices(linearIndex) = true;
        end
    end
end

boundaryValueIndices = [logicalIndices;logicalIndices;logicalIndices;logicalIndices;logicalIndices;logicalIndices;];

F_boundaryVals = F(1,boundaryValueIndices);

solverResult.emFlag = zeros(length(t)-1,1);
solverResult.emRelativeResidual = zeros(length(t)-1,1);
solverResult.emIterations = zeros(length(t)-1,1);
solverResult.qmFlag = zeros(length(t)-1,1);
solverResult.qmRelativeResidual = zeros(length(t)-1,1);
solverResult.qmIterations = zeros(length(t)-1,1);

for time = 2:(length(t))

    stateTime = 2;


    %% H_EM Stepping
    %%%%% EM Field Stepping %%%%%

    [F,emSolverInfo] = M_em_v2(F,Q,2*fVFL,params.phys.delt_norm,stateTime,params,L_fac,U_fac);
    solverResult.emFlag(time-1) = emSolverInfo.flag;
    solverResult.emRelativeResidual(time-1) = emSolverInfo.relativeResidual;
    solverResult.emIterations(time-1) = emSolverInfo.iterations;

    if params.sim.boundaryCondition == "fixed"
        F(stateTime,boundaryValueIndices) = F_boundaryVals;
    end

    %%%%% QM Field Stepping %%%%%
    %S does not evolve

    %% H_QM Stepping

    %%%%% QM Field Stepping %%%%%

    [S,qmSolverInfo] = M_qm_quantumFields_v3(S,F,G,L,T,V_op,fFL,fVFL,params.phys.delt_norm,stateTime,params);
    solverResult.qmFlag(time-1) = qmSolverInfo.flag;
    solverResult.qmRelativeResidual(time-1) = qmSolverInfo.relativeResidual;
    solverResult.qmIterations(time-1) = qmSolverInfo.iterations;

    %%%%% EM Field Stepping %%%%%

    %A does not evolve

    %Y evolves through J

    F = M_qm_electromagneticFields_v3(F,S,D,params.phys.delt_norm,stateTime,params);

    %% Save data

    if time == saveStep
        displayMessage = "Saving Time Step " + num2str(time-1);
        disp(displayMessage)
        saveTimeStep(params.save,time,S,F,V_flat,stateTime)
        saveStep = saveStep + params.save.saveFrequency;
    end

    S(1,:) = S(stateTime,:);
    F(1,:) = F(stateTime,:);

end

solverResult.converged = all(solverResult.emFlag == 0) && all(solverResult.qmFlag == 0);
solverResult.maximumRelativeResidual = max([solverResult.emRelativeResidual;solverResult.qmRelativeResidual]);

disp('All Done! :^)')

end
