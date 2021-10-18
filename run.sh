
# Build the repo
make build

# Ensure data timestamps are in the correct order
make fix-target-timestamps

# Maze Environments
make xai-maze EXPERIMENT_NAME=base_allSG
make xai-maze EXPERIMENT_NAME=base_4SG SP_LIMIT_NUM=4
make xai-maze EXPERIMENT_NAME=base_0SG SP_LIMIT_NUM=0

# University Building (floorplan) Environments
make xai-floorplan EXPERIMENT_NAME=base_allSG
make xai-floorplan EXPERIMENT_NAME=base_4SG SP_LIMIT_NUM=4
make xai-floorplan EXPERIMENT_NAME=base_0SG SP_LIMIT_NUM=0

# Results Plotting
make xai-process-results
