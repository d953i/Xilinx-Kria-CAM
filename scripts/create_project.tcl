
# source D:/Projects/_github/Xilinx-Kria-CAM/scripts/create_project.tcl

########################### Project Configuration ##############################

#set CAMERA RPI-IMX219
#set CAMERA IAS-AR1335
set CAMERA ISP-AR1335

#set MODE FullHD
set MODE 4K-UHD

set JTAG2AXI 1
set EMMC 1

######################## Project Global Variables ##############################
set OS [lindex $tcl_platform(os) 0]

set ProjectPart xck26-sfvc784-2LV-c
set ProjectBoard xilinx.com:kv260_som:part0:1.3
set BoardConnections {som240_1_connector xilinx.com:kv260_carrier:som240_1_connector:1.3}

set CAM_INTERFACE IAS
if {$::CAMERA == "RPI-IMX219"} {
    set CAM_INTERFACE RPI 
} elseif {$::CAMERA == "ISP-AR1335"} {
    set CAM_INTERFACE ISP
}

#### Version Checking ##########################################################
set scriptName [file split [file rootname [ info script ]]]
puts stdout "scriptName is $scriptName"

set NameFields [split [lindex $scriptName end] _]
puts stdout "NameFields is $NameFields"
set Major [lindex $NameFields end-1]
puts stdout "Major is $Major"
set Minor [lindex $NameFields end]
puts stdout "Minor is $Minor"
set ToolsVersion [version -short]

if {[string compare [version -short] 2023.2] != 0} {
    return -code error [format "Unsupported Vivado version. Try 2023.2"]
}

#### Project Local Variables - Don't touch ! ###################################
set scrPath [file dirname [file normalize [info script]]]
set srcRoot [join [lrange [file split [file dirname [file normalize [info script]]]] 0 end-1] "/"]
#set srcRoot [join [lrange [file split [file dirname [info script]]] 0 end-1] "/"]

puts stdout "scrPath is ${scrPath}"
puts stdout "srcRoot is ${srcRoot}"

#return -code 1

#set origin_dir "."
set ProjectName Kria-${CAMERA}
set ProjectFolder $ProjectName
set ProjectIPRepos ${srcRoot}/_ip_repos/

#Remove unnecessary files.
set file_list [glob -nocomplain webtalk*.*]
foreach name $file_list {
    file delete $name
}

#Delete old project if folder already exists.
if {[file exists .Xil]} { 
    file delete -force .Xil
}

#Delete old project if folder already exists.
if {[file exists "$ProjectFolder"]} { 
    file delete -force $ProjectFolder
}

#return -code 1

variable GPIO0_count 0
global PS2PL_N_MI
global PS2PL_N_SI
set PS2PL_N_MI 0
set PS2PL_N_SI 1

proc connect_ps2pl {side block port {clk_source ""} {clk_name ""} {rsr_source ""} {rst_name ""}} {

    if {"" == [get_bd_cells ps2pl]} {
    
        #set_property -dict [list CONFIG.PSU__USE__M_AXI_GP2 {1} CONFIG.PSU__MAXIGP2__DATA_WIDTH {64}] [get_bd_cells cpu]
        set_property -dict [list CONFIG.PSU__USE__M_AXI_GP0 {1} CONFIG.PSU__MAXIGP0__DATA_WIDTH {128}] [get_bd_cells cpu]
        connect_bd_net [get_bd_pins cpu/pl_clk0] [get_bd_pins cpu/maxihpm1_fpd_aclk]
        
        create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 ps2pl
        set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] [get_bd_cells ps2pl]
        connect_bd_net [get_bd_pins cpu/pl_clk0] [get_bd_pins ps2pl/ACLK]
        connect_bd_net [get_bd_pins cpu_rst/interconnect_aresetn] [get_bd_pins ps2pl/ARESETN]
        connect_bd_intf_net [get_bd_intf_pins cpu/M_AXI_HPM1_FPD] -boundary_type upper [get_bd_intf_pins ps2pl/S00_AXI]

        connect_bd_net [get_bd_pins cpu/pl_clk0] [get_bd_pins ps2pl/S00_ACLK]
        connect_bd_net [get_bd_pins cpu_rst/peripheral_aresetn] [get_bd_pins ps2pl/S00_ARESETN]
    
    }

    puts stdout "PS2PL_N_MI is $::PS2PL_N_MI"
    puts stdout "PS2PL_N_SI is $::PS2PL_N_SI"
    
    if {$side == "MASTER"} {
        set M2S_M1AXI M[format %02u $::PS2PL_N_MI]_AXI
        set M2S_M1CLK M[format %02u $::PS2PL_N_MI]_ACLK
        set M2S_M1RST M[format %02u $::PS2PL_N_MI]_ARESETN
        set_property CONFIG.NUM_MI [expr {$::PS2PL_N_MI + 1}] [get_bd_cells ps2pl]
        connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ps2pl/$M2S_M1AXI] [get_bd_intf_pins $block/$port]
        
        if {"" == $clk_source} {
            connect_bd_net [get_bd_pins cpu/pl_clk0] [get_bd_pins ps2pl/$M2S_M1CLK]
            connect_bd_net [get_bd_pins cpu_rst/peripheral_aresetn] [get_bd_pins ps2pl/$M2S_M1RST]
        } else {
            connect_bd_net [get_bd_pins $clk_source/$clk_name] [get_bd_pins ps2pl/$M2S_M1CLK]
            connect_bd_net [get_bd_pins $rsr_source/$rst_name] [get_bd_pins ps2pl/$M2S_M1RST]
        }
        
        set ::PS2PL_N_MI [expr $::PS2PL_N_MI + 1]
        
    } else {
        set M2S_M1AXI S[format %02u $::PS2PL_N_SI]_AXI
        set M2S_M1CLK S[format %02u $::PS2PL_N_SI]_ACLK
        set M2S_M1RST S[format %02u $::PS2PL_N_SI]_ARESETN
        set_property CONFIG.NUM_SI [expr {$::PS2PL_N_SI + 1}] [get_bd_cells ps2pl]
        connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ps2pl/$M2S_M1AXI] [get_bd_intf_pins $block/$port]
        connect_bd_net [get_bd_pins cpu/pl_clk0] [get_bd_pins ps2pl/$M2S_M1CLK]
        connect_bd_net [get_bd_pins cpu_rst/peripheral_aresetn] [get_bd_pins ps2pl/$M2S_M1RST]
        set ::PS2PL_N_SI [expr $::PS2PL_N_SI + 1]
    }
}

global PL2PS_N_MI
global PL2PS_N_SI
set PL2PS_N_MI 1
set PL2PS_N_SI 0

