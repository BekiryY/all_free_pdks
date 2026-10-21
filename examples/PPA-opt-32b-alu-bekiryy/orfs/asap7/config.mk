# ALU_TOP on asap7 with OpenROAD-flow-scripts. Run with:
#   examples/PPA-opt-32b-alu-bekiryy/run.sh asap7
export DESIGN_NICKNAME = alu
export DESIGN_NAME = ALU_TOP
export PLATFORM    = asap7

ALU_DIR = $(abspath $(dir $(DESIGN_CONFIG))../..)
export VERILOG_FILES = $(sort $(wildcard $(ALU_DIR)/rtl/*.sv))
export SDC_FILE      = $(ALU_DIR)/constraints/alu.sdc
# Clock period in the platform's time unit (ps)
export ALU_CLOCK_PERIOD = 550

export CORE_UTILIZATION = 40
export PLACE_DENSITY ?= 0.60

