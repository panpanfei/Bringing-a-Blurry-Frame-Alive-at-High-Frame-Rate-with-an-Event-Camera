function aedat = ImportAedatHeaders(aedat)

%{
This is a sub-function of importAedat. 
This function processes the headers of an Aedat file. 
(as well as any attached prefs files). 
The .aedat file format is documented here:
http://inilabs.com/support/software/fileformat/

2015_12_11 Work in progress: 
	- Reading from a separate prefs file is not implemented yet.  
	- It would be neater (more readable) to turn the xml cell array into a
		structure.

This function expects a structure "info" with the following fields:
	- fileHandle - the handle of the file (useful for passing amongst
	subfunctions).
	- filePath (optional) - a string containing the full path to the file, 
		including its name. If this field is not present, the function will
		try to open the first file in the current directory.
	- source (optional) - a string containing the name of the chip class from
		which the data came. Options are (upper case, spaces, hyphens, underscores
		are eliminated if used):
		- file
		- network
		- dvs128 (tmpdiff128 accepted as equivalent)
		- davis - a generic label for any davis sensor
		- davis240a (sbret10 accepted as equivalent)
		- davis240b (sbret20, seebetter20 accepted as equivalent)
		- davis240c (sbret21 accepted as equivalent)
		- davis128mono 
		- davis128rgb (davis128 accepted as equivalent)
		- davis208rgbw (sensdavis192, pixelparade, davis208 accepted as equivalent)
		- davis208mono (sensdavis192, pixelparade accepted as equivalent)
		- davis346rgb (davis346 accepted as equivalent)
		- davis346mono 
		- davis346bsi 
		- davis640rgb (davis640 accepted as equivalent)
		- davis640mono 
		- hdavis640mono 
		- hdavis640rgbw (davis640rgbw, cdavis640 accepted as equivalent)
		- das1 (cochleaams1c accepted as equivalent)
		If class is not provided and the file does not specify the class, dvs128 is assumed.
		If the file specifies the class then this input is ignored. 
	- startTime (optional) - if provided, any data with a timeStamp lower
		than this will not be returned.
	- endTime (optional) - if provided, any data with a timeStamp higher than 
		this time will not be returned.
	- startEvent (optional) Only accepted for fileformats 1.0-2.1. If
		provided, any events with a lower count that this will not be returned.
		APS samples, if present, are counted as events. 
	- endEvent (optional) Only accepted for fileformats 1.0-2.1. If
		provided, any events with a higher count that this will not be returned.
		APS samples, if present, are counted as events. 
	- startPacket (optional) Only accepted for fileformat 3.0. If
		provided, any packets with a lower count that this will not be returned.
	- endPacket (optional) Only accepted for fileformat 3.0. If
		provided, any packets with a higher count that this will not be returned.
		
The output is the same "info" structure; it has the following additional or 
	updated fields:
	- fileFormat - i.e. Aedat format version (double). 
	- source (string) - as derived either from info.source or failing that, 
		from the file. In the case of multiple sources, this is a horizonal 
		cell array of sources in order. 
	- dateTime - a string encoding the start date and time of the
	recording.
	- endEvent - (for file format 1.0-2.1 only) The count of the last event 
		included in the readout.
	- endPacket - (for file format 3.0 only) The count of the last packet
		from which all of the data has been included in the readout. 
		Packets partially read out are not included in the count - this
		is necessary to implement incremental readout by blocks of
		time.
	- xml (optional) any preferences included in either the header of the file
	or in an associated prefs file found next to the .aedat file. 
	- beginningOfDataPointer - an integer
%}

dbstop if error

importParams = aedat.importParams;
fileHandle = aedat.importParams.fileHandle;

info = struct;

% Start from the beginning of the file (should not be necessary)
frewind(fileHandle);
info.beginningOfDataPointer = ftell(fileHandle); 

% Read the first line to determine file format
line = native2unicode(fgets(fileHandle));
versionPrefix = '#!AER-DAT';
if strncmp(line, versionPrefix, length(versionPrefix))
	info.fileFormat = sscanf(line(length(versionPrefix) + 1 : end), '%f');
	fprintf('File format: %g.1\n', info.fileFormat);
else % the default version is 1
	info.fileFormat = 1;
	fprintf('No #!AER-DAT version header found, assuming format 1.0\n');
end

