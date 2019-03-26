function aedat = Reorientate(aedat, transpose, flipX, flipY)

%{
For polarity and frame data, if present, apply transpose, flipX and flipY 
operations in that order according to the boolean inputs.
%}

dbstop if error

% ReorientatePolarity function depends on this step being carried out
% first
if transpose
    aedat.info.deviceAddressSpace = aedat.info.deviceAddressSpace([2 1]);
end

aedat = ReorientatePolarity(aedat, transpose, flipX, flipY);

aedat = ReorientateFrames(aedat, transpose, flipX, flipY);
