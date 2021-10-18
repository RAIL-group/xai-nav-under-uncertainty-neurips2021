import pytest


@pytest.fixture()
def debug_plot(pytestconfig):
    dbg_plt = pytestconfig.getoption("debug_plot")
    if pytestconfig.getoption("xpassthrough") == 'true':
        dbg_plt = True
    return dbg_plt


@pytest.fixture()
def unity_path(pytestconfig):
    return pytestconfig.getoption("unity_path")


@pytest.fixture()
def maze_interp_network_path(pytestconfig):
    return pytestconfig.getoption("maze_interp_network_path")
