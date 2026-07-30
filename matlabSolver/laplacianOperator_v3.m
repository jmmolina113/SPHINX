function L = laplacianOperator_v3(N,delx,dely,delz,params)
%LAPLACIANOPERATOR_V3 Build the sparse scalar Laplacian operator.
%   N supplies [Nx,Ny,Nz] through fields x, y, and z. Grid spacings are in
%   normalized units, and PARAMS.NUMDIM selects the 1D, 2D, or 3D branch.

Ncube = N.x * N.y * N.z;
Nsqr = N.x * N.y;

L_x = sparse(Ncube,Ncube);
L_y = sparse(Ncube,Ncube);
L_z = sparse(Ncube,Ncube);


if params.numDim == 1

    %% Filling X-values
    upperDiagRows = (1:N.x:(Ncube-(N.x-1)))';
    upperDiagCols = (N.x:N.x:(Ncube))';
    upperDiagVals = -2*ones(size(upperDiagCols));

    upperDiagRows_L = upperDiagRows;
    upperDiagCols_L = upperDiagCols - 1;
    upperDiagVals_L = 1*ones(size(upperDiagCols_L));

    upperDiagRows_D = upperDiagRows + 1;
    upperDiagCols_D = upperDiagCols;
    upperDiagVals_D = 1*ones(size(upperDiagCols_D));

    lowerDiagRows_1 = zeros(Ncube/(N.x)*(N.x-1),1);
    lowerDiagCols_1 = zeros(Ncube/(N.x)*(N.x-1),1);
    lowerDiagVals_1 = -2*ones(size(lowerDiagCols_1));

    block=0;
    for i = 0:(Ncube/N.x-1)
        lowerDiagRows_1((1:(N.x-1))+block*(N.x-1)) = (2:N.x)' + i*N.x;
        lowerDiagCols_1((1:(N.x-1))+block*(N.x-1)) = (1:(N.x-1))' + i*N.x;
        block = block + 1;
    end

    lowerDiagRows_2 = zeros(Ncube/(N.x)*(N.x-2),1);
    lowerDiagCols_2 = zeros(Ncube/(N.x)*(N.x-2),1);
    lowerDiagVals_2 = 1*ones(size(lowerDiagCols_2));

    block=0;
    for i = 0:(Ncube/N.x-1)
        lowerDiagRows_2((1:(N.x-2))+block*(N.x-2)) = (3:N.x)' + i*N.x;
        lowerDiagCols_2((1:(N.x-2))+block*(N.x-2)) = (1:(N.x-2))' + i*N.x;
        block = block + 1;
    end

    L_x = (1/delx)^2*speye(Ncube);
    L_x = L_x + (1/delx)^2*sparse(upperDiagRows,upperDiagCols,upperDiagVals,Ncube,Ncube) ...
        + (1/delx)^2*sparse(upperDiagRows_L,upperDiagCols_L,upperDiagVals_L,Ncube,Ncube) ...
        + (1/delx)^2*sparse(upperDiagRows_D,upperDiagCols_D,upperDiagVals_D,Ncube,Ncube) ...
        + (1/delx)^2*sparse(lowerDiagRows_1,lowerDiagCols_1,lowerDiagVals_1,Ncube,Ncube) ...
        + (1/delx)^2*sparse(lowerDiagRows_2,lowerDiagCols_2,lowerDiagVals_2,Ncube,Ncube);


