function J = calculateJ(psi_R,psi_I,A,D,params,fFL)
%CALCULATEJ Evaluate the three-component discrete quantum current.
%   PSI_R and PSI_I are midpoint wavefunction vectors, A is the flattened
%   vector potential, D contains component gradient matrices, and PARAMS
%   supplies the normalized current-coupling coefficients.

psi_sqrd = sparse((1:fFL),(1:fFL),(psi_R.^2 + psi_I.^2));

d=0;
gradPsi_R = D.x * (psi_R);
gradPsi_I = D.x * (psi_I);
termOne = psi_R .* gradPsi_I;
termTwo = psi_I .* gradPsi_R;
termThree = psi_sqrd * A((1:fFL)+d*fFL);

Jx  = (params.sim.C_JQ*termOne - params.sim.C_JQ*termTwo - params.sim.C_JA*termThree);
d=1;
gradPsi_R = D.y * (psi_R);
gradPsi_I = D.y * (psi_I);
termOne = psi_R .* gradPsi_I;
termTwo = psi_I .* gradPsi_R;
termThree = psi_sqrd * A((1:fFL)+d*fFL);
Jy  = (params.sim.C_JQ*termOne - params.sim.C_JQ*termTwo - params.sim.C_JA*termThree);

d=2;
gradPsi_R = D.z * (psi_R);
gradPsi_I = D.z * (psi_I);
termOne = psi_R .* gradPsi_I;
termTwo = psi_I .* gradPsi_R;
termThree = psi_sqrd * A((1:fFL)+d*fFL);
Jz  = (params.sim.C_JQ*termOne - params.sim.C_JQ*termTwo - params.sim.C_JA*termThree);

J = [Jx;Jy;Jz;];

end
