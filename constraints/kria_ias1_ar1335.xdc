# Xilinx design constraints (XDC) file for Kria KV Carrier Card - Rev 1

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.PUDC_B Pulldown [current_design] 

set_property PACKAGE_PIN F10 [get_ports {IIC_CAM_sda_io}]     ;# Bank  45 VCCO - som240_1_b13 - IO_L5N_HDGC_45 (som240_1_d17)
set_property PACKAGE_PIN G11 [get_ports {IIC_CAM_scl_io}]     ;# Bank  45 VCCO - som240_1_b13 - IO_L5P_HDGC_45 (som240_1_d16)
set_property IOSTANDARD LVCMOS33 [get_ports {IIC_CAM_sda_io}] ;# Net name HDA01 (som240_1_d17)
set_property IOSTANDARD LVCMOS33 [get_ports {IIC_CAM_scl_io}] ;# Net name HDA00_CC (som240_1_d16)
set_property SLEW SLOW [get_ports {IIC_CAM_sda_io}]           ;# Net name HDA01
set_property SLEW SLOW [get_ports {IIC_CAM_scl_io}]           ;# Net name HDA00_CC
set_property DRIVE 4   [get_ports {IIC_CAM_sda_io}]           ;# Net name HDA01
set_property DRIVE 4   [get_ports {IIC_CAM_scl_io}]           ;# Net name HDA00_CC

set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVCMOS33} [get_ports "IAS1_RST[0]"]

# IAS1 MIPI CSI
set_property IOSTANDARD  MIPI_DPHY_DCI [get_ports "mipi_phy_if_0_data_p[3]"]
set_property IOSTANDARD  MIPI_DPHY_DCI [get_ports "mipi_phy_if_0_data_n[3]"]
set_property IOSTANDARD  MIPI_DPHY_DCI [get_ports "mipi_phy_if_0_data_p[2]"]
set_property IOSTANDARD  MIPI_DPHY_DCI [get_ports "mipi_phy_if_0_data_n[2]"]
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
set_property DIFF_TERM_ADV TERM_100 [get_ports "mipi_phy_if_0_data_n[2]"]
set_property DIFF_TERM_ADV TERM_100 [get_ports "mipi_phy_if_0_data_p[2]"]
set_property DIFF_TERM_ADV TERM_100 [get_ports "mipi_phy_if_0_data_n[3]"]
set_property DIFF_TERM_ADV TERM_100 [get_ports "mipi_phy_if_0_data_p[3]"]

#set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
#set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
#set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
#connect_debug_port dbg_hub/clk [get_nets clk]
#create_clock -period 5.000 -name axi_clk -waveform {0.000 2.500} [get_nets bd_i/cpu_clk/clk_out1]