proc connect_pl2ps {side block port} {

    if {"" == [get_bd_cells pl2ps]} {

        set_property -dict [list CONFIG.PSU__USE__S_AXI_GP6 {1} CONFIG.PSU__SAXIGP6__DATA_WIDTH {128}] [get_bd_cells cpu]
        connect_bd_net [get_bd_pins cpu/pl_clk0] [get_bd_pins cpu/maxihpm0_fpd_aclk]

        create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 pl2ps
        set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] [get_bd_cells pl2ps]
        connect_bd_net [get_bd_pins cpu/pl_clk0] [get_bd_pins pl2ps/ACLK]
        connect_bd_net [get_bd_pins cpu_rst/interconnect_aresetn] [get_bd_pins pl2ps/ARESETN]
        connect_bd_intf_net -boundary_type upper [get_bd_intf_pins pl2ps/M00_AXI] [get_bd_intf_pins cpu/S_AXI_LPD]

        connect_bd_net [get_bd_pins cpu/pl_clk0] [get_bd_pins pl2ps/M00_ACLK]
        connect_bd_net [get_bd_pins cpu_rst/peripheral_aresetn] [get_bd_pins pl2ps/M00_ARESETN]
    }

    if {$side == "SLAVE"} {
        set M2S_M1AXI S[format %02u $::PL2PS_N_SI]_AXI
        set M2S_M1CLK S[format %02u $::PL2PS_N_SI]_ACLK
        set M2S_M1RST S[format %02u $::PL2PS_N_SI]_ARESETN
        set_property CONFIG.NUM_SI [expr {$::PL2PS_N_SI + 1}] [get_bd_cells pl2ps]
        connect_bd_intf_net -boundary_type upper [get_bd_intf_pins pl2ps/$M2S_M1AXI] [get_bd_intf_pins $block/$port]
        connect_bd_net [get_bd_pins cpu/pl_clk0] [get_bd_pins pl2ps/$M2S_M1CLK]
        connect_bd_net [get_bd_pins cpu_rst/peripheral_aresetn] [get_bd_pins pl2ps/$M2S_M1RST]
        set ::PL2PS_N_SI [expr {$::PL2PS_N_SI + 1}]
    } else {
        set M2S_M1AXI S[format %02u $::PL2PS_N_MI]_AXI
        set M2S_M1CLK S[format %02u $::PL2PS_N_MI]_ACLK
        set M2S_M1RST S[format %02u $::PL2PS_N_MI]_ARESETN
        set_property CONFIG.NUM_MI [expr {$::PL2PS_N_MI + 1}] [get_bd_cells pl2ps]
        connect_bd_intf_net -boundary_type upper [get_bd_intf_pins pl2ps/$M2S_M1AXI] [get_bd_intf_pins $block/$port]
        connect_bd_net [get_bd_pins cpu/pl_clk0] [get_bd_pins pl2ps/$M2S_M1CLK]
        connect_bd_net [get_bd_pins cpu_rst/peripheral_aresetn] [get_bd_pins pl2ps/$M2S_M1RST]
        set ::PL2PS_N_MI [expr {$::PL2PS_N_MI + 1}]
    }
}

proc connect_irq2ps {block port bd_port} {

    puts stdout "proc connect_irq2ps: $block $port"
    set num_ports 0
    set concat_id 0
    if {"" == [get_bd_cells concat_irq2ps0]} {
        #Add IP block.
        create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_irq2ps0
        #Connect to PS and configure.
        set_property -dict [list CONFIG.PSU__USE__IRQ0 {1}] [get_bd_cells cpu]
        connect_bd_net [get_bd_pins concat_irq2ps0/dout] [get_bd_pins cpu/pl_ps_irq0]
        set_property CONFIG.NUM_PORTS 1 [get_bd_cells concat_irq2ps0]
    } else {
        set num_ports [get_property CONFIG.NUM_PORTS [get_bd_cells concat_irq2ps0]]
        if {$num_ports == 8} {
            set concat_id 1
            if {"" == [get_bd_cells concat_irq2ps1]} {
                #Add IP block.
                create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_irq2ps1
                #Connect to PS and configure.
                set_property -dict [list CONFIG.PSU__USE__IRQ1 {1}] [get_bd_cells cpu]
                connect_bd_net [get_bd_pins concat_irq2ps1/dout] [get_bd_pins cpu/pl_ps_irq1]
                set_property CONFIG.NUM_PORTS 1 [get_bd_cells concat_irq2ps1]
                set num_ports 0
            } else {
                set num_ports [get_property CONFIG.NUM_PORTS [get_bd_cells concat_irq2ps1]]
            }
        }
    }

    set_property CONFIG.NUM_PORTS [expr {$num_ports + 1}] [get_bd_cells concat_irq2ps${concat_id}]
    set IRQ_PORT In[format %01u $num_ports]
    
    if {$bd_port == 1} {
        connect_bd_net [get_bd_ports $port] [get_bd_pins concat_irq2ps${concat_id}/$IRQ_PORT]
    } else {
        connect_bd_net [get_bd_pins $block/$port] [get_bd_pins concat_irq2ps${concat_id}/$IRQ_PORT]
    }
}


#### Create Project ############################################################

create_project $ProjectName ./$ProjectName -part $ProjectPart
set_property board_part ${ProjectBoard} [current_project]

if {$BoardConnections != "0"} {
    set_property board_connections ${BoardConnections} [current_project]
}

set_param synth.maxThreads 8
set_param general.maxThreads 12
auto_detect_xpm -verbose
set_param xicom.use_bitstream_version_check false
set_param synth.elaboration.rodinMoreOptions "rt::set_parameter max_loop_limit 524288"
set_param synth.elaboration.rodinMoreOptions "rt::set_parameter var_size_limit 4194304"

create_bd_design "bd"

#Add required IP repo's
set_property  ip_repo_paths $srcRoot/interfaces [current_project]
#set_property ip_repo_paths [concat [get_property ip_repo_paths [current_project]] "$::ProjectIPRepos/iic_multiplexer_v1.2"] [current_project]
#set_property ip_repo_paths [concat [get_property ip_repo_paths [current_project]] "$::ProjectIPRepos/managed_ip_project"] [current_project]

#return -code 1

if {$::CAM_INTERFACE == "RPI"} {
    add_files -norecurse $srcRoot/sources/rpi_cam_ctrl.v
    add_files -fileset constrs_1 -norecurse $srcRoot/constraints/kria_rpi_imx219.xdc
    set_property used_in_synthesis false [get_files */kria_rpi_imx219.xdc]
    set_property used_in_implementation true [get_files */kria_rpi_imx219.xdc]
} elseif {$::CAM_INTERFACE == "IAS"} {
    add_files -fileset constrs_1 -norecurse $srcRoot/constraints/kria_ias1_ar1335.xdc
    set_property used_in_synthesis false [get_files */kria_ias1_ar1335.xdc]
    set_property used_in_implementation true [get_files */kria_ias1_ar1335.xdc]
} elseif {$::CAM_INTERFACE == "ISP"} {
    add_files -fileset constrs_1 -norecurse $srcRoot/constraints/kria_isp_ar1335.xdc
    set_property used_in_synthesis false [get_files */kria_isp_ar1335.xdc]
    set_property used_in_implementation true [get_files */kria_isp_ar1335.xdc]
}

