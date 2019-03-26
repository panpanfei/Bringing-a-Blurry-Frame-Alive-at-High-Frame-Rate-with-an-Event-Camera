function [frames, frameCentreTimes] = FramesFromEvents(aedat, numFrames, distributeBy, minTime, maxTime, proportionOfPixels, contrast)

%{
aedat is the standard structure in AedatTools representing a package of 
address-event data as imported from a .aedat file. This should contain 
data.polarity, which should contain at least the fields x, y, and polarity,
column vectors of equal lengths where polarity is boolean
and x and y are zero-based coordinates.
returns 'frames' (uint8) a 3D matrix of plus/minus plots of polarity data a la jAER.
Dim 1 is Y, Dim 2 is X, Dim 3 is frame number. 
Encoding of frames from 0 (full scale OFF events) 
to contrast * 2 (full scale ON events, with contrast representing the
neutral value. 

Takes 'polarity' - a data structure containing an imported .aedat file, 
as created by ImportAedat, and creates a series of green/red plots of
polarity data. 
The number of subplots is given by the numPlots parameter.
'distributeBy' can either be 'time' or 'events', to decide how the points 
around which data is rendered are chosen. If distributeBy is a vector, then
this is taken as the frame centre times.
The events are then recruited by the time points, spreading out until
either they are about to overlap with a neighbouring point, or until 
a certain ratio of an array full is reached. 
%}

% The proportion of an array-full of events which is shown on a plot
% Default is zero, which means that all data out to the frame boundaries is
% used regardless of the amount of data. 
if ~exist('proportionOfPixels', 'var')
	proportionOfPixels = 0;
end

% The 'contrast' for display of events, as used in jAER (aka FS = Full Scale)
if ~exist('contrast', 'var')
    contrast = 3;
end

if ~exist('numFrames', 'var')
	numFrames = 3;
end

if ~exist('distributeBy', 'var')
	distributeBy = 'time';
end

% break out the timeStamps for readability
timeStamp   = aedat.data.polarity.timeStamp;
x           = aedat.data.polarity.x;
y           = aedat.data.polarity.y;
polarity    = aedat.data.polarity.polarity;

% Preallocate the output array
numPixelsInArray = aedat.info.deviceAddressSpace(1) * aedat.info.deviceAddressSpace(2);
numPixelsToSelectEachWay = ceil(numPixelsInArray * proportionOfPixels / 2);
frames = zeros([aedat.info.deviceAddressSpace(2) ...
                aedat.info.deviceAddressSpace(1) ...
                numFrames], ...
               'uint8');

% Parse the minTime and maxTime params
if ~exist('minTime', 'var') || (exist('minTime', 'var') && minTime == 0)
    minTime = min(timeStamp);
else
    minTime = uint32(minTime * 1e6);
end
if ~exist('maxTime', 'var') || (exist('maxTime', 'var') && maxTime == 0)
    maxTime = max(timeStamp);
else
    maxTime = uint32(maxTime * 1e6);
end
numEvents = length(timeStamp); % ignore valid flags - convention for AedatTools
    
% Calculate the time distribution
if strcmpi(distributeBy, 'time')
    totalTime = maxTime - minTime;
    timeStep = totalTime / numFrames;
    frameCentreTimes = minTime + timeStep * 0.5 : timeStep : maxTime;
    frameBoundaryTimes = [minTime frameCentreTimes + timeStep * 0.5];
elseif strcmpi(distributeBy, 'events') % distribute by event number
    eventsPerStep = numEvents / numFrames;
    frameCentreTimes = timeStamp(ceil(eventsPerStep * 0.5 : eventsPerStep : numEvents));
    frameBoundaryTimes = timeStamp([1 ceil(eventsPerStep * 1 : eventsPerStep : numEvents)]);
else % distributeBy is a vector of the frameCentreTimes
    if numel(distributeBy) ~= numFrames
        error('If you provide the frameCentreTimes in the "distributeBy" parameter, then the number of elements must match the numFrames parameter')
    end
    frameCentreTimes = uint64(distributeBy * 1e6); % assume that it is given in secs
    frameBoundaryTimes = uint64([minTime (frameCentreTimes(1 : end - 1) + frameCentreTimes(2 : end)) / 2 maxTime]);
end
    
% frameCentreTimes now contains the division lines between frames.
% If all data is to be used (i.e. ProportionOfPixels == 0) then we instead
% need the time boundaries of each frame; that is frameBoundaryTimes

% Now create the frames one by one
for frameIndex = 1 : numFrames
    if proportionOfPixels == 0
        firstIndex = find(timeStamp >= frameBoundaryTimes(frameIndex), 1, 'first');
        lastIndex = find(timeStamp <= frameBoundaryTimes(frameIndex + 1), 1, 'last');
    else
        % Find eventIndex nearest to timePoint
        eventIndex = find(timeStamp >= frameCentreTimes(frameIndex), 1, 'first');
        firstIndex = max(1, eventIndex - numPixelsToSelectEachWay);
        lastIndex = min(numEvents, eventIndex + numPixelsToSelectEachWay);
    end
    selectedLogical = [false(firstIndex - 1, 1); ...
					true(lastIndex - firstIndex + 1, 1); ...
					false(numEvents - lastIndex, 1)];
    eventsForFrame = struct;
    eventsForFrame.x        = x(selectedLogical);
    eventsForFrame.y        = y(selectedLogical);
    eventsForFrame.polarity = polarity(selectedLogical);
    frames(:, :, frameIndex) = FrameFromEvents(eventsForFrame, contrast, aedat.info.deviceAddressSpace);
end
