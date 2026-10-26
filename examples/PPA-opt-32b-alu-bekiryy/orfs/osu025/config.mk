# ALU_TOP on osu025 with OpenROAD-flow-scripts. Run with:
#   examples/PPA-opt-32b-alu-bekiryy/run.sh osu025
export DESIGN_NICKNAME = alu
export DESIGN_NAME = ALU_TOP
export PLATFORM    = osu025

ALU_DIR = $(abspath $(dir $(DESIGN_CONFIG))../..)
export VERILOG_FILES = $(sort $(wildcard $(ALU_DIR)/rtl/*.sv))
export SDC_FILE      = $(ALU_DIR)/constraints/alu.sdc
# Clock period in the platform's time unit (ns)
export ALU_CLOCK_PERIOD = 11

export CORE_UTILIZATION = 55
export PLACE_DENSITY ?= 0.65

