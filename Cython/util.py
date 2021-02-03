import numpy as np

# Source for formulas: https://sistenix.com/rgb2ycbcr.html


def rgb2y(i):
    if type(i) == np.ndarray:
        return 16. + (65.738 * i[:, :, 0] + 129.057 * i[:, :, 1] + 25.064 * i[:, :, 2]) / 256.
    else:
        raise Exception('Unknown Type', type(i))


def rgb2ycbcr(i):
    if type(i) == np.ndarray:
        y = 16. + (65.738 * i[:, :, 0] + 129.057 *
                   i[:, :, 1] + 25.064 * i[:, :, 2]) / 256.
        cb = 128. + (-37.945 * i[:, :, 0] - 74.494 *
                     i[:, :, 1] + 112.439 * i[:, :, 2]) / 256.
        cr = 128. + (112.439 * i[:, :, 0] - 94.154 *
                     i[:, :, 1] - 18.285 * i[:, :, 2]) / 256.
        return np.array([y, cb, cr]).transpose([1, 2, 0])
    else:
        raise Exception('Unknown Type', type(i))


def ycbcr2rgb(i):
    if type(i) == np.ndarray:
        r = 298.082 * i[:, :, 0] / 256. + \
            408.583 * i[:, :, 2] / 256. - 222.921
        g = 298.082 * i[:, :, 0] / 256. - 100.291 * i[:, :, 1] \
            / 256. - 208.120 * i[:, :, 2] / 256. + 135.576
        b = 298.082 * i[:, :, 0] / 256. + \
            516.412 * i[:, :, 1] / 256. - 276.836
        return np.array([r, g, b]).transpose([1, 2, 0])
    else:
        raise Exception('Unknown Type', type(i))


# def calc_psnr(i1, i2):
    #    return 10. * torch.log10(1. / torch.mean((i1 - i2) ** 2))


# class AverageMeter(object):
#     def __init__(self):
#         self.reset()

#     def reset(self):
#         self.val = 0
#         self.avg = 0
#         self.sum = 0
#         self.count = 0

#     def update(self, val, n=1):
#         self.val = val
#         self.sum += val * n
#         self.count += n
#         self.avg = self.sum / self.count
