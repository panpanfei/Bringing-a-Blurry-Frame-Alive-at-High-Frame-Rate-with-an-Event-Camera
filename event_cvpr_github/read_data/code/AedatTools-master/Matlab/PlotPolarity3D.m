function PlotPolarity3D(aedat, minTime, maxTime)

%{
Takes 'aedat' - a data structure containing an imported .aedat file, 
as created by ImportAedat, and creates a 3D scatter plot of the events 
in space time. The colour of the points gives their polarity.
%}


if ~exist('minTime', 'var') || (exist('minTime', 'var') && minTime == 0)
    minTime = double(min(aedat.data.polarity.timeStamp)) / 1e6;
end
if ~exist('maxTime', 'var') || (exist('maxTime', 'var') && maxTime == 0)
    maxTime = double(max(aedat.data.polarity.timeStamp)) / 1e6;
end

aedatTemp = TrimTime(aedat, minTime, maxTime);


scatter3(   aedatTemp.data.polarity.x, ...
            aedatTemp.data.polarity.y, ...
            aedatTemp.data.polarity.timeStamp, ...
            1, ...
            aedatTemp.data.polarity.polarity)
colormap([  1 0 0; ...
            0 1 0])

