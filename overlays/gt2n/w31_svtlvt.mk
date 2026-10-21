# all_free_pdks: shared ORFS settings for GT2N designs using the w31 SVT+LVT
# libraries and the frontside PDN. GT2N's platform config.mk is a minimal shim,
# so include this from your design config after setting the DESIGN_* variables:
#
#   export PLATFORM = gt2n
#   ...
#   include $(dir $(firstword $(MAKEFILE_LIST)))platforms/gt2n/all_free_pdks_w31_svtlvt.mk
#
# (PLATFORM_DIR is not defined yet when ORFS reads a design config.)
#
# Adapted from GT2N's ORFS example (AES_128 .../1000ps_fspdn_tapm3_rdl_dense_u40_c80);
# its PDN scripts are used as shipped. Their strap pitches are 6-12.8 um, so
# the core should be at least ~40 um wide for the mesh to form.

GT2N_EXAMPLE = $(realpath $(PLATFORM_DIR))/../../../../AES_128/GT2_2nm_PDK/03_spnr/tt/w31_svtlvt/1000ps_fspdn_tapm3_rdl_dense_u40_c80

export PROCESS = 2

export TECH_LEF = $(PLATFORM_DIR)/techlib/gt2_fspdn_tech.lef
export SC_LEF = $(PLATFORM_DIR)/lef/gt2_6t_w31_svt.lef
export ADDITIONAL_LEFS = $(PLATFORM_DIR)/lef/gt2_6t_w31_lvt.lef
export LIB_FILES = $(PLATFORM_DIR)/lib/gt2_6t_w31_svt_tt_0p7v25c.lib \
                   $(PLATFORM_DIR)/lib/gt2_6t_w31_lvt_tt_0p7v25c.lib
export GDS_FILES = $(wildcard $(PLATFORM_DIR)/gds/*w31_svt.gds $(PLATFORM_DIR)/gds/*w31_lvt.gds)

export DONT_USE_CELLS = gt2_6t_tapfspdn_w31_lvt
export FILL_CELLS ?= gt2_6t_filler_w31_lvt
export TIEHI_CELL_AND_PORT = gt2_6t_tiehigh_w31_lvt Y
export TIELO_CELL_AND_PORT = gt2_6t_tielow_w31_lvt Y
export MIN_BUF_CELL_AND_PORTS = gt2_6t_buf_x1_w31_lvt A Y
export LATCH_MAP_FILE :=
export CLKGATE_MAP_FILE :=
export ADDER_MAP_FILE :=
export ABC_DRIVER_CELL = gt2_6t_buf_x1_w31_svt
export ABC_LOAD_IN_FF = 5
export MATCH_CELL_FOOTPRINT = 1

export PLACE_SITE = gt2_6t
export IO_PLACER_H ?= M2
export IO_PLACER_V ?= M3
export PDN_TCL ?= $(GT2N_EXAMPLE)/pdn_no_bpr_m2m3_rdl_dense.tcl
export GT2N_POST_PDN_TCL = $(GT2N_EXAMPLE)/post_pdn_tap_to_m3.tcl
export POST_PDN_TCL ?= $(PLATFORM_DIR)/all_free_pdks_post_pdn.tcl
export TAP_CELL_NAME = gt2_6t_tapfspdn_w31_lvt
export TAPCELL_DISTANCE ?= 28
export TAPCELL_TCL ?= $(PLATFORM_DIR)/tapcell.tcl

export CELL_PAD_IN_SITES_GLOBAL_PLACEMENT ?= 1
export CELL_PAD_IN_SITES_DETAIL_PLACEMENT ?= 1

export ROUTING_LAYER_ADJUSTMENT ?= 0.25
export MIN_ROUTING_LAYER ?= M1
export MIN_CLK_ROUTING_LAYER ?= M3
export MAX_ROUTING_LAYER ?= M9
export FASTROUTE_TCL ?= $(PLATFORM_DIR)/fastroute.tcl

export KLAYOUT_TECH_FILE = $(PLATFORM_DIR)/$(PLATFORM).lyt
export GDS_LAYER_MAP = $(PLATFORM_DIR)/techlib/gt2_techfile.layermap
export FILL_CONFIG = $(PLATFORM_DIR)/fill.json
export RCX_RULES = $(PLATFORM_DIR)/rcx_patterns.rules
export LAYER_PARASITICS_FILE ?= $(PLATFORM_DIR)/setRC_fspdn.tcl
export SET_RC_TCL ?= $(PLATFORM_DIR)/setRC_fspdn.tcl
export MAKE_TRACKS ?= $(PLATFORM_DIR)/make_tracks_fspdn.tcl

export PWR_NETS_VOLTAGES ?= VDD 0.7
export GND_NETS_VOLTAGES ?= VSS 0.0
export IR_DROP_LAYER ?= M1
export PDNSIM_SOURCE_TYPE ?= STRAPS

export KLAYOUT_DRC_FILE = $(PLATFORM_DIR)/$(PLATFORM).lydrc
