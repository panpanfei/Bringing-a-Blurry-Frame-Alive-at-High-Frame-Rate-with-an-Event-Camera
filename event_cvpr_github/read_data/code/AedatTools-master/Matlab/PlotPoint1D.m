function PlotPoint1D(aedat)

%{

Takes 'aedat' - a data structure containing an imported .aedat file, 
as created by ImportAedat, and creates a plot of point1D events. 

TO DO: use colour to express event Type
%}

timeStamps = double(aedat.data.point1D.timeStamp)' / 1000000;
x = (aedat.data.point1D.x)';

figure
set(gcf,'numbertitle','off','name','Point1D')
%timeStamp vs x
plot(timeStamps, x, '-o')
xlabel('Time (s)')
ylabel('X')
	