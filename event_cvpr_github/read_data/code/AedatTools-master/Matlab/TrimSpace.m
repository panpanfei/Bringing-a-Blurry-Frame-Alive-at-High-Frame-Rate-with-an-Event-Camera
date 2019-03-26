function aedat = TrimSpace(aedat, newX, newY)

%{
This function take a structure which has been imported and trims the events
down to the params newX and newY. parameters
give the array size and one-based, but the address space is zero based.
 newX and newY are tuples, containing the desired range. Addresses are then
 shifted to start at 0,0

Applies to polarity and point2D events; 
TODO: Apply to frames

%}

% Zero-base the params
newX = newX - 1;
newY = newY - 1;

dbstop if error

if isfield(aedat, 'data') && isfield(aedat.data, 'polarity')
    keepXLogical = aedat.data.polarity.x <= newX(2) & aedat.data.polarity.x >= newX(1);
    keepYLogical = aedat.data.polarity.y < newY(2) & aedat.data.polarity.y >= newY(1);
    keepLogical = keepXLogical & keepYLogical;
    aedat.data.polarity.x = aedat.data.polarity.x(keepLogical) - newX(1);
    aedat.data.polarity.y = aedat.data.polarity.y(keepLogical) - newY(1);
    aedat.data.polarity.polarity = aedat.data.polarity.polarity(keepLogical);
    aedat.data.polarity.timeStamp = aedat.data.polarity.timeStamp(keepLogical);
    aedat.data.polarity.numEvents = length(aedat.data.polarity.polarity);
end
    
if isfield(aedat, 'data') && isfield(aedat.data, 'point2D')
    keepXLogical = aedat.data.point2D.x <= newX(2) & aedat.data.point2D.x >= newX(1);
    keepYLogical = aedat.data.point2D.y <= newY(2) & aedat.data.point2D.y >= newY(1);
    keepLogical = keepXLogical & keepYLogical;
    aedat.data.point2D.x = aedat.data.point2D.x(keepLogical) - newX(1);
    aedat.data.point2D.y = aedat.data.point2D.y(keepLogical) - newY(1);
    aedat.data.point2D.type = aedat.data.point2D.type(keepLogical);
    aedat.data.point2D.timeStamp = aedat.data.point2D.timeStamp(keepLogical);
    aedat.data.point2D.numEvents = length(aedat.data.point2D.polarity);
end
    
% Recalculate first and last timestamps
aedat = FindFirstAndLastTimeStamps(aedat);
