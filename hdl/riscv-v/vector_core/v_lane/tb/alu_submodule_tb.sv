`timescale 1ns/1ps
`include "../../../../packages/typedef_pkg.sv"
module alu_submodule_tb();

   logic 				       clk=0;
   logic 				       rstn;

   // Interfaces towards DSPs in ALU. If alu_en_32bit_mul==1
   // then only [0] interface is used
   logic [8:0] 				       alu_opmode_i;
   logic [31:0] 			       op1_i;
   logic [31:0] 			       op2_i;
   logic [31:0] 			       op3_i;
   logic [2:0] 				       sew_i;
   logic [31:0] 			       result_o;

   // Enables 32 bit multiply; but takes a bit longer to
   // execute.
   logic 				       alu_en_32bit_mul;
   // stalls all registers in ALU
   logic 				       alu_stall;
   
   // End of automatics
   alu_submodule dut(/*AUTOINST*/
		     // Outputs
		     .alu_vld_o		(alu_vld_o),
		     .result_o		(result_o[31:0]),
		     // Inputs
		     .clk		(clk),
		     .rstn		(rstn),
		     .alu_opmode_i	(alu_opmode_i[8:0]),
		     .op1_i		(op1_i[31:0]),
		     .op2_i		(op2_i[31:0]),
		     .op3_i		(op3_i[31:0]),
		     .sew_i             (sew_i),
		     .alu_vld_i		(1'b1));

   always begin    
      clk = #50 ~clk;    
   end

   initial
   begin
      rstn <= 1'b0;
      sew_i <= 3'b000;
      #300;
      rstn <= 1'b1;
      op1_i <= 176;
      op2_i <= 2;
      alu_stall <= 1'b0;
      alu_opmode_i <= add_op;
      @(posedge clk);
      alu_opmode_i <= sub_op;
      @(posedge clk);
      alu_opmode_i <= mul_op;
      @(posedge clk);
      alu_opmode_i <= and_op;
      @(posedge clk);
      alu_opmode_i <= or_op;
      @(posedge clk);
      alu_opmode_i <= mulhu_op;
   end

endmodule // alu_tb
// Local Variables:
// verilog-library-extensions:(".v" ".sv" "_stub.v" "_bb.v")
// verilog-library-directories:("." "../rtl/")
// End:

