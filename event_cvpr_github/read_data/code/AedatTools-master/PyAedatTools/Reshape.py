# -*- coding: utf-8 -*-
"""
Takes a dict such as created from ImportAedat and returns the same with the events
having been squashed or stretched into the new dinmensions given as parameters 
newX newY
Polarity events only, to start with
"""
import numpy as np

def Reshape(aedat, newX, newY):
    # ... actually just crop for now
    inXLogical = aedat['data']['polarity']['x'] < newX
    inYLogical = aedat['data']['polarity']['y'] < newY
    inLogical = np.bitwise_and(inXlogical, inYLogical)
    aedat['data']['polarity']['x']          = aedat['data']['polarity']['x'][inLogical]
    aedat['data']['polarity']['y']          = aedat['data']['polarity']['y'][inLogical]
    aedat['data']['polarity']['polarity']   = aedat['data']['polarity']['polarity'][inLogical]
    aedat['data']['polarity']['timeStamp']  = aedat['data']['polarity']['timeStamp'][inLogical]
    aedat['data']['polarity']['numEvents']  = len(aedat['data']['polarity']['x'])
    #reset needs handling
    
    return aedat
