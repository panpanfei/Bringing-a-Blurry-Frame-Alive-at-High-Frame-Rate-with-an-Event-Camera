function aedat = ImportAedatDataVersion1or2(aedat)
%{
Code contributions from Gemma Taverni.

This is a sub-function of importAedat - it process the data where the aedat 
file format is determined to be 1 or 2. 
The .aedat file format is documented here:
http://inilabs.com/support/software/fileformat/
This function is based on a combination of the loadaerdat function and
sensor-specific address interpretation functions. 
There is a single input "info", a structure with the following
fields:
	- beginningOfDataPointer - Points to the byte before the beginning of the
		data
	- fileHandle - handle of the open aedat file in question
	- fileFormat - indicates the version of the aedat file format - should
		be either 1 or 2
	- startTime (optional) - if provided, any data with a timeStamp lower
		than this will not be returned.
	- endTime (optional) - if provided, any data with a timeStamp higher than 
		this time will not be returned.
	- startEvent (optional) Any events with a lower count that this will not be returned.
		APS samples, if present, are counted as events. 
	- endEvent (optional) Any events with a higher count that this will not be returned.
		APS samples, if present, are counted as events. 
	- source - a string containing the name of the chip class from
		which the data came. Options are:
		- dvs128 
		- davis240a
		- davis240b
		- davis240c
		- davis128mono 
		- davis128rgb
		- davis208rgbw
		- davis208mono
		- davis346rgb
		- davis346mono 
		- davis346bsi 
		- davis640rgb
		- davis640mono 
		- hdavis640mono 
		- hdavis640rgbw
		- das1
		'file' and 'network' origins are not acceptable - the chip class is
		necessary for the interpretation of the addresses in address-events.
	- dataTypes (optional) cellarray. If present, only data types specified 
		in this cell array are returned. Options are: 
		special; polarity; frame; imu6; imu9; sample; ear; config.
	- subtractResetRead - optional, only for aedat2 and DAVIS - 

The output is a structure with 2 fields.
	- info - the input structure, embelished with other data
	- data a structure which contains one structure for each type of
		data present. These structures are named according to the type of
		data; the options are:
		- special
		- polarity
		- frame
		- imu6
		- sample
		- ear
		Other data types supported in aedat3.0 are not implemented
		because no chip class currently implements them.
		Within each of these structures, there are typically a set of column 
			vectors containing timeStamp, a valid bit and then other data fields, 
			where each vector has the same number of elements. 
			There are some exceptionss to this. 
			In detail the contents of these structures are:
		- special
			- valid (colvector bool)
			- timeStamp (colvector uint32)
			- address (colvector uint32)
		- polarity
			- valid (colvector bool)
			- timeStamp (colvector uint32)
			- x (colvector uint16)
			- y (colvector uint16)
			- polarity (colvector bool)
		- frame
			- valid (bool)
			- frame timeStamp start ???
			- frame timeStamp end ???
			- timeStampExposureStart (uint32)
			- timeStampExposureEnd (uint32)
			- samples (matrix of uint16 r*c, where r is the number of rows and c is 
				the number of columns.)
			- xStart (only present if the frame doesn't start from x=0)
			- yStart (only present if the frame doesn't start from y=0)
			- roiId (only present if this frame has an ROI identifier)
			- colChannelId (optional, if its not present, assume a mono array)
		- imu6
			- valid (colvector bool)
			- timeStamp (colvector uint32)
			- accelX (colvector single)
			- accelY (colvector single)
			- accelZ (colvector single)
			- gyroX (colvector single)
			- gyroY (colvector single)
			- gyroZ (colvector single)
			- temperature (colvector single)
		- sample
			- valid (colvector bool)
			- timeStamp (colvector uint32)
			- sampleType (colvector uint8)
			- sample (colvector uint32)
		- ear
			- valid (colvector bool)
			- timeStamp (colvector uint32)
			- position (colvector uint8)
			- channel (colvector uint16)
			- neuron (colvector uint8)
			- filter (colvector uint8)

Implementation: There is an efficient implementation of startEvent and
EndEvent, since the correct file locations to read from can be determined
in advance. 
However, the implementation of startTime and endTime is not efficient, since
the file is read and then the timestamps are processed.
It is not possible to do better than this, since a binary search through
the file to find the correct file locations in advance could fail due to
non-monotonic timestamps. 
%}

dbstop if error

info = aedat.info;
importParams = aedat.importParams;

% The fileFormat dictates whether there are 6 or 8 bytes per event. 
if info.fileFormat == 1
	numBytesPerAddress = 2;
	numBytesPerEvent = 6;
	addrPrecision = 'uint16';
else
	numBytesPerAddress = 4;
	numBytesPerEvent = 8;
	addrPrecision = 'uint32';
end

fileHandle = aedat.importParams.fileHandle;

% Go to the EOF to find out how long it is
fseek(fileHandle, 0, 'eof');

% Calculate the number of events
info.numEventsInFile = floor((ftell(fileHandle) - info.beginningOfDataPointer) / numBytesPerEvent);

% Check the startEvent and endEvent parameters
if isfield(importParams, 'startEvent')
    startEvent = importParams.startEvent;
else
    startEvent = 1;
end
if startEvent > info.numEventsInFile
	error([	'The file contains ' num2str(info.numEventsInFile) ...
			'; the startEvent parameter is ' num2str(startEvent) ]);
end
if isfield(importParams, 'endEvent')	
	endEvent = importParams.endEvent;
else
	endEvent = info.numEventsInFile;
end
	
if endEvent > info.numEventsInFile
	disp([	'The file contains ' num2str(info.numEventsInFile) ...
			'; the endEvent parameter is ' num2str(endEvents) ...
			'; reducing the endEvent parameter accordingly.']);
		endEvent = info.numEventsInFile;
end
if startEvent >= endEvent 
	error([	'The startEvent parameter is ' num2str(startEvent) ...
		', but the endEvent parameter is ' num2str(endEvent) ]);
end

if isfield(importParams, 'startPacket')
	error('The startPacket parameter is set, but range by packets is not available for .aedat version < 3 files')
end
if isfield(importParams, 'endPacket')
	error('The endPacket parameter is set, but range by events is not available for .aedat version < 3 files')
end

numEventsToRead = endEvent - startEvent + 1;

% Read addresses
disp('Reading addresses ...')
fseek(fileHandle, info.beginningOfDataPointer + numBytesPerEvent * startEvent, 'bof'); 
allAddr = uint32(fread(fileHandle, numEventsToRead, addrPrecision, 4, 'b'));

% Read timestamps
disp('Reading timestamps ...')
fseek(fileHandle, info.beginningOfDataPointer + numBytesPerEvent * startEvent + numBytesPerAddress, 'bof');
allTs = uint32(fread(fileHandle, numEventsToRead, addrPrecision, numBytesPerAddress, 'b'));

% Trim events outside time window
% This is an inefficent implementation, which allows for
% non-monotonic timestamps. 

if isfield(importParams, 'startTime')
    disp('Trimming to start time ...')
	tempIndex = allTs >= startTime * 1e6;
	allAddr = allAddr(tempIndex);
	allTs	= allTs(tempIndex);
end

if isfield(importParams, 'endTime')
    disp('Trimming to end time ...')    
	tempIndex = allTs <= endTime * 1e6;
	allAddr = allAddr(tempIndex);
	allTs	= allTs(tempIndex);
end

% Interpret the addresses
%{ 
- Split between DVS/DAVIS and DAS.
	For DAS1:
		- Special events - external injected events has never been
		implemented for DAS
		- Split between Address events and ADC samples
		- Intepret address events
		- Interpret ADC samples
	For DVS128:
		- Special events - external injected events are on bit 15 = 1;
		there is a more general label for special events which is bit 31 =
		1, but this has ambiguous interpretations; it is also overloaded
		for the stereo pair encoding - ignore this. 
		- Intepret address events
	For DAVIS:
		- Special events
			- Interpret IMU events from special events
		- Interpret DVS events according to chip class
		- Interpret APS events according to chip class
%}

% Declare function for finding specific event types in eventTypes cell array
cellFind = @(string)(@(cellContents)(strcmpi(string, cellContents)));

% Create structure to put all the data in 
data = struct;

%% DAS1

if strcmp(info.source, 'Das1')
	% DAS1 
	sampleMask = hex2dec('1000');
	sampleLogical = bitand(allAddr, sampleMask);
	earLogical = ~sampleLogical;
	if (~isfield(importParams, 'dataTypes') || any(cellfun(cellFind('ear'), importParams.dataTypes))) && any(sampleLogical)
		% ADC Samples
		data.sample.timeStamp = allTs(sampleLogical);
		% Sample type
		sampleTypeMask = hex2dec('1c00'); % take ADC scanner sync and ADC channel together for this value - kludge - the alternative would be to introduce a special event type to represent the scanner wrapping around
		sampleTypeShiftBits = 10;
		data.sample.sampleType = uint8(bitshift(bitand(allAddr(sampleLogical), sampleTypeMask), -sampleTypeShiftBits));
		% Sample data
		sampleDataMask = hex2dec('3FF'); % take ADC scanner sync and ADC channel together for this value - kludge - the alternative would be to introduce a special event type to represent the scanner wrapping around
		data.sample.sample = uint32(bitand(allAddr(sampleLogical), sampleTypeMask));
	end
	if (~isfield(importParams, 'dataTypes') || any(cellfun(cellFind('ear'), importParams.dataTypes))) && any(earLogical)
		% EAR events
		data.ear.timeStamp = allTs(earLogical); 
		% Filter (0 = BPF, 1 = SOS)
		filterMask     = hex2dec('0001');
		data.ear.filter = uint8(bitand(allAddr, filterMask));
		% Position (0 = left; 1 = right)
		positionMask   = hex2dec('0002');
		positionShiftBits = 1;
		data.ear.position = uint8(bitshift(bitand(allAddr, positionMask), -positionShiftBits));
		% Channel (0 (high freq) to 63 (low freq))
		channelMask = hex2dec('00FC');
		channelShiftBits = 2;
		data.ear.channel = uint16(bitshift(bitand(allAddr, channelMask), -channelShiftBits));
		% Neuron (in the range 0-3)
		neuronMask  = hex2dec('0300'); 
		neuronShiftBits = 8;
		data.ear.neuron = uint8(bitshift(bitand(allAddr, neuronMask), -neuronShiftBits));
    end

%% DVS128
    
elseif strcmp(info.source, 'Dvs128')
	% DVS128
	specialMask = hex2dec ('8000');
	specialLogical = boolean(bitand(allAddr, specialMask));
	polarityLogical = ~specialLogical;
	if (~isfield(importParams, 'dataTypes') || any(cellfun(cellFind('special'), importParams.dataTypes))) && any(specialLogical)
		% Special events
		data.special.timeStamp = allTs(specialLogical);
		% No need to create address field, since there is only one type of special event
	end
	if (~isfield(importParams, 'dataTypes') || any(cellfun(cellFind('polarity'), importParams.dataTypes))) && any(polarityLogical)
		% Polarity events
		data.polarity.timeStamp = allTs(polarityLogical); % Use the negation of the special mask for polarity events
		% Y addresses
		yMask = hex2dec('7F00');
		yShiftBits = 8;
		data.polarity.y = uint16(bitshift(bitand(allAddr(polarityLogical), yMask), -yShiftBits));
		% X addresses
		xMask = hex2dec('fE');
		xShiftBits = 1;
		data.polarity.x = uint16(bitshift(bitand(allAddr(polarityLogical), xMask), -xShiftBits));
		% Polarity bit
		polBit = 1;
		data.polarity.polarity = bitget(allAddr(polarityLogical), polBit) == 0;
    end	
    
%% Davis

elseif (~isempty(strfind(info.source, 'Davis')) ...
        && strfind(info.source, 'Davis')) ...
       || (~isempty(strfind(info.source, 'SecDvs')) ... 
           &&strfind(info.source, 'SecDvs'))
	% DAVIS
	% In the 32-bit address:
	% bit 32 (1-based) being 1 indicates an APS sample
	% bit 11 (1-based) being 1 indicates a special event 
	% bits 11 and 32 (1-based) both being zero signals a polarity event
    disp('Constructing logical indices for event types ...')
	apsOrImuMask = hex2dec ('80000000');
	apsOrImuLogical = bitand(allAddr, apsOrImuMask);
	ImuOrPolarityMask = hex2dec ('800');
	ImuOrPolarityLogical = bitand(allAddr, ImuOrPolarityMask);
	signalOrSpecialMask = hex2dec ('400');
	signalOrSpecialLogical = bitand(allAddr, signalOrSpecialMask);
	frameLogical = apsOrImuLogical & ~ImuOrPolarityLogical;
	imuLogical = apsOrImuLogical & ImuOrPolarityLogical;
	polarityLogical = ~apsOrImuLogical & ~signalOrSpecialLogical;
	specialLogical = ~apsOrImuLogical & signalOrSpecialLogical;

	% These masks are used for both frames and polarity events, so are
	% defined outside of the following if statement
	yMask = hex2dec('7FC00000');
	yShiftBits = 22;
	xMask = hex2dec('003FF000');
	xShiftBits = 12;

%% Davis special events

	% Special events
	if (~isfield(importParams, 'dataTypes') || any(cellfun(cellFind('special'), importParams.dataTypes))) && any(specialLogical)
		disp('Importing special events ...')
        data.special.timeStamp = allTs(specialLogical);
		% No need to create address field, since there is only one type of special event
    end

%% Davis polarity events
    
	% Polarity (DVS) events
	if (~isfield(importParams, 'dataTypes') || any(cellfun(cellFind('polarity'), importParams.dataTypes))) && any(polarityLogical)
		disp('Importing polarity events ...')
		data.polarity.timeStamp = allTs(polarityLogical);
		% Y addresses
		data.polarity.y = uint16(bitshift(bitand(allAddr(polarityLogical), yMask), -yShiftBits));
		% X addresses
		data.polarity.x = uint16(bitshift(bitand(allAddr(polarityLogical), xMask), -xShiftBits));
		% Polarity bit
		polBit = 12;		
		data.polarity.polarity = bitget(allAddr(polarityLogical), polBit) == 1;
	end	
	
%% Davis frame events
    
	% NOTE This code currently only handles global shutter readout ...
   
	if (~isfield(importParams, 'dataTypes') || any(cellfun(cellFind('frame'), importParams.dataTypes))) && any(frameLogical)
		disp('Importing frames ...')
		% These two are defined in the format, but not actually necessary to establish the frame boundaries
		% frameLastEventMask = hex2dec ('FFFFFC00');
		% frameLastEvent = hex2dec     ('80000000'); %starts with biggest address
		
		frameSampleMask = bin2dec('1111111111');
		
		frameData = allAddr(frameLogical);
		frameTs = allTs(frameLogical);

		frameX = uint16(bitshift(bitand(frameData, xMask),-xShiftBits));
		frameY = uint16(bitshift(bitand(frameData, yMask),-yShiftBits));
		frameSignal = logical(bitand(frameData, signalOrSpecialMask));
		frameSample = uint16(bitand(frameData, frameSampleMask));
		
		% In general the ramp of address values could be in either
		% direction and either x or y could be the outer(inner) loop
		% Search for a discontinuity in both x and y simultaneously
		frameXDouble = double(frameX);
		frameYDouble = double(frameY);
		frameXDiscont = abs(frameXDouble(2 : end) - frameXDouble(1 : end - 1)) > 1;
		frameYDiscont = abs(frameYDouble(2 : end) - frameYDouble(1 : end - 1)) > 1;
		frameStarts = [1; find(frameXDiscont & frameYDiscont) + 1; length(frameData) + 1]; 
		% Now we have the indices of the first sample in each frame, plus
		% an additional index just beyond the end of the array
		numFrames = length(frameStarts) - 1;
		
		data.frame.reset = false(numFrames, 1);
		data.frame.timeStampStart = zeros(numFrames, 1, 'uint32');
		data.frame.timeStampEnd = zeros(numFrames, 1, 'uint32');
		data.frame.samples = cell(numFrames, 1);
		data.frame.xLength = zeros(numFrames, 1, 'uint16');
		data.frame.yLength = zeros(numFrames, 1, 'uint16');
		data.frame.xPosition = zeros(numFrames, 1, 'uint16');
		data.frame.yPosition = zeros(numFrames, 1, 'uint16');
		
		for frameIndex = 1 : numFrames
			disp(['Processing frame ' num2str(frameIndex)])
			% All within a frame should be either reset or signal. I could
			% implement a check here to see that that's true, but I haven't
			% done so; rather I just take the first value
			data.frame.reset(frameIndex) = ~frameSignal(frameStarts(frameIndex)); 
			
			% in aedat 2 format we don't have the four timestamps of aedat 3 format
			% We expect to find all the same timestamps; 
			% nevertheless search for lowest and highest
			data.frame.timeStampStart(frameIndex) = min(frameTs(frameStarts(frameIndex) : frameStarts(frameIndex + 1) - 1)); 
			data.frame.timeStampEnd(frameIndex) = max(frameTs(frameStarts(frameIndex) : frameStarts(frameIndex + 1) - 1)); 

			tempXPosition = min(frameX(frameStarts(frameIndex) : frameStarts(frameIndex + 1) - 1));
			data.frame.xPosition(frameIndex) = tempXPosition;
			tempYPosition = min(frameY(frameStarts(frameIndex) : frameStarts(frameIndex + 1) - 1));
			data.frame.yPosition(frameIndex) = tempYPosition;
			data.frame.xLength(frameIndex) = max(frameX(frameStarts(frameIndex) : frameStarts(frameIndex + 1) - 1)) - data.frame.xPosition(frameIndex) + 1;
			data.frame.yLength(frameIndex) = max(frameY(frameStarts(frameIndex) : frameStarts(frameIndex + 1) - 1)) - data.frame.yPosition(frameIndex) + 1;
			% If we worked out which way the data is ramping in each
			% direction, and if we could exclude data loss, then we could
			% do some nice clean matrix transformations; but I'm just going
			% to iterate through the samples, putting them in the right
			% place in the array according to their address
			
			% first create a temporary array - there is no concept of
			% colour channels in aedat2
            %{ 
            Code before I learned about 'accumarray':
			tempSamples = zeros(data.frame.yLength(frameIndex), data.frame.xLength(frameIndex), 'uint16');
			for sampleIndex = frameStarts(frameIndex) : frameStarts(frameIndex + 1) - 1
				tempSamples(frameY(sampleIndex) - data.frame.yPosition(frameIndex) + 1, ...
							frameX(sampleIndex) - data.frame.xPosition(frameIndex) + 1) ...
							= frameSample(sampleIndex);
			end
			data.frame.samples{frameIndex} = tempSamples;
            %}
            sampleIndexRange = frameStarts(frameIndex) : frameStarts(frameIndex + 1) - 1;
            data.frame.samples{frameIndex} = accumarray(...
                [frameY(sampleIndexRange) - data.frame.yPosition(frameIndex) + 1 ...
                 frameX(sampleIndexRange) - data.frame.xPosition(frameIndex) + 1], ...
                 frameSample(sampleIndexRange), ...
                 [data.frame.yLength(frameIndex) data.frame.xLength(frameIndex)]);
		end	
		% By default, subtract the reset read 
		if isfield(importParams, 'subtractResetRead')
            subtractResetRead = importParams.subtractResetRead;
        else
            subtractResetRead = true;
        end
		if subtractResetRead && isfield(data.frame, 'reset')
            disp('Performing frame subtraction ...')    
			% Make a second pass through the frames, subtracting reset
			% reads from signal reads
			frameCount = 0;
			for frameIndex = 1 : numFrames
				if data.frame.reset(frameIndex) 
					resetFrame = data.frame.samples{frameIndex};
					resetXPosition = data.frame.xPosition(frameIndex);
					resetYPosition = data.frame.yPosition(frameIndex);
					resetXLength = data.frame.xLength(frameIndex);
					resetYLength = data.frame.yLength(frameIndex);					
				else
					frameCount = frameCount + 1;
					% If a resetFrame has not yet been found, 
					% push through the signal frame as is
					if ~exist('resetFrame', 'var')
						data.frame.samples{frameCount} ...
							= data.frame.samples{frameIndex};
					else
						% If the resetFrame and signalFrame are not the same size,	
						% don't attempt subtraction 
						% (there is probably a cleaner solution than this - could be improved)
						if resetXPosition ~= data.frame.xPosition(frameIndex) ...
							|| resetYPosition ~= data.frame.yPosition(frameIndex) ...
							|| resetXLength ~= data.frame.xLength(frameIndex) ...
							|| resetYLength ~= data.frame.yLength(frameIndex)
							data.frame.samples{frameCount} ...
								= data.frame.samples{frameIndex};
						else
							% Do the subtraction
							data.frame.samples{frameCount} ...
								= resetFrame - data.frame.samples{frameIndex};
                                			% This operation was on unsigned integers, set negatives to zero
                                			data.frame.samples{frameCount}(data.frame.samples{frameCount} > 32767) = 0;

						end
						% Copy over the rest of the info
						data.frame.xPosition(frameCount) = data.frame.xPosition(frameIndex);
						data.frame.yPosition(frameCount) = data.frame.yPosition(frameIndex);
						data.frame.xLength(frameCount) = data.frame.xLength(frameIndex);
						data.frame.yLength(frameCount) = data.frame.yLength(frameIndex);
						data.frame.timeStampStart(frameCount) = data.frame.timeStampStart(frameIndex); 
						data.frame.timeStampEnd(frameCount) = data.frame.timeStampEnd(frameIndex); 							
					end
				end
			end
			% Clip the arrays
			data.frame.xPosition = data.frame.xPosition(1 : frameCount);
			data.frame.yPosition = data.frame.yPosition(1 : frameCount);
			data.frame.xLength = data.frame.xLength(1 : frameCount);
			data.frame.yLength = data.frame.yLength(1 : frameCount);
			data.frame.timeStampStart = data.frame.timeStampStart(1 : frameCount);
			data.frame.timeStampEnd = data.frame.timeStampEnd(1 : frameCount);
			data.frame.samples = data.frame.samples(1 : frameCount);
			data.frame = rmfield(data.frame, 'reset'); % reset is no longer needed
		end
	end
%% Davis IMU events

		% These come in blocks of 7, for the 7 different values produced in
		% a single sample; the following code recomposes these
		% 7 words are sent in series, these being 3 axes for accel, temperature, and 3 axes for gyro
	if (~isfield(importParams, 'dataTypes') || any(cellfun(cellFind('imu6'), importParams.dataTypes))) && any(imuLogical)
		disp('Importing imu6 events ...')
		if mod(nnz(imuLogical), 7) > 0 
			%error('The number of IMU samples is not divisible by 7, so IMU samples are not interpretable')
            % There's a problem here, but chop off the last words and hope
            % for the best ...
		end
		data.imu6.timeStamp = allTs(imuLogical);
		data.imu6.timeStamp = data.imu6.timeStamp(1 : 7 : end - mod(nnz(imuLogical), 7));

		%Conversion factors
		accelScale = 1/8192;
		gyroScale = 1/65.5;
		temperatureScale = 1/340;
		temperatureOffset=35;

		imuDataMask = hex2dec('0FFFF000');
		imuDataShiftBits = 12;
        rawData = bitshift(bitand(allAddr(imuLogical), imuDataMask), -imuDataShiftBits);
        % Now RawData is uint32, but the data is a signed int in the ls 16 bits. 
		rawData = uint16(rawData); % Now any negative indicators are in the MSB
        rawData = typecast(rawData, 'int16'); % Now the same numbers are interpretted as negatives
        rawData = double(rawData); 
        % Now the data is floating point, ready for conversion to physical units
			
		data.imu6.accelX			= rawData(1 : 7 : end - mod(nnz(imuLogical), 7)) * accelScale;	
		data.imu6.accelY			= rawData(2 : 7 : end - mod(nnz(imuLogical), 7)) * accelScale;	
		data.imu6.accelZ			= rawData(3 : 7 : end - mod(nnz(imuLogical), 7)) * accelScale;	
		data.imu6.temperature	= rawData(4 : 7 : end - mod(nnz(imuLogical), 7)) * temperatureScale + temperatureOffset;	
		data.imu6.gyroX			= rawData(5 : 7 : end - mod(nnz(imuLogical), 7)) * gyroScale;	
		data.imu6.gyroY			= rawData(6 : 7 : end - mod(nnz(imuLogical), 7)) * gyroScale;	
		data.imu6.gyroZ			= rawData(7 : 7 : end - mod(nnz(imuLogical), 7)) * gyroScale;	
		
	end

	% If you want to do chip-specific address shifts or subtractions,
	% this would be the place to do it. 

elseif strfind(info.source, 'SecDvs') 
	if (~isfield(importParams, 'dataTypes') || any(cellfun(cellFind('polarity'), importParams.dataTypes))) 
        
		data.polarity.timeStamp = allTs; 
		% Y addresses
		yMask = hex2dec('ff800');
		yShiftBits = 11;
		data.polarity.y = uint16(bitshift(bitand(allAddr, yMask), -yShiftBits));
		% X addresses
		xMask = hex2dec('7fe');
		xShiftBits = 1;
		data.polarity.x = uint16(bitshift(bitand(allAddr, xMask), -xShiftBits));
		% Polarity bit
		polBit = 1;
		data.polarity.polarity = bitget(allAddr, polBit) == 1;
    end
end

%% Pack data

% aedat.importParams is already there and should be unchanged
aedat.info = info;
aedat.data = data;

%% Find first and last time stamps        

aedat = FindFirstAndLastTimeStamps(aedat);

%% Add NumEvents field for each data type

aedat = NumEventsByType(aedat);

disp('Import finished')



