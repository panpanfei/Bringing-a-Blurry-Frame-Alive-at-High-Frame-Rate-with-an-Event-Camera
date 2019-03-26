function PlotPoint2D(aedat)

%{

Takes 'aedat' - a data structure containing an imported .aedat file, 
as created by ImportAedat, and creates plots of point2D events. There are 3
x 2d plots: timeStamp vs x, timeStamp vs y and x vs y;
then there is a 3D plot with timeStamp vs x vs y

TO DO: use colour to express event Type
%}

timeStamps = double(aedat.data.point2D.timeStamp)' / 1000000;
x = (aedat.data.point2D.x)';
y = (aedat.data.point2D.y)';

figure
set(gcf,'numbertitle','off','name','Point2D')
%timeStamp vs x
subplot(2, 2, 1)
plot(timeStamps, x, '-o')
xlabel('Time (s)')
ylabel('X')

%timeStamp vs y
subplot(2, 2, 2)
plot(timeStamps, y, '-o')
xlabel('Time (s)')
ylabel('Y')

%x vs y
subplot(2, 2, 3)
plot(x, y, '-o')
xlabel('X')
ylabel('Y')

% x vs y vs time
subplot(2, 2, 4)
plot3(timeStamps, x, y, '-o')
xlabel('Time (s)')
ylabel('X')
zlabel('Y')
	


