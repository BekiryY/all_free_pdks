# OpenROAD-flow-scripts platform for the OSU TSMC 0.25 um standard cells
# (stineje/MOSIS_SCMOS, osu025_stdcells). Written for all_free_pdks; the cell
# data itself is fetched from upstream by install_pdks.py.
#
# Limitations of this library (2004 release):
#   - no tie-hi/tie-lo cells: designs that synthesize constant 0/1 nets fail
#   - no tap/endcap cells, no clock-gating or adder cells
#   - one LEF holds both the technology and the cells; install_pdks.py derives
#     osu025_tech.lef (tech only) from it for TECH_LEF
#   - RC values below are rough estimates from the LEF, not foundry data

export PROCESS = 250

#-----------------------------------------------------
# Tech/Libs
#-----------------------------------------------------
export TECH_LEF = $(PLATFORM_DIR)/osu025_tech.lef
export SC_LEF = $(PLATFORM_DIR)/osu025_stdcells.lef
export LIB_FILES = $(PLATFORM_DIR)/osu025_stdcells.lib $(ADDITIONAL_LIBS)
export GDS_FILES = $(PLATFORM_DIR)/osu025_stdcells.gds $(ADDITIONAL_GDS)

export DONT_USE_CELLS = FILL
export FILL_CELLS ?= FILL

#-----------------------------------------------------
# Yosys
#-----------------------------------------------------
# The library has no tie cells; these names are never instantiated as long as
# synthesis produces no constant nets.
export TIEHI_CELL_AND_PORT = TIEHI Y
export TIELO_CELL_AND_PORT = TIELO Y
export SKIP_REPAIR_TIE_FANOUT ?= 1

export MIN_BUF_CELL_AND_PORTS = BUFX2 A Y
export ABC_DRIVER_CELL = BUFX2
# Liberty capacitance unit is pF
export ABC_LOAD_IN_FF = 0.08

#-----------------------------------------------------
# Floorplan
#-----------------------------------------------------
export PLACE_SITE = core

export IO_PLACER_H ?= metal3
export IO_PLACER_V ?= metal2

export PDN_TCL ?= $(PLATFORM_DIR)/pdn.tcl
export MACRO_PLACE_HALO ?= 15 15

#-----------------------------------------------------
# Place
#-----------------------------------------------------
export PLACE_DENSITY ?= 0.50

#-----------------------------------------------------
# Route
#-----------------------------------------------------
export MIN_ROUTING_LAYER = metal2
export MIN_CLK_ROUTING_LAYER = metal2
export MAX_ROUTING_LAYER = metal5

export FASTROUTE_TCL ?= $(PLATFORM_DIR)/fastroute.tcl

# KLayout technology (LEF/DEF -> GDS layer map) for the final GDS merge
export KLAYOUT_TECH_FILE = $(PLATFORM_DIR)/osu025.lyt

#-----------------------------------------------------
# IR drop
#-----------------------------------------------------
export PWR_NETS_VOLTAGES ?= VDD 2.5
export GND_NETS_VOLTAGES ?= VSS 0.0
export IR_DROP_LAYER ?= metal1