update_ip_catalog
update_compile_order -fileset sources_1

create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.5 cpu
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells cpu]
set_property CONFIG.PSU__FPGA_PL1_ENABLE {0} [get_bd_cells cpu]
set_property CONFIG.PSU__USE__S_AXI_GP0 {1} [get_bd_cells cpu]
set_property CONFIG.PSU__SAXIGP0__DATA_WIDTH {128} [get_bd_cells cpu]
set_property -dict [list CONFIG.PSU__GPIO0_MIO__PERIPHERAL__ENABLE {0}] [get_bd_cells cpu]
set_property -dict [list CONFIG.PSU__GPIO1_MIO__PERIPHERAL__ENABLE {1}] [get_bd_cells cpu]
set_property -dict [list CONFIG.PSU__GPIO_EMIO__PERIPHERAL__ENABLE {1}] [get_bd_cells cpu]

if {$::EMMC == 1} {
    set_property -dict [list CONFIG.PSU__SD0__DATA_TRANSFER_MODE {8Bit} CONFIG.PSU__SD0__GRP_POW__ENABLE {0} \
        CONFIG.PSU__SD0__GRP_WP__ENABLE {0} CONFIG.PSU__SD0__PERIPHERAL__ENABLE {1} \
        CONFIG.PSU__SD0__PERIPHERAL__IO {MIO 13 .. 22} CONFIG.PSU__SD0__RESET__ENABLE {1} \
        CONFIG.PSU__SD0__SLOT_TYPE {eMMC}] [get_bd_cells cpu]
}

upgrade_ip [get_ips bd_cpu_0] -log ip_upgrade.log

#return -code 1

create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 cpu_clk
set_property -dict [list CONFIG.USE_LOCKED {false} CONFIG.USE_RESET {false}] [get_bd_cells cpu_clk]
set_property -dict [list CONFIG.NUM_OUT_CLKS {2}] [get_bd_cells cpu_clk]
connect_bd_net [get_bd_pins cpu/pl_clk0] [get_bd_pins cpu_clk/clk_in1]
set_property -dict [list CONFIG.CLKOUT1_USED {true} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200.000}] [get_bd_cells cpu_clk]
set_property -dict [list CONFIG.CLKOUT2_USED {true} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {300.000}] [get_bd_cells cpu_clk]

create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 cpu_rst
connect_bd_net [get_bd_pins cpu/pl_clk0] [get_bd_pins cpu_rst/slowest_sync_clk]
connect_bd_net [get_bd_pins cpu/pl_resetn0] [get_bd_pins cpu_rst/ext_reset_in]

regenerate_bd_layout
save_bd_design

if {$::JTAG2AXI == 1} {
    create_bd_cell -type ip -vlnv xilinx.com:ip:jtag_axi:1.2 jtag2axi
    set_property -dict [list CONFIG.M_AXI_ADDR_WIDTH {64} CONFIG.M_AXI_DATA_WIDTH {64}] [get_bd_cells jtag2axi]

    connect_bd_net [get_bd_pins cpu/pl_clk0] [get_bd_pins jtag2axi/aclk]
    connect_bd_net [get_bd_pins cpu_rst/peripheral_aresetn] [get_bd_pins jtag2axi/aresetn]

    connect_ps2pl SLAVE jtag2axi M_AXI

    regenerate_bd_layout
    save_bd_design
}

##### VIDEO PROCESSING PIPELINE ################################################

create_bd_cell -type ip -vlnv xilinx.com:ip:mipi_csi2_rx_subsystem:5.4 mipi_csi2_rx_subsyst_0

create_bd_cell -type ip -vlnv xilinx.com:ip:v_frmbuf_wr:2.5 v_frmbuf_wr_0
set_property -dict [list CONFIG.HAS_BGR8 {1} CONFIG.HAS_BGRX8 {1} CONFIG.HAS_RGBX8 {1} CONFIG.HAS_UYVY8 {1} \
    CONFIG.HAS_Y8 {1} CONFIG.HAS_YUV8 {1} CONFIG.HAS_YUVX8 {1} CONFIG.HAS_YUYV8 {1} \
    CONFIG.HAS_Y_UV8 {1} CONFIG.HAS_Y_UV8_420 {1} CONFIG.HAS_Y_U_V8 {1} CONFIG.HAS_Y_U_V8_420 {1}] [get_bd_cells v_frmbuf_wr_0]

make_bd_intf_pins_external  [get_bd_intf_pins mipi_csi2_rx_subsyst_0/mipi_phy_if]

create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 axis_subset_conv0
connect_bd_intf_net [get_bd_intf_pins mipi_csi2_rx_subsyst_0/video_out] [get_bd_intf_pins axis_subset_conv0/S_AXIS]

connect_bd_net [get_bd_pins cpu_clk/clk_out1] [get_bd_pins mipi_csi2_rx_subsyst_0/dphy_clk_200M]
connect_ps2pl MASTER mipi_csi2_rx_subsyst_0 csirxss_s_axi
connect_irq2ps mipi_csi2_rx_subsyst_0 csirxss_csi_irq 0
connect_irq2ps v_frmbuf_wr_0 interrupt 0
connect_bd_net [get_bd_pins cpu_rst/peripheral_aresetn] [get_bd_pins mipi_csi2_rx_subsyst_0/lite_aresetn]

#### Interconnect ####
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 vpss_interconnect
set_property CONFIG.NUM_MI {2} [get_bd_cells vpss_interconnect]

connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins cpu/maxihpm0_fpd_aclk]
connect_bd_intf_net [get_bd_intf_pins cpu/M_AXI_HPM0_FPD] -boundary_type upper [get_bd_intf_pins vpss_interconnect/S00_AXI]

connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins vpss_interconnect/ACLK]
connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins vpss_interconnect/S00_ACLK]
connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins vpss_interconnect/M00_ACLK]
connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins vpss_interconnect/M01_ACLK]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins vpss_interconnect/M00_AXI] [get_bd_intf_pins v_frmbuf_wr_0/s_axi_CTRL]
connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins cpu/saxihpc0_fpd_aclk]

connect_bd_net [get_bd_pins cpu/pl_clk0] [get_bd_pins mipi_csi2_rx_subsyst_0/lite_aclk]
connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins mipi_csi2_rx_subsyst_0/video_aclk]
connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins axis_subset_conv0/aclk]
connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins v_frmbuf_wr_0/ap_clk]

