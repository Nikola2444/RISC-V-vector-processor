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
#common
add_files -norecurse ..\/hdl\/common\/sdp_bram.sv
add_files -norecurse ..\/hdl\/common\/sdp_bwe_bram.sv
add_files -norecurse ..\/hdl\/common\/tdp_bram.sv
add_files -norecurse ..\/hdl\/common\/tdp_bwe_bram.sv

#vector lane
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/v_lane\/rtl\/vrf.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/v_lane\/rtl\/alu.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/v_lane\/rtl\/Vector_Lane.sv
#scheduler
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/scheduler\/rtl\/scheduler.sv
#vector core
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/rtl\/vector_core.sv
#scalar core
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
#axim controller
add_files -norecurse ..\/hdl\/riscv-v\/axim_ctrl\/rtl\/axim_ctrl_counter.sv
add_files -norecurse ..\/hdl\/riscv-v\/axim_ctrl\/rtl\/axim_ctrl_axi_read_master.sv
add_files -norecurse ..\/hdl\/riscv-v\/axim_ctrl\/rtl\/axim_ctrl_axi_write_master.sv
add_files -norecurse ..\/hdl\/riscv-v\/axim_ctrl\/rtl\/axim_ctrl.sv
#top files
add_files -norecurse ..\/hdl\/riscv-v\/rtl\/riscv_v.sv
add_files -norecurse ..\/hdl\/riscv-v\/rtl\/riscv_v_w_mem_subsystem.sv

set_property top riscv_v_w_mem_subsystem [current_fileset]
#verification files

add_files -fileset sim_1 -norecurse ..\/verif\/bd_instr_if_Agent\/bd_instr_if_agent_pkg.sv
add_files -fileset sim_1 -norecurse ..\/verif\/Sequences\/riscv_v_seq_pkg.sv
add_files -fileset sim_1 -norecurse ..\/verif\/Configurations\/configurations_pkg.sv
add_files -fileset sim_1 -norecurse ..\/verif\/Assembly_code\/assembly_test.b
add_files -fileset sim_1 -norecurse ..\/verif\/test_pkg.sv
add_files -fileset sim_1 -norecurse ..\/verif\/top.sv



update_compile_order -fileset sources_1
