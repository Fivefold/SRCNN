import numpy as np
import warnings
from SSIM_PIL import compare_ssim as ssim

# taken from sewar source since zedboard can't install SciPy dependance of sewar
# https://github.com/andrewekhalel/sewar/blob/master/sewar/


def _initial_check(GT, P):
    assert GT.shape == P.shape, "Supplied images have different sizes " + \
        str(GT.shape) + " and " + str(P.shape)
    if GT.dtype != P.dtype:
        msg = "Supplied images have different dtypes " + \
            str(GT.dtype) + " and " + str(P.dtype)
        warnings.warn(msg)

    if len(GT.shape) == 2:
        GT = GT[:, :, np.newaxis]
        P = P[:, :, np.newaxis]

    return GT.astype(np.float64), P.astype(np.float64)


def mse(GT, P):
    """calculates mean squared error (mse).
    :param GT: first (original) input image.
    :param P: second (deformed) input image.
    :returns:  float -- mse value.
    """
    GT, P = _initial_check(GT, P)
    return np.mean((GT.astype(np.float64)-P.astype(np.float64))**2)


def psnr(GT, P, MAX=None):
    """calculates peak signal-to-noise ratio (psnr).
    :param GT: first (original) input image.
    :param P: second (deformed) input image.
    :param MAX: maximum value of datarange (if None, MAX is calculated using image dtype).
    :returns:  float -- psnr value in dB.
    """
    if MAX is None:
        MAX = np.iinfo(GT.dtype).max

    GT, P = _initial_check(GT, P)

    mse_value = mse(GT, P)
    if mse_value == 0.:
        return np.inf
    return 10 * np.log10(MAX**2 / mse_value)
