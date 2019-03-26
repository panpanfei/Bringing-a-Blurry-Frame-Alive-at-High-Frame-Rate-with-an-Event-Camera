% Imports a ROS bag cotaining event data recorded with the rpg_dvs_ros
% driver into the same workspace structure as ImportAedat uses. 
%
% Code taken from ConvertRosbagToAedat, written by Guillermo Gallego
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
% aedat struct, containing at least field 'importParams', 
% containing at least field 'filePath': full name and path of the ROS bag (dataset) to read
%
% Output:
% aedat: data structure used in AedatTools with information and
% content of the input dataset.
%
% Guillermo Gallego
% e-mail: guillermo.gallego@ifi.uzh.ch

function aedat = ImportRosbag(aedat)

if ~isfield(aedat, 'importParams') || ~isfield(aedat.importParams, 'filePath')
    error('No filename')
end

% Load a bag and get information about it
bag = ros.Bag.load(aedat.importParams.filePath);
bag.info()

% Start to fill in aedat structure, for conversion
aedat.data = [];

%% Default ROS topics with the published data
topic_events = '/dvs/events';
topic_images = '/dvs/image_raw';
topic_imu = '/dvs/imu';

%% Get first timestamp of the bag so that it is subtracted from all timestamps
% and hence the 32 bits of the timestamps are better used
bag.resetView({topic_events, topic_images, topic_imu});
msg = bag.read();
% IMU or image messages have the timestamp in the header
% Event messages have header timestamp empty
if isfield(msg, 'events')
    % first message is a packet of events
    time_first_sec_uint32 = uint32( msg.events(3,1) );
else
    % first message is image or IMU
    time_first_sec_uint32 = msg.header.stamp.sec;
end

margin = 10; % some margin. Maybe some events happen before this time
if time_first_sec_uint32 > margin
    time_first_sec_uint32 = time_first_sec_uint32 - margin;
end
bag.resetView({topic_events, topic_images, topic_imu});


%% Frames (i.e., images)
disp('Reading image topic from ROS bag');
msgs = bag.readAll(topic_images);
num_msgs = length(msgs);
disp(['Found ' num2str(num_msgs) ' frames']);
if (num_msgs > 0)
    aedat.data.frame = []; % create images struct
    aedat.data.frame.numEvents = num_msgs; % number of frames
    disp('Converting APS-frame messages...');
    img_width = double(msgs{1}.width);
    img_height = double(msgs{1}.height);
    v_zero = zeros(num_msgs,1);
    v_one = ones(num_msgs,1);
    aedat.data.frame.xPosition = uint16(v_zero);
    aedat.data.frame.yPosition = uint16(v_zero);
    aedat.data.frame.xLength = uint16(img_width * v_one); % 240
    aedat.data.frame.yLength = uint16(img_height* v_one); % 180
    for ii = 1:num_msgs
        % timestamp: remove offset, convert to microseconds and cast to uint32
        time_us = double(msgs{ii}.header.stamp.sec - time_first_sec_uint32) * 1e6 ...
            + double(msgs{ii}.header.stamp.nsec) / 1e3; % microseconds
        aedat.data.frame.timeStampStart(ii) = uint32(time_us);
        aedat.data.frame.timeStampEnd(ii) = uint32(time_us);
        
        img = reshape(msgs{ii}.data,img_width,img_height)';
        img = double(img) * 4; % convert from 8 bits to 10 bits: [0,255] to [0,1023]
        img = flipud(img);
        if (img_width == 346)
            % miniDAVIS346 needs to flip left-right events and frames
            img = fliplr(img);
        end
        aedat.data.frame.samples{ii,1} = img; % cell array with the grayscale values
    end
    % column vectors
    aedat.data.frame.timeStampStart = aedat.data.frame.timeStampStart';
    aedat.data.frame.timeStampEnd = aedat.data.frame.timeStampEnd';
    disp('...done!');
end


