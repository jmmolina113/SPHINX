function G = gradientOperator_v3(N,delx,dely,delz,params)
%GRADIENTOPERATOR_V3 Build the sparse stacked discrete gradient.
%   The returned matrix maps a flattened scalar field to concatenated x, y,
%   and z derivatives. PARAMS.NUMDIM selects the active dimensional branch.

Ncube = N.x * N.y * N.z;
Nsqr = N.x * N.y;

x_Block = sparse(Ncube,Ncube);
y_Block = sparse(Ncube,Ncube);
z_Block = sparse(Ncube,Ncube);

if params.numDim == 1

    %% X-block

    upperDiagRows = (1:N.x:(Ncube-(N.x-1)))';
    upperDiagCols = (N.x:N.x:(Ncube))';
    upperDiagVals = -1*ones(size(upperDiagCols));

    lowerDiagRows = zeros(Ncube/(N.x)*(N.x-1),1);
    lowerDiagCols = zeros(Ncube/(N.x)*(N.x-1),1);
    lowerDiagVals = -1*ones(size(lowerDiagCols));

    block=0;
    for i = 0:(Ncube/N.x-1)
        lowerDiagRows((1:(N.x-1))+block*(N.x-1)) = (2:N.x)' + i*N.x;
        lowerDiagCols((1:(N.x-1))+block*(N.x-1)) = (1:(N.x-1))' + i*N.x;
        block = block + 1;
    end


        x_Block = x_Block + (1/delx)*speye(Ncube);
    x_Block = x_Block + (1/delx)*sparse(upperDiagRows,upperDiagCols,upperDiagVals,Ncube,Ncube) ...
        + (1/delx)*sparse(lowerDiagRows,lowerDiagCols,lowerDiagVals,Ncube,Ncube);

elseif params.numDim == 2

  
    %% X-block

    upperDiagRows = (1:N.x:(Ncube-(N.x-1)))';
    upperDiagCols = (N.x:N.x:(Ncube))';
    upperDiagVals = -1*ones(size(upperDiagCols));

    lowerDiagRows = zeros(Ncube/(N.x)*(N.x-1),1);
    lowerDiagCols = zeros(Ncube/(N.x)*(N.x-1),1);

    block=0;
    for i = 0:(Ncube/N.x-1)
        lowerDiagRows((1:(N.x-1))+block*(N.x-1)) = (2:N.x)' + i*N.x;
        lowerDiagCols((1:(N.x-1))+block*(N.x-1)) = (1:(N.x-1))' + i*N.x;
        block = block + 1;
    end

    lowerDiagVals = -1*ones(size(lowerDiagCols));

        x_Block = x_Block + (1/delx)*speye(Ncube);
    x_Block = x_Block + (1/delx)*sparse(upperDiagRows,upperDiagCols,upperDiagVals,Ncube,Ncube) ...
        + (1/delx)*sparse(lowerDiagRows,lowerDiagCols,lowerDiagVals,Ncube,Ncube);

    %% Y-block

    upperDiagRows = zeros(N.x*N.z,1);
    upperDiagCols = zeros(N.x*N.z,1);
    upperDiagVals = -1*ones(size(upperDiagCols));

    block=0;
    for i = 0:(N.z-1)
        upperDiagRows((1:(N.x))+block*N.x) = (1:N.x)' + i*Nsqr;
        upperDiagCols((1:(N.x))+block*N.x) = ((Nsqr-N.x+1):(Nsqr))' + i*Nsqr;
        block = block + 1;
    end

    lowerDiagRows = zeros(N.x*(N.y-1)*N.z,1);
    lowerDiagCols = zeros(N.x*(N.y-1)*N.z,1);
    lowerDiagVals = -1*ones(size(lowerDiagCols));

    block=0;
    for i = 0:(N.z-1)
        lowerDiagRows((1:(Nsqr-N.x))+block*(Nsqr-N.x)) = ((N.x+1):Nsqr)' + i*Nsqr;
        lowerDiagCols((1:(Nsqr-N.x))+block*(Nsqr-N.x)) = (1:(Nsqr-N.x))' + i*Nsqr;
        block = block + 1;
    end

    y_Block = (1/dely)*speye(Ncube);
    y_Block = y_Block+(1/dely)*sparse(upperDiagRows,upperDiagCols,upperDiagVals,Ncube,Ncube) ...
        + (1/dely)*sparse(lowerDiagRows,lowerDiagCols,lowerDiagVals,Ncube,Ncube);

