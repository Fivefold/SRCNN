import argparse

import sys
import os
import numpy as np
import PIL.Image as pil_image
import timeit

from util import rgb2ycbcr, ycbcr2rgb
from metrics import psnr, ssim

from ctypes import c_uint8, c_uint16, c_int32, POINTER, cdll
from numpy.ctypeslib import ndpointer


def conv_layer(inputs, weights, biases, mode):
    numChannelOut, numChannelIn, kernelSize, _ = weights.shape

    kernels = weights.flatten('C')
    biases_f = biases.flatten('C')

    c_int32_p = POINTER(c_int32)
    # with sys_pipes():
    if mode == "cpu":
        c_conv_cpu.restype = ndpointer(dtype=c_int32, shape=(
            (numChannelOut * image_height * image_width),))

        result = c_conv_cpu(inputs.ctypes.data_as(c_int32_p),
                            kernels.ctypes.data_as(c_int32_p),
                            biases_f.ctypes.data_as(c_int32_p),
                            c_uint8(numChannelIn),
                            c_uint8(numChannelOut),
                            c_uint8(kernelSize),
                            c_uint16(image_height),
                            c_uint16(image_width))
    else:
        c_conv_fpga.restype = ndpointer(dtype=c_int32, shape=(
            (numChannelOut * image_height * image_width),))

        result = c_conv_fpga(inputs.ctypes.data_as(c_int32_p),
                             kernels.ctypes.data_as(c_int32_p),
                             biases_f.ctypes.data_as(c_int32_p),
                             c_uint8(numChannelIn),
                             c_uint8(numChannelOut),
                             c_uint8(kernelSize),
                             c_uint16(image_height),
                             c_uint16(image_width))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--image-file', type=str, required=True)
    parser.add_argument('--mode', type=str, required=True,
                        choices=['cpu', 'fpga1', 'fpga2'])
    parser.add_argument('--scale', type=int, default=3, choices=[3])
    # Only scale 3 is supported currently.
    # Other scales need new weights & biases
    args = parser.parse_args()

    # --- load c convolution libraries ---
    if args.mode == "cpu":
        lib_cpu = cdll.LoadLibrary("./lib_cpu/cconv.so")
        c_conv_cpu = lib_cpu.cconv
    elif args.mode == "fpga1":
        lib_cpu = cdll.LoadLibrary("./lib_cpu/cconv.so")
        c_conv_cpu = lib_cpu.cconv
        lib_fpga = cdll.LoadLibrary("./lib_fpga/cconv1.so")
        c_conv_fpga = lib_fpga.cconv1
    else:  # fpga2
        lib_fpga = cdll.LoadLibrary("./lib_fpga/cconv2.so")
        c_conv_fpga = lib_fpga.cconv2

    timer_start = timeit.default_timer()

    # --- load weights & biases ---
    conv1_w = np.load("weights/conv1_w.npz")["arr_0"]
    conv1_b = np.load("weights/conv1_b.npz")["arr_0"]
    conv2_w = np.load("weights/conv2_w.npz")["arr_0"]
    conv2_b = np.load("weights/conv2_b.npz")["arr_0"]
    conv3_w = np.load("weights/conv3_w.npz")["arr_0"]
    conv3_b = np.load("weights/conv3_b.npz")["arr_0"]

    image = pil_image.open(args.image_file).convert('RGB')

    # --- image resizing & preparation ---
    image_width = (image.width // args.scale) * args.scale
    image_height = (image.height // args.scale) * args.scale
    # resize to a multiple of 3 to get the ground truth
    image = image.resize((image_width, image_height),
                         resample=pil_image.BICUBIC)
    image.save(args.image_file.replace(
        '.bmp', '_GT.bmp'))
    ground_truth_pil = image
    ground_truth_np = np.array(image)
    # actual resizing to 1/3
    image = image.resize((image.width // args.scale, image.height //
                          args.scale), resample=pil_image.BICUBIC)

    # back x3
    image = image.resize((image.width * args.scale, image.height *
                          args.scale), resample=pil_image.BICUBIC)
    image.save(args.image_file.replace(
        '.bmp', '_bicubic_x{}.bmp'.format(args.scale)))

    image = np.array(image).astype(np.float32)
    ycbcr = rgb2ycbcr(image)

    y = ycbcr[..., 0]       # remove colour channels
    y /= 255.               # scaling pixel values from 0-255 to 0-1
    y = y[np.newaxis, ...]  # add a dimension at the start

    # Conversion of luminance to fixed point 6.26
    y = y.astype("float64")
    y = np.multiply(y, pow(2, 26)).astype("int32")

    # --- Convolution layers ---
    cc0 = y.flatten('C')
    if args.mode == "fpga1":
        # fpga1 mode only calculates layer 2 and 3 on the fpga
        print("\nStarting convolution layer 1 of 3...")
        cc1 = conv_layer(cc0, conv1_w, conv1_b, "cpu")
        print("\nStarting convolution layer 2 of 3...")
        cc2 = conv_layer(cc1, conv2_w, conv2_b, args.mode)
        print("\nStarting convolution layer 3 of 3...")
        cc3 = conv_layer(cc2, conv3_w, conv3_b, args.mode)
    else:
        # cpu and fpga2 modes calculate all layer on the
        # cpu and fpga respectively
        print("\nStarting convolution layer 1 of 3...")
        cc1 = conv_layer(cc0, conv1_w, conv1_b, args.mode)
        print("\nStarting convolution layer 2 of 3...")
        cc2 = conv_layer(cc1, conv2_w, conv2_b, args.mode)
        print("\nStarting convolution layer 3 of 3...")
        cc3 = conv_layer(cc2, conv3_w, conv3_b, args.mode)
    cc3 = cc3.reshape(1, image_height, image_width)

    # Conversion from fixed point back to float
    cc3 = cc3.astype("float64")
    cc3 = np.divide(cc3, pow(2, 26))

    # scaling pixel values back from 0-1 to 0-255
    cc3 = np.squeeze(cc3) * 255.0
    # transpose: https://arrayjson.com/numpy-transpose/#NumPy_transpose_3d_array
    output_np = np.array(
        [cc3, ycbcr[..., 1], ycbcr[..., 2]]).transpose([1, 2, 0])
    # convert back to RGB and clip values that are outside of 0-255 range
    output_np = np.clip(ycbcr2rgb(output_np), 0.0, 255.0).astype(np.uint8)
    output = pil_image.fromarray(output_np)
    output.save(args.image_file.replace(
        '.bmp', '_srcnn_x{}.bmp'.format(args.scale)))

    print("\n\nUpscaling finished!\n")
    print("Ground truth image saved at \t" + args.image_file.replace(
        '.bmp', '_GT.bmp'))
    print("Bicubic upscaled image saved at " + args.image_file.replace(
        '.bmp', '_bicubic_x{}.bmp'.format(args.scale)))
    print("SRCNN upscaled image saved at \t" + args.image_file.replace(
        '.bmp', '_srcnn_x{}.bmp'.format(args.scale)))

    # --- image metrics ---
    PSNR = psnr(ground_truth_np, output_np, 255)
    SSIM = ssim(ground_truth_pil, output, GPU=False)

    print("\n--- Image Metrics ---")
    print("PSNR: %.2f dB" % PSNR)
    print("SSIM: %.4f" % SSIM)

    # --- execution time ---
    timer_stop = timeit.default_timer()
    execution_time = timer_stop - timer_start
    if execution_time > 60:
        execution_time_minutes = execution_time / 60
        print("\nExecution time: %.3f minutes (%.0f seconds)" %
              (execution_time_minutes, execution_time))
    else:
        print("\nExecution time: %.3f seconds" % execution_time)
