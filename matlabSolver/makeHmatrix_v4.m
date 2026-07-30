function Hprime=makeHmatrix_v4(G,A_flat)
%MAKEHMATRIX_V4 Construct the transposed A-weighted gradient contribution.
%   HPRIME represents the term required by the quantum generator when the
%   flattened vector potential A_FLAT multiplies component gradient blocks.

Ncube = size(G,2);

Hprime = sparse(Ncube,Ncube);

xRange = 1:Ncube;
yRange = xRange + Ncube;
zRange = yRange + Ncube;

Ax = A_flat(xRange);
Ay = A_flat(yRange);
Az = A_flat(zRange);


%The following transposes occur by definition of the partial/partial psi
%term in equation 34 of the original Chen 2017 paper 
G_transX = transpose(G(xRange,:));
G_transY = transpose(G(yRange,:));
G_transZ = transpose(G(zRange,:));

Hprime = Ax .* G_transX + Ay .* G_transY + Az .* G_transZ;

end


% for J = 1:Ncube
% 
%     Hprime(J,:) = A_flat(1,xRange) .* G_transX(J,:) + A_flat(1,yRange) .* G_transY(J,:) + A_flat(1,zRange) .* G_transZ(J,:);
% 
% end
