# create project
create_project kerbin . -force -part $::env(XILINX_PART)
set_property board_part $::env(XILINX_BOARD) [current_project]

debug::set_visibility 10

# set up includes
# source tcl/ips_inc_dirs.tcl
set_property include_dirs { ../../include } [current_fileset]

# set up meaningful errors
source ../common/messages.tcl

# setup source files
# source tcl/ips_src_files.tcl
# source tcl/rtl_src_files.tcl

# add_files -v -norecurse -scan_for_includes ../rtl
add_files -v -scan_for_includes ../../src
add_files -v -scan_for_includes ../../include


# add IPs
# source tcl/ips_add_files.tcl
# source tcl/rtl_add_files.tcl

# add memory cuts
read_ip ../ips/xilinx_dcache_bank_data_256x128/ip/xilinx_dcache_bank_data_256x128.xci
read_ip ../ips/xilinx_dcache_bank_tag_256x46/ip/xilinx_dcache_bank_tag_256x46.xci
# read_ip ../ips/xilinx_l2_mem_4096x64/ip/xilinx_l2_mem_4096x64.xci
# read_ip ../ips/xilinx_mig7_ddr3/ip/xilinx_mig7_ddr3.xci
# read_ip ../ips/xilinx_clock_manager/ip/xilinx_clock_manager.xci

# synth_ip [get_ips xilinx_dcache_bank_data_256x128]
# synth_ip [get_ips xilinx_dcache_bank_tag_256x46]
# synth_ip [get_ips xilinx_icache_bank_data_512x64]
# synth_ip [get_ips xilinx_mig7_ddr3]
# synth_ip [get_ips xilinx_clock_manager]

# set kerbin as top
# set_property top kerbin [current_fileset]
set_property top ariane [current_fileset]

# needed only if used in batch mode
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# add constraints (timing and cdc)
# add_files -fileset constrs_1 -norecurse tcl/constraints.xdc
# set_property target_constrs_file tcl/constraints.xdc [current_fileset -constrset]

catch { synth_design -retiming -rtl -name rtl_1 -verilog_define SYNTHESIS -verilog_define PULP_FPGA_EMUL }
update_compile_order -fileset sources_1
synth_design -retiming -rtl -name rtl_1 -verilog_define SYNTHESIS -verilog_define PULP_FPGA_EMUL

set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.GATED_CLOCK_CONVERSION on [get_runs synth_1]

launch_runs synth_1
wait_on_run synth_1
open_run synth_1

# hook up debug
# source tcl/debug.tcl

# reports
exec mkdir -p reports/
exec rm -rf reports/*

check_timing                                                            -file reports/kerbin.check_timing.rpt
report_timing -max_paths 100 -nworst 100 -delay_type max -sort_by slack -file reports/kerbin.timing_WORST_100.rpt
report_timing -nworst 1 -delay_type max -sort_by group                  -file reports/kerbin.timing.rpt
report_utilization -hierarchical                                        -file reports/kerbin.utilization.rpt
report_cdc                                                              -file reports/kerbin.cdc.rpt
report_clock_interaction                                                -file reports/kerbin.clock_interaction.rpt

# physical constraints
# source tcl/kerbin_io.xdc

# # set number of threads to 8 (maximum, unfortunately)
set_param general.maxThreads 8

# set for RuntimeOptimized implementation
# set_property "steps.opt_design.args.directive" "RuntimeOptimized" [get_runs impl_1]
# set_property "steps.place_design.args.directive" "RuntimeOptimized" [get_runs impl_1]
# set_property "steps.route_design.args.directive" "RuntimeOptimized" [get_runs impl_1]

# launch_runs impl_1
# wait_on_run impl_1
# launch_runs impl_1 -to_step write_bitstream
# wait_on_run impl_1
# open_run impl_1

# # # output Verilog netlist + SDC for timing simulation
# write_verilog -force -mode funcsim kerbin_funcsim.v
# write_verilog -force -mode timesim kerbin_timesim.v
# write_sdf     -force kerbin_timesim.sdf

# # reports
# exec mkdir -p reports/
# exec rm -rf reports/*
# check_timing                                                                                         -file reports/kerbin.check_timing.rpt
# report_timing -max_paths 100 -nworst 100 -delay_type max -sort_by slack                              -file reports/kerbin.timing_WORST_100.rpt
# report_timing -nworst 1 -delay_type max -sort_by group                                               -file reports/kerbin.timing.rpt
# report_utilization -hierarchical                                                                     -file reports/kerbin.utilization.rpt


