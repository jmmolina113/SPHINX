function CtC = fixedBoundaryCurlCurlOperator_2D(N,params)
%FIXEDBOUNDARYCURLCURLOPERATOR_2D Build the fixed 2D curl-curl operator.
%   CTC acts on flattened three-component vector potentials and incorporates
%   the original interior fixed-boundary difference construction.

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

secondLowerDiag_rows = mainDiag_rows;
secondLowerDiag_cols = mainDiag_cols - 2;
%filling in other values


Dxx = sparse(Ncube,Ncube);
Dxx = Dxx + sparse(mainDiag_rows,mainDiag_cols,1/(params.phys.delx_norm)^2,Ncube,Ncube) ... 
    + sparse(lowerDiag_rows,lowerDiag_cols,-2/(params.phys.delx_norm)^2,Ncube,Ncube) ...
    + sparse(secondLowerDiag_rows,secondLowerDiag_cols,1/(params.phys.delx_norm)^2,Ncube,Ncube);



%N.B., the -1 on the other end of the matrix is to get rid of the diagonal values we created in using the SPEYE function. There is probably a better wya to do this but I am lazy.....
%% Y-Block

mainDiag_rows = sparse(Nsqr_prime,1);

for j = 1:Ny_prime

    mainDiag_rows((1:Nx_prime) + (j-1)*Nx_prime) = ((1:Nx_prime)+ newStart) + (j-1)*N.x;

end

mainDiag_cols = mainDiag_rows;

lowerDiag_rows = mainDiag_rows;
lowerDiag_cols = mainDiag_cols - N.x;

secondLowerDiag_rows = mainDiag_rows;
secondLowerDiag_cols = mainDiag_cols - 2*N.x;


Dyy = sparse(Ncube,Ncube);
Dyy = Dyy + sparse(mainDiag_rows,mainDiag_cols,1/(params.phys.dely_norm)^2,Nsqr,Nsqr) ... 
+ sparse(lowerDiag_rows,lowerDiag_cols,-2/(params.phys.dely_norm)^2,Nsqr,Nsqr) ... 
+ sparse(secondLowerDiag_rows,secondLowerDiag_cols,1/(params.phys.dely_norm)^2,Nsqr,Nsqr) ;

%% Cross term

%Dx part
mainDiag_rows = sparse(Nsqr_prime,1);

for j = 1:Ny_prime

    mainDiag_rows((1:Nx_prime) + (j-1)*Nx_prime) = ((1:Nx_prime)+ newStart) + (j-1)*N.x;

end

mainDiag_cols = mainDiag_rows;

lowerDiag_rows = mainDiag_rows;
lowerDiag_cols = mainDiag_cols - 1;

%filling in other values


Dx = sparse(Ncube,Ncube);
Dx = Dx + sparse(lowerDiag_rows,lowerDiag_cols,-1/(params.phys.delx_norm * params.phys.dely_norm),Ncube,Ncube);



%Dy part

mainDiag_cols = mainDiag_rows;

lowerDiag_rows = mainDiag_rows;
lowerDiag_cols = mainDiag_cols - N.x;

Dy = sparse(Ncube,Ncube);
Dy = Dy + sparse(lowerDiag_rows,lowerDiag_cols,-1/(params.phys.delx_norm * params.phys.dely_norm),Nsqr,Nsqr);


%Cross term part


crossDiag_rows = mainDiag_rows;
crossDiag_cols = mainDiag_cols - N.x - 1;


Dxy = sparse(Ncube,Ncube);
Dxy = Dxy + sparse(mainDiag_rows,mainDiag_rows,1/(params.phys.delx_norm * params.phys.dely_norm),Ncube,Ncube) + Dx + Dy  + sparse(crossDiag_rows,crossDiag_cols,1/(params.phys.delx_norm * params.phys.dely_norm),Ncube,Ncube);


%%

zeroMat = sparse(Ncube,Ncube);

CtC = [Dyy,-1*Dxy,zeroMat;-1*Dxy,Dxx,zeroMat;zeroMat,zeroMat,(Dxx + Dyy)];


end
