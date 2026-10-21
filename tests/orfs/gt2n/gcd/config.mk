# gcd on GT2N. Quick smoke test only: gcd is too small for GT2N's PDN pitches,
# so the power grid is fragmentary; see tests/orfs/gt2n/aes for a real mesh.
export DESIGN_NICKNAME = gcd
export DESIGN_NAME = gcd
export PLATFORM    = gt2n

export VERILOG_FILES = $(DESIGN_HOME)/src/$(DESIGN_NAME)/gcd.v
export SDC_FILE      = $(dir $(DESIGN_CONFIG))/constraint.sdc

# gcd is tiny at 2 nm; GT2N's PDN straps need a core wider than ~20 um
export CORE_UTILIZATION = 5
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN = 5.04
# Denser placement left 3 M1/M2 spacing violations in detailed routing
export PLACE_DENSITY ?= 0.40

# PLATFORM_DIR is not defined yet while ORFS reads this file
include $(dir $(firstword $(MAKEFILE_LIST)))platforms/gt2n/all_free_pdks_w31_svtlvt.mk
