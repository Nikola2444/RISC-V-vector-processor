module alu #
  (
   parameter OP_WIDTH = 32,
   parameter PARALLEL_IF_NUM=4)
   (
    input 				       clk,
    input 				       rstn,

    // Interfaces towards DSPs in ALU. If alu_en_32bit_mul_i==1
    // then only [0] interface is used
    input [PARALLEL_IF_NUM-1:0][8:0] 	       alu_opmode_i,
    input [PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0]  alu_a_i,
    input [PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0]  alu_b_i,
    input [PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0]  alu_c_i,
    input [1:0] 			       sew_i,
    output [PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0] alu_o,
    input [PARALLEL_IF_NUM-1:0] 	       alu_vld_i,
    output [PARALLEL_IF_NUM-1:0] 	       alu_vld_o,
    output logic[PARALLEL_IF_NUM-1:0] 	       alu_mask_vector_o,

    // Enables 32 bit multiply, but takes a bit longer to
    // execute.
    input 				       alu_en_32bit_mul_i,
    // stalls all registers in ALU
    input 				       alu_stall_i
    );

   alu_submodule alu_submodule_inst0(/*AUTOINST*/
				     // Outputs
				     .alu_vld_o		(alu_vld_o[0]),
				     .result_o		(alu_o[0]),
				     // Inputs
				     .clk		(clk),
				     .rstn		(rstn),
				     .sew_i		(sew_i[2:0]),
				     .alu_opmode_i	(alu_opmode_i[0][8:0]),
				     .op1_i		(alu_a_i[0]),
				     .op2_i		(alu_b_i[0]),
				     .op3_i		(alu_c_i[0]),
				     .alu_vld_i		(alu_vld_i[0]));
   alu_submodule alu_submodule_inst1(/*AUTOINST*/
				     // Outputs
				     .alu_vld_o		(alu_vld_o[1]),
				     .result_o		(alu_o[1]),
				     // Inputs
				     .clk		(clk),
				     .rstn		(rstn),
				     .sew_i		(sew_i[2:0]),
				     .alu_opmode_i	(alu_opmode_i[1][8:0]),
				     .op1_i		(alu_a_i[1]),
				     .op2_i		(alu_b_i[1]),
				     .op3_i		(alu_c_i[1]),
				     .alu_vld_i		(alu_vld_i[1]));
   alu_submodule alu_submodule_inst2(/*AUTOINST*/
				     // Outputs
				     .alu_vld_o		(alu_vld_o[2]),
				     .result_o		(alu_o[2]),
				     // Inputs
				     .clk		(clk),
				     .rstn		(rstn),
				     .sew_i		(sew_i[2:0]),
				     .alu_opmode_i	(alu_opmode_i[2][8:0]),
				     .op1_i		(alu_a_i[2]),
				     .op2_i		(alu_b_i[2]),
				     .op3_i		(alu_c_i[2]),
				     .alu_vld_i		(alu_vld_i[2]));
   alu_submodule alu_submodule_inst3(/*AUTOINST*/
				     // Outputs
				     .alu_vld_o		(alu_vld_o[3]),
				     .result_o		(alu_o[3]),
				     // Inputs
				     .clk		(clk),
				     .rstn		(rstn),
				     .sew_i		(sew_i[2:0]),
				     .alu_opmode_i	(alu_opmode_i[3][8:0]),
				     .op1_i		(alu_a_i[3]),
				     .op2_i		(alu_b_i[3]),
				     .op3_i		(alu_c_i[3]),
				     .alu_vld_i		(alu_vld_i[3]));

   always_comb
   begin
      for (int i=0; i<4; i++)
	alu_mask_vector_o[i] = alu_o[i][0];
   end

   endmodule

