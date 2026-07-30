function analysis = analyze(data,varargin)
%SPHINX.POST.ANALYZE Compute selected diagnostics from an imported run.
%   ANALYSIS = SPHINX.POST.ANALYZE(DATA) computes probability, EM energy,
%   QM energy, energy breakdowns, and conservation drift for DATA returned
%   by SPHINX.POST.IMPORTRUN.
%
%   ANALYSIS = SPHINX.POST.ANALYZE(DATA,"Diagnostics",NAMES) selects any of
%   "probability", "energy", and "field_statistics". "all" selects every
%   diagnostic. IntegrationBox may be [] (the full domain) or a 3-by-2
%   physical-coordinate box [xmin xmax; ymin ymax; zmin zmax].

parser = inputParser;
parser.FunctionName = 'sphinx.post.analyze';
addParameter(parser,'Diagnostics',"all")
addParameter(parser,'IntegrationBox',[])
parse(parser,varargin{:})
options = parser.Results;

diagnostics = lower(string(options.Diagnostics));
if isscalar(diagnostics) && diagnostics == "all"
    diagnostics = ["probability","energy","field_statistics"];
end
valid = ["probability","energy","field_statistics"];
assert(all(ismember(diagnostics,valid)), ...
    'Diagnostics must be all, probability, energy, or field_statistics.')

analysis.schemaVersion = 1;
analysis.sourceFolder = data.sourceFolder;
analysis.savedSteps = data.savedSteps;
analysis.time = data.time;
analysis.integrationBox = options.IntegrationBox;

if ismember("probability",diagnostics)
    probability = zeros(numel(data.time),1);
    for index = 1:numel(data.time)
        density = spatialFrame(data.psi.probability,index);
        probability(index) = data.params.phys.psi_0^2 ...
            * integrateField(density,data.coordinates,options.IntegrationBox);
    end
    analysis.probability.integral = probability;
    analysis.probability.normAmplitude = sqrt(max(probability,0));
    analysis.probability.relativeDrift = relativeDrift(probability);
end

if ismember("energy",diagnostics)
    assert(isfield(data,'B'), ...
        'Energy diagnostics require importRun(...,"Derived",true).')
    analysis.energy = calculateEnergy(data,options.IntegrationBox);
end

if ismember("field_statistics",diagnostics)
    names = ["probability","psiR","psiI","Ax","Ay","Az", ...
        "Yx","Yy","Yz","Bx","By","Bz","Ex","Ey","Ez", ...
        "Jx","Jy","Jz"];
    for name = names
        history = selectField(data,name);
        analysis.fieldStatistics.(name).minimum = squeeze(min(history,[],[2,3,4]));
        analysis.fieldStatistics.(name).maximum = squeeze(max(history,[],[2,3,4]));
        analysis.fieldStatistics.(name).rms = squeeze(sqrt(mean(abs(history).^2,[2,3,4])));
    end
end

end

function energy = calculateEnergy(data,integrationBox)
rootFolder = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(rootFolder,'matlabSolver'))
grid = data.problem.domain.grid;
N.x = grid(1); N.y = grid(2); N.z = grid(3);
fFL = prod(grid);
fVFL = 3*fFL;
[G,~,L] = importDifferentialOperators(N,data.params,fFL);
physics = data.params.phys;
nSnapshots = numel(data.time);

names = ["electromagnetic","magnetic","electric", ...
    "quantum","quantumGradient","quantumCoupling","quantumPotential","total"];
for name = names
    energy.(name) = zeros(nSnapshots,1);
end

