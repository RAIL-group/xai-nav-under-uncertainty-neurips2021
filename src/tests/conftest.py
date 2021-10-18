def pytest_addoption(parser):
    parser.addoption("--debug-plot", action="store_true")
    parser.addoption("--xpassthrough", default="false", action="store")
    parser.addoption("--unity-path", action="store", default=None)
    parser.addoption("--sim-dungeon-network-path",
                     action="store",
                     default=None)
    parser.addoption("--maze-interp-network-path",
                     action="store",
                     default=None)
