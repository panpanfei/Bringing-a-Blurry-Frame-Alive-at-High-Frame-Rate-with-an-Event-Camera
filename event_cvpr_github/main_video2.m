addpath './EDI/'
%% load data
outname = 'rotatevideonew2_6';
videoname = sprintf('./result/%s/',outname);
if ~exist([videoname '/im/'],'dir'), mkdir([videoname '/im/']); end
dataname = sprintf('./data/%s/',outname);
load([dataname 'data.mat']);
%% parameters
% The way to generate vedio
option = 2; % avoide flickering noise, option=2
dnoise = 0; % If needs denoise, dnoise=1
% Data paremeter
timescale = 1e6;
t_shift = -0.04;

startframe = 45;
endframe = 50;
% The length of the reconstructed video
v_length = 100;
%% prepare data
y_o = double(matlabdata.data.polarity.y)-1;
x_o = double(matlabdata.data.polarity.x)-1;
pol_o = double(matlabdata.data.polarity.polarity);
pol_o(pol_o==0) = -1;
t_o = double(matlabdata.data.polarity.timeStamp) ./ timescale;
%%
for frame = startframe:endframe
    
    blur = matlabdata.data.frame.samples{frame};
    blur = mat2gray(blur);
    x = x_o; y = y_o; pol = pol_o; t = t_o;
    % choose frame and time tag
    
    t_for = double(matlabdata.data.frame.timeStampStart(frame+1))./ timescale - double(matlabdata.data.frame.timeStampEnd(frame))./ timescale;
    t_back = double(matlabdata.data.frame.timeStampStart(frame))./ timescale - double(matlabdata.data.frame.timeStampEnd(frame-1))./ timescale;
    eventstart = double(matlabdata.data.frame.timeStampStart(frame))./ timescale + t_shift - t_back/2;
    eventend = double(matlabdata.data.frame.timeStampEnd(frame))./ timescale + t_shift + t_for/2;
    
    exptime = eventend - eventstart;
    
    idx = (t>=eventstart)&(t<=eventend);
    
    y(idx~=1)=[];
    x(idx~=1)=[];
    pol(idx~=1)=[];
    t(idx~=1)=[];
    
    %% option1: easiest way to reconstruct clean video with a uniform c
    %  for the whole video, sometimes include flickering noise at the end
    %  of the video because of the accumulated error.
    
    if option == 1
        tic
        [delta] = estdelta(blur,x,y,pol,t,eventstart,eventend,exptime);
        [I,~] = warpingBlur2If(delta,blur,x,y,pol,t,eventstart,eventend,exptime);
        [I_video] = fromIf2Ivideo(delta,I,x,y,pol,t,eventstart,eventend,exptime,v_length);
        toc
    end
    
    %% option2: estimate c for each reconstruct clean frame
    
    if option == 2
        tic
        [I_video,deltaT] = event2video_final(blur,x,y,pol,t,eventstart,eventend,exptime,v_length);
        toc
    end
    
    %% save result
    for i = 1:length(I_video)
        imgname = [videoname sprintf('/%03d_%02d.png',frame,i)];
        if dnoise == 1
            cI = bilateral_filter(mat2gray(I_video{i}), 1, 0.1);
        else
            cI = mat2gray(I_video{i});
        end
        imwrite( cI, [videoname sprintf('/im/%03d_%02d.png',frame,i)]);
    end
    
end
%% make videos
% video frame rate
fps = 50;
makevideo([videoname outname '.avi'],matlabdata.data.frame.samples,videoname,startframe,endframe,v_length,fps)