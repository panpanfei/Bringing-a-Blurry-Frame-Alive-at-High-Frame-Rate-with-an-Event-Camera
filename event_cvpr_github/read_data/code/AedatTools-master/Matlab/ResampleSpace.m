function aedat = ResampleSpace(aedat, newX, newY)

%{
This function take a structure which has been imported and squeezes or 
stretches the events (polarity only for now ...) 
into the params newX and newY. 
parameters give the array size and one-based, but the address space is zero based. 
%}

dbstop if error

if isfield(aedat, 'data') && isfield(aedat.data, 'polarity')
    % There should be a more principled way of finding out the array size,
    % but for now just look at the max addresses ...
    mx = uint64(max(aedat.data.polarity.x));
	temp = uint64(aedat.data.polarity.x) * (newX - 1);
	aedat.data.polarity.x = uint16(temp / mx);

    mx = uint64(max(aedat.data.polarity.y));
	temp = uint64(aedat.data.polarity.y) * (newY - 1);
	aedat.data.polarity.y = uint16(temp / mx);
end
    