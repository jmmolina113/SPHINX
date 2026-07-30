function data = importRun(runSource,varargin)
%SPHINX.POST.IMPORTRUN Import a complete SPHINX run for post-production.
%   DATA = SPHINX.POST.IMPORTRUN(FOLDER) reads the manifest, every saved S
%   and F snapshot, the static potential, coordinates, parameters, and
%   derived electromagnetic and current fields. Structured histories use
%   [time,y,x,z].
%
%   DATA = SPHINX.POST.IMPORTRUN(RESULT) accepts the structure returned by
%   SPHINX.RUN. Name-value options are:
%       Snapshots     "all" (default), a numeric list of saved step numbers,
%                     or MATLAB indices into the available snapshot list
%       Derived       true (default) computes B, E, J, probability current,
%                     canonical momentum, and Poynting flux
%       VerifyOrder   true (default) round-trip checks every primary field

parser = inputParser;
parser.FunctionName = 'sphinx.post.importRun';
addParameter(parser,'Snapshots',"all")
addParameter(parser,'Derived',true,@(x) islogical(x) && isscalar(x))
addParameter(parser,'VerifyOrder',true,@(x) islogical(x) && isscalar(x))
parse(parser,varargin{:})
options = parser.Results;

if isstruct(runSource)
    assert(isfield(runSource,'outputFolder'), ...
        'A run result must contain outputFolder.')
    runFolder = string(runSource.outputFolder);
else
    runFolder = string(runSource);
end

assert(isfolder(runFolder),'SPHINX run folder does not exist: %s',runFolder)
manifestPath = fullfile(runFolder,'manifest.json');
assert(isfile(manifestPath), ...
    'manifest.json is required. This importer targets runs made by sphinx.run.')

manifest = jsondecode(fileread(manifestPath));
sim = sphinx.validateProblem(manifest.problem);
[~,~,~,~,R,params] = sphinx.prepare(sim);
params.save.saveFrequency = sim.output.every;

[availableSteps,sFiles] = snapshotFiles(fullfile(runFolder,'S'),'S');
[fSteps,fFiles] = snapshotFiles(fullfile(runFolder,'F'),'F');
assert(isequal(availableSteps,fSteps),'S and F snapshot step numbers do not match.')

selection = selectSnapshots(options.Snapshots,availableSteps);
steps = availableSteps(selection);
sFiles = sFiles(selection);
fFiles = fFiles(selection);

grid = sim.domain.grid;
fFL = prod(grid);
fVFL = 3*fFL;
nSnapshots = numel(steps);
spatialHistorySize = [nSnapshots,grid(2),grid(1),grid(3)];

S = zeros(nSnapshots,2*fFL);
F = zeros(nSnapshots,2*fVFL);
psi.R = zeros(spatialHistorySize);
psi.I = zeros(spatialHistorySize);
A = emptyVectorHistory(spatialHistorySize);
Y = emptyVectorHistory(spatialHistorySize);

for timeIndex = 1:nSnapshots
    S(timeIndex,:) = readRow(sFiles(timeIndex),2*fFL);
    F(timeIndex,:) = readRow(fFiles(timeIndex),2*fVFL);

    psi.R(timeIndex,:,:,:) = sphinx.post.unflatten(S(timeIndex,1:fFL),grid);
    psi.I(timeIndex,:,:,:) = sphinx.post.unflatten(S(timeIndex,fFL+1:2*fFL),grid);
    A = assignVector(A,F(timeIndex,1:fVFL),grid,timeIndex);
    Y = assignVector(Y,F(timeIndex,fVFL+1:2*fVFL),grid,timeIndex);
end

potentialPath = fullfile(runFolder,'V','V.txt');
assert(isfile(potentialPath),'Static potential file is missing: %s',potentialPath)
V_flat = readmatrix(potentialPath);
V_flat = V_flat(:);
assert(numel(V_flat) == fFL,'V.txt has the wrong number of values.')
V = sphinx.post.unflatten(V_flat,grid);

