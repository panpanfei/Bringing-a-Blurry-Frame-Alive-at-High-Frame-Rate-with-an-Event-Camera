function aedat = ImportSecGen3(aedat, fileId)
%{
This function works similarly to ImportAedat, but takes instead data from 
SEC DVS Gen3. These .bin files have no header info, therefore they are not 
compatible with ImportAedat.

Expects the aedat.importParams.filePath parameter to contain a .bin file.
If, however the suffix is not .bin, it assumes that it has been passed a
folder path and takes the most recent file in the folder.
 
If fileId is supplied then it takes the fileId'th .bin file rather than the
last one
%}

dbstop if error

% Unpack parameters
importParams = aedat.importParams;

%% Open the file

if ~isfield(importParams, 'filePath') || ~strcmp(importParams.filePath(end -3 : end), '.bin') 
    % Open the newest file
    % Note: For this to work at the moment, matlab must already be in the
    % correct directory
    directoryListing = dir('*.bin');
    [~, fileIndex] = sort([directoryListing.datenum]);
    aedat.info.numFilesInDirectory = length(fileIndex);
    if aedat.info.numFilesInDirectory == 0
        error('No .bin files in current directory')
    end
    if exist('fileId', 'var') && fileId > 0
        filePath = directoryListing(fileIndex(fileId)).name;
    else
        filePath = directoryListing(fileIndex(end)).name;
    end
    importParams.filePath = filePath;
else
    filePath = importParams.filePath;
end

fileHandle = fopen(filePath, 'r');

if fileHandle == -1
    error('file not found')
end

% Go to the EOF to find out how long it is
fseek(fileHandle, 0, 'eof');

% Find the number of packets
numPacketsInFile = ftell(fileHandle) / 4;

%% Check parameters

% Check the startEvent and endEvent parameters - if present, this shall 
% actually refer to packets.
if isfield(importParams, 'startPacket')
    startPacket = importParams.startPacket;
elseif isfield(importParams, 'startEvent')
    startPacket = importParams.startEvent;
else
    startPacket = 1;
end
if startPacket > numPacketsInFile
	error([	'The file contains ' num2str(numPacketsInFile) ...
			'; the startEvent/startPacket parameter is ' num2str(startPacket)]);
end
if isfield(importParams, 'endPacket')	
    endPacket = importParams.endPacket;
elseif isfield(importParams, 'endEvent')	
    endPacket = importParams.endEvent;
else
    endPacket = numPacketsInFile;
end
	
if endPacket > numPacketsInFile
	disp([	'The file contains ' num2str(numPacketsInFile) ...
			'; the endEvent/endPacket parameter is ' num2str(endPacket) ...
			'; reducing the endPacket parameter accordingly.']);
        endPacket = numPacketsInFile;
end
if startPacket >= endPacket 
	error([	'The startEvent/Packet parameter is ' num2str(startEvent) ...
		', but the endEvent/Packet parameter is ' num2str(endEvent) ]);
end

if isfield(importParams, 'startTime')
    startTime = importParams.startTime * 1e6 / 2^10;
else
    startTime = 0;
end

if isfield(importParams, 'endTime')
    endTime = importParams.endTime * 1e6 / 2^10;
else
    endTime = inf;
end

numPacketsToRead = endPacket - startPacket + 1;

%% Read data

disp('Reading data ...')
fseek(fileHandle, 0, 'bof'); 
allPackets = uint32(fread(fileHandle, numPacketsToRead, 'uint32', 0, 'b'));

%% Prepare to unpack data

% Let's just do this iteratively for now; not sure how to matricise this,
% though see below for a half-baked attempt

%% Prepare data masks

majorTimeStampMask        = bin2dec('0000 0000 0011 1111 1111 1111 1111 1111');
minorTimeStampMask        = bin2dec('0000 0000 0001 1111 1111 1000 0000 0000');
columnAddressMask         = bin2dec('0000 0000 0000 0000 0000 0011 1111 1111');
majorRowAddressMask       = bin2dec('0000 0000 1111 1100 0000 0000 0000 0000');
minorRowAddressAndPolMask = bin2dec('0000 0000 0000 0000 1111 1111 1111 1111'); 

