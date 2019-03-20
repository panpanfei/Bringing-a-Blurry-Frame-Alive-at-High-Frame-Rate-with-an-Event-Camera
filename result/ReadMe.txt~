This package contains an implementation of the image deblurring algorithm described in the paper: 
(accepted by cvpr 2019)
@article{pan2018phase,
  title={Phase-only Image Based Kernel Estimation for Single-image Blind Deblurring},
  author={Pan, Liyuan and Hartley, Richard and Liu, Miaomiao and Dai, Yuchao},
  journal={arXiv preprint arXiv:1811.10185},
  year={2018}
}

Please cite our paper if using the code to generate data (e.g., images, tables of processing times, etc.) 
in an academic publication.
----------------
Notes 
----------------
For algorithmic details, please refer to our paper.
We give the result of our method in file 'result'. Include dataset from 'Levin', 'Kohler', 'Gong' and 'Pan'.
For better result, some parameters are carefully designed. We also use some strategies like the 'patch-wise process' and 'coarse to fine', etc. 
The current release version is mainly for tackle uniform motion blur, especially on linear motion. The non-uniform deblurring can be achieved by segment the input blur image to overlapped square patches. If you use our code, please also cite 
  [1] Li Xu, Cewu Lu, Yi Xu, and Jiaya Jia. Image smoothing via l0 
      gradient minimization. ACM Trans. Graph., 30(6):174, 2011
  [2] S. Cho, J. Wang, and S. Lee, Handling outliers in non-blind image 
      deconvolution. ICCV 2011.
  [3] Jinshan Pan, Deqing Sun, Hanspteter Pfister, and Ming-Hsuan Yang,
      Blind Image Deblurring Using Dark Channel Prior, CVPR, 2016.
More details can be found in our paper.  
----------------
How to use
----------------
The code is tested in MATLAB 2015b(64bit) under the ubuntu 14.04 LTS 64bit version with an Intel Core i7-4790 CPU and a6 GB RAM.

1. unpack the package
2. include code/Phase_for_public/ in your Matlab path
3. Run "main_uniform.m" to try the examples included in this package.
----------------
User specified parameter:
----------------
There are a few parameters need to be specified by users.
---------------
Kernel estimation part:
---------------
'motionb'    :   1 for synthetic testing data
'kernel_size':   the size of blur kernel
'auto_size'  :   the scale for autocorrelation
'lambda_grad':   the weight for the L0 regularization on the gradient (typically set as 4e-3)
---------------

----------------
IMPORTANT NOTE 
----------------
1. Note that the algorithm sometimes may converge to an incorrect result. When you obtain such an incorrect result, please re-try to deblur with slightly changed parameters (e.g., using large blur kernel sizes or autocorrelation size). 
2. Our method works better in linear uniform motion. 
3.Should you have any questions regarding this code and the corresponding results, please contact Liyuan Pan
