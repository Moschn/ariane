set partNumber $::env(XILINX_PART)
set boardName  $::env(XILINX_BOARD)

create_project xilinx_mig7_ddr3 . -force -part $partNumber
set_property board_part $boardName [current_project]

create_ip -name mig_7series -vendor xilinx.com -library ip -version 4.1 -module_name xilinx_mig7_ddr3

if { $boardName eq "digilentinc.com:zybo-z7-20:part0:1.0" } {
    exec cp mig_a_zybo.prj ./xilinx_mig7_ddr3.srcs/sources_1/ip/xilinx_mig7_ddr3/mig_a.prj
} elseif { $boardName eq "digilentinc.com:arty-s7-50:part0:1.0" } {
    exec cp mig_a_arty.prj ./xilinx_mig7_ddr3.srcs/sources_1/ip/xilinx_mig7_ddr3/mig_a.prj
} else {
    error "No supported board specified"
}


set_property -dict [list CONFIG.XML_INPUT_FILE {mig_a.prj} CONFIG.RESET_BOARD_INTERFACE {Custom} CONFIG.MIG_DONT_TOUCH_PARAM {Custom} CONFIG.BOARD_MIG_PARAM {Custom}] [get_ips xilinx_mig7_ddr3]
generate_target {instantiation_template} [get_files ./xilinx_mig7_ddr3.srcs/sources_1/ip/xilinx_mig7_ddr3/xilinx_mig7_ddr3.xci]
update_compile_order -fileset sources_1
generate_target all [get_files  ./xilinx_mig7_ddr3.srcs/sources_1/ip/xilinx_mig7_ddr3/xilinx_mig7_ddr3.xci]
catch { config_ip_cache -export [get_ips -all xilinx_mig7_ddr3] }
export_ip_user_files -of_objects [get_files ./xilinx_mig7_ddr3.srcs/sources_1/ip/xilinx_mig7_ddr3/xilinx_mig7_ddr3.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] ./xilinx_mig7_ddr3.srcs/sources_1/ip/xilinx_mig7_ddr3/xilinx_mig7_ddr3.xci]

launch_runs -jobs 4 xilinx_mig7_ddr3_synth_1
wait_on_run xilinx_mig7_ddr3_synth_1