%This following oneshot mask allows the identification of events to add
%from the one-shot encoding
minorRowAndPolOneShotMask = uint16(2 .^ (0:15)');
oneShotPolarity = [true(8, 1); false(8, 1)];
oneShotMinorRowAddress = uint16(repmat((0:7)', 2, 1));

% Loop variables
numEventsProcessed = 0;
currentLengthOfEventVectors = 1024;
majorTimeStamp = 0;
timeStampOffset = 0;
columnAddress = uint16(0);
minorTimeStamp = uint32(0);

% Data arrays
timeStamp	= zeros(currentLengthOfEventVectors, 1, 'uint32');
x			= zeros(currentLengthOfEventVectors, 1, 'uint16');
y			= zeros(currentLengthOfEventVectors, 1, 'uint16');
polarity    = false(currentLengthOfEventVectors, 1);

%% Unpack events by iterating through packets

for packetIndex = startPacket : endPacket
    if mod(packetIndex, 100000) == 0
		disp(['packet: ' num2str(packetIndex) '; ' ...
              'file position: ' num2str(floor(packetIndex / 2^17)) ' MB; ' ...
              '(' num2str(floor((packetIndex - startPacket + 1) / (endPacket - startPacket + 1) * 100)) '%)'])
	end

    currentPacket = allPackets(packetIndex);
    packetCode = bitshift(currentPacket, -26);
    if packetCode == 2 % 0b000001
        % Timestamp packet
        currentTimeStamp = bitand(currentPacket, majorTimeStampMask);
        if majorTimeStamp == 0
            timeStampOffset = currentTimeStamp - 1;
        end
        majorTimeStamp = bitshift(currentTimeStamp - timeStampOffset, 10);
    else
        % apply startTime only to the majorTimeStamp - note that rezero is
        % automatic in this import, so actually comparing to the
        % timeStampOffset

        if startTime <= timeStampOffset
            if endTime < timeStampOffset
                break
            end
            if packetCode == 1 % 0b000001
                % Column address packet
                minorTimeStamp = bitshift(bitand(currentPacket, majorTimeStampMask), -11);
                columnAddress = uint16(bitand(currentPacket, columnAddressMask));
            elseif packetCode == 32 % 0b100000
                % Events packet
                majorRowAddress       = uint16(bitshift(bitand(currentPacket, majorRowAddressMask), -15));
                minorRowAndPolOneShot = uint16(bitand(currentPacket, minorRowAddressAndPolMask));
                minorRowAndPolLogical = logical(bitand(minorRowAndPolOneShot, minorRowAndPolOneShotMask));
                numNewEvents          = nnz(minorRowAndPolLogical);
                polarityNew           = oneShotPolarity(minorRowAndPolLogical);
                minorRowAddress       = oneShotMinorRowAddress(minorRowAndPolLogical);
                numEventsProcessed = numEventsProcessed + numNewEvents;
                while numEventsProcessed > currentLengthOfEventVectors
                    timeStamp	= [timeStamp;	zeros(currentLengthOfEventVectors, 1, 'uint32')];
                    x			= [x;			zeros(currentLengthOfEventVectors, 1, 'uint16')];
                    y			= [y;			zeros(currentLengthOfEventVectors, 1, 'uint16')];
                    polarity    = [polarity;	false(currentLengthOfEventVectors, 1)];
                    currentLengthOfEventVectors = currentLengthOfEventVectors * 2;
                end
                rangeStart = numEventsProcessed - numNewEvents + 1;
                timeStamp(rangeStart : numEventsProcessed) = majorTimeStamp + minorTimeStamp;
                x        (rangeStart : numEventsProcessed) = columnAddress; 
                y        (rangeStart : numEventsProcessed) = majorRowAddress + minorRowAddress; 
                polarity (rangeStart : numEventsProcessed) = polarityNew; 

            else
                error('packet formation error')
            end
        end
    end
end

%% Crop the data arrays and pack

aedat.importParams = importParams;

aedat.info.source = 'SecDvsGen3';
aedat.info.deviceAddressSpace = [320 480];

if numEventsProcessed > 0 
    polarityArray = polarity;
    polarity = [];
    keepLogical = [true(numEventsProcessed, 1); false(currentLengthOfEventVectors - numEventsProcessed, 1)]; 
    polarity.timeStamp	= timeStamp(keepLogical);
    polarity.y			= y(keepLogical) - 8; % These subtractions are because of the 1-based encoding in the SEC packet format
    polarity.x			= x(keepLogical) - 1; % These subtractions are because of the 1-based encoding in the SEC packet format
    polarity.polarity	= polarityArray(keepLogical);
    aedat.data.polarity = polarity;
    
    % Find first and last time stamps        
    aedat = FindFirstAndLastTimeStamps(aedat);

    % Add NumEvents field for each data type
    aedat = NumEventsByType(aedat);
end

disp('Import finished')


%% Half-baked approach to matricising computation
%{ 

msb = bitget(allPackets, 32);
secondMsb = bitget(allPackets, 31);

eventsLogical = msb & secondMsb;
columnLogical = msb & ~secondMsb;
timeStampLogical = ~msb & secondMsb;

timeStamps = zeros(numPackets, 1, 'uint32');
timeStamps(timeStampLogical) = bitshift(allPackets(timeStampLogical), 10);
timeStamps = FloodFillColumnDownwards(timeStamps);

%}


