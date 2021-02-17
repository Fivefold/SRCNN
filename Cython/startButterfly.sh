#!/bin/sh
rm -f "../Images/butterfly_bicubic_x3.bmp"
rm -f "../Images/butterfly_srcnn_x3.bmp"
python3.8 test_cpython.py --image-file ../Images/butterfly.bmp
