# Torch implementation

This is an implementation of the *Super Resolution Convolutional Neural Network (SRCNN) by Dong, Chao, et al. "Image super-resolution using deep convolutional networks."* (https://arxiv.org/abs/1501.00092v3) done in Python utilising Torch and Numpy.

## Prerequisites

* Python (tested on Python 3.8)
  * Numpy (tested on 1.20.1)
  * torch (tested on 1.7.0)
  * torchvision (tested on 0.8.1)
  * Pillow (tested on 8.1.0)
  * sewar (tested on 1.0.12)
  * tdqm (tested on 4.57.0)
  * h5py (tested on 3.1.0)
  

## Limitations

The included weights file only uses a scale factor of 3. If you need other scale factors you need to adjust the model in models.py and retrain the network using train.py.

## Usage

### Upscaling

1. If you are not there already, change into the repository and the Torch folder with `cd ~/SRCNN/Torch/` 
   
2. There are a few test images in ~/SRCNN/Images/ like `bird.bmp` or `butterfly.bmp`

3. execute the script with 
   
   `python test_numpy.py --image-file "[Path to image file]" --weights-file "[Path to weights file]"`
   
   e.g. `python test_numpy.py --image-file "../Images/butterfly.bmp" --weights-file "./weights/x3.pth"`

4. In the location of the original image there should be three additional images. Example with `butterfly.bmp`:
   1. `butterfly_GT.bmp`: original image (Ground truth)
   2. `butterfly_bicubic_x3.bmp`: image with bicubic upscaling
   3. `butterfly_srcnn_x3.bmp`: image with SRCNN upscaling

### Training

If you want to use a different network structure (e.g. a different kernel size) or scale factor you need to train a new set of weights and biases. First you need two sets/folders of images:

1. A (large) training set that is used to train the network. An example would be one of the [BSDS image sets](https://www2.eecs.berkeley.edu/Research/Projects/CS/vision/bsds/).
2. A (small) evaluation set that is *not contained* in the training set. A good choice is the Set5 image set.

Let's assume these sets are in the folders ./trainingSet/ and ./evaluationSet/

1. Execute `python ./prepare.py --images-dir "./trainingSet/" --output-path "./training.h5"`  
   This will create a ./training.h5 file.
2. Do the same for the evaluation set with `python .\prepare.py --images-dir "./trainingSet/" --output-path "./evaluation.h5"`
3. Now train the network with `python ./train.py --train-file "./training.h5" --eval-file ".\.h5" --outputs-dir "./output/"`  
   the ./output/ folder will contain a "best.pth" file which are the weights and biases of the epoch that gave the best PSNR.

### Weights and bias extraction

To use newly trained weights and biases in the Numpy implementation, they need to be converted into Numpy-compatible .npz files using extract.py

`python .\extract.py --weights-file ".\weights\x3.pth" --output-path "./"`

This will create 6 .npz files, representing the weights and biases of each of the three network layers.

To use these on the Cython implementation they need to be converted to fixed point (signed) 6.26 format. For this convert them to float64, multiply them with 2^26 and then convert to int32.