set_property PACKAGE_PIN F14 [get_ports board_clk_i]
create_clock -period 83.333 -name SYSTEM_CLOCK [get_ports board_clk_i]

set_property PACKAGE_PIN A2 [get_ports board_rst_i]
set_property PACKAGE_PIN A3 [get_ports ddr_aresetn]
set_property IOSTANDARD LVCMOS18 [get_ports board_rst_i]
set_property IOSTANDARD LVCMOS18 [get_ports ddr_aresetn]
set_property IOSTANDARD LVCMOS18 [get_ports board_clk_i]

### arty S7 specific settings

## Configuration options, can be used for all designs
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

## SW3 is assigned to a pin M5 in the 1.35v bank. This pin can also be used as
## the VREF for BANK 34. To ensure that SW3 does not define the reference voltage
## and to be able to use this pin as an ordinary I/O the following property must
## be set to enable an internal VREF for BANK 34. Since a 1.35v supply is being
## used the internal reference is set to half that value (i.e. 0.675v). Note that
## this property must be set even if SW3 is not used in the design.
set_property INTERNAL_VREF 0.675 [get_iobanks 34]

