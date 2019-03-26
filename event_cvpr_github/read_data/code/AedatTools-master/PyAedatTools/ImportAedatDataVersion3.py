#!/usr/bin/env python

# Federico Corradi contributed the first version of this code
"""
Import data from AEDAT version 3 format
A subfunction of ImportAedat.py 
Refer to this function for the definition of input/output variables etc

Let's just assume this code runs on little-endian processor. 

Not handled yet:
Timestamp overflow
Reading by packets
Data-type-specific read in
Frames and other data types
Multi-source read-in
Building large arrays, 
    exponentially expanding them, and cropping them at the end, in order to 
    read more efficiently - at the moment we build a list then convert to array. 


"""

import struct
import math
import numpy as np                       
from PyAedatTools.FindFirstAndLastTimeStamps import FindFirstAndLastTimeStamps
from PyAedatTools.NumEventsByType import NumEventsByType

def ImportAedatDataVersion3(aedat):

    # Unpack the aedat dict
    info = aedat['info']
    importParams = aedat['importParams']
    fileHandle = importParams['fileHandle']
    
    # Check the startEvent and endEvent parameters
    if 'startPacket' in importParams:
        startPacket = importParams.startPacket
    else:    
        startPacket = 1

    if 'endPacket' in importParams:
        endPacket = importParams['endPacket']
    else:
        endPacket = np.inf
        
    if startPacket > endPacket:
        raise Exception('The startPacket parameter is %d, but the endPacket parameter is %d' % (startPacket, endPacket))
    
    if 'startEvent' in importParams:
        raise Exception('The startEvent parameter is set, but range by events is not available for .aedat version 3.x files')
    
    if 'endEvent' in importParams:
        raise Exception('The endEvent parameter is set, but range by events is not available for .aedat version 3.x files')
    
    if 'startTime' in importParams:
        startTime = importParams['startTime']
    else:
        startTime = 0
    
    if 'endTime' in importParams:
        endTime = importParams['endTime']
    else:
        endTime = np.inf
    
    if startTime > endTime:
        raise Exception('The startTime parameter is %d, but the endTime parameter is %d' % (info['startTime'], info['endTime']))
    
    # By default, throw away timeStampFrameStart/End, 
    # renaming timeStampExposureStart/End to timeStampStart/End
    if 'simplifyFrameTimeStamps' in importParams:
        simplifyFrameTimeStamps = importParams['simplifyFrameTimeStamps']
    else:
        simplifyFrameTimeStamps = True

    # By default, throw away the valid flags, 
    # and any events which are set as invalid.
    if 'validOnly' in importParams:
        validOnly = importParams['validOnly']
    else:
        validOnly = True

    # By default, do not skip any packets
    if 'modPacket' in importParams:
        modPacket = importParams['modPacket']
    else:
        modPacket = 1
    
    # By default, import the full data, rather than just indexing the packets
    if 'noData' in importParams: 
        noData = importParams['noData']
    else:
        noData = False

    # By default, import all data types
    if 'dataTypes' in importParams:
        allDataTypes = False
        dataTypes = importParams['dataTypes']
    else:
        allDataTypes = True
        
    packetCount = 0

    # Has this file already been indexed in a previous pass?
    if 'packetPointers' in info:
        packetTypes = info['packetTypes']
        packetPointers = info['packetPointers']
        packetTimeStamps = info['packetTimeStamps']
    elif endPacket < np.inf:
        packetTypes = np.ones(endPacket, np.uint16)
        packetPointers = np.zeros(endPacket, np.uint64)
        packetTimeStamps = np.zeros(endPacket, np.uint64)
    else:
        packetTypes = np.ones(1000, np.uint16)
        packetPointers = np.zeros(1000, np.uint64)
        packetTimeStamps = np.zeros(1000, np.uint64)
        
    if noData == False:
        specialNumEvents = 0
        specialValid = np.zeros(0, dtype=bool)
        specialDataFormat = np.dtype([('info', '<u4'), ('timeStamp', '<i4')])

        polarityNumEvents  = 0
        polarityValid      = np.zeros(0, dtype=bool)
        polarityDataFormat = np.dtype([('address', '<u4'), ('timeStamp', '<i4')])

        frameNumEvents              = 0
        frameValid                  = np.zeros(0, dtype=bool)
        frameColorChannelsMask      = 0xE
        frameColorChannelsShiftBits = 1
        frameColorFilterMask        = 0x70
        frameColorFilterShiftBits   = 4
        frameRoiIdMask              = 0x3F80
        frameRoiIdShiftBits         = 7

        imu6NumEvents = 0
        imu6Valid     = np.zeros(0, dtype=bool)

        sampleNumEvents = 0
        sampleValid     = np.zeros(0, dtype=bool)

        earNumEvents = 0
        earValid     = np.zeros(0, dtype=bool)

        point1DNumEvents = 0
        point1DValid     = np.zeros(0, dtype=bool)
        point1DDataFormat = np.dtype([('info', '<u4'), 
                                      ('x', '<f4'), 
                                      ('timeStamp', '<i4')])

        point2DNumEvents = 0
        point2DValid     = np.zeros(0, dtype=bool)
        point2DDataFormat = np.dtype([('info', '<u4'), 
                                      ('x', '<f4'), 
                                      ('y', '<f4'), 
                                      ('timeStamp', '<i4')])

        point3DNumEvents = 0
        point3DValid     = np.zeros(0, dtype=bool)
        point3DDataFormat = np.dtype([('info', '<u4'), 
                                      ('x', '<f4'), 
                                      ('y', '<f4'), 
                                      ('z', '<f4'), 
                                      ('timeStamp', '<i4')])

        # Ignore scale for now 
  
    fileHandle.seek(info['beginningOfDataPointer'])
    
    # If the file has been indexed or partially indexed, and there is a
    # startPacket or startTime parameter, then jump ahead to the right place
    if 'packetPointers' in info:
        if startPacket > 1: 
            fileHandle.seek(packetPointers(startPacket))
            packetCount = startPacket - 1
        elif startTime > 0:
            targetPacketIndices = np.argwhere(info['packetTimeStamps'] < startTime * 1e6)
            if targetPacketIndices: # i.e. targetPacketIndices is not empty
                fileHandle.seek(packetPointers(targetPacketIndices[-1]))
                packetCount = targetPacketIndices[-1]
    
    # If the file has already been indexed (PARTIAL INDEXING NOT HANDLED), and
    # we are using modPacket to skip a proportion of the data, then use this
    # flag to speed up the loop
    modSkipping = 'packetPointers' in info and modPacket > 1
    
    while True : # implement the exit conditions inside the loop - allows to distinguish between different types of exit
    # Headers
        # Read the header of the next packet
        packetCount = packetCount + 1
        if modSkipping:
            packetCount = np.ceil(packetCount / modPacket) * modPacket
            fileHandle.seek(packetPointers[packetCount])


        header = fileHandle.read(28)
        if len(header) < 28: # i.e. EOF
            packetCount = packetCount - 1
            info['numPackets'] = packetCount
            break
        if len(packetTypes) < packetCount:
            # Double the size of packet index arrays as necessary
            packetTypes      = np.append(packetTypes,      np.ones (packetCount, 'uint16') * 32768, 0)
            packetPointers   = np.append(packetPointers,   np.zeros(packetCount, 'uint64'), 0)
            packetTimeStamps = np.append(packetTimeStamps, np.zeros(packetCount, 'uint64'), 0)
        packetPointers[packetCount] = fileHandle.tell() - 28    
        if packetCount % 100 == 0 :
            print 'packet: %d; file position: %d MB' % (packetCount, math.floor(info['fileHandle'].tell / 1000000))
        if startPacket > packetCount or np.mod(packetCount, modPacket) > 0:
            # Ignore this packet as its count is too low
            eventSize = struct.unpack('I', header[4:8])[0]
            eventNumber = struct.unpack('I', header[20:24])[0]
            fileHandle.seek(eventNumber * eventSize, 1)
        elif endPacket < packetCount:
            packetCount = packetCount - 1
        else:
            eventSize = struct.unpack('I', header[4:8])[0]
            eventTsOffset = struct.unpack('I', header[8:12])[0]
            eventTsOverflow = struct.unpack('I', header[12:16])[0]
            #eventCapacity = struct.unpack('I', header[16:20])[0] # Not needed
            eventNumber = struct.unpack('I', header[20:24])[0]
            #eventValid = struct.unpack('I', header[24:28])[0] # Not needed
            # Read the full packet
            numBytesInPacket = eventNumber * eventSize
            packetTimeStampOffset = np.uint64(eventTsOverflow) * 2 ** 31 # Why 31 bits? because this is added to the 32 bit timestamp, which is signed and therefore wraps after 31 bits
            '''
            There should be a startTime check here, but this requires to find the maintimestamp by reading ahead - do this later
            It should only do this until a flag is raised saying that we're now past the start time.
                        # Check the start time constraint
                        if startTime * 1e6 <= mainTimeStamp:
            '''
            eventType = struct.unpack('h', header[0:2])[0]
            packetTypes[packetCount] = eventType
        
            #eventSource = struct.unpack('h', [header[2:4])[0] # Multiple sources not handled yet
            if noData:
                # Inefficient - better to just read the timestamp and skip the rest
                packetData = fileHandle.read(numBytesInPacket)
                mainTimeStamp = np.uint64(struct.unpack('i', \
                                       packetData[eventTsOffset : eventTsOffset + 4])[0]) \
                              + packetTimeStampOffset
            else:
                              
                # Handle the packet types individually:
            
                # Special events
                if eventType == 0:
                    if allDataTypes or 'special' in info['dataTypes']:
                        # First check if the array is big enough
                        currentLength = len(specialValid)
                        if currentLength == 0:
                            specialValid     = np.zeros(eventNumber, dtype=bool)
                            specialTimeStamp = np.zeros(eventNumber, 'uint64')
                            specialAddress   = np.zeros(eventNumber, 'uint32')
                        else:
                            while eventNumber > currentLength - specialNumEvents:
                                specialValid		= np.append(specialValid,     np.zeros(currentLength, 'bool'  ))
                                specialTimeStamp	= np.append(specialTimeStamp, np.zeros(currentLength, 'uint64'))
                                specialAddress	= np.append(specialAddress,   np.zeros(currentLength, 'uint32'))
                                currentLength = len(specialValid)
                        allEvents = np.fromfile(fileHandle, specialDataFormat, eventNumber)
                        allInfo = np.array(allEvents['info'])
                        specialValid[specialNumEvents : specialNumEvents + eventNumber] \
                            = bool(allInfo and 0x1) # Pick off the first bit
                        specialAddress[specialNumEvents : specialNumEvents + eventNumber] \
                            = (allInfo and 0xFE) >> 1 # Next 7 bits are the special event type
                        # special optional data would go here - next 24 bits - no need at the present    
                        specialTimeStamp[specialNumEvents : specialNumEvents + eventNumber] \
                            = packetTimeStampOffset + np.uint64(np.array(allEvents['timeStamp']))
                        mainTimeStamp = specialTimeStamp(specialNumEvents)
                        specialNumEvents = specialNumEvents + eventNumber

                # Polarity events                
                elif eventType == 1:  
                    if allDataTypes or 'polarity' in info['dataTypes']:
                        # First check if the array is big enough
                        currentLength = len(polarityValid)
                        if currentLength == 0:
                            polarityValid     = np.zeros(eventNumber, dtype=bool)
                            polarityTimeStamp = np.zeros(eventNumber, 'uint64')
                            polarityX         = np.zeros(eventNumber, 'uint16')
                            polarityY         = np.zeros(eventNumber, 'uint16')
                            polarityPolarity  = np.false(eventNumber);
                        else:
                            while eventNumber > currentLength - polarityNumEvents:
                                polarityValid     = np.append(polarityValid,     np.zeros(currentLength, 'bool'  ))
                                polarityTimeStamp = np.append(polarityTimeStamp, np.zeros(currentLength, 'uint64'))
                                polarityX         = np.append(polarityX,         np.zeros(currentLength, 'uint16'))
                                polarityY         = np.append(polarityY,         np.zeros(currentLength, 'uint16'))
                                polarityPolarity  = np.append(polarityPolarity,  np.false(currentLength          ))
                                currentLength = len(polarityValid)
                        allEvents = np.fromfile(fileHandle, polarityDataFormat, eventNumber)
                        allAddresses = np.array(allEvents['addr'])
                        # Pick off the first bit as the validity mark
                        polarityValid[polarityNumEvents : polarityNumEvents + eventNumber] \
                            = bool(allAddresses & 0x1) 
                        # Pick off the second bit as the polarity
                        polarityPolarity[polarityNumEvents : polarityNumEvents + eventNumber] \
                            = bool(allAddresses & 0x2)
                        polarityY[polarityNumEvents : polarityNumEvents + eventNumber] \
                            = np.uint16((allAddresses & 0x1FFFC) >> 2)
                        polarityX[polarityNumEvents : polarityNumEvents + eventNumber] \
                            = np.uint16((allAddresses & 0xFFFE0000) >> 17)
                        polarityTimeStamp[polarityNumEvents : polarityNumEvents + eventNumber] \
                            = packetTimeStampOffset + np.uint64(np.array(allEvents['timeStamp'])) 
                        mainTimeStamp = polarityTimeStamp(polarityNumEvents)
                        polarityNumEvents = polarityNumEvents + eventNumber
                # Frames
                elif(eventType == 2): 
                    '''                    
                    if allDataTypes || any(cellfun(cellFind('frame'), dataTypes))
                        % First check if the array is big enough
                        currentLength = length(frameValid);
                        if currentLength == 0
                            frameValid					= np.zeros(eventNumber, dtype=bool)
                            frameColorChannels			= uint8(zeros(eventNumber, 1));
                            frameColorFilter			= uint8(zeros(eventNumber, 1));
                            frameRoiId					= uint8(zeros(eventNumber, 1));
                            if simplifyFrameTimeStamps
                                frameTimeStampStart     = uint64(zeros(eventNumber, 1));
                                frameTimeStampEnd		= uint64(zeros(eventNumber, 1));
                            else
                                frameTimeStampFrameStart	= uint64(zeros(eventNumber, 1));
                                frameTimeStampFrameEnd		= uint64(zeros(eventNumber, 1));
                                frameTimeStampExposureStart = uint64(zeros(eventNumber, 1));
                                frameTimeStampExposureEnd	= uint64(zeros(eventNumber, 1));
                            end
                            frameXLength				= uint16(zeros(eventNumber, 1));
                            frameYLength				= uint16(zeros(eventNumber, 1));
                            frameXPosition				= uint16(zeros(eventNumber, 1));
                            frameYPosition				= uint16(zeros(eventNumber, 1));
                            frameSamples				= cell(eventNumber, 1);
                        else	
                            while eventNumber > currentLength - frameNumEvents
                                frameValid					= [frameValid;                  false(currentLength, 1)];
                                frameColorChannels			= [frameColorChannels;			uint8(zeros(currentLength, 1))];
                                frameColorFilter			= [frameColorFilter;			uint8(zeros(currentLength, 1))];
                                frameRoiId					= [frameRoiId;					uint8(zeros(currentLength, 1))];
                                if simplifyFrameTimeStamps
                                    frameTimeStampStart	= [frameTimeStampStart;	uint64(zeros(currentLength, 1))];
                                    frameTimeStampEnd		= [frameTimeStampEnd;		uint64(zeros(currentLength, 1))];
                                else
                                    frameTimeStampFrameStart	= [frameTimeStampFrameStart;	uint64(zeros(currentLength, 1))];
                                    frameTimeStampFrameEnd		= [frameTimeStampFrameEnd;		uint64(zeros(currentLength, 1))];                                
                                    frameTimeStampExposureStart = [frameTimeStampExposureStart; uint64(zeros(currentLength, 1))];
                                    frameTimeStampExposureEnd	= [frameTimeStampExposureEnd;	uint64(zeros(currentLength, 1))];
                                end
                                frameXLength				= [frameXLength;				uint16(zeros(currentLength, 1))];
                                frameYLength				= [frameYLength;				uint16(zeros(currentLength, 1))];
                                frameXPosition				= [frameXPosition;				uint16(zeros(currentLength, 1))];
                                frameYPosition				= [frameYPosition;				uint16(zeros(currentLength, 1))];
                                frameSamples				= [frameSamples;				cell(currentLength, 1)];
                                currentLength = length(frameValid);
                                %disp(['Frame array resized to ' num2str(currentLength)])
                            end
                        end					

                        % Iterate through the events, converting the data and
                        % populating the arrays
                        for dataPointer = 1 : eventSize : numBytesInPacket % This points to the first byte for each event
                            frameNumEvents = frameNumEvents + 1;
                            frameValid(frameNumEvents) = mod(packetData(dataPointer), 2) == 1; % Pick off the first bit
                            frameData = typecast(packetData(dataPointer : dataPointer + 3), 'uint32');
                            frameColorChannels(frameNumEvents) = uint16(bitshift(bitand(frameData, frameColorChannelsMask), -frameColorChannelsShiftBits));
                            frameColorFilter(frameNumEvents)	= uint16(bitshift(bitand(frameData, frameColorFilterMask),	-frameColorFilterShiftBits));
                            frameRoiId(frameNumEvents)		= uint16(bitshift(bitand(frameData, frameRoiIdMask),		-frameRoiIdShiftBits));
                            if simplifyFrameTimeStamps
                                frameTimeStampStart(frameNumEvents)		= packetTimeStampOffset + uint64(typecast(packetData(dataPointer + 12 : dataPointer + 15), 'int32'));
                                frameTimeStampEnd(frameNumEvents)		= packetTimeStampOffset + uint64(typecast(packetData(dataPointer + 16 : dataPointer + 19), 'int32'));
                            else
                                frameTimeStampFrameStart(frameNumEvents)		= packetTimeStampOffset + uint64(typecast(packetData(dataPointer + 4 : dataPointer + 7), 'int32'));
                                frameTimeStampFrameEnd(frameNumEvents)		= packetTimeStampOffset + uint64(typecast(packetData(dataPointer + 8 : dataPointer + 11), 'int32'));
                                frameTimeStampExposureStart(frameNumEvents)	= packetTimeStampOffset + uint64(typecast(packetData(dataPointer + 12 : dataPointer + 15), 'int32'));
                                frameTimeStampExposureEnd(frameNumEvents)		= packetTimeStampOffset + uint64(typecast(packetData(dataPointer + 16 : dataPointer + 19), 'int32'));
                            end
                            frameXLength(frameNumEvents)		= typecast(packetData(dataPointer + 20 : dataPointer + 21), 'uint16'); % strictly speaking these are 4-byte signed integers, but there's no way they'll be that big in practice
                            frameYLength(frameNumEvents)		= typecast(packetData(dataPointer + 24 : dataPointer + 25), 'uint16');
                            frameXPosition(frameNumEvents)	= typecast(packetData(dataPointer + 28 : dataPointer + 29), 'uint16');
                            frameYPosition(frameNumEvents)	= typecast(packetData(dataPointer + 32 : dataPointer + 33), 'uint16');
                            numSamples = int32(frameXLength(frameNumEvents)) * int32(frameYLength(frameNumEvents)) * int32(frameColorChannels(frameNumEvents)); % Conversion to int32 allows addition with 'dataPointer' below
                            % At least one recording has a file ending half way
                            % through the frame data due to a laptop dying,
                            % hence the following check
                            if length(packetData) >= dataPointer + 35 + numSamples * 2
                                sampleData = cast(typecast(packetData(dataPointer + 36 : dataPointer + 35 + numSamples * 2), 'uint16'), 'uint16');
                                frameSamples{frameNumEvents}		= reshape(sampleData, frameColorChannels(frameNumEvents), frameXLength(frameNumEvents), frameYLength(frameNumEvents));
                                if frameColorChannels(frameNumEvents) == 1
                                    frameSamples{frameNumEvents} = squeeze(frameSamples{frameNumEvents});
                                    frameSamples{frameNumEvents} = permute(frameSamples{frameNumEvents}, [2 1]);
                                else
                                    % Change the dimensions of the frame array to
                                    % the standard for matlab: column, then row,
                                    % then channel number
                                    frameSamples{frameNumEvents} = permute(frameSamples{frameNumEvents}, [3 2 1]);
                                end
                            else
                                frameSamples{frameNumEvents} = zeros(frameYLength(frameNumEvents), frameXLength(frameNumEvents), frameColorChannels(frameNumEvents));
                            end
                            % aedat3 uses left-justified 16 bit samples -
                            % for consistency with aedat2, revert to
                            % fundamental 10 bit representation
                            frameSamples{frameNumEvents} = frameSamples{frameNumEvents} / 2^6;
                        end
                        
                    end
                    '''
                # Imu6    
                elif eventType == 3:
                    '''
                    if allDataTypes || any(cellfun(cellFind('imu6'), dataTypes))
                        % First check if the array is big enough
                        currentLength = length(imu6Valid);
                        if currentLength == 0 
                            imu6Valid			= np.zeros(eventNumber, dtype=bool)
                            imu6TimeStamp		= uint64(zeros(eventNumber, 1));
                            imu6AccelX			= single(zeros(eventNumber, 1));
                            imu6AccelY			= single(zeros(eventNumber, 1));
                            imu6AccelZ			= single(zeros(eventNumber, 1));
                            imu6GyroX			= single(zeros(eventNumber, 1));
                            imu6GyroY			= single(zeros(eventNumber, 1));
                            imu6GyroZ			= single(zeros(eventNumber, 1));
                            imu6Temperature     = single(zeros(eventNumber, 1));
                        else	
                            while eventNumber > currentLength - imu6NumEvents
                                imu6Valid			= [imu6Valid;        false(currentLength, 1)];
                                imu6TimeStamp		= [imu6TimeStamp;    uint64(zeros(currentLength, 1))];
                                imu6AccelX			= [imu6AccelX;       single(zeros(currentLength, 1))];
                                imu6AccelY			= [imu6AccelY;       single(zeros(currentLength, 1))];
                                imu6AccelZ			= [imu6AccelZ;       single(zeros(currentLength, 1))];
                                imu6GyroX			= [imu6GyroX;        single(zeros(currentLength, 1))];
                                imu6GyroY			= [imu6GyroY;        single(zeros(currentLength, 1))];
                                imu6GyroZ			= [imu6GyroZ;        single(zeros(currentLength, 1))];
                                imu6Temperature     = [imu6Temperature;  single(zeros(currentLength, 1))];                            
                                currentLength = length(imu6Valid);
                            end
                        end
                        % Matricise computation on a packet
                        dataMatrix = reshape(packetData, [eventSize, eventNumber]);
                        dataTempTimeStamp = dataMatrix(5:8, :);
                        imu6TimeStamp(imu6NumEvents + (1 : eventNumber)) = packetTimeStampOffset + uint64(typecast(dataTempTimeStamp(:), 'int32'));
                        % The following is overkill - only need to pick out 1
                        % byte to get to the valid flag
                        dataTempAddress = dataMatrix(1:4, :);
                        dataTempAddress = typecast(dataTempAddress(:), 'uint32');
                        imu6Valid(imu6NumEvents + (1 : eventNumber)) = mod(dataTempAddress, 2) == 1; % Pick off the first bit
                        tempDataMatrix = dataMatrix(9:12, :);
                        imu6AccelX      (imu6NumEvents + (1 : eventNumber)) = typecast(tempDataMatrix(:), 'single');
                        tempDataMatrix = dataMatrix(13:16, :);
                        imu6AccelY      (imu6NumEvents + (1 : eventNumber)) = typecast(tempDataMatrix(:), 'single');
                        tempDataMatrix = dataMatrix(17:20, :);
                        imu6AccelZ      (imu6NumEvents + (1 : eventNumber)) = typecast(tempDataMatrix(:), 'single');
                        tempDataMatrix = dataMatrix(21:24, :);
                        imu6GyroX       (imu6NumEvents + (1 : eventNumber)) = typecast(tempDataMatrix(:), 'single');
                        tempDataMatrix = dataMatrix(25:28, :);
                        imu6GyroY       (imu6NumEvents + (1 : eventNumber)) = typecast(tempDataMatrix(:), 'single');
                        tempDataMatrix = dataMatrix(29:32, :);
                        imu6GyroZ       (imu6NumEvents + (1 : eventNumber)) = typecast(tempDataMatrix(:), 'single');
                        tempDataMatrix = dataMatrix(33:36, :);
                        imu6Temperature (imu6NumEvents + (1 : eventNumber)) = typecast(tempDataMatrix(:), 'single');
                        imu6NumEvents = imu6NumEvents + eventNumber;
                    end
                    '''
                # Sample
                elif eventType == 5:
                    '''
                     if allDataTypes || any(cellfun(cellFind('sample'), dataTypes))
                        %{        polarityYShiftBits = 2
        polarityXShiftBits = 17
        numBytesPerEvent   = 8
                        sampleValid			= bool([]);
                        sampleTimeStamp		= uint64([]);
                        sampleSampleType	= uint8([]);
                        sampleSample		= uint32([]);
                        %}
                    '''
                # Ear
                elif eventType == 6:
                    '''
                     if allDataTypes || any(cellfun(cellFind('ear'), dataTypes))
                        %{
                        earValid		= bool([]);
                        earTimeStamp	= uint64([]);
                        earPosition 	= uint8([]);
                        earChannel		= uint16([]);
                        earNeuron		= uint8([]);
                        earFilter		= uint8([]);
                        %}
                    '''        
                # Point1D
                elif eventType == 8: 

                    if allDataTypes or 'point1D' in info['dataTypes']:
                        # First check if the array is big enough
                        currentLength = len(point1DValid)
                        if currentLength == 0:
                            point1DValid     = np.zeros(eventNumber, 'bool')
                            point1DTimeStamp = np.zeros(eventNumber, 'uint64')
                            point1DType      = np.zeros(eventNumber, 'uint8')
                            point1DX         = np.zeros(eventNumber, 'float32')
                        else:	
                            while eventNumber > currentLength - point1DNumEvents:
                                point1DValid		= np.append(point1DValid,		np.zeros(currentLength, 'bool'  ))
                                point1DTimeStamp	= np.append(point1DTimeStamp,	np.zeros(currentLength, 'uint64'))
                                point1DType	    = np.append(point1DType,	    np.zeros(currentLength, 'uint8'))
                                point1DX		= np.append(point1DX,		np.zeros(currentLength, 'float32'))
                                currentLength = len(point1DValid)
                        allEvents = np.fromfile(fileHandle, point1DDataFormat, eventNumber)
                        allInfo = np.array(allEvents['info'])
                        point1DValid[point1DNumEvents : point1DNumEvents + eventNumber] \
                            = bool(allInfo and 0x1) # Pick off the first bit
                        point1DType[point1DNumEvents : point1DNumEvents + eventNumber] \
                            = (allInfo and 0xFE) >> 1 # Next 7 bits are the point1D event type
                        # point1D scale would go here - next 8 bits - no need at the present    
                        point1DX[point1DNumEvents : point1DNumEvents + eventNumber] \
                            = np.array(allEvents['x'])
                        point1DTimeStamp[point1DNumEvents : point1DNumEvents + eventNumber] \
                            = packetTimeStampOffset + np.uint64(np.array(allEvents['timeStamp']))
                        mainTimeStamp = point1DTimeStamp(point1DNumEvents)
                        point1DNumEvents = point1DNumEvents + eventNumber

                # Point2D
                elif eventType == 9:

                    if allDataTypes or 'point2D' in info['dataTypes']:
                        # First check if the array is big enough
                        currentLength = len(point2DValid)
                        if currentLength == 0:
                            point2DValid     = np.zeros(eventNumber, 'bool')
                            point2DTimeStamp = np.zeros(eventNumber, 'uint64')
                            point2DType      = np.zeros(eventNumber, 'uint8')
                            point2DX         = np.zeros(eventNumber, 'float32')
                            point2DY         = np.zeros(eventNumber, 'float32')
                        else:
                            while eventNumber > currentLength - point1DNumEvents:
                                point2DValid     = np.append(point2DValid,     np.zeros(currentLength, 'bool'  ))
                                point2DTimeStamp = np.append(point2DTimeStamp, np.zeros(currentLength, 'uint64'))
                                point2DType      = np.append(point2DType,	      np.zeros(currentLength, 'uint8'))
                                point2DX         = np.append(point2DX,    np.zeros(currentLength, 'float32'))
                                point2DY         = np.append(point2DY,    np.zeros(currentLength, 'float32'))
                                currentLength = len(point1DValid)
                        allEvents = np.fromfile(fileHandle, point2DDataFormat, eventNumber)
                        allInfo = np.array(allEvents['info'])
                        point2DValid[point2DNumEvents : point2DNumEvents + eventNumber] \
                            = np.logical_and(allInfo, 0x1) # Pick off the first bit
                        point2DType[point2DNumEvents : point2DNumEvents + eventNumber] \
                            = (allInfo & 0xFE) >> 1 # Next 7 bits are the point1D event type
                        # point1D scale would go here - next 8 bits - no need at the present    
                        point2DX[point2DNumEvents : point2DNumEvents + eventNumber] \
                            = np.array(allEvents['x'])
                        point2DY[point2DNumEvents : point2DNumEvents + eventNumber] \
                            = np.array(allEvents['y'])
                        point2DTimeStamp[point2DNumEvents : point2DNumEvents + eventNumber] \
                            = packetTimeStampOffset + np.uint64(np.array(allEvents['timeStamp']))
                        mainTimeStamp = point2DTimeStamp[point2DNumEvents]
                        point2DNumEvents = point2DNumEvents + eventNumber
                        
                # Point3D
                elif eventType == 10:

                    if allDataTypes or 'point3D' in info['dataTypes']:
                        # First check if the array is big enough
                        currentLength = len(point3DValid)
                        if currentLength == 0:
                            point3DValid     = np.zeros(eventNumber, 'bool')
                            point3DTimeStamp = np.zeros(eventNumber, 'uint64')
                            point3DType      = np.zeros(eventNumber, 'uint8')
                            point3DX         = np.zeros(eventNumber, 'float32')
                            point3DY         = np.zeros(eventNumber, 'float32')
                            point3DZ         = np.zeros(eventNumber, 'float32')
                        else:
                            while eventNumber > currentLength - point1DNumEvents:
                                point3DValid     = np.append(point3DValid,     np.zeros(currentLength, 'bool'  ))
                                point3DTimeStamp = np.append(point3DTimeStamp, np.zeros(currentLength, 'uint64'))
                                point3DType      = np.append(point3DType,	      np.zeros(currentLength, 'uint8'))
                                point3DX         = np.append(point3DX,         np.zeros(currentLength, 'float32'))
                                point3DY         = np.append(point3DY,         np.zeros(currentLength, 'float32'))
                                point3DZ         = np.append(point3DZ,         np.zeros(currentLength, 'float32'))
                                currentLength = len(point1DValid)
                        allEvents = np.fromfile(fileHandle, point3DDataFormat, eventNumber)
                        allInfo = np.array(allEvents['info'])
                        point3DValid[point3DNumEvents : point3DNumEvents + eventNumber] \
                            = np.logical_and(allInfo, 0x1) # Pick off the first bit
                        point3DType[point3DNumEvents : point3DNumEvents + eventNumber] \
                            = (allInfo & 0xFE) >> 1 # Next 7 bits are the point1D event type
                        # point1D scale would go here - next 8 bits - no need at the present    
                        point3DX[point3DNumEvents : point3DNumEvents + eventNumber] \
                            = np.array(allEvents['x'])
                        point3DY[point3DNumEvents : point3DNumEvents + eventNumber] \
                            = np.array(allEvents['y'])
                        point3DZ[point3DNumEvents : point3DNumEvents + eventNumber] \
                            = np.array(allEvents['z'])                            
                        point3DTimeStamp[point3DNumEvents : point3DNumEvents + eventNumber] \
                            = packetTimeStampOffset + np.uint64(np.array(allEvents['timeStamp']))
                        mainTimeStamp = point3DTimeStamp[point3DNumEvents]
                        point3DNumEvents = point3DNumEvents + eventNumber

                else:
                    raise Exception('Unknown event type')
            
            if mainTimeStamp > endTime * 1e6 \
                    and mainTimeStamp != 0x7FFFFFFF: # This may be a timestamp reset - don't let it stop the import
                # Naively assume that the packets are all ordered correctly and finish
                break                            
        if packetCount == endPacket:
            break
                    
