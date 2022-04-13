`timescale 1ns/1ps
`include "../../../../packages/typedef_pkg.sv"
module alu_tb();

   logic 				       clk=0;
   logic 				       rstn;

   // Interfaces towards DSPs in ALU. If alu_en_32bit_mul==1
   // then only [0] interface is used
   logic 				       [3:0][6:0] 	       alu_opmode;
   logic [3:0][31:0] 			       alu_a_i;
   logic [3:0][31:0] 			       alu_b_i;
   logic [3:0][31:0] 			       alu_c_i;
   logic [3:0][31:0] 			       alu_o;

   // Enables 32 bit multiply; but takes a bit longer to
   // execute.
   logic 				       alu_en_32bit_mul;
   // stalls all registers in ALU
   logic 				       alu_stall;
   
   // End of automatics
   alu dut(/*AUTOINST*/
	   // Outputs
	   .alu_o			(alu_o/*[PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0]*/),
	   // Inputs
	   .clk				(clk),
	   .rstn			(rstn),
	   .alu_opmode			(alu_opmode/*[PARALLEL_IF_NUM-1:0][4:0]*/),
	   .alu_a_i			(alu_a_i/*[PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0]*/),
	   .alu_b_i			(alu_b_i/*[PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0]*/),
	   .alu_c_i			(alu_c_i/*[PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0]*/),
	   .alu_en_32bit_mul		(alu_en_32bit_mul),
	   .alu_stall			(alu_stall));

   always begin    
      clk = #50 ~clk;    
   end

   initial
   begin
      rstn <= 1'b0;
      #300;
      rstn <= 1'b1;
      alu_a_i[0] <= 20;
      alu_b_i[0] <= 10;
      alu_stall <= 1'b0;
      alu_opmode[0] <= add_op;
      @(posedge clk);
      @(posedge clk);
      alu_opmode[0] <= sub_op;
      @(posedge clk);
      @(posedge clk);
      alu_opmode[0] <= mul_op;            
   end

endmodule // alu_tb
// Local Variables:
// verilog-library-extensions:(".v" ".sv" "_stub.v" "_bb.v")
// verilog-library-directories:("." "../rtl/")
// End:
