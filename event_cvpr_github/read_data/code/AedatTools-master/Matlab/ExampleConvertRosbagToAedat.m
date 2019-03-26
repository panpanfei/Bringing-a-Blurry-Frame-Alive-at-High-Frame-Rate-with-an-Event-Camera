% Example: convert a ROS bag with events, images and IMU data to aedat file
clear, clc, close ALL

% Library used for reading ROS bags
% Can be downloaded from https://github.com/bcharrow/matlab_rosbag/releases
addpath(genpath('/home/ggb/MATLAB/matlab_rosbag-0.5.0-linux64'));

% Convert file, from ROS to aedat 2.0
filename_rosbag = '/home/ggb/AedatTools/test/test_davis240c.bag';
aedat_struct = ConvertRosbagToAedat(filename_rosbag);