%% IMU
disp('Reading IMU topic from ROS bag');
msgs = bag.readAll(topic_imu);
num_msgs = length(msgs);
disp(['Found ' num2str(num_msgs) ' IMU samples']);
if (num_msgs > 0)
    aedat.data.imu6 = []; % create IMU struct
    aedat.data.imu6.numEvents = num_msgs; % number of measurements
    disp('Converting IMU messages...');
    % Column vectors
    v_zero = zeros(num_msgs,1);
    aedat.data.imu6.timeStamp = uint32(v_zero);
    aedat.data.imu6.accelX = v_zero;
    aedat.data.imu6.accelY = v_zero;
    aedat.data.imu6.accelZ = v_zero;
    aedat.data.imu6.gyroX = v_zero;
    aedat.data.imu6.gyroY = v_zero;
    aedat.data.imu6.gyroZ = v_zero;
    aedat.data.imu6.temperature = 28 + v_zero; % centigrades
    for ii = 1:num_msgs
        % timestamp: remove offset, convert to microseconds and cast to uint32
        time_us = double(msgs{ii}.header.stamp.sec - time_first_sec_uint32) * 1e6 ...
            + double(msgs{ii}.header.stamp.nsec) / 1e3; % microseconds
        aedat.data.imu6.timeStamp(ii) = uint32(time_us);
        
        aedat.data.imu6.accelX(ii) = msgs{ii}.linear_acceleration(1);
        aedat.data.imu6.accelY(ii) = msgs{ii}.linear_acceleration(2);
        aedat.data.imu6.accelZ(ii) = msgs{ii}.linear_acceleration(3);
        aedat.data.imu6.gyroX(ii) = msgs{ii}.angular_velocity(1);
        aedat.data.imu6.gyroY(ii) = msgs{ii}.angular_velocity(2);
        aedat.data.imu6.gyroZ(ii) = msgs{ii}.angular_velocity(3);
        % aedat.data.imu6.temperature(ii) = 0;
    end
    
    % Conversion of units.
    % Acceleration is imported as m/s^2, and aedat wants it in multiples of g
    gravity = 9.8; % m/s^2
    aedat.data.imu6.accelX = aedat.data.imu6.accelX / gravity;
    aedat.data.imu6.accelY = aedat.data.imu6.accelY / gravity;
    aedat.data.imu6.accelZ = aedat.data.imu6.accelZ / gravity;
    % Angular velocity is imported as rad/s, and aedat expects deg/s
    rad_in_deg = 180 / pi; % degrees in one radian
    aedat.data.imu6.gyroX = aedat.data.imu6.gyroX * rad_in_deg;
    aedat.data.imu6.gyroY = aedat.data.imu6.gyroY * rad_in_deg;
    aedat.data.imu6.gyroZ = aedat.data.imu6.gyroZ * rad_in_deg;
    
    disp('...done!');
end


%% Events
disp('Reading event topic from ROS bag');
msgs = bag.readAll(topic_events);
num_msgs = length(msgs);
disp(['Found ' num2str(num_msgs) ' event messages']);
if (num_msgs > 0)
    aedat.data.polarity = []; % create events struct
    disp('Converting event messages...');
    
    % Get size of the event sensor
    ev_sensor_width = double(msgs{1}.width);
    ev_sensor_height = double(msgs{1}.height);
    
    % Compute number of events
    numEvents = 0;
    for ii = 1:num_msgs
        numEvents = numEvents + size(msgs{ii}.events,2);
    end
    disp(['Number of events = ' num2str(numEvents)]);
    aedat.data.polarity.numEvents = numEvents;
    
    % Allocate memory for all events. Read events
    idx_firt_ev_msg = 1;
    for ii = 1:num_msgs
        if mod(ii,100) == 0
            disp(['Message ' num2str(ii) ' of ' num2str(num_msgs)]);
        end
        num_ev_msg = size(msgs{ii}.events,2);
        idx = idx_firt_ev_msg + (0:num_ev_msg-1)';
        idx_firt_ev_msg = idx_firt_ev_msg + num_ev_msg;
        
        % Read (x, y, t, polarity) of the events
        
        % timestamp: remove offset, convert to microseconds and cast to uint32
        time_us = (msgs{ii}.events(3,:) - double(time_first_sec_uint32)) * 1e6; % microseconds
        aedat.data.polarity.timeStamp(idx) = uint32(time_us);
        
        if (ev_sensor_width == 128) || (ev_sensor_width == 346)
            % DVS and miniDAVIS346 need to flip events. Don't ask why
            aedat.data.polarity.x(idx) = uint16(ev_sensor_width-1 -msgs{ii}.events(1,:));
        else
            aedat.data.polarity.x(idx) = uint16(msgs{ii}.events(1,:));
        end
        aedat.data.polarity.y(idx) = uint16(ev_sensor_height-1 -msgs{ii}.events(2,:));
        aedat.data.polarity.polarity(idx) = logical(msgs{ii}.events(4,:));
    end
    % column vectors
    aedat.data.polarity.timeStamp = aedat.data.polarity.timeStamp';
    aedat.data.polarity.x = aedat.data.polarity.x';
    aedat.data.polarity.y = aedat.data.polarity.y';
    aedat.data.polarity.polarity = aedat.data.polarity.polarity';
    disp('...done!');
end


%% Fill in additional information for aedat file
aedat.info = [];

% Set sensor size
if exist('ev_sensor_width','var') && exist('ev_sensor_height','var')
    % Get the sensor size from the event topic
    aedat.info.deviceAddressSpace = [ev_sensor_width, ev_sensor_height];
elseif exist('img_width','var') && exist('img_height','var')
    % Get the sensor size from the image topic
    aedat.info.deviceAddressSpace = [img_width, img_height];
else
    error('Could not determine the sensor size from the events or images');
end

% Set the type of sensor used, according to resolution
% See file BasicSourceName.m
sensor_size = aedat.info.deviceAddressSpace;
if (sensor_size(1) == 240) && (sensor_size(2) == 180)
    aedat.info.source = 'Davis240C';
elseif (sensor_size(1) == 346) && (sensor_size(2) == 260)
    aedat.info.source = 'Davis346BMono';
elseif (sensor_size(1) == 128) && (sensor_size(2) == 128)
    aedat.info.source = 'Dvs128';
else
    error(['Unknown sensor type for resolution: ' ...
        num2str(sensor_size(1)) ' x ' num2str(sensor_size(2)) ' pixels']);
end

% Fill in standard info
aedat = NumEventsByType(aedat);
aedat = FindFirstAndLastTimeStamps(aedat);

