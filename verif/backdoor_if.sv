`ifndef BACKDOOR_INSTR_IF_SV
 `define BACKDOOR_INSTR_IF_SV

interface backdoor_instr_if (input clk, logic rstn);   
   logic 	  instr_ready;
   logic [31:0]   instr_mem_address;
   logic [31:0]   instr_mem_read;
   logic 	  instr_mem_flush;
   logic 	  instr_mem_en;
endinterface:backdoor_instr_if

interface backdoor_register_bank_if (input clk, logic rstn);   
   logic 	  rd_we_i;
   logic 	  rs1_address_i[4:0];
   logic 	  rs2_address_i[4:0];
   logic 	  rs1_data_o [31:0];
   logic 	  rs2_data_o[31:0];   
   logic 	  rd_address_i[4:0]; 
   logic 	  rd_data_i[31:0];
endinterface:backdoor_register_bank_if
`endif
