function ExportAedat2Polarity(aedat)

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
if ~isfield(aedat, 'exportParams') || ~isfield(aedat.exportParams, 'filePath')
    error('Missing parameter exportParams.filePath')
end

f = fopen(aedat.exportParams.filePath, 'w', 'b');

% Simple - events only - assume DAVIS ..

% CRLF \r\n is needed to not break header parsing in jAER
fprintf(f,'#!AER-DAT2.0\r\n');
fprintf(f,'# This is a raw AE data file created by an export function in the AedatTools library\r\n');
fprintf(f,'# Data format is int32 address, int32 timestamp (8 bytes total), repeated for each event\r\n');
fprintf(f,'# Timestamps tick is 1 us\r\n');
% Put the source in - use an override if it has been given
if isfield(aedat.exportParams, 'source')
    source = aedat.exportParams.source;
else 
    source = aedat.info.source;
end
fprintf(f,['# AEChip: ' source '\r\n']);
fprintf(f,'# End of ASCII Header\r\n');

if strcmp(source, 'Dvs128')
    % In the 32-bit address:
    % bit 1 (1-based) is polarity
    % bit 2-8 is x
    % bit 9-15 is y
    % bit 16 is special
    
    yShiftBits = 8;
    xShiftBits = 1;
    polShiftBits = 0;
    y =   int32(aedat.data.polarity.y)          * int32(2 ^ yShiftBits);
    x =   int32(aedat.data.polarity.x)          * int32(2 ^ xShiftBits);
    pol = int32(aedat.data.polarity.polarity)    * int32(2 ^ polShiftBits);
    addr = y + x + pol;
else % Default to DAVIS
    % In the 32-bit address:
    % bit 32 (1-based) being 1 indicates an APS sample
    % bit 11 (1-based) being 1 indicates a special event 
    % bits 11 and 32 (1-based) both being zero signals a polarity event

    yShiftBits = 22;
    xShiftBits = 12;
    polShiftBits = 11;
    y =   int32(aedat.data.polarity.y)          * int32(2 ^ yShiftBits);
    x =   int32(aedat.data.polarity.x)          * int32(2 ^ xShiftBits);
    pol = int32(aedat.data.polarity.polarity)    * int32(2 ^ polShiftBits);
    addr = y + x + pol;
end

output = int32(zeros(1,2 * aedat.data.polarity.numEvents)); % allocate horizontal vector to hold output data
output(1:2:end) = addr;
output(2:2:end)=int32(aedat.data.polarity.timeStamp(:)); % set even elements to timestamps

% write addresses and timestamps
count=fwrite(f,output,'uint32')/2; % write 4 byte data
fclose(f);
fprintf('wrote %d events to %s\n', count, aedat.exportParams.filePath);


