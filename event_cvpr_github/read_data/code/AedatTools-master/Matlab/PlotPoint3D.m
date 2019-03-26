function PlotPoint3D(aedat)

%{

Takes 'aedat' - a data structure containing an imported .aedat file, 
as created by ImportAedat, and creates plots of point3D events. 
There are 4x 3d plots: 
    - timeStamp vs x vs y 
    - timeStamp vs y vs z;
    - timeStamp vs x vs z;
    - x vs y vs z;

TO DO: use colour to express event Type
%}

timeStamp = double(aedat.data.point3D.timeStamp)' / 1e6;
x = (aedat.data.point3D.x)';
y = (aedat.data.point3D.y)';
z = (aedat.data.point3D.z)';

figure
set(gcf,'numbertitle','off','name','Point2D')
%timeStamp vs value 1
subplot(2, 2, 1)
plot3(timeStamp, x, y, '-o')
xlabel('Time (s)')
ylabel('X')
zlabel('Y')

%timeStamp vs value 2
subplot(2, 2, 2)
plot3(timeStamp, y, z, '-o')
xlabel('Time (s)')
ylabel('Y')
zlabel('Z')

%timeStamp vs value 2
subplot(2, 2, 3)
plot3(timeStamp, x, z, '-o')
xlabel('Time (s)')
ylabel('X')
zlabel('Z')

subplot(2, 2, 4)
plot3(x, y, z, '-o')
xlabel('X')
ylabel('Y')
zlabel('Z')
	


