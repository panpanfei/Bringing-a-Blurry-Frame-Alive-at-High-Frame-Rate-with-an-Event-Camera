function makevideo(videoName,blur_v,videoname,startframe,endframe,num,fps)


if(exist('videoName','file'))
    delete videoName.avi
end

aviobj=VideoWriter(videoName); 
aviobj.FrameRate=fps;

open(aviobj);%Open file for writing video data
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for frame=startframe:endframe
    for i = 1:num
        imgname = [videoname sprintf('/im/%03d_%02d.png',frame,i)];
        cI=imread(imgname);
%         cI = bilateral_filter((cI), 1, 0.1);
%         cI(cI>1) = 1;
        bI = mat2gray(im2double(blur_v{frame}));
        cI = mat2gray(im2double(cI));
        frames = [bI,cI];

        writeVideo(aviobj,frames);
    end
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close(aviobj);

end