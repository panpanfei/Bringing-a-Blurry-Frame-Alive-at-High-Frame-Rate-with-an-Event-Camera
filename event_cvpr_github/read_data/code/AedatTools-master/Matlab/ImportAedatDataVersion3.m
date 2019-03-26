function aedat = ImportAedatDataVersion3(aedat)
%{
This is a sub-function of importAedat - it process the data where the aedat 
file format is determined to be 3.x
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
		be 3.xx
	- startTime (optional) - if provided, any data with a timeStamp lower
		than this will not be returned.
	- endTime (optional) - if provided, any data with a timeStamp higher than 
		this time will not be returned.
	- startPacket (optional) Any packets with a lower count that this will not be returned.
	- endPacket (optional) Any packets with a higher count that this will not be returned.
	- modPacket (optional) For sparse sampling of a file, 
        packets are imported if mod(packetNumber,modPacket) = 0 
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
		- file
		- network
	- dataTypes (optional) cellarray. If present, only data types specified 
		in this cell array are returned. Options are: 
		special; polarity; frame; imu6; imu9; sample; ear; config; 1dPoint;
		2dPoint; 3dPoint 4dPoint; dynapse

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
			- timeStamp (colvector uint64)
			- address (colvector uint32)
		- polarity
			- valid (colvector bool)
			- timeStamp (colvector uint64)
			- x (colvector uint16)
			- y (colvector uint16)
			- polarity (colvector bool)
		- frame
			- valid (bool)
			- roiId (uint8)
			- colorChannel (uint8)
			- colorFilter (uint8)
			- frame timeStamp start (uint64)
			- frame timeStamp end (uint64)
			- timeStampExposureStart (uint64)
			- timeStampExposureEnd (uint64)
			- samples (cellArray, with one cell for each frame; cells
				contain a matrix of uint16 row*col*chn, where row is the number of rows,
				col is the number of columns, and chn is the number of
				(colour) channels. Where frames have only one channel, the
				third dimension is squeezed out. 
			- xLength (uint32)
			- yLength (uint32)
			- xPosition (uint32)
			- yPosition (uint32)
		- imu6
			- valid (colvector bool)
			- timeStamp (colvector uint64)
			- accelX (colvector single)
			- accelY (colvector single)
			- accelZ (colvector single)
			- gyroX (colvector single)
			- gyroY (colvector single)
			- gyroZ (colvector single)
			- temperature (colvector single)
		- sample
			- valid (colvector bool)
			- timeStamp (colvector uint64)
			- sampleType (colvector uint8)
			- sample (colvector uint32)
		- ear
			- valid (colvector bool)
			- timeStamp (colvector uint64)
			- position (colvector uint8)
			- channel (colvector uint16)
			- neuron (colvector uint8)
			- filter (colvector uint8)

Implementation: There is an efficient implementation of startPacket and
EndPacket, since the correct file locations to read from can be determined
in advance.
There are two possibilities for handling startTime and endTime; one is with
strict capture of events within the prescribed time window. The other is a
loose interpretation with capture of all events whose packets start within
the prescribed time window. It is much more efficient to implement this
second approach, and nevertheless allows a calling function to iterate 
through all the data in bite-sized chunks. 
There is a switch info.strictTime - if this is present and
true then the strict time approach is used, otherwise the packet-based time
approach is used. In the strict approach, data must be accumulated from the
beginning of the file and then cut off once packets' first timestamp is
greater than endTime. In the strict approach, frames are considered part of
the time window if the time which is half way between exposure start and
exposure end is within the time window. 
2016_06_27 Strict time handling is not implemented yet.
Since there is no way to know in advance how big the data vectors must be,
the data vectors/matrices are started off when they are needed 
and are grown by a factor of 2 each time they need to be enlarged. 
At the end of the run they are clipped to the correct size. 
%}

dbstop if error

info = aedat.info;
importParams = aedat.importParams;
fileHandle = importParams.fileHandle;

% Check the startEvent and endEvent parameters
if isfield(importParams, 'startPacket')
    startPacket = importParams.startPacket;
else
	startPacket = 1;
end

if isfield(importParams, 'endPacket')
	endPacket = importParams.endPacket;
else
	endPacket = inf;
end

if startPacket > endPacket 
	error([	'The startPacket parameter is ' num2str(startPacket) ...
		', but the endPacket parameter is ' num2str(endPacket) ]);
end
if isfield(importParams, 'startEvent')
	error('The startEvent parameter is set, but range by events is not available for .aedat version 3.x files')
end
if isfield(importParams, 'endEvent')
	error('The endEvent parameter is set, but range by events is not available for .aedat version 3.x files')
end
if isfield(importParams, 'startTime')
    startTime = importParams.startTime;
else
	startTime = 0;
end
if isfield(importParams, 'endTime')
    endTime = importParams.endTime;
else
	endTime = inf;
end
if startTime > endTime 
	error([	'The startTime parameter is ' num2str(startTime) ...
		', but the endTime parameter is ' num2str(endTime) ]);
end
% By default, throw away timeStampFrameStart/End, 
% renaming timeStampExposureStart/End to timeStampStart/End
if isfield(importParams, 'simplifyFrameTimeStamps')
  simplifyFrameTimeStamps = importParams.simplifyFrameTimeStamps;
else
  simplifyFrameTimeStamps = true;
end

% By default, throw away the valid flags, 
% and any events which are set as invalid.
if isfield(importParams, 'validOnly')
  validOnly = importParams.validOnly;
else
  validOnly = true;
end

% By default, do not skip any packets.
if isfield(importParams, 'modPacket')
  modPacket = importParams.modPacket;
else
  modPacket = 1;
end

%By default, import the full data, rather than just indexing the packets
if isfield(importParams, 'noData') 
  noData = importParams.noData;
else
  noData = false;
end

% By default, import all data types
if isfield(importParams, 'dataTypes')
    allDataTypes = false;
    dataTypes = importParams.dataTypes;
else
    allDataTypes = true;
end

packetCount = 0;

% Has this file already been indexed in a previous pass?
if isfield(info, 'packetPointers')
	packetTypes = info.packetTypes;
	packetPointers = info.packetPointers;
	packetTimeStamps = info.packetTimeStamps;
elseif endPacket < inf
    packetTypes = ones(endPacket, 1, 'uint16');
    packetPointers = zeros(endPacket, 1, 'uint64');
    packetTimeStamps = zeros(endPacket, 1, 'uint64');
else
    packetTypes = ones(1000, 1, 'uint16');
    packetPointers = zeros(1000, 1, 'uint64');
    packetTimeStamps = zeros(1000, 1, 'uint64');
end

if noData == false
    % Create structures to hold the output data

    specialNumEvents	= 0;
    specialValid		= false(0); % initialising this tells the first pass 
                                     % to set up the arrays with the size 
                                     % necessary for the initial packet
    specialDataMask = hex2dec('7E');
    specialDataShiftBits = 1;

    polarityNumEvents	= 0;
    polarityValid		= false(0);
    polarityYMask = hex2dec('1FFFC');
    polarityYShiftBits = 2;
    polarityXMask = hex2dec('FFFE0000');
    polarityXShiftBits = 17;

    frameNumEvents	= 0;
    frameValid		= false(0);
    frameColorChannelsMask = hex2dec('E');
    frameColorChannelsShiftBits = 1;
    frameColorFilterMask = hex2dec('70');
    frameColorFilterShiftBits = 4;
    frameRoiIdMask = hex2dec('3F80');
    frameRoiIdShiftBits = 7;

    imu6NumEvents	= 0;
    imu6Valid		= false(0);

    sampleNumEvents	= 0;
    sampleValid		= false(0);

    earNumEvents	= 0;
    earValid		= false(0);

    point1DNumEvents = 0;
    point1DValid	= false(0);
    point1DTypeMask = hex2dec('FE');
    point1DTypeShiftBits = 1;

    point2DNumEvents = 0;
    point2DValid	= false(0);
    point2DTypeMask = hex2dec('FE');
    point2DTypeShiftBits = 1;

    point3DNumEvents = 0;
    point3DValid	= false(0);
    point3DTypeMask = hex2dec('FE');
    point3DTypeShiftBits = 1;
end
    
    
cellFind = @(string)(@(cellContents)(strcmp(string, cellContents)));

% Go back to the beginning of the data
fseek(fileHandle, info.beginningOfDataPointer, 'bof');

% If the file has been indexed or partially indexed, and there is a
% startPacket or startTime parameter, then jump ahead to the right place
if isfield(info, 'packetPointers') 
    if startPacket > 1 
        fseek(fileHandle, double(packetPointers(startPacket)), 'bof');
        packetCount = startPacket - 1;
    elseif startTime > 0
        targetPacketIndex = find(info.packetTimeStamps < startTime * 1e6, 1, 'last');
        if ~isempty(targetPacketIndex)
            fseek(fileHandle, double(packetPointers(targetPacketIndex)), 'bof');
            packetCount = targetPacketIndex - 1;
        end
    end
end

% If the file has already been indexed (PARTIAL INDEXING NOT HANDLED), and
% we are using modPacket to skip a proportion of the data, then use this
% flag to speed up the loop
modSkipping = isfield(info, 'packetPointers') && modPacket > 1;


while true % implement the exit conditions inside the loop - allows to distinguish between different types of exit
%% Headers
    % Read the header of the next packet
    packetCount = packetCount + 1;
    if modSkipping
        packetCount = ceil(packetCount / modPacket) * modPacket;
        fseek(fileHandle, double(packetPointers(packetCount)), 'bof');
    end
	header = uint8(fread(fileHandle, 28));
    
	if feof(fileHandle)
        packetCount = packetCount - 1;
		info.numPackets = packetCount;
		break
	end
	if length(packetTypes) < packetCount
		% Double the size of packet index arrays as necessary
		packetTypes		= [packetTypes;		ones(packetCount, 1, 'uint16') * 32768];
		packetPointers	= [packetPointers;	zeros(packetCount, 1, 'uint64')];
		packetTimeStamps	= [packetTimeStamps;	zeros(packetCount, 1, 'uint64')];
	end
	packetPointers(packetCount) = ftell(fileHandle) - 28;
	if mod(packetCount, 100) == 0
		disp(['packet: ' num2str(packetCount) '; file position: ' num2str(floor(ftell(fileHandle) / 1000000)) ' MB'])
	end
	if startPacket > packetCount || mod(packetCount, modPacket) > 0 
		% Ignore this packet as its count is too low
		eventSize = typecast(header(5:8), 'int32');
		eventNumber = typecast(header(21:24), 'int32');
		fseek(fileHandle, eventNumber * eventSize, 'cof');
    elseif endPacket < packetCount
        packetCount = packetCount - 1;
		info.numPackets = packetCount;
        break
    else
		eventSize = typecast(header(5:8), 'int32');
		eventTsOffset = typecast(header(9:12), 'int32');
		eventTsOverflow = typecast(header(13:16), 'int32');
		%eventCapacity = typecast(header(17:20), 'int32');
		eventNumber = typecast(header(21:24), 'int32');
		%eventValid = typecast(header(25:28), 'int32');
		% Read the full packet
		numBytesInPacket = eventNumber * eventSize;
		packetData = uint8(fread(fileHandle, numBytesInPacket));
		% Find the first timestamp and check the timing constraints
		packetTimeStampOffset = uint64(eventTsOverflow) * uint64(2^31);
		mainTimeStamp = uint64(typecast(packetData (eventTsOffset + 1 : eventTsOffset + 4), 'int32')) + packetTimeStampOffset;
     	packetTimeStamps(packetCount) = mainTimeStamp;
           
        if mainTimeStamp > endTime * 1e6 && ...
                mainTimeStamp ~= hex2dec('7FFFFFFF') % This may be a timestamp reset - don't let it stop the import
            % Naively assume that the packets are all ordered correctly and finish
            packetCount = packetCount - 1;
            break
        end
        if startTime * 1e6 <= mainTimeStamp
			eventType = typecast(header(1:2), 'int16');
			packetTypes(packetCount) = eventType;
			
			%eventSource = typecast(data(3:4), 'int16'); % Multiple sources not handled yet

            if ~noData
    			% Handle the packet types individually:
    %% Special events
                if eventType == 0 
                    if allDataTypes || any(cellfun(cellFind('special'), dataTypes))
                        % First check if the array is big enough
                        currentLength = length(specialValid);
                        if currentLength == 0
                            specialValid		= false(eventNumber, 1);
                            specialTimeStamp	= zeros(eventNumber, 1, 'uint64');
                            specialAddress		= zeros(eventNumber, 1, 'uint32');
                        else
                            while eventNumber > currentLength - specialNumEvents
                                specialValid		= [specialValid;		false(currentLength, 1)];
                                specialTimeStamp	= [specialTimeStamp;	zeros(currentLength, 1, 'uint64')];
                                specialAddress		= [specialAddress;		zeros(currentLength, 1, 'uint32')];
                                currentLength = length(specialValid);
                                %disp(['Special array resized to ' num2str(currentLength)])
                            end
                        end
                        % Iterate through the events, converting the data and
                        % populating the arrays
                        % TO DO - MATRICISE THIS COMPUTATION, FOLLOWING THE
                        % EXAMPLE IN POLARITY
                        for dataPointer = 1 : eventSize : numBytesInPacket % This points to the first byte for each event
                            specialNumEvents = specialNumEvents + 1;
                            specialValid(specialNumEvents) = mod(packetData(dataPointer), 2) == 1; %Pick off the first bit
                            specialTimeStamp(specialNumEvents) = packetTimeStampOffset + uint64(typecast(packetData(dataPointer + 4 : dataPointer + 7), 'int32'));
                            specialAddress(specialNumEvents) = uint8(bitshift(bitand(packetData(dataPointer), specialDataMask), -specialDataShiftBits));
                        end
                    end
    %% Polarity events
                elseif eventType == 1  
                    if allDataTypes || any(cellfun(cellFind('polarity'), dataTypes))
                        % First check if the array is big enough
                        currentLength = length(polarityValid);
                        if currentLength == 0 
                            polarityValid		= false(eventNumber, 1);
                            polarityTimeStamp	= zeros(eventNumber, 1, 'uint64');
                            polarityX			= zeros(eventNumber, 1, 'uint16');
                            polarityY			= zeros(eventNumber, 1, 'uint16');
                            polarityPolarity	= false(eventNumber, 1);
                        else	
                            while eventNumber > currentLength - polarityNumEvents
                                polarityValid		= [polarityValid;		false(currentLength, 1)];
                                polarityTimeStamp	= [polarityTimeStamp;	zeros(currentLength, 1, 'uint64')];
                                polarityX			= [polarityX;			zeros(currentLength, 1, 'uint16')];
                                polarityY			= [polarityY;			zeros(currentLength, 1, 'uint16')];
                                polarityPolarity	= [polarityPolarity;	false(currentLength, 1)];
                                currentLength = length(polarityValid);
                                %disp(['Polarity array resized to ' num2str(currentLength)])
                            end
                        end
                        dataMatrix = reshape(packetData, [eventSize, eventNumber]);
                        dataTempTimeStamp = dataMatrix(5:8, :);
                        polarityTimeStamp(polarityNumEvents + (1 : eventNumber)) = packetTimeStampOffset + uint64(typecast(dataTempTimeStamp(:), 'int32'));
                        dataTempAddress = dataMatrix(1:4, :);
                        dataTempAddress = typecast(dataTempAddress(:), 'uint32');
                        polarityValid(polarityNumEvents + (1 : eventNumber)) = mod(dataTempAddress, 2) == 1; % Pick off the first bit
                        polarityPolarity(polarityNumEvents + (1 : eventNumber)) = mod(floor(dataTempAddress / 2), 2) == 1; % Pick out the second bit
                        polarityY(polarityNumEvents + (1 : eventNumber)) = uint16(bitshift(bitand(dataTempAddress, polarityYMask), -polarityYShiftBits));
                        polarityX(polarityNumEvents + (1 : eventNumber)) = uint16(bitshift(bitand(dataTempAddress, polarityXMask), -polarityXShiftBits));
                        polarityNumEvents = polarityNumEvents + eventNumber;
                    end
    %% Frames
                elseif eventType == 2
                    if allDataTypes || any(cellfun(cellFind('frame'), dataTypes))
                        % First check if the array is big enough
                        currentLength = length(frameValid);
                        if currentLength == 0
                            frameValid					= false(eventNumber, 1);
                            frameColorChannels			= zeros(eventNumber, 1, 'uint8');
                            frameColorFilter			= zeros(eventNumber, 1, 'uint8');
                            frameRoiId					= zeros(eventNumber, 1, 'uint8');
                            if simplifyFrameTimeStamps
                                frameTimeStampStart     = zeros(eventNumber, 1, 'uint64');
                                frameTimeStampEnd		= zeros(eventNumber, 1, 'uint64');
                            else
                                frameTimeStampFrameStart	= zeros(eventNumber, 1, 'uint64');
                                frameTimeStampFrameEnd		= zeros(eventNumber, 1, 'uint64');
                                frameTimeStampExposureStart = zeros(eventNumber, 1, 'uint64');
                                frameTimeStampExposureEnd	= zeros(eventNumber, 1, 'uint64');
                            end
                            frameXLength				= zeros(eventNumber, 1, 'uint16');
                            frameYLength				= zeros(eventNumber, 1, 'uint16');
                            frameXPosition				= zeros(eventNumber, 1, 'uint16');
                            frameYPosition				= zeros(eventNumber, 1, 'uint16');
                            frameSamples				= cell(eventNumber, 1);
                        else	
                            while eventNumber > currentLength - frameNumEvents
                                frameValid					= [frameValid;                  false(currentLength, 1)];
                                frameColorChannels			= [frameColorChannels;			zeros(currentLength, 1, 'uint8')];
                                frameColorFilter			= [frameColorFilter;			zeros(currentLength, 1, 'uint8')];
                                frameRoiId					= [frameRoiId;					zeros(currentLength, 1, 'uint8')];
                                if simplifyFrameTimeStamps
                                    frameTimeStampStart	= [frameTimeStampStart;         zeros(currentLength, 1, 'uint64')];
                                    frameTimeStampEnd		= [frameTimeStampEnd;		zeros(currentLength, 1, 'uint64')];
                                else
                                    frameTimeStampFrameStart	= [frameTimeStampFrameStart;	zeros(currentLength, 1, 'uint64')];
                                    frameTimeStampFrameEnd		= [frameTimeStampFrameEnd;		zeros(currentLength, 1, 'uint64')];                                
                                    frameTimeStampExposureStart = [frameTimeStampExposureStart; zeros(currentLength, 1, 'uint64')];
                                    frameTimeStampExposureEnd	= [frameTimeStampExposureEnd;	zeros(currentLength, 1, 'uint64')];
                                end
                                frameXLength				= [frameXLength;				zeros(currentLength, 1, 'uint16')];
                                frameYLength				= [frameYLength;				zeros(currentLength, 1, 'uint16')];
                                frameXPosition				= [frameXPosition;				zeros(currentLength, 1, 'uint16')];
                                frameYPosition				= [frameYPosition;				zeros(currentLength, 1, 'uint16')];
                                frameSamples				= [frameSamples;				cell(currentLength, 1)];
                                currentLength = length(frameValid);
                                %disp(['Frame array resized to ' num2str(currentLength)])
                            end
                        end					

                        % Iterate through the events, converting the data and
                        % populating the arrays
                        for dataPointer = 1 : eventSize : numBytesInPacket % This points to the first byte for each event
                            frameNumEvents = frameNumEvents + 1;
                            frameValid(frameNumEvents) = mod(packetData(dataPointer), 2) == 1; % Pick off the first bit
                            frameData = typecast(packetData(dataPointer : dataPointer + 3), 'uint32');
                            frameColorChannels(frameNumEvents) = uint16(bitshift(bitand(frameData, frameColorChannelsMask), -frameColorChannelsShiftBits));
                            frameColorFilter(frameNumEvents)	= uint16(bitshift(bitand(frameData, frameColorFilterMask),	-frameColorFilterShiftBits));
                            frameRoiId(frameNumEvents)		= uint16(bitshift(bitand(frameData, frameRoiIdMask),		-frameRoiIdShiftBits));
                            if simplifyFrameTimeStamps
                                frameTimeStampStart(frameNumEvents)		= packetTimeStampOffset + uint64(typecast(packetData(dataPointer + 12 : dataPointer + 15), 'int32'));
                                frameTimeStampEnd(frameNumEvents)		= packetTimeStampOffset + uint64(typecast(packetData(dataPointer + 16 : dataPointer + 19), 'int32'));
                            else
                                frameTimeStampFrameStart(frameNumEvents)		= packetTimeStampOffset + uint64(typecast(packetData(dataPointer + 4 : dataPointer + 7), 'int32'));
                                frameTimeStampFrameEnd(frameNumEvents)		= packetTimeStampOffset + uint64(typecast(packetData(dataPointer + 8 : dataPointer + 11), 'int32'));
                                frameTimeStampExposureStart(frameNumEvents)	= packetTimeStampOffset + uint64(typecast(packetData(dataPointer + 12 : dataPointer + 15), 'int32'));
                                frameTimeStampExposureEnd(frameNumEvents)		= packetTimeStampOffset + uint64(typecast(packetData(dataPointer + 16 : dataPointer + 19), 'int32'));
                            end
                            frameXLength(frameNumEvents)		= typecast(packetData(dataPointer + 20 : dataPointer + 21), 'uint16'); % strictly speaking these are 4-byte signed integers, but there's no way they'll be that big in practice
                            frameYLength(frameNumEvents)		= typecast(packetData(dataPointer + 24 : dataPointer + 25), 'uint16');
                            frameXPosition(frameNumEvents)	= typecast(packetData(dataPointer + 28 : dataPointer + 29), 'uint16');
                            frameYPosition(frameNumEvents)	= typecast(packetData(dataPointer + 32 : dataPointer + 33), 'uint16');
                            numSamples = int32(frameXLength(frameNumEvents)) * int32(frameYLength(frameNumEvents)) * int32(frameColorChannels(frameNumEvents)); % Conversion to int32 allows addition with 'dataPointer' below
                            % At least one recording has a file ending half way
                            % through the frame data due to a laptop dying,
                            % hence the following check
                            if length(packetData) >= dataPointer + 35 + numSamples * 2
                                sampleData = cast(typecast(packetData(dataPointer + 36 : dataPointer + 35 + numSamples * 2), 'uint16'), 'uint16');
                                frameSamples{frameNumEvents}		= reshape(sampleData, frameColorChannels(frameNumEvents), frameXLength(frameNumEvents), frameYLength(frameNumEvents));
                                if frameColorChannels(frameNumEvents) == 1
                                    frameSamples{frameNumEvents} = squeeze(frameSamples{frameNumEvents});
                                    frameSamples{frameNumEvents} = permute(frameSamples{frameNumEvents}, [2 1]);
                                else
                                    % Change the dimensions of the frame array to
                                    % the standard for matlab: column, then row,
                                    % then channel number
                                    frameSamples{frameNumEvents} = permute(frameSamples{frameNumEvents}, [3 2 1]);
                                end
                            else
                                frameSamples{frameNumEvents} = zeros(frameYLength(frameNumEvents), frameXLength(frameNumEvents), frameColorChannels(frameNumEvents));
                            end
                            % aedat3 uses left-justified 16 bit samples -
                            % for consistency with aedat2, revert to
                            % fundamental 10 bit representation
                            frameSamples{frameNumEvents} = frameSamples{frameNumEvents} / 2^6;
                        end
                        
                    end
    %% IMU6
                elseif eventType == 3
                     if allDataTypes || any(cellfun(cellFind('imu6'), dataTypes))
                        % First check if the array is big enough
                        currentLength = length(imu6Valid);
                        if currentLength == 0 
                            imu6Valid			= false(eventNumber, 1);
                            imu6TimeStamp		= zeros(eventNumber, 1, 'uint64');
                            imu6AccelX			= zeros(eventNumber, 1, 'single');
                            imu6AccelY			= zeros(eventNumber, 1, 'single');
                            imu6AccelZ			= zeros(eventNumber, 1, 'single');
                            imu6GyroX			= zeros(eventNumber, 1, 'single');
                            imu6GyroY			= zeros(eventNumber, 1, 'single');
                            imu6GyroZ			= zeros(eventNumber, 1, 'single');
                            imu6Temperature     = zeros(eventNumber, 1, 'single');
                        else	
                            while eventNumber > currentLength - imu6NumEvents
                                imu6Valid			= [imu6Valid;        false(currentLength, 1)];
                                imu6TimeStamp		= [imu6TimeStamp;    zeros(currentLength, 1, 'uint64')];
                                imu6AccelX			= [imu6AccelX;       zeros(currentLength, 1, 'single')];
                                imu6AccelY			= [imu6AccelY;       zeros(currentLength, 1, 'single')];
                                imu6AccelZ			= [imu6AccelZ;       zeros(currentLength, 1, 'single')];
                                imu6GyroX			= [imu6GyroX;        zeros(currentLength, 1, 'single')];
                                imu6GyroY			= [imu6GyroY;        zeros(currentLength, 1, 'single')];
                                imu6GyroZ			= [imu6GyroZ;        zeros(currentLength, 1, 'single')];
                                imu6Temperature     = [imu6Temperature;  zeros(currentLength, 1, 'single')];                            
                                currentLength = length(imu6Valid);
                            end
                        end
                        % Matricise computation on a packet
                        dataMatrix = reshape(packetData, [eventSize, eventNumber]);
                        dataTempTimeStamp = dataMatrix(5:8, :);
                        imu6TimeStamp(imu6NumEvents + (1 : eventNumber)) = packetTimeStampOffset + uint64(typecast(dataTempTimeStamp(:), 'int32'));
                        % The following is overkill - only need to pick out 1
                        % byte to get to the valid flag
                        dataTempAddress = dataMatrix(1:4, :);
                        dataTempAddress = typecast(dataTempAddress(:), 'uint32');
                        imu6Valid(imu6NumEvents + (1 : eventNumber)) = mod(dataTempAddress, 2) == 1; % Pick off the first bit
                        tempDataMatrix = dataMatrix(9:12, :);
                        imu6AccelX      (imu6NumEvents + (1 : eventNumber)) = typecast(tempDataMatrix(:), 'single');
                        tempDataMatrix = dataMatrix(13:16, :);
                        imu6AccelY      (imu6NumEvents + (1 : eventNumber)) = typecast(tempDataMatrix(:), 'single');
                        tempDataMatrix = dataMatrix(17:20, :);
                        imu6AccelZ      (imu6NumEvents + (1 : eventNumber)) = typecast(tempDataMatrix(:), 'single');
                        tempDataMatrix = dataMatrix(21:24, :);
                        imu6GyroX       (imu6NumEvents + (1 : eventNumber)) = typecast(tempDataMatrix(:), 'single');
                        tempDataMatrix = dataMatrix(25:28, :);
                        imu6GyroY       (imu6NumEvents + (1 : eventNumber)) = typecast(tempDataMatrix(:), 'single');
                        tempDataMatrix = dataMatrix(29:32, :);
                        imu6GyroZ       (imu6NumEvents + (1 : eventNumber)) = typecast(tempDataMatrix(:), 'single');
                        tempDataMatrix = dataMatrix(33:36, :);
                        imu6Temperature (imu6NumEvents + (1 : eventNumber)) = typecast(tempDataMatrix(:), 'single');
                        imu6NumEvents = imu6NumEvents + eventNumber;
                    end
    %% Sample
                elseif eventType == 5
                     if allDataTypes || any(cellfun(cellFind('sample'), dataTypes))
                        %{
                        sampleValid			= bool([]);
                        sampleTimeStamp		= uint64([]);
                        sampleSampleType	= uint8([]);
                        sampleSample		= uint32([]);
                        %}
                    end
    %% Ear
                elseif eventType == 6
                     if allDataTypes || any(cellfun(cellFind('ear'), dataTypes))
                            %{
                            earValid		= bool([]);
                            earTimeStamp	= uint64([]);
                            earPosition 	= uint8([]);
                            earChannel		= uint16([]);
                            earNeuron		= uint8([]);
                            earFilter		= uint8([]);
                            %}				
                    end	
    %% Point1D

                elseif eventType == 8 
                    if allDataTypes || any(cellfun(cellFind('point1D'), dataTypes))
                        % First check if the array is big enough
                        currentLength = length(point1DValid);
                        if currentLength == 0
                            point1DValid		= false(eventNumber, 1);
                            point1DType         = zeros(eventNumber, 1, 'uint8');
                            point1DTimeStamp	= zeros(eventNumber, 1, 'uint64');
                            point1DX            = zeros(eventNumber, 1, 'single');
                        else	
                            while eventNumber > currentLength - point1DNumEvents
                                point1DValid		= [point1DValid;		false(currentLength, 1)];
                                point1DType     	= [point1DType;     	zeros(currentLength, 1, 'uint8')];
                                point1DTimeStamp	= [point1DTimeStamp;	zeros(currentLength, 1, 'uint64')];
                                point1DX            = [point1DX;            zeros(currentLength, 1, 'single')];
                                currentLength = length(point1dValid);
                            end
                        end
                        % Iterate through the events, converting the data and
                        % populating the arrays
                        for dataPointer = 1 : eventSize : numBytesInPacket % This points to the first byte for each event
                            point1DNumEvents = point1DNumEvents + 1;
                            point1DValid(point1DNumEvents) = boolean(bitand(packetData(dataPointer), 1)); %Pick off the first bit
                            point1DType(point1DNumEvents) = bitshift(bitand(packetData(dataPointer), point1DTypeMask), -point1DTypeShiftBits); 
                            point1DTimeStamp(point1DNumEvents) = packetTimeStampOffset + uint64(typecast(packetData(dataPointer + 8 : dataPointer + 11), 'int32'));
                            point1DX(point1DNumEvents) = typecast(packetData(dataPointer + 4 : dataPointer + 7), 'single');
                        end
                    end
    %% Point2D
                elseif eventType == 9 
                    if allDataTypes || any(cellfun(cellFind('point2D'), dataTypes))
                        % First check if the array is big enough
                        currentLength = length(point2DValid);
                        if currentLength == 0
                            point2DValid		= false(eventNumber, 1);
                            point2DType         = zeros(eventNumber, 1, 'uint8');
                            point2DTimeStamp	= zeros(eventNumber, 1, 'uint64');
                            point2DX            = zeros(eventNumber, 1, 'single');
                            point2DY            = zeros(eventNumber, 1, 'single');
                        else	
                            while eventNumber > currentLength - point2DNumEvents
                                point2DValid		= [point2DValid;		false(currentLength, 1)];
                                point2DType     	= [point2DType;     	zeros(currentLength, 1, 'uint8')];
                                point2DTimeStamp	= [point2DTimeStamp;	zeros(currentLength, 1, 'uint64')];
                                point2DX            = [point2DX;            zeros(currentLength, 1, 'single')];
                                point2DY            = [point2DY;            zeros(currentLength, 1, 'single')];
                                currentLength = length(point2DValid);
                            end
                        end
                        % Iterate through the events, converting the data and
                        % populating the arrays
                        for dataPointer = 1 : eventSize : numBytesInPacket % This points to the first byte for each event
                            point2DNumEvents = point2DNumEvents + 1;
                            point2DValid(point2DNumEvents) = boolean(bitand(packetData(dataPointer), 1)); %Pick off the first bit
                            point2DType(point2DNumEvents) = bitshift(bitand(packetData(dataPointer), point2DTypeMask), -point2DTypeShiftBits); 
                            point2DTimeStamp(point2DNumEvents) = packetTimeStampOffset + uint64(typecast(packetData(dataPointer + 12 : dataPointer + 15), 'int32'));
                            point2DX(point2DNumEvents) = typecast(packetData(dataPointer + 4 : dataPointer + 7), 'single');
                            point2DY(point2DNumEvents) = typecast(packetData(dataPointer + 8 : dataPointer + 11), 'single');
                        end
                    end
    %% Point3D
                elseif eventType == 10 
                    if allDataTypes || any(cellfun(cellFind('point3D'), dataTypes))
                        % First check if the array is big enough
                        currentLength = length(point3DValid);
                        if currentLength == 0
                            point3DValid		= false(eventNumber, 1);
                            point3DType         = zeros(eventNumber, 1, 'uint8');
                            point3DTimeStamp	= zeros(eventNumber, 1, 'uint64');
                            point3DX            = zeros(eventNumber, 1, 'single');
                            point3DY            = zeros(eventNumber, 1, 'single');
                            point3DZ            = zeros(eventNumber, 1, 'single');
                        else	
                            while eventNumber > currentLength - point3DNumEvents
                                point3DValid		= [point3DValid;		false(currentLength, 1)];
                                point3DType     	= [point3DType;     	zeros(currentLength, 1, 'uint8')];
                                point3DTimeStamp	= [point3DTimeStamp;	zeros(currentLength, 1, 'uint64')];
                                point3DX            = [point3DX;            zeros(currentLength, 1, 'single')];
                                point3DY            = [point3DY;            zeros(currentLength, 1, 'single')];
                                point3DZ            = [point3DZ;            zeros(currentLength, 1, 'single')];
                                currentLength = length(point3DValid);
                            end
                        end
                        % Iterate through the events, converting the data and
                        % populating the arrays
                        for dataPointer = 1 : eventSize : numBytesInPacket % This points to the first byte for each event
                            point3DNumEvents = point3DNumEvents + 1;
                            point3DValid(point3DNumEvents) = boolean(bitand(packetData(dataPointer), 1)); %Pick off the first bit
                            point3DType(point3DNumEvents) = bitshift(bitand(packetData(dataPointer), point3DTypeMask), -point3DTypeShiftBits); 
                            point3DTimeStamp(point3DNumEvents) = packetTimeStampOffset + uint64(typecast(packetData(dataPointer + 16 : dataPointer + 19), 'int32'));
                            point3DX(point3DNumEvents) = typecast(packetData(dataPointer + 4 : dataPointer + 7), 'single');
                            point3DY(point3DNumEvents) = typecast(packetData(dataPointer + 8 : dataPointer + 11), 'single');
                            point3DZ(point3DNumEvents) = typecast(packetData(dataPointer + 12 : dataPointer + 15), 'single');
                        end
                    end
                else
                    error('Unknown event type')
                end
            end
        end
	end
	if packetCount == endPacket
		break
	end
end

%% Clip data arrays to correct size

if noData == false

    outputData = struct;

    if specialNumEvents > 0
        keepLogical = false(size(specialValid, 1), 1);
        keepLogical(1:specialNumEvents) = true; 
        special.valid = specialValid(keepLogical); 
        special.timeStamp = specialTimeStamp(keepLogical);
        special.address = specialAddress(keepLogical);
        outputData.special = special;
    end

    if polarityNumEvents > 0
        keepLogical = false(size(polarityValid, 1), 1);
        keepLogical(1:polarityNumEvents) = true; 
        polarity.valid = polarityValid(keepLogical);
        polarity.timeStamp	= polarityTimeStamp(keepLogical);
        polarity.y			= polarityY(keepLogical);
        polarity.x			= polarityX(keepLogical);
        polarity.polarity	= polarityPolarity(keepLogical);
        outputData.polarity = polarity;
    end

    if frameNumEvents > 0
        keepLogical = false(size(frameValid, 1), 1);
        keepLogical(1:frameNumEvents) = true; 
        frame.valid = frameValid(keepLogical);
        frame.roiId					= frameRoiId(keepLogical);
        frame.colorChannels			= frameColorChannels(keepLogical);
        frame.colorFilter			= frameColorFilter(keepLogical);
        if simplifyFrameTimeStamps
            frame.timeStampStart	= frameTimeStampStart(keepLogical);
            frame.timeStampEnd		= frameTimeStampEnd(keepLogical);
        else
            frame.timeStampFrameStart	= frameTimeStampFrameStart(keepLogical);
            frame.timeStampFrameEnd		= frameTimeStampFrameEnd(keepLogical);
            frame.timeStampExposureStart = frameTimeStampExposureStart(keepLogical);
            frame.timeStampExposureEnd	= frameTimeStampExposureEnd(keepLogical);
        end
        frame.samples				= frameSamples(keepLogical);
        frame.xLength				= frameXLength(keepLogical);
        frame.yLength				= frameYLength(keepLogical);
        frame.xPosition				= frameXPosition(keepLogical);
        frame.yPosition				= frameYPosition(keepLogical);
        outputData.frame = frame;
    end

    if imu6NumEvents > 0
        keepLogical = false(size(imu6Valid, 1), 1);
        keepLogical(1:imu6NumEvents) = true; 
        imu6.valid = imu6Valid(keepLogical);
        imu6.timeStamp	= imu6TimeStamp(keepLogical);
        imu6.gyroX		= imu6GyroX(keepLogical);
        imu6.gyroY		= imu6GyroY(keepLogical);
        imu6.gyroZ		= imu6GyroZ(keepLogical);
        imu6.accelX		= imu6AccelX(keepLogical);
        imu6.accelY		= imu6AccelY(keepLogical);
        imu6.accelZ		= imu6AccelZ(keepLogical);
        imu6.temperature = imu6Temperature(keepLogical);
        outputData.imu6 = imu6;
    end

    if sampleNumEvents > 0
        keepLogical = false(size(sampleValid, 1), 1);
        keepLogical(1:sampleNumEvents) = true; 
        sample.valid = sampleValid(keepLogical);
        sample.timeStamp	= sampleTimeStamp(keepLogical);
        sample.sampleType	= sampleSampleType(keepLogical);
        sample.sample		= sampleSample(keepLogical);
        outputData.sample = sample;
    end

    if earNumEvents > 0
        keepLogical = false(size(earValid, 1), 1);
        keepLogical(1:earNumEvents) = true; 
        ear.valid = earValid(keepLogical); 
        ear.timeStamp	= earTimeStamp(keepLogical);
        ear.position	= earosition(keepLogical);
        ear.channel		= earChannel(keepLogical);
        ear.neuron		= earNeuron(keepLogical);
        ear.filter		= earFilter(keepLogical);
        outputData.ear = ear;
    end

    if point1DNumEvents > 0
        keepLogical = false(size(point1DValid, 1), 1);
        keepLogical(1:point1DNumEvents) = true; 
        point1D.valid       = point1DValid      (keepLogical); 
        point1D.type        = point1DType       (keepLogical); 
        point1D.timeStamp   = point1DTimeStamp  (keepLogical);
        point1D.x           = point1DX          (keepLogical);
        outputData.point1D = point1D;
    end

    if point2DNumEvents > 0
        keepLogical = false(size(point2DValid, 1), 1);
        keepLogical(1:point2DNumEvents) = true; 
        point2D.valid       = point2DValid      (keepLogical); 
        point2D.type        = point2DType       (keepLogical); 
        point2D.timeStamp   = point2DTimeStamp  (keepLogical);
        point2D.x           = point2DX          (keepLogical);
        point2D.y           = point2DY          (keepLogical);
        outputData.point2D = point2D;
    end
    
    if point3DNumEvents > 0
        keepLogical = false(size(point3DValid, 1), 1);
        keepLogical(1:point3DNumEvents) = true; 
        point3D.valid       = point3DValid      (keepLogical); 
        point3D.type        = point3DType       (keepLogical); 
        point3D.timeStamp   = point3DTimeStamp  (keepLogical);
        point3D.x           = point3DX          (keepLogical);
        point3D.y           = point3DY          (keepLogical);
        point3D.z           = point3DZ          (keepLogical);
        outputData.point3D = point3D;
    end
end

%% Pack packet info 
info.packetTypes	= packetTypes(1 : packetCount);
info.packetPointers	= packetPointers(1 : packetCount);
info.packetTimeStamps	= packetTimeStamps(1 : packetCount);

%% Calculate data volume by type

% This calculation excludes the final packet for simplicity. 
% It doesn't handle partial imports or invalid data.

packetSizes = [info.packetPointers(2 : end) - info.packetPointers(1 : end - 1) - 28; 0];
info.dataVolumeByEventType = {};
eventTypesTemp = info.packetTypes;
eventTypesTemp(eventTypesTemp == 32768) = 0;
for eventType = max(eventTypesTemp): -1 : 0 % counting down means the array is only assigned once
	info.dataVolumeByEventType(eventType + 1, 1 : 2) = [{EventTypes(eventType)} sum(packetSizes(info.packetTypes == eventType))];
end

%% Pack the data into the output structure

aedat.info = info;
if exist ('outputData', 'var')
    aedat.data = outputData;
end
% the unpacked importParams should not have been changed

%% Remove invalid events

if validOnly && noData == false
	aedat = RemoveInvalidEvents(aedat);
end

%% Add NumEvents field for each data type

if noData == false
    aedat = NumEventsByType(aedat);
end

%% Find first and last time stamps      

if noData == false
    aedat = FindFirstAndLastTimeStamps(aedat);
end

disp('Import finished')

