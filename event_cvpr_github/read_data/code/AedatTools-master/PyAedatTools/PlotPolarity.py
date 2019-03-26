function PlotPolarity(input, numPlots, distributeBy, minTime, maxTime, proportionOfPixels, contrast, flipVertical, flipHorizontal, transpose)

%{
Takes 'input' - a data structure containing an imported .aedat file, 
as created by ImportAedat, and creates a series of green/red plots of
polarity data. 
The number of subplots is given by the numPlots parameter.
'distributeBy' can either be 'time' or 'events', to decide how the points 
around which data is rendered are chosen.
The events are then recruited by the time points, spreading out until
either they are about to overlap with a neighbouring point, or until 
a certain ratio of an array full is reached. 
%}

% The proportion of an array-full of events which is shown on a plot
if ~exist('proportionOfPixels', 'var')
	proportionOfPixels = 0.1;
end

% The 'contrast' for display of events, as used in jAER.
if ~exist('contrast', 'var')
    contrast = 3;
end

if ~exist('numPlots', 'var')
	numPlots = 3;
end

if ~exist('distributeBy', 'var')
	distributeBy = 'time';
end

% Distribute plots in a raster with a 3:4 ratio
numPlotsX = round(sqrt(numPlots / 3 * 4));
numPlotsY = ceil(numPlots / numPlotsX);

numEvents = length(input.data.polarity.timeStamp); % ignore issue of valid / invalid for now ...
if strcmpi(distributeBy, 'time')
    if ~exist('minTime', 'var') || (exist('minTime', 'var') && minTime == 0)
        minTime = min(input.data.polarity.timeStamp);
    else
        minTime = minTime * 1e6;
    end
    if ~exist('maxTime', 'var') || (exist('maxTime', 'var') && maxTime == 0)
        maxTime = max(input.data.polarity.timeStamp);
    else
        maxTime = maxTime * 1e6;
    end
	totalTime = maxTime - minTime;
	timeStep = totalTime / numPlots;
	timePoints = minTime + timeStep * 0.5 : timeStep : maxTime;
else % distribute by event number
	eventsPerStep = numEvents / numPlots;
	timePoints = input.data.polarity.timeStamp(ceil(eventsPerStep * 0.5 : eventsPerStep : numEvents));
end

minY = double(min(input.data.polarity.y));
maxY = double(max(input.data.polarity.y));
minX = double(min(input.data.polarity.x));
maxX = double(max(input.data.polarity.x));
numPixelsInArray = (maxY - minY) * (maxX - minX);
numPixelsToSelectEachWay = ceil(numPixelsInArray * proportionOfPixels / 2);

if numPlots > 1
    figure
end
for plotCount = 1 : numPlots
    if numPlots > 1
    	subplot(numPlotsY, numPlotsX, plotCount);
    end
	hold all
	% Find eventIndex nearest to timePoint
	eventIndex = find(input.data.polarity.timeStamp >= timePoints(plotCount), 1, 'first');
	firstIndex = max(1, eventIndex - numPixelsToSelectEachWay);
	lastIndex = min(numEvents, eventIndex + numPixelsToSelectEachWay);
	selectedLogical = [false(firstIndex - 1, 1); ...
					true(lastIndex - firstIndex + 1, 1); ...
					false(numEvents - lastIndex, 1)];
	
	% This is how to do a straight plot with contrast of 1, where off (red)
	% events overwrite on (green) events. 
	% onLogical = selectedLogical & input.data.polarity.polarity;
	% offLogical = selectedLogical & ~input.data.polarity.polarity;
	% plot(input.data.polarity.x(onLogical), input.data.polarity.y(onLogical), '.g');
	% plot(input.data.polarity.x(offLogical), input.data.polarity.y(offLogical), '.r');
	
	% However, we will create an image from events with contrast, as used
	% in jAER
	% accumulate the array from the event indices, using an increment of 1
	% for on and a decrement of 1 for off.
    if exist('transpose', 'var') && transpose
    	frameFromEvents = accumarray([input.data.polarity.x(selectedLogical) input.data.polarity.y(selectedLogical)] + 1, input.data.polarity.polarity(selectedLogical) * 2 - 1);
    else
        frameFromEvents = accumarray([input.data.polarity.y(selectedLogical) input.data.polarity.x(selectedLogical)] + 1, input.data.polarity.polarity(selectedLogical) * 2 - 1);
    end
    % Clip the values according to the contrast
	frameFromEvents(frameFromEvents > contrast) = contrast;
	frameFromEvents(frameFromEvents < - contrast) = -contrast;
	frameFromEvents = frameFromEvents + contrast + 1;
	image(frameFromEvents)
    colormap(redgreencmap(contrast * 2 + 1))
	axis equal tight
	if exist('flipVertical', 'var') && flipVertical
		set(gca, 'YDir', 'reverse')
	end
	if exist('flipHorizontal', 'var') && flipHorizontal
		set(gca, 'XDir', 'reverse')
    end
	title([num2str(double(input.data.polarity.timeStamp(eventIndex)) / 1000000) ' s'])
end

