function writeSimParamsToFile(R,params,save_params)
%WRITESIMPARAMSTOFILE Write legacy XML coordinate and parameter metadata.
%   The new sphinx API uses manifest.json, but this function remains available
%   for compatibility with the original run scripts and analysis workflow.

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

disp('Writing simulation space-time to file')
disp('...')
spaceTime_fullFileName = newFolderString + "/spaceTime.xml";
writestruct(R,spaceTime_fullFileName)
disp('Done!')

disp('Writing simulation parameters to file')
disp('...')
simParams_fullFileName = newFolderString + "/simulationParams.xml";
writestruct(params,simParams_fullFileName)
disp('Done!')



end
