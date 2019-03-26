function frame = FrameFromEvents(polarity, contrast, dims)

%{
Polarity is a structure containing at least the fields x, y, and polarity,
column vectors of equal lengths where polarity is boolean
and x and y are zero-based coordinates.
returns 'frame'(uint8) a matrix of plus/minus plots of polarity data a la jAER. 
Encoding is from 0 (full scale OFF events) 
to contrast * 2 (full scale ON events, with contrast representing the
neutral value. 
dims is the expected dimension of the output - a tuple of [X Y]

Note that the frame returned accords to the maximum size of the x and y
events. 
%}

% Output class is double, because the numerical operation on polarity
% results in a double
if exist('dims', 'var')
    frame = accumarray([polarity.y polarity.x] + 1, polarity.polarity * 2 - 1, dims(end : -1 : 1));
else
    frame = accumarray([polarity.y polarity.x] + 1, polarity.polarity * 2 - 1);    
end

% Clip the values according to the contrast
frame(frame > contrast) = contrast;
frame(frame < - contrast) = -contrast;
frame = uint8(frame + contrast + 1);


