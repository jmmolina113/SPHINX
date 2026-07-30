function F = reference_M_qm_electromagneticFields_v3(F,S,D,delt,time,params)
%REFERENCE_M_QM_ELECTROMAGNETICFIELDS_V3 Preserve original current coupling.
%   This renamed copy is a regression fixture and is not used in production.

%This function consitutes the one-step symplectic map for the electromagnetic fields derived from the
%discretized Hamiltonian for the quantum subsystem. Here, F_old is the
%vector F = <A,Y> for the current timestep, S is the vector = <psi_R,psi_I>
%J is the current density, G is the matrix representation of the gradient
%operator, N is the length of the field psi, fFl is the flattened field
%length, fVFL is the flattened vector field length, and delt is the time
%step-size, time is the current time-step

%%%%% EM Field Stepping %%%%%

%A does not evolve

%Y evolves through J

if params.sim.whatKindOfSim == "both"

    N = params.sim.Ngrid;

    Ncube = N.x*N.y*N.z;

    fFL = N.x * N.y * N.z; %fFL = flattened Field Length
    fVFL = 3*fFL; %fVFL = flattened Vector Field Length
    
    J = sparse(1,fVFL); %%filled in later

    A = squeeze(F((time),1:fVFL))';

    psi_R_half = 0.5*(S((time-1),1:(Ncube))+S(time,1:(Ncube)))';
    psi_I_half = 0.5*(S((time-1),((Ncube)+1):2*(Ncube))+S(time,((Ncube)+1):2*(Ncube)))';
    
    J(1,:) = calculateJ(psi_R_half,psi_I_half,A,D,params,fFL);
 
    F(time,(1:fVFL)+fVFL)  = F((time),(1:fVFL)+fVFL)  + delt * J;

end

end
