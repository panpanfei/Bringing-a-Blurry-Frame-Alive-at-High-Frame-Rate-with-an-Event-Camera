function aedat = ZeroTime(aedat)

%{
shifts all timestamps so that the first timestamp is zero
This affects both data.<dataType>.timeStamp and info.packetTimeStamps;
info.first/lastTimeStamp are also updated
%}

dbstop if error

aedat = FindFirstAndLastTimeStamps(aedat);

if isfield(aedat.info, 'firstTimeStamp')
    lowestTimeStamp = aedat.info.firstTimeStamp;
else % Allow the comparison with the packettimestamp timestamps to take place. 
    if ~isfield(aedat.info, 'fileFormat') || aedat.info.fileFormat == 2
        lowestTimeStamp = uint32(inf);    
    else
        lowestTimeStamp = uint64(inf);
    end
end

if isfield(aedat.info, 'packetTimeStamps') ...
        && min(aedat.info.packetTimeStamps) < lowestTimeStamp
    lowestTimeStamp = min(aedat.info.packetTimeStamps);
end

% Now we have the lowest timestamp, whether it came from data or from packet timestamps

if isfield(aedat.info, 'packetTimeStamps') ...
    aedat.info.packetTimeStamps = aedat.info.packetTimeStamps - lowestTimeStamp;
end
 
if isfield(aedat, 'data')
    aedat = OffsetTime(aedat, -double(lowestTimeStamp) / 1e6);
end