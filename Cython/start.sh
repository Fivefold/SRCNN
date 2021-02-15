#!/bin/sh
rm -f "../Images/small_bw_bicubic_x3.bmp"
rm -f "../Images/small_bw_srcnn_x3.bmp"
python3.8 test_cpython.py --image-file ../Images/small_bw.bmp
