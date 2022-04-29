//this component is responsible for issuing instruction to V_CU if there
// are resources available, and also it is responbile for providing M_CU with
// information about ld and st instructions.


`include "../../../../packages/typedef_pkg.sv"
module scheduler
  (input logic clk,
   input logic 	       rstn,
   //*** Scalar-Vector interface*****
   input logic [31:0]  vector_instr_i,
   input logic [31:0]  rs1_i,
   input logic [31:0]  rs2_i,
   input logic [ 1:0]  sew_i,
   output logic        vector_stall_o,
   //*** Scheduler-V_CU interface****
   input logic [10:0]  instr_rdy_i,
   output logic [10:0] instr_vld_o,
   output logic [31:0] vector_instr_o,
   //*** Scheduler-M_CU interface****
   //Load handshake
   input logic 	       mcu_ld_rdy_i,
   output logic        mcu_ld_vld_o, 
   input logic 	       mcu_ld_buffered_i,
   //Store handshake
   input logic 	       mcu_st_rdy_i,
   output logic        mcu_st_vld_o,
   //Load/store information
   output logic [31:0] mcu_base_addr_o, // -> base address
   output logic [31:0] mcu_stride_o, // -> stride
   output logic [ 2:0] mcu_data_width_o,
   output logic        mcu_idx_ld_st_o,
   output logic        mcu_strided_ld_st_o,
   output logic        mcu_unit_ld_st_o
   

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

   logic               mcu_ld_buffering_reg;
   logic [31:0]        v_idx_ld_part2;

   assign v_instr_opcode       = vector_instr_reg[6:0];
   assign v_instr_funct3       = vector_instr_reg[14:12];
   assign v_instr_mop          = vector_instr_reg[27:26];
   assign v_instr_funct6_upper = vector_instr_reg[31:29];

   // MCU signals
   assign mcu_base_addr_o  = rs1_i;
   assign mcu_stride_o     = rs2_i;
   assign mcu_data_width_o = vector_instr_reg[14:12];


   always @(posedge clk)
   begin
      if (!rstn)
      begin
	 vector_instr_reg <= 'h0;
      end
      else if (next_instr_rdy)
      begin
	 vector_instr_reg <= vector_instr_next;
      end
   end

   //if the instructions is indexed load, for the next instruction we insert the second part of that instruction which is
   // a simple vector load.
   assign v_idx_ld_part2    = {vector_instr_reg[31:28],2'b00,vector_instr_reg[25:15],sew_i, vector_instr_reg[11:0]};

   assign vector_instr_next =  (v_idx_unordered_check && v_ld_instr_check) ?  v_idx_ld_part2 : vector_instr_i;


   
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
      
      mcu_unit_ld_st_o = 1'b0;
      mcu_strided_ld_st_o = 1'b0;
      mcu_idx_ld_st_o = 1'b0;

      if (v_instr_mop == unit_stride)
      begin
	 v_unit_check = 1'b1;
	 mcu_unit_ld_st_o = 1'b1;
      end
      if (v_instr_mop == strided)
      begin
	 v_strided_check = 1'b1;
	 mcu_strided_ld_st_o = 1'b1;
      end
      if (v_instr_mop == idx_unordered)
      begin
	 v_idx_unordered_check = 1'b1;
	 mcu_idx_ld_st_o = 1'b1;
      end
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
	 if ((v_strided_check || v_unit_check) && mcu_st_rdy_i)
	   instr_vld_o = STORE_vld;
	 else if ((v_idx_ordered_check || v_idx_unordered_check) && mcu_st_rdy_i)
	   instr_vld_o = STORE_IDX_vld;
      end
      if (v_ld_instr_check)
      begin
	 if ((v_strided_check || v_unit_check) && mcu_ld_buffered_i)
	   instr_vld_o = LOAD_vld;
	 else if ((v_idx_ordered_check || v_idx_unordered_check))
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

   //logic that checks if there is a load being buffered by M_CU
   assign mcu_ld_vld_o = (!mcu_ld_buffering_reg && v_ld_instr_check);
   always @(posedge clk)
   begin
      if (!rstn)
      begin
	 mcu_ld_buffering_reg <= 'h0;
      end
      else
      begin
	 if (mcu_ld_vld_o && mcu_ld_rdy_i && !mcu_ld_buffering_reg)
	 begin
	    mcu_ld_buffering_reg <= 1'b1;
	 end
	 else if (mcu_ld_buffered_i)
	   mcu_ld_buffering_reg <= 1'b0;
      end
   end

   assign mcu_st_vld_o = v_st_instr_check && !v_idx_unordered_check;

   //check handshake between scheduler and V_CU

   assign next_instr_rdy = (instr_vld_o & instr_rdy_i) != 'h0;

   // maybe extented
   // Stall if new instructions is valid but v_cu is not ready,
   // if we have a store instruction but m_cu is not ready,
   // 

   assign vector_stall_o   = (!next_instr_rdy && (v_st_instr_check | v_ld_instr_check | v_arith_instr_check)) | 
			     (mcu_st_vld_o && !mcu_st_rdy_i) | 
			     (v_ld_instr_check && !mcu_ld_buffered_i);


   assign mcu_rs1_o        = rs1_i;
   assign mcu_rs2_o        = rs2_i;
   assign data_width_o = vector_instr_i[14:12];
   assign mop_o        = vector_instr_i[27:26];
   
endmodule

