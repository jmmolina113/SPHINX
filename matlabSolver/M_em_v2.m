function [F,solverInfo] = M_em_v2(F,Q,M,delt,time,params,L_fac,U_fac)
%M_EM_V2 Apply one electromagnetic Cayley-map substep.
%   The map advances F = <A,Y> unless the selected mode is QM-only. Optional
%   ILU factors permit reuse of the constant electromagnetic preconditioner.
%   SOLVERINFO reports the BICGSTAB flag, residual, and iteration count.
%This function consitutes the one-step symplectic map derived from the
%discretized Hamiltonian for the electromagnetic subsystem. Here, F is the
%vector F = <A,Y>, Q is the matrix defined in equation (50) in the Chen
%2017 paper, M is the length of Q, delt is the time step-size,
%and time is the current time-step



if params.sim.whatKindOfSim == "QM"

    F(time,:) = F((time-1),:);
    solverInfo.flag = 0;
    solverInfo.relativeResidual = 0;
    solverInfo.iterations = 0;
else

    Q_minus = (speye(M)-delt*0.5*Q);
    Q_plus = (speye(M)+delt*0.5*Q);

    if nargin < 8 || isempty(L_fac) || isempty(U_fac)
        [L_fac,U_fac] = ilu(Q_minus);
    end

    [F_new,flag,relativeResidual,iterations] = bicgstab(Q_minus,Q_plus*transpose(F((time-1),:)),1e-8,1000,L_fac,U_fac);
    F(time,:) = F_new;
    solverInfo.flag = flag;
    solverInfo.relativeResidual = relativeResidual;
    solverInfo.iterations = iterations;

end



end
