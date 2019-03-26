function PlotImu6(input, numBins, startTime, endTime)

%{
%}

if isfield(input.data, 'imu6')
    data = input.data.imu6;
else
    return
end

if ~exist('numBins', 'var') || (exist('numBins', 'var') && numBins == 0)
	numBins = data.numEvents;
end

if exist('startTime', 'var') && startTime > 0 
    startTime = startTime * 1e6;
else
    startTime = input.info.firstTimeStamp;
end

if exist('endTime', 'var') && endTime > 0 
    endTime = endTime * 1e6;
else
    startTime = input.info.lastTimeStamp;
end

durationUs = double(endTime - startTime);
durationOfBinUs = durationUs / numBins;
durationOfBinS = durationOfBinUs / 1000000;

timeBinBoundariesUs = double(startTime) : durationOfBinUs : double(endTime);
timeBinCentresS = (timeBinBoundariesUs(1 : end - 1) + durationOfBinUs / 2) / 1000000;

if numBins == data.numEvents
    accelX = data.accelX;
    accelY = data.accelY;
    accelZ = data.accelZ;
    gyroX  = data.gyroX;
    gyroY  = data.gyroY;
    gyroZ  = data.gyroZ;
else
    accelX = zeros(numBins, 1);
    accelY = zeros(numBins, 1);
    accelZ = zeros(numBins, 1);
    gyroX  = zeros(numBins, 1);
    gyroY  = zeros(numBins, 1);
    gyroZ  = zeros(numBins, 1);
    
    for bin = 1 : numBins
		firstTimeStampIndex = find(data.timeStamp >= timeBinBoundariesUs(bin), 1, 'first');
		lastTimeStampIndex = max(firstTimeStampIndex, find(data.timeStamp < timeBinBoundariesUs(bin + 1), 1, 'last'));
		if ~isempty(firstTimeStampIndex) && ~isempty(lastTimeStampIndex) 
			accelX(bin) = mean(data.accelX(firstTimeStampIndex : lastTimeStampIndex));
			accelY(bin) = mean(data.accelZ(firstTimeStampIndex : lastTimeStampIndex));
			accelZ(bin) = mean(data.accelY(firstTimeStampIndex : lastTimeStampIndex));
			gyroX(bin) = mean(data.gyroX(firstTimeStampIndex : lastTimeStampIndex));
			gyroY(bin) = mean(data.gyroY(firstTimeStampIndex : lastTimeStampIndex));
			gyroZ(bin) = mean(data.gyroZ(firstTimeStampIndex : lastTimeStampIndex));
		end
    end
end

figure
legendLocal = {};

subplot(2, 1, 1)
hold all
plot(timeBinCentresS, accelX, '-')
legendLocal = [legendLocal 'accelX'];
plot(timeBinCentresS, accelY, '-')
legendLocal = [legendLocal 'accelY'];
plot(timeBinCentresS, accelZ, '-')
legendLocal = [legendLocal 'accelZ'];
xlabel('Time (s)')
ylabel('Acceleration (m/s^2? g?)')
legend(legendLocal)

subplot(2, 1, 2)
hold all
plot(timeBinCentresS, gyroX)
legendLocal = [legendLocal 'gyroX'];
plot(timeBinCentresS, gyroY)
legendLocal = [legendLocal 'gyroY'];
plot(timeBinCentresS, gyroZ)
legendLocal = [legendLocal 'gyroZ'];
xlabel('Time (s)')
ylabel('Angular veloicty (RPS? deg/s?)')
legend(legendLocal)



