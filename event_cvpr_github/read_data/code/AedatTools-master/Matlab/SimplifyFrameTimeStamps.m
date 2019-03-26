function aedat = SimplifyFrameTimeStamps(aedat, keepReadoutTime)

%{
aedat2 just encodes the start and end of a frame - this doesn't relate to
exposure but rather when the frame was read out.
aedat 3 encodes exposure start and end, and also frame start and end -
frame start and end being when the frames were read out.
There is therefore no common timestamp field for frames in the two formats.
This function removes the four timestamp fields resulting from aedat3
import and replaces them with two fields matching the aedat2 format.
Importantly it defaults to using the exposure start and end for these two fields, 
so the delay from exposure to read out is considered irrelevant. setting
the keepReadoutTime flag instead disregards the actual exposure times (this
info should be recoverable from the special events, however). 
%}

dbstop if error

if isfield(aedat, 'data') ...
        && isfield(aedat.data, 'frame') ...
        && isfield(aedat.data.frame, 'timeStampExposureStart') 
    if exist('keepReadoutTime' , 'var')&& keepReadoutTime
        aedat.data.frame.timeStampStart =  aedat.data.frame.timeStampFrameStart;
        aedat.data.frame.timeStampEnd   =  aedat.data.frame.timeStampFrameEnd;
    else
        aedat.data.frame.timeStampStart =  aedat.data.frame.timeStampExposureStart;
        aedat.data.frame.timeStampEnd   =  aedat.data.frame.timeStampExposureEnd;        
    end
    aedat.data.frame = rmfield(aedat.data.frame, 'timeStampFrameStart');
    aedat.data.frame = rmfield(aedat.data.frame, 'timeStampFrameEnd');
    aedat.data.frame = rmfield(aedat.data.frame, 'timeStampExposureStart');
    aedat.data.frame = rmfield(aedat.data.frame, 'timeStampExposureEnd');
end
