
set_property -dict {PACKAGE_PIN U15  IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports SDA0]
set_property -dict {PACKAGE_PIN U14  IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports SCL0]
set_property -dict {PACKAGE_PIN N1   IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports SDA1]
set_property -dict {PACKAGE_PIN M1   IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports SCL1]

set_property -dict {PACKAGE_PIN L2   IOSTANDARD LVCMOS33  DRIVE 4  SLEW SLOW  PULLUP TRUE} [get_ports GPIO[11]]
set_property -dict {PACKAGE_PIN K2   IOSTANDARD LVCMOS33  DRIVE 4  SLEW SLOW  PULLUP TRUE} [get_ports GPIO[10]]
set_property -dict {PACKAGE_PIN J1   IOSTANDARD LVCMOS33  DRIVE 4  SLEW SLOW  PULLUP TRUE} [get_ports GPIO[9]]
set_property -dict {PACKAGE_PIN H1   IOSTANDARD LVCMOS33  DRIVE 4  SLEW SLOW  PULLUP TRUE} [get_ports GPIO[8]]
set_property -dict {PACKAGE_PIN N3   IOSTANDARD LVCMOS33  DRIVE 4  SLEW SLOW  PULLUP TRUE} [get_ports GPIO[7]]
set_property -dict {PACKAGE_PIN G2   IOSTANDARD LVCMOS33  DRIVE 4  SLEW SLOW  PULLUP TRUE} [get_ports GPIO[6]]
set_property -dict {PACKAGE_PIN M2   IOSTANDARD LVCMOS33  DRIVE 4  SLEW SLOW  PULLUP TRUE} [get_ports GPIO[5]]
set_property -dict {PACKAGE_PIN G3   IOSTANDARD LVCMOS33  DRIVE 4  SLEW SLOW  PULLUP TRUE} [get_ports GPIO[4]]
set_property -dict {PACKAGE_PIN J2   IOSTANDARD LVCMOS33  DRIVE 4  SLEW SLOW  PULLUP TRUE} [get_ports GPIO[3]]
set_property -dict {PACKAGE_PIN H2   IOSTANDARD LVCMOS33  DRIVE 4  SLEW SLOW  PULLUP TRUE} [get_ports GPIO[2]]
set_property -dict {PACKAGE_PIN L3   IOSTANDARD LVCMOS33  DRIVE 4  SLEW SLOW  PULLUP TRUE} [get_ports GPIO[1]]
set_property -dict {PACKAGE_PIN M3   IOSTANDARD LVCMOS33  DRIVE 4  SLEW SLOW  PULLUP TRUE} [get_ports GPIO[0]]

set_property -dict {PACKAGE_PIN R19  IOSTANDARD LVCMOS33} [get_ports CLK026EN]
set_property -dict {PACKAGE_PIN V17  IOSTANDARD LVCMOS33} [get_ports CLK026SEL]
set_property -dict {PACKAGE_PIN N17  IOSTANDARD LVCMOS33} [get_ports CLK026IN]

set_property -dict {PACKAGE_PIN M18  IOSTANDARD LVCMOS33} [get_ports USBNRST]
set_property -dict {PACKAGE_PIN E19  IOSTANDARD LVCMOS33} [get_ports USBREF026]
set_property -dict {PACKAGE_PIN C16  IOSTANDARD LVCMOS33} [get_ports USBCLK]
set_property -dict {PACKAGE_PIN C17  IOSTANDARD LVCMOS33  SLEW FAST} [get_ports USBSTP]
set_property -dict {PACKAGE_PIN B18  IOSTANDARD LVCMOS33  SLEW FAST} [get_ports USBDIR]
set_property -dict {PACKAGE_PIN A18  IOSTANDARD LVCMOS33  SLEW FAST} [get_ports USBNXT]
set_property -dict {PACKAGE_PIN C15  IOSTANDARD LVCMOS33  SLEW FAST} [get_ports USBD[7]]
set_property -dict {PACKAGE_PIN A14  IOSTANDARD LVCMOS33  SLEW FAST} [get_ports USBD[6]]
set_property -dict {PACKAGE_PIN A15  IOSTANDARD LVCMOS33  SLEW FAST} [get_ports USBD[5]]
set_property -dict {PACKAGE_PIN B15  IOSTANDARD LVCMOS33  SLEW FAST} [get_ports USBD[4]]
set_property -dict {PACKAGE_PIN A16  IOSTANDARD LVCMOS33  SLEW FAST} [get_ports USBD[3]]
set_property -dict {PACKAGE_PIN A17  IOSTANDARD LVCMOS33  SLEW FAST} [get_ports USBD[1]]
set_property -dict {PACKAGE_PIN B16  IOSTANDARD LVCMOS33  SLEW FAST} [get_ports USBD[2]]
set_property -dict {PACKAGE_PIN B17  IOSTANDARD LVCMOS33  SLEW FAST} [get_ports USBD[0]]

set_property -dict {PACKAGE_PIN U19  IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports LMSNRST]
set_property -dict {PACKAGE_PIN W13  IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports SS1]
set_property -dict {PACKAGE_PIN W14  IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports SCK1]
set_property -dict {PACKAGE_PIN W15  IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports MISO1]
set_property -dict {PACKAGE_PIN W16  IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports MOSI1]

set_property -dict {PACKAGE_PIN B6} [get_ports PCIERXP[0]]
set_property -dict {PACKAGE_PIN B8} [get_ports PCIECLKP]

set_property -dict {PACKAGE_PIN N18  IOSTANDARD LVCMOS33} [get_ports SYSLED]

# 65 MHz nominal, +/- 50%  =>  32.5 - 97.5 MHz  =>  100 MHz
create_clock -name sysclk -period 10.00 [get_pins startup/CFGMCLK]

create_clock -name pcieclk -period 10 [get_ports PCIECLKP]

# 26 MHz VCTXCO - make it 26.315 to cover all varations
create_clock -name clk026 -period 38.00 [get_ports CLK026IN]

# 60 MHz clk returned by USB PHY over ULPI interface
create_clock -name usbclk -period 16.666 [get_ports USBCLK]

# input min and output min are not stated in specification, so assuming 0ns
set_input_delay -clock usbclk -max 9.0 [get_ports {USBDIR USBNXT USBD[*]}]
set_input_delay -clock usbclk -min 0.0 [get_ports {USBDIR USBNXT USBD[*]}]
set_output_delay -clock usbclk -max 6.0 [get_ports {USBSTP USBD[*]}]
set_output_delay -clock usbclk -min 0.0 [get_ports {USBSTP USBD[*]}]

# whenever USBDIR changes, there is an extra USBCLK time for turnaround
set_multicycle_path -from [get_ports USBDIR] -to [get_port USBD[*]] -setup 2
set_multicycle_path -from [get_ports USBDIR] -to [get_port USBD[*]] -hold 1


