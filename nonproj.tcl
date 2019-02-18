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

read_ip pcie_7x_0.xci
generate_target all [get_ips]
synth_ip [get_ips]

generate_target example [get_files pcie_7x_0.xci]
read_vhdl example_design/EP_MEM.vhd
read_vhdl example_design/PIO.vhd
read_vhdl example_design/PIO_EP.vhd
read_vhdl example_design/PIO_EP_MEM_ACCESS.vhd
read_vhdl example_design/PIO_RX_ENGINE.vhd
read_vhdl example_design/PIO_TO_CTRL.vhd
read_vhdl example_design/PIO_TX_ENGINE.vhd
read_vhdl example_design/pcie_app_7x.vhd
read_vhdl example_design/xilinx_pcie_2_1_ep_7x.vhd

synth_design -top top

opt_design
place_design
route_design

report_timing_summary -max_paths 10 -file top_timing_summary_routed.rpt -warn_on_violation
report_utilization -file top_utilization_placed.rpt
report_io -file top_io_placed.rpt

write_bitstream -force -bin_file top.bit

