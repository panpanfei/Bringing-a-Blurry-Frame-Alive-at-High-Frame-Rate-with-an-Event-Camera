function aedat = OffsetTime(aedat, offset)

%{
Offset all data timestamps by the(positive going) offset parameter.
No trimming at zero - this can result in negative timestamps. 
Recalculate first and last timestamps
%}

dbstop if error


if ~isfield(aedat, 'data')
    disp('No data found')
    return
end

% Are we working with 32 or 64 bit timestamps? It depends on the fileFormat
% from which we imported; default is 32 bit
if ~isfield(aedat.info, 'fileFormat') || aedat.info.fileFormat == 2
    % Assume offset param is given in secs (AedatTools standard)
    offset = int32(offset * 1e6);
    % Special
    if isfield(aedat.data, 'special')
        aedat.data.special.timeStamp = uint32(int32(aedat.data.special.timeStamp) + offset);
    end
    % Polarity
    if isfield(aedat.data, 'polarity')
        aedat.data.polarity.timeStamp = uint32(int32(aedat.data.polarity.timeStamp) + offset);
    end

    % Frames
    % This assumes that timestamps have been simplified to aedat2 standard, if
    % they came from aedat3 file
    if isfield(aedat.data, 'frame')
        aedat.data.frame.timeStampStart = uint32(int32(aedat.data.frame.timeStampStart)   + offset);
        aedat.data.frame.timeStampEnd   = uint32(int32(aedat.data.frame.timeStampEnd)     + offset);
    end
    % Imu6
    if isfield(aedat.data, 'imu6')
        aedat.data.imu6.timeStamp = uint32(int32(aedat.data.imu6.timeStamp) + offset);
    end

    % Sample
    if isfield(aedat.data, 'sample')
        aedat.data.sample.timeStamp = uint32(int32(aedat.data.sample.timeStamp) + offset);
    end

    % Ear
    if isfield(aedat.data, 'ear')
        aedat.data.ear.timeStamp = uint32(int32(aedat.data.ear.timeStamp) + offset);
    end

    % Point1D
    if isfield(aedat.data, 'point1D')
        aedat.data.point1D.timeStamp = uint32(int32(aedat.data.point1D.timeStamp) + offset);
    end

    %Point2D
    if isfield(aedat.data, 'point2D')
        aedat.data.point2D.timeStamp = uint32(int32(aedat.data.point2D.timeStamp) + offset);
    end

    %Point3D
    if isfield(aedat.data, 'point3D')
        aedat.data.point3D.timeStamp = uint32(int32(aedat.data.point3D.timeStamp) + offset);
    end

    %Point4D
    if isfield(aedat.data, 'point4D')
        aedat.data.point4D.timeStamp = uint32(int32(aedat.data.point4D.timeStamp) + offset);
    end
else

    % Assume offset param is given in secs (AedatTools standard)
    offset = int64(offset * 1e6);
    % Special
    if isfield(aedat.data, 'special')
        aedat.data.special.timeStamp = uint64(int64(aedat.data.special.timeStamp) + offset);
    end
    % Polarity
    if isfield(aedat.data, 'polarity')
        aedat.data.polarity.timeStamp = uint64(int64(aedat.data.polarity.timeStamp) + offset);
    end

    % Frames
    % This assumes that timestamps have been simplified to aedat2 standard, if
    % they came from aedat3 file
    if isfield(aedat.data, 'frame')
        aedat.data.frame.timeStampStart = uint64(int64(aedat.data.frame.timeStampStart)   + offset);
        aedat.data.frame.timeStampEnd   = uint64(int64(aedat.data.frame.timeStampEnd)     + offset);
    end
    % Imu6
    if isfield(aedat.data, 'imu6')
        aedat.data.imu6.timeStamp = uint64(int64(aedat.data.imu6.timeStamp) + offset);
    end

    % Sample
    if isfield(aedat.data, 'sample')
        aedat.data.sample.timeStamp = uint64(int64(aedat.data.sample.timeStamp) + offset);
    end

    % Ear
    if isfield(aedat.data, 'ear')
        aedat.data.ear.timeStamp = uint64(int64(aedat.data.ear.timeStamp) + offset);
    end

    % Point1D
    if isfield(aedat.data, 'point1D')
        aedat.data.point1D.timeStamp = uint64(int64(aedat.data.point1D.timeStamp) + offset);
    end

    %Point2D
    if isfield(aedat.data, 'point2D')
        aedat.data.point2D.timeStamp = uint64(int64(aedat.data.point2D.timeStamp) + offset);
    end

    %Point3D
    if isfield(aedat.data, 'point3D')
        aedat.data.point3D.timeStamp = uint64(int64(aedat.data.point3D.timeStamp) + offset);
    end

    %Point4D
    if isfield(aedat.data, 'point4D')
        aedat.data.point4D.timeStamp = uint64(int64(aedat.data.point4D.timeStamp) + offset);
    end
end

aedat = FindFirstAndLastTimeStamps(aedat);
