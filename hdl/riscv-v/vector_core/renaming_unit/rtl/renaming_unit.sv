  module renaming_unit#
  (parameter VLEN=4096,   
   parameter VLANE_NUM=8,	
   parameter R_PORTS_NUM = 8,
   parameter W_PORTS_NUM = 4)
   (/*AUTOARG*/
   // Outputs
   vrf_starting_addr_vld_o, vrf_starting_waddr_o,
   vrf_starting_raddr0_o, vrf_starting_raddr1_o,
   // Inputs
   instr_vld_i, vector_instr_i
   );

   
   localparam MEM_DEPTH=VLEN/VLANE_NUM;
   localparam LP_V_REGISTER_WORD_LEN = 32;
   localparam LP_VECTOR_REG_SIZE=VLEN/LP_V_REGISTER_WORD_LEN/VLANE_NUM;
   //input clk,
   //input 					 rstn,
   input [12:0]	instr_vld_i;
   input [31:0] vector_instr_i;

   // We concatanate 8 pointers to max eight registers, because that is the worst
   // case when LMUL=8;
   output logic vrf_starting_addr_vld_o;
   (* dont_touch = "yes" *)output logic [8*$clog2(MEM_DEPTH)-1:0]  vrf_starting_waddr_o;
   (* dont_touch = "yes" *)output logic [8*$clog2(MEM_DEPTH)-1:0]  vrf_starting_raddr0_o;
   (* dont_touch = "yes" *)output logic [8*$clog2(MEM_DEPTH)-1:0]  vrf_starting_raddr1_o;


   //output 					 addresses_vld_o

   
   

   (* dont_touch = "yes" *) logic [8*$clog2(MEM_DEPTH)-1:0] 	 base_addr_vs1;
   (* dont_touch = "yes" *) logic [8*$clog2(MEM_DEPTH)-1:0] 	 base_addr_vs2;
   (* dont_touch = "yes" *) logic [8*$clog2(MEM_DEPTH)-1:0] 	 base_addr_vd;
   
   logic [4:0] 	v_instr_vs1;
   logic [4:0] 	v_instr_vs2;
   logic [4:0] 	v_instr_vd;

   assign v_instr_vs1 = instr_vld_i[2] || instr_vld_i[3] ? vector_instr_i[11:7] :  instr_vld_i[10] || instr_vld_i[7] || instr_vld_i[9] ? vector_instr_i[24:20] : vector_instr_i[19:15];
   assign v_instr_vs2 = vector_instr_i[24:20];
   assign v_instr_vd = vector_instr_i[11:7];
   
   
   // Currently renaming is not implemented, but in the future this will change.
   typedef logic [31:0][8*$clog2(MEM_DEPTH)-1:0] base_addr_array;
   localparam base_addr_array base_addresses=init_base_addr();
   function base_addr_array init_base_addr();
      base_addr_array base_addresses1;
      for (logic [$clog2(MEM_DEPTH)-1:0] i = 'h0; i<'h20; i++)
      begin
	 base_addresses1[i] = i * LP_VECTOR_REG_SIZE;
	 //base_addresses1[i] = i;
      end
      return base_addresses1;	
   endfunction // init_base_addr
   



   generate
      for (genvar i=0; i<8; i++)
      begin
	 assign base_addr_vs1[i*$clog2(MEM_DEPTH) +: $clog2(MEM_DEPTH)] = base_addresses[v_instr_vs1+i];
	 assign base_addr_vs2[i*$clog2(MEM_DEPTH) +: $clog2(MEM_DEPTH)] = base_addresses[v_instr_vs2+i];
	 assign base_addr_vd[i*$clog2(MEM_DEPTH)  +: $clog2(MEM_DEPTH)] = base_addresses[v_instr_vd+i];
      end
   endgenerate
   
   assign vrf_starting_raddr0_o=base_addr_vs1;
   assign vrf_starting_raddr1_o=base_addr_vs2;
   assign vrf_starting_waddr_o=base_addr_vd;
   assign vrf_starting_addr_vld_o = 1'b1;
   
endmodule
