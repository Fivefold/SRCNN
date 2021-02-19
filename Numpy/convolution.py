import numpy as np


def convolution2d_multichannel(image, kernel, bias):
    _, y, x = image.shape

    # kernel shape: (output channels, input channels, x, y)
    chO, chI, _, _ = kernel.shape
    new_image = np.empty([chO, y, x])

    # for adding the images when num channel out < channel in
    layer_image = np.empty([chI, y, x])

    for i, kernel_arr in enumerate(kernel):
        # i ... iteration no.
        # kernel_arr shape: (input channels, x, y)

        print("i: %d" % i)
        padding = 9//2

        if chO < chI:  # Layers 2 and 3
            padding = 5//2

            for j, subkernel in enumerate(kernel_arr):
                layer_image[j] = convolution2d(
                    image[0, ...], subkernel, bias[i], padding)

            new_image[i] = np.sum(layer_image, axis=0) + bias[i]
        else:  # Layer 1
            new_image[i] = convolution2d(
                image[0, ...], kernel_arr[0, ...], bias[i], padding) + bias[i]

    new_image = np.clip(new_image, 0.0, None)
    return new_image


def convolution2d(image, kernel, bias, padding):
    m, n = kernel.shape
    if (m == n):  # if kernel is quadratic
        y, x = image.shape
        new_image = np.zeros((y, x), dtype='float32')  # create new temp array
        image = np.pad(image, padding, 'edge')

        for i in range(y):
            for j in range(x):
                new_image[i][j] = np.sum(image[i:i+m, j:j+m]*kernel) + bias
    return new_image