create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 isp_reset
connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins isp_reset/slowest_sync_clk]
connect_bd_net [get_bd_pins cpu/pl_resetn0] [get_bd_pins isp_reset/ext_reset_in]
connect_bd_net [get_bd_pins isp_reset/peripheral_aresetn] [get_bd_pins axis_subset_conv0/aresetn]

connect_bd_net [get_bd_pins isp_reset/interconnect_aresetn] [get_bd_pins vpss_interconnect/ARESETN]
connect_bd_net [get_bd_pins isp_reset/interconnect_aresetn] [get_bd_pins vpss_interconnect/S00_ARESETN]
connect_bd_net [get_bd_pins isp_reset/interconnect_aresetn] [get_bd_pins vpss_interconnect/M00_ARESETN]
connect_bd_net [get_bd_pins isp_reset/interconnect_aresetn] [get_bd_pins vpss_interconnect/M01_ARESETN]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 fb_interconnect
set_property CONFIG.NUM_MI {1} [get_bd_cells fb_interconnect]
set_property CONFIG.S00_HAS_DATA_FIFO {1} [get_bd_cells fb_interconnect]
connect_bd_intf_net [get_bd_intf_pins v_frmbuf_wr_0/m_axi_mm_video] -boundary_type upper [get_bd_intf_pins fb_interconnect/S00_AXI]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins fb_interconnect/M00_AXI] [get_bd_intf_pins cpu/S_AXI_HPC0_FPD]
connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins fb_interconnect/ACLK]
connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins fb_interconnect/S00_ACLK]
connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins fb_interconnect/M00_ACLK]
connect_bd_net [get_bd_pins isp_reset/interconnect_aresetn] [get_bd_pins fb_interconnect/ARESETN]
connect_bd_net [get_bd_pins isp_reset/interconnect_aresetn] [get_bd_pins fb_interconnect/S00_ARESETN]
connect_bd_net [get_bd_pins isp_reset/interconnect_aresetn] [get_bd_pins fb_interconnect/M00_ARESETN]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0
set_property CONFIG.DIN_WIDTH {95} [get_bd_cells xlslice_0]
set_property -dict [list CONFIG.DIN_FROM {0} CONFIG.DIN_TO {0}] [get_bd_cells xlslice_0]
connect_bd_net [get_bd_pins cpu/emio_gpio_o] [get_bd_pins xlslice_0/Din]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1
set_property CONFIG.DIN_WIDTH {95} [get_bd_cells xlslice_1]
set_property -dict [list CONFIG.DIN_FROM {1} CONFIG.DIN_TO {1}] [get_bd_cells xlslice_1]
connect_bd_net [get_bd_pins cpu/emio_gpio_o] [get_bd_pins xlslice_1/Din]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_2
set_property CONFIG.DIN_WIDTH {95} [get_bd_cells xlslice_2]
set_property -dict [list CONFIG.DIN_FROM {2} CONFIG.DIN_TO {2}] [get_bd_cells xlslice_2]
connect_bd_net [get_bd_pins cpu/emio_gpio_o] [get_bd_pins xlslice_2/Din]

connect_bd_net [get_bd_pins xlslice_0/Dout] [get_bd_pins mipi_csi2_rx_subsyst_0/video_aresetn]
connect_bd_net [get_bd_pins xlslice_1/Dout] [get_bd_pins v_frmbuf_wr_0/ap_rst_n]

create_bd_cell -type ip -vlnv xilinx.com:ip:v_proc_ss:2.3 v_proc_ss_1
set_property -dict [list CONFIG.C_ENABLE_CSC {true} CONFIG.C_TOPOLOGY {0}] [get_bd_cells v_proc_ss_1]
connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins v_proc_ss_1/aclk_axis]
connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins v_proc_ss_1/aclk_ctrl]
connect_bd_net [get_bd_pins xlslice_2/Dout] [get_bd_pins v_proc_ss_1/aresetn_ctrl]

connect_bd_intf_net -boundary_type upper [get_bd_intf_pins vpss_interconnect/M01_AXI] [get_bd_intf_pins v_proc_ss_1/s_axi_ctrl]


