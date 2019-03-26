# -*- coding: utf-8 -*-

# Bodo Rueckhauser contributed the core of this code

"""
Import aedat version 1 or 2.
"""

import numpy as np
from PyAedatTools.FindFirstAndLastTimeStamps import FindFirstAndLastTimeStamps
from PyAedatTools.NumEventsByType import NumEventsByType

def ImportAedatDataVersion1or2(aedat):
    """
    Later ;)
    """

    # unpack    
    info = aedat['info']
    importParams = aedat['importParams']
    fileHandle = importParams['fileHandle']

    # The formatVersion dictates whether there are 6 or 8 bytes per event.
    if info['fileFormat'] == 1:
        numBytesPerEvent = 6
        addrPrecision = np.dtype([('addr', '>u2'), ('ts', '>u4')])
    else:
        numBytesPerEvent = 8
        addrPrecision = np.dtype([('addr', '>u4'), ('ts', '>u4')])

    # Find the number of events, assuming that the file position is just at the
    # end of the headers.
    fileHandle.seek(0, 2)
    info['numEventsInFile'] = int(np.floor(
        (fileHandle.tell() - info['beginningOfDataPointer']) /
        numBytesPerEvent))

    # Check the startEvent and endEvent parameters
    if 'startEvent' in importParams:
        startEvent = importParams['startEvent']
    else:
        startEvent = 0
    assert startEvent <= info['numEventsInFile']
    if 'endEvent' in importParams:
        endEvent = importParams['endEvent']
    else:
        endEvent = info['numEventsInFile']
    assert endEvent <= info['numEventsInFile']    
    if 'startPacket' in importParams:
        print("The startPacket parameter is set, but range by packets is not "
              "available for .aedat version < 3 files")
    if 'endPacket' in importParams:
        print("The endPacket parameter is set, but range by events is not "
              "available for .aedat version < 3 files")
    assert startEvent <= endEvent

    numEventsToRead = endEvent - startEvent + 1

    # Read events
    print 'Reading events ...'
    fileHandle.seek(info['beginningOfDataPointer'] + numBytesPerEvent *
                     startEvent)
    allEvents = np.fromfile(fileHandle, addrPrecision, numEventsToRead)

    allAddr = np.array(allEvents['addr'])
    allTs = np.array(allEvents['ts'])

    # Trim events outside time window.
    # This is an inefficent implementation, which allows for non-monotonic
    # timestamps.

    if 'startTime' in importParams:
        print 'Cropping events by time ...'
        tempIndex = np.nonzero(allTs >= importParams['startTime'] * 1e6)
        allAddr = allAddr[tempIndex]
        allTs = allTs[tempIndex]

    if 'endTime' in importParams:
        print 'Cropping events by time ...'
        tempIndex = np.nonzero(allTs <= importParams['endTime'] * 1e6)
        allAddr = allAddr[tempIndex]
        allTs = allTs[tempIndex]

    # Interpret the addresses
    
    """
    Split between DVS/DAVIS and DAS.
        For DAS1:
            - Special events - external injected events has never been
            implemented for DAS
            - Split between Address events and ADC samples
            - Intepret address events
            - Interpret ADC samples
        For DVS128:
            - Special events - external injected events are on bit 15 = 1 
            there is a more general label for special events which is bit 31 =
            1, but this has ambiguous interpretations  it is also overloaded
            for the stereo pair encoding - ignore this. 
            - Intepret address events
        For DAVIS:
            - Special events
                - Interpret IMU events from special events
            - Interpret DVS events according to chip class
            - Interpret APS events according to chip class
    """
    
    """
        # DAVIS. In the 32-bit address:
        # bit 32 (1-based) being 1 indicates an APS sample
        # bit 11 (1-based) being 1 indicates a special event
        # bits 11 and 32 (1-based) both being zero signals a polarity event
    """

    # Create a structure to put all the data in 
    outputData = {}

    if info['source'] == 'Das1':

        # To do: DAS
        pass
    
    elif info['source'] == 'Dvs128':
    
        # To do: Dvs128
        pass
    
    else: # DAVIS
    
        """ 
        In the 32-bit address:
        bit 32 (1-based) being 1 indicates an APS sample
        bit 11 (1-based) being 1 indicates a special event 
        bits 11 and 32 (1-based) both being zero signals a polarity event
        """

        print 'Building logical indices by type ...'        
        apsOrImuMask = int('80000000', 16)
        apsOrImuLogical = np.bitwise_and(allAddr, apsOrImuMask)
        apsOrImuLogical = apsOrImuLogical.astype(bool)
        signalOrSpecialMask = int('400', 16)
        signalOrSpecialLogical = np.bitwise_and(allAddr, signalOrSpecialMask)
        signalOrSpecialLogical = signalOrSpecialLogical.astype(bool)

        # These masks are used for both frames and polarity events, so are defined
        # outside of the following if statement
        yMask = int('7FC00000', 16)
        yShiftBits = 22
        xMask = int('003FF000', 16)
        xShiftBits = 12        
        polarityMask = int('00000800', 16)
        
        specialLogical = np.logical_and(signalOrSpecialLogical,
                                       np.logical_not(apsOrImuLogical))
    # Special events
        if ('dataTypes' not in importParams or 'special' in importParams['dataTypes']) \
                 and any(specialLogical):
            print 'Processing special events ...'
            outputData['special'] = {}
            outputData['special']['timeStamp'] = allTs[specialLogical] 
            # No need to create address field, since there is only one type of special event
        del specialLogical
    
        polarityLogical = np.logical_and(np.logical_not(apsOrImuLogical),
                                      np.logical_not(signalOrSpecialLogical))
        # Polarity(DVS) events
        if ('dataTypes' not in importParams or 'polarity' in importParams['dataTypes']) \
                and any(polarityLogical):
            print 'Processing polarity events ...'
            polarityData = allAddr[polarityLogical]         
            outputData['polarity'] = {}
            outputData['polarity']['timeStamp'] = allTs[polarityLogical]
            # Y addresses
            outputData['polarity']['y'] = np.array(np.right_shift( \
                np.bitwise_and(polarityData, yMask), yShiftBits), 'uint16')
            # X addresses
            outputData['polarity']['x'] = np.array(np.right_shift( \
                np.bitwise_and(polarityData, xMask), xShiftBits), 'uint16')
            # Polarity bit
            
            # Note: no need for a bitshift here, since its converted to boolean anyway
            outputData['polarity']['polarity'] = np.array( \
            np.bitwise_and(polarityData, polarityMask), 'bool')
            del polarityData
        del polarityLogical


        ImuOrPolarityMask = int('800', 16)
        ImuOrPolarityLogical = np.bitwise_and(allAddr, ImuOrPolarityMask)
        ImuOrPolarityLogical = ImuOrPolarityLogical.astype(bool)
        frameLogical = np.logical_and(apsOrImuLogical,
                                     np.logical_not(ImuOrPolarityLogical))
       # Frame events
        if ('dataTypes' not in importParams or 'frame' in importParams['dataTypes']) \
                and any(frameLogical):
            print 'Processing frames ...'
            frameSampleMask = int('1111111111', 2) 
            
            frameData = allAddr[frameLogical] 
            frameTs = allTs[frameLogical] 
    
            # Note: uses int16 instead of uint16 to allow for a subtraction operation below to look for discontinuities
            frameX = np.array(np.right_shift(np.bitwise_and(frameData, xMask), xShiftBits), 'int16') 
            frameY = np.array(np.right_shift(np.bitwise_and(frameData, yMask), yShiftBits), 'int16') 
            frameSample = np.array(np.bitwise_and(frameData, frameSampleMask), 'uint16') 
            # Note: no need for a bitshift here, since it's converted to boolean anyway
            frameSignal = np.array(np.bitwise_and(frameData, signalOrSpecialMask), 'bool') 
            
             # In general the ramp of address values could be in either
             # direction and either x or y could be the outer(inner) loop
             # Search for a discontinuity in both x and y simultaneously
            frameXDiscont = abs(frameX[1 : ] - frameX[0 : -1]) > 1 
            frameYDiscont = abs(frameY[1 : ] - frameY[0 : -1]) > 1
            frameDiscontIndex = np.where(np.logical_and(frameXDiscont, frameYDiscont))
            frameDiscontIndex = frameDiscontIndex[0] # The last line produces a tuple - we only want the array
            frameStarts = np.concatenate([[0], frameDiscontIndex  + 1, [frameData.size]])
             # Now we have the indices of the first sample in each frame, plus
             # an additional index just beyond the end of the array
            numFrames = frameStarts.size - 1 
            outputData['frame'] = {}
            outputData['frame']['reset']            = np.zeros(numFrames, 'bool') 
            outputData['frame']['timeStampStart']   = np.zeros(numFrames, 'uint32') 
            outputData['frame']['timeStampEnd']     = np.zeros(numFrames, 'uint32')
            outputData['frame']['samples']          = np.empty(numFrames, 'object') 
            outputData['frame']['xLength']          = np.zeros(numFrames, 'uint16') 
            outputData['frame']['yLength']          = np.zeros(numFrames, 'uint16') 
            outputData['frame']['xPosition']        = np.zeros(numFrames, 'uint16') 
            outputData['frame']['yPosition']        = np.zeros(numFrames, 'uint16') 
            
            for frameIndex in range(0, numFrames) :
                if frameIndex % 10 == 9:
                    print 'Processing frame ', frameIndex + 1, ' of ', numFrames
                # All within a frame should be either reset or signal. I could
                # implement a check here to see that that's true, but I haven't
                # done so; rather I just take the first value
                outputData['frame']['reset'][frameIndex] \
                    = not frameSignal[frameStarts[frameIndex]]  
                
                 # in aedat 2 format we don't have the four timestamps of aedat 3 format
                 # We expect to find all the same timestamps  
                 # nevertheless search for lowest and highest
                outputData['frame']['timeStampStart'][frameIndex] \
                    = min(frameTs[frameStarts[frameIndex] : frameStarts[frameIndex + 1]])  
                outputData['frame']['timeStampEnd'][frameIndex] \
                    = max(frameTs[frameStarts[frameIndex] : frameStarts[frameIndex + 1]])  
    
                tempXPosition = min(frameX[frameStarts[frameIndex] : frameStarts[frameIndex + 1]]) 
                outputData['frame']['xPosition'][frameIndex] = tempXPosition 
                tempYPosition = min(frameY[frameStarts[frameIndex] : frameStarts[frameIndex + 1]]) 
                outputData['frame']['yPosition'][frameIndex] = tempYPosition 
                outputData['frame']['xLength'][frameIndex] \
                    = max(frameX[frameStarts[frameIndex] : frameStarts[frameIndex + 1]]) \
                        - outputData['frame']['xPosition'][frameIndex] + 1 
                outputData['frame']['yLength'][frameIndex] \
                    = max(frameY[frameStarts[frameIndex] : frameStarts[frameIndex + 1]]) \
                        - outputData['frame']['yPosition'][frameIndex] + 1 
                # If we worked out which way the data is ramping in each
                # direction, and if we could exclude data loss, then we could
                # do some nice clean matrix transformations; but I'm just going
                # to iterate through the samples, putting them in the right
                # place in the array according to their address
                
                 # first create a temporary array - there is no concept of
                 # colour channels in aedat2
                
                # IN MATLAB IMPLEMENTATION, THIS FOLLOWING LOOP IS REPLACED BY ACCUMARRAY FUNCTION - Haven't figured out a good python equivalent yet                
                tempSamples = np.zeros((outputData['frame']['yLength'][frameIndex], \
                                    outputData['frame']['xLength'][frameIndex]), dtype='uint16') 
                for sampleIndex in range(frameStarts[frameIndex], frameStarts[frameIndex + 1]):
                    tempSamples[frameY[sampleIndex] \
                                    - outputData['frame']['yPosition'][frameIndex], \
                                frameX[sampleIndex] \
                                    - outputData['frame']['xPosition'][frameIndex]] \
                        = frameSample[sampleIndex] 

                outputData['frame']['samples'][frameIndex] = tempSamples 
    
            if (not ('subtractResetRead' in importParams) or importParams['subtractResetRead']) \
                    and 'reset' in outputData['frame']:
                # Make a second pass through the frames, subtracting reset
                # reads from signal reads
                frameCount = 0
                for frameIndex in range(0, numFrames):
                    if frameIndex % 10 == 9:
                        print 'Performing subtraction on frame ', frameIndex + 1, ' of ', numFrames
                    if outputData['frame']['reset'][frameIndex]: 
                        resetFrame = outputData['frame']['samples'][frameIndex] 
                        resetXPosition = outputData['frame']['xPosition'][frameIndex] 
                        resetYPosition = outputData['frame']['yPosition'][frameIndex] 
                        resetXLength = outputData['frame']['xLength'][frameIndex] 
                        resetYLength = outputData['frame']['yLength'][frameIndex]                     
                    else: 
                         # If a resetFrame has not yet been found, 
                         # push through the signal frame as is
                        if not 'resetFrame' in locals():
                            outputData['frame']['samples'][frameCount] \
                                = outputData['frame']['samples'][frameIndex] 
                        else:
                             # If the resetFrame and signalFrame are not the same size,    
                             # don't attempt subtraction 
                             # (there is probably a cleaner solution than this - could be improved)
                            if resetXPosition != outputData['frame']['xPosition'][frameIndex] \
                                or resetYPosition != outputData['frame']['yPosition'][frameIndex] \
                                or resetXLength != outputData['frame']['xLength'][frameIndex] \
                                or resetYLength != outputData['frame']['yLength'][frameIndex]:
                                outputData['frame']['samples'][frameCount] \
                                    = outputData['frame']['samples'][frameIndex] 
                            else:
                                 # Do the subtraction
                                outputData['frame']['samples'][frameCount] \
                                    = resetFrame - outputData['frame']['samples'][frameIndex] 
                                # This operation was on unsigned integers, set negatives to zero
                                outputData['frame']['samples'][frameCount][outputData['frame']['samples'][frameCount] > 32767] = 0
                             # Copy over the reset of the info
                            outputData['frame']['xPosition'][frameCount] \
                                = outputData['frame']['xPosition'][frameIndex] 
                            outputData['frame']['yPosition'][frameCount] \
                                = outputData['frame']['yPosition'][frameIndex] 
                            outputData['frame']['xLength'][frameCount] \
                                = outputData['frame']['xLength'][frameIndex] 
                            outputData['frame']['yLength'][frameCount] \
                                = outputData['frame']['yLength'][frameIndex] 
                            outputData['frame']['timeStampStart'][frameCount] \
                                = outputData['frame']['timeStampStart'][frameIndex]  
                            outputData['frame']['timeStampEnd'][frameCount] \
                                = outputData['frame']['timeStampEnd'][frameIndex]                              
                            frameCount = frameCount + 1
                 # Clip the arrays
                outputData['frame']['xPosition'] \
                    = outputData['frame']['xPosition'][0 : frameCount] 
                outputData['frame']['yPosition'] \
                    = outputData['frame']['yPosition'][0 : frameCount] 
                outputData['frame']['xLength'] \
                    = outputData['frame']['xLength'][0 : frameCount] 
                outputData['frame']['yLength'] \
                    = outputData['frame']['yLength'][0 : frameCount] 
                outputData['frame']['timeStampStart'] \
                    = outputData['frame']['timeStampStart'][0 : frameCount] 
                outputData['frame']['timeStampEnd'] \
                    = outputData['frame']['timeStampEnd'][0 : frameCount] 
                outputData['frame']['samples'] \
                    = outputData['frame']['samples'][0 : frameCount]
                del outputData['frame']['reset']   # reset is no longer needed
        del frameLogical
    
    
        # IMU events
        # These come in blocks of 7, for the 7 different values produced in
        # a single sample; the following code recomposes these
        # 7 words are sent in series, these being 3 axes for accel, temperature, and 3 axes for gyro

        imuLogical = np.logical_and(apsOrImuLogical, ImuOrPolarityLogical)
        if ('dataTypes' not in importParams or 'imu6' in importParams['dataTypes']) \
                and any(imuLogical):
            print 'Processing IMU6 events ...'
            outputData['imu6'] = {}
            outputData['imu6']['timeStamp'] = allTs[imuLogical]

            if np.mod(np.count_nonzero(imuLogical), 7) > 0: 
                print 'The number of IMU samples is not divisible by 7, so IMU samples are not interpretable'
            else:
                outputData['imu6']['timeStamp'] = allTs[imuLogical]
                outputData['imu6']['timeStamp'] \
                    = outputData['imu6']['timeStamp'][0 : : 7]
    
            # Conversion factors
            # Actually these scales depend on the fiull scale value 
            # with which the IMU is configured.
            # Here I assume jaer defaults: 1000 deg/s for gyro and 8 g for accel
            # Given 16 bit samples, this results in the following:
            accelScale = 1.0/8192 # This gives acceleration in g
            gyroScale = 1.0/65.535 # This gives angular velocity in deg/s
            temperatureScale = 1.0/340
            temperatureOffset=35.0
    
            imuDataMask = int('0FFFF000', 16)
            imuDataShiftBits = 12
            rawData = np.right_shift(np.bitwise_and(allAddr[imuLogical], imuDataMask), imuDataShiftBits)
            # This is a uint32 which contains an int16. Need to convert to int16 before converting to float.             
            rawData = rawData.astype('int16')
            rawData = rawData.astype('float32')
                        
            outputData['imu6']['accelX']        = rawData[0 : : 7] * accelScale    
            outputData['imu6']['accelY']        = rawData[1 : : 7] * accelScale    
            outputData['imu6']['accelZ']        = rawData[2 : : 7] * accelScale    
            outputData['imu6']['temperature']   = rawData[3 : : 7] * temperatureScale + temperatureOffset   
            outputData['imu6']['gyroX']         = rawData[4 : : 7] * gyroScale  
            outputData['imu6']['gyroY']         = rawData[5 : : 7] * gyroScale
            outputData['imu6']['gyroZ']         = rawData[6 : : 7] * gyroScale
        del imuLogical

    # If you want to do chip-specific address shifts or subtractions,
    # this would be the place to do it.

    # calculate numEvents fields  also find first and last timeStamps
    info['firstTimeStamp'] = np.infty
    info['lastTimeStamp'] = 0

    aedat['info'] = info
    aedat['data'] = outputData

    # Find first and last time stamps        
    aedat = FindFirstAndLastTimeStamps(aedat)
    
    # Add NumEvents field for each data type
    aedat = NumEventsByType(aedat)
       
    return aedat
