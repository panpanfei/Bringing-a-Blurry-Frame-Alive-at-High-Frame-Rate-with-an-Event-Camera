function PlotAedat(aedat, numPlots, distributeBy)

% This function calls the 'Plot...' function for each of the supported event
% types

if ~exist('numPlots', 'var')
	numPlots = 3;
end

if ~exist('distributeBy', 'var')
	distributeBy = 'time';
end

if isfield(aedat.data, 'special')
	PlotSpecial(aedat); % This function displays all special events
end
if isfield(aedat.data, 'polarity')
	PlotPolarity(aedat, numPlots, distributeBy);
end
if isfield(aedat.data, 'frame')
	PlotFrame(aedat, numPlots, distributeBy);
end
if isfield(aedat.data, 'imu6')
	PlotImu6(aedat);
end
%{
if isfield(aedat.data, 'sample')
	PlotSample(aedat, numPlots, distributeBy);
end
if isfield(aedat.data, 'ear')
	PlotEar(aedat, numPlots, distributeBy);
end
%}
if isfield(aedat.data, 'point1D')
	PlotPoint1D(aedat);
end
if isfield(aedat.data, 'point2D')
	PlotPoint2D(aedat);
end
if isfield(aedat.data, 'point3D')
	PlotPoint3D(aedat);
end

PlotPacketTimeStamps(aedat, false)
