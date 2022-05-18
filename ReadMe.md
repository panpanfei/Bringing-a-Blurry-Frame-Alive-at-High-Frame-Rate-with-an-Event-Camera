# For academic use only.

Update
----------------

Update: please download the 'update' folder and do a replacement (replace warpingBlur2If.p, fromIf2Ivideo.p, and event2video_final.p within the event_cvpr_github/EDI folder).  
Especially for those who would like to use their own dataset, please update files and choose option '1' if the dataset has a short exposure time. 

### If the image/video is sharp, please let I (main_video2.m, Line55) be the input image.


Prepare matlab code
----------------
1. Download the data and put them to 'data' folder
2. Choose the data name and saving name
3. run `rawdata2matlab(inputname,outputname);`
(e.g. `rawdata2matlab('../data/rotatevideonew2_6.aedat','../data/rotatevideonew2_6/');`)


Reconstruct high frame rate video
1. Choose the data name and saving name
2. Run event_cvpr_github/read_data/main_video2.m
3. Change some options that can help to avoid noise

There are a few parameters which need to be specified by users.
----------------

Kernel estimation part:
1. 'option'   :   2 for avoiding flickering noise
2. 'dnoise'   :   1 for bilateral_filter to denoise
3. 't_shift'  :   In our real event data, the time shift is '-0.02' or '-0.04'
4. 'v_length' :   The length of the reconstructed video
5. 'lambda'   :   In file './EDI/TVnorm.m' 


Note 
----------------
1. For pursuing better results when using your own dataset, please try with slightly changed parameters. 
   (e.g.  't_shift', 'v_length', 'exptime', and 'lambda')
   Make sure that there are enough events during each time interval (interval here means 
   the time between the neighbouring frames in our reconstructed video).
   
2. Should you have any questions regarding this code and the corresponding results, 
   please contact Liyuan.Pan@anu.edu.au
   

CVPR-video
----------------
https://drive.google.com/file/d/1NscnUF2QxK0of4ZW7T8kneJTH1X76l2u/view?usp=sharing

Data 
----------------
https://drive.google.com/file/d/1s-PR7GxpCAIB20hu7F3BlbXdUi4c9UAo/view

Publications 
----------------
1. https://openaccess.thecvf.com/content_CVPR_2019/html/Pan_Bringing_a_Blurry_Frame_Alive_at_High_Frame-Rate_With_an_CVPR_2019_paper.html
<pre>
@inproceedings{pan2019bringing,  
  title={Bringing a blurry frame alive at high frame-rate with an event camera}, 
  author={Pan, Liyuan and Scheerlinck, Cedric and Yu, Xin and Hartley, Richard and Liu, Miaomiao and Dai, Yuchao},      
  booktitle={Proceedings of the IEEE Conference on Computer Vision and Pattern Recognition},  
  pages={6820--6829},    
  year={2019}  
}
</pre>

2. https://ieeexplore.ieee.org/abstract/document/9252186

<pre>
@article{pan2020high,   
  title={High frame rate video reconstruction based on an event camera},   
  author={Pan, Liyuan and Hartley, Richard and Scheerlinck, Cedric and Liu, Miaomiao and Yu, Xin and Dai, Yuchao},      
  journal={IEEE Transactions on Pattern Analysis and Machine Intelligence},    
  year={2020},  
  publisher={IEEE}   
}
</pre>