if {$::CAM_INTERFACE != "ISP"} {
    create_bd_cell -type ip -vlnv xilinx.com:ip:v_demosaic:1.1 v_demosaic_0

    create_bd_cell -type ip -vlnv xilinx.com:ip:v_gamma_lut:1.1 v_gamma_lut_0

    create_bd_cell -type ip -vlnv xilinx.com:ip:v_proc_ss:2.3 v_proc_ss_0
    set_property CONFIG.C_TOPOLOGY {3} [get_bd_cells v_proc_ss_0]


    connect_bd_intf_net [get_bd_intf_pins axis_subset_conv0/M_AXIS] [get_bd_intf_pins v_demosaic_0/s_axis_video]
    connect_bd_intf_net [get_bd_intf_pins v_demosaic_0/m_axis_video] [get_bd_intf_pins v_gamma_lut_0/s_axis_video]
    connect_bd_intf_net [get_bd_intf_pins v_gamma_lut_0/m_axis_video] [get_bd_intf_pins v_proc_ss_0/s_axis]
    connect_bd_intf_net [get_bd_intf_pins v_proc_ss_0/m_axis] [get_bd_intf_pins v_proc_ss_1/s_axis]
    connect_bd_intf_net [get_bd_intf_pins v_proc_ss_1/m_axis] [get_bd_intf_pins v_frmbuf_wr_0/s_axis_video]
    
    connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins v_demosaic_0/ap_clk]
    connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins v_gamma_lut_0/ap_clk]
    connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins v_proc_ss_0/aclk]

    connect_irq2ps v_demosaic_0 interrupt 0
    connect_irq2ps v_gamma_lut_0 interrupt 0
    connect_irq2ps v_frmbuf_wr_0 interrupt 0
    
    #connect_bd_net [get_bd_pins cpu_rst/peripheral_aresetn] [get_bd_pins axis_subset_conv0/aresetn]
    #connect_bd_net [get_bd_pins cpu_rst/peripheral_aresetn] [get_bd_pins v_demosaic_0/ap_rst_n]
    #connect_bd_net [get_bd_pins cpu_rst/peripheral_aresetn] [get_bd_pins v_gamma_lut_0/ap_rst_n]
    #connect_bd_net [get_bd_pins cpu_rst/peripheral_aresetn] [get_bd_pins v_proc_ss_0/aresetn]
    #connect_bd_net [get_bd_pins cpu_rst/peripheral_aresetn] [get_bd_pins v_proc_ss_1/aresetn_ctrl]
    #connect_bd_net [get_bd_pins cpu_rst/peripheral_aresetn] [get_bd_pins v_frmbuf_wr_0/ap_rst_n]
        
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_3
    set_property CONFIG.DIN_WIDTH {95} [get_bd_cells xlslice_3]
    set_property -dict [list CONFIG.DIN_FROM {3} CONFIG.DIN_TO {3}] [get_bd_cells xlslice_3]
    connect_bd_net [get_bd_pins cpu/emio_gpio_o] [get_bd_pins xlslice_3/Din]
    
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_4
    set_property CONFIG.DIN_WIDTH {95} [get_bd_cells xlslice_4]
    set_property -dict [list CONFIG.DIN_FROM {4} CONFIG.DIN_TO {4}] [get_bd_cells xlslice_4]
    connect_bd_net [get_bd_pins cpu/emio_gpio_o] [get_bd_pins xlslice_4/Din]
    
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_5
    set_property CONFIG.DIN_WIDTH {95} [get_bd_cells xlslice_5]
    set_property -dict [list CONFIG.DIN_FROM {5} CONFIG.DIN_TO {5}] [get_bd_cells xlslice_5]
    connect_bd_net [get_bd_pins cpu/emio_gpio_o] [get_bd_pins xlslice_5/Din]

    connect_bd_net [get_bd_pins xlslice_3/Dout] [get_bd_pins v_demosaic_0/ap_rst_n]
    connect_bd_net [get_bd_pins xlslice_4/Dout] [get_bd_pins v_gamma_lut_0/ap_rst_n]
    connect_bd_net [get_bd_pins xlslice_5/Dout] [get_bd_pins v_proc_ss_0/aresetn]
    
    #create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 vpss_interconnect
    set_property CONFIG.NUM_MI {5} [get_bd_cells vpss_interconnect]
    

    connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins vpss_interconnect/M02_ACLK]
    connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins vpss_interconnect/M03_ACLK]
    connect_bd_net [get_bd_pins cpu_clk/clk_out2] [get_bd_pins vpss_interconnect/M04_ACLK]
    connect_bd_intf_net -boundary_type upper [get_bd_intf_pins vpss_interconnect/M02_AXI] [get_bd_intf_pins v_demosaic_0/s_axi_CTRL]
    connect_bd_intf_net -boundary_type upper [get_bd_intf_pins vpss_interconnect/M03_AXI] [get_bd_intf_pins v_gamma_lut_0/s_axi_CTRL]
    connect_bd_intf_net -boundary_type upper [get_bd_intf_pins vpss_interconnect/M04_AXI] [get_bd_intf_pins v_proc_ss_0/s_axi_ctrl]

    connect_bd_net [get_bd_pins isp_reset/interconnect_aresetn] [get_bd_pins vpss_interconnect/M02_ARESETN]
    connect_bd_net [get_bd_pins isp_reset/interconnect_aresetn] [get_bd_pins vpss_interconnect/M03_ARESETN]
    connect_bd_net [get_bd_pins isp_reset/interconnect_aresetn] [get_bd_pins vpss_interconnect/M04_ARESETN]

} else {
    
    connect_bd_intf_net [get_bd_intf_pins axis_subset_conv0/M_AXIS] [get_bd_intf_pins v_proc_ss_1/s_axis]
    connect_bd_intf_net [get_bd_intf_pins v_proc_ss_1/m_axis] [get_bd_intf_pins v_frmbuf_wr_0/s_axis_video]
    
}

#return -code 1

##### AXI_I2C for CAMERA #######################################################
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.1 iic2cam
connect_ps2pl MASTER iic2cam S_AXI
connect_irq2ps iic2cam iic2intc_irpt 0
connect_bd_net [get_bd_pins cpu/pl_clk0] [get_bd_pins iic2cam/s_axi_aclk]
connect_bd_net [get_bd_pins cpu_rst/peripheral_aresetn] [get_bd_pins iic2cam/s_axi_aresetn]
make_bd_intf_pins_external  [get_bd_intf_pins iic2cam/IIC]
set_property name IIC_CAM [get_bd_intf_ports IIC_0]
#return -code 1

group_bd_cells RESET_SLICE [get_bd_cells xlslice_0] [get_bd_cells xlslice_1] [get_bd_cells xlslice_2] [get_bd_cells xlslice_3] [get_bd_cells xlslice_4] [get_bd_cells xlslice_5]
group_bd_cells ISP [get_bd_cells fb_interconnect]  [get_bd_cells isp_reset] [get_bd_cells v_proc_ss_1] [get_bd_cells mipi_csi2_rx_subsyst_0] [get_bd_cells RESET_SLICE] [get_bd_cells axis_subset_conv0] [get_bd_cells v_frmbuf_wr_0] [get_bd_cells v_demosaic_0] [get_bd_cells concat_irq2ps0] [get_bd_cells v_gamma_lut_0] [get_bd_cells v_proc_ss_0] [get_bd_cells vpss_interconnect]

regenerate_bd_layout
save_bd_design

