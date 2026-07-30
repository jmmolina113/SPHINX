function SPHINX_postproduction_test
%SPHINX_POSTPRODUCTION_TEST Verify nonsquare 3D save/import orientation.
%   Runs a small 5-by-4-by-3 periodic problem, compares every imported
%   initial field to the structured field before flattening, checks derived
%   diagnostics, and creates representative post-production products.

rootFolder = fileparts(fileparts(mfilename('fullpath')));
addpath(rootFolder)
setupSPHINX;

outputRoot = string(tempname);
mkdir(outputRoot)
cleanupObject = onCleanup(@() removeTestOutput(outputRoot));

sim = sphinx.configure("cyclotron", ...
    "Resolution","quick", ...
    "Boundary","periodic", ...
    "Grid",[5,4,3], ...
    "ExtentLambda",[-2,2;-1,1;-0.5,0.5], ...
    "EndTime",1e-5, ...
    "TimePoints",3, ...
    "SaveEvery",1, ...
    "RunName","postproduction_test", ...
    "OutputRoot",outputRoot);

[psiExpected,AExpected,YExpected,VExpected] = sphinx.prepare(sim);
result = sphinx.run(sim);
data = sphinx.post.importRun(result);

assert(isequal(size(data.psi.R),[3,4,5,3]))
assertClose(data.psi.R(1,:,:,:),reshape(psiExpected.R,[1,4,5,3]))
assertClose(data.psi.I(1,:,:,:),reshape(psiExpected.I,[1,4,5,3]))
assertVectorEqual(data.A,AExpected)
assertVectorEqual(data.Y,YExpected)
assertClose(data.V,VExpected)

for snapshot = 1:numel(data.savedSteps)
    field = reshape(data.psi.R(snapshot,:,:,:),[4,5,3]);
    raw = reshape(data.raw.S(snapshot,1:60),[],1);
    assert(isequal(sphinx.post.flatten(field),raw))
end

analysis = sphinx.post.analyze(data);
assert(numel(analysis.probability.integral) == 3)
assert(numel(analysis.energy.total) == 3)
assert(all(isfinite(analysis.energy.total)))

productFolder = fullfile(outputRoot,'products');
files = sphinx.post.produce(data,analysis,"summary", ...
    "OutputFolder",productFolder,"Visible","off");
assert(all(isfile(files)))

catalog = sphinx.post.options(false);
assert(height(catalog.products) == 7)

clear cleanupObject
removeTestOutput(outputRoot)
disp('SPHINX post-production test passed.')

end

function assertVectorEqual(actual,expected)
components = ["x","y","z"];
for component = components
    expectedHistory = reshape(expected.(component), ...
        [1,size(expected.(component),1),size(expected.(component),2),size(expected.(component),3)]);
    assertClose(actual.(component)(1,:,:,:),expectedHistory)
end
end

function assertClose(actual,expected)
scale = max(1,max(abs(expected),[],'all'));
assert(max(abs(actual-expected),[],'all') <= 10*eps(scale))
end

function removeTestOutput(folder)
if isfolder(folder)
    rmdir(folder,'s')
end
end
