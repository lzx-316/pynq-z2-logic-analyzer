# PYNQ-Z2 Pmod A input pins.
# The Block Design external port must be named exactly "probe_i".
# If Vivado generated "probe_i_0", rename the external port before synthesis.

set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports {probe_i[0]}]
set_property -dict {PACKAGE_PIN Y19 IOSTANDARD LVCMOS33} [get_ports {probe_i[1]}]
set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS33} [get_ports {probe_i[2]}]
set_property -dict {PACKAGE_PIN Y17 IOSTANDARD LVCMOS33} [get_ports {probe_i[3]}]
