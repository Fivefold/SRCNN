import h5py
import numpy as np
from torch.utils.data import Dataset


class Train_Dataset(Dataset):
    def __init__(self, h5_file):
        super(Train_Dataset, self).__init__()
        self.h5_file = h5_file

    def __getitem__(self, idx):
        with h5py.File(self.h5_file, 'r') as fun:
            return np.expand_dims(fun['lr'][idx] / 255., 0), np.expand_dims(fun['hr'][idx] / 255., 0)

    def __len__(self):
        with h5py.File(self.h5_file, 'r') as fun:
            return len(fun['lr'])


class Eval_Dataset(Dataset):
    def __init__(self, h5_file):
        super(Eval_Dataset, self).__init__()
        self.h5_file = h5_file

    def __getitem__(self, idx):
        with h5py.File(self.h5_file, 'r') as fun:
            return np.expand_dims(fun['lr'][str(idx)][:, :] / 255., 0), np.expand_dims(fun['hr'][str(idx)][:, :] / 255., 0)

    def __len__(self):
        with h5py.File(self.h5_file, 'r') as fun:
            return len(fun['lr'])