if options.VerifyOrder
    verifyRoundTrip(psi,A,Y,S,F,grid)
    assert(isequaln(sphinx.post.flatten(V),V_flat), ...
        'Potential flattening round-trip failed.')
end

data.schemaVersion = 1;
data.sourceFolder = runFolder;
data.manifest = manifest;
data.problem = sim;
data.params = params;
data.coordinates = R;
data.savedSteps = steps;
data.time = R.t(steps+1);
data.storageOrder = "time,y,x,z";
data.flatteningOrder = "x-fastest, then y, then z; components are contiguous";
data.raw.S = S;
data.raw.F = F;
data.raw.V = V_flat;
data.psi = psi;
data.psi.probability = psi.R.^2 + psi.I.^2;
data.A = A;
data.Y = Y;
data.V = V;

if options.Derived
    data = deriveFields(data);
end

fprintf('Imported %d snapshots from:\n%s\n',nSnapshots,runFolder)
fprintf('Field storage: [time,y,x,z] = [%d,%d,%d,%d]\n',spatialHistorySize)

end

function [steps,files] = snapshotFiles(folder,prefix)
listing = dir(fullfile(folder,prefix + "_*.txt"));
assert(~isempty(listing),'No %s snapshots found in %s.',prefix,folder)
names = string({listing.name});
steps = zeros(size(names));
for index = 1:numel(names)
    token = regexp(names(index),'_(\d+)\.txt$','tokens','once');
    assert(~isempty(token),'Unrecognized snapshot filename: %s',names(index))
    steps(index) = str2double(token{1});
end
[steps,order] = sort(steps);
files = fullfile(string({listing.folder}),names);
files = files(order);
end

function selection = selectSnapshots(request,availableSteps)
if ischar(request) || isstring(request)
    assert(string(request) == "all",'Snapshots text option must be "all".')
    selection = 1:numel(availableSteps);
    return
