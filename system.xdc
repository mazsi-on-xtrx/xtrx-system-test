
set_property -dict {PACKAGE_PIN R19  IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports PWRNRST]
set_property -dict {PACKAGE_PIN U15  IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports SDA0]
set_property -dict {PACKAGE_PIN U14  IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports SCL0]
set_property -dict {PACKAGE_PIN N1   IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports SDA1]
set_property -dict {PACKAGE_PIN M1   IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports SCL1]

set_property -dict {PACKAGE_PIN L2   IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports GPIO[11]]
set_property -dict {PACKAGE_PIN K2   IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports GPIO[10]]
set_property -dict {PACKAGE_PIN J1   IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports GPIO[9]]
set_property -dict {PACKAGE_PIN H1   IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports GPIO[8]]
set_property -dict {PACKAGE_PIN N3   IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports GPIO[7]]
set_property -dict {PACKAGE_PIN G2   IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports GPIO[6]]
set_property -dict {PACKAGE_PIN M2   IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports GPIO[5]]
set_property -dict {PACKAGE_PIN G3   IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports GPIO[4]]
set_property -dict {PACKAGE_PIN J2   IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports GPIO[3]]
set_property -dict {PACKAGE_PIN H2   IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports GPIO[2]]
set_property -dict {PACKAGE_PIN L3   IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports GPIO[1]]
set_property -dict {PACKAGE_PIN M3   IOSTANDARD LVCMOS33  PULLUP TRUE} [get_ports GPIO[0]]

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

