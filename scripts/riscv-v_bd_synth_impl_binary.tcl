#process for getting script file directory
variable dispScriptFile [file normalize [info script]]
proc getScriptDirectory {} {
    variable dispScriptFile
    set scriptFolder [file dirname $dispScriptFile]
    return $scriptFolder
}

# change working directory to script file directory
cd [getScriptDirectory]
# set result directory
set resultDir .\/result\/RISCV_AXI_system
# set release directory
set releaseDir .\/release\/RISCV_AXI_system
# set ip_repo_path to script dir
set ip_repo_path .\/release

file mkdir $resultDir
file mkdir $releaseDir

# Create project
create_project RISCV_V_AXI_project $resultDir -part xc7z020clg484-1 -force
set boardpart [get_board_parts -filter {BOARD_NAME=~zed*}]
set_property board_part $boardpart [current_project]

# Create block design
create_bd_design "riscv_v_axi_bd"
update_compile_order -fileset sources_1

# Add ip-s to main repo
set_property  ip_repo_paths  $ip_repo_path [current_project]
update_ip_catalog

# Zynq processing system
update_compile_order -fileset sources_1
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
endgroup
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
startgroup
set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {1} CONFIG.PCW_USE_S_AXI_HP1 {1}] [get_bd_cells processing_system7_0]
set_property -dict [list CONFIG.PCW_USE_FABRIC_INTERRUPT {1} CONFIG.PCW_IRQ_F2P_INTR {1}] [get_bd_cells processing_system7_0]
set_property -dict [list CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100.000000}] [get_bd_cells processing_system7_0]
endgroup

# Add RISCV-V // 8lanes 4096vlen
startgroup
create_bd_cell -type ip -vlnv FTN:ftn_cores:RISCV_V:1.0 RISCV_V_0
set_property -dict [list CONFIG.VLEN {4096} CONFIG.V_LANES {8}] [get_bd_cells RISCV_V_0]
endgroup
# Connect Interrupt signal
connect_bd_net [get_bd_pins RISCV_V_0/interrupt_o] [get_bd_pins processing_system7_0/IRQ_F2P]


# Instantiate Smartconnects and conenct AXIFull interfaces
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0
endgroup
set_property -dict [list CONFIG.NUM_SI {1}] [get_bd_cells smartconnect_0]
copy_bd_objs /  [get_bd_cells {smartconnect_0}]
connect_bd_intf_net [get_bd_intf_pins RISCV_V_0/s_m_axi] [get_bd_intf_pins smartconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
connect_bd_intf_net [get_bd_intf_pins RISCV_V_0/v_m_axi] [get_bd_intf_pins smartconnect_1/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins smartconnect_1/M00_AXI] [get_bd_intf_pins processing_system7_0/S_AXI_HP1]

# Create clocking wizard
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0
set_property -dict [list CONFIG.CLKOUT2_USED {true} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50.000} CONFIG.MMCM_CLKOUT0_DIVIDE_F {20.000} CONFIG.MMCM_CLKOUT1_DIVIDE {10} CONFIG.NUM_OUT_CLKS {2} CONFIG.CLKOUT1_JITTER {151.636} CONFIG.CLKOUT2_JITTER {130.958} CONFIG.CLKOUT2_PHASE_ERROR {98.575}] [get_bd_cells clk_wiz_0]
set_property -dict [list CONFIG.USE_LOCKED {false} CONFIG.USE_RESET {false}] [get_bd_cells clk_wiz_0]
endgroup

#Connect PS clock to input of clock wizard
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins clk_wiz_0/clk_in1]

#Create AXI Interconnect
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_0/clk_out1 (50 MHz)} Clk_slave {/clk_wiz_0/clk_out1 (50 MHz)} Clk_xbar {/clk_wiz_0/clk_out1 (50 MHz)} Master {/processing_system7_0/M_AXI_GP0} Slave {/RISCV_V_0/s_axi} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins RISCV_V_0/s_axi]

#Connect reset and clocks
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {Auto}}  [get_bd_pins rst_clk_wiz_0_50M/ext_reset_in]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins RISCV_V_0/s_axi_aclk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins smartconnect_0/aclk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins smartconnect_1/aclk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins processing_system7_0/S_AXI_HP1_ACLK]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins RISCV_V_0/clk2]
connect_bd_net [get_bd_pins RISCV_V_0/rstn2] [get_bd_pins rst_clk_wiz_0_50M/peripheral_aresetn]
connect_bd_net [get_bd_pins smartconnect_1/aresetn] [get_bd_pins rst_clk_wiz_0_50M/peripheral_aresetn]
connect_bd_net [get_bd_pins smartconnect_0/aresetn] [get_bd_pins rst_clk_wiz_0_50M/peripheral_aresetn]
connect_bd_net [get_bd_pins RISCV_V_0/s_axi_aresetn] [get_bd_pins rst_clk_wiz_0_50M/peripheral_aresetn]

# Assign address to AXI masters? 
assign_bd_address -target_address_space /RISCV_V_0/s_m_axi [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] -force
assign_bd_address -target_address_space /RISCV_V_0/v_m_axi [get_bd_addr_segs processing_system7_0/S_AXI_HP1/HP1_DDR_LOWOCM] -force

# Regenerate layout
regenerate_bd_layout


# Create BD wrapper
make_wrapper -files [get_files $resultDir/RISCV_V_AXI_project.srcs/sources_1/bd/riscv_v_axi_bd/riscv_v_axi_bd.bd] -top
add_files -norecurse $resultDir/RISCV_V_AXI_project.srcs/sources_1/bd/riscv_v_axi_bd/hdl/riscv_v_axi_bd_wrapper.v


#Run synthesis
#launch_runs synth_1 -jobs 4

#Run implementation
#launch_runs impl_1 -to_step write_bitstream -jobs 4

#wait on implementation
#wait_on_run impl_1

#puts "* Synthesis & Implementation Finished *"

#update_compile_order -fileset sources_1
