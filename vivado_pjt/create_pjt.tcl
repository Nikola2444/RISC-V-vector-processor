variable dispScriptFile [file normalize [info script]]

proc getScriptDirectory {} {
    variable dispScriptFile
    set scriptFolder [file dirname $dispScriptFile]
    return $scriptFolder
}

set sdir [getScriptDirectory]
cd [getScriptDirectory]

# KORAK#1: Definisanje direktorijuma u kojima ce biti smesteni projekat i konfiguracioni fajl
set resultDir result
file mkdir $resultDir
create_project riscv_v_pjt result -part xc7z010clg400-1 -force

set_property -name {xsim.elaborate.xelab.more_options} -value {-L uvm} -objects [get_filesets sim_1]
set_property -name {xsim.compile.xvlog.more_options} -value {-L uvm} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg UVM_TESTNAME=test_simple -testplusarg UVM_VERBOSITY=UVM_LOW} -objects [get_filesets sim_1]

# KORAK#2: Ukljucivanje svih izvornih fajlova u projekat
#packages
add_files -norecurse ..\/hdl\/packages\/typedef_pkg.sv
add_files -norecurse ..\/hdl\/packages\/util_pkg.vhd
add_files -norecurse ..\/hdl\/packages\/cache_pkg.vhd
#common
add_files -norecurse ..\/hdl\/common\/ram_tdp_rf.vhd
add_files -norecurse ..\/hdl\/common\/ram_sp_ar.vhd
add_files -norecurse ..\/hdl\/common\/ram_sp_ar_bw.vhd

add_files -norecurse ..\/hdl\/common\/sdp_bram.sv
add_files -norecurse ..\/hdl\/common\/sdp_bwe_bram.sv
add_files -norecurse ..\/hdl\/common\/tdp_bram.sv
add_files -norecurse ..\/hdl\/common\/tdp_bwe_bram.sv
add_files -norecurse ..\/hdl\/common\/sdp_distram.sv

#vector lane
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/v_lane\/rtl\/vrf.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/v_lane\/rtl\/alu.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/v_lane\/rtl\/alu_submodule.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/v_lane\/rtl\/Vector_Lane.sv
#scheduler
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/scheduler\/rtl\/scheduler.sv
#v_cu
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/v_cu\/rtl\/v_cu.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/v_cu\/rtl\/Address_counter.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/v_cu\/rtl\/Column_offset_register.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/v_cu\/rtl\/Complete_sublane_driver.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/v_cu\/rtl\/Complete_sublane_driver_new.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/v_cu\/rtl\/Data_validation.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/v_cu\/rtl\/Driver_vlane_interconnect.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/v_cu\/rtl\/Partial_sublane_driver.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/v_cu\/rtl\/port_allocate_unit.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/v_cu\/rtl\/renaming_unit.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/v_cu\/rtl\/Vlane_with_low_lvl_ctrl.sv
#vector core
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/rtl\/vector_core.sv
#scalar core
add_files -norecurse ..\/hdl\/riscv-v\/scalar_core\/rtl\/white_box.sv
add_files -norecurse ..\/hdl\/riscv-v\/scalar_core\/rtl\/alu_decoder.vhd
add_files -norecurse ..\/hdl\/riscv-v\/scalar_core\/rtl\/ALU.vhd
add_files -norecurse ..\/hdl\/riscv-v\/scalar_core\/rtl\/control_path.vhd
add_files -norecurse ..\/hdl\/riscv-v\/scalar_core\/rtl\/ctrl_decoder.vhd
add_files -norecurse ..\/hdl\/riscv-v\/scalar_core\/rtl\/data_path.vhd
add_files -norecurse ..\/hdl\/riscv-v\/scalar_core\/rtl\/forwarding_unit.vhd
add_files -norecurse ..\/hdl\/riscv-v\/scalar_core\/rtl\/hazard_unit.vhd
add_files -norecurse ..\/hdl\/riscv-v\/scalar_core\/rtl\/immediate.vhd
add_files -norecurse ..\/hdl\/riscv-v\/scalar_core\/rtl\/register_bank.vhd
add_files -norecurse ..\/hdl\/riscv-v\/scalar_core\/rtl\/TOP_RISCV.vhd
#axim controller for vector core
add_files -norecurse ..\/hdl\/riscv-v\/vector_axif_m_ctrl\/rtl\/axim_ctrl_counter.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_axif_m_ctrl\/rtl\/axim_ctrl_axi_read_master.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_axif_m_ctrl\/rtl\/axim_ctrl_axi_write_master.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_axif_m_ctrl\/rtl\/axim_ctrl.sv

#axim controller for scalar core
add_files -norecurse ..\/hdl\/riscv-v\/scalar_axil_s_ctrl/rtl/riscv_axil_s_ctrl.vhd
add_files -norecurse ..\/hdl\/riscv-v\/scalar_axif_m_ctrl/rtl/riscv_axif_m_ctrl.vhd
#mem_subsystem
add_files -norecurse ..\/hdl\/riscv-v\/scalar_cache\/rtl\/cache_contr_nway_vnv_axi.vhd
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/mem_subs\/m_cu\/rtl\/axi_m_controller.v
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/mem_subs\/m_cu\/rtl\/m_cu.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/mem_subs\/buff_array\/rtl\/buff_array.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/mem_subs\/rtl/mem_subsys.sv


#top files
add_files -norecurse ..\/hdl\/riscv-v\/rtl\/riscv_v.sv
add_files -norecurse ..\/hdl\/riscv-v\/rtl\/riscv_v_w_mem_subsystem.sv

set_property top riscv_v_w_mem_subsystem [current_fileset]
#verification files
add_files -fileset sim_1 -norecurse ..\/verif\/bd_v_instr_if_Agent\/bd_v_instr_if_agent_pkg.sv
add_files -fileset sim_1 -norecurse ..\/verif\/bd_instr_if_Agent\/bd_instr_if_agent_pkg.sv
add_files -fileset sim_1 -norecurse ..\/verif\/bd_v_data_if_Agent\/bd_v_data_if_agent_pkg.sv
add_files -fileset sim_1 -norecurse ..\/verif\/AXI4_Agent\/AXI4_agent_pkg.sv
add_files -fileset sim_1 -norecurse ..\/verif\/Sequences\/riscv_v_seq_pkg.sv
add_files -fileset sim_1 -norecurse ..\/verif\/Configurations\/configurations_pkg.sv
add_files -fileset sim_1 -norecurse ..\/verif\/Assembly_code\/assembly_test.b
add_files -fileset sim_1 -norecurse ..\/verif\/test_pkg.sv
add_files -fileset sim_1 -norecurse ..\/verif\/top.sv



update_compile_order -fileset sources_1

