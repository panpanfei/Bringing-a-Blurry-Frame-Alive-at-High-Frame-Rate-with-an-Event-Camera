
import numpy as np

def FindFirstAndLastTimeStamps(aedat):
    '''
    This is a sub-function of importAedat. 
    For each field in aedat['data'], it finds the first and last timestamp. 
    The min and max of these respectively are put into aedat.info
    '''
    
    # Clip arrays to correct size and add them to the output structure.
    # Also find first and last timeStamps
    
    if not 'data' in aedat:
        print 'No data found from which to extract time stamps'
        return aedat
    
    firstTimeStamp = np.inf
    lastTimeStamp = 0
    
    if 'special' in aedat['data']:
    	if aedat['data']['special']['timeStamp'][0] < firstTimeStamp:
    		firstTimeStamp = aedat['data']['special.timeStamp'][0]
    	if aedat['data']['special']['timeStamp'][-1] > lastTimeStamp:
    		lastTimeStamp = aedat['data']['special']['timeStamp'][-1]
    
    if 'polarity' in aedat['data']:
    	if aedat['data']['polarity']['timeStamp'][0] < firstTimeStamp:
    		firstTimeStamp = aedat['data']['polarity']['timeStamp'][0]
    	if aedat['data']['polarity']['timeStamp'][-1] > lastTimeStamp:
    		lastTimeStamp = aedat['data']['polarity']['timeStamp'][-1]
    
    if 'frame' in aedat['data']:    
        if 'timeStampExposureStart' in aedat['data']['frame']:
            if aedat['data']['frame']['timeStampExposureStart'][0] < firstTimeStamp:
                firstTimeStamp = aedat['data']['frame']['timeStampExposureStart'][0]
            if aedat['data']['frame']['timeStampExposureEnd'][-1] > lastTimeStamp:
                lastTimeStamp = aedat['data']['frame']['timeStampExposureEnd'][-1]
        else:
            if aedat['data']['frame']['timeStampStart'][0] < firstTimeStamp:
                firstTimeStamp = aedat['data']['frame']['timeStampStart'][0]
            if aedat['data']['frame']['timeStampEnd'][-1] > lastTimeStamp:
                lastTimeStamp = aedat['data']['frame']['timeStampEnd'][-1]
    
    if 'imu6' in aedat['data']:
    	if aedat['data']['imu6']['timeStamp'][0] < firstTimeStamp:
    		firstTimeStamp = aedat['data']['imu6']['timeStamp'][0]
    	if aedat['data']['imu6']['timeStamp'][-1] > lastTimeStamp:
    		lastTimeStamp = aedat['data']['imu6']['timeStamp'][-1]
    
    if 'sample' in aedat['data']:
    	if aedat['data']['sample']['timeStamp'][0] < firstTimeStamp:
    		firstTimeStamp = aedat['data']['sample']['timeStamp'][0]
    	if aedat['data']['sample']['timeStamp'][-1] > lastTimeStamp:
    		lastTimeStamp = aedat['data']['sample']['timeStamp'][-1]
    
    if 'ear' in aedat['data']:
    	if aedat['data']['ear']['timeStamp'][0] < firstTimeStamp:
    		firstTimeStamp = aedat['data']['ear']['timeStamp'][0]
    	if aedat['data']['ear']['timeStamp'][-1] > lastTimeStamp:
    		lastTimeStamp = aedat['data']['ear']['timeStamp'][-1]
    
    if 'point1D' in aedat['data']:
    	if aedat['data']['point1D']['timeStamp'][0] < firstTimeStamp:
    		firstTimeStamp = aedat['data']['point1D']['timeStamp'][0]
    	if aedat['data']['point1D']['timeStamp'][-1] > lastTimeStamp:
    		lastTimeStamp = aedat['data']['point1D']['timeStamp'][-1]
    
    if 'point2D' in aedat['data']:
    	if aedat['data']['point2D']['timeStamp'][0] < firstTimeStamp:
    		firstTimeStamp = aedat['data']['point2D']['timeStamp'][0]
    	if aedat['data']['point2D']['timeStamp'][-1] > lastTimeStamp:
    		lastTimeStamp = aedat['data']['point2D']['timeStamp'][-1]

    if 'point3D' in aedat['data']:
    	if aedat['data']['point3D']['timeStamp'][0] < firstTimeStamp:
    		firstTimeStamp = aedat['data']['point3D']['timeStamp'][0]
    	if aedat['data']['point3D']['timeStamp'][-1] > lastTimeStamp:
    		lastTimeStamp = aedat['data']['point3D']['timeStamp'][-1]

    if 'point4D' in aedat['data']:
    	if aedat['data']['point4D']['timeStamp'][0] < firstTimeStamp:
    		firstTimeStamp = aedat['data']['point4D']['timeStamp'][0]
    	if aedat['data']['point4D']['timeStamp'][-1] > lastTimeStamp:
    		lastTimeStamp = aedat['data']['point4D']['timeStamp'][-1]
    
    aedat['info']['firstTimeStamp'] = firstTimeStamp
    aedat['info']['lastTimeStamp'] = lastTimeStamp

    return aedat
