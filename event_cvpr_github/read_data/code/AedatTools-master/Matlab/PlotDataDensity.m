function PlotDataDensity(aedat, numBins, runningAverage, startTime, endTime)

%{
Takes 'aedat' - a data structure containing an imported .aedat file, 
as created by ImportAedat. For each data type present, 
it gives a graph of data density. All the graphs are superimposed. The
number of time bins used to create the graph is an argument of the function. 
runningAverage - the number of bins over which to smooth.

THERE WOULD BE A BETTER TREATMENT IF YOU"RE INTERESTED IN IDENTIFYING DATA GAPS 
- plotting instantaneous data rate by event - 
this would be consistent with the semilogy plot as there would be
no zero data points and the size of the downward spikes would tell you how
long the data gaps were for. 

%}

if ~exist('numBins', 'var')
	numBins = 1000;
end

if exist('startTime', 'var')
    startTime = startTime * 1e6;
else
    startTime = aedat.info.firstTimeStamp;
end

if exist('endTime', 'var')
    endTime = endTime * 1e6;
else
    endTime = aedat.info.lastTimeStamp;
end

durationUs = double(endTime - startTime);
durationOfBinUs = durationUs / numBins;
durationOfBinS = durationOfBinUs / 1000000;

timeBinBoundariesUs = double(startTime) : durationOfBinUs : double(endTime);
timeBinCentresS = (timeBinBoundariesUs(1 : end - 1) + durationOfBinUs / 2) / 1000000;

figure
legendLocal = {};

if isfield(aedat.data, 'special')
    timeStampsInTimeRange = aedat.data.special.timeStamp(...
        aedat.data.special.timeStamp >= startTime ...
        & aedat.data.special.timeStamp <= endTime);
    density = hist(double(timeStampsInTimeRange), numBins);
	if exist('runningAverage', 'var') && runningAverage > 1
		kernel = (1 / runningAverage) * ones(1, runningAverage);
		density = filter(kernel, 1, density);
	end
	semilogy(timeBinCentresS, density, '.-')
    hold all
    legendLocal = [legendLocal 'special'];
end

if isfield(aedat.data, 'polarity')
    timeStampsInTimeRange = aedat.data.polarity.timeStamp(...
        aedat.data.polarity.timeStamp >= startTime ...
        & aedat.data.polarity.timeStamp <= endTime);
    density = hist(double(timeStampsInTimeRange), numBins);
	if exist('runningAverage', 'var') && runningAverage > 1
		kernel = (1 / runningAverage) * ones(1, runningAverage);
		density = filter(kernel, 1, density);
	end
	semilogy(timeBinCentresS, density, '.-')
    hold all
	legendLocal = [legendLocal 'polarity'];
end

% Assumes that aedat3 timestamps, if present, have been simplified
if isfield(aedat.data, 'frame')
    timeStampsInTimeRange = aedat.data.frame.timeStampStart(...
        aedat.data.frame.timeStampStart >= startTime ...
        & aedat.data.frame.timeStampStart <= endTime);
    density = hist(double(timeStampsInTimeRange), numBins);
	if exist('runningAverage', 'var') && runningAverage > 1
		kernel = (1 / runningAverage) * ones(1, runningAverage);
		density = filter(kernel, 1, density);
	end
	semilogy(timeBinCentresS, density, '.-')
    hold all
	legendLocal = [legendLocal 'frame'];
end

if isfield(aedat.data, 'imu6')
    timeStampsInTimeRange = aedat.data.imu6.timeStamp(...
        aedat.data.imu6.timeStamp >= startTime ...
        & aedat.data.imu6.timeStamp <= endTime);
    density = hist(double(timeStampsInTimeRange), numBins);
	if exist('runningAverage', 'var') && runningAverage > 1
		kernel = (1 / runningAverage) * ones(1, runningAverage);
		density = filter(kernel, 1, density);
	end
	semilogy(timeBinCentresS, density, '.-')
    hold all
	legendLocal = [legendLocal 'imu6'];
end

if isfield(aedat.data, 'sample')
    timeStampsInTimeRange = aedat.data.sample.timeStamp(...
        aedat.data.sample.timeStamp >= startTime ...
        & aedat.data.sample.timeStamp <= endTime);
    density = hist(double(timeStampsInTimeRange), numBins);
	if exist('runningAverage', 'var') && runningAverage > 1
		kernel = (1 / runningAverage) * ones(1, runningAverage);
		density = filter(kernel, 1, density);
	end
	semilogy(timeBinCentresS, density, '.-')
    hold all
	legendLocal = [legendLocal 'sample'];
end

if isfield(aedat.data, 'ear')
    timeStampsInTimeRange = aedat.data.ear.timeStamp(...
        aedat.data.ear.timeStamp >= startTime ...
        & aedat.data.ear.timeStamp <= endTime);
    density = hist(double(timeStampsInTimeRange), numBins);
	if exist('runningAverage', 'var') && runningAverage > 1
		kernel = (1 / runningAverage) * ones(1, runningAverage);
		density = filter(kernel, 1, density);
	end
	semilogy(timeBinCentresS, density, '.-')
    hold all
	legendLocal = [legendLocal 'ear'];
end

if isfield(aedat.data, 'point1D')
    timeStampsInTimeRange = aedat.data.point1D.timeStamp(...
        aedat.data.point1D.timeStamp >= startTime ...
        & aedat.data.point1D.timeStamp <= endTime);
    density = hist(double(timeStampsInTimeRange), numBins);
	if exist('runningAverage', 'var') && runningAverage > 1
		kernel = (1 / runningAverage) * ones(1, runningAverage);
		density = filter(kernel, 1, density);
	end
	semilogy(timeBinCentresS, density, '.-')
    hold all
	legendLocal = [legendLocal 'point1D'];
end

if isfield(aedat.data, 'point2D')
    timeStampsInTimeRange = aedat.data.point2D.timeStamp(...
        aedat.data.point2D.timeStamp >= startTime ...
        & aedat.data.point2D.timeStamp <= endTime);
    density = hist(double(timeStampsInTimeRange), numBins);
	if exist('runningAverage', 'var') && runningAverage > 1
		kernel = (1 / runningAverage) * ones(1, runningAverage);
		density = filter(kernel, 1, density);
	end
	semilogy(timeBinCentresS, density, '.-')
    hold all
	legendLocal = [legendLocal 'point2D'];
end

xlabel('Time (s)')
ylabel('Data density (events per second)')
legend(legendLocal)

