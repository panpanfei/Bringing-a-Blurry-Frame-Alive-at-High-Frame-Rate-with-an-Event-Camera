function PlotPolarity(aedat, numFrames, distributeBy, minTime, maxTime, proportionOfPixels, contrast, transpose, flipVertical, flipHorizontal)

%{
Takes 'aedat' - a data structure containing an imported .aedat file, 
as created by ImportAedat, and creates a series of green/red plots of
polarity data. 
The number of subplots is given by the numPlots parameter.
'distributeBy' can either be 'time' or 'events', to decide how the points 
around which data is rendered are chosen.
The events are then recruited by the time points, spreading out until
either they are about to overlap with a neighbouring point, or until 
a certain ratio of an array full is reached. 
flipVertical is assumed true, so that y=0 is considered the top of the image.

This function now pushes most of the computation to the FramesFromEvents
function; however the parameter checking which occurs in there also has to
happen at this level, in order to make a coherent call.
What remains in this function is to interpret the flip and transpose
parameters and do the plot
%}

if ~exist('numFrames', 'var')
	numFrames = 3;
end

if ~exist('distributeBy', 'var')
	distributeBy = 'time';
end

if ~exist('minTime', 'var') || (exist('minTime', 'var') && minTime == 0)
    minTime = double(min(aedat.data.polarity.timeStamp)) / 1e6;
end
if ~exist('maxTime', 'var') || (exist('maxTime', 'var') && maxTime == 0)
    maxTime = double(max(aedat.data.polarity.timeStamp)) / 1e6;
end

% The proportion of an array-full of events which is shown on a plot
if ~exist('proportionOfPixels', 'var')
	proportionOfPixels = 0.1;
end

% The 'contrast' for display of events, as used in jAER.
if ~exist('contrast', 'var')
    contrast = 3;
end

[frames, frameCentreTimes] = FramesFromEvents(aedat, numFrames, distributeBy, minTime, maxTime, proportionOfPixels, contrast);

% Distribute plots in a raster with a 3:4 ratio
numPlotsX = round(sqrt(numFrames / 3 * 4));
numPlotsY = ceil(numFrames / numPlotsX);

if numFrames > 1
    figure
end
for plotCount = 1 : numFrames
    if numFrames > 1
    	subplot(numPlotsY, numPlotsX, plotCount);
    end
	hold all

    frame = squeeze(frames(:, :, plotCount));
	if exist('transpose', 'var') && transpose
        frame = frame';
    end
    image(frame - 1); % I'm not sure why I need that - 1; perhaps the colormap indices are zero-based?
    colormap(redgreencmap(contrast * 2 + 1))
	axis equal tight
	if ~exist('flipVertical', 'var') || flipVertical
		set(gca, 'YDir', 'reverse')
    end
    if exist('flipHorizontal', 'var') && flipHorizontal
		set(gca, 'XDir', 'reverse')
    end
	title([num2str(double(frameCentreTimes(plotCount)) / 1e6) ' s'])
end

