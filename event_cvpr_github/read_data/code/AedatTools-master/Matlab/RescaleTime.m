function aedat = RescaleTime(aedat, factor, packetTimeStamps, dataTimeStamps)

%{
Stretches or squeezes time by multiplying all timestamps by a factor.
This affects both data.<dataType>.timeStamp and info.packetTimeStamps,
by default, overridden by the optional flags. 
%}

dbstop if error

if ~exist('packetTimeStamps', 'var') || packetTimeStamps

    if ~isfield(aedat, 'info') || ~isfield(aedat.info, 'packetTimeStamps')
        disp('No packet timestamps found')
    else
        aedat.info.packetTimeStamps = uint64(double(aedat.info.packetTimeStamps * factor));        
    end
end

if ~exist('dataTimeStamps', 'var') || dataTimeStamps

    if ~isfield(aedat, 'data')
        disp('No data found')
    else

        % Special
        if isfield(aedat.data, 'special')
            aedat.data.special.timeStamp = uint64(double(aedat.data.special.timeStamp * factor));
        end

        % Polarity
        if isfield(aedat.data, 'polarity')
            aedat.data.polarity.timeStamp = uint64(double(aedat.data.polarity.timeStamp * factor));
        end

        % Frames
        % This assumes that timestamps have been simplified to aedat2 standard, if
        % they came from aedat3 file
        if isfield(aedat.data, 'frame')
            aedat.data.frame.timeStampStart = uint64(double(aedat.data.frame.timeStampStart * factor));
            aedat.data.frame.timeStampEnd = uint64(double(aedat.data.frame.timeStampEnd * factor));
        end

        % Imu6
        if isfield(aedat.data, 'imu6')
            aedat.data.imu6.timeStamp = uint64(double(aedat.data.imu6.timeStamp * factor));
        end

        if isfield(aedat.data, 'sample')
            aedat.data.sample.timeStamp = uint64(double(aedat.data.sample.timeStamp * factor));
        end

        if isfield(aedat.data, 'ear')
            aedat.data.ear.timeStamp = uint64(double(aedat.data.ear.timeStamp * factor));
        end

        if isfield(aedat.data, 'point1D')
            aedat.data.point1D.timeStamp = uint64(double(aedat.data.point1D.timeStamp * factor));
        end

        if isfield(aedat.data, 'point2D')
            aedat.data.point2D.timeStamp = uint64(double(aedat.data.point2D.timeStamp * factor));
        end

        if isfield(aedat.data, 'point3D')
            aedat.data.point3D.timeStamp = uint64(double(aedat.data.point3D.timeStamp * factor));
        end

        aedat = FindFirstAndLastTimeStamps(aedat);

        if isfield(aedat.info, 'packetTimeStamps')
            aedat.info.packetTimeStamps = uint64(double(aedat.info.packetTimeStamps * factor));
        end
    end
end