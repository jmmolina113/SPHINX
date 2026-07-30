function [G,C,L,T,D] = importDifferentialOperators(N,params,fFL)
%IMPORTDIFFERENTIALOPERATORS Build the operators required by the split maps.
%   G is the stacked gradient, C the selected curl, L the Laplacian, T=L',
%   and D contains component views of G used by the current calculation.
%This function imports our differential operators, and keeps the main
%function clean. If boundary conditions are fixed we will use 

G = gradientOperator_v3(N,params.phys.delx_norm,params.phys.dely_norm,params.phys.delz_norm,params.sim);
L= laplacianOperator_v3(N,params.phys.delx_norm,params.phys.dely_norm,params.phys.delz_norm,params.sim);
T = transpose(L);

if params.sim.boundaryCondition == "fixed"
    C = fixedBoundaryCurlOperator_2D(N,params);
else
    C = curlOperator_v3(N,params.phys.delx_norm,params.phys.dely_norm,params.phys.delz_norm,params.sim);
end



d=0;
D.x = G((1:fFL)+d*fFL,:);
d=1;
D.y = G((1:fFL)+d*fFL,:);
d=2;
D.z = G((1:fFL)+d*fFL,:);

end