end
request = double(request(:)');
assert(all(isfinite(request) & request == floor(request)), ...
    'Snapshots must contain integer step numbers or indices.')
if all(ismember(request,availableSteps))
    [~,selection] = ismember(request,availableSteps);
elseif all(request >= 1 & request <= numel(availableSteps))
    selection = request;
else
    error('Requested snapshots are neither saved step numbers nor valid indices.')
end
end

function row = readRow(path,expectedLength)
row = readmatrix(path);
row = row(:)';
assert(numel(row) == expectedLength, ...
    'Snapshot %s contains %d values; expected %d.',path,numel(row),expectedLength)
end

function vector = emptyVectorHistory(historySize)
vector.x = zeros(historySize);
vector.y = zeros(historySize);
vector.z = zeros(historySize);
end

function vector = assignVector(vector,flat,grid,timeIndex)
fFL = prod(grid);
components = ["x","y","z"];
for componentIndex = 1:3
    range = (1:fFL) + (componentIndex-1)*fFL;
    vector.(components(componentIndex))(timeIndex,:,:,:) = ...
        sphinx.post.unflatten(flat(range),grid);
end
end

function verifyRoundTrip(psi,A,Y,S,F,grid)
fFL = prod(grid);
for timeIndex = 1:size(S,1)
    assert(isequaln(sphinx.post.flatten(squeezeTime(psi.R,timeIndex)),S(timeIndex,1:fFL)'), ...
        'psi.R flattening round-trip failed at imported snapshot %d.',timeIndex)
    assert(isequaln(sphinx.post.flatten(squeezeTime(psi.I,timeIndex)),S(timeIndex,fFL+1:end)'), ...
        'psi.I flattening round-trip failed at imported snapshot %d.',timeIndex)
    packed = [packVector(A,timeIndex);packVector(Y,timeIndex)];
    assert(isequaln(packed,F(timeIndex,:)'), ...
        'Electromagnetic flattening round-trip failed at imported snapshot %d.',timeIndex)
end
end

function field = squeezeTime(history,timeIndex)
field = reshape(history(timeIndex,:,:,:),size(history,2),size(history,3),size(history,4));
end

function flat = packVector(vector,timeIndex)
flat = [sphinx.post.flatten(squeezeTime(vector.x,timeIndex)); ...
        sphinx.post.flatten(squeezeTime(vector.y,timeIndex)); ...
        sphinx.post.flatten(squeezeTime(vector.z,timeIndex))];
end

function data = deriveFields(data)
rootFolder = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(rootFolder,'matlabSolver'))
grid = data.problem.domain.grid;
N.x = grid(1); N.y = grid(2); N.z = grid(3);
fFL = prod(grid);
fVFL = 3*fFL;
[G,C,~,~,D] = importDifferentialOperators(N,data.params,fFL);
nSnapshots = numel(data.savedSteps);
historySize = [nSnapshots,grid(2),grid(1),grid(3)];
data.B = emptyVectorHistory(historySize);
data.E = emptyVectorHistory(historySize);
data.J = emptyVectorHistory(historySize);
data.probabilityCurrent = emptyVectorHistory(historySize);
data.canonicalMomentum = emptyVectorHistory(historySize);
data.poynting = emptyVectorHistory(historySize);
data.poynting.divergence = zeros(historySize);
data.probabilityCurrent.divergence = zeros(historySize);

for timeIndex = 1:nSnapshots
    psiR = data.raw.S(timeIndex,1:fFL)';
    psiI = data.raw.S(timeIndex,fFL+1:2*fFL)';
    Aflat = data.raw.F(timeIndex,1:fVFL)';
    Yflat = data.raw.F(timeIndex,fVFL+1:2*fVFL)';
    Bflat = C*Aflat;
    Jflat = calculateJ(psiR,psiI,Aflat,D,data.params,fFL);
    probabilityCurrentFlat = Jflat/data.params.phys.q;
    psiFull = psiR + 1i*psiI;
    canonicalFlat = -1i*(G*psiFull) ...
        - data.params.phys.q*data.params.phys.A_0 ...
        /(data.params.phys.hbar/data.params.phys.lambda) ...
        *(repmat(Aflat,1,1).*repmat(psiFull,3,1));
    poyntingFlat = crossComponents(-Yflat,Bflat,fFL);
    poyntingDivergence = componentDivergence(poyntingFlat,D,fFL);
    probabilityDivergence = componentDivergence(probabilityCurrentFlat,D,fFL);

    data.B = assignVector(data.B,Bflat,grid,timeIndex);
    data.E = assignVector(data.E,-Yflat/data.params.phys.eps_0,grid,timeIndex);
    data.J = assignVector(data.J,Jflat,grid,timeIndex);
    data.probabilityCurrent = assignVector(data.probabilityCurrent,probabilityCurrentFlat,grid,timeIndex);
    data.canonicalMomentum = assignVector(data.canonicalMomentum,canonicalFlat,grid,timeIndex);
    data.poynting = assignVector(data.poynting,poyntingFlat,grid,timeIndex);
    data.poynting.divergence(timeIndex,:,:,:) = sphinx.post.unflatten(poyntingDivergence,grid);
    data.probabilityCurrent.divergence(timeIndex,:,:,:) = sphinx.post.unflatten(probabilityDivergence,grid);
end
end

function crossFlat = crossComponents(left,right,fFL)
lx = left(1:fFL); ly = left(fFL+1:2*fFL); lz = left(2*fFL+1:3*fFL);
rx = right(1:fFL); ry = right(fFL+1:2*fFL); rz = right(2*fFL+1:3*fFL);
crossFlat = [ly.*rz-lz.*ry; lz.*rx-lx.*rz; lx.*ry-ly.*rx];
end

function divergence = componentDivergence(vector,D,fFL)
divergence = D.x*vector(1:fFL) + D.y*vector(fFL+1:2*fFL) ...
    + D.z*vector(2*fFL+1:3*fFL);
end
