function PlotPolarityAroundATimeByDensity(aedat, time, numTimePoints, numDensities, minProportionOfPixels, maxProportionOfPixels, contrast, transposeVar, flipVertical, flipHorizontal)

%{
Takes 'aedat' - a data structure containing an imported .aedat file, 
as created by ImportAedat, and creates a series of green/red plots of
polarity data. 
Plots in Y have different densities (i.e. proportions of pixels). These
densities are distributed exponentially between the min and max parameters
Plots in X have different centre times. The numTimePoints param must be
odd, and the centre plot in X is the one centred at the parameter 'time'.

For numPlots > 1, the proportionOfPixels used to include events around that
time point is varied logarithmically from minProp.. to maxProp.
Defaults are 0.1 and 1. 
flipVertical is assumed true, so that y=0 is considered the top of the image.
%}

%% Parameters

if ~exist('time', 'var')
	time = (aedat.info.firstTimeStamp + aedat.info.lastTimeStamp) / 2;
else
    time = time * 1e6;
end

if ~exist('numDensities', 'var')
	numDensities = 3;
end

if ~exist('numTimePoints', 'var')
	numTimePoints = 3;
end
if mod(numTimePoints,2) == 0
	numTimePoints = numTimePoints + 1;
end

if ~exist('distributeBy', 'var')
	distributeBy = 'time';
end

if ~exist('minProportionOfPixels', 'var') ...
        || (exist('minProportionOIfPixels', 'var') ...
            && minProportionOfPixels == 0)
    minProportionOfPixels = 0.001;
end
if ~exist('maxProportionOfPixels', 'var') ...
        || (exist('maxProportionOIfPixels', 'var') ...
            && maxProportionOfPixels == 0)
    maxProportionOfPixels = 0.1;
end

% The 'contrast' for display of events, as used in jAER.
if ~exist('contrast', 'var')
    contrast = 3;
end

%% Unpack

% break out the timeStamps for readability
timeStamp   = aedat.data.polarity.timeStamp;
x           = aedat.data.polarity.x;
y           = aedat.data.polarity.y;
polarity    = aedat.data.polarity.polarity;
numEvents   = aedat.data.polarity.numEvents;

%% Produce plots

% Find eventIndex nearest to timePoint
eventIndex = find(timeStamp >= time, 1, 'first');
if isempty(eventIndex)
    eventIndex = numEvents;
end

numPlots = numDensities * numTimePoints;

if numDensities > 1
    % distribute the 
    logMin = log(minProportionOfPixels);
    logMax = log(maxProportionOfPixels);
    logStep = (logMax - logMin) / (numPlots - 1);
    proportionsOfPixels = exp(logMin : logStep : logMax);
    numPixelsInArray = aedat.info.deviceAddressSpace(1) * aedat.info.deviceAddressSpace(2);
    numPixelsToSelectEachWay = ceil(numPixelsInArray * proportionsOfPixels / 2);
    
    figure
else
    numPixelsToSelectEachWay = minProportionOfPixels; % Arbitrrary choice to use the minimum 
end
for densityIndex = 1 : numDensities
    % First do the central timePoint
    firstIndex = max(1, eventIndex - numPixelsToSelectEachWay(plotIndex));
    lastIndex = min(numEvents, eventIndex + numPixelsToSelectEachWay(plotIndex));
    selectedLogical = [false(firstIndex - 1, 1); ...
					true(lastIndex - firstIndex + 1, 1); ...
					false(numEvents - lastIndex, 1)];
    eventsForFrame = struct;
    eventsForFrame.x        = x(selectedLogical);
    eventsForFrame.y        = y(selectedLogical);
    eventsForFrame.polarity = polarity(selectedLogical);
    frame = FrameFromEvents(eventsForFrame, contrast, aedat.info.deviceAddressSpace);
	if exist('transpose', 'var') && transposeVar
        frame = frame';
    end
    image(frame - 1);
    colormap(redgreencmap(contrast * 2 + 1))
	axis equal tight
	if ~exist('flipVertical', 'var') || flipVertical
		set(gca, 'YDir', 'reverse')
    end
    if exist('flipHorizontal', 'var') && flipHorizontal
		set(gca, 'XDir', 'reverse')
    end
	title(['Proportion of pixels: ' num2str(proportionsOfPixels(plotIndex))])
    
    % Then work outwards from the central time point
    lastIndexUp = lastIndex;
    firstIndexDown = firstIndex;
    for timePointsIndex = (numTimePoints - 1) / 2; 
        subplot(numPlotsY, numPlotsX, plotIndex);
        hold all

        firstIndex = max(1, eventIndex - numPixelsToSelectEachWay(plotIndex));
        lastIndex = min(numEvents, eventIndex + numPixelsToSelectEachWay(plotIndex));
        selectedLogical = [false(firstIndex - 1, 1); ...
                        true(lastIndex - firstIndex + 1, 1); ...
                        false(numEvents - lastIndex, 1)];
        eventsForFrame = struct;
        eventsForFrame.x        = x(selectedLogical);
        eventsForFrame.y        = y(selectedLogical);
        eventsForFrame.polarity = polarity(selectedLogical);
        frame = FrameFromEvents(eventsForFrame, contrast, aedat.info.deviceAddressSpace);
        if exist('transpose', 'var') && transposeVar
            frame = frame';
        end
        image(frame - 1);
        colormap(redgreencmap(contrast * 2 + 1))
        axis equal tight
        if ~exist('flipVertical', 'var') || flipVertical
            set(gca, 'YDir', 'reverse')
        end
        if exist('flipHorizontal', 'var') && flipHorizontal
            set(gca, 'XDir', 'reverse')
        end
        title(['Proportion of pixels: ' num2str(proportionsOfPixels(plotIndex))])
    end
end


