# Numpy implementation

This is an implementation of the *Super Resolution Convolutional Neural Network (SRCNN) by Dong, Chao, et al. "Image super-resolution using deep convolutional networks."* (https://arxiv.org/abs/1501.00092v3) done in Python utilising Numpy.

## Prerequisites

* Python (tested on Python 3.8)
  * Numpy (tested on 1.20.1)
  * Pillow (tested on 8.1.0)
  * sewar (tested on 1.0.12)

## Limitations

This implementation is very inefficient (read: slow). If you are using a PC it is recommended to use the torch implementation in this repository. If you are using Avnet's [ZedBoard](http://zedboard.org/product/zedboard) or a Linux-based system and don't want to install torch it is recommended to use the Cython implementation in this repository. 

## Usage

1. If you are not there already, change into the repository and the Numpy folder with `cd ~/SRCNN/Numpy/` 
   
2. There are a few test images in ~/SRCNN/Images/ like `bird.bmp` or `butterfly.bmp`

3. execute the script with 
   
   `python3.8 test_numpy.py --image-file "[Path to image file]"`
   
   e.g. `python3.8 test_numpy.py --image-file "../Images/butterfly.bmp"`

4. In the location of the original image there should be three additional images. Example with `butterfly.bmp`:
   1. `butterfly_GT.bmp`: original image (Ground truth)
   2. `butterfly_bicubic_x3.bmp`: image with bicubic upscaling
   3. `butterfly_srcnn_x3.bmp`: image with SRCNN upscaling
