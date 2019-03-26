function PlotPacketTimeStamps(aedat, newFigure, diffs)

%{
Takes 'aedat' - a data structure containing an imported .aedat file, 
as created by ImportAedat. 
When imported from aedat3, there is an info field packetTimeStamps. Plot
this.
%}

if ~isfield(aedat, 'info') || ~isfield(aedat.info, 'packetTimeStamps')
    disp('No packet timestamps found')
    return
end

% newFigure - default is to create a new figure in which to plot - supress
% this with the newFigure flag
if ~exist('newFigure', 'var') || newFigure
    figure
end
if exist('diffs', 'var') && diffs
    % In the diffs mode, plots the difference in timestamp from one packet
    % to the next. Exclude packets before last timestanmp reset
    aedat = FindFirstPacketAfterLastTimeStampReset(aedat);
    firstPacket = aedat.info.firstPacketAfterLastTimeStampReset;
    ts = double(aedat.info.packetTimeStamps(firstPacket : end)) / 1e6;
    diffs = [0; ts(2 : end) - ts(1 : end - 1)] * 1e3;
    plot(ts, diffs, '.-')
    xlabel('Packet timestamp (s)')
    ylabel('time difference from previous timestamp (ms)')
else 
    plot(aedat.info.packetTimeStamps, '.-')
    xlabel('Packet number')
    ylabel('Time (us)')
end
