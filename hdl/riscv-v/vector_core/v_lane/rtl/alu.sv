module alu #
  (
   parameter OP_WIDTH = 32,
   parameter PARALLEL_IF_NUM=4,
   parameter V_LANE_NUM = 8)
   (
    input 					     clk,
    input 					     rstn,

    // Interfaces towards DSPs in ALU. If alu_en_32bit_mul_i==1
    // then only [0] interface is used
    input [PARALLEL_IF_NUM-1:0][8:0] 		     alu_opmode_i,

    input [PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0] 	     alu_a_i,
    input [PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0] 	     alu_b_i,
    input [PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0] 	     alu_c_i,
    input [PARALLEL_IF_NUM-1:0][1:0] 		     input_sew_i,
    input [PARALLEL_IF_NUM-1:0][1:0] 		     output_sew_i,
    input [PARALLEL_IF_NUM-1:0] 		     alu_reduction_i,
    output logic [PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0] alu_o,
    input [PARALLEL_IF_NUM-1:0] 		     alu_vld_i,
    output [PARALLEL_IF_NUM-1:0] 		     alu_vld_o,
    output logic [PARALLEL_IF_NUM-1:0] 		     alu_mask_vector_o

    // Enables 32 bit multiply, but takes a bit longer to
    // execute.
    //input 					     alu_en_32bit_mul_i,
    // stalls all registers in ALU
    // input 					     alu_stall_i
    );

   logic [3:0][31:0] 				     alu_out;

   alu_submodule  #
     (.V_LANE_NUM(V_LANE_NUM))
   alu_submodule_inst0
   (/*AUTOINST*/
    // Outputs
    .alu_vld_o		(alu_vld_o[0]),
    .result_o		(alu_out[0]),
    // Inputs
    .clk		(clk),
    .reduction_op_i     (alu_reduction_i[0]),
    .rstn		(rstn),
    .input_sew_i	(input_sew_i[0]),
    .output_sew_i	(output_sew_i[0]),
    .alu_opmode_i	(alu_opmode_i[0][8:0]),
    .op1_i		(alu_a_i[0]),
    .op2_i		(alu_b_i[0]),
    .op3_i		(alu_c_i[0]),
    .alu_vld_i		(alu_vld_i[0]));
   alu_submodule #
     (.V_LANE_NUM(V_LANE_NUM))
   alu_submodule_inst1
   (/*AUTOINST*/
    // Outputs
    .alu_vld_o		(alu_vld_o[1]),
    .result_o		(alu_out[1]),
    // Inputs
    .clk		(clk),
    .reduction_op_i     (alu_reduction_i[1]),
    .rstn		(rstn),
    .input_sew_i	(input_sew_i[1]),
    .output_sew_i	(output_sew_i[1]),
    .alu_opmode_i	(alu_opmode_i[1][8:0]),
    .op1_i		(alu_a_i[1]),
    .op2_i		(alu_b_i[1]),
    .op3_i		(alu_c_i[1]),
    .alu_vld_i		(alu_vld_i[1]));

   alu_submodule #
     (.V_LANE_NUM(V_LANE_NUM))
   alu_submodule_inst2
   (/*AUTOINST*/
    // Outputs
    .alu_vld_o		(alu_vld_o[2]),
    .result_o		(alu_out[2]),
    // Inputs
    .clk		(clk),
    .rstn		(rstn),
    .input_sew_i	(input_sew_i[2]),
    .output_sew_i	(output_sew_i[2]),
    .reduction_op_i     (alu_reduction_i[2]),
    .alu_opmode_i	(alu_opmode_i[2][8:0]),
    .op1_i		(alu_a_i[2]),
    .op2_i		(alu_b_i[2]),
    .op3_i		(alu_c_i[2]),
    .alu_vld_i		(alu_vld_i[2]));
   alu_submodule #
     (.V_LANE_NUM(V_LANE_NUM))
   alu_submodule_inst3
   (/*AUTOINST*/
    // Outputs
    .alu_vld_o		(alu_vld_o[3]),
    .result_o		(alu_out[3]),
    // Inputs
    .clk		(clk),
    .rstn		(rstn),
    .input_sew_i	(input_sew_i[3]),
    .output_sew_i	(output_sew_i[3]),
    .reduction_op_i     (alu_reduction_i[3]),
    .alu_opmode_i	(alu_opmode_i[3][8:0]),
    .op1_i		(alu_a_i[3]),
    .op2_i		(alu_b_i[3]),
    .op3_i		(alu_c_i[3]),
    .alu_vld_i		(alu_vld_i[3]));

   always_comb
   begin
      for (int i=0; i<4; i++)
	alu_mask_vector_o[i] = alu_out[i][0];
   end

   assign alu_o=alu_out;


/* -----\/----- EXCLUDED -----\/-----
   always_comb
   begin
      for (int i=0; i<4;i++)
      begin
	 if (output_sew_i==2'b00)
	   for (int j=0; j<4; j++)
	   begin
	      alu_o[i][j*8 +: 8] = alu_out[i][7:0];
	   end	
	 else if (output_sew_i==2'b01)
	 begin
	    for (int j=0; j<2; j++)
	    begin
	       alu_o[i][j*16 +: 16] = alu_out[i][15:0];
	    end	
	 end
	 else
	 begin
	    alu_o[i]=alu_out[i];
	 end
      end
   end
 -----/\----- EXCLUDED -----/\----- */

   
endmodule

