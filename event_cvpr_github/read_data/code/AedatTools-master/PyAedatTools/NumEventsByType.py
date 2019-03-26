def NumEventsByType(aedat):

    '''
    For each data type in aedat['data'], fill in the numEvents field.
    If there are no events, remove the data type field. 
    '''
    
    if 'special' in aedat['data']:
    	aedat['data']['special']['numEvents'] = len(aedat['data']['special']['timeStamp'])
        if aedat['data']['special']['numEvents'] == 0:
            del aedat['data']['special']
    if 'polarity' in aedat['data']:
    	aedat['data']['polarity']['numEvents'] = len(aedat['data']['polarity']['timeStamp'])
        if aedat['data']['polarity']['numEvents'] == 0:
            del aedat['data']['polarity']
    if 'frame' in aedat['data']:
    	aedat['data']['frame']['numEvents'] = len(aedat['data']['frame']['samples']) # Don't use timeStamp fields because of the possible ambiguity
        if aedat['data']['frame']['numEvents'] == 0:
            del aedat['data']['frame']
    if 'imu6' in aedat['data']:
    	aedat['data']['imu6']['numEvents'] = len(aedat['data']['imu6']['timeStamp'])
        if aedat['data']['imu6']['numEvents'] == 0:
            del aedat['data']['imu6']
    if 'sample' in aedat['data']:
    	aedat['data']['sample']['numEvents'] = len(aedat['data']['sample']['timeStamp'])
        if aedat['data']['sample']['numEvents'] == 0:
            del aedat['data']['sample']
    if 'ear' in aedat['data']:
    	aedat['data']['ear']['numEvents'] = len(aedat['data']['ear']['timeStamp'])
        if aedat['data']['ear']['numEvents'] == 0:
            del aedat['data']['ear']
    if 'point1D' in aedat['data']:
    	aedat['data']['point1D']['numEvents'] = len(aedat['data']['point1D']['timeStamp'])
        if aedat['data']['point1D']['numEvents'] == 0:
            del aedat['data']['point1D']
    if 'point2D' in aedat['data']:
    	aedat['data']['point2D']['numEvents'] = len(aedat['data']['point2D']['timeStamp'])
        if aedat['data']['point2D']['numEvents'] == 0:
            del aedat['data']['point2D']

    return aedat