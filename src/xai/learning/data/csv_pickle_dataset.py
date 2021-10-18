import glob
import gzip
import numpy as np
import os
import _pickle as cPickle
import torch.utils.data as data


class CSVPickleDataset(data.Dataset):
    def __init__(self, csv_filename, preprocess_image=True):
        if not isinstance(csv_filename, list):
            csv_filename = [csv_filename]

        self.preprocess_image = preprocess_image
        self._pickle_paths = []

        csvs = []
        for csvf in csv_filename:
            if '*' in csvf:
                csvs += glob.glob(csvf)
            else:
                csvs.append(csvf)

        for csvf in csvs:
            csv_file_directory = os.path.split(csvf)[0]
            with open(csvf, 'r') as fdata:
                self._pickle_paths += [
                    os.path.join(csv_file_directory, line.rstrip('\n'))
                    for line in fdata
                ]

    def __getitem__(self, index):
        with gzip.GzipFile(self._pickle_paths[index], 'rb') as pfile:
            data = cPickle.load(pfile)

        # Preprocess image
        if self.preprocess_image:
            try:
                data['image'] = np.transpose(data['image'], (2, 0, 1)).astype(
                    np.float32) / 255
            except:
                pass

        return data

    def __len__(self):
        return len(self._pickle_paths)
