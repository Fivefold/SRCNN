import argparse

import numpy as np
import PIL.Image as pil_image

import timeit
from util import rgb2ycbcr, ycbcr2rgb
from sewar.full_ref import psnr, ssim, msssim  # image metrics
from convolution import convolution2d_multichannel


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--image-file', type=str, required=True)
    args = parser.parse_args()

    args.scale = 3  # global scale. There are only weights for scale x3

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
    ground_truth = np.array(image).astype(np.uint8)
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

    # --- Convolution layers ---
    print("\nStarting convolution layer 1...")
    cc1 = convolution2d_multichannel(y, conv1_w, conv1_b)
    print("done")
    print("Starting convolution layer 2...")
    cc2 = convolution2d_multichannel(cc1, conv2_w, conv2_b)
    print("done")
    print("Starting convolution layer 3...")
    cc3 = convolution2d_multichannel(cc2, conv3_w, conv3_b)
    print("done")

    # scaling pixel values back from 0-1 to 0-255
    cc3 = np.squeeze(cc3) * 255.0
    # transpose: https://arrayjson.com/numpy-transpose/#NumPy_transpose_3d_array
    output_np = np.array(
        [cc3, ycbcr[..., 1], ycbcr[..., 2]]).transpose([1, 2, 0])
    # convert the output back to RGB and scale back to pixel values
    output_np = np.clip(ycbcr2rgb(output_np), 0.0, 255.0).astype(np.uint8)
    output = pil_image.fromarray(output_np)
    output.save(args.image_file.replace(
        '.bmp', '_srcnn_x{}.bmp'.format(args.scale)))

    print("\nUpscaling finished!")
    print("Ground truth image saved at \t" + args.image_file.replace(
        '.bmp', '_GT.bmp'))
    print("Bicubic upscaled image saved at " + args.image_file.replace(
        '.bmp', '_bicubic_x{}.bmp'.format(args.scale)))
    print("SRCNN upscaled image saved at \t" + args.image_file.replace(
        '.bmp', '_srcnn_x{}.bmp'.format(args.scale)))

    # image metrics
    PSNR = psnr(ground_truth, output_np, 255)
    SSIM, SSIM_CS = ssim(ground_truth, output_np, MAX=255)
    MS_SSIM = msssim(ground_truth, output_np, MAX=255)

    print("\n--- Image Metrics ---")
    print("PSNR: %.2f dB" % PSNR)
    print("SSIM: %.4f CS: %.4f" % (SSIM, SSIM_CS))
    print("MSSSIM: %.4f" % MS_SSIM.real)

    # execution time
    timer_stop = timeit.default_timer()
    execution_time = timer_stop - timer_start
    if execution_time > 60:
        execution_time_minutes = execution_time / 60
        print("\nExecution time: %.3f minutes (%.0f seconds)" %
              (execution_time_minutes, execution_time))
    else:
        print("\nExecution time: %.3f seconds" % execution_time)