# Clip data arrays to correct size

    if not noData:

        outputData = {}
    
        if specialNumEvents > 0:
            special = {}
            special['valid']      = specialValid[0 : specialNumEvents] 
            special['timeStamp']  = specialTimeStamp[0 : specialNumEvents]
            special['address']    = specialAddress[0 : specialNumEvents]
            outputData['special'] = special
    
        if polarityNumEvents > 0:
            polarity = {}
            polarity['valid']       = polarityValid[0 : polarityNumEvents]
            polarity['timeStamp']   = polarityTimeStamp[0 : polarityNumEvents]
            polarity['y']           = polarityY[0 : polarityNumEvents]
            polarity['x']           = polarityX[0 : polarityNumEvents]
            polarity['polarity']    = polarityPolarity[0 : polarityNumEvents]
            outputData['polarity']  = polarity
    
        '''
        if frameNumEvents > 0
            keepLogical = false(size(frameValid, 1), 1);
            keepLogical(1:frameNumEvents) = true; 
            frame.valid = frameValid(keepLogical);
            frame.roiId					= frameRoiId(keepLogical);
            frame.colorChannels			= frameColorChannels(keepLogical);
            frame.colorFilter			= frameColorFilter(keepLogical);
            if simplifyFrameTimeStamps
                frame.timeStampStart	= frameTimeStampStart(keepLogical);
                frame.timeStampEnd		= frameTimeStampEnd(keepLogical);
            else
                frame.timeStampFrameStart	= frameTimeStampFrameStart(keepLogical);
                frame.timeStampFrameEnd		= frameTimeStampFrameEnd(keepLogical);
                frame.timeStampExposureStart = frameTimeStampExposureStart(keepLogical);
                frame.timeStampExposureEnd	= frameTimeStampExposureEnd(keepLogical);
            end
            frame.samples				= frameSamples(keepLogical);
            frame.xLength				= frameXLength(keepLogical);
            frame.yLength				= frameYLength(keepLogical);
            frame.xPosition				= frameXPosition(keepLogical);
            frame.yPosition				= frameYPosition(keepLogical);
            outputData.frame = frame;
        end
    
        if imu6NumEvents > 0
            keepLogical = false(size(imu6Valid, 1), 1);
            keepLogical(1:imu6NumEvents) = true; 
            imu6.valid = imu6Valid(keepLogical); 
            imu6.timeStamp	= imu6TimeStamp(keepLogical);
            imu6.gyroX		= imu6GyroX(keepLogical);
            imu6.gyroY		= imu6GyroY(keepLogical);
            imu6.gyroZ		= imu6GyroZ(keepLogical); 
            imu6.accelX		= imu6AccelX(keepLogical);
            imu6.accelY		= imu6AccelY(keepLogical);
            imu6.accelZ		= imu6AccelZ(keepLogical);
            imu6.temperature = imu6Temperature(keepLogical);
            outputData.imu6 = imu6;
        end
    
        if sampleNumEvents > 0
            keepLogical = false(size(sampleValid, 1), 1);
            keepLogical(1:sampleNumEvents) = true; 
            sample.valid = sampleValid(keepLogical); 
            sample.timeStamp	= sampleTimeStamp(keepLogical);
            sample.sampleType	= sampleSampleType(keepLogical);
            sample.sample		= sampleSample(keepLogical);
            outputData.sample = sample;
        end
    
        if earNumEvents > 0
            keepLogical = false(size(earValid, 1), 1);
            keepLogical(1:earNumEvents) = true; 
            ear.valid = earValid(keepLogical); 
            ear.timeStamp	= earTimeStamp(keepLogical);
            ear.position	= earosition(keepLogical);
            ear.channel		= earChannel(keepLogical);
            ear.neuron		= earNeuron(keepLogical);
            ear.filter		= earFilter(keepLogical);
            outputData.ear = ear;
        end
        '''
        if point1DNumEvents > 0:
            point1D = {}
            point1D['valid'] = point1DValid[0 : point1DNumEvents] 
            point1D['timeStamp'] = point1DTimeStamp[0 : point1DNumEvents]
            point1D['type'] = point1DType[0 : point1DNumEvents]
            point1D['x'] = point1DX[0 : point1DNumEvents]
            outputData['point1D'] = point1D
    
        if point2DNumEvents > 0:
            point2D = {}
            point2D['valid'] = point2DValid[0 : point2DNumEvents]
            point2D['timeStamp'] = point2DTimeStamp[0 : point2DNumEvents]
            point2D['type'] = point2DType[0 : point2DNumEvents]
            point2D['x'] = point2DX[0 : point2DNumEvents]
            point2D['y'] = point2DY[0 : point2DNumEvents]
            outputData['point2D'] = point2D
            
        if point3DNumEvents > 0:
            point3D = {}
            point3D['valid'] = point3DValid[0 : point3DNumEvents]
            point3D['timeStamp'] = point3DTimeStamp[0 : point3DNumEvents]
            point3D['type'] = point3DType[0 : point3DNumEvents]
            point3D['x'] = point3DX[0 : point3DNumEvents]
            point3D['y'] = point3DY[0 : point3DNumEvents]
            point3D['z'] = point3DZ[0 : point3DNumEvents]
            outputData['point3D'] = point3D

    # Pack packet info 
    info['packetTypes']     = packetTypes[0 : packetCount]
    info['packetPointers']  = packetPointers[0 : packetCount]
    info['packetTimeStamps'] = packetTimeStamps[0 : packetCount]
    
    # Calculate data volume by type
    
    # This calculation excludes the final packet for simplicity. 
    # It doesn't handle partial imports or invalid data.
    
    ''' LATER
    packetSizes = np.append(info['packetPointers'][1 : ] - info.packetPointers[0 : -1] - 28, 0)
    info['dataVolumeByEventType'] = {};
    eventTypesTemp = info.packetTypes;
    eventTypesTemp(eventTypesTemp == 32768) = 0;
    for eventType = max(eventTypesTemp): -1 : 0 % counting down means the array is only assigned once
    	info.dataVolumeByEventType(eventType + 1, 1 : 2) = [{EventTypes(eventType)} sum(packetSizes(info.packetTypes == eventType))];
    end
    '''
    # Pack the data into the output structure
    
    aedat['info'] = info
    try:
        aedat['data'] = outputData
    except NameError:
        pass
    # the unpacked importParams should not have been changed
    
    # Remove invalid events
    
    if validOnly and not noData:
    	pass # LATER aedat = RemoveInvalidEvents(aedat)
    
    # Add NumEvents field for each data type
    
    if not noData:
        aedat = NumEventsByType(aedat)
    
    # Find first and last time stamps      
    
    if not noData:
        aedat = FindFirstAndLastTimeStamps(aedat)

    return aedat






