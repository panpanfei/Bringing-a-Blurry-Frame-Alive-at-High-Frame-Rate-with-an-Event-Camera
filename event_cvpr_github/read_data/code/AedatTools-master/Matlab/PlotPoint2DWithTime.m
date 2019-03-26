function PlotPoint2DWithTime(aedat, minTime, maxTime, useCurrentAxes)

%{

Takes 'aedat' - a data structure containing an imported .aedat file, 
as created by ImportAedat, and creates a plot of point2D events,
where: 
 - X and Y are X and Y; 
 - Z is the timestamp; 
 - Colour gives the type

% TO DO: MERGE THIS BACK INTO PlotPoint2D
%}

% Unpack

timeStamp = aedat.data.point2D.timeStamp;
x = aedat.data.point2D.x;
y = aedat.data.point2D.y;
type = aedat.data.point2D.type;

if ~exist('minTime', 'var') || (exist('minTime', 'var') && minTime == 0)
    minTime = min(timeStamp);
else
    minTime = minTime * 1e6;
end
if ~exist('maxTime', 'var') || (exist('maxTime', 'var') && maxTime == 0)
    maxTime = max(timeStamp);
else
    maxTime = maxTime * 1e6;
end

% To do: time selection here ...

if ~exist('useCurrentAxes', 'var') || ~useCurrentAxes 
    figure
end

hold all

uniqueTypes = unique(type);

for typeIndex = uniqueTypes'
    selectedByTypeLogical = type == typeIndex;
    plot3(x(selectedByTypeLogical), y(selectedByTypeLogical), timeStamp(selectedByTypeLogical), '.-');    
end
xlim([0 aedat.info.deviceAddressSpace(1)])
ylim([0 aedat.info.deviceAddressSpace(2)])
zlim([0 maxTime])

