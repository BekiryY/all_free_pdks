# Liberty units are pF, kOhm. Resistance from the LEF (0.07 ohm/sq at the
# minimum width); capacitance is a rough 0.25 um estimate (~0.2 fF/um).
set_layer_rc -layer metal1 -resistance 1.56e-04 -capacitance 2.0e-04
set_layer_rc -layer metal2 -resistance 1.56e-04 -capacitance 2.0e-04
set_layer_rc -layer metal3 -resistance 1.56e-04 -capacitance 2.0e-04
set_layer_rc -layer metal4 -resistance 1.56e-04 -capacitance 2.0e-04
set_layer_rc -layer metal5 -resistance 1.17e-04 -capacitance 2.0e-04

set_wire_rc -signal -layer metal2
set_wire_rc -clock -layer metal3
