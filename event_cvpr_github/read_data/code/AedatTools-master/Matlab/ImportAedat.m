function aedat = ImportAedat(aedat)

%{
This function imports data from a .aedat file (as well as any attached prefs files). 
The .aedat file format is documented here:

http://inilabs.com/support/software/fileformat/

This function implements most of the functionality of the "loadaerdat" function 
	plus chip-specific interpretation functions, such as "getDVSeventsDavis".
Some data-type-specific functionality are removed, such as a spatial
	region-of-interest (ROI) parameter. 
Addresses and polarities from DAVIS are exactly what is encoded in the file 
	- no messing about with arbitrary inversions and subtractions.
It extends functionality to the new aedat format 3. Importantly, data
	from earlier versions are separated as if they had been encoded in version
	3 - there are separate output data structures for retina address-events vs
	aps samples, etc. 

This function supports incremental readout, through these methods: 
	- Blocks of time can be read out.
	- Alternatively, for fileformats 1.0-2.1, blocks of events (as counted 
		from the beginning of the file) can be read out.
	- Alternatively, for fileformat 3, blocks of packets (as counted from
		the beginning of the file) can be read out.
	In time-based readout, for fileformat 1.0-2.1, frame data is read out 
		according to the timeStamps of individual samples. For fileformat
		3, frames are read out if the mid point between the exposure
		start and exposure end is included in the time window. 
	
This function expects a single input, which is a structure with the following fields:
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
		than this will not be returned. This is in seconds, not
		microseconds.
	- endTime (optional) - if provided, any data with a timeStamp higher than 
		this time will not be returned. This is in seconds, not
		microseconds. 
	- strictTime (optional) boolean - if present and true, then AEDAT3.x
		files will handle the inclusion of time in the startTime-endTime
		time window strictly, i.e. on an event-by-event basis. 
	- startEvent (optional) Only accepted for fileformats 1.0-2.1. If
		provided, any events with a lower count that this will not be returned.
		APS samples, if present, are counted individually as events. 
	- endEvent (optional) Only accepted for fileformats 1.0-2.1. If
		provided, any events with a higher count that this will not be returned.
		APS samples, if present, are counted as events. 
	- startPacket (optional) Only accepted for fileformat 3. If
		provided, any packets with a lower count that this will not be returned.
	- endPacket (optional) Only accepted for fileformat 3. If
		provided, any packets with a higher count that this will not be returned.
	- modPacket (optional) Only accepted for fileformat 3. For sparse sampling of a file, 
        packets are imported if mod(packetNumber,modPacket) = 0 
	- dataTypes (optional) cellarray. If present, only data types specified 
		in this cell array are returned. Options are: 
		special; polarity; frame; imu6; imu9; sample; ear; config (other types as they are implemented)
	- validOnly (optional; aedat3.x only) bool. If present, non-valid
		events are removed.
	When using startEvent and endEvent, any events excluded
	because of the time window or dataType are not replaced, so the amount
	of data returned may be much less than the difference between
	startEvent and endEvent.
		
The output is a structure with the following fields:
	- info - structure containing informational fields. This starts life as the 
		input structure (as defined above), and when output includes:
		- file, as defined in the input structure.
		- fileFormat, as defined above, (double). 
		- source, as derived either from the file or from input.class. In
			the case of multiple sources, this is a horizonal cell array of
			classes of each source in order. 
		- dateTime, a string representing the date and time at which the
			recording started.
		- endEvent - (for file format 1.0-2.1 only) The count of the last event 
			included in the readout.
		- endPacket - (for file format 3 only) The count of the last packet
			from which all of the data has been included in the readout. 
			Packets partially read out are not included in the count - this
			is necessary to implement incremental readout by blocks of
			time.
		- xml (optional) any xml-encoded preferences included in either the header of the file
		or in an associated prefs file found next to the .aedat file. 
	- data - where only a single source is defined (always the case for 
		fileformats 1.0-2.1) this contains one structure for each type of
		data present. These structures are named according to the type of
		data; the options are:
		- special
		- polarity
		- frame
		- imu6
		- imu9
		- sample
		- ear
		- config
		Within each of these structures, there are typically a set of column 
			vectors containing timeStamp, a valid bit and then other data fields, 
			where each vector has the same number of elements. 
			There are some exceptions to this. 
			The valid bit is not constructed for recordings where 
			fileFormat < 3 (where all events are assumed to be valid).
			In detail the contents of these structures are:
		- special
			- valid (colvector bool)
			- timeStamp (colvector uint64)
			- address (colvector uint32) % Not constructed for e.g. DVS128,
				where there is only one type of special event
		- polarity
			- valid (colvector bool)
			- timeStamp (colvector uint64)
			- x (colvector uint16)
			- y (colvector uint16)
			- polarity (colvector bool)
		- frame
			- valid (bool)
			- reset (bool) In AEDAT2/jAER, reset reads are stored separately
				from signal reads; this flag indicates a reset read, which
				should then be subtracted from a subsequent signal read.
			- roiId (uint8)
			- colorChannel (uint8)
			- colorFilter (uint8)
			- frame timeStamp start (uint64)
			- frame timeStamp end (uint64)
			- timeStampExposureStart (uint64)
			- timeStampExposureEnd (uint64)
			- samples (cellArray, with one cell for each frame; cells
				contain a matrix of uint16 row*col*chn, where row is the number of rows,
				col is the number of columns, and chn is the number of
				(colour) channels. Where frames have only one channel, the
				third dimension is squeezed out. 
			- xLength (uint32)
			- yLength (uint32)
			- xPosition (uint32)
			- yPosition (uint32)

		- imu6
			- valid (colvector bool)
			- timeStamp (colvector uint64)
			- accelX (colvector single)
			- accelY (colvector single)
			- accelZ (colvector single)
			- gyroX (colvector single)
			- gyroY (colvector single)
			- gyroZ (colvector single)
			- temperature (colvector single)
		- imu9
			As imu6, but with these 3 additional fields:
			- compX (colvector single)
			- compY (colvector single)
			- compZ (colvector single)
		- sample
			- valid (colvector bool)
			- timeStamp (colvector uint64)
			- sampleType (colvector uint8)
			- sample (colvector uint32)
		- ear
			- valid (colvector bool)
			- timeStamp (colvector uint64)
			- position (colvector uint8)
			- channel (colvector uint16)
			- neuron (colvector uint8)
			- filter (colvector uint8)
		- config
			- valid (colvector bool)
			- timeStamp (colvector uint64)
			- moduleAddress (colvector uint8)
			- parameterAddress (colvector uint8)
			- parameter (colvector uint32)
		If multiple sources are defined, then data is instead a cell array,
			where each cell is a structure as defined above. 
%}

dbstop if error

% If the input variable doesn't exist, create a dummy one.
if ~exist('aedat', 'var') 
    aedat = struct;
end

% Open the file
if ~isfield(aedat, 'importParams') || ~isfield(aedat.importParams, 'filePath')
	[fileName path ~] = uigetfile('*.aedat','Select aedat file');
    if fileName==0
		disp('File to import not specified')
		return
	end
	aedat.importParams.filePath = [path fileName];
end

aedat.importParams.fileHandle = fopen(aedat.importParams.filePath, 'r');

if aedat.importParams.fileHandle == -1
    error('file not found')
end

% Process the headers if they haven't been processed already
% The 'info' field is created by the ImportAedatHeaders function 
if ~isfield(aedat, 'info')
    aedat = ImportAedatHeaders(aedat);
end

% Process the data - different subfunctions handle fileFormat 2 vs 3
if aedat.info.fileFormat < 3
	aedat = ImportAedatDataVersion1or2(aedat);
else
	aedat = ImportAedatDataVersion3(aedat);	
end

fclose(aedat.importParams.fileHandle);
aedat.importParams = rmfield(aedat.importParams, 'fileHandle');

