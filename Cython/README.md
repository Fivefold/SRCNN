# Cython implementation

This is an implementation of the *Super Resolution Convolutional Neural Network (SRCNN) by Dong, Chao, et al. "Image super-resolution using deep convolutional networks."* (https://arxiv.org/abs/1501.00092v3) done in Python, C and VHDL.

The purely CPU-run version can run on any Linux-based system but is **made primarily for running on Avnet's [ZedBoard](http://zedboard.org/product/zedboard)**, utilising it's FPGA. 

## General prerequisites

* Python (tested on Python 3.8 but should work on any version above 3.5)
  * Numpy (tested on 1.19.5)
  * Pillow (tested on 8.1.0)
  * wurlitzer (tested on 2.0.1)
  * SSIM-PIL (tested on 1.0.12)
* A C compiler

## ZedBoard-specific prerequisites

* Python (tested on Python 3.8 installed via the [deadsnakes PPA](https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa))
  * (Optional) pip (tested on 21.0, installed via [get-pip.py](https://github.com/pypa/get-pip))
  * Numpy (tested on 1.19.5)
  * Pillow (tested on 8.1.0)
  * wurlitzer (tested on 2.0.1)
  * SSIM-PIL (tested on 1.0.12)
* python3.8-distutils (for compiling numpy)
* python3.8-dev (for compiling numpy)
* libjpeg-dev (for compiling pillow)

## Usage

1. If you are not there already, change into the repository and the Cython folder with `cd ~/SRCNN/Cython/` 
   
2. There are a few test images in ~/SRCNN/Images/ like `bird.bmp` or `butterfly.bmp`
3. (Optional) to upload your own image you can use the scp command from another PC (if your zedboard is connected to the same local network via Ethernet).
   
   `scp "[Path to image file on host system]" root@[local IP address]:"/root/SRCNN/Images/"`

   If it asks for a password and you haven't set one on the zedboard you can do so (in the ZedBoard shell) with `passwd`

4. execute the script with 
   
   `python3.8 test_cpython.py --image-file "[Path to image file]"`
   
   e.g. `python3.8 test_cpython.py --image-file "../Images/butterfly.bmp"`

5. In the location of the original image should be three additional images. Example with `butterfly.bmp`:
   1. `butterfly_GT.bmp`: original image (Ground truth)
   2. `butterfly_bicubic_x3.bmp`: image with bicubic upscaling
   3. `butterfly_srcnn_x3.bmp`: image with SRCNN upscaling

6. (Optional) To easily access the file remotely you can use the scp command again like in step 3.
   
   `scp root@[local IP address]:"/root/SRCNN/Images/[image name]" "[Destination path on host system]" `

## Installation instructions for ZedBoard

Prepare your ZedBoard for running Xillinux according to the [official guide](http://www.xillybus.com/downloads/doc/xillybus_getting_started_zynq.pdf).

When Xillinux is running you can either connect a display, mouse and keyboard to work directly with the zedboard or just connect an Ethernet cable and connect via SSH. The latter is recommended for ease of use. Also, the following commands won't work without any internet access.

1. Because the current (as of writing) Xillinux distro is based on Ubuntu 16.04, the repository sources are very old. To get more current python versions an external PPA needs to be added, for example the [deadsnakes PPA](https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa).
   
   `add-apt-repository ppa:deadsnakes/ppa`

2. Update the repository sources with `apt update`
   
3. Install python 3.8 as well as needed dev packages for compiling python packages later 
   
   `apt install python3.8 python3.8-distutils python3.8-dev libjpeg-dev`
   
4. To install a current version of pip there are various ways. The easiest on the Zedboard is to use the [get-pip.py](https://github.com/pypa/get-pip) script. Download it with 
   
   `curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py`

5. Execute the script with `python3.8 get-pip.py`
6. Check if pip was installed correctly with `pip --version` the output should look like this:
   
   `pip 21.0 from /usr/local/lib/python3.8/dist-packages/pip (python 3.8)`

   While the pip version might be higher than 21.0 check if the python version at the end says 3.8. If it does, it means pip was correctly linked with the previously installed python.
   
7. The pre-installed version of pillow is very old. Upgrade it with `pip install --upgrade pillow`. This can take a few minutes because it will need to compile the package.
8. Check if the version was correctly updated with `pip show pillow`. It should say 8.1.0 or higher. If it says 3.x.x it was not correctly updated.
9. Install numpy with `pip install numpy wurlitzer SSIM-PIL`. Because pip will have to build these from source this will take up to an hour with no immediate shell output, so be patient. You can check if it's still compiling by watching CPU usage on the OLED screen of the ZedBoard.
10. Check if numpy is correctly installed with `pip show numpy`. It should say 1.19.5 or higher.
11. Clone this repository with `git clone https://github.com/Fivefold/SRCNN.git`
