# Xilinx design constraints (XDC) file for Kria KV Carrier Card - Rev 1

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.PUDC_B Pulldown [current_design] 

set_property PACKAGE_PIN J12 [get_ports RPI_LED_EN]
set_property IOSTANDARD LVCMOS33 [get_ports RPI_LED_EN]

set_property PACKAGE_PIN F11 [get_ports RPI_PWR_EN]
set_property IOSTANDARD  LVCMOS33 [get_ports RPI_PWR_EN]
set_property SLEW SLOW [get_ports RPI_PWR_EN]
set_property DRIVE 4   [get_ports RPI_PWR_EN]

set_property PACKAGE_PIN F10 [get_ports {IIC_CAM_sda_io}]
set_property PACKAGE_PIN G11 [get_ports {IIC_CAM_scl_io}]
set_property IOSTANDARD LVCMOS33 [get_ports {IIC_CAM_sda_io}]
set_property IOSTANDARD LVCMOS33 [get_ports {IIC_CAM_scl_io}]
set_property SLEW SLOW [get_ports {IIC_CAM_sda_io}]
set_property SLEW SLOW [get_ports {IIC_CAM_scl_io}]
set_property DRIVE 4   [get_ports {IIC_CAM_sda_io}]
set_property DRIVE 4   [get_ports {IIC_CAM_scl_io}]

set_property -dict {PACKAGE_PIN J11 IOSTANDARD LVCMOS33} [get_ports IAS0_EN]
set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVCMOS33} [get_ports IAS1_EN]

# RPI MIPI CSI
set_property IOSTANDARD  MIPI_DPHY_DCI [get_ports "mipi_phy_if_0_data_p[1]"]
set_property IOSTANDARD  MIPI_DPHY_DCI [get_ports "mipi_phy_if_0_data_n[1]"]
set_property IOSTANDARD  MIPI_DPHY_DCI [get_ports "mipi_phy_if_0_data_p[0]"]
set_property IOSTANDARD  MIPI_DPHY_DCI [get_ports "mipi_phy_if_0_data_n[0]"]
set_property IOSTANDARD  MIPI_DPHY_DCI [get_ports "mipi_phy_if_0_clk_p"]
set_property IOSTANDARD  MIPI_DPHY_DCI [get_ports "mipi_phy_if_0_clk_n"]
set_property DIFF_TERM_ADV TERM_100 [get_ports "mipi_phy_if_0_clk_n"]
set_property DIFF_TERM_ADV TERM_100 [get_ports "mipi_phy_if_0_clk_p"]
set_property DIFF_TERM_ADV TERM_100 [get_ports "mipi_phy_if_0_data_n[0]"]
set_property DIFF_TERM_ADV TERM_100 [get_ports "mipi_phy_if_0_data_p[0]"]
set_property DIFF_TERM_ADV TERM_100 [get_ports "mipi_phy_if_0_data_n[1]"]
set_property DIFF_TERM_ADV TERM_100 [get_ports "mipi_phy_if_0_data_p[1]"]

#set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
#set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
#set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
#connect_debug_port dbg_hub/clk [get_nets clk]
#create_clock -period 5.000 -name axi_clk -waveform {0.000 2.500} [get_nets bd_i/cpu_clk/clk_out1]
