function aedat = FindFirstPacketAfterLastTimeStampReset(aedat)

%{
If timestamp reset events occur, timestamps become non-monotonic.
For an aedat3 import where the packet indices have already been created, 
add in info.firstPacketAfterLastTimestampreset, allowing later
exclusion of any packets before the last timestamp reset.

%}

dbstop if error

if ~isfield(aedat, 'info')
    disp('No data found.')
    return
end
if ~isfield(aedat.info, 'packetTimeStamps')
    disp('No packet indices found.')
    return
end
ts = int64(aedat.info.packetTimeStamps);
lastTsReset = find(ts(2 : end) - ts(1 : end - 1) < 0, 1, 'last');
if ~isempty(lastTsReset)
    disp('Timestamp reset found')
    aedat.info.firstPacketAfterLastTimeStampReset = lastTsReset + 1;
else
    disp('Timestamp reset not found')
    aedat.info.firstPacketAfterLastTimeStampReset = 1;
end
