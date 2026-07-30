function files = produce(data,analysis,products,varargin)
%SPHINX.POST.PRODUCE Create selected post-production files from one run.
%   FILES = SPHINX.POST.PRODUCE(DATA,ANALYSIS,PRODUCTS) creates any of:
%   "summary", "conservation", "energy_breakdown", "snapshot", "lineout",
%   "movie", and "workspace". DATA comes from SPHINX.POST.IMPORTRUN and
%   ANALYSIS from SPHINX.POST.ANALYZE.
%
%   Name-value controls:
%       OutputFolder  runFolder/processedData by default
%       Field         scalar field name, default "probability"
%       Plane         "x", "y", or "z" for snapshots/movies, default "z"
%       Coordinate    nearest physical plane coordinate, default 0
%       Snapshot      "first", "middle", "last", saved step, or index
%       LineAxis      varying axis for lineouts, default "x"
%       FixedPoint    [x,y,z] physical coordinates, default [0,0,0]
%       FrameRate     movie frame rate, default 8
%       Visible       "off" (default) or "on"

parser = inputParser;
parser.FunctionName = 'sphinx.post.produce';
addParameter(parser,'OutputFolder',fullfile(data.sourceFolder,'processedData'))
addParameter(parser,'Field',"probability")
addParameter(parser,'Plane',"z")
addParameter(parser,'Coordinate',0)
addParameter(parser,'Snapshot',"last")
addParameter(parser,'LineAxis',"x")
addParameter(parser,'FixedPoint',[0,0,0])
addParameter(parser,'FrameRate',8)
addParameter(parser,'Visible',"off")
parse(parser,varargin{:})
options = parser.Results;

products = reshape(lower(string(products)),1,[]);
validProducts = ["summary","conservation","energy_breakdown", ...
    "snapshot","lineout","movie","workspace"];
assert(all(ismember(products,validProducts)), ...
    'Unknown product. Run sphinx.post.options for the supported products.')

outputFolder = string(options.OutputFolder);
if ~isfolder(outputFolder)
    mkdir(outputFolder)
end
files = strings(0,1);

for productIndex = 1:numel(products)
    product = products(productIndex);
    switch product
        case "summary"
            path = fullfile(outputFolder,'diagnostics.csv');
            writetable(summaryTable(analysis),path)
        case "conservation"
            path = fullfile(outputFolder,'conservation.png');
            figureHandle = conservationFigure(analysis,options.Visible);
            savePng(figureHandle,path)
            close(figureHandle)
        case "energy_breakdown"
            path = fullfile(outputFolder,'energy_breakdown.png');
            figureHandle = energyFigure(analysis,options.Visible);
            savePng(figureHandle,path)
            close(figureHandle)
        case "snapshot"
            path = fullfile(outputFolder,options.Field + "_snapshot.png");
            figureHandle = snapshotFigure(data,options);
            savePng(figureHandle,path)
            close(figureHandle)
        case "lineout"
            path = fullfile(outputFolder,options.Field + "_lineout.png");
            figureHandle = lineoutFigure(data,options);
            savePng(figureHandle,path)
            close(figureHandle)
        case "movie"
            path = fullfile(outputFolder,options.Field + "_" + options.Plane + "_movie.mp4");
            writeMovie(data,path,options)
        case "workspace"
            path = fullfile(outputFolder,'postproduction.mat');
            save(path,'data','analysis','-v7.3')
    end
    files(end+1,1) = path; %#ok<AGROW>
end

fprintf('Created %d post-production files in:\n%s\n',numel(files),outputFolder)

end

function savePng(figureHandle,path)
%SAVEPNG Use MATLAB's batch-safe print path instead of screen capture.
set(figureHandle,'Renderer','painters')
print(figureHandle,path,'-dpng','-r180')
end

function output = summaryTable(analysis)
output = table(analysis.savedSteps(:),analysis.time(:), ...
    'VariableNames',{'Step','Time'});
if isfield(analysis,'probability')
    output.Probability = analysis.probability.integral;
    output.ProbabilityRelativeDrift = analysis.probability.relativeDrift;
end
if isfield(analysis,'energy')
    output.ElectromagneticEnergy = analysis.energy.electromagnetic;
    output.QuantumEnergy = analysis.energy.quantum;
    output.TotalEnergy = analysis.energy.total;
    output.TotalEnergyRelativeDrift = analysis.energy.totalRelativeDrift;
