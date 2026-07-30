function rootFolder = setupSPHINX()
%SETUPSPHINX Add the SPHINX repository root to the MATLAB path.
%   ROOTFOLDER = SETUPSPHINX() enables the +sphinx package for the current
%   MATLAB session and returns the repository's absolute path.

rootFolder = fileparts(mfilename('fullpath'));
addpath(rootFolder)
addpath(fullfile(rootFolder,'matlabSolver'))

fprintf('SPHINX is ready.\n')
fprintf('First run: SPHINX_demo;\n')
fprintf('Configure: sphinx.options;\n')
fprintf('Post-production: sphinx.post.options;\n')

end
