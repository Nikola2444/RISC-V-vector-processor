`ifndef BACKDOOR_INSTR_IF_SV
 `define BACKDOOR_INSTR_IF_SV

interface backdoor_instr_if (input clk, logic rstn);   
   logic 	  instr_ready;
   logic [31:0]   instr_mem_address;
   logic [31:0]   instr_mem_read;
   logic 	  instr_mem_flush;
   logic 	  instr_mem_en;   
endinterface:backdoor_instr_if
`endif
