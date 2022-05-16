`ifndef BACKDOOR_CONNECTIONS_SV
 `define BACKDOOR_CONNECTIONS_SV
// This file just connects inner DUT connections to signals defined in the top.sv.
// This is needed because some verification components need to see these inner signals
// for automated checking.

// Instruction interface backdoor connections
assign DUT.instr_ready = backdoor_instr_vif.instr_ready; 
assign DUT.instr_mem_read=backdoor_instr_vif.instr_mem_read;
assign backdoor_instr_vif.instr_mem_address = DUT.instr_mem_address;
assign backdoor_instr_vif.instr_mem_flush = DUT.instr_mem_flush;
assign backdoor_instr_vif.instr_mem_en = DUT.instr_mem_en;

// Register bank backdoor connections
assign backdoor_register_bank_vif.rd_we_i=DUT.riscv_v_inst.scalar_core_inst.data_path_1.white_box_inst.rd_we_i;
assign backdoor_register_bank_vif.rs1_address_i=DUT.riscv_v_inst.scalar_core_inst.data_path_1.white_box_inst.rs1_address_i;
assign backdoor_register_bank_vif.rs2_address_i=DUT.riscv_v_inst.scalar_core_inst.data_path_1.white_box_inst.rs2_address_i;
assign backdoor_register_bank_vif.rs1_data_o=DUT.riscv_v_inst.scalar_core_inst.data_path_1.white_box_inst.rs1_data_o;
assign backdoor_register_bank_vif.rs2_data_o=DUT.riscv_v_inst.scalar_core_inst.data_path_1.white_box_inst.rs2_data_o;
assign backdoor_register_bank_vif.rd_address_i=DUT.riscv_v_inst.scalar_core_inst.data_path_1.white_box_inst.rd_address_i;
assign backdoor_register_bank_vif.rd_data_i=DUT.riscv_v_inst.scalar_core_inst.data_path_1.white_box_inst.rd_data_i;

// Scalaro core data interface

//assign DUT.data_ready = backdoor_sc_data_if.data_ready_i;
assign DUT.data_ready=1'b1;
assign backdoor_sc_data_vif.data_mem_address_o=DUT.data_mem_address; 
assign DUT.data_mem_read = backdoor_sc_data_vif.data_mem_read_i;
assign backdoor_sc_data_vif.data_mem_write_o=DUT.data_mem_write;
assign backdoor_sc_data_vif.data_mem_we_o=DUT.data_mem_we;
assign backdoor_sc_data_vif.data_mem_re_o=DUT.data_mem_re; 




`endif