elseif params.numDim == 2

    %% Filling X-values
    upperDiagRows = (1:N.x:(Ncube-(N.x-1)))';
    upperDiagCols = (N.x:N.x:(Ncube))';
    upperDiagVals = -2*ones(size(upperDiagCols));

    upperDiagRows_L = upperDiagRows;
    upperDiagCols_L = upperDiagCols - 1;
    upperDiagVals_L = 1*ones(size(upperDiagCols_L));

    upperDiagRows_D = upperDiagRows + 1;
    upperDiagCols_D = upperDiagCols;
    upperDiagVals_D = 1*ones(size(upperDiagCols_D));

    lowerDiagRows_1 = zeros(Ncube/(N.x)*(N.x-1),1);
    lowerDiagCols_1 = zeros(Ncube/(N.x)*(N.x-1),1);
    lowerDiagVals_1 = -2*ones(size(lowerDiagCols_1));

    block=0;
    for i = 0:(Ncube/N.x-1)
        lowerDiagRows_1((1:(N.x-1))+block*(N.x-1)) = (2:N.x)' + i*N.x;
        lowerDiagCols_1((1:(N.x-1))+block*(N.x-1)) = (1:(N.x-1))' + i*N.x;
        block = block + 1;
    end

    lowerDiagRows_2 = zeros(Ncube/(N.x)*(N.x-2),1);
    lowerDiagCols_2 = zeros(Ncube/(N.x)*(N.x-2),1);
    lowerDiagVals_2 = 1*ones(size(lowerDiagCols_2));

    block=0;
    for i = 0:(Ncube/N.x-1)
        lowerDiagRows_2((1:(N.x-2))+block*(N.x-2)) = (3:N.x)' + i*N.x;
        lowerDiagCols_2((1:(N.x-2))+block*(N.x-2)) = (1:(N.x-2))' + i*N.x;
        block = block + 1;
    end

    L_x = (1/delx)^2*speye(Ncube);
    L_x = L_x + (1/delx)^2*sparse(upperDiagRows,upperDiagCols,upperDiagVals,Ncube,Ncube) ...
        + (1/delx)^2*sparse(upperDiagRows_L,upperDiagCols_L,upperDiagVals_L,Ncube,Ncube) ...
        + (1/delx)^2*sparse(upperDiagRows_D,upperDiagCols_D,upperDiagVals_D,Ncube,Ncube) ...
        + (1/delx)^2*sparse(lowerDiagRows_1,lowerDiagCols_1,lowerDiagVals_1,Ncube,Ncube) ...
        + (1/delx)^2*sparse(lowerDiagRows_2,lowerDiagCols_2,lowerDiagVals_2,Ncube,Ncube);

    %% Filling Y-values

    upperDiagRows_1 = zeros(N.x*N.z,1);
    upperDiagCols_1 = zeros(N.x*N.z,1);
    upperDiagVals_1 = -2*ones(size(upperDiagCols_1));

    upperDiagRows_2 = zeros(2*N.x*N.z,1);
    upperDiagCols_2 = zeros(2*N.x*N.z,1);
    upperDiagVals_2 = 1*ones(size(upperDiagCols_2));

    block=0;
    for i = 0:(N.z-1)
        upperDiagRows_1((1:(N.x))+block*N.x) = (1:N.x)' + i*Nsqr;
        upperDiagCols_1((1:(N.x))+block*N.x) = ((Nsqr-N.x+1):(Nsqr))' + i*Nsqr;

        upperDiagRows_2((1:2*N.x)+block*(2*N.x)) = (1:2*N.x)' + i*Nsqr;
        upperDiagCols_2((1:2*N.x)+block*(2*N.x)) = ((Nsqr-(2*N.x-1)):Nsqr)' + i*Nsqr;

        block = block + 1;
    end

    lowerDiagRows_1 = zeros(N.x*(N.y-1)*N.z,1);
    lowerDiagCols_1 = zeros(N.x*(N.y-1)*N.z,1);
    lowerDiagVals_1 = -2*ones(size(lowerDiagCols_1));

    lowerDiagRows_2 = zeros(N.x*(N.y-2)*N.z,1);
    lowerDiagCols_2 = zeros(N.x*(N.y-2)*N.z,1);
    lowerDiagVals_2 = 1*ones(size(lowerDiagRows_2));

    block=0;
    for i = 0:(N.z-1)
        lowerDiagRows_1((1:(Nsqr-N.x))+block*(Nsqr-N.x)) = ((N.x+1):Nsqr)' + i*Nsqr;
        lowerDiagCols_1((1:(Nsqr-N.x))+block*(Nsqr-N.x)) = (1:(Nsqr-N.x))' + i*Nsqr;

        lowerDiagRows_2((1:(Nsqr-2*N.x))+block*(Nsqr-2*N.x)) = ((2*N.x+1):Nsqr)' + i*Nsqr;
        lowerDiagCols_2((1:(Nsqr-2*N.x))+block*(Nsqr-2*N.x)) = (1:(Nsqr-2*N.x))' + i*Nsqr;
        block = block + 1;
    end


    L_y = (1/dely)^2*speye(Ncube);
    L_y = L_y + (1/dely)^2*sparse(upperDiagRows_1,upperDiagCols_1,upperDiagVals_1,Ncube,Ncube) ...
        + (1/dely)^2*sparse(upperDiagRows_2,upperDiagCols_2,upperDiagVals_2,Ncube,Ncube) ...
        + (1/dely)^2*sparse(lowerDiagRows_1,lowerDiagCols_1,lowerDiagVals_1,Ncube,Ncube) ...
        + (1/dely)^2*sparse(lowerDiagRows_2,lowerDiagCols_2,lowerDiagVals_2,Ncube,Ncube);