elseif params.numDim == 3

    %% X-block

    upperDiagRows = (1:N.x:(Ncube-(N.x-1)))';
    upperDiagCols = (N.x:N.x:(Ncube))';
    upperDiagVals = -1*ones(size(upperDiagCols));

    lowerDiagRows = zeros(Ncube/(N.x)*(N.x-1),1);
    lowerDiagCols = zeros(Ncube/(N.x)*(N.x-1),1);

    block=0;
    for i = 0:(Ncube/N.x-1)
        lowerDiagRows((1:(N.x-1))+block*(N.x-1)) = (2:N.x)' + i*N.x;
        lowerDiagCols((1:(N.x-1))+block*(N.x-1)) = (1:(N.x-1))' + i*N.x;
        block = block + 1;
    end

    lowerDiagVals = -1*ones(size(lowerDiagCols));

        x_Block = x_Block + (1/delx)*speye(Ncube);
    x_Block = x_Block + (1/delx)*sparse(upperDiagRows,upperDiagCols,upperDiagVals,Ncube,Ncube) ...
        + (1/delx)*sparse(lowerDiagRows,lowerDiagCols,lowerDiagVals,Ncube,Ncube);

    %% Y-block

    upperDiagRows = zeros(N.x*N.z,1);
    upperDiagCols = zeros(N.x*N.z,1);
    upperDiagVals = -1*ones(size(upperDiagCols));

    block=0;
    for i = 0:(N.z-1)
        upperDiagRows((1:(N.x))+block*N.x) = (1:N.x)' + i*Nsqr;
        upperDiagCols((1:(N.x))+block*N.x) = ((Nsqr-N.x+1):(Nsqr))' + i*Nsqr;
        block = block + 1;
    end

    lowerDiagRows = zeros(N.x*(N.y-1)*N.z,1);
    lowerDiagCols = zeros(N.x*(N.y-1)*N.z,1);
    lowerDiagVals = -1*ones(size(lowerDiagCols));

    block=0;
    for i = 0:(N.z-1)
        lowerDiagRows((1:(Nsqr-N.x))+block*(Nsqr-N.x)) = ((N.x+1):Nsqr)' + i*Nsqr;
        lowerDiagCols((1:(Nsqr-N.x))+block*(Nsqr-N.x)) = (1:(Nsqr-N.x))' + i*Nsqr;
        block = block + 1;
    end

    y_Block = (1/dely)*speye(Ncube);
    y_Block = y_Block+(1/dely)*sparse(upperDiagRows,upperDiagCols,upperDiagVals,Ncube,Ncube) ...
        + (1/dely)*sparse(lowerDiagRows,lowerDiagCols,lowerDiagVals,Ncube,Ncube);


    %% Z-block

    upperDiagRows = (1:Nsqr)';
    upperDiagCols = ((Ncube-(Nsqr-1)):Ncube)';
    upperDiagVals = -1*ones(size(upperDiagCols));

    lowerDiagRows = ((Nsqr+1):Ncube)';
    lowerDiagCols = (1:(Ncube-(Nsqr)))';
    lowerDiagVals = -1*ones(size(lowerDiagCols));

    z_Block = (1/delz)*eye(Ncube,'like',sparse(Ncube));
    z_Block = z_Block+(1/delz)*sparse(upperDiagRows,upperDiagCols,upperDiagVals,Ncube,Ncube) ...
        + (1/delz)*sparse(lowerDiagRows,lowerDiagCols,lowerDiagVals,Ncube,Ncube);
    
end



%% Putting it all together
G = sparse(3*Ncube,Ncube);
G(1:Ncube,:) = x_Block;
G((1:Ncube)+Ncube,:) = y_Block;
G((1:Ncube)+2*Ncube,:) = z_Block;



end
