function ExportAedat2(aedat)

%{
This function exports data to a .aedat file in format version 2.
The .aedat file format is documented here:
http://inilabs.com/support/software/fileformat/

Just merges polarity, frame and imu6 at the moment.

If there is a timestamp reset, events before and after it will be mixed
together. Make sure to cut out time before any resets, or otherwise
monotonise the timestamps for each data type separately before applying
this function.

%}

%% validation of parameters

dbstop if error

if ~exist('aedat', 'var')
    error('Missing input')
end

if ~isfield(aedat, 'exportParams') || ~isfield(aedat.exportParams, 'filePath')
    error('Missing parameter exportParams.filePath')
end

% For source, use an override if it has been given. This allows data from
% one sensor to masquerade as data from another sensor.

if isfield(aedat.exportParams, 'source')
    source = aedat.exportParams.source;
else
    source = aedat.info.source;
end

%% General preparation

% Create overall containers
allTimeStamps = uint32([]);
allSamples = uint32([]);

% Declare function for finding specific event types in eventTypes cell array
cellFind = @(string)(@(cellContents)(strcmp(string, cellContents)));

%% Polarity

if isfield(aedat.data, 'polarity') ...
        && (~isfield(aedat.exportParams, 'dataTypes') ...
        || any(cellfun(cellFind('polarity'), aedat.exportParams.dataTypes)))
    
    
    disp('Preparing polarity data ...')
    
    if strcmp(source, 'Dvs128')
        % In the 32-bit address:
        % bit 1 (1-based) is polarity
        % bit 2-8 is x
        % bit 9-15 is y
        % bit 16 is special
        
        yShiftBits = 8;
        xShiftBits = 1;
        polShiftBits = 0;
    else % Default to DAVIS
        % In the 32-bit address:
        % bit 32 (1-based) being 1 indicates an APS sample
        % bit 11 (1-based) being 1 indicates a special event
        % bits 11 and 32 (1-based) both being zero signals a polarity event
        
        yShiftBits = 22;
        xShiftBits = 12;
        polShiftBits = 11;
    end
    
    y = bitshift(uint32(aedat.data.polarity.y), yShiftBits);
    x = bitshift(uint32(aedat.data.polarity.x), xShiftBits);
    pol = bitshift(uint32(aedat.data.polarity.polarity), polShiftBits);
    allSamples = [allSamples; y + x + pol];
    allTimeStamps = [allTimeStamps; uint32(aedat.data.polarity.timeStamp)];
end

%% Frame

