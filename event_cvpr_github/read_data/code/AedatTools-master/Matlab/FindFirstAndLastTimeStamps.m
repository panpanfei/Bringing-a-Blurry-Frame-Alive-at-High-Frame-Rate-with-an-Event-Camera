function aedat = FindFirstAndLastTimeStamps(aedat)
%{
This is a sub-function of importAedat. 
For each field in aedat.data, it finds the first and last timestamp. 
The min and max of these respectively are put into aedat.info
%}

dbstop if error

% Clip arrays to correct size and add them to the output structure.
% Also find first and last timeStamps

if ~isfield(aedat, 'data')
    disp('No data found from which to extract time stamps')
    return
end

firstTimeStamp = inf;
lastTimeStamp = 0;

if isfield(aedat.data, 'special')
	if aedat.data.special.timeStamp(1) < firstTimeStamp
		firstTimeStamp = aedat.data.special.timeStamp(1);
	end
	if aedat.data.special.timeStamp(end) > lastTimeStamp
		lastTimeStamp = aedat.data.special.timeStamp(end);
	end	
end

if isfield(aedat.data, 'polarity')
	if aedat.data.polarity.timeStamp(1) < firstTimeStamp
		firstTimeStamp = aedat.data.polarity.timeStamp(1);
	end
	if aedat.data.polarity.timeStamp(end) > lastTimeStamp
		lastTimeStamp = aedat.data.polarity.timeStamp(end);
	end	
end

if isfield(aedat.data, 'frame')
    if isfield(aedat.data.frame, 'timeStampExposureStart')
        if aedat.data.frame.timeStampExposureStart(1) < firstTimeStamp
            firstTimeStamp = aedat.data.frame.timeStampExposureStart(1);
        end
        if aedat.data.frame.timeStampExposureEnd(end) > lastTimeStamp
            lastTimeStamp = aedat.data.frame.timeStampExposureEnd(end);
        end	
    else
        if aedat.data.frame.timeStampStart(1) < firstTimeStamp
            firstTimeStamp = aedat.data.frame.timeStampStart(1);
        end
        if aedat.data.frame.timeStampEnd(end) > lastTimeStamp
            lastTimeStamp = aedat.data.frame.timeStampEnd(end);
        end	
    end
end

if isfield(aedat.data, 'imu6')
	if aedat.data.imu6.timeStamp(1) < firstTimeStamp
		firstTimeStamp = aedat.data.imu6.timeStamp(1);
	end
	if aedat.data.imu6.timeStamp(end) > lastTimeStamp
		lastTimeStamp = aedat.data.imu6.timeStamp(end);
	end	
end

if isfield(aedat.data, 'sample')
	if aedat.data.sample.timeStamp(1) < firstTimeStamp
		firstTimeStamp = aedat.data.sample.timeStamp(1);
	end
	if aedat.data.sample.timeStamp(end) > lastTimeStamp
		lastTimeStamp = aedat.data.sample.timeStamp(end);
	end	
end

if isfield(aedat.data, 'ear')
	if aedat.data.ear.timeStamp(1) < firstTimeStamp
		firstTimeStamp = aedat.data.ear.timeStamp(1);
	end
	if aedat.data.ear.timeStamp(end) > lastTimeStamp
		lastTimeStamp = aedat.data.ear.timeStamp(end);
	end	
end

if isfield(aedat.data, 'point1D')
	if aedat.data.point1D.timeStamp(1) < firstTimeStamp
		firstTimeStamp = aedat.data.point1D.timeStamp(1);
	end
	if aedat.data.point1D.timeStamp(end) > lastTimeStamp
		lastTimeStamp = aedat.data.point1D.timeStamp(end);
	end	
end

if isfield(aedat.data, 'point2D')
	if aedat.data.point2D.timeStamp(1) < firstTimeStamp
		firstTimeStamp = aedat.data.point2D.timeStamp(1);
	end
	if aedat.data.point2D.timeStamp(end) > lastTimeStamp
		lastTimeStamp = aedat.data.point2D.timeStamp(end);
	end	
end
if isfield(aedat.data, 'point3D')
	if aedat.data.point3D.timeStamp(1) < firstTimeStamp
		firstTimeStamp = aedat.data.point3D.timeStamp(1);
	end
	if aedat.data.point3D.timeStamp(end) > lastTimeStamp
		lastTimeStamp = aedat.data.point3D.timeStamp(end);
	end	
end
if isfield(aedat.data, 'point4D')
	if aedat.data.point4D.timeStamp(1) < firstTimeStamp
		firstTimeStamp = aedat.data.point4D.timeStamp(1);
	end
	if aedat.data.point4D.timeStamp(end) > lastTimeStamp
		lastTimeStamp = aedat.data.point4D.timeStamp(end);
	end	
end

aedat.info.firstTimeStamp = firstTimeStamp;
aedat.info.lastTimeStamp = lastTimeStamp;

