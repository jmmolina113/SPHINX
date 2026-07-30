function saveTimeStep(save_params,time,S,F,V,stateTime)
%SAVETIMESTEP Write one rolling state to the legacy text snapshot layout.
%   TIME determines the global zero-based filename. STATETIME selects the
%   rolling row to write and defaults to TIME for legacy callers.

if nargin < 6
    stateTime = time;
end

timeString = num2str((time-1),'%07.f');

newFolderString = save_params.saveLocation + "Runs/" + save_params.simName + save_params.saveDate;
if ~exist(newFolderString,'dir')
    mkdir(newFolderString)

    newVarFolder = newFolderString + "/S";
    mkdir(newVarFolder)

    newVarFolder = newFolderString + "/F";
    mkdir(newVarFolder)

    newVarFolder = newFolderString + "/V";
    mkdir(newVarFolder)

end

S_double = S((stateTime),:);
F_double = F((stateTime),:);
V_double = V;


fileTitle = newFolderString + '/S/S_' + timeString +'.txt';
writematrix(S_double,fileTitle)

fileTitle = newFolderString + '/F/F_' + timeString +'.txt';
writematrix(F_double,fileTitle)

if time == 1

    fileTitle = newFolderString + '/V/V.txt';
    writematrix(V_double,fileTitle)

end

end
