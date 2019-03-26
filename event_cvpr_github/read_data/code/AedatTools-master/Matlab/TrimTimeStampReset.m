function aedat = TrimTimeStampReset(aedat)

%{
If timestamp reset events occur, timestamps become non-monotonic.
Resolve this by searching for non-monotonicites in the timestamps for each
data type and trimming away everything before the last non-monotonicity. 
A better technique would look at the packetTimestamps, at least in aedat3
imports. 
%}

dbstop if error

% Special

if ~isfield(aedat, 'data')
    disp('No data found')
    return
end
if isfield(aedat.data, 'special')
    ts = int64(aedat.data.special.timeStamp);
    lastTsReset = find(ts(2 : end) - ts(1 : end - 1) < 0, 1, 'last');
    if ~isempty(lastTsReset)
        keepLogical = true(aedat.data.special.numEvents, 1);
        keepLogical(1 : lastTsReset) = false; 
        aedat.data.special.timeStamp = aedat.data.special.timeStamp (keepLogical);
        aedat.data.special.address       = aedat.data.special.address  (keepLogical);
        aedat.data.special.numEvents = nnz(keepLogical);
        if isfield(aedat.data.special, 'valid')
            aedat.data.special.valid    = aedat.data.special.valid (keepLogical);
        end
    end
end
% Polarity

if isfield(aedat.data, 'polarity')
    ts = int64(aedat.data.polarity.timeStamp);
    lastTsReset = find(ts(2 : end) - ts(1 : end - 1) < 0, 1, 'last');
    if ~isempty(lastTsReset)
        keepLogical = true(aedat.data.polarity.numEvents, 1);
        keepLogical(1 : lastTsReset) = false; 
        aedat.data.polarity.timeStamp   = aedat.data.polarity.timeStamp (keepLogical);
        aedat.data.polarity.x           = aedat.data.polarity.x         (keepLogical);
        aedat.data.polarity.y           = aedat.data.polarity.y         (keepLogical);
        aedat.data.polarity.polarity    = aedat.data.polarity.polarity  (keepLogical);
        aedat.data.polarity.numEvents   = nnz(keepLogical);
        if isfield(aedat.data.polarity, 'valid')
            aedat.data.polarity.valid    = aedat.data.polarity.valid (keepLogical);
        end
    end
end

% Frames

% This assumes that timestamps have been simplified to aedat2 standard, if
% they came from aedat3 file
if isfield(aedat.data, 'frame')
    ts = int64(aedat.data.frame.timeStampStart);
    lastTsReset = find(ts(2 : end) - ts(1 : end - 1) < 0, 1, 'last');
    if ~isempty(lastTsReset)
        keepLogical = true(aedat.data.frame.numEvents, 1);
        keepLogical(1 : lastTsReset) = false; 
        aedat.data.frame.timeStampStart = aedat.data.frame.timeStampStart (keepLogical);
        aedat.data.frame.timeStampEnd = aedat.data.frame.timeStampEnd (keepLogical);
        aedat.data.frame.samples           = aedat.data.frame.samples         (keepLogical);
        aedat.data.frame.xLength           = aedat.data.frame.xLength         (keepLogical);
        aedat.data.frame.yLength           = aedat.data.frame.yLength         (keepLogical);
        aedat.data.frame.xPosition         = aedat.data.frame.xPosition       (keepLogical);
        aedat.data.frame.yPosition         = aedat.data.frame.yPosition       (keepLogical);
        aedat.data.frame.numEvents         = nnz(keepLogical);
        if isfield(aedat.data.frame, 'valid')
            aedat.data.frame.valid    = aedat.data.frame.valid (keepLogical);
        end
    end
end
% Imu6

if isfield(aedat.data, 'imu6')
    ts = int64(aedat.data.imu6.timeStamp);
    lastTsReset = find(ts(2 : end) - ts(1 : end - 1) < 0, 1, 'last');
    if ~isempty(lastTsReset)
        keepLogical = true(aedat.data.imu6.numEvents, 1);
        keepLogical(1 : lastTsReset) = false; 
        aedat.data.imu6.timeStamp = aedat.data.imu6.timeStamp (keepLogical);
        aedat.data.imu6.accelX       = aedat.data.imu6.accelX (keepLogical);
        aedat.data.imu6.accelY       = aedat.data.imu6.accelY (keepLogical);
        aedat.data.imu6.accelZ       = aedat.data.imu6.accelZ (keepLogical);
        aedat.data.imu6.gyroX        = aedat.data.imu6.gyroX (keepLogical);
        aedat.data.imu6.gyroY        = aedat.data.imu6.gyroY (keepLogical);
        aedat.data.imu6.gyroZ        = aedat.data.imu6.gyroZ (keepLogical);
        aedat.data.imu6.temperature  = aedat.data.imu6.temperature (keepLogical);
        aedat.data.imu6.numEvents    = nnz(keepLogical);
        if isfield(aedat.data.imu6, 'valid')
            aedat.data.imu6.valid    = aedat.data.imu6.valid (keepLogical);
        end
    end
end


% To do: handle other event types

% To do - correct first and last timestamp in info, also numPackets, ...
% startTime, endTime, startPacket, endPacket, startEvent, endEvent
