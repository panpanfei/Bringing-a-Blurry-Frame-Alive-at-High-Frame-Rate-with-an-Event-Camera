function ExportAedat3(aedat)

%{
This function exports data to a .aedat file in format version 3. 
The .aedat file format is documented here:
http://inilabs.com/support/software/fileformat/

At the moment, only supports Point2D events. 

%}

%% validation of parameters

dbstop if error

if ~exist('aedat', 'var')
	error('Missing input')
end

if ~isfield(aedat, 'exportParams') || ~isfield(aedat.exportParams, 'filePath')
    error('Missing parameter exportParams.filePath')
end

% For source, use an override if it has been given. This allows data from
% one sensor to masquerade as data from another sensor. 

if isfield(aedat.exportParams, 'source')
    source = aedat.exportParams.source;
else 
    source = aedat.info.source;
end

if ~isfield(aedat, 'data') || ~isfield(aedat.data, 'point2D')
    error('No point2D data to export - other data types haven''t been encoded yet')
end

disp('Writing to file ...')

% Create the file
f = fopen(aedat.exportParams.filePath, 'w', 'l');

% CRLF \r\n is needed to not break header parsing in jAER
fprintf(f,'#!AER-DAT3.1\r\n');
fprintf(f,'#Format: RAW\r\n');
fprintf(f,['#Source 0: ' source '\r\n']);
fprintf(f,'#Start-Time: 1999-01-01 00:00:00\r\n'); % later ...
fprintf(f,'#!END-HEADER\r\n');

% Write header

fwrite(f, 9, 'uint16', 0, 'l'); %eventType
fwrite(f, 0, 'uint16', 0, 'l'); %eventSource
fwrite(f, 16, 'uint32', 0, 'l'); %eventSize
fwrite(f, 12, 'uint32', 0, 'l'); %eventTSOffset
fwrite(f, 0, 'uint32', 0, 'l'); %eventTSOverflow
fwrite(f, aedat.data.point2D.numEvents, 'uint32', 0, 'l'); %eventCapacity
fwrite(f, aedat.data.point2D.numEvents, 'uint32', 0, 'l'); %eventCapacity
fwrite(f, aedat.data.point2D.numEvents, 'uint32', 0, 'l'); %eventCapacity

% Write data

valid = uint32(1);
scale = uint32(2^8);
validPlusScale = valid + scale;
infoField = uint32(aedat.data.point2D.type * 2) ...
              + validPlusScale;
for eventIdx = 1 : aedat.data.point2D.numEvents
    fwrite(f, infoField(eventIdx), 'uint32', 0, 'l');
    fwrite(f, aedat.data.point2D.x(eventIdx), 'single', 0, 'l');
    fwrite(f, aedat.data.point2D.y(eventIdx), 'single', 0, 'l');
    fwrite(f, aedat.data.point2D.timeStamp(eventIdx), 'uint32', 0, 'l');
end

fclose(f);
fprintf('wrote to %s\n', aedat.exportParams.filePath);

