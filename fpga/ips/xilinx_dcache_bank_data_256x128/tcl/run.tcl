set partNumber $::env(XILINX_PART)
set boardName  $::env(XILINX_BOARD)

set ipName xilinx_dcache_bank_data_256x128

create_project $ipName . -force -part $partNumber
set_property board_part $boardName [current_project]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name $ipName

set_property -dict [list CONFIG.Use_Byte_Write_Enable {true} CONFIG.Byte_Size {8}  CONFIG.Write_Width_A {128} CONFIG.Write_Depth_A {256} CONFIG.Read_Width_A {128} CONFIG.Operating_Mode_A {READ_FIRST} CONFIG.Register_PortA_Output_of_Memory_Primitives {false}] [get_ips $ipName]

generate_target all [get_files ./${ipName}.srcs/sources_1/ip/${ipName}/${ipName}.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] ./${ipName}.srcs/sources_1/ip/${ipName}/${ipName}.xci]
launch_run -jobs 8 ${ipName}_synth_1
wait_on_run ${ipName}_synth_1

