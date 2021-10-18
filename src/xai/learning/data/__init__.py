from itertools import repeat
import torch.utils.data as data

from .csv_pickle_dataset import CSVPickleDataset


def repeater(data_loader):
    """Allows the dataset to loop indefinitely."""
    for loader in repeat(data_loader):
        for datum in loader:
            yield datum


def create_dataset_from_files(files):
    """Make a dataset from a file or list of CSV files."""
    return CSVPickleDataset(files)


def create_datasets(args):
    if args.training_data_file:
        training_datasets = list(
            map(lambda x: CSVPickleDataset(x), args.training_data_file))
        training_dataset = data.ConcatDataset(training_datasets)
    else:
        training_dataset = None

    if args.test_data_file:
        test_datasets = list(
            map(lambda x: CSVPickleDataset(x), args.test_data_file))
        test_dataset = data.ConcatDataset(test_datasets)
    else:
        test_dataset = None

    return training_dataset, test_dataset
