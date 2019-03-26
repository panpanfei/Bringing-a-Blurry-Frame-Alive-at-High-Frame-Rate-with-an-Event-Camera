# -*- coding: utf-8 -*-

# Henri Rebecq contributed the core of this code

import sys
sys.path.append('/usr/local/lib/python2.7/site-packages')
sys.path.append('/opt/ros/kinetic/lib')
sys.path.append('/opt/ros/kinetic/lib/python2.7/dist-packages')
sys.path.append('/home/sim/catkin_ws/devel/lib/python2.7/dist-packages')
import os
import numpy as np
#import cv2
import rosbag
from dvs_msgs.msg import Event, EventArray
#from sensor_msgs.msg import CameraInfo
#from sensor_msgs.msg import Image
from sensor_msgs.msg import Imu
from geometry_msgs.msg import Vector3
from cv_bridge import CvBridge #, CvBridgeError
import rospy

def ExportRosbag(aedat):
    
    # bag file name and path will be the same as origin .aedat file, unless overruled
    bagFilePath = os.path.splitext(aedat['exportParams']['filePath'])[0] + '.bag'
    
    # Open bag
    bag = rosbag.Bag(bagFilePath, 'w')

#%% Frames

    if 'frame' in aedat['data'] \
        and ('dataTypes' not in aedat['info'] or 'frame' in aedat['info']['dataTypes']): 
        bridge = CvBridge()
        for frameIndex in range(0, aedat['data']['frame']['numEvents']):
            if frameIndex % 10 == 9:
                print 'Writing img message', frameIndex + 1, 'of', aedat['data']['frame']['numEvents'], ' ...'
            img = aedat['data']['frame']['samples'][frameIndex]
            # The sample is really 10 bits, but held in a uint16; 
            # convert to uint8, dropping the least significant 2 bits
            img = np.right_shift(img, 2)
            img = img.astype('uint8')
    
            # To do: make compatible with aedat3 imports, with different timestamp fields
            timeStamp = rospy.Time(secs=aedat['data']['frame']['timeStampStart'][frameIndex]/1000000.0)
            img_msg = bridge.cv2_to_imgmsg(img, 'mono8')
            img_msg.header.stamp = timeStamp
            bag.write(topic='/dvs/image_raw', msg=img_msg, t=timeStamp)
    
#%% Polarity
    
    # Put several events into an array in a single ros message, for efficiency     
    
    if 'polarity' in aedat['data'] \
        and ('dataTypes' not in aedat['info'] or 'polarity' in aedat['info']['dataTypes']): 
        countMsgs = 0
        numEventsPerArray = 25000 # Could be a parameter
        numEvents = aedat['data']['polarity']['numEvents']
        numArrays = - (- numEvents / numEventsPerArray) # The subtraction allows rounding up
    
        # Construct the event array object - a definition from rpg_dvs_ros
        # Use this repeatedly for each message        
        eventArrayObject = EventArray()
        # The following properties don't change
        eventArrayObject.width = 240 # HARDCODED CONSTANT - RESOLVE ON A RAINY DAY
        eventArrayObject.height = 180 # HARDCODED CONSTANT - RESOLVE ON A RAINY DAY
        # Use the following object array repeatedly to construct the contents 
        # of each ros message
        eventArray = np.empty(-(-numEventsPerArray), 'object')
        # Outer loop over arrays or ros messages
        for startPointer in range(0, numEvents, numEventsPerArray):         
            countMsgs = countMsgs + 1        
            print 'Writing event array message', countMsgs, 'of', numArrays, ' ...'
            endPointer = min(startPointer + numEventsPerArray, numEvents)            
            # Break the data vectors out of the dict for efficiency, 
            # but do this message by message to avoid memory problems
            arrayX        = aedat['data']['polarity']['x'][startPointer : endPointer] 
            arrayY        = aedat['data']['polarity']['y'][startPointer : endPointer] 
            arrayPolarity = aedat['data']['polarity']['polarity'][startPointer : endPointer]
            # Convert timestamps to seconds (ros, however, stores timestamps to ns precision)            
            arrayTimeStamp = aedat['data']['polarity']['timeStamp'][startPointer : endPointer]/1000000.0 

            # Iterate through all the events in the intended event array
            for eventIndex in range (0, endPointer - startPointer):
                # The Event object definition comes from rpg_dvs_ros
                e = Event()
                e.x = 239 - arrayX[eventIndex] # Flip X - I don't know why this is necessary
                e.y = arrayY[eventIndex]
                e.ts = rospy.Time(arrayTimeStamp[eventIndex])
                e.polarity = arrayPolarity[eventIndex]
                eventArray[eventIndex] = e;
            # The last array may be smaller than numEventsPerArray, so clip the object array
            if endPointer == numEvents:
                eventArray = eventArray[0 : endPointer - startPointer]
            # Assume that the ros message is sent at the time of the last event in the message
            eventArrayObject.header.stamp = e.ts
            eventArrayObject.events = eventArray
            bag.write(topic='/dvs/events', msg=eventArrayObject, t=e.ts)
            
    #%% IMU6
    
    # Put several events into an array in a single ros message, for efficiency     
    if 'imu6' in aedat['data'] \
        and ('dataTypes' not in aedat['info'] or 'imu6' in aedat['info']['dataTypes']): 
        # Break the IMU events out of the dict, for efficiency
        # Accel is imported as g; we want m/s^2
        arrayAccelX = aedat['data']['imu6']['accelX'] * 9.8
        arrayAccelY = aedat['data']['imu6']['accelY'] * 9.8
        arrayAccelZ = aedat['data']['imu6']['accelZ'] * 9.8
        # Angular velocity is imported as deg/s; we want rad/s
        arrayGyroX = aedat['data']['imu6']['gyroX'] * 0.01745
        arrayGyroY = aedat['data']['imu6']['gyroY'] * 0.01745
        arrayGyroZ = aedat['data']['imu6']['gyroZ'] * 0.01745
            # Convert timestamps to seconds (ros, however, stores timestamps to ns precision)            
        arrayTimeStamp = aedat['data']['imu6']['timeStamp']/1000000.0 
        numEvents = aedat['data']['imu6']['numEvents']
        # Use the following containers repeatedly during the export
        imuMsg = Imu()
        accel = Vector3()
        gyro = Vector3()
        # I guess these assignments only need to be made once
        imuMsg.linear_acceleration = accel
        imuMsg.angular_velocity = gyro
        for eventIndex in range(0, numEvents):         
            imuMsg.header.stamp = rospy.Time(arrayTimeStamp[eventIndex])            
            accel.x = arrayAccelX[eventIndex]
            accel.y = arrayAccelY[eventIndex]
            accel.z = arrayAccelZ[eventIndex]
            gyro.x = arrayGyroX[eventIndex]
            gyro.y = arrayGyroY[eventIndex]
            gyro.z = arrayGyroZ[eventIndex]
            bag.write(topic='/dvs/imu', msg=imuMsg, t=imuMsg.header.stamp)
    bag.close()

