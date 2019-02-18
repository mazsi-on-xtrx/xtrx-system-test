
set_property -dict {PACKAGE_PIN N18  IOSTANDARD LVCMOS33} [get_ports SYSLED]

# 65 MHz nominal, +/- 50%  =>  32.5 - 97.5 MHz  =>  100 MHz
create_clock -name sysclk -period 10.00 [get_pins startup/CFGMCLK]

