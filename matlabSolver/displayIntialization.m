function displayIntialization(psi,psi_sqr,A,Y,V,R,params,titleSize,axesSize,POV)
%DISPLAYINTIALIZATION Plot the original 2D initialization diagnostics.
%   The function displays central-z wavefunction, vector-potential, and Y-field
%   surfaces using normalized spatial coordinates. The historical misspelling
%   in the function name is preserved for compatibility.
figure('Position',[250 500 3000 2000]) %Creating figure environment and setting figure position and size

[Rx,Ry] = meshgrid(R.x / params.phys.lambda,R.y / params.phys.lambda);

subplot(2,2,1) %Subplot 1 - Pinhole Image
surf(Rx,Ry,squeeze(psi.R(:,:,round(length(R.z)/2))))
shading interp
xlabel('x / \lambda [unitless]','FontSize',axesSize)
ylabel('y / \lambda [unitless]','FontSize',axesSize)
xlim([min(R.x/params.phys.lambda) max(R.x/params.phys.lambda)])
ylim([min(R.y/params.phys.lambda) max(R.y/params.phys.lambda)])
cb = colorbar;
ylabel(cb,'\psi_R / \psi_0 [unitless]','FontSize',titleSize)
set(gca,'fontsize',axesSize)
shading interp
view(POV)

subplot(2,2,2) %Subplot 2 - Vertical Lineout
surf(Rx,Ry,squeeze(psi.I(:,:,round(length(R.z)/2))))
shading interp
xlabel('x / \lambda [unitless]','FontSize',axesSize)
ylabel('y / \lambda [unitless]','FontSize',axesSize)
xlim([min(R.x/params.phys.lambda) max(R.x/params.phys.lambda)])
ylim([min(R.y/params.phys.lambda) max(R.y/params.phys.lambda)])
cb = colorbar;
ylabel(cb,'\psi_I / \psi_0 [unitless]','FontSize',titleSize)
set(gca,'fontsize',axesSize)
shading interp
view(POV)

subplot(2,2,3) %Subplot 2 - Vertical Lineout
surf(Rx,Ry,squeeze(psi_sqr(:,:,round(length(R.z)/2))))
shading interp
xlabel('x / \lambda [unitless]','FontSize',axesSize)
ylabel('y / \lambda [unitless]','FontSize',axesSize)
xlim([min(R.x/params.phys.lambda) max(R.x/params.phys.lambda)])
ylim([min(R.y/params.phys.lambda) max(R.y/params.phys.lambda)])
cb = colorbar;
ylabel(cb,'|\psi|^2 / |\psi_0|^2','FontSize',titleSize)
set(gca,'fontsize',axesSize)
shading interp
view(POV)

subplot(2,2,4) %Subplot 2 - Vertical Lineout
surf(Rx,Ry,squeeze(V(:,:,round(length(R.z)/2))))
shading interp
xlabel('x / \lambda [unitless]','FontSize',axesSize)
ylabel('y / \lambda [unitless]','FontSize',axesSize)
xlim([min(R.x/params.phys.lambda) max(R.x/params.phys.lambda)])
ylim([min(R.y/params.phys.lambda) max(R.y/params.phys.lambda)])
cb = colorbar;
ylabel(cb,'V / \epsilon [unitless]','FontSize',titleSize)
set(gca,'fontsize',axesSize)
shading interp
view(POV)

sgtitle('Quantum Intialization','FontSize',titleSize)

%% Electro-magnetic Fields 
figure('Position',[250 500 3000 2000]) %Creating figure environment and setting figure position and size
subplot(2,3,1) %Subplot 3 - Horizontal Lineout
surf(Rx,Ry,squeeze(A.x(:,:,round(length(R.z)/2))))
xlabel('x / \lambda [unitless]','FontSize',axesSize)
ylabel('y / \lambda [unitless]','FontSize',axesSize)
xlim([min(R.x/params.phys.lambda) max(R.x/params.phys.lambda)])
ylim([min(R.y/params.phys.lambda) max(R.y/params.phys.lambda)])
cb = colorbar;
ylabel(cb,'A_x / A_0 [unitless]','FontSize',titleSize)
set(gca,'fontsize',axesSize)
shading interp
view(POV)


subplot(2,3,2) %Subplot 3 - Horizontal Lineout
surf(Rx,Ry,squeeze(A.y(:,:,round(length(R.z)/2))))
xlabel('x / \lambda [unitless]','FontSize',axesSize)
ylabel('y / \lambda [unitless]','FontSize',axesSize)
xlim([min(R.x/params.phys.lambda) max(R.x/params.phys.lambda)])
ylim([min(R.y/params.phys.lambda) max(R.y/params.phys.lambda)])
cb = colorbar;
ylabel(cb,'A_y / A_0 [unitless]','FontSize',titleSize)
set(gca,'fontsize',axesSize)
shading interp
view(POV)


subplot(2,3,3) %Subplot 3 - Horizontal Lineout
surf(Rx,Ry,squeeze(A.z(:,:,round(length(R.z)/2))))
xlabel('x / \lambda [unitless]','FontSize',axesSize)
ylabel('y / \lambda [unitless]','FontSize',axesSize)
xlim([min(R.x/params.phys.lambda) max(R.x/params.phys.lambda)])
ylim([min(R.y/params.phys.lambda) max(R.y/params.phys.lambda)])
cb = colorbar;
ylabel(cb,'A_z / A_0 [unitless]','FontSize',titleSize)
set(gca,'fontsize',axesSize)
shading interp
view(POV)


subplot(2,3,4) %Subplot 3 - Horizontal Lineout
surf(Rx,Ry,squeeze(Y.x(:,:,round(length(R.z)/2))))
xlabel('x / \lambda [unitless]','FontSize',axesSize)
ylabel('y / \lambda [unitless]','FontSize',axesSize)
xlim([min(R.x/params.phys.lambda) max(R.x/params.phys.lambda)])
ylim([min(R.y/params.phys.lambda) max(R.y/params.phys.lambda)])
cb = colorbar;
ylabel(cb,'Y_x / Y_0 [unitless]','FontSize',titleSize)
set(gca,'fontsize',axesSize)
shading interp
view(POV)


subplot(2,3,5) %Subplot 3 - Horizontal Lineout
surf(Rx,Ry,squeeze(Y.y(:,:,round(length(R.z)/2))))
xlabel('x / \lambda [unitless]','FontSize',axesSize)
ylabel('y / \lambda [unitless]','FontSize',axesSize)
xlim([min(R.x/params.phys.lambda) max(R.x/params.phys.lambda)])
ylim([min(R.y/params.phys.lambda) max(R.y/params.phys.lambda)])
cb = colorbar;
ylabel(cb,'Y_y / Y_0 [unitless]','FontSize',titleSize)
set(gca,'fontsize',axesSize)
shading interp
view(POV)


subplot(2,3,6) %Subplot 3 - Horizontal Lineout
surf(Rx,Ry,squeeze(Y.z(:,:,round(length(R.z)/2))))
xlabel('x / \lambda [unitless]','FontSize',axesSize)
ylabel('y / \lambda [unitless]','FontSize',axesSize)
xlim([min(R.x/params.phys.lambda) max(R.x/params.phys.lambda)])
ylim([min(R.y/params.phys.lambda) max(R.y/params.phys.lambda)])
cb = colorbar;
ylabel(cb,'Y_z / Y_0 [unitless]','FontSize',titleSize)
set(gca,'fontsize',axesSize)
shading interp
view(POV)

sgtitle('Electromagnetic Intialization','FontSize',titleSize)
 
end
