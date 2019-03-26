function PeristimulusEventPlot(aedat, specialEventType, timeBeforeUs, timeAfterUs, stepStimuli, maxStimuli, minX, maxX, minY, maxY)

%{
Takes 'aedat' - a data structure containing an imported .aedat file, 
as created by ImportAedat, and creates a peristimulus event plot. This
requires both special event data and polarity data to be present. 
For a chosen type of special event, all polarity events are time-shifted
w.r.t. the nearest special event of that type. Then the events are plotted.

For reference, these are the core special event types:

'0: TIMESTAMP_WRAP' ...
'1: TIMESTAMP_RESET' ...
'2: EXTERNAL_INPUT_RISING_EDGE' ...
'3: EXTERNAL_INPUT_FALLING_EDGE' ...
'4: EXTERNAL_INPUT_PULSE' ...
'5: DVS_ROW_ONLY' ...
'6: EXTERNAL_INPUT1_RISING_EDGE' ...
'7: EXTERNAL_INPUT1_FALLING_EDGE' ...
'8: EXTERNAL_INPUT1_PULSE' ...
'9: EXTERNAL_INPUT2_RISING_EDGE' ...
'10: EXTERNAL_INPUT2_FALLING_EDGE' ...
'11: EXTERNAL_INPUT2_PULSE' ...
'12: EXTERNAL_GENERATOR_RISING_EDGE' ...
'13: EXTERNAL_GENERATOR_FALLING_EDGE' ...
'14: APS_FRAME_START' ...
'15: APS_FRAME_END' ...
'16: APS_EXPOSURE_START' ...
'17: APS_EXPOSURE_END'
%}

if ~exist('timeBeforeUs', 'var') || isempty(timeBeforeUs)
	timeBeforeUs = 5000;
end

if ~exist('stepStimuli', 'var') || isempty(stepStimuli)
	stepStimuli = 1;
end

if ~exist('timeAfterUs', 'var') || isempty(timeAfterUs)
	timeAfterUs = 5000;
end

% Find the timeStamps of the selected special eventz
correctTypeLogical = aedat.data.special.address == specialEventType;
% Convert to signed integer, since time stamp will now be relative to
% stimuli and could be negative
stimulusTimeStamps = int64(aedat.data.special.timeStamp(correctTypeLogical)); 
% if there is a spatial restriction, apply it
selectedPolarityLogical =   aedat.data.polarity.x >= minX & ...
							aedat.data.polarity.x <= maxX & ...
							aedat.data.polarity.y >= minY & ...
							aedat.data.polarity.y <= maxY;
x = aedat.data.polarity.x(selectedPolarityLogical);
y = aedat.data.polarity.y(selectedPolarityLogical);
polarity = aedat.data.polarity.polarity(selectedPolarityLogical);
polarityTimeStamps = int64(aedat.data.polarity.timeStamp(selectedPolarityLogical));


if isempty(stimulusTimeStamps)
	error('There are no special events of the chosen type')
elseif ~exist('maxStimuli', 'var') || isempty(maxStimuli) || maxStimuli > length(stimulusTimeStamps)
	maxStimuli = length(stimulusTimeStamps);
end

% Iterate through special events, searching for boundaries in the polarity timeStamps

eventPointer = 0;

for stimulusIndex = 2 : stepStimuli : maxStimuli
	% Find midway position
	timeBoundary = (stimulusTimeStamps(stimulusIndex - 1) + stimulusTimeStamps(stimulusIndex)) / 2;
	newEventPointer = find(polarityTimeStamps < timeBoundary, 1, 'last');
	polarityTimeStamps(eventPointer + 1 : newEventPointer) = polarityTimeStamps(eventPointer + 1 : newEventPointer) - stimulusTimeStamps(stimulusIndex - 1);
	eventPointer = newEventPointer;
	disp(num2str(stimulusIndex))
end

% Find events in range
chosenLogical = polarityTimeStamps > -timeBeforeUs & ...
				polarityTimeStamps <  timeAfterUs;
			
x = x(chosenLogical);
y = y(chosenLogical);
polarity = polarity(chosenLogical);
polarityTimeStamps = polarityTimeStamps(chosenLogical);
figure
hold all
scatter3(x(polarity),  y(polarity),  polarityTimeStamps(polarity),  '.g')
scatter3(x(~polarity), y(~polarity), polarityTimeStamps(~polarity), '.r')