if {$::CAMERA == "RPI-IMX219"} {

    create_bd_cell -type module -reference RPI_CAM_CTRL RPI_CAM_CTRL
    connect_bd_net [get_bd_pins cpu/pl_clk0] [get_bd_pins RPI_CAM_CTRL/ACLOCK]
    connect_bd_net [get_bd_pins cpu_rst/peripheral_aresetn] [get_bd_pins RPI_CAM_CTRL/RESETN]
    make_bd_pins_external  [get_bd_pins RPI_CAM_CTRL/IAS0_EN]
    make_bd_pins_external  [get_bd_pins RPI_CAM_CTRL/IAS1_EN]
    make_bd_pins_external  [get_bd_pins RPI_CAM_CTRL/RPI_PWR_EN]
    make_bd_pins_external  [get_bd_pins RPI_CAM_CTRL/RPI_LED_EN]
    set_property name IAS0_EN [get_bd_ports IAS0_EN_0]
    set_property name IAS1_EN [get_bd_ports IAS1_EN_0]
    set_property name RPI_PWR_EN [get_bd_ports RPI_PWR_EN_0]
    set_property name RPI_LED_EN [get_bd_ports RPI_LED_EN_0]
    
    set_property -dict [list CONFIG.CLK_LANE_IO_LOC {D7} CONFIG.CMN_NUM_LANES {2} \
      CONFIG.CMN_PXL_FORMAT {RAW8} CONFIG.CSI_BUF_DEPTH {8192} \
      CONFIG.C_CSI_EN_CRC {false} CONFIG.C_EN_CSI_V2_0 {true} \
      CONFIG.DATA_LANE0_IO_LOC {E5} CONFIG.DATA_LANE1_IO_LOC {G6} \
      CONFIG.DPHYRX_BOARD_INTERFACE {som240_1_connector_mipi_csi_raspi} CONFIG.DPY_LINE_RATE {912} \
      CONFIG.HP_IO_BANK_SELECTION {66} CONFIG.SupportLevel {1}] [get_bd_cells ISP/mipi_csi2_rx_subsyst_0]
   
    set_property -dict [list CONFIG.S_TDEST_WIDTH.VALUE_SRC USER CONFIG.M_HAS_TLAST.VALUE_SRC \
        USER CONFIG.S_HAS_TLAST.VALUE_SRC USER CONFIG.S_TUSER_WIDTH.VALUE_SRC \
        USER CONFIG.M_TUSER_WIDTH.VALUE_SRC USER CONFIG.M_TDATA_NUM_BYTES.VALUE_SRC \
     USER CONFIG.M_TDEST_WIDTH.VALUE_SRC USER] [get_bd_cells ISP/axis_subset_conv0]
    
    set_property -dict [list CONFIG.M_HAS_TLAST {1} CONFIG.M_TDEST_WIDTH {10} CONFIG.M_TUSER_WIDTH {1} CONFIG.S_HAS_TLAST {1} \
        CONFIG.S_TDEST_WIDTH {10} CONFIG.S_TUSER_WIDTH {1} CONFIG.TDEST_REMAP {tdest[9:0]}] [get_bd_cells ISP/axis_subset_conv0]
    
    set_property -dict [list CONFIG.MAX_DATA_WIDTH {8} CONFIG.SAMPLES_PER_CLOCK {1} CONFIG.MAX_COLS {3840} CONFIG.MAX_ROWS {2160}] [get_bd_cells ISP/v_demosaic_0]
    set_property -dict [list CONFIG.MAX_DATA_WIDTH {8} CONFIG.SAMPLES_PER_CLOCK {1} CONFIG.MAX_COLS {3840} CONFIG.MAX_ROWS {2160}] [get_bd_cells ISP/v_gamma_lut_0]
    set_property -dict [list CONFIG.C_MAX_DATA_WIDTH {8} CONFIG.C_SAMPLES_PER_CLK {1} CONFIG.MAX_COLS {3840} CONFIG.MAX_ROWS {2160}] [get_bd_cells ISP/v_proc_ss_0]
    set_property -dict [list CONFIG.C_MAX_DATA_WIDTH {8} CONFIG.C_SAMPLES_PER_CLK {1} CONFIG.MAX_COLS {3840} CONFIG.MAX_ROWS {2160}] [get_bd_cells ISP/v_proc_ss_1]
    set_property -dict [list CONFIG.AXIMM_ADDR_WIDTH {64} CONFIG.SAMPLES_PER_CLOCK {1}  CONFIG.MAX_COLS {3840} CONFIG.MAX_ROWS {2160}] [get_bd_cells ISP/v_frmbuf_wr_0]
} 

if {$::CAMERA == "IAS-AR1335"} {
    
    set_property -dict [list CONFIG.CLK_LANE_IO_LOC {C1} CONFIG.CMN_NUM_LANES {4} CONFIG.CMN_PXL_FORMAT {RAW10} \
        CONFIG.DATA_LANE0_IO_LOC {A2} CONFIG.DATA_LANE1_IO_LOC {B3} CONFIG.DATA_LANE2_IO_LOC {B4} CONFIG.DATA_LANE3_IO_LOC {D4} \
        CONFIG.DPHYRX_BOARD_INTERFACE {som240_1_connector_mipi_csi_ias} CONFIG.DPY_LINE_RATE {1104} CONFIG.HP_IO_BANK_SELECTION {66} \
        CONFIG.SupportLevel {1}] [get_bd_cells ISP/mipi_csi2_rx_subsyst_0]

    set_property CONFIG.C_CSI_EN_CRC {false} [get_bd_cells ISP/mipi_csi2_rx_subsyst_0]
    set_property CONFIG.C_CSI_EN_ACTIVELANES {false} [get_bd_cells ISP/mipi_csi2_rx_subsyst_0]
    
    set_property -dict [list CONFIG.S_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells ISP/axis_subset_conv0]
    set_property -dict [list CONFIG.S_TDEST_WIDTH.VALUE_SRC USER CONFIG.M_HAS_TLAST.VALUE_SRC \
        USER CONFIG.S_HAS_TLAST.VALUE_SRC USER CONFIG.S_TUSER_WIDTH.VALUE_SRC \
        USER CONFIG.M_TUSER_WIDTH.VALUE_SRC USER CONFIG.M_TDATA_NUM_BYTES.VALUE_SRC \
     USER CONFIG.M_TDEST_WIDTH.VALUE_SRC USER] [get_bd_cells ISP/axis_subset_conv0]
        
    set_property -dict [list CONFIG.M_HAS_TLAST {1} CONFIG.M_TDEST_WIDTH {10} CONFIG.M_TUSER_WIDTH {1} CONFIG.S_HAS_TLAST {1} \
        CONFIG.S_TDEST_WIDTH {10} CONFIG.S_TUSER_WIDTH {1} CONFIG.TDEST_REMAP {tdest[9:0]}] [get_bd_cells ISP/axis_subset_conv0]
    
    set_property -dict [list CONFIG.MAX_DATA_WIDTH {8} CONFIG.SAMPLES_PER_CLOCK {1} CONFIG.MAX_COLS {3840} CONFIG.MAX_ROWS {2160}] [get_bd_cells ISP/v_demosaic_0]
    set_property -dict [list CONFIG.MAX_DATA_WIDTH {8} CONFIG.SAMPLES_PER_CLOCK {1} CONFIG.MAX_COLS {3840} CONFIG.MAX_ROWS {2160}] [get_bd_cells ISP/v_gamma_lut_0]
    set_property -dict [list CONFIG.C_MAX_DATA_WIDTH {8} CONFIG.C_SAMPLES_PER_CLK {1} CONFIG.MAX_COLS {3840} CONFIG.MAX_ROWS {2160}] [get_bd_cells ISP/v_proc_ss_0]
    set_property -dict [list CONFIG.C_MAX_DATA_WIDTH {8} CONFIG.C_SAMPLES_PER_CLK {1} CONFIG.MAX_COLS {3840} CONFIG.MAX_ROWS {2160}] [get_bd_cells ISP/v_proc_ss_1]
    set_property -dict [list CONFIG.AXIMM_ADDR_WIDTH {64} CONFIG.SAMPLES_PER_CLOCK {1}  CONFIG.MAX_COLS {3840} CONFIG.MAX_ROWS {2160}] [get_bd_cells ISP/v_frmbuf_wr_0]
    set_property CONFIG.C_CSC_ENABLE_WINDOW {false} [get_bd_cells ISP/v_proc_ss_0]
    set_property CONFIG.C_COLORSPACE_SUPPORT {2} [get_bd_cells ISP/v_proc_ss_0]
    set_property CONFIG.C_COLORSPACE_SUPPORT {2} [get_bd_cells ISP/v_proc_ss_1]
    
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 ISP/xlslice_0
    set_property -dict [list CONFIG.DIN_FROM {6} CONFIG.DIN_TO {6} CONFIG.DIN_WIDTH {95}] [get_bd_cells ISP/xlslice_0]
    connect_bd_net [get_bd_pins ISP/Din] [get_bd_pins ISP/xlslice_0/Din]
    make_bd_pins_external  [get_bd_pins ISP/xlslice_0/Dout]
    set_property name IAS1_RST [get_bd_ports Dout_0]

    if {$::MODE == "4K-UHD"} {

        set_property -dict [list CONFIG.S_TDATA_NUM_BYTES {3} CONFIG.M_TDATA_NUM_BYTES {2}] [get_bd_cells ISP/axis_subset_conv0]
        set_property -dict [list CONFIG.TDATA_REMAP {tdata[19:12],tdata[9:2]}] [get_bd_cells ISP/axis_subset_conv0]
        
        set_property CONFIG.C_CSI_FILTER_USERDATATYPE {true} [get_bd_cells ISP/mipi_csi2_rx_subsyst_0]
        set_property CONFIG.CMN_NUM_PIXELS {2} [get_bd_cells ISP/mipi_csi2_rx_subsyst_0]
        set_property -dict [list CONFIG.SAMPLES_PER_CLOCK {2} CONFIG.CSI_BUF_DEPTH {4096}] [get_bd_cells ISP/mipi_csi2_rx_subsyst_0]
        set_property -dict [list CONFIG.SAMPLES_PER_CLOCK {2} CONFIG.MAX_COLS {3840} CONFIG.MAX_ROWS {2160}] [get_bd_cells ISP/v_demosaic_0]
        set_property -dict [list CONFIG.SAMPLES_PER_CLOCK {2} CONFIG.MAX_COLS {3840} CONFIG.MAX_ROWS {2160}] [get_bd_cells ISP/v_gamma_lut_0]
        set_property -dict [list CONFIG.C_SAMPLES_PER_CLK {2} CONFIG.C_MAX_COLS {3840} CONFIG.C_MAX_ROWS {2160}] [get_bd_cells ISP/v_proc_ss_0]
        set_property -dict [list CONFIG.C_SAMPLES_PER_CLK {2} CONFIG.C_MAX_COLS {3840} CONFIG.C_MAX_ROWS {2160}] [get_bd_cells ISP/v_proc_ss_1]
        set_property -dict [list CONFIG.SAMPLES_PER_CLOCK {2}  CONFIG.MAX_COLS {3840} CONFIG.MAX_ROWS {2160}] [get_bd_cells ISP/v_frmbuf_wr_0]
        
    } else {
        
        set_property -dict [list CONFIG.S_TDATA_NUM_BYTES {2} CONFIG.M_TDATA_NUM_BYTES {1}] [get_bd_cells ISP/axis_subset_conv0]
        set_property -dict [list CONFIG.TDATA_REMAP {tdata[9:2]}] [get_bd_cells ISP/axis_subset_conv0]
        
        set_property CONFIG.C_CSI_FILTER_USERDATATYPE {false} [get_bd_cells ISP/mipi_csi2_rx_subsyst_0]
        set_property -dict [list CONFIG.CSI_BUF_DEPTH {2048}] [get_bd_cells ISP/mipi_csi2_rx_subsyst_0]
        set_property -dict [list CONFIG.SAMPLES_PER_CLOCK {1} CONFIG.MAX_COLS {3840} CONFIG.MAX_ROWS {2160}] [get_bd_cells ISP/v_demosaic_0]
        set_property -dict [list CONFIG.SAMPLES_PER_CLOCK {1} CONFIG.MAX_COLS {3840} CONFIG.MAX_ROWS {2160}] [get_bd_cells ISP/v_gamma_lut_0]
        set_property -dict [list CONFIG.SAMPLES_PER_CLOCK {1} CONFIG.C_MAX_COLS {3840} CONFIG.C_MAX_ROWS {2160}] [get_bd_cells ISP/v_proc_ss_0]
        set_property -dict [list CONFIG.SAMPLES_PER_CLOCK {1} CONFIG.C_MAX_COLS {3840} CONFIG.C_MAX_ROWS {2160}] [get_bd_cells ISP/v_proc_ss_1]
        set_property -dict [list CONFIG.SAMPLES_PER_CLOCK {1} CONFIG.MAX_COLS {3840} CONFIG.MAX_ROWS {2160}] [get_bd_cells ISP/v_frmbuf_wr_0]
        
    }
    
}

