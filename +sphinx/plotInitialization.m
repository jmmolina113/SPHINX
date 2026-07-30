function figures = plotInitialization(sim,varargin)
%SPHINX.PLOTINITIALIZATION Display initialized fields in 1D, 2D, or 3D.
%   FIGURES = SPHINX.PLOTINITIALIZATION(SIM) materializes SIM with
%   SPHINX.PREPARE and displays quantum/scalar and electromagnetic figures.
%   It does not advance time or write output.
%
%   Solver fields use [y,x,z] ordering. One-dimensional fields are line
%   plots, two-dimensional fields are planar maps, and three-dimensional
%   fields are orthogonal center slices.
%
%   FIGURES = SPHINX.PLOTINITIALIZATION(...,"FigureVisible","off") creates
%   hidden figures for testing or scripted export.

parser = inputParser;
parser.FunctionName = 'sphinx.plotInitialization';
addParameter(parser,'FigureVisible',"on",@(value) any(strcmpi(string(value),["on","off"])))
parse(parser,varargin{:})
figureVisible = char(string(parser.Results.FigureVisible));

if ischar(sim) || isstring(sim)
    sim = sphinx.problem(sim);
end

sim = sphinx.validateProblem(sim);
[psi,A,Y,V,R,params] = sphinx.prepare(sim);

plotCoordinates = R;
plotCoordinates.x = R.x/params.phys.lambda;
plotCoordinates.y = R.y/params.phys.lambda;
plotCoordinates.z = R.z/params.phys.lambda;

Psi = psi.R + 1i*psi.I;
density = abs(Psi).^2;
phase = angle(Psi);
dimension = sum(sim.domain.grid > 1);

figures = gobjects(1,2);
figures(1) = figure('Name','SPHINX quantum initialization', ...
    'NumberTitle','off','Visible',figureVisible);
quantumLayout = tiledlayout(figures(1),2,3,'TileSpacing','compact','Padding','compact');

plotScalar(nexttile(quantumLayout),psi.R,plotCoordinates,sim,"Re(\psi)","\psi_R / \psi_0",dimension)
plotScalar(nexttile(quantumLayout),psi.I,plotCoordinates,sim,"Im(\psi)","\psi_I / \psi_0",dimension)
plotScalar(nexttile(quantumLayout),density,plotCoordinates,sim,"|\psi|^2","|\psi|^2 / |\psi_0|^2",dimension)
plotScalar(nexttile(quantumLayout),phase,plotCoordinates,sim,"arg(\psi)","phase [rad]",dimension)
plotScalar(nexttile(quantumLayout),V,plotCoordinates,sim,"Scalar potential V","V / \epsilon",dimension)

summaryAxis = nexttile(quantumLayout);
axis(summaryAxis,'off')
text(summaryAxis,0,1,initializationSummary(sim,params), ...
    'VerticalAlignment','top','Interpreter','none','FontName','FixedWidth')
title(quantumLayout,sprintf('Quantum initialization (%dD)',dimension))

figures(2) = figure('Name','SPHINX electromagnetic initialization', ...
    'NumberTitle','off','Visible',figureVisible);
emLayout = tiledlayout(figures(2),2,3,'TileSpacing','compact','Padding','compact');

components = ["x","y","z"];
for componentIndex = 1:3
    component = components(componentIndex);
    plotScalar(nexttile(emLayout),A.(component),plotCoordinates,sim, ...
        "A_" + component,"A_" + component + " / A_0",dimension)
end
for componentIndex = 1:3
    component = components(componentIndex);
    plotScalar(nexttile(emLayout),Y.(component),plotCoordinates,sim, ...
        "Y_" + component,"Y_" + component + " / Y_0",dimension)
end
title(emLayout,sprintf('Electromagnetic initialization (%dD)',dimension))

end

function plotScalar(plotAxis,field,R,sim,plotTitle,colorLabel,dimension)
%PLOTSCALAR Select a representation consistent with the active dimensions.

activeAxes = find(sim.domain.grid > 1);
axisNames = ["x","y","z"];

switch dimension
    case 1
        activeAxis = activeAxes(1);
        coordinateName = axisNames(activeAxis);
        values = extractLine(field,activeAxis);
        plot(plotAxis,R.(coordinateName),values,'LineWidth',1.5)
        xlabel(plotAxis,coordinateName + " / \lambda")
        ylabel(plotAxis,colorLabel)
        grid(plotAxis,'on')

    case 2
        horizontalAxis = activeAxes(1);
        verticalAxis = activeAxes(2);
        horizontalName = axisNames(horizontalAxis);
        verticalName = axisNames(verticalAxis);
        plane = extractPlane(field,horizontalAxis,verticalAxis);
        imagesc(plotAxis,R.(horizontalName),R.(verticalName),plane)
        axis(plotAxis,'image')
        set(plotAxis,'YDir','normal')
        xlabel(plotAxis,horizontalName + " / \lambda")
        ylabel(plotAxis,verticalName + " / \lambda")
        colorbar(plotAxis)

    case 3
        xCenter = R.x(ceil(end/2));
        yCenter = R.y(ceil(end/2));
        zCenter = R.z(ceil(end/2));
        slice(plotAxis,R.x,R.y,R.z,field,xCenter,yCenter,zCenter)
        shading(plotAxis,'interp')
        axis(plotAxis,'tight')
        view(plotAxis,3)
        xlabel(plotAxis,"x / \lambda")
        ylabel(plotAxis,"y / \lambda")
        zlabel(plotAxis,"z / \lambda")
        colorbar(plotAxis)

    otherwise
        error('SPHINX initialization plots require one to three active dimensions.')
end

title(plotAxis,plotTitle)

end

function values = extractLine(field,activeAxis)
%EXTRACTLINE Return a vector ordered along x, y, or z.

storageDimension = [2,1,3];
indices = repmat({':'},1,3);

for physicalAxis = setdiff(1:3,activeAxis)
    dimensionIndex = storageDimension(physicalAxis);
    indices{dimensionIndex} = ceil(size(field,dimensionIndex)/2);
end

values = squeeze(field(indices{:}));
values = values(:);

end

function plane = extractPlane(field,horizontalAxis,verticalAxis)
%EXTRACTPLANE Return [vertical,horizontal] data for any active axis pair.

storageDimension = [2,1,3];
inactiveAxis = setdiff(1:3,[horizontalAxis,verticalAxis]);
indices = repmat({':'},1,3);
inactiveStorageDimension = storageDimension(inactiveAxis);
indices{inactiveStorageDimension} = ceil(size(field,inactiveStorageDimension)/2);
selected = field(indices{:});

remainingStorageDimensions = storageDimension([verticalAxis,horizontalAxis]);
permutation = [remainingStorageDimensions, ...
    setdiff(1:3,remainingStorageDimensions,'stable')];
plane = squeeze(permute(selected,permutation));

end

function summaryText = initializationSummary(sim,params)
%INITIALIZATIONSUMMARY Provide compact context beside the field plots.

summaryText = sprintf([ ...
    'model: %s\n' ...
    'boundary: %s\n' ...
    'grid: %d x %d x %d\n' ...
    'q: %.6g\n' ...
    'm: %.6g\n' ...
    'hbar: %.6g\n' ...
    'delta: %.6g\n' ...
    'x0: %.6g\n' ...
    'y0: %.6g'], ...
    sim.model,sim.boundary,sim.domain.grid, ...
    params.phys.q,params.phys.m,params.phys.hbar, ...
    params.phys.delta,params.phys.x0,params.phys.y0);

end
