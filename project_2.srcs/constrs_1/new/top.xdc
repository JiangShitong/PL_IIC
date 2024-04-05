create_clock -period 10.000 [get_ports clk]
set_property -dict {PACKAGE_PIN Y9 IOSTANDARD LVCMOS33} [get_ports clk]

set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS33} [get_ports rst]

set_property -dict {PACKAGE_PIN Y11 IOSTANDARD LVCMOS33} [get_ports i2c_scl]
#set_property -dict { PULLUP false } [get_ports { i2c_scl }]
set_property -dict { PULLUP false } [get_ports { i2c_sda }]
set_property -dict {PACKAGE_PIN AA11 IOSTANDARD LVCMOS33} [get_ports i2c_sda]
set_property -dict { PULLDOWN false } [get_ports { i2c_sda }]
set_property -dict { PULLDOWN false } [get_ports { i2c_scl }]

set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports write_config]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports write_calibration]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS33} [get_ports set_current_address]
set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS33} [get_ports set_voltage_address]
set_property -dict {PACKAGE_PIN F21 IOSTANDARD LVCMOS33} [get_ports set_power_address]
set_property -dict {PACKAGE_PIN H22 IOSTANDARD LVCMOS33} [get_ports read_request]

