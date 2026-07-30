function S = reference_M_qm_quantumFields_v3(S,F,G,L,T,V_op,fFL,fVFL,delt,time,params)
%REFERENCE_M_QM_QUANTUMFIELDS_V3 Preserve the original QM map for comparison.
%   This renamed copy is a regression fixture and is not used in production.

%This function consitutes the one-step symplectic map for the quantum fields derived from the
%discretized Hamiltonian for the quantum subsystem. Here, S_old is the
%current time step of S = <psi_R, psi_I> we want to evolve, F is the vector
%F = <A,Y>, G is the matrix representation of the gradient operator, L is
%the matrix representation of the laplacian operator, T is the transpose of
%L, fFL is the length of the flattened scalar field, fVFL is the length of
%the flattened vector field delt is the size of
%the temporal timestep, and time is the current timestep

%%%%% QM Field Stepping %%%%%

if params.sim.whatKindOfSim == "EM"
        
    S(time,:) = S((time-1),:);

else

    O = sparse(2*fFL,2*fFL);

    xRange = (1:fFL)+0;
    yRange = (1:fFL)+fFL;
    zRange = (1:fFL)+2*fFL;

    Ax = squeeze(F((time-1),xRange));
    Ay = squeeze(F((time-1),yRange));
    Az = squeeze(F((time-1),zRange));

    hMatrix = makeHmatrix_v4(G,F((time-1),1:fVFL)) ;
    AdotG = transpose(Ax) .* G(xRange,:) + transpose(Ay) .* G(yRange,:) + transpose(Az) .* G(zRange,:);

    Asqr = sparse((1:fFL),(1:fFL),(Ax.^2 + Ay.^2 + Az.^2));


    o_para = params.sim.C1 * (AdotG - hMatrix);
    o_perp = params.sim.C2 * (L + T) - (params.sim.C3 * Asqr + params.sim.C4 * V_op);

    O = [o_para,-1*o_perp;1*o_perp,o_para;];

    if isequal(-1*O,transpose(O)) ~= 1
        %%This checks if this matrix is skew
        %symmetric

        error('\Omega matrix is not skew symmetric')

    end
    O_plus = speye(2*fFL) + 0.5 * delt * O;

    O_minus = speye(2*fFL) - 0.5 * delt * O;

    [L_fac,U_fac] = ilu(O_minus);


    %disp('Calculating Cay[Ω(A) Δt/2]...')
    S(time,:) = bicgstab(O_minus,O_plus*transpose(S((time-1),:)),1e-8,1000,L_fac,U_fac);

end


end
