function [S,F,V_flat,V_op] = flattenFields(psi,A,Y,V,R)
%FLATTENFIELDS Pack structured fields into the solver's rolling state rows.
%   S stores <psi_R,psi_I>; F stores <A_x,A_y,A_z,Y_x,Y_y,Y_z>;
%   V_FLAT and V_OP store the scalar potential as a vector and sparse
%   diagonal operator. Only two rows are allocated for S and F.

N.x = size(A.x,2);
N.y = size(A.x,1);
N.z = size(A.x,3);

Nsqr = N.x*N.y;
Ncube = N.x*N.y*N.z;

t = R.t;
fFL = N.x * N.y * N.z; %fFL = flattened Field Length
fVFL = 3*fFL; %fVFL = flattened Vector Field Length

%%%%% Flattening E-M Fields %%%%%


F = zeros(2,2*fVFL);

disp('Flattening Electromagnetic Fields')
disp('...')

for k = 1:N.z
    F(1,(1:(Nsqr)) + (k-1)*(Nsqr)) = reshape(transpose(squeeze(A.x(:,:,k))),[],1);
    F(1,(1:(Nsqr)) + (k-1)*(Nsqr) + (Ncube)) = reshape(transpose(squeeze(A.y(:,:,k))),[],1);
    F(1,(1:(Nsqr)) + (k-1)*(Nsqr) + 2*(Ncube)) = reshape(transpose(squeeze(A.z(:,:,k))),[],1);

    F(1,(1:(Nsqr)) + (k-1)*(Nsqr) + fVFL) = reshape(transpose(squeeze(Y.x(:,:,k))),[],1);
    F(1,(1:(Nsqr)) + (k-1)*(Nsqr) + (Ncube) + fVFL) = reshape(transpose(squeeze(Y.y(:,:,k))),[],1);
    F(1,(1:(Nsqr)) + (k-1)*(Nsqr) + 2*(Ncube) + fVFL) = reshape(transpose(squeeze(Y.z(:,:,k))),[],1);
end

%%%%% Flattening Quantum Fields %%%%%

S = zeros(2,2*fFL);
V_flat = zeros(fFL,1);

disp('Flattening Quantum Fields')
disp('...')

for k = 1:N.z
    S(1,(1:(Nsqr)) + (k-1)*(Nsqr)) = reshape(transpose(squeeze(psi.R(:,:,k))),[],1);
    S(1,(1:(Nsqr)) + (k-1)*(Nsqr) + (Ncube)) = reshape(transpose(squeeze(psi.I(:,:,k))),[],1);
    V_flat((1:(Nsqr)) + (k-1)*(Nsqr),1) = reshape(transpose(squeeze(V(:,:,k))),[],1);
end

V_op = sparse((1:fFL),(1:fFL),V_flat);

end
