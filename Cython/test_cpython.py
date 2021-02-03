import argparse

import numpy as np
import PIL.Image as pil_image

from util import rgb2ycbcr, ycbcr2rgb

from ctypes import c_uint8, c_uint16, c_int32, POINTER, cdll
from numpy.ctypeslib import ndpointer

lib = cdll.LoadLibrary("./cconv.so")
c_conv = lib.cconv

scale = 3


def conv_layer(inputs, weights, biases):
    numChannelOut, numChannelIn, kernelSize, _ = weights.shape

    kernels = weights.flatten('C')
    biases_f = biases.flatten('C')

    c_conv.restype = ndpointer(dtype=c_int32, shape=(
        (numChannelOut * image_height * image_width),))

    c_int32_p = POINTER(c_int32)
    result = c_conv(inputs.ctypes.data_as(c_int32_p), kernels.ctypes.data_as(c_int32_p), biases_f.ctypes.data_as(c_int32_p), c_uint8(
        numChannelIn), c_uint8(numChannelOut), c_uint8(kernelSize), c_uint16(image_height), c_uint16(image_width))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--image-file', type=str, required=True)
    args = parser.parse_args()

    args.scale = 3  # global scale. There are only weights for scale x3

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
    # resize to a multiple of 3
    image = image.resize((image_width, image_height),
                         resample=pil_image.BICUBIC)
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
    cc1 = conv_layer(cc0, conv1_w, conv1_b)
    cc2 = conv_layer(cc1, conv2_w, conv2_b)
    cc3 = conv_layer(cc2, conv3_w, conv3_b)
    cc3 = cc3.reshape(1, image_height, image_width)

    # Conversion from fixed point back to float
    cc3 = cc3.astype("float64")
    cc3 = np.divide(cc3, pow(2, 26))

    # scaling pixel values back from 0-1 to 0-255
    cc3 = np.squeeze(cc3) * 255.0
    # transpose: https://arrayjson.com/numpy-transpose/#NumPy_transpose_3d_array
    output = np.array([cc3, ycbcr[..., 1], ycbcr[..., 2]]).transpose([1, 2, 0])
    # convert back to RGB and clip values that are outside of 0-255 range
    output = np.clip(ycbcr2rgb(output), 0.0, 255.0).astype(np.uint8)
    output = pil_image.fromarray(output)
    output.save(args.image_file.replace(
        '.bmp', '_srcnn_x{}.bmp'.format(args.scale)))
