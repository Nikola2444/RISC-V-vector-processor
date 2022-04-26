//this component is responsible for issuing instruction to V_CU if there
// are resources available, and also it is responbile for providing M_CU with
// information about ld and st instructions.


`include "../../../../packages/typedef_pkg.sv"
module scheduler
  (input logic clk,
   input logic 	       rstn,
   // Scalar-Vector interface
   input logic [31:0]  vector_instr_i,
   input logic [31:0]  rs1_i,
   input logic [31:0]  rs2_i,
   output logic        vector_rdy_o,
   // Scheduler-V_CU interface
   input logic [10:0]  instr_rdy_i,
   output logic [10:0] instr_vld_o,
   output logic [31:0] vector_instr_o,
   // Scheduler-M_CU interface
   input logic 	       ld_rdy_i,
   input logic 	       ld_buffered_i,
   input logic 	       st_rdy_i,
   output logic        st_vld_i,
   output logic        ld_vld_i
   );


   logic [31:0]        vector_instr_reg, vector_instr_next;
   logic 	       v_st_instr_check;
   logic 	       v_ld_instr_check;
   logic 	       v_arith_instr_check;

   logic 	       v_OPIVI_check;
   logic 	       v_OPIVX_check;
   logic 	       v_OPIVV_check;
   logic 	       v_OPFVV_check;
   logic 	       v_OPFVF_check;
   logic 	       v_OPMVV_check;
   logic 	       v_OPMVX_check;
   logic 	       v_OPCFG_check;

   logic 	       v_strided_check;
   logic 	       v_unit_check;
   logic 	       v_idx_unordered_check;
   logic 	       v_idx_ordered_check;
   
   logic [6:0] 	       v_instr_opcode;
   logic [2:0] 	       v_instr_funct6_upper;
   logic [2:0] 	       v_instr_funct3;
   logic [1:0] 	       v_instr_mop;

   logic 	       next_instr_rdy;

   assign v_instr_opcode       = vector_instr_reg[6:0];
   assign v_instr_funct3       = vector_instr_reg[14:12];
   assign v_instr_mop          = vector_instr_reg[27:26];
   assign v_instr_funct6_upper = vector_instr_reg[31:29];

   always @(posedge clk)
   begin
      if (!rstn)
      begin
	 vector_instr_reg <= 'h0;
      end
      else
      begin
	 vector_instr_reg <= vector_instr_next;
      end
   end
   assign vector_instr_next = vector_rdy_o ? vector_instr_i : vector_instr_reg;

   //combinational logic bellow checks the opcode field of an
   //vector instruction
   always_comb
   begin
      v_st_instr_check = 1'b0;
      v_ld_instr_check = 1'b0;
      v_arith_instr_check = 1'b0;
      if (v_instr_opcode == v_st_opcode)
	v_st_instr_check = 1'b1;
      if (v_instr_opcode == v_ld_opcode)
	v_ld_instr_check = 1'b1;
      if (v_instr_opcode == v_arith_opcode)
	v_arith_instr_check = 1'b1;     
   end
   always_comb
   begin
      v_OPIVV_check = 1'b0;
      v_OPIVI_check = 1'b0;
      v_OPIVX_check = 1'b0;
      v_OPMVV_check = 1'b0;
      v_OPMVX_check = 1'b0;
      v_OPFVV_check = 1'b0;
      v_OPFVF_check = 1'b0;
      v_OPCFG_check = 1'b0;

      if (v_instr_funct3==OPIVV)
	v_OPIVV_check = 1'b1;
      if (v_instr_funct3==OPIVI)
	v_OPIVI_check = 1'b1;
      if (v_instr_funct3==OPIVX)
	v_OPIVX_check = 1'b1;
      if (v_instr_funct3==OPMVV)
	v_OPMVV_check = 1'b1;
      if (v_instr_funct3==OPMVX)
	v_OPMVX_check = 1'b1;
      if (v_instr_funct3==OPFVV)
	v_OPFVV_check = 1'b1;
      if (v_instr_funct3==OPFVF)
	v_OPFVF_check = 1'b1;
      if (v_instr_funct3==OPCFG)
	v_OPCFG_check = 1'b1;
   end

   // combinational logic bellow checks mop field of a
   // vector instruction
   always_comb
   begin
      v_unit_check = 1'b0;
      v_strided_check = 1'b0;
      v_idx_unordered_check = 1'b0;
      v_idx_ordered_check = 1'b0;
      if (v_instr_mop == unit_stride)
	v_unit_check = 1'b1;
      if (v_instr_mop == strided)
	v_strided_check = 1'b1;
      if (v_instr_mop == idx_unordered)
	v_idx_unordered_check = 1'b1;
      if (v_instr_mop == idx_ordered)
	v_idx_ordered_check = 1'b1;
   end

   //combinational logic bellow checks funct3 field of an 
   //vector instruction
   
   always_comb
   begin
      instr_vld_o = 'h0;
      if (v_st_instr_check)
      begin
	 if (v_strided_check || v_unit_check)
	   instr_vld_o = STORE_vld;
	 else if (v_idx_ordered_check || v_idx_unordered_check)
	   instr_vld_o = STORE_IDX_vld;
      end
      if (v_ld_instr_check)
      begin
	 if (v_strided_check || v_unit_check)
	   instr_vld_o = LOAD_vld;
	 else if (v_idx_ordered_check || v_idx_unordered_check)
	   instr_vld_o = LOAD_IDX_vld;
      end
      if (v_arith_instr_check)
      begin
	 if (v_OPIVV_check)
	   instr_vld_o = OPIVV_vld;
	 if (v_OPIVI_check)
	   instr_vld_o = OPIVI_vld;
	 if (v_OPIVX_check)
	   instr_vld_o = OPIVX_vld;
	 if (v_OPMVV_check)
	   if (v_instr_funct6_upper==3'b101)
	     instr_vld_o = OPMVV_101xxx_vld;
	   else
	     instr_vld_o = OPMVV_vld;
	 if (v_OPMVX_check)
	   if (v_instr_funct6_upper==3'b101)
	     instr_vld_o = OPMVX_101xxx_vld;
	   else
	     instr_vld_o = OPMVX_vld;
	 if (v_OPCFG_check)
	   instr_vld_o = OPCFG_vld;
      end            
   end

   //check handshake between scheduler and V_CU

   assign next_instr_rdy = (instr_vld_o & instr_rdy_i) != 12'b0;

   // maybe extented
   assign vector_rdy_o   = next_instr_rdy;
endmodule

