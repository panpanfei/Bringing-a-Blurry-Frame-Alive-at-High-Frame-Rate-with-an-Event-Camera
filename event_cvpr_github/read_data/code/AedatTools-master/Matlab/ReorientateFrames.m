function aedat = ReorientateFrames(aedat, transpose, flipX, flipY)

%{
For the frame data, if present, apply transpose, flipX and flipY operations
in that order according to the boolean inputs.
%}

dbstop if error
if transpose
    for frameIndex = 1 : aedat.data.frame.numEvents
        aedat.data.frame.samples{frameIndex} = aedat.data.frame.samples{frameIndex}';
    end
    temp                        = aedat.data.frame.xLength;
    aedat.data.frame.xLength    = aedat.data.frame.yLength;
    aedat.data.frame.yLength    = temp;
    temp                        = aedat.data.frame.xPosition;
    aedat.data.frame.xPosition  = aedat.data.frame.yPosition;
    aedat.data.frame.yPosition  = temp;
end

if flipX
    for frameIndex = 1 : aedat.data.frame.numEvents
        aedat.data.frame.samples{frameIndex} ...
            = aedat.data.frame.samples{frameIndex}(:, end: -1 : 1);
    end
    aedat.data.frame.xPosition  = aedat.info.deviceAddressSpace(1) ...
                                    - aedat.data.frame.xPosition;
end

if flipY
    for frameIndex = 1 : aedat.data.frame.numEvents
        aedat.data.frame.samples{frameIndex} ...
            = aedat.data.frame.samples{frameIndex}(end : -1 : 1, :);
    end
    aedat.data.frame.yPosition  = aedat.info.deviceAddressSpace(2) ...
                                    - aedat.data.frame.yPosition;
end
