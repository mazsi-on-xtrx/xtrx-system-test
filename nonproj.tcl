#
# based on 7 Series Integrated Block for PCIe v3.3, PG054, December 5, 2018
#

#read_verilog file.v
read_vhdl xtrxinitrom.vhd
read_vhdl xtrxinit.vhd
read_vhdl top.vhd
read_xdc system.xdc
read_xdc bitconfig.xdc

set_property TARGET_LANGUAGE VHDL [current_project]
set_property PART xc7a35tcpg236-2 [current_project]

#read_ip file.xci

synth_design -top top

opt_design
place_design
route_design

report_timing_summary -max_paths 10 -file top_timing_summary_routed.rpt -warn_on_violation
report_utilization -file top_utilization_placed.rpt
report_io -file top_io_placed.rpt

write_bitstream -force -bin_file top.bit

