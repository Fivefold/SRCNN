import argparse
import glob
import h5py
import numpy as np
import PIL.Image as pil_image
from util import rgb2y


def scale_ops(hr):
    # --- image resizing & preparation ---
    hr_width = (hr.width // args.scale) * args.scale
    hr_height = (hr.height // args.scale) * args.scale
    # resize to a multiple of 3 to get the ground truth
    hr = hr.resize((hr_width, hr_height), resample=pil_image.BICUBIC)
    # actual resizing to 1/3
    lr = hr.resize((hr_width // args.scale, hr_height //
                    args.scale), resample=pil_image.BICUBIC)
    # back x3
    lr = lr.resize((lr.width * args.scale, lr.height *
                    args.scale), resample=pil_image.BICUBIC)

    hr = np.array(hr).astype(np.float32)
    lr = np.array(lr).astype(np.float32)
    hr = rgb2y(hr)
    lr = rgb2y(lr)

    return hr, lr


def train(args):
    h5_file = h5py.File(args.output_path, 'w')

    # lr...low resolution hr...high resolution
    lr_patches = []
    hr_patches = []

    for image_path in sorted(glob.glob('{}/*'.format(args.images_dir))):
        hr = pil_image.open(image_path).convert('RGB')

        hr, lr = scale_ops(hr)

        for i in range(0, lr.shape[0] - args.patch_size + 1, args.stride):
            for j in range(0, lr.shape[1] - args.patch_size + 1, args.stride):
                lr_patches.append(
                    lr[i:i + args.patch_size, j:j + args.patch_size])
                hr_patches.append(
                    hr[i:i + args.patch_size, j:j + args.patch_size])

    lr_patches = np.array(lr_patches)
    hr_patches = np.array(hr_patches)

    h5_file.create_dataset('hr', data=hr_patches)
    h5_file.create_dataset('lr', data=lr_patches)

    h5_file.close()


def eval(args):
    h5_file = h5py.File(args.output_path, 'w')

    # lr...low resolution hr...high resolution
    lr_group = h5_file.create_group('lr')
    hr_group = h5_file.create_group('hr')

    for i, image_path in enumerate(sorted(glob.glob('{}/*'.format(args.images_dir)))):
        hr = pil_image.open(image_path).convert('RGB')

        hr, lr = scale_ops(hr)

        hr_group.create_dataset(str(i), data=hr)
        lr_group.create_dataset(str(i), data=lr)

    h5_file.close()


# Prepare a folder of images into the .h5 format that torch uses
# Warning: the resulting files are much larger than the size of
# the initial images. 1.3 MB of images become over 1 GB.
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    # Directory with images to prepare for training/evaluation
    parser.add_argument('--images-dir', type=str, required=True)
    # Path/Filename to output the .h5 file to
    parser.add_argument('--output-path', type=str, default="prepared_set.h5")
    parser.add_argument('--patch-size', type=int, default=33)
    parser.add_argument('--stride', type=int, default=14)
    parser.add_argument('--scale', type=int, default=3)
    parser.add_argument('--eval', action='store_true')
    args = parser.parse_args()

    if not args.eval:
        train(args)
    else:
        eval(args)
    print("Preparation complete! .h5 file saved as " + args.output_path)
