function aedat = TrimEventsPolarity(aedat, startEvent, endEvent, reZero)

%{
For polarity events only, trim to a certain range of events by event number
Default is not to rezero time
%}

dbstop if error

if ~isfield(aedat, 'data')
    disp('No data found')
    return
end

if isfield(aedat.data, 'polarity')
    
    if startEvent > endEvent ...
            || startEvent > aedat.data.polarity.numEvents ...
            || endEvent   > aedat.data.polarity.numEvents
        error('Parameter error')
    end
    keepLogical = false(aedat.data.polarity.numEvents, 1);
    keepLogical(startEvent : endEvent) = true;
    aedat.data.polarity.timeStamp = aedat.data.polarity.timeStamp (keepLogical);
    aedat.data.polarity.x           = aedat.data.polarity.x       (keepLogical);
    aedat.data.polarity.y           = aedat.data.polarity.y       (keepLogical);
    aedat.data.polarity.polarity    = aedat.data.polarity.polarity(keepLogical);

    % Rezero
    if exist('reZero', 'var') && reZero
        aedat = ZeroTime(aedat);
    end

    % Tidy up
    aedat = NumEventsByType(aedat);
    aedat = FindFirstAndLastTimeStamps(aedat);
    
else
    error('No polarity data to trim')
end


