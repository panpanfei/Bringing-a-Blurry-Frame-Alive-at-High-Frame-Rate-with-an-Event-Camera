addpath './code/AedatTools-master/Matlab'
clear
aedat.importParams.filePath = '../data/rotatevideonew2_6.aedat';%newdrop
matlabdata = ImportAedat(aedat);


dataname = '../data/rotatevideonew2_6/';
if ~exist([dataname 'blurimage/'],'dir'), mkdir([dataname 'blurimage/']);end


for i = 1:length(matlabdata.data.frame.samples)
    matlabdata.data.frame.samples{i} = flipud(matlabdata.data.frame.samples{i});
    imgname = sprintf('blurimage/%04d.png',i);
    image   = (mat2gray(matlabdata.data.frame.samples{i}));
    imwrite(image,[dataname,imgname])
end

matlabdata.data.polarity.y = 180 - matlabdata.data.polarity.y;%flipud
matlabdata.data.polarity.x = 240 - matlabdata.data.polarity.x;
     
save([dataname 'data.mat'] , 'matlabdata');

% figure
% imshow(matlabdata.data.frame.samples{5},[]);
