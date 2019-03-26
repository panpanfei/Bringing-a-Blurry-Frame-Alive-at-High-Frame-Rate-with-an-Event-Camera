def PlotFrame(aedat, numPlots, distributeBy, minTime, maxTime, transpose, flipVertical, flipHorizontal)

%{
Takes 'aedat' - a data structure containing an imported .aedat file, 
as created by ImportAedat, and creates a series of images from selected
frames.
The number of subplots is given by the numPlots parameter.
'distributeBy' can either be 'time' or 'events', to decide how the points 
around which data is rendered are chosen. 
The frame events are then chosen as those nearest to the time points.
If the 'distributeBy' is 'time' then if the further parameters 'minTime' 
and 'maxTime' are used then the time window used is only between
those limits.
flipVertical is assumed true, so that y=0 is considered the top of the image.
%}

if ~exist('distributeBy', 'var')
	distributeBy = 'time';
end

if ~exist('numPlots', 'var')
	numPlots = 12;
end

% This function assumes that aedat3 frame timestamps have been simplified
timeStamps = aedat.data.frame.timeStampStart;
% This function plots all frames, assuming that they are valid; 
% it assumes that reset read subtraction has been performed
numFrames = length(aedat.data.frame.samples); 
if numFrames < numPlots
	numPlots = numFrames;
end

if numFrames == numPlots
	distributeBy = 'events';    
end

% Distribute plots in a raster with a 3:4 ratio
numPlotsX = round(sqrt(numPlots / 3 * 4));
numPlotsY = ceil(numPlots / numPlotsX);

if strcmpi(distributeBy, 'time')
    if ~exist('minTime', 'var') || (exist('minTime', 'var') && minTime == 0)
        minTime = min(timeStamps);
    else
        minTime = minTime * 1e6;
    end
    if ~exist('maxTime', 'var') || (exist('maxTime', 'var') && maxTime == 0)
        maxTime = max(timeStamps);
    else
        maxTime = maxTime * 1e6;
    end

	totalTime = maxTime - minTime;
	timeStep = totalTime / numPlots;
	timePoints = minTime + timeStep * 0.5 : timeStep : maxTime;
else % distribute by event number
	framesPerStep = numFrames / numPlots;
	timePoints = timeStamps(ceil(framesPerStep * 0.5 : framesPerStep : numFrames));
end

if numPlots > 1
    figure
end
for plotCount = 1 : numPlots
	if numPlots > 1
        subplot(numPlotsY, numPlotsX, plotCount);
	end
	hold all
	% Find eventIndex nearest to timePoint
	frameIndex = find(timeStamps >= timePoints(plotCount), 1, 'first');
	% Ignore colour for now ...    
	if exist('transpose', 'var') && transpose
        imagesc(aedat.data.frame.samples{frameIndex}')
    else
        imagesc(aedat.data.frame.samples{frameIndex})
	end
    colormap('gray')
	axis equal tight
	if ~exist('flipVertical', 'var') || ~flipVertical
		set(gca, 'YDir', 'reverse')
	end
	if exist('flipHorizontal', 'var') && flipHorizontal
		set(gca, 'XDir', 'reverse')
	end
	title(['Time: ' num2str(round(double(timeStamps(frameIndex)) / 1000) /1000) ' s; frame number: ' num2str(frameIndex)])
end

