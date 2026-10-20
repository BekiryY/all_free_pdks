export DESIGN_NICKNAME = gcd
export DESIGN_NAME = gcd
export PLATFORM    = osu025

export VERILOG_FILES = $(DESIGN_HOME)/src/$(DESIGN_NAME)/gcd.v
export SDC_FILE      = $(dir $(DESIGN_CONFIG))/constraint.sdc

export CORE_UTILIZATION = 40
export PLACE_DENSITY    = 0.60