end
end

function figureHandle = conservationFigure(analysis,visibility)
assert(isfield(analysis,'probability') && isfield(analysis,'energy'), ...
    'Conservation output requires probability and energy diagnostics.')
figureHandle = figure('Visible',visibility,'Color','w','Position',[100,100,1200,700]);
tiledlayout(2,2,'Padding','compact','TileSpacing','compact')
nexttile
plot(analysis.time,analysis.probability.integral,'k','LineWidth',1.8)
xlabel('time'); ylabel('probability'); grid on
nexttile
plot(analysis.time,analysis.energy.electromagnetic,'b','LineWidth',1.6); hold on
plot(analysis.time,analysis.energy.quantum,'r','LineWidth',1.6)
plot(analysis.time,analysis.energy.total,'k','LineWidth',1.8); hold off
xlabel('time'); ylabel('energy'); legend('EM','QM','total','Location','best'); grid on
nexttile
plot(analysis.time,analysis.probability.relativeDrift,'k','LineWidth',1.8)
xlabel('time'); ylabel('(P-P_0)/P_0'); grid on
nexttile
plot(analysis.time,analysis.energy.totalRelativeDrift,'k','LineWidth',1.8)
xlabel('time'); ylabel('(H-H_0)/H_0'); grid on
sgtitle('SPHINX conservation diagnostics')
end

function figureHandle = energyFigure(analysis,visibility)
assert(isfield(analysis,'energy'),'Energy breakdown requires energy diagnostics.')
figureHandle = figure('Visible',visibility,'Color','w','Position',[100,100,1200,520]);
tiledlayout(1,2,'Padding','compact','TileSpacing','compact')
nexttile
plot(analysis.time,analysis.energy.magnetic,'b','LineWidth',1.6); hold on
plot(analysis.time,analysis.energy.electric,'r','LineWidth',1.6)
plot(analysis.time,analysis.energy.electromagnetic,'k','LineWidth',1.8); hold off
xlabel('time'); ylabel('energy'); title('Electromagnetic energy')
legend('magnetic','electric','total','Location','best'); grid on
nexttile
plot(analysis.time,analysis.energy.quantumGradient,'b','LineWidth',1.6); hold on
plot(analysis.time,analysis.energy.quantumCoupling,'r','LineWidth',1.6)
plot(analysis.time,analysis.energy.quantumPotential,'Color',[0,.5,0],'LineWidth',1.6)
plot(analysis.time,analysis.energy.quantum,'k','LineWidth',1.8); hold off
xlabel('time'); ylabel('energy'); title('Quantum energy')
legend('gradient','A coupling','potential','total','Location','best'); grid on
end

function figureHandle = snapshotFigure(data,options)
history = resolveField(data,string(options.Field));
timeIndex = resolveSnapshot(data,options.Snapshot);
[imageData,horizontal,vertical,labels] = planeSlice(history,data.coordinates, ...
    timeIndex,string(options.Plane),options.Coordinate);
figureHandle = figure('Visible',options.Visible,'Color','w','Position',[100,100,760,650]);
imagesc(horizontal,vertical,imageData); axis image xy
colorbar; xlabel(labels(1)); ylabel(labels(2))
title(sprintf('%s at t = %.6g, %s = %.6g',options.Field,data.time(timeIndex), ...
    options.Plane,nearestCoordinate(data.coordinates,string(options.Plane),options.Coordinate)))
end

function figureHandle = lineoutFigure(data,options)
history = resolveField(data,string(options.Field));
timeIndex = resolveSnapshot(data,options.Snapshot);
[lineData,coordinate,fixed] = extractLineout(history,data.coordinates,timeIndex, ...
    string(options.LineAxis),options.FixedPoint);
figureHandle = figure('Visible',options.Visible,'Color','w','Position',[100,100,850,480]);
plot(coordinate,lineData,'k','LineWidth',1.8); grid on
xlabel(string(options.LineAxis)); ylabel(string(options.Field))
title(sprintf('%s lineout at t = %.6g through (%.4g, %.4g, %.4g)', ...
    options.Field,data.time(timeIndex),fixed))
end