elseif params.numDim == 3
    
    %% Filling X-values
    upperDiagRows = (1:N.x:(Ncube-(N.x-1)))';
    upperDiagCols = (N.x:N.x:(Ncube))';
    upperDiagVals = -2*ones(size(upperDiagCols));

    upperDiagRows_L = upperDiagRows;
    upperDiagCols_L = upperDiagCols - 1;
    upperDiagVals_L = 1*ones(size(upperDiagCols_L));

    upperDiagRows_D = upperDiagRows + 1;
    upperDiagCols_D = upperDiagCols;
    upperDiagVals_D = 1*ones(size(upperDiagCols_D));

    lowerDiagRows_1 = zeros(Ncube/(N.x)*(N.x-1),1);
    lowerDiagCols_1 = zeros(Ncube/(N.x)*(N.x-1),1);
    lowerDiagVals_1 = -2*ones(size(lowerDiagCols_1));

    block=0;
    for i = 0:(Ncube/N.x-1)
        lowerDiagRows_1((1:(N.x-1))+block*(N.x-1)) = (2:N.x)' + i*N.x;
        lowerDiagCols_1((1:(N.x-1))+block*(N.x-1)) = (1:(N.x-1))' + i*N.x;
        block = block + 1;
    end

    lowerDiagRows_2 = zeros(Ncube/(N.x)*(N.x-2),1);
    lowerDiagCols_2 = zeros(Ncube/(N.x)*(N.x-2),1);
    lowerDiagVals_2 = 1*ones(size(lowerDiagCols_2));

    block=0;
    for i = 0:(Ncube/N.x-1)
        lowerDiagRows_2((1:(N.x-2))+block*(N.x-2)) = (3:N.x)' + i*N.x;
        lowerDiagCols_2((1:(N.x-2))+block*(N.x-2)) = (1:(N.x-2))' + i*N.x;
        block = block + 1;
    end

    L_x = (1/delx)^2*speye(Ncube);
    L_x = L_x + (1/delx)^2*sparse(upperDiagRows,upperDiagCols,upperDiagVals,Ncube,Ncube) ...
        + (1/delx)^2*sparse(upperDiagRows_L,upperDiagCols_L,upperDiagVals_L,Ncube,Ncube) ...
        + (1/delx)^2*sparse(upperDiagRows_D,upperDiagCols_D,upperDiagVals_D,Ncube,Ncube) ...
        + (1/delx)^2*sparse(lowerDiagRows_1,lowerDiagCols_1,lowerDiagVals_1,Ncube,Ncube) ...
        + (1/delx)^2*sparse(lowerDiagRows_2,lowerDiagCols_2,lowerDiagVals_2,Ncube,Ncube);

    %% Filling Y-values

    upperDiagRows_1 = zeros(N.x*N.z,1);
    upperDiagCols_1 = zeros(N.x*N.z,1);
    upperDiagVals_1 = -2*ones(size(upperDiagCols_1));

    upperDiagRows_2 = zeros(2*N.x*N.z,1);
    upperDiagCols_2 = zeros(2*N.x*N.z,1);
    upperDiagVals_2 = 1*ones(size(upperDiagCols_2));

    block=0;
    for i = 0:(N.z-1)
        upperDiagRows_1((1:(N.x))+block*N.x) = (1:N.x)' + i*Nsqr;
        upperDiagCols_1((1:(N.x))+block*N.x) = ((Nsqr-N.x+1):(Nsqr))' + i*Nsqr;

        upperDiagRows_2((1:2*N.x)+block*(2*N.x)) = (1:2*N.x)' + i*Nsqr;
        upperDiagCols_2((1:2*N.x)+block*(2*N.x)) = ((Nsqr-(2*N.x-1)):Nsqr)' + i*Nsqr;

        block = block + 1;
    end

    lowerDiagRows_1 = zeros(N.x*(N.y-1)*N.z,1);
    lowerDiagCols_1 = zeros(N.x*(N.y-1)*N.z,1);
    lowerDiagVals_1 = -2*ones(size(lowerDiagCols_1));

    lowerDiagRows_2 = zeros(N.x*(N.y-2)*N.z,1);
    lowerDiagCols_2 = zeros(N.x*(N.y-2)*N.z,1);
    lowerDiagVals_2 = 1*ones(size(lowerDiagRows_2));

    block=0;
    for i = 0:(N.z-1)
        lowerDiagRows_1((1:(Nsqr-N.x))+block*(Nsqr-N.x)) = ((N.x+1):Nsqr)' + i*Nsqr;
        lowerDiagCols_1((1:(Nsqr-N.x))+block*(Nsqr-N.x)) = (1:(Nsqr-N.x))' + i*Nsqr;

        lowerDiagRows_2((1:(Nsqr-2*N.x))+block*(Nsqr-2*N.x)) = ((2*N.x+1):Nsqr)' + i*Nsqr;
        lowerDiagCols_2((1:(Nsqr-2*N.x))+block*(Nsqr-2*N.x)) = (1:(Nsqr-2*N.x))' + i*Nsqr;
        block = block + 1;
    end


    L_y = (1/dely)^2*speye(Ncube);
    L_y = L_y + (1/dely)^2*sparse(upperDiagRows_1,upperDiagCols_1,upperDiagVals_1,Ncube,Ncube) ...
        + (1/dely)^2*sparse(upperDiagRows_2,upperDiagCols_2,upperDiagVals_2,Ncube,Ncube) ...
        + (1/dely)^2*sparse(lowerDiagRows_1,lowerDiagCols_1,lowerDiagVals_1,Ncube,Ncube) ...
        + (1/dely)^2*sparse(lowerDiagRows_2,lowerDiagCols_2,lowerDiagVals_2,Ncube,Ncube);

    %% Filling Z-values
    upperDiagRows_1 = (1:Nsqr)';
    upperDiagCols_1 = ((Ncube-(Nsqr-1)):Ncube)';
    upperDiagVals_1 = -2*ones(size(upperDiagCols_1));

    upperDiagRows_2 = (1:2*Nsqr)';
    upperDiagCols_2 = ((Ncube-(2*Nsqr-1)):Ncube)';
    upperDiagVals_2 = 1*ones(size(upperDiagCols_2));

    lowerDiagRows_1 = ((Nsqr+1):Ncube)';
    lowerDiagCols_1 = (1:(Ncube-(Nsqr)))';
    lowerDiagVals_1 = -2*ones(size(lowerDiagCols_1));

    lowerDiagRows_2 = ((2*Nsqr+1):Ncube)';
    lowerDiagCols_2 = (1:(Ncube-(2*Nsqr)))';
    lowerDiagVals_2 = 1*ones(size(lowerDiagCols_2));

    L_z = (1/delz)^2*speye(Ncube);
    L_z = L_z + (1/delz)^2*sparse(upperDiagRows_1,upperDiagCols_1,upperDiagVals_1,Ncube,Ncube) ...
        + (1/delz)^2*sparse(upperDiagRows_2,upperDiagCols_2,upperDiagVals_2,Ncube,Ncube) ...
        + (1/delz)^2*sparse(lowerDiagRows_1,lowerDiagCols_1,lowerDiagVals_1,Ncube,Ncube) ...
        + (1/delz)^2*sparse(lowerDiagRows_2,lowerDiagCols_2,lowerDiagVals_2,Ncube,Ncube);

end




%% Putting it all together

L = L_x + L_y + L_z;



end
