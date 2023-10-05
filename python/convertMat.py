
import numpy as np
import scipy.io as sio

# Load alpha data structure from .mat file
alpha_data = sio.loadmat('../matlab/data/alpha.mat')
alpha_r = alpha_data['alpha_r'].astype(float)
alpha_r = alpha_r.flatten()
np.save('./data/alpha.npy', alpha_r)

icio21 = sio.loadmat('../matlab/data/icio21_data.mat')
np.save('./data/icio21_data.npy', icio21)