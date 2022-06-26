variable dispScriptFile [file normalize [info script]]
proc getScriptDirectory {} {
    variable dispScriptFile
    set scriptFolder [file dirname $dispScriptFile]
    return $scriptFolder
}

set sdir [getScriptDirectory]
cd [getScriptDirectory]

# SETTING PATHS, CREATING PROJECT

set rootDir .
set resultDir $rootDir\/result\/RISCV_V_AXI_IP
set releaseDir $rootDir\/release\/RISCV_V_AXI_IP
file mkdir $resultDir
file mkdir $releaseDir

create_project RISCV_V_AXI_project $resultDir -part xc7z020clg484-1 -force
set_property board_part avnet.com:zedboard:part0:1.4 [current_project]



# ADDING FILES
add_files -norecurse ..\/hdl\/packages\/typedef_pkg.sv
add_files -norecurse ..\/hdl\/packages\/util_pkg.vhd
add_files -norecurse ..\/hdl\/packages\/cache_pkg.vhd
#common
add_files -norecurse ..\/hdl\/common\/ram_tdp_rf.vhd
add_files -norecurse ..\/hdl\/common\/ram_sp_ar.vhd
add_files -norecurse ..\/hdl\/common\/ram_sp_ar_bw.vhd
add_files -norecurse ..\/hdl\/common\/sdp_bwe_bram.sv
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
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/mem_subs\/m_cu\/rtl\/m_cu.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/mem_subs\/buff_array\/rtl\/buff_array.sv
add_files -norecurse ..\/hdl\/riscv-v\/vector_core\/mem_subs\/rtl/mem_subsys.sv


#top files
add_files -norecurse ..\/hdl\/riscv-v\/rtl\/riscv_v.sv
add_files -norecurse ..\/hdl\/riscv-v\/rtl\/riscv_v_w_mem_subsystem.sv

update_compile_order -fileset sources_1


ipx::package_project -root_dir $releaseDir -vendor ftn.uns.ac.rs -library ftn_cores -taxonomy /UserIP -import_files -set_current false
ipx::unload_core $releaseDir\/component.xml
ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory $releaseDir $releaseDir\/component.xml
update_compile_order -fileset sources_1

# SETTING IP FEILDS
set_property vendor FTN [ipx::current_core]
set_property name RISCV_V [ipx::current_core]
set_property display_name RISCV_V [ipx::current_core]
set_property description {RV32I scalar core with two levels of cache, and a customizable vector core} [ipx::current_core]
set_property company_url http://www.fnt.uns.ac.rs [ipx::current_core]
set_property vendor_display_name FTN [ipx::current_core]
set_property taxonomy {/Embedded_Processing/AXI_Peripheral /UserIP} [ipx::current_core]
set_property supported_families {zynq Production} [ipx::current_core]


# SETTING VISIBLE PARAMETERS
ipgui::add_param -name {V_LANES} -component [ipx::current_core]
ipgui::add_param -name {CHAINING} -component [ipx::current_core]
ipgui::add_param -name {C_BLOCK_SIZE} -component [ipx::current_core]
ipgui::add_param -name {C_LVL1_CACHE_SIZE} -component [ipx::current_core]
ipgui::add_param -name {C_LVL2_CACHE_SIZE} -component [ipx::current_core]
ipgui::add_param -name {C_LVL2_CACHE_NWAY} -component [ipx::current_core]



ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "VLEN" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 1 [ipgui::get_guiparamspec -name "V_LANES" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 2 [ipgui::get_guiparamspec -name "CHAINING" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 3 [ipgui::get_guiparamspec -name "C_BLOCK_SIZE" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 4 [ipgui::get_guiparamspec -name "C_LVL1_CACHE_SIZE" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 5 [ipgui::get_guiparamspec -name "C_LVL2_CACHE_SIZE" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 6 [ipgui::get_guiparamspec -name "C_LVL2_CACHE_NWAY" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]


set_property core_revision 2 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]

set_property  ip_repo_paths $releaseDir  [current_project]
update_ip_catalog
ipx::check_integrity -quiet [ipx::current_core]
ipx::archive_core $releaseDir\/FTN_RISCV-V_1.0.zip [ipx::current_core]
close_project
close_project
