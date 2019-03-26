function [startPacket, endPacket] = FindPacketsByTimeAfterTimeStampReset(aedat, startTime, endTime)

%{
If timestamp reset events occur, timestamps become non-monotonic.
For an aedat3 import where the packet indices have already been created, 
Search for the packet range which corresponds to a chosen time range,
excluding any packets before the last timestamp reset.

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
aedat = FindFirstPacketAfterLastTimeStampReset(aedat);
firstPacket = aedat.info.firstPacketAfterLastTimeStampReset;
startPacket = find(aedat.info.packetTimeStamps(firstPacket : end) >= startTime * 1e6, 1, 'first');
if isempty(startPacket)
    disp('No packets found in time range (after any timestamp resets)')
    startPacket = 0;
    endPacket = 0;
    return
end
startPacket = startPacket + firstPacket - 1;
endPacket = find(aedat.info.packetTimeStamps <= endTime * 1e6, 1, 'last');
