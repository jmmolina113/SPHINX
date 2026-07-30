function sim = validateProblem(sim)
%SPHINX.VALIDATEPROBLEM Validate and normalize a problem definition.
%   SIM = SPHINX.VALIDATEPROBLEM(SIM) checks modes, boundary support,
%   physical constants, grid geometry, timing, and output settings before
%   the solver allocates fields or sparse operators. It returns normalized
%   string and numeric representations of the configuration fields.
%
%   Fixed boundaries are supported in 2D only. Periodic boundaries support
%   1D, 2D, and 3D.

requiredFields = ["name","model","boundary","initialCondition","physics","domain","time","output"];

for fieldIndex = 1:length(requiredFields)
    assert(isfield(sim,requiredFields(fieldIndex)), ...
        'Missing required problem field: %s',requiredFields(fieldIndex))
end

sim.model = string(sim.model);
sim.boundary = string(sim.boundary);
sim.initialCondition = string(sim.initialCondition);
sim.output.root = string(sim.output.root);
sim.output.name = string(sim.output.name);

assert(any(sim.model == ["EM","QM","both"]), ...
    'model must be "EM", "QM", or "both"')
assert(any(sim.boundary == ["fixed","periodic"]), ...
    'boundary must be "fixed" or "periodic"')
assert(sim.initialCondition == "cyclotron", ...
    'The current interface supports the "cyclotron" initializer')

gridSize = double(sim.domain.grid(:)');
assert(length(gridSize) == 3,'domain.grid must be [Nx,Ny,Nz]')
assert(all(isfinite(gridSize)) && all(gridSize >= 1) && all(gridSize == floor(gridSize)), ...
    'domain.grid entries must be positive integers')

numDim = sum(gridSize > 1);
assert(numDim >= 1,'At least one grid dimension must contain multiple points')

if sim.boundary == "fixed"
    assert(numDim == 2 && gridSize(3) == 1, ...
        'The original fixed-boundary operators support 2D runs only')
    assert(gridSize(1) == gridSize(2), ...
        'The original fixed-boundary operators require Nx = Ny')
end

extentLambda = double(sim.domain.extentLambda);
assert(isequal(size(extentLambda),[3,2]), ...
    'domain.extentLambda must contain [min,max] rows for x, y, and z')
assert(all(isfinite(extentLambda),'all'), ...
    'domain.extentLambda must contain finite values')

for dimensionIndex = 1:3
    if gridSize(dimensionIndex) > 1
        assert(extentLambda(dimensionIndex,2) > extentLambda(dimensionIndex,1), ...
            'Each active dimension requires max > min')
    end
end

assert(isfinite(sim.time.steps) && sim.time.steps >= 2 && sim.time.steps == floor(sim.time.steps), ...
    'time.steps must be an integer greater than one')
assert(isfinite(sim.time.cycles) && sim.time.cycles > 0, ...
    'time.cycles must be positive')

if ~isempty(sim.time.endTime)
    assert(isscalar(sim.time.endTime) && isfinite(sim.time.endTime) && sim.time.endTime > 0, ...
        'time.endTime must be empty or a positive scalar')
end

assert(isfinite(sim.output.every) && sim.output.every >= 1 && sim.output.every == floor(sim.output.every), ...
    'output.every must be a positive integer')
assert(strlength(sim.output.root) > 0,'output.root cannot be empty')
assert(strlength(sim.output.name) > 0,'output.name cannot be empty')
assert(isvarname(char(sim.output.name)), ...
    'output.name must be a valid MATLAB-style name without path separators')

physicsFields = ["q","m","hbar","c","eps_0","N_particles","B_mag"];

for fieldIndex = 1:length(physicsFields)
    fieldName = physicsFields(fieldIndex);
    assert(isfield(sim.physics,fieldName), ...
        'Missing required physics field: %s',fieldName)
    assert(isscalar(sim.physics.(fieldName)) && isfinite(sim.physics.(fieldName)), ...
        'physics.%s must be a finite scalar',fieldName)
end

assert(sim.physics.m > 0,'physics.m must be positive')
assert(sim.physics.hbar > 0,'physics.hbar must be positive')
assert(sim.physics.c > 0,'physics.c must be positive')
assert(sim.physics.eps_0 > 0,'physics.eps_0 must be positive')
assert(sim.physics.N_particles > 0,'physics.N_particles must be positive')
assert(sim.physics.q ~= 0,'physics.q cannot be zero for the cyclotron preset')
assert(sim.physics.B_mag ~= 0,'physics.B_mag cannot be zero for the cyclotron preset')

sim.domain.grid = gridSize;
sim.domain.extentLambda = extentLambda;

end
