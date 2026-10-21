# ORFS's aes (aes_cipher_top) on GT2N: large enough for GT2N's PDN mesh.
export DESIGN_NICKNAME = aes
export DESIGN_NAME = aes_cipher_top
export PLATFORM    = gt2n

export VERILOG_FILES = $(sort $(wildcard $(DESIGN_HOME)/src/$(DESIGN_NICKNAME)/*.v))
export SDC_FILE      = $(dir $(DESIGN_CONFIG))/constraint.sdc

export ABC_AREA = 1
export CORE_UTILIZATION = 40
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN = 5.04
export PLACE_DENSITY ?= 0.50

# PLATFORM_DIR is not defined yet while ORFS reads this file
include $(dir $(firstword $(MAKEFILE_LIST)))platforms/gt2n/all_free_pdks_w31_svtlvt.mk