if {$::CAMERA == "ISP-AR1335"} {
    
    #return -code 1
    
    set_property -dict [list CONFIG.SupportLevel {1}] [get_bd_cells ISP/mipi_csi2_rx_subsyst_0]
    set_property -dict [list CONFIG.DPHYRX_BOARD_INTERFACE {som240_1_connector_mipi_csi_isp}] [get_bd_cells ISP/mipi_csi2_rx_subsyst_0]
    set_property -dict [list CONFIG.CMN_PXL_FORMAT {YUV422_8bit} CONFIG.CMN_VC {0} CONFIG.CSI_BUF_DEPTH {8192}] [get_bd_cells ISP/mipi_csi2_rx_subsyst_0]
    set_property -dict [list CONFIG.C_CSI_EN_ACTIVELANES {true} CONFIG.C_CSI_FILTER_USERDATATYPE {true} CONFIG.DPY_LINE_RATE {896}] [get_bd_cells ISP/mipi_csi2_rx_subsyst_0]
    set_property -dict [list  CONFIG.CMN_NUM_PIXELS {2}] [get_bd_cells ISP/mipi_csi2_rx_subsyst_0]
    
    #save_bd_design
    
    set_property -dict [list CONFIG.S_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells ISP/axis_subset_conv0]
    set_property CONFIG.S_TDATA_NUM_BYTES {4} [get_bd_cells ISP/axis_subset_conv0]
    
    set_property -dict [list CONFIG.M_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells ISP/axis_subset_conv0]
    set_property CONFIG.M_TDATA_NUM_BYTES {6} [get_bd_cells ISP/axis_subset_conv0]
    
    #set_property -dict [list CONFIG.TDATA_REMAP {8'b00000000,tdata[15:0]}] [get_bd_cells ISP/axis_subset_conv0]
    set_property -dict [list CONFIG.TDATA_REMAP {16'b00000000,tdata[31:0]}] [get_bd_cells ISP/axis_subset_conv0]
    
    set_property -dict [list CONFIG.M_TDEST_WIDTH.VALUE_SRC USER] [get_bd_cells ISP/axis_subset_conv0]
    set_property -dict [list CONFIG.M_TDEST_WIDTH {1}] [get_bd_cells ISP/axis_subset_conv0]
    
    set_property -dict [list CONFIG.C_MAX_DATA_WIDTH {8} CONFIG.C_SAMPLES_PER_CLK {2} CONFIG.C_MAX_COLS {8192} CONFIG.C_MAX_ROWS {4320}] [get_bd_cells ISP/v_proc_ss_1]
    set_property -dict [list CONFIG.C_COLORSPACE_SUPPORT {0} CONFIG.C_SCALER_ALGORITHM {2}] [get_bd_cells ISP/v_proc_ss_1]
    set_property -dict [list CONFIG.AXIMM_ADDR_WIDTH {64} CONFIG.SAMPLES_PER_CLOCK {2}  CONFIG.MAX_COLS {8192} CONFIG.MAX_ROWS {4320}] [get_bd_cells ISP/v_frmbuf_wr_0]

    ###################
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 ISP/xlslice_isp_reset
    set_property -dict [list CONFIG.DIN_FROM {6} CONFIG.DIN_TO {6} CONFIG.DIN_WIDTH {95}] [get_bd_cells ISP/xlslice_isp_reset]
    connect_bd_net [get_bd_pins ISP/Din] [get_bd_pins ISP/xlslice_isp_reset/Din]
    make_bd_pins_external  [get_bd_pins ISP/xlslice_isp_reset/Dout]
    set_property name IAS0_RST [get_bd_ports Dout_0]
    
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 ISP/xlslice_isp_stndby
    set_property -dict [list CONFIG.DIN_FROM {7} CONFIG.DIN_TO {7} CONFIG.DIN_WIDTH {95}] [get_bd_cells ISP/xlslice_isp_stndby]
    connect_bd_net [get_bd_pins ISP/Din] [get_bd_pins ISP/xlslice_isp_stndby/Din]
    make_bd_pins_external  [get_bd_pins ISP/xlslice_isp_stndby/Dout]
    set_property name IAS0_STDBY [get_bd_ports Dout_0]
    
}

if { ($::CAMERA == "RPI-IMX219") || ($::CAMERA == "IAS-AR1335")} {

    assign_bd_address -target_address_space /cpu/Data [get_bd_addr_segs iic2cam/S_AXI/Reg] -force
    assign_bd_address -target_address_space /cpu/Data [get_bd_addr_segs ISP/mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg] -force
    assign_bd_address -target_address_space /cpu/Data [get_bd_addr_segs ISP/v_demosaic_0/s_axi_CTRL/Reg] -force
    assign_bd_address -target_address_space /cpu/Data [get_bd_addr_segs ISP/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
    assign_bd_address -target_address_space /cpu/Data [get_bd_addr_segs ISP/v_gamma_lut_0/s_axi_CTRL/Reg] -force
    assign_bd_address -target_address_space /cpu/Data [get_bd_addr_segs ISP/v_proc_ss_0/s_axi_ctrl/Reg] -force
    assign_bd_address -target_address_space /cpu/Data [get_bd_addr_segs ISP/v_proc_ss_1/s_axi_ctrl/Reg] -force
    assign_bd_address -target_address_space /ISP/v_frmbuf_wr_0/Data_m_axi_mm_video [get_bd_addr_segs cpu/SAXIGP0/HPC0_DDR_LOW] -force
    exclude_bd_addr_seg [get_bd_addr_segs cpu/SAXIGP0/HPC0_QSPI] -target_address_space [get_bd_addr_spaces ISP/v_frmbuf_wr_0/Data_m_axi_mm_video]
    exclude_bd_addr_seg [get_bd_addr_segs cpu/SAXIGP0/HPC0_DDR_HIGH] -target_address_space [get_bd_addr_spaces ISP/v_frmbuf_wr_0/Data_m_axi_mm_video]
    exclude_bd_addr_seg [get_bd_addr_segs cpu/SAXIGP0/HPC0_LPS_OCM] -target_address_space [get_bd_addr_spaces ISP/v_frmbuf_wr_0/Data_m_axi_mm_video]
    
} elseif { $::CAMERA == "ISP-AR1335" } {
    
    assign_bd_address -target_address_space /cpu/Data [get_bd_addr_segs iic2cam/S_AXI/Reg] -force
    assign_bd_address -target_address_space /cpu/Data [get_bd_addr_segs ISP/mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg] -force
    #assign_bd_address -target_address_space /cpu/Data [get_bd_addr_segs ISP/v_demosaic_0/s_axi_CTRL/Reg] -force
    assign_bd_address -target_address_space /cpu/Data [get_bd_addr_segs ISP/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
    #assign_bd_address -target_address_space /cpu/Data [get_bd_addr_segs ISP/v_gamma_lut_0/s_axi_CTRL/Reg] -force
    #assign_bd_address -target_address_space /cpu/Data [get_bd_addr_segs ISP/v_proc_ss_0/s_axi_ctrl/Reg] -force
    assign_bd_address -target_address_space /cpu/Data [get_bd_addr_segs ISP/v_proc_ss_1/s_axi_ctrl/Reg] -force
    assign_bd_address -target_address_space /ISP/v_frmbuf_wr_0/Data_m_axi_mm_video [get_bd_addr_segs cpu/SAXIGP0/HPC0_DDR_LOW] -force
    exclude_bd_addr_seg [get_bd_addr_segs cpu/SAXIGP0/HPC0_QSPI] -target_address_space [get_bd_addr_spaces ISP/v_frmbuf_wr_0/Data_m_axi_mm_video]
    exclude_bd_addr_seg [get_bd_addr_segs cpu/SAXIGP0/HPC0_DDR_HIGH] -target_address_space [get_bd_addr_spaces ISP/v_frmbuf_wr_0/Data_m_axi_mm_video]
    exclude_bd_addr_seg [get_bd_addr_segs cpu/SAXIGP0/HPC0_LPS_OCM] -target_address_space [get_bd_addr_spaces ISP/v_frmbuf_wr_0/Data_m_axi_mm_video]
    
}

#return -code 1

assign_bd_address
regenerate_bd_layout
save_bd_design

make_wrapper -files [get_files ./$ProjectName/$ProjectName.srcs/sources_1/bd/bd/bd.bd] -top
add_files -norecurse ./$ProjectName/$ProjectName.srcs/sources_1/bd/bd/hdl/bd_wrapper.v
update_compile_order -fileset sources_1
set_property top bd_wrapper [current_fileset]

#assign_bd_address
save_bd_design

set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property strategy Performance_RefinePlacement [get_runs impl_1]
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE ExploreWithRemap [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.TCL.PRE {} [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE WLDrivenBlockPlacement [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE ExploreWithAggressiveHoldFix [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE ExploreWithAggressiveHoldFix [get_runs impl_1]

set_property STEPS.SYNTH_DESIGN.ARGS.GATED_CLOCK_CONVERSION auto [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]
#set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE ExploreWithHoldFix [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE ExtraPostPlacementOpt [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]

save_bd_design

auto_detect_xpm

#update_compile_order -fileset sources_1
#launch_runs impl_1 -to_step write_bitstream -jobs 10

#write_hw_platform -fixed -include_bit -force -file ${ProjectFolder}/NG_UltraZed_IOCC.runs/impl_1/bd_wrapper.xsa
