function params = importParams_sim(params)
%IMPORTPARAMS_SIM Derive normalization scales and coupling coefficients.
%   PARAMS.PHYS must already contain q, m, hbar, c, eps_0, and N_particles.
%   The returned structure supplies scales and coefficients used by all maps.

%% Calculating New Physics Parameters
params.phys.lambda  = 4*pi*params.phys.eps_0 * (params.phys.hbar)^(2) / (abs(1) * 1); %[bohr radii]
params.phys.Epsilon = (params.phys.hbar/params.phys.lambda)^2 * 1/(1);
params.phys.tau = params.phys.hbar / params.phys.Epsilon;
% params.phys.psi_0 = 1 / (params.phys.lambda)^(params.sim.numDim/2); %[ a_0^(-3/2)]
params.phys.psi_0 = 1 / (params.phys.lambda)^(3/2); %[ a_0^(-3/2)]
params.phys.B_0 = params.phys.hbar / (abs(1) * params.phys.lambda^2); %[T / atomic units conversion]
params.phys.E_0 = params.phys.Epsilon / (abs(1) * params.phys.lambda); %[V/m / atomic units conversion]

params.phys.A_0 = params.phys.B_0 * params.phys.lambda; %[T / atomic units conversion]
params.phys.Y_0 = params.phys.E_0 * params.phys.eps_0; %[V/m / atomic units conversion]
params.phys.mu = 1 / ((params.phys.c)^2 * params.phys.eps_0);

%% Calculating Simulation Parameters

params.sim.C_Y = params.phys.tau*params.phys.Y_0 / (params.phys.A_0 * params.phys.eps_0);
params.sim.C_A = params.phys.tau*params.phys.A_0*(params.phys.c)^2 * params.phys.eps_0 / ((params.phys.lambda)^2*params.phys.Y_0);

params.sim.C1 = params.phys.tau * params.phys.q * params.phys.A_0 / (2*params.phys.m*(params.phys.lambda));
params.sim.C2 = params.phys.hbar * params.phys.tau / (4*params.phys.m*(params.phys.lambda)^2);
params.sim.C3 = params.phys.tau * (params.phys.q)^2 * (params.phys.A_0)^2 /  (2 * params.phys.m * params.phys.hbar);
params.sim.C4 = params.phys.tau * params.phys.Epsilon / params.phys.hbar;

params.sim.C_JQ = params.phys.q * params.phys.hbar * (params.phys.psi_0)^2 * params.phys.tau / (params.phys.m * params.phys.lambda * 2 * params.phys.Y_0);
params.sim.C_JA = (params.phys.q)^2 * params.phys.A_0 * (params.phys.psi_0)^2 * params.phys.tau / (params.phys.m * 2 * params.phys.Y_0);


end
