function [C,Dx_prime,Dy_prime] = fixedBoundaryCurlOperator_2D(N,params)
%FIXEDBOUNDARYCURLOPERATOR_2D Build the fixed-boundary 2D curl operator.
%   C is the vector curl assembly. DX_PRIME and DY_PRIME expose the interior
%   first-derivative blocks used to construct it. This operator is 2D only.
%This function is used to create the curl operator for a fixed boundary
%simulation, which is only used in the Maxwell Solver.

newStart = 2*N.x +2;
Nsqr = N.x * N.y;
Ncube = N.x * N.y * N.z;


Nx_prime = (N.x - 2);
Ny_prime = (N.y - 2);

Nsqr_prime = Nx_prime * Ny_prime;
mainDiag_rows = sparse(Nsqr_prime,1);

for j = 1:Ny_prime

    mainDiag_rows((1:Nx_prime) + (j-1)*Nx_prime) = ((1:Nx_prime)+ newStart) + (j-1)*N.x;

end

mainDiag_cols = mainDiag_rows;

lowerDiag_rows = mainDiag_rows;
lowerDiag_cols = mainDiag_cols - 1;

%filling in other values


Dx_prime = sparse(Ncube,Ncube);
Dx_prime = Dx_prime + sparse(mainDiag_rows,mainDiag_cols,(1/params.phys.delx_norm),Ncube,Ncube) + sparse(lowerDiag_rows,lowerDiag_cols,-1/params.phys.delx_norm,Ncube,Ncube);



%N.B., the -1 on the other end of the matrix is to get rid of the diagonal values we created in using the SPEYE function. There is probably a better wya to do this but I am lazy.....
%% Y-Block

mainDiag_rows = sparse(Nsqr_prime,1);

for j = 1:Ny_prime

    mainDiag_rows((1:Nx_prime) + (j-1)*Nx_prime) = ((1:Nx_prime)+ newStart) + (j-1)*N.x;

end

mainDiag_cols = mainDiag_rows;

lowerDiag_rows = mainDiag_rows;
lowerDiag_cols = mainDiag_cols - N.x;

Dy_prime = sparse(Ncube,Ncube);
Dy_prime = Dy_prime + sparse(mainDiag_rows,mainDiag_cols,(1/params.phys.dely_norm),Nsqr,Nsqr) + sparse(lowerDiag_rows,lowerDiag_cols,-1/params.phys.dely_norm,Nsqr,Nsqr);

%% No Z


%%

zeroMat = sparse(Ncube,Ncube);
z_Block = sparse(Ncube,Ncube);

C = [zeroMat,-1*z_Block,Dy_prime;z_Block,zeroMat,-1*Dx_prime;-1*Dy_prime,Dx_prime,zeroMat];

end
