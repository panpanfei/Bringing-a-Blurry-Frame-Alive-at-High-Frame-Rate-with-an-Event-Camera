%{
Assume ImportAedat has been run and that the resulting structure is
called 'aedat'
%}

dbstop if error

%{
PlotAedat tries to plot each type of data which has been imported
Call syntax is:
PlotAedat(input, numPlots, distributeBy)
'distributeBy' can either be 'time' or 'events'
%}
PlotAedat(aedat, 10, 'time') % For polarity and frame data, give 10 sub-plots, 
                             % distributed equally by time

%{ 
Alternatively, you can call just the function to plot a  specific data
type; syntaxes follow:

PlotSpecial(aedat)
PlotPolarity(aedat, numPlots, distributeBy, minTime, maxTime, proportionOfPixels, contrast, transpose, flipVertical, flipHorizontal)
PlotFrame(aedat, numPlots, distributeBy, minTime, maxTime, transpose, flipVertical, flipHorizontal)
PlotImu6(aedat, numBins, startTime, endTime)
PlotPoint1D(aedat)
PlotPoint2D(aedat)
%}

%{
This function gives data density by time for each data type:
PlotDataDensity(aedat, numBins, runningAverage, startTime, endTime)
Example:
%}
PlotDataDensity(aedat, 1000, 10, 0, 100)

%{ 
For aedat3 file imports, plot the packet timestamps - this is an
alternative way to look at data rate
%}
PlotPacketTimeStamps(aedat)

%{
The peristimulus event plot shows polarity events clustered around nearby
special events of a chose type:
PeristimulusEventPlot(aedat, specialEventType, timeBeforeUs, timeAfterUs, stepStimuli, maxStimuli, minX, maxX, minY, maxY)
Example - look at polarity events for 1 ms either side of the start of a frame exposure:
%}
PeristimulusEventPlot(aedat, 16, 1000, 1000) % 16 is the special event type for start of frame exposure (not present in aedat2 recordings)


