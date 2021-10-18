import argparse


def add_base_learning_arguments(parser):
    """This function defines options shared across models."""
    parser.add_argument('--training_data_file', nargs='+', type=str)

    # Logging
    parser.add_argument('--logdir',
                        help='Directory in which to store log files',
                        required=True,
                        type=str)
    parser.add_argument('--summary_frequency',
                        default=1000,
                        help='Frequency (in steps) summary is logged to file',
                        type=int)

    # Training
    parser.add_argument('--training_iterations',
                        default=100000,
                        help='Number of iterations to run training',
                        type=int)
    parser.add_argument('--num_epochs',
                        default=20,
                        help='Number of epochs to run training',
                        type=int)
    parser.add_argument('--roll_variables', default=None, nargs='+')
    parser.add_argument('--learning_rate',
                        help='Initial learning rate',
                        type=float)
    parser.add_argument('--batch_size',
                        help='Number of data per training iteration batch',
                        type=int)
    parser.add_argument('--relative_positive_weight',
                        default=2.0,
                        help='Positive data relative weight',
                        type=float)


def parse_bool(v):
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')
