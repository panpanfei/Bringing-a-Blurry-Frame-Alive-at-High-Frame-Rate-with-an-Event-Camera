import numpy as np
import matplotlib.pyplot as plt

def PlotFrame(aedat, numPlots, distributeBy, minTime, maxTime, flipVertical, flipHorizontal, transpose):

# REWRITE HALFWAY THROUGH

    '''
    Takes 'aedat' - a data structure containing an imported .aedat file, 
    as created by ImportAedat, and creates a series of images from selected
    frames.
    The number of subplots is given by the numPlots parameter.
    'distributeBy' can either be 'time' or 'events', to decide how the points 
    around which data is rendered are chosen. 
    The frame events are then chosen as those nearest to the time points.
    If the 'distributeBy' is 'time' then if the further parameters 'minTime' 
    and 'maxTime' are used then the time window used is only between
    those limits.
    '''
    
    try:
    	distributeBy = distributeBy
    except NameError:
        distributeBy = 'time'
    
    # Assume that any aedat3 frame timestamps have been simplified
    	timeStamps = aedat['data']['frame']['timeStampStart']
    numFrames = aedat['data']['frame']['numEvents']
    if numFrames < numPlots:
    	numPlots = numFrames

    if numFrames == numPlots:
    	distributeBy = 'events'    
    
    # Distribute plots in a raster with a 3:4 ratio
    numPlotsX = round(sqrt(numPlots / 3 * 4))
    numPlotsY = np.ceil(numPlots / numPlotsX)
    
    
!!!!!!!REWRITE GOT TO HERE!    
    
    
    if strcmpi(distributeBy, 'time')
        if ~exist('minTime', 'var') || (exist('minTime', 'var') && minTime == 0)
            minTime = min(timeStamps);
        else
            minTime = minTime * 1e6;
        end
        if ~exist('maxTime', 'var') || (exist('maxTime', 'var') && maxTime == 0)
            maxTime = max(timeStamps);
        else
            maxTime = maxTime * 1e6;
        end
    
    	totalTime = maxTime - minTime;
    	timeStep = totalTime / numPlots;
    	timePoints = minTime + timeStep * 0.5 : timeStep : maxTime;
    else % distribute by event number
    	framesPerStep = numFrames / numPlots;
    	timePoints = timeStamps(ceil(framesPerStep * 0.5 : framesPerStep : numFrames));
    end
    
!!! THIS IS AN EXAMPLE FROM MATPLOTLIB    
    
    f, axarr = plt.subplots(2, 2)
    axarr[0, 0].plot(x, y)
    axarr[0, 0].set_title('Axis [0,0]')
    axarr[0, 1].scatter(x, y)
    axarr[0, 1].set_title('Axis [0,1]')
    axarr[1, 0].plot(x, y ** 2)
    axarr[1, 0].set_title('Axis [1,0]')
    axarr[1, 1].scatter(x, y ** 2)
    axarr[1, 1].set_title('Axis [1,1]')
    # Fine-tune figure; hide x ticks for top plots and y ticks for right plots
    plt.setp([a.get_xticklabels() for a in axarr[0, :]], visible=False)
    plt.setp([a.get_yticklabels() for a in axarr[:, 1]], visible=False)    
    
    


    for plotCount = 1 : numPlots
    	if numPlots > 1
            subplot(numPlotsY, numPlotsX, plotCount);
    	end
    	hold all
    	% Find eventIndex nearest to timePoint
    	frameIndex = find(timeStamps >= timePoints(plotCount), 1, 'first');
    	% Ignore colour for now ...    
    	if exist('transpose', 'var') && transpose
        	imagesc(input.data.frame.samples{frameIndex}')
        else
            imagesc(input.data.frame.samples{frameIndex})
        end
        colormap('gray')
    	axis equal tight
    	if exist('flipVertical', 'var') && flipVertical
    		set(gca, 'YDir', 'reverse')
    	end
    	if exist('flipHorizontal', 'var') && flipHorizontal
    		set(gca, 'XDir', 'reverse')
    	end
    	title(['Time: ' num2str(round(double(timeStamps(frameIndex)) / 1000) /1000) ' s; frame number: ' num2str(frameIndex)])
    end
    
