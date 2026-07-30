function results = SPHINX_user_api_test()
%SPHINX_USER_API_TEST Exercise the public API through 2D and 3D runs.
%   RESULTS = SPHINX_USER_API_TEST() creates temporary output directories,
%   runs fixed-2D and periodic-3D coupled problems, and verifies manifests,
%   result metadata, and final S, F, and V snapshots.

rootFolder = fileparts(fileparts(mfilename('fullpath')));
addpath(rootFolder)

testRoot = string(tempname);
mkdir(testRoot)
cleanupObject = onCleanup(@() rmdir(testRoot,'s'));

fixedProblem = sphinx.problem("cyclotron");
fixedProblem.domain.grid = [5,5,1];
fixedProblem.time.steps = 4;
fixedProblem.time.endTime = 1e-4;
fixedProblem.output.root = testRoot;
fixedProblem.output.name = "api_fixed_2D";
fixedProblem.output.every = 1;

fixedPreview = sphinx.preview(fixedProblem,false);
assert(fixedPreview.valid)
assert(fixedPreview.dimension == 2)
fixedResult = sphinx.run(fixedProblem);
verifyResult(fixedResult)

periodicProblem = sphinx.problem("cyclotron");
periodicProblem.boundary = "periodic";
periodicProblem.physics.q = 1;
periodicProblem.physics.hbar = 1;
periodicProblem.domain.grid = [4,4,4];
periodicProblem.domain.extentLambda = [-1,1;-1,1;-1,1];
periodicProblem.time.steps = 4;
periodicProblem.time.endTime = 1e-4;
periodicProblem.output.root = testRoot;
periodicProblem.output.name = "api_periodic_3D";
periodicProblem.output.every = 1;

periodicPreview = sphinx.preview(periodicProblem,false);
assert(periodicPreview.valid)
assert(periodicPreview.dimension == 3)
periodicResult = sphinx.run(periodicProblem);
verifyResult(periodicResult)

results.fixed_2D = fixedResult;
results.periodic_3D = periodicResult;
results.pass = true;

clear cleanupObject

end

function verifyResult(result)
%VERIFYRESULT Check the durable output contract for one API run.

assert(result.status == "completed")
assert(isfolder(result.outputFolder))
assert(isfile(fullfile(result.outputFolder,"manifest.json")))
assert(isfile(fullfile(result.outputFolder,"result.json")))
assert(isfile(fullfile(result.outputFolder,"S","S_0000003.txt")))
assert(isfile(fullfile(result.outputFolder,"F","F_0000003.txt")))
assert(isfile(fullfile(result.outputFolder,"V","V.txt")))

manifest = jsondecode(fileread(fullfile(result.outputFolder,"manifest.json")));
assert(string(manifest.status) == "completed")
assert(isfield(manifest,'coreProvenance'))
assert(ismember(string(manifest.coreProvenance.classification), ...
    ["SPHINX-CERTIFIED","SPHINX-MODIFIED","SPHINX-UNVERIFIED"]))

end
