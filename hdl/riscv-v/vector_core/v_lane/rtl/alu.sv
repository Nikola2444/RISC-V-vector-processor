module alu #
  (
   parameter OP_WIDTH = 32,
   parameter PARALLEL_IF_NUM=4)
   (
    input 				       clk,
    input 				       rstn,

    input [PARALLEL_IF_NUM-1:0][4:0] 	       alu_opmode,
    input [PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0]  alu_a_i,
    input [PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0]  alu_b_i,
    input [PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0]  alu_c_i,
    output [PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0] alu_o,
   
    );



endmodule