function writeMovie(data,path,options)
history = resolveField(data,string(options.Field));
writer = VideoWriter(path,'MPEG-4');
writer.FrameRate = options.FrameRate;
open(writer)
cleanupObject = onCleanup(@() close(writer));
figureHandle = figure('Visible',options.Visible,'Color','w','Position',[100,100,760,650]);
figureCleanup = onCleanup(@() close(figureHandle));
limits = [min(history,[],'all'),max(history,[],'all')];
for timeIndex = 1:numel(data.time)
    [imageData,horizontal,vertical,labels] = planeSlice(history,data.coordinates, ...
        timeIndex,string(options.Plane),options.Coordinate);
    imagesc(horizontal,vertical,imageData); axis image xy
    if limits(1) < limits(2), clim(limits); end
    colorbar; xlabel(labels(1)); ylabel(labels(2))
    title(sprintf('%s at t = %.6g',options.Field,data.time(timeIndex)))
    drawnow
    writeVideo(writer,getframe(figureHandle))
end
clear cleanupObject figureCleanup
end

function history = resolveField(data,name)
switch lower(name)
    case "probability", history = data.psi.probability;
    case "psir", history = data.psi.R;
    case "psii", history = data.psi.I;
    otherwise
        token = regexp(name,'^(A|Y|B|E|J)(x|y|z)$','tokens','once','ignorecase');
        if isempty(token)
            token = regexp(name,'^poynting(x|y|z)$','tokens','once','ignorecase');
            assert(~isempty(token),'Unknown field %s. Run sphinx.post.options.',name)
            history = data.poynting.(lower(token{1}));
        else
            history = data.(upper(token{1})).(lower(token{2}));
        end
end
end

function index = resolveSnapshot(data,request)
if ischar(request) || isstring(request)
    switch lower(string(request))
        case "first", index = 1;
        case "middle", index = ceil(numel(data.time)/2);
        case "last", index = numel(data.time);
        otherwise, error('Snapshot must be first, middle, last, a saved step, or an index.')
    end
elseif ismember(request,data.savedSteps)
    index = find(data.savedSteps == request,1);
elseif isscalar(request) && request >= 1 && request <= numel(data.time)
    index = request;
else
    error('Requested snapshot was not imported.')
end
end

function [imageData,horizontal,vertical,labels] = planeSlice(history,R,timeIndex,plane,coordinate)
field = reshape(history(timeIndex,:,:,:),size(history,2),size(history,3),size(history,4));
switch lower(plane)
    case "x"
        index = nearestIndex(R.x,coordinate);
        imageData = squeeze(field(:,index,:))'; horizontal = R.y; vertical = R.z;
        labels = ["y","z"];
    case "y"
        index = nearestIndex(R.y,coordinate);
        imageData = squeeze(field(index,:,:))'; horizontal = R.x; vertical = R.z;
        labels = ["x","z"];
    case "z"
        index = nearestIndex(R.z,coordinate);
        imageData = squeeze(field(:,:,index)); horizontal = R.x; vertical = R.y;
        labels = ["x","y"];
    otherwise
        error('Plane must be x, y, or z.')
end
end

function [lineData,coordinate,fixedPoint] = extractLineout(history,R,timeIndex,axisName,fixedPoint)
assert(numel(fixedPoint) == 3,'FixedPoint must be [x,y,z].')
field = reshape(history(timeIndex,:,:,:),size(history,2),size(history,3),size(history,4));
ix = nearestIndex(R.x,fixedPoint(1)); iy = nearestIndex(R.y,fixedPoint(2));
iz = nearestIndex(R.z,fixedPoint(3));
fixedPoint = [R.x(ix),R.y(iy),R.z(iz)];
switch lower(axisName)
    case "x", lineData = squeeze(field(iy,:,iz)); coordinate = R.x;
    case "y", lineData = squeeze(field(:,ix,iz)); coordinate = R.y;
    case "z", lineData = squeeze(field(iy,ix,:)); coordinate = R.z;
    otherwise, error('LineAxis must be x, y, or z.')
end
end

function index = nearestIndex(vector,value)
[~,index] = min(abs(vector-value));
end

function value = nearestCoordinate(R,axisName,requested)
vector = R.(axisName);
value = vector(nearestIndex(vector,requested));
end
