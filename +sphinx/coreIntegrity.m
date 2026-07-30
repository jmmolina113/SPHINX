function report = coreIntegrity(rootFolder)
%SPHINX.COREINTEGRITY Classify the numerical core against its release manifest.

if nargin == 0
    rootFolder = fileparts(fileparts(mfilename('fullpath')));
end

manifestPath = fullfile(rootFolder,'SPHINX_CORE_MANIFEST.json');
report.classification = "SPHINX-UNVERIFIED";
report.release = "unknown";
report.manifestSha256 = "unavailable";
report.modifiedFiles = strings(0,1);
report.reason = "core manifest is missing";

if ~isfile(manifestPath)
    return
end

manifestText = fileread(manifestPath);
report.manifestSha256 = fileSha256(manifestPath);
try
    manifest = jsondecode(manifestText);
    report.release = string(manifest.release);
    entries = manifest.coreFiles;
catch
    report.reason = "core manifest is invalid";
    return
end

modified = strings(0,1);
for index = 1:numel(entries)
    relativePath = string(entries(index).path);
    path = fullfile(rootFolder,strrep(relativePath,'/',filesep));
    if ~isfile(path) || ~strcmpi(fileSha256(path),entries(index).sha256)
        modified(end+1,1) = string(relativePath); %#ok<AGROW>
    end
end

report.modifiedFiles = modified;
if isempty(modified)
    report.classification = "SPHINX-CERTIFIED";
    report.reason = "official numerical core verified";
else
    report.classification = "SPHINX-MODIFIED";
    report.reason = "numerical core differs from the official manifest";
end

end

function value = fileSha256(path)
stream = java.io.FileInputStream(java.io.File(path));
cleanup = onCleanup(@() stream.close());
digest = java.security.MessageDigest.getInstance('SHA-256');
buffer = zeros(1,8192,'int8');
while true
    count = stream.read(buffer,0,numel(buffer));
    if count < 0
        break
    end
    digest.update(buffer(1:count));
end
bytes = typecast(digest.digest(),'uint8');
value = lower(reshape(dec2hex(bytes,2).',1,[]));
clear cleanup
end
