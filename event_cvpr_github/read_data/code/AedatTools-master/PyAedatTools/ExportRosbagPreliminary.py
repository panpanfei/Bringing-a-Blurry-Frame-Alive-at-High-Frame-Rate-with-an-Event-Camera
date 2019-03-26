# -*- coding: utf-8 -*-

# The ros kinetic lib is needed for the export to rosbag; 
# this script makes sure it's on the LD_LIBRARY_PATH as seen within Python 
# However the re-exec may cause unspecified problems, 
# so it's better to do it the very first thing, hence the separate script.

import sys
import os
if 'LD_LIBRARY_PATH' not in os.environ:
    os.environ['LD_LIBRARY_PATH'] = '/opt/ros/kinetic/lib'
    try:
        os.execv(sys.argv[0], sys.argv)
    except Exception, exc:
        print 'Failed re-exec:', exc
        sys.exit(1)