if isfield(aedat.data, 'frame') ...
        && (~isfield(aedat.exportParams, 'dataTypes') ...
        || any(cellfun(cellFind('frame'), aedat.exportParams.dataTypes)))
    disp('Preparing frame data ...')
    yShiftBits = 22;
    xShiftBits = 12;
    % frameShiftBits = 0;
    frameFlagShiftBits = 31;
    signalFlagShiftBits = 10;
    
    frameData = aedat.data.frame;
    
    numFrames = frameData.numEvents;
    xDim = aedat.info.deviceAddressSpace(1);
    yDim = aedat.info.deviceAddressSpace(2);
    numPixels = xDim * yDim;
    
    % Allocate horizontal vectors to hold output data.
    % Why are the vectors that big? The factor of 2 is because
    % we insert dummy 'reset' frames prior to each frame.
    samples = uint32(zeros(1, 2 * numFrames * numPixels));
    timeStamps = uint32(zeros(2 * numFrames * numPixels, 1));
    
    % The output vector is twice as big again because samples and timeStamps
    % will be interspersed in the 'output' vector.
    y = repmat(uint32(yDim - 1 : -1 : 0)', xDim * numFrames * 2, 1); % y ramps down
    x = repmat(uint32(0 : xDim - 1), yDim, numFrames * 2);           % but x ramps up
    x = x(:);
    % in bit 11 (1-based) 1 means signal read and 0 means reset read.
    signalFlag = repmat([zeros(numPixels, 1, 'uint32');  ...
        bitshift(ones(numPixels, 1, 'uint32'), signalFlagShiftBits)], ...
        numFrames, 1);
    % The last event mask is synonymous with the sample from x=0 y=0; data is
    % therefore ordered backwards.
    for frameIndex = 1 : numFrames
        samplesTemp = frameData.samples{frameIndex}(:);
        samplesTemp = samplesTemp(end : -1 : 1);
        samples((frameIndex * 2 - 1) * numPixels + 1 : frameIndex * 2 * numPixels) ...
            = samplesTemp ;
        timeStamps((frameIndex - 1) * 2 * numPixels + 1 : frameIndex * 2 * numPixels) ...
            = frameData.timeStampStart(frameIndex);
    end
    frameFlag = bitshift(1, frameFlagShiftBits, 'uint32');
    y = bitshift(y, yShiftBits, 'uint32');
    x = bitshift(x, xShiftBits, 'uint32');
    % samples should now be in the range 0-1023 (10-bit).
    % subtract samples from 1023. This has the effect of leaving all the reset
    % frame samples at 1023 - the highest value, against which the signal frames
    % will later be subtracted.
    samples = 1023 - samples';
    
    allSamples = [allSamples; frameFlag + y + x + signalFlag + samples];
    allTimeStamps = [allTimeStamps; timeStamps];
end

%% IMU6


if isfield(aedat.data, 'imu6') ...
        && (~isfield(aedat.exportParams, 'dataTypes') ...
        || any(cellfun(cellFind('imu6'), aedat.exportParams.dataTypes)))
    disp('Preparing imu6 data ...')
    
    imuFlag = uint32(0);
    imuFlag = bitset(imuFlag, 31+1);
    imuFlag = bitset(imuFlag, 11+1);
    imuFlag = bitset(imuFlag, 10+1);
    accelXFlag      = bitshift(uint32(0), 28);
    accelYFlag      = bitshift(uint32(1), 28);
    accelZFlag      = bitshift(uint32(2), 28);
    temperatureFlag = bitshift(uint32(3), 28);
    gyroXFlag       = bitshift(uint32(4), 28);
    gyroYFlag       = bitshift(uint32(5), 28);
    gyroZFlag       = bitshift(uint32(6), 28);
    
    accelX = convertAccelUint32(aedat.data.imu6.accelX);
    accelX = accelX + imuFlag + accelXFlag;
    
    accelY = convertAccelUint32(aedat.data.imu6.accelY);
    accelY = accelY + imuFlag + accelYFlag;
    
    accelZ = convertAccelUint32(aedat.data.imu6.accelZ);
    accelZ = accelZ + imuFlag + accelZFlag;
    
    temp = aedat.data.imu6.temperature; % conversion from g to full scale, and shift bits
    temp = int16((temp - 35) * 340); % conversion from K to full scale 16 range
    temp = [temp zeros(aedat.data.imu6.numEvents, 1, 'int16')];
    temp = temp';
    temp = temp(:);
    temp = typecast(temp, 'uint32');
    temp = bitshift(temp, 12); % shift bits
    temp = temp + imuFlag + temperatureFlag;
    
    gyroX = convertGyroUint32(aedat.data.imu6.gyroX);
    gyroX = gyroX + imuFlag + gyroXFlag;
    
    gyroY = convertGyroUint32(aedat.data.imu6.gyroY);
    gyroY = gyroY + imuFlag + gyroYFlag;
    
    gyroZ = convertGyroUint32(aedat.data.imu6.gyroZ);
    gyroZ = gyroZ + imuFlag + gyroZFlag;
    
    allData = [accelX accelY accelZ temp gyroX gyroY gyroZ];
    allData = allData';
    allData = allData(:);
    
    timeStamps = uint32(aedat.data.imu6.timeStamp(:));
    timeStamps = repmat(timeStamps', 7 , 1);
    timeStamps = timeStamps(:);
    
    allSamples = [allSamples; allData];
    allTimeStamps = [allTimeStamps; timeStamps];
end

%% Sort the events by timestamp

disp('Sorting events ...')

[allTimeStamps, sortIndex] = sort(allTimeStamps);
allSamples = allSamples(sortIndex);

output = zeros(1, length(allSamples) * 2, 'uint32');

output(1:2:end) = allSamples;
output(2:2:end) = allTimeStamps; % set even elements to timestamps

%% Write to file

disp('Writing to file ...')

% Create the file
f = fopen(aedat.exportParams.filePath, 'w', 'b');

if ~isfield(aedat.exportParams, 'noHeader') || aedat.exportParams.noHeader == false
    
    % CRLF \r\n is needed to not break header parsing in jAER
    fprintf(f,'#!AER-DAT2.0\r\n');
    fprintf(f,'# This is a raw AE data file created by an export function in the AedatTools library\r\n');
    fprintf(f,'# Data format is int32 address, int32 timestamp (8 bytes total), repeated for each event\r\n');
    fprintf(f,'# Timestamps tick is 1 us\r\n');
    fprintf(f,['# AEChip: ' source '\r\n']);
    fprintf(f,'# End of ASCII Header\r\n');
end

% write addresses and timestamps
count = fwrite(f, output, 'uint32', 0, 'b') / 2; % write 4 byte data
fclose(f);
fprintf('wrote %d events to %s\n', count, aedat.exportParams.filePath);



function accel = convertAccelUint32(accel)
% Conversion from g to full scale, and shift bits
accel = int16(accel * 8192); % conversion from g to full scale 16 range
accel = [accel zeros(numel(accel), 1, 'int16')];
accel = accel';
accel = accel(:);
accel = typecast(accel, 'uint32');
accel = bitshift(accel, 12); % shift bits


function gyro = convertGyroUint32(gyro)
gyro = int16(gyro * 65.5);
gyro = [gyro zeros(numel(gyro), 1, 'int16')];
gyro = gyro';
gyro = gyro(:);
gyro = typecast(gyro, 'uint32');
gyro = bitshift(gyro, 12); % shift bits
