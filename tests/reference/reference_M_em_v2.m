function F = reference_M_em_v2(F,Q,M,delt,time,params)
%REFERENCE_M_EM_V2 Preserve the original electromagnetic map for comparison.
%   This renamed copy is a regression fixture and is not used in production.
%This function consitutes the one-step symplectic map derived from the
%discretized Hamiltonian for the electromagnetic subsystem. Here, F is the
%vector F = <A,Y>, Q is the matrix defined in equation (50) in the Chen
%2017 paper, M is the length of Q, delt is the time step-size,
%and time is the current time-step



if params.sim.whatKindOfSim == "QM"

    F(time,:) = F((time-1),:);
else

    Q_minus = (speye(M)-delt*0.5*Q);
    Q_plus = (speye(M)+delt*0.5*Q);

    [L_fac,U_fac] = ilu(Q_minus);

    F(time,:) = bicgstab(Q_minus,Q_plus*transpose(F((time-1),:)),1e-8,1000,L_fac,U_fac);

end



end