% Read through all the header lines
info.xml = {};
while line(1)=='#'
	
    fprintf('%s\n',line(1:end-2)); % Debugging only, or could perhaps be used in a verbose mode - print line using \n for newline, discarding CRLF written by java under windows

	% When exiting the while loop, this pointer points to the byte before the start of the actual data
    info.beginningOfDataPointer = ftell(fileHandle); 
	
	% Strip off # and initial spaces, and trailing /r/n
	line = strtrim(line(2:end-2));
	
	% Pick out the source
	% Version 2.0 encodes it like this:
	if strncmp(line, 'AEChip: ', 8)
		% Ignore the class path and only use what follows the final dot 
		startPrefix = find(line=='.', 1, 'last');
        if isempty(startPrefix)
            startPrefix = 8;
        end
		sourceFromFile = BasicSourceName(line(startPrefix + 1 : end));
	end
	% Version 3.0 encodes it like this
	% The following ignores any trace of previous sources (prefixed with a minus sign)
	if strncmp(line, 'Source ', 7) 
		startPrefix = find(line==':'); % There should be only one colon
		if isfield(info, 'sourceFromFile')
			% One source has already been added; convert to a cell array if
			% it has not already been done
            % THIS NEEDS RETHINKING
			if ~iscell(info.sourceFromFile)
				info.sourceFromFile = {info.sourceFromFile};
			end
			info.sourceFromFile = [info.sourceFromFile line(startPrefix + 2 : end)];
		else
			sourceFromFile = line(startPrefix + 2 : end);
		end		
	end

	% Pick out date and time of recording
	
	% Version 2.0 encodes it like this:
	% # created Thu Dec 03 14:47:00 CET 2015
	if strncmp(line, 'created ', 8) 
		info.dateTime = line(9 : end);
	end
	
	% Version 3.0 encodes it like this:
	% # Start-Time: %Y-%m-%d %H:%M:%S (TZ%z)\r\n
	if strncmp(line, 'Start-Time: ', 12) 
		info.dateTime = line(13 : end);
	end

	% Parse xml, adding it to output as a cell array, in a field called 'xml'.
	% This is done by maintaining a cell array which is inside out as it is
	% constructed - as a level of the hierarchy is descended, everything is
	% pushed down into the first position of a cell array, and as the
	% hierarchy is ascended, the first node is popped back up and the nodes 
	% that have been added to the right are pushed down inside it. 
	
	% If <node> then descend hierarchy - do this by taking the existing
	% cell array and putting it into another cell array
	if strncmp(line, '<node', 5)
		nameOfNode = line(length('<node name="') + 1 : end - length('">'));
		info.xml = {info.xml nameOfNode};
		
	% </node> - ascend hierarchy - take everything to the right of the
	% initial cell array and put it inside the inital cell array
	elseif strncmp(line, '</node>', 7)
		parent = info.xml{1};
		child = info.xml(2:end);
		info.xml = [parent {child}];
		
	% <entry> - Add a field to the struct
	elseif strncmp(line, '<entry ', 7)
		% Find the division between key and value
		endOfKey = strfind(line, '" value="');
		key = line(length('<entry key="') + 1 : endOfKey - 1);
		value = line(endOfKey + length('" value="') : end - length('"/>')); 
		info.xml{end + 1} = {key value};
	end
	% Gets the next line, including line ending chars
    line = native2unicode(fgets(fileHandle)); 
end

% If a device is specified in input, does it match the derived source?
if isfield(importParams, 'source')
	sourceFromImportParams = BasicSourceName(importParams.source);
	if exist('sourceFromFile', 'var') && ~strcmp(sourceFromImportParams, sourceFromFile)
        fprintf('The source given as input, "%s", doesn''t match the source declared in the file, "%s"; assuming the source given as input.\n', sourceFromImportParams, info.sourceFromFile);
	end
    info.source = sourceFromImportParams;
elseif exist('sourceFromFile', 'var')
	info.source = BasicSourceName(sourceFromFile);
else
	% If no source was detected, assume it was from a DVS128	
	info.source = 'Dvs128';
end

if strcmp(info.source, 'SecDvs')
    % The secdvs bin to aedat encoder adds an extra 5 newline (0x0A) characters
    % at this point (I don't know why). Strip them off.
    info.beginningOfDataPointer = info.beginningOfDataPointer + 5; 
end

% Get the address space (dimensions) of the device
% For vision sensors, this is a tuple [X Y]
info.deviceAddressSpace = DeviceAddressSpace(info.source);

% Pack the result (importParams is already in aedat and need not be packed
aedat.info = info;
