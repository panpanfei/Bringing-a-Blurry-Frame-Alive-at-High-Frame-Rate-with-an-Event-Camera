For academic use only.
--------------------------------------------------------------------------------
#Publications
https://arxiv.org/abs/1811.10180v1
@article{pan2018bringing,
  title={Bringing a blurry frame alive at high frame-rate with an event camera},
  author={Pan, Liyuan and Scheerlinck, Cedric and Yu, Xin and Hartley, Richard and Liu, Miaomiao and Dai, Yuchao},
  journal={arXiv preprint arXiv:1811.10180},
  year={2018}
}

@article{pan2019bringing,
  title={Bringing Blurry Alive at High Frame-Rate with an Event Camera},
  author={Pan, Liyuan and Hartley, Richard and Scheerlinck, Cedric and Liu, Miaomiao and Yu, Xin and Dai, Yuchao},
  journal={arXiv preprint arXiv:1903.06531},
  year={2019}
}

#Data
https://drive.google.com/file/d/1s-PR7GxpCAIB20hu7F3BlbXdUi4c9UAo/view
--------------------------------------------------------------------------------

Prepare matlab code
1. Download the data and put them to 'data' file
2. Chose the data name and saving name; 
3. run rawdata2matlab(inputname,outputname);
(e.g. rawdata2matlab('../data/rotatevideonew2_6.aedat','../data/rotatevideonew2_6/');)


Reconstruct high frame rate video
1. Chose the data name and saving name; 
2. Please run: event_cvpr_github/read_data/main_video2.m
3. Change some options that can help to avoide noise.

----------------
There are a few parameters need to be specified by users.
---------------
Kernel estimation part:
---------------
'option'   :   2 for avoide flickering noise
'dnoise'   :   1 for bilateral_filter to denoise
't_shift'  :   In our real event data, the time shift is '-0.02' or '-0.04'
'v_length' :   The length of the reconstructed video
'lambda'   :   In file './EDI/TVnorm.m' 
---------------

----------------
IMPORTANT NOTE 
----------------
1. For pursuing better result when using your own dataset, please try with slightly changed parameters. 
   (e.g.  't_shift', 'v_length' and 'lambda')
   Make sure that there have enough events during each time interval (interval here means 
   the time between the neighbouring frames in our reconstructed video).
   
2. Should you have any questions regarding this code and the corresponding results, 
   please contact Liyuan.Pan@anu.edu.au

