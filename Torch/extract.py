import argparse
import os

import torch
import torch.backends.cudnn as cudnn
import numpy as np
from numpy import savez_compressed

from models import SRCNN

# Extract weights & biases from the torch-based .pth format to
# several numpy-based .npz files
# use this if you want to use different weights & biases for the
# non-torch implementations
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--weights-file', type=str, required=True)
    parser.add_argument('--output-path', type=str,
                        default="./extracted_weights/")
    args = parser.parse_args()

    cudnn.benchmark = True
    device = torch.device('cpu:0' if torch.cuda.is_available() else 'cpu')

    model = SRCNN().to(device)

    # Gewichte einlesen
    state_dict = model.state_dict()
    for key, value in torch.load(args.weights_file, map_location=lambda storage, loc: storage).items():
        if key in state_dict.keys():
            state_dict[key].copy_(value)
        else:
            raise KeyError(key)

    if not os.path.exists(args.output_path):
        os.makedirs(args.output_path)

    # TODO: make this more elegant, iterate through the state_dict
    conv1_w = state_dict['conv1.weight'].numpy()
    savez_compressed(args.output_path + 'conv1_w.npz', conv1_w)
    conv1_b = state_dict['conv1.bias'].numpy()
    savez_compressed(args.output_path + 'conv1_b.npz', conv1_b)

    conv2_w = state_dict['conv2.weight'].numpy()
    savez_compressed(args.output_path + 'conv2_w.npz', conv2_w)
    conv2_b = state_dict['conv2.bias'].numpy()
    savez_compressed(args.output_path + 'conv2_b.npz', conv2_b)

    conv3_w = state_dict['conv3.weight'].numpy()
    savez_compressed(args.output_path + 'conv3_w.npz', conv3_w)
    conv3_b = state_dict['conv3.bias'].numpy()
    savez_compressed(args.output_path + 'conv3_b.npz', conv3_b)

    print("Extraction complete")
