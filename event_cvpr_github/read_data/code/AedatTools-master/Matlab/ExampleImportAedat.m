%{
Example script for ways to invoke the importAedat function.

- The first example imports from a single file, exploring various
parameters
- The second set of examples first indexes the file then consecutively 
  reads in disjunctive sections of a file. 
- The third example reads in a set of files.
%}

%% Import a single file

clearvars
dbstop if error

% make sure Matlab can see the AedatTools library
addpath('C:\AedatTools\Matlab') 

% Create a structure with which to pass in the input parameters.
aedat = struct;

% Put the filename, including full path, in the 'file' field.

aedat.importParams.filePath = 'C:\project\example3.aedat'; % Windows
aedat.importParams.filePath = '/home/project/example3.aedat'; % Linux

% Alternatively, make sure the file is already on the matlab path.
addpath('C:\project')
aedat.importParams.filePath = 'example3.aedat'; 

% Add any restrictions on what to read out. 
% This example limits readout to the first 1M events (aedat fileFormat 1 or 2 only):
aedat.importParams.endEvent = 1e6;

% This example ignores the first 1M events (aedat fileFormat 1 or 2 only):
aedat.importParams.startEvent = 1e6;

% This example limits readout to a time window between 48.0 and 48.1 s:
aedat.importParams.startTime = 48;
aedat.importParams.endTime = 48.1;

% This example only reads out from packets 1000 to 2000 (aedat3.x only)
aedat.importParams.startPacket = 1000;
aedat.importParams.endPacket = 2000;

% This example samples only every 100th packet (aedat3.x only), in order to quickly assess a large file
aedat.importParams.modPacket = 100;

%These examples limit the read out to certain types of event only
aedat.importParams.dataTypes = {'polarity', 'special'};
aedat.importParams.dataTypes = {'special'};
aedat.importParams.dataTypes = {'frame'};

% With the following flag, you don't get data, but just the header info, 
% plus packet indices info for Aedat3.x
% Thereafter, (aedat3.x only) you can run the import routine again for a
% selected time or packet range and it will use the indices to jump
% straight to the right place in the file. This can be a quicker way of
% exploring large files. There is no such facility for aedat1-2 files. 
aedat.importParams.noData = true;

% Working with a file where the source hasn't been declared - do this explicitly:
aedat.source = 'Davis240c';

% Invoke the function
aedat = ImportAedat(aedat);

%{
ImportAedat supports importation of a large file chunk by chunk. One way of
using this is to pick out small parts of a file at a time and work with
them. 

Another type of batch mode is importing from and working with a series of
files. 

This script contains examples of both types of operation
%}

%% Index the file then import from selected sections of it (aedat3 only)

clearvars
close all
dbstop if error

% Create a structure with which to pass in the input parameters.
aedat = struct;
aedat.importParams.filePath = 'N:\Project\example3.aedat';
aedat.importParams.noData = true; % This tells the function just to index the file by packet.
aedat = ImportAedat(aedat);

% At this point you may look at various info for example data rates as
% indicated by the packet indices. Then you may choose sections of the file
% to look at in detail.

packetRanges = [	1		1000; ...
					5000	6000; ...
					10000	11000];

aedat.importParams.noData = false; % Now that the container has this override you need to override it
for packetRange = 1 : size(packetRanges, 1)
	aedat.importParams.startPacket	= packetRanges(packetRange, 1);
	aedat.importParams.endPacket		= packetRanges(packetRange, 2);
	aedat = ImportAedat(aedat);
	PlotAedat(aedat)
end

% Alternatively, you may choose a time period to look at. 
% In this example, any time before a timestamp reset is ignored:

timeRange = [120 180]; % All time parameters are in seconds; 
                       % internally all timestamps are in microseconds

aedat.importParams.noData = false;
[startPacket, endPacket] = FindPacketsByTimeAfterTimeStampReset(aedat, timeRange(1), timeRange(2));
aedat.importParams.startPacket = startPacket;
aedat.importParams.endPacket = endPacket;
aedat = ImportAedat(aedat);

%% Import and plot from a series of files

clearvars
close all
dbstop if error

% Create a structure with which to pass in the input parameters.
aedat = struct;

% This example only reads out the first 1000 packets
aedat.importParams.endPacket = 1000;


filePaths = {	'N:\Project\example1.aedat'; ...
				'N:\Project\example2.aedat'; ...
				'N:\Project\example3.aedat'};

numFiles = length(filePaths);
			
for file = 1 : numFiles
	aedat.importParams.filePath = filePaths{file};
	aedat = ImportAedat(aedat);
	PlotAedat(aedat)
end