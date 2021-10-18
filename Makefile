## ==== Core Arguments and Parameters ====
MAJOR ?= 1
MINOR ?= 0
VERSION = $(MAJOR).$(MINOR)
APP_NAME ?= xai-nav-neurips21

# Core Names
MAZE_XAI_BASENAME ?= maze_xai_pretrained
FLOORPLAN_XAI_BASENAME ?= floorplan_xai_pretrained
EXPERIMENT_NAME ?= base
SP_LIMIT_NUM ?= -1

# Handle Optional GPU
USE_GPU ?= true
ifeq ($(USE_GPU),true)
	DOCKER_GPU_ARG = --gpus all
endif

# Docker args
DISPLAY ?= :0.0
DATA_BASE_DIR = $(shell pwd)/data
UNITY_DIR = $(DATA_BASE_DIR)/unity
UNITY_BASENAME = xai_unity
XPASSTHROUGH ?= false
DOCKER_FILE_DIR = "."
DOCKERFILE = ${DOCKER_FILE_DIR}/Dockerfile
IMAGE_NAME = ${APP_NAME}
DOCKER_CORE_VOLUMES = \
	--env XPASSTHROUGH=$(XPASSTHROUGH) \
	--env DISPLAY=$(DISPLAY) \
	$(DOCKER_GPU_ARG) \
	--volume="$(UNITY_DIR):/unity/:rw" \
	--volume="$(DATA_BASE_DIR):/data/:rw" \
	--volume="/tmp/.X11-unix:/tmp/.X11-unix:rw"
DOCKER_PYTHON = docker run --init --ipc=host \
	$(DOCKER_ARGS) $(DOCKER_CORE_VOLUMES) \
	${IMAGE_NAME}:${VERSION} python3


.PHONY: help
help:
	@echo ''
	@echo 'Usage: make [TARGET] [EXTRA_ARGUMENTS]'
	@echo 'Targets:'
	@echo '  help		display this help message'
	@echo '  build		build docker image (incremental)'
	@echo '  rebuild	build docker image from scratch'
	@echo '  kill		close all project-related docker containers'
	@echo '  test		run pytest in docker container'
	@echo 'Extra Arguments:'
	@echo '  DATA_BASE_DIR	local path to directory for storing data'
	@echo ''


## ==== Helpers for setting up the environment ====
define arg_check_unity
	@[ "${UNITY_DIR}" ] && true || \
		( echo "ERROR: Environment variable 'UNITY_DIR' must be set." 1>&2; exit 1 )
endef

define xhost_activate
	@echo "Enabling local xhost sharing:"
	@echo "  Display: $(DISPLAY)"
	@-DISPLAY=$(DISPLAY) xhost  +
	@-xhost  +
endef

arg-check-unity:
	$(call arg_check_unity)
arg-check-data:
	@[ "${DATA_BASE_DIR}" ] && true || \
		( echo "ERROR: Environment variable 'DATA_BASE_DIR' must be set." 1>&2; exit 1 )
xhost-activate:
	$(call xhost_activate)


## ==== Build targets ====

.PHONY: build
build:
	@echo "Building the Docker container"
	@docker build -t ${IMAGE_NAME}:${VERSION} \
		$(DOCKER_ARGS) -f ./${DOCKERFILE} .
	@echo "Creating source directory: $(DATA_BASE_DIR)"
	@mkdir -p $(DATA_BASE_DIR)

.PHONY: rebuild
rebuild:
	@docker build -t ${IMAGE_NAME}:${VERSION} --no-cache \
		$(DOCKER_ARGS) -f ./${DOCKERFILE} .

.PHONY: kill
kill:
	@echo "Closing all running docker containers:"
	@docker kill $(shell docker ps -q --filter ancestor=${IMAGE_NAME}:${VERSION})

.PHONY: fix-target-timestamps
fix-target-timestamps:
	@echo "Fixing relative timestamps after unzipping."
	@- touch $(shell ls $(maze-dir)/data_collect_plots/*.png)
	@- touch $(shell ls $(maze-dir)/training/base_allSG/*.pt)
	@- touch $(shell ls $(maze-dir)/results/base_allSG/*.png)
	@- touch $(shell ls $(maze-dir)/training/base_4SG/*.pt)
	@- touch $(shell ls $(maze-dir)/results/base_4SG/*.png)
	@- touch $(shell ls $(maze-dir)/training/base_0SG/*.pt)
	@- touch $(shell ls $(maze-dir)/results/base_0SG/*.png)
	@- touch $(shell ls $(floorplan-dir)/data_collect_plots/*.png)
	@- touch $(shell ls $(floorplan-dir)/training/base_allSG/*.pt)
	@- touch $(shell ls $(floorplan-dir)/results/base_allSG/*.png)
	@- touch $(shell ls $(floorplan-dir)/training/base_4SG/*.pt)
	@- touch $(shell ls $(floorplan-dir)/results/base_4SG/*110*.png)
	@- touch $(shell ls $(floorplan-dir)/results/base_4SG/*111*.png)
	@- touch $(shell ls $(floorplan-dir)/results/base_4SG/*112*.png)
	@- touch $(shell ls $(floorplan-dir)/results/base_4SG/*113*.png)
	@- touch $(shell ls $(floorplan-dir)/results/base_4SG/*114*.png)
	@- touch $(shell ls $(floorplan-dir)/results/base_4SG/*115*.png)
	@- touch $(shell ls $(floorplan-dir)/results/base_4SG/*116*.png)
	@- touch $(shell ls $(floorplan-dir)/results/base_4SG/*117*.png)
	@- touch $(shell ls $(floorplan-dir)/results/base_4SG/*118*.png)
	@- touch $(shell ls $(floorplan-dir)/results/base_4SG/*119*.png)
	@- touch $(shell ls $(floorplan-dir)/training/base_0SG/*.pt)
	@- touch $(shell ls $(floorplan-dir)/results/base_0SG/*.png)

# Shrink images (for submission file size limit)
.PHONY: shrink-images
# shrink-images: shr-dir = $(maze-dir)/data_collect_plots
shrink-images: shr-dir = $(maze-dir)/results/base_4SG
shrink-images: shr-args = -dither None -colors 10 -set filename:base "%[basename]"
shrink-images:
	- sudo convert $(shr-dir)/*110*.png[240x] $(shr-args) "$(shr-dir)/%[filename:base].png"
	- sudo convert $(shr-dir)/*111*.png[240x] $(shr-args) "$(shr-dir)/%[filename:base].png"
	- sudo convert $(shr-dir)/*112*.png[240x] $(shr-args) "$(shr-dir)/%[filename:base].png"
	- sudo convert $(shr-dir)/*113*.png[240x] $(shr-args) "$(shr-dir)/%[filename:base].png"
	- sudo convert $(shr-dir)/*114*.png[240x] $(shr-args) "$(shr-dir)/%[filename:base].png"
	- sudo convert $(shr-dir)/*115*.png[240x] $(shr-args) "$(shr-dir)/%[filename:base].png"
	- sudo convert $(shr-dir)/*116*.png[240x] $(shr-args) "$(shr-dir)/%[filename:base].png"
	- sudo convert $(shr-dir)/*117*.png[240x] $(shr-args) "$(shr-dir)/%[filename:base].png"
	- sudo convert $(shr-dir)/*118*.png[240x] $(shr-args) "$(shr-dir)/%[filename:base].png"
	- sudo convert $(shr-dir)/*119*.png[240x] $(shr-args) "$(shr-dir)/%[filename:base].png"


## ==== Running tests ====
.PHONY: test
test: DOCKER_ARGS ?= -it
test: PYTEST_FILTER ?= "py"
test:
	@$(call xhost_activate)
	@$(call arg_check_unity)
	@mkdir -p $(DATA_BASE_DIR)/test_logs
	@$(DOCKER_PYTHON) \
		-m py.test -vk $(PYTEST_FILTER) \
		-rsx \
		--full-trace \
		--html=/data/test_logs/report.html \
		--xpassthrough=$(XPASSTHROUGH) \
		--unity-path=/unity/$(UNITY_BASENAME).x86_64 \
		--maze-interp-network-path /data/maze_xai_pretrained/training/base_0SG/ExpNavVisLSP.final.pt \
		tests/

## ==== Core arguments ====

SIM_ROBOT_ARGS ?= --step_size 1.8 \
		--num_primitives 32 \
		--field_of_view_deg 360
INTERP_ARGS ?= --summary_frequency 100 \
		--num_epochs 1 \
		--learning_rate 2.0e-2 \
		--batch_size 4


## ==== Maze Arguments and Experiments ====
MAZE_CORE_ARGS ?= --unity_path /unity/$(UNITY_BASENAME).x86_64 \
		--map_type maze \
		--base_resolution 1.0 \
		--inflation_rad 2.5 \
		--laser_max_range_m 60 \
		--save_dir /data/$(MAZE_XAI_BASENAME)/
MAZE_DATA_GEN_ARGS = $(MAZE_CORE_ARGS) --logdir /data/$(MAZE_XAI_BASENAME)/training/data_gen
MAZE_EVAL_ARGS = $(MAZE_CORE_ARGS) --logdir /data/$(MAZE_XAI_BASENAME)/training/$(EXPERIMENT_NAME)
maze-dir = $(DATA_BASE_DIR)/$(MAZE_XAI_BASENAME)

# Initialize the Learning
xai-maze-init-learning = $(maze-dir)/training/data_gen/ExpNavVisLSP.init.pt
$(xai-maze-init-learning):
	@echo "Writing the 'initial' neural network [Maze: $(MAZE_XAI_BASENAME)]"
	@mkdir -p $(maze-dir)/training/$(EXPERIMENT_NAME)
	@$(DOCKER_PYTHON) -m scripts.explainability_train_eval \
		$(MAZE_DATA_GEN_ARGS) \
		$(SIM_ROBOT_ARGS) \
		$(INTERP_ARGS) \
		--do_init_learning

# Generate Data
xai-maze-data-gen-seeds = $(shell for ii in $$(seq 1000 1999); do echo "$(maze-dir)/data_collect_plots/learned_planner_$$ii.png"; done)
$(xai-maze-data-gen-seeds): $(xai-maze-init-learning)
	@echo "Generating Data [$(MAZE_XAI_BASENAME) | seed: $(shell echo $@ | grep -Eo '[0-9]+' | tail -1)"]
	@$(call xhost_activate)
	@rm -f $(maze-dir)/lsp_data_$(shell echo $@ | grep -Eo '[0-9]+' | tail -1).*.csv
	@mkdir -p $(maze-dir)/data
	@mkdir -p $(maze-dir)/data_collect_plots
	@$(DOCKER_PYTHON) -m scripts.explainability_train_eval \
		$(MAZE_DATA_GEN_ARGS) \
	 	$(SIM_ROBOT_ARGS) \
	 	$(INTERP_ARGS) \
	 	--do_data_gen \
	 	--current_seed $(shell echo $@ | grep -Eo '[0-9]+' | tail -1) \

# Train the Network
xai-maze-train-learning = $(maze-dir)/training/$(EXPERIMENT_NAME)/ExpNavVisLSP.final.pt
$(xai-maze-train-learning): $(xai-maze-data-gen-seeds)
	@$(DOCKER_PYTHON) -m scripts.explainability_train_eval \
		$(MAZE_EVAL_ARGS) \
		$(SIM_ROBOT_ARGS) \
		$(INTERP_ARGS) \
		--sp_limit_num $(SP_LIMIT_NUM) \
		--do_train

# Evaluate Performance
xai-maze-eval-seeds = $(shell for ii in $$(seq 11000 11999); do echo "$(DATA_BASE_DIR)/$(MAZE_XAI_BASENAME)/results/$(EXPERIMENT_NAME)/learned_planner_$$ii.png"; done)
$(xai-maze-eval-seeds): $(xai-maze-train-learning)
	@echo "Evaluating Performance [$(MAZE_XAI_BASENAME) | seed: $(shell echo $@ | grep -Eo '[0-9]+ | tail -1')]"
	@$(call xhost_activate)
	@$(call arg_check_unity)
	@mkdir -p $(maze-dir)/results/$(EXPERIMENT_NAME)
	$(DOCKER_PYTHON) -m scripts.explainability_train_eval \
		$(MAZE_EVAL_ARGS) \
		$(SIM_ROBOT_ARGS) \
		$(INTERP_ARGS) \
		--do_eval \
		--current_seed $(shell echo $@ | grep -Eo '[0-9]+' | tail -1) \
		--save_dir /data/$(MAZE_XAI_BASENAME)/results/$(EXPERIMENT_NAME) \
		--logfile_name logfile_final.txt


## ==== University Building (Floorplan) Environment Experiments ====
FLOORPLAN_CORE_ARGS ?= --unity_path /unity/$(UNITY_BASENAME).x86_64 \
		--map_type ploader \
		--base_resolution 0.6 \
		--inflation_radius_m 1.5 \
		--laser_max_range_m 72 \
		--save_dir /data/$(FLOORPLAN_XAI_BASENAME)/
FLOORPLAN_DATA_GEN_ARGS ?= $(FLOORPLAN_CORE_ARGS) \
		--map_file /data/university_building_floorplans/train/*.pickle \
		--logdir /data/$(FLOORPLAN_XAI_BASENAME)/training/data_gen
FLOORPLAN_EVAL_ARGS ?= $(FLOORPLAN_CORE_ARGS) \
		--map_file /data/university_building_floorplans/test/*.pickle \
		--logdir /data/$(FLOORPLAN_XAI_BASENAME)/training/$(EXPERIMENT_NAME)
floorplan-dir = $(DATA_BASE_DIR)/$(FLOORPLAN_XAI_BASENAME)


# Initialize the Learning
xai-floorplan-init-learning = $(floorplan-dir)/training/data_gen/ExpNavVisLSP.init.pt
$(xai-floorplan-init-learning):
	@echo "Writing the 'initial' neural network [Floorplan: $(FLOORPLAN_XAI_BASENAME)]"
	@mkdir -p $(floorplan-dir)/training/$(EXPERIMENT_NAME)
	@$(DOCKER_PYTHON) -m scripts.explainability_train_eval \
		$(FLOORPLAN_DATA_GEN_ARGS) \
		$(SIM_ROBOT_ARGS) \
		$(INTERP_ARGS) \
		--do_init_learning

# Generate Data
xai-floorplan-data-gen-seeds = $(shell for ii in $$(seq 1000 1009); do echo "$(floorplan-dir)/data_collect_plots/learned_planner_$$ii.png"; done)
$(xai-floorplan-data-gen-seeds): $(xai-floorplan-init-learning)
	@echo "Generating Data [$(FLOORPLAN_XAI_BASENAME) | seed: $(shell echo $@ | grep -Eo '[0-9]+' | tail -1)"]
	@$(call xhost_activate)
	@rm -f $(floorplan-dir)/lsp_data_$(shell echo $@ | grep -Eo '[0-9]+' | tail -1).*.csv
	@mkdir -p $(floorplan-dir)/data
	@mkdir -p $(floorplan-dir)/data_collect_plots
	@$(DOCKER_PYTHON) -m scripts.explainability_train_eval \
		$(FLOORPLAN_DATA_GEN_ARGS) \
	 	$(SIM_ROBOT_ARGS) \
	 	$(INTERP_ARGS) \
	 	--do_data_gen \
	 	--current_seed $(shell echo $@ | grep -Eo '[0-9]+' | tail -1) \

# Train the Network
xai-floorplan-train-learning = $(floorplan-dir)/training/$(EXPERIMENT_NAME)/ExpNavVisLSP.final.pt
$(xai-floorplan-train-learning): $(xai-floorplan-data-gen-seeds)
	@$(DOCKER_PYTHON) -m scripts.explainability_train_eval \
		$(FLOORPLAN_EVAL_ARGS) \
		$(SIM_ROBOT_ARGS) \
		$(INTERP_ARGS) \
		--sp_limit_num $(SP_LIMIT_NUM) \
		--do_train

# Evaluate Performance
xai-floorplan-eval-seeds = $(shell for ii in $$(seq 11000 11009); do echo "$(DATA_BASE_DIR)/$(FLOORPLAN_XAI_BASENAME)/results/$(EXPERIMENT_NAME)/learned_planner_$$ii.png"; done)
$(xai-floorplan-eval-seeds): $(xai-floorplan-train-learning)
	@echo "Evaluating Performance [$(FLOORPLAN_XAI_BASENAME) | seed: $(shell echo $@ | grep -Eo '[0-9]+ | tail -1')]"
	@$(call xhost_activate)
	@$(call arg_check_unity)
	@mkdir -p $(floorplan-dir)/results/$(EXPERIMENT_NAME)
	$(DOCKER_PYTHON) -m scripts.explainability_train_eval \
		$(FLOORPLAN_EVAL_ARGS) \
		$(SIM_ROBOT_ARGS) \
		$(INTERP_ARGS) \
		--do_eval \
		--current_seed $(shell echo $@ | grep -Eo '[0-9]+' | tail -1) \
		--save_dir /data/$(FLOORPLAN_XAI_BASENAME)/results/$(EXPERIMENT_NAME) \
		--logfile_name logfile_final.txt


# Some helper targets to run code individually
xai-floorplan-intervene-seeds-4SG = $(shell for ii in 11304 11591 11870 11336 11245 11649 11891 11315 11069 11202 11614 11576 11100 11979 11714 11430 11267 11064 11278 11367 11193 11670 11385 11180 11923 11195 11642 11462 11010 11386 11913 11103 11474 11855 11823 11641 11408 11899 11449 11393 11041 11435 11101 11610 11422 11546 11048 11070 11699 11618; do echo "$(floorplan-dir)/results/$(EXPERIMENT_NAME)/learned_planner_$${ii}_intervened_4SG.png"; done)
xai-floorplan-intervene-seeds-allSG = $(shell for ii in 11304 11591 11870 11336 11245 11649 11891 11315 11069 11202 11614 11576 11100 11979 11714 11430 11267 11064 11278 11367 11193 11670 11385 11180 11923 11195 11642 11462 11010 11386 11913 11103 11474 11855 11823 11641 11408 11899 11449 11393 11041 11435 11101 11610 11422 11546 11048 11070 11699 11618; do echo "$(floorplan-dir)/results/$(EXPERIMENT_NAME)/learned_planner_$${ii}_intervened_allSG.png"; done)
$(xai-floorplan-intervene-seeds-4SG): $(xai-floorplan-train-learning)
	@mkdir -p $(DATA_BASE_DIR)/$(FLOORPLAN_XAI_BASENAME)/results/$(EXPERIMENT_NAME)
	@$(DOCKER_PYTHON) -m scripts.explainability_train_eval \
		$(FLOORPLAN_EVAL_ARGS) \
		$(SIM_ROBOT_ARGS) \
		$(INTERP_ARGS) \
		--do_intervene \
		--sp_limit_num 4 \
	 	--current_seed $(shell echo $@ | grep -Eo '[0-9]+' | tail -2 | head -1) \
		--save_dir /data/$(FLOORPLAN_XAI_BASENAME)/results/$(EXPERIMENT_NAME) \
		--logfile_name logfile_intervene_4SG.txt

$(xai-floorplan-intervene-seeds-allSG): $(xai-floorplan-train-learning)
	@mkdir -p $(DATA_BASE_DIR)/$(FLOORPLAN_XAI_BASENAME)/results/$(EXPERIMENT_NAME)
	@$(DOCKER_PYTHON) -m scripts.explainability_train_eval \
		$(FLOORPLAN_EVAL_ARGS) \
		$(SIM_ROBOT_ARGS) \
		$(INTERP_ARGS) \
		--do_intervene \
	 	--current_seed $(shell echo $@ | grep -Eo '[0-9]+' | tail -1) \
		--save_dir /data/$(FLOORPLAN_XAI_BASENAME)/results/$(EXPERIMENT_NAME) \
		--logfile_name logfile_intervene_allSG.txt \

## ==== Results & Plotting ====
.PHONY: xai-process-results
xai-process-results:
	@echo "==== Maze Results ===="
	@$(DOCKER_PYTHON) -m scripts.explainability_results \
		--data_file /data/$(MAZE_XAI_BASENAME)/results/base_allSG/logfile_final.txt \
			/data/$(MAZE_XAI_BASENAME)/results/base_4SG/logfile_final.txt \
			/data/$(MAZE_XAI_BASENAME)/results/base_0SG/logfile_final.txt \
		--output_image_file /data/maze_results.png
	@echo "==== Floorplan Results ===="
	@$(DOCKER_PYTHON) -m scripts.explainability_results \
		--data_file /data/$(FLOORPLAN_XAI_BASENAME)/results/base_allSG/logfile_final.txt \
			/data/$(FLOORPLAN_XAI_BASENAME)/results/base_4SG/logfile_final.txt \
			/data/$(FLOORPLAN_XAI_BASENAME)/results/base_0SG/logfile_final.txt \
		--output_image_file /data/floorplan_results.png
	@echo "==== Floorplan Intervention Results ===="
	@$(DOCKER_PYTHON) -m scripts.explainability_results \
		--data_file /data/$(FLOORPLAN_XAI_BASENAME)/results/base_4SG/logfile_intervene_4SG.txt \
			/data/$(FLOORPLAN_XAI_BASENAME)/results/base_4SG/logfile_intervene_allSG.txt \
		--do_intervene \
		--xpassthrough $(XPASSTHROUGH) \
		--output_image_file /data/floorplan_intervene_results.png \

.PHONY: xai-explanations
xai-explanations:
	@mkdir -p $(DATA_BASE_DIR)/explanations/
	@$(DOCKER_PYTHON) -m scripts.explainability_train_eval \
	 	$(MAZE_EVAL_ARGS) \
	 	$(SIM_ROBOT_ARGS) \
	 	$(INTERP_ARGS) \
		--do_explain \
		--explain_at 20 \
	 	--sp_limit_num 4 \
	  	--current_seed 1037 \
	 	--save_dir /data/explanations/ \
	 	--logdir /data/$(MAZE_XAI_BASENAME)/training/base_0SG
	@$(DOCKER_PYTHON) -m scripts.explainability_train_eval \
		$(FLOORPLAN_EVAL_ARGS) \
		$(SIM_ROBOT_ARGS) \
		$(INTERP_ARGS) \
		--do_explain \
		--explain_at 289 \
		--sp_limit_num 4 \
	 	--current_seed 11591 \
		--save_dir /data/explanations/ \
		--logdir /data/$(FLOORPLAN_XAI_BASENAME)/training/base_4SG


## ==== Some helper targets to run code individually ====
# Maze
xai-maze-data-gen: $(xai-maze-data-gen-seeds)
xai-maze-train: $(xai-maze-train-learning)
xai-maze-eval: $(xai-maze-eval-seeds)
xai-maze: xai-maze-eval

# Floorplan
xai-floorplan-data-gen: $(xai-floorplan-data-gen-seeds)
xai-floorplan-train: $(xai-floorplan-train-learning)
xai-floorplan-eval: $(xai-floorplan-eval-seeds)
xai-floorplan: xai-floorplan-eval

xai-floorplan-data-gen: $(xai-floorplan-data-gen-seeds)
xai-floorplan-intervene: $(xai-floorplan-intervene-seeds-allSG) $(xai-floorplan-intervene-seeds-4SG)
