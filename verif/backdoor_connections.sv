`ifndef BACKDOOR_CONNECTIONS_SV
`define BACKDOOR_CONNECTIONS_SV
assign DUT.instr_ready = backdoor_instr_vif.instr_ready; 
assign DUT.instr_mem_read=backdoor_instr_vif.instr_mem_read;
assign DUT.data_ready=1'b1;
assign backdoor_instr_vif.instr_mem_address = DUT.instr_mem_address;
assign backdoor_instr_vif.instr_mem_flush = DUT.instr_mem_flush;
assign backdoor_instr_vif.instr_mem_en = DUT.instr_mem_en;

`endif
