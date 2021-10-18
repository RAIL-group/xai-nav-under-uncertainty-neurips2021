from collections import namedtuple
import torch.nn as nn


class Subgoal(object):
    def __init__(self, prob_feasible, delta_success_cost, exploration_cost,
                 id):
        self.prob_feasible = prob_feasible
        self.delta_success_cost = delta_success_cost
        self.exploration_cost = exploration_cost
        self.id = int(id)
        self.is_from_last_chosen = False

    def __hash__(self):
        return self.id


SubgoalPropDat = namedtuple('SubgoalPropDat', [
    'ind', 'prop_name', 'delta', 'weight', 'delta_cost', 'delta_cost_fraction',
    'net_data_cost_fraction', 'rank'
])


class EncoderNBlocks(nn.Module):
    def __init__(self, in_channels, out_channels, num_layers):
        super(EncoderNBlocks, self).__init__()
        nin = in_channels
        nout = out_channels
        modules = []

        # First layer
        modules.append(
            nn.Conv2d(nin,
                      nout,
                      kernel_size=3,
                      stride=1,
                      padding=1,
                      bias=False))
        modules.append(nn.BatchNorm2d(nout, momentum=0.01))
        modules.append(nn.LeakyReLU(0.1, inplace=True))

        # Add remaining layers
        for ii in range(1, num_layers):
            modules.append(
                nn.Conv2d(nout,
                          nout,
                          kernel_size=3,
                          stride=1,
                          padding=1,
                          bias=False))
            modules.append(nn.BatchNorm2d(nout, momentum=0.01))
            modules.append(nn.LeakyReLU(0.1, inplace=True))

        modules.append(nn.MaxPool2d(kernel_size=2, stride=2))

        self.cnn_layers = nn.Sequential(*modules)

    def forward(self, x):
        return self.cnn_layers(x)
