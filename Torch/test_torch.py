import argparse

import torch
import torch.backends.cudnn as cudnn
import numpy as np
import PIL.Image as pil_image

import timeit
from models import SRCNN
from util import rgb2ycbcr, ycbcr2rgb
from sewar.full_ref import psnr, ssim, msssim  # image metrics


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--weights-file', type=str, required=True)
    parser.add_argument('--image-file', type=str, required=True)
    parser.add_argument('--scale', type=int, default=3)
    args = parser.parse_args()

    timer_start = timeit.default_timer()

    cudnn.benchmark = True
    device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')

    model = SRCNN().to(device)  # Create an instance of the NN and send to CUDA

    # --- load weights & biases ---
    state_dict = model.state_dict()
    for key, value in torch.load(args.weights_file, map_location=lambda storage, loc: storage).items():
        if key in state_dict.keys():
            state_dict[key].copy_(value)
        else:
            raise KeyError(key)

    model.eval()  # put model in evaluation mode (instead of training mode)

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

    y = torch.from_numpy(y).to(device)  # y becomes a tensor
    # add two dimensions at the start (input channels, output channels)
    y = y.unsqueeze(0).unsqueeze(0)

    with torch.no_grad():  # deactivate gradient calculations (if only tensor.forward() is needed)
        # cut off values outside of 0-1 and send the data to our network
        conv = model(y).clamp(0.0, 1.0)

    # scale back to pixel values (0-255) and remove the two (now) obsolete dimensions
    conv = conv.mul(255.0).cpu().numpy().squeeze()

    # transpose: https://arrayjson.com/numpy-transpose/#NumPy_transpose_3d_array
    output_np = np.array(
        [conv, ycbcr[..., 1], ycbcr[..., 2]]).transpose([1, 2, 0])
    # convert the output back to RGB and scale back to pixel values
    output_np = np.clip(ycbcr2rgb(output_np), 0.0, 255.0).astype(np.uint8)
    output = pil_image.fromarray(output_np)
    output.save(args.image_file.replace(
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
