% Convert a ROS bag cotaining event data recorded with the rpg_dvs_ros
% driver into aedat format, to open in jAER
%
% RPG DVS/DAVIS driver for ROS:
% https://github.com/uzh-rpg/rpg_dvs_ros
% Currently, the code assumes that the ROS data is published/stored in the
% dafault topic names: /dvs/events, /dvs/image_raw and /dvs/imu
%
% To read ROS bags, you need to have in the matlab path the library
% https://github.com/bcharrow/matlab_rosbag/releases
%
% AEDAT 2.0 format is explained in:
% https://inilabs.com/support/software/fileformat/#h.4ydb2xpu03ik
% Timestamps tick is 1 microsecond
%
% Input:
% -filename_rosbag: full name and path of the ROS bag (dataset) to read
%
% Output:
% -converted data is written into an file with the same name as input file,
% but with aedat extension.
% -aedat_struct: data structure used in AedatTools with information and
% content of the input dataset.
%
%
% Guillermo Gallego
% e-mail: guillermo.gallego@ifi.uzh.ch

function aedat = ConvertRosbagToAedat(filename_rosbag)

%% Import rosbag

aedat = struct;
aedat.importParams.filePath = filename_rosbag;
aedat = ImportRosbag(aedat);

%% Write output to aedat file

aedat.exportParams.filePath = [filename_rosbag(1:end-4) '.aedat'];
ExportAedat2(aedat);
