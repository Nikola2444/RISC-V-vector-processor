`ifndef BACKDOOR_INSTR_IF_SV
 `define BACKDOOR_INSTR_IF_SV

interface backdoor_instr_if (input clk, logic rstn);   
   logic 	  instr_ready;
   logic [31:0]   instr_mem_address;
   logic [31:0]   instr_mem_read;
   logic 	  instr_mem_flush;
   logic 	  instr_mem_en;
endinterface:backdoor_instr_if

interface backdoor_v_instr_if (input clk, logic rstn);   
   logic [3:0] 	  start;
   logic [3:0] 	  ready;
   logic [31:0]   v_instruction;
   logic [31:0]   v_rs1_scalar;
   logic [31:0]   v_rs2_scalar;
   logic [11:0]   v_instr_vld;
   logic [11:0]   v_instr_rdy;
   logic [2:0] 	  lmul;
   logic [2:0] 	  sew;
   logic [31:0]   vl;
   logic [31:0]   vrf_read_ram [`V_LANES][2][4][`VRF_DEPTH-1:0];
   
endinterface:backdoor_v_instr_if

interface backdoor_register_bank_if (input clk, logic rstn);   
   logic 	  rd_we_i;
   logic [4:0 ]   rs1_address_i;
   logic [4:0] 	  rs2_address_i;
   logic [31:0]   rs1_data_o ;
   logic [31:0]   rs2_data_o;   
   logic [4:0] 	  rd_address_i; 
   logic [31:0]   rd_data_i;
   logic [0:31][31:0] scalar_reg_bank;
endinterface:backdoor_register_bank_if

interface backdoor_sc_data_if (input clk, logic rstn);   
   logic 	  data_ready_i;
   logic [31:0]	  data_mem_address_o;
   logic [31:0]	  data_mem_read_i;
   logic [31:0]	  data_mem_write_o;
   logic 	  data_mem_we_o;
   logic 	  data_mem_re_o;
   
endinterface:backdoor_sc_data_if

interface backdoor_v_data_if (input clk, logic rstn, output reg [31:0] ddr_mem[`DDR_DEPTH]);   
   logic [31:0]   ctrl_raddr_offset_o;
   logic [31:0]   ctrl_rxfer_size_o;
   logic 	  ctrl_rstart_o;
   logic 	  rd_tready_o;
   logic [31:0]   rd_tdata_i;
   logic 	  rd_tvalid_i;
   logic 	  rd_tlast_i;
   logic 	  ctrl_rdone_i;

   logic [31:0]   ctrl_waddr_offset_o;
   logic [31:0]   ctrl_wxfer_size_o;
   logic [31:0]   wr_tdata_o;
   logic 	  ctrl_wstart_o;
   logic 	  wr_tvalid_o;
   logic 	  wr_tready_i;
   logic 	  ctrl_wdone_i;
endinterface:backdoor_v_data_if


`endif
