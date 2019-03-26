function ExportAedat2Imu6(aedat)

%{
This function exports data to a .aedat file. 
The .aedat file format is documented here:

http://inilabs.com/support/software/fileformat/
%}

dbstop if error

if ~exist('aedat', 'var')
	error('Missing input')
end

% Create the file
if ~isfield(aedat.exportParams, 'filePath')
    error('Missing file path and name')
end

f = fopen(aedat.exportParams.filePath, 'w', 'b');

% Simple - events only - assume DAVIS

% CRLF \r\n is needed to not break header parsing in jAER
fprintf(f,'#!AER-DAT2.0\r\n');
fprintf(f,'# This is a raw AE data file created by an export function in the AedatTools library\r\n');
fprintf(f,'# Data format is int32 address, int32 timestamp (8 bytes total), repeated for each event\r\n');
fprintf(f,'# Timestamps tick is 1 us\r\n');
% Put the source in - use an override if it has been given
if isfield(aedat.exportParams, 'source')
    fprintf(f,['# AEChip: ' aedat.exportParams.source '\r\n']);
else 
    fprintf(f,['# AEChip: ' aedat.info.source '\r\n']);
end
fprintf(f,'# End of ASCII Header\r\n');

% DAVIS

accelX = aedat.data.imu6.accelX; % conversion from g to full scale, and shift bits
accelX = int16(accelX * 8192); % conversion from g to full scale 16 range
accelX = [accelX zeros(aedat.data.imu6.numEvents, 1, 'int16')];
accelX = accelX';
accelX = accelX(:);
accelX = typecast(accelX, 'uint32'); 
accelX = bitshift(accelX, 12); % shift bits
accelX = accelX + 2 ^ 31 + 2 ^ 11; % imu flag bits

accelY = aedat.data.imu6.accelY; % conversion from g to full scale, and shift bits
accelY = int16(accelY * 8192); % conversion from g to full scale 16 range
accelY = [accelY zeros(aedat.data.imu6.numEvents, 1, 'int16')];
accelY = accelY';
accelY = accelY(:);
accelY = typecast(accelY, 'uint32'); 
accelY = bitshift(accelY, 12); % shift bits
accelY = accelY + 2 ^ 31 + 2 ^ 11; % imu flag bits

accelZ = aedat.data.imu6.accelZ; % conversion from g to full scale, and shift bits
accelZ = int16(accelZ * 8192); % conversion from g to full scale 16 range
accelZ = [accelZ zeros(aedat.data.imu6.numEvents, 1, 'int16')];
accelZ = accelZ';
accelZ = accelZ(:);
accelZ = typecast(accelZ, 'uint32'); 
accelZ = bitshift(accelZ, 12); % shift bits
accelZ = accelZ + 2 ^ 31 + 2 ^ 11; % imu flag bits

temp = aedat.data.imu6.temperature; % conversion from g to full scale, and shift bits
temp = int16((temp - 35) * 340); % conversion from K to full scale 16 range
temp = [temp zeros(aedat.data.imu6.numEvents, 1, 'int16')];
temp = temp';
temp = temp(:);
temp = typecast(temp, 'uint32'); 
temp = bitshift(temp, 12); % shift bits
temp = temp + 2 ^ 31 + 2 ^ 11; % imu flag bits

gyroX = aedat.data.imu6.gyroX; % conversion from g to full scale, and shift bits
gyroX = int16(gyroX * 65.5); % conversion from g to full scale 16 range
gyroX = [gyroX zeros(aedat.data.imu6.numEvents, 1, 'int16')];
gyroX = gyroX';
gyroX = gyroX(:);
gyroX = typecast(gyroX, 'uint32'); 
gyroX = bitshift(gyroX, 12); % shift bits
gyroX = gyroX + 2 ^ 31 + 2 ^ 11; % imu flag bits

gyroY = aedat.data.imu6.gyroY; % conversion from g to full scale, and shift bits
gyroY = int16(gyroY * 65.5); % conversion from g to full scale 16 range
gyroY = [gyroY zeros(aedat.data.imu6.numEvents, 1, 'int16')];
gyroY = gyroY';
gyroY = gyroY(:);
gyroY = typecast(gyroY, 'uint32'); 
gyroY = bitshift(gyroY, 12); % shift bits
gyroY = gyroY + 2 ^ 31 + 2 ^ 11; % imu flag bits

gyroZ = aedat.data.imu6.gyroZ; % conversion from g to full scale, and shift bits
gyroZ = int16(gyroZ * 65.5); % conversion from g to full scale 16 range
gyroZ = [gyroZ zeros(aedat.data.imu6.numEvents, 1, 'int16')];
gyroZ = gyroZ';
gyroZ = gyroZ(:);
gyroZ = typecast(gyroZ, 'uint32'); 
gyroZ = bitshift(gyroZ, 12); % shift bits
gyroZ = gyroZ + 2 ^ 31 + 2 ^ 11; % imu flag bits

allData = [accelX accelY accelZ temp gyroX gyroY gyroZ];
allData = allData';
allData = allData(:);

timeStamps = uint32(aedat.data.imu6.timeStamp(:));
timeStamps = repmat(timeStamps', 7 , 1);
timeStamps = timeStamps(:);

output = zeros(1, 2 * aedat.data.imu6.numEvents * 7, 'uint32'); % allocate horizontal vector to hold output data
output(1 : 2 : end) = allData;
output(2 : 2 : end) = timeStamps; % set even elements to timestamps

% write addresses and timestamps
count=fwrite(f, output, 'uint32') / 2; % write 4 byte data
fclose(f);
fprintf('wrote %d events to %s\n',count, aedat.exportParams.filePath);


