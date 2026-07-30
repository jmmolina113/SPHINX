function params = importParams_phys(params)
%IMPORTPARAMS_PHYS Populate the original atomic-unit physical defaults.
%   Existing callers commonly override selected PARAMS.PHYS fields after
%   this function. The sphinx API performs those overrides automatically.

%% Defining physical reference constants - atomic units
% time_norm = 2.4188843265864e-17; %s
% length_norm = 5.29177210544e-11; %m
% B_0 = (2.35051757077e5); %[T / atomic units conversion]
% E_0 = 5.14220675112e11; %[V/m / atomic units conversion]
% w_p = 6e11 * time_norm ; %[Hz]
% d_e = (c / w_p); %(speed of light / plasma frequency), units of[m]

params.phys.q = 1; %[e, electron charges]
params.phys.m = 1; %[m_e, electron masses]
params.phys.hbar = 1; %[hbar, units of hbar]
params.phys.c = 137; %[a.u.]
params.phys.eps_0 = 1/(4*pi);
params.phys.N_particles = 1;
params.phys.B_mag = 1; %[magnetic-field scale in the cyclotron initializer]

end
