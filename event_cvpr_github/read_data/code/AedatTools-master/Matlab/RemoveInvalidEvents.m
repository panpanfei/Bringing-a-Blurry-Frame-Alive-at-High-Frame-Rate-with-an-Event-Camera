function aedat = RemoveInvalidEvents(aedat)

%{
This function removes any events which are flagged as invalid, and then
removes the 'valid' fields. It's possible that all events get removed. In
this case the data type field itself needs to be removed, but this should
be handled by a subsequent call to NumEventsByType. 
%}

dbstop if error

if ~isfield(aedat, 'data')
    return
end
% Special

if isfield(aedat.data, 'special') && isfield(aedat.data.special, 'valid')
    aedat.data.special.timeStamp    = aedat.data.special.timeStamp  (aedat.data.special.valid);
    aedat.data.special.address      = aedat.data.special.address    (aedat.data.special.valid);
    aedat.data.special = rmfield(aedat.data.special, 'valid');
end

% Polarity

if isfield(aedat.data, 'polarity') && isfield(aedat.data.polarity, 'valid')
    aedat.data.polarity.timeStamp   = aedat.data.polarity.timeStamp (aedat.data.polarity.valid);
    aedat.data.polarity.x           = aedat.data.polarity.x         (aedat.data.polarity.valid);
    aedat.data.polarity.y           = aedat.data.polarity.y         (aedat.data.polarity.valid);
    aedat.data.polarity.polarity    = aedat.data.polarity.polarity  (aedat.data.polarity.valid);
    aedat.data.polarity = rmfield(aedat.data.polarity, 'valid');
end
% Frames

if isfield(aedat.data, 'frame') && isfield(aedat.data.frame, 'valid')
    aedat.data.frame.timeStampStart    = aedat.data.frame.timeStampStart (aedat.data.frame.valid);
    aedat.data.frame.timeStampEnd      = aedat.data.frame.timeStampEnd   (aedat.data.frame.valid);
    aedat.data.frame.samples           = aedat.data.frame.samples        (aedat.data.frame.valid);
    aedat.data.frame.xLength           = aedat.data.frame.xLength        (aedat.data.frame.valid);
    aedat.data.frame.yLength           = aedat.data.frame.yLength        (aedat.data.frame.valid);
    aedat.data.frame.xPosition         = aedat.data.frame.xPosition      (aedat.data.frame.valid);
    aedat.data.frame.yPosition         = aedat.data.frame.yPosition      (aedat.data.frame.valid);
    aedat.data.frame.roiId             = aedat.data.frame.roiId          (aedat.data.frame.valid);
    aedat.data.frame.colorChannels     = aedat.data.frame.colorChannels  (aedat.data.frame.valid);
    aedat.data.frame.colorFilter       = aedat.data.frame.colorFilter    (aedat.data.frame.valid);
    aedat.data.frame = rmfield(aedat.data.frame, 'valid');
end
% Imu6

if isfield(aedat.data, 'imu6') && isfield(aedat.data.imu6, 'valid')
    aedat.data.imu6.timeStamp    = aedat.data.imu6.timeStamp    (aedat.data.imu6.valid);
    aedat.data.imu6.accelX       = aedat.data.imu6.accelX       (aedat.data.imu6.valid);
    aedat.data.imu6.accelY       = aedat.data.imu6.accelY       (aedat.data.imu6.valid);
    aedat.data.imu6.accelZ       = aedat.data.imu6.accelZ       (aedat.data.imu6.valid);
    aedat.data.imu6.gyroX        = aedat.data.imu6.gyroX        (aedat.data.imu6.valid);
    aedat.data.imu6.gyroY        = aedat.data.imu6.gyroY        (aedat.data.imu6.valid);
    aedat.data.imu6.gyroZ        = aedat.data.imu6.gyroZ        (aedat.data.imu6.valid);
    aedat.data.imu6.temperature  = aedat.data.imu6.temperature  (aedat.data.imu6.valid);
    aedat.data.imu6 = rmfield(aedat.data.imu6, 'valid');
end


if isfield(aedat.data, 'sample') && isfield(aedat.data.sample, 'valid')
    aedat.data.sample.timeStamp     = aedat.data.sample.timeStamp   (aedat.data.sample.valid);
    aedat.data.sample.sampleType	= aedat.data.sample.sampleType  (aedat.data.sample.valid);
    aedat.data.sample.sample		= aedat.data.sample.sample      (aedat.data.sample.valid);
    aedat.data.sample = rmfield(aedat.data.sample, 'valid');
end

if isfield(aedat.data, 'ear') && isfield(aedat.data.ear, 'valid')
    aedat.data.ear.timeStamp	= aedat.data.ear.timeStamp  (aedat.data.ear.valid);
    aedat.data.ear.position     = aedat.data.ear.position   (aedat.data.ear.valid);
    aedat.data.ear.channel		= aedat.data.ear.channel	(aedat.data.ear.valid);
    aedat.data.ear.neuron		= aedat.data.ear.neuron		(aedat.data.ear.valid);
    aedat.data.ear.filter		= aedat.data.ear.filter		(aedat.data.ear.valid);
    aedat.data.ear = rmfield(aedat.data.ear, 'valid');
end

if isfield(aedat.data, 'point1D') && isfield(aedat.data.point1D, 'valid')
    aedat.data.point1D.type         = aedat.data.point1D.type         (aedat.data.point1D.valid);
    aedat.data.point1D.timeStamp    = aedat.data.point1D.timeStamp    (aedat.data.point1D.valid);
    aedat.data.point1D.x            = aedat.data.point1D.x            (aedat.data.point1D.valid);
    aedat.data.point1D = rmfield(aedat.data.point1D, 'valid');
end

if isfield(aedat.data, 'point2D') && isfield(aedat.data.point2D, 'valid')
    aedat.data.point2D.type         = aedat.data.point2D.type       (aedat.data.point2D.valid);
    aedat.data.point2D.timeStamp    = aedat.data.point2D.timeStamp  (aedat.data.point2D.valid);
    aedat.data.point2D.x            = aedat.data.point2D.x          (aedat.data.point2D.valid);
    aedat.data.point2D.y            = aedat.data.point2D.y          (aedat.data.point2D.valid);
    aedat.data.point2D = rmfield(aedat.data.point2D, 'valid');
end

if isfield(aedat.data, 'point3D') && isfield(aedat.data.point3D, 'valid')
    aedat.data.point3D.type         = aedat.data.point3D.type       (aedat.data.point3D.valid);
    aedat.data.point3D.timeStamp    = aedat.data.point3D.timeStamp  (aedat.data.point3D.valid);
    aedat.data.point3D.x            = aedat.data.point3D.x          (aedat.data.point3D.valid);
    aedat.data.point3D.y            = aedat.data.point3D.y          (aedat.data.point3D.valid);
    aedat.data.point3D.z            = aedat.data.point3D.z          (aedat.data.point3D.valid);
    aedat.data.point3D = rmfield(aedat.data.point3D, 'valid');
end