for index = 1:nSnapshots
    psiR = data.raw.S(index,1:fFL)';
    psiI = data.raw.S(index,fFL+1:2*fFL)';
    Aflat = data.raw.F(index,1:fVFL)';
    Vflat = data.raw.V;
    psiSquared = psiR.^2 + psiI.^2;
    gradientR = G*psiR;
    gradientI = G*psiI;
    laplacianR = L*psiR;
    laplacianI = L*psiI;

    componentRange = @(component) (1:fFL) + (component-1)*fFL;
    couplingR = zeros(fFL,1);
    couplingI = zeros(fFL,1);
    aSquared = zeros(fFL,1);
    for component = 1:3
        range = componentRange(component);
        couplingR = couplingR + Aflat(range).*gradientR(range);
        couplingI = couplingI + Aflat(range).*gradientI(range);
        aSquared = aSquared + Aflat(range).^2;
    end

    gradientDensity = -physics.hbar^2*physics.psi_0^2 ...
        /(4*physics.m*physics.lambda^2) ...
        .*(psiR.*laplacianR + psiI.*laplacianI);
    couplingDensity = physics.q*physics.hbar*physics.A_0*physics.psi_0^2 ...
        /(2*physics.m*physics.lambda) ...
        .*(psiI.*couplingR - psiR.*couplingI);
    potentialDensity = physics.psi_0^2/2 ...
        .*(physics.q^2*physics.A_0^2/(2*physics.m).*aSquared.*psiSquared ...
        + physics.Epsilon/physics.m.*Vflat.*psiSquared);

    magneticSquared = vectorMagnitudeSquared(data.B,index);
    electricCanonicalSquared = vectorMagnitudeSquared(data.Y,index);
    magneticDensity = 0.5*physics.B_0^2/physics.mu.*magneticSquared;
    electricDensity = 0.5*physics.Y_0^2/physics.eps_0.*electricCanonicalSquared;

    energy.magnetic(index) = integrateField(magneticDensity,data.coordinates,integrationBox);
    energy.electric(index) = integrateField(electricDensity,data.coordinates,integrationBox);
    energy.electromagnetic(index) = energy.magnetic(index) + energy.electric(index);
    energy.quantumGradient(index) = integrateFlat(gradientDensity,grid,data.coordinates,integrationBox);
    energy.quantumCoupling(index) = integrateFlat(couplingDensity,grid,data.coordinates,integrationBox);
    energy.quantumPotential(index) = integrateFlat(potentialDensity,grid,data.coordinates,integrationBox);
    energy.quantum(index) = energy.quantumGradient(index) ...
        + energy.quantumCoupling(index) + energy.quantumPotential(index);
    energy.total(index) = energy.electromagnetic(index) + energy.quantum(index);
end

for name = ["electromagnetic","quantum","total","magnetic","electric"]
    energy.(name + "RelativeDrift") = relativeDrift(energy.(name));
end
end

function value = integrateFlat(flat,grid,R,integrationBox)
value = integrateField(sphinx.post.unflatten(flat,grid),R,integrationBox);
end

function value = integrateField(field,R,integrationBox)
coordinates = {R.y,R.x,R.z};
if isempty(integrationBox)
    indices = {1:numel(R.y),1:numel(R.x),1:numel(R.z)};
else
    assert(isequal(size(integrationBox),[3,2]), ...
        'IntegrationBox must be [xmin xmax; ymin ymax; zmin zmax].')
    xyz = {R.x,R.y,R.z};
    xyzIndices = cell(1,3);
    for dimension = 1:3
        xyzIndices{dimension} = find(xyz{dimension} >= integrationBox(dimension,1) ...
            & xyz{dimension} <= integrationBox(dimension,2));
        assert(~isempty(xyzIndices{dimension}), ...
            'IntegrationBox excludes the entire %s axis.',char('x'+dimension-1))
    end
    indices = {xyzIndices{2},xyzIndices{1},xyzIndices{3}};
end

value = field(indices{:});
selectedCoordinates = {coordinates{1}(indices{1}), ...
    coordinates{2}(indices{2}),coordinates{3}(indices{3})};
for dimension = 3:-1:1
    if numel(selectedCoordinates{dimension}) > 1
        value = trapz(selectedCoordinates{dimension},value,dimension);
    end
end
value = double(value(1));
end

function result = relativeDrift(values)
if isempty(values) || values(1) == 0
    result = nan(size(values));
else
    result = (values-values(1))/values(1);
end
end

function squared = vectorMagnitudeSquared(vector,index)
squared = spatialFrame(vector.x,index).^2 + spatialFrame(vector.y,index).^2 ...
    + spatialFrame(vector.z,index).^2;
end

function field = spatialFrame(history,index)
field = reshape(history(index,:,:,:),size(history,2),size(history,3),size(history,4));
end

function history = selectField(data,name)
switch name
    case "probability", history = data.psi.probability;
    case "psiR", history = data.psi.R;
    case "psiI", history = data.psi.I;
    otherwise
        group = extractBefore(name,strlength(name));
        component = lower(extractAfter(name,strlength(name)-1));
        history = data.(group).(component);
end
end
