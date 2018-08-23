set partNumber $::env(XILINX_PART)
set boardName  $::env(XILINX_BOARD)

set ipName xilinx_axi_clock_converter

create_project $ipName .  -force -part $partNumber
set_property board_part $boardName [current_project]

create_ip -name axi_clock_converter -vendor xilinx.com -library ip -version 2.1 -module_name $ipName

# set_property -dict [list CONFIG.USE_DYN_RECONFIG {false} CONFIG.PRIM_IN_FREQ {200.00} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50.000} CONFIG.LOCKED_PORT {locked}] [get_ips xilinx_clock_manager]
# set_property -dict [list CONFIG.CLKOUT2_USED {true} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {50} CONFIG.CLKOUT2_DRIVES {BUFGCE} CONFIG.MMCM_DIVCLK_DIVIDE {1} CONFIG.MMCM_CLKOUT1_DIVIDE {20} CONFIG.NUM_OUT_CLKS {2} CONFIG.CLKOUT2_JITTER {151.636} CONFIG.CLKOUT2_PHASE_ERROR {98.575}] [get_ips xilinx_clock_manager]

#set_property -dict [list CONFIG.CLKOUT1_USED {true} CONFIG.CLK_IN1_BOARD_INTERFACE {sys_clock} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200} CONFIG.RESET_TYPE {ACTIVE_LOW} CONFIG.PRIM_IN_FREQ {125.000} CONFIG.CLKIN1_JITTER_PS {80.0} CONFIG.CLKOUT2_USED {false} CONFIG.MMCM_DIVCLK_DIVIDE {1} CONFIG.MMCM_CLKFBOUT_MULT_F {8.000} CONFIG.MMCM_CLKIN1_PERIOD {8.000} CONFIG.MMCM_CLKOUT0_DIVIDE_F {5.000} CONFIG.MMCM_CLKOUT1_DIVIDE {1} CONFIG.NUM_OUT_CLKS {1} CONFIG.RESET_PORT {resetn} CONFIG.CLKOUT1_JITTER {109.241} CONFIG.CLKOUT1_PHASE_ERROR {96.948} CONFIG.CLKOUT2_JITTER {124.615} CONFIG.CLKOUT2_PHASE_ERROR {96.948}] [get_ips $ipName]


if { $boardName eq "digilentinc.com:zybo-z7-20:part0:1.0" } {
    error "Not yet created"
} elseif { $boardName eq "digilentinc.com:arty-s7-50:part0:1.0" } {
    set_property -dict [list CONFIG.Component_Name {axi_clock_converter} CONFIG.ADDR_WIDTH {64} CONFIG.DATA_WIDTH {64} CONFIG.ID_WIDTH {6} CONFIG.ACLK_ASYNC {1} CONFIG.SYNCHRONIZATION_STAGES {4}] [get_ips $ipName]
} else {
    error "No supported board specified"
}


generate_target {instantiation_template} [get_files ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
generate_target all [get_files  ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
launch_run -jobs 8 ${ipName}_synth_1
wait_on_run ${ipName}_synth_1