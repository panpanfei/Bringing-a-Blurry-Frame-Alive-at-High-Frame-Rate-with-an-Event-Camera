function aedat = NumEventsByType(aedat)

%{
For each data type in aedat.data, fill in the numEvents field.
If there are no events, remove the data type field. 
%}

dbstop if error


if isfield(aedat.data, 'special')
	aedat.data.special.numEvents = length(aedat.data.special.timeStamp);
    if aedat.data.special.numEvents == 0
        aedat.data = rmfield(aedat.data, 'special');
    end
end
if isfield(aedat.data, 'polarity')
	aedat.data.polarity.numEvents = length(aedat.data.polarity.timeStamp);
    if aedat.data.polarity.numEvents == 0
        aedat.data = rmfield(aedat.data, 'polarity');
    end
end
if isfield(aedat.data, 'frame')
	aedat.data.frame.numEvents = length(aedat.data.frame.samples); % Don't use timeStamp fields because of the possible ambiguity
    if aedat.data.frame.numEvents == 0
        aedat.data = rmfield(aedat.data, 'frame');
    end
end
if isfield(aedat.data, 'imu6')
	aedat.data.imu6.numEvents = length(aedat.data.imu6.timeStamp);
    if aedat.data.imu6.numEvents == 0
        aedat.data = rmfield(aedat.data, 'imu6');
    end
end
if isfield(aedat.data, 'sample')
	aedat.data.sample.numEvents = length(aedat.data.sample.timeStamp);
    if aedat.data.sample.numEvents == 0
        aedat.data = rmfield(aedat.data, 'sample');
    end
end
if isfield(aedat.data, 'ear')
	aedat.data.ear.numEvents = length(aedat.data.ear.timeStamp);
    if aedat.data.ear.numEvents == 0
        aedat.data = rmfield(aedat.data, 'ear');
    end
end
if isfield(aedat.data, 'point1D')
	aedat.data.point1D.numEvents = length(aedat.data.point1D.timeStamp);
    if aedat.data.point1D.numEvents == 0
        aedat.data = rmfield(aedat.data, 'point1D');
    end
end
if isfield(aedat.data, 'point2D')
	aedat.data.point2D.numEvents = length(aedat.data.point2D.timeStamp);
    if aedat.data.point2D.numEvents == 0
        aedat.data = rmfield(aedat.data, 'point2D');
    end
end
if isfield(aedat.data, 'point3D')
	aedat.data.point3D.numEvents = length(aedat.data.point3D.timeStamp);
    if aedat.data.point3D.numEvents == 0
        aedat.data = rmfield(aedat.data, 'point3D');
    end
end
if isfield(aedat.data, 'point4D')
	aedat.data.point4D.numEvents = length(aedat.data.point4D.timeStamp);
    if aedat.data.point4D.numEvents == 0
        aedat.data = rmfield(aedat.data, 'point4D');
    end
end
