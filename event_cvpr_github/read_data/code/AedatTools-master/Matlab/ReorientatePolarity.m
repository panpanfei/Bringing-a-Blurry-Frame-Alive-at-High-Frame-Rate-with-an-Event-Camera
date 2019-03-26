function aedat = ReorientatePolarity(aedat, transpose, flipX, flipY)

%{
For the frame data, if present, apply transpose, flipX and flipY operations
in that order according to the boolean inputs.
%}

dbstop if error

if ~isfield(aedat, 'data')
    disp('No data found')
    return
end
if ~isfield(aedat.data, 'polarity')
    disp('No polarity data to reorientate')
    return
end
if transpose
    temp                    = aedat.data.polarity.x;
    aedat.data.polarity.x   = aedat.data.polarity.y;
    aedat.data.polarity.y   = temp;
end

if flipX
    aedat.data.polarity.x   = aedat.info.deviceAddressSpace(1) - aedat.data.polarity.x - 1;
end

if flipY
    aedat.data.polarity.y   = aedat.info.deviceAddressSpace(2) - aedat.data.polarity.y - 1;
end
