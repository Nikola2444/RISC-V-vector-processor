module vector_core #
  (parameter VLEN=4096,
   parameter V_LANES=16,
   parameter CHAINING=4)
   (
    input 	 clk,
    input 	 rstn,

    //scalar core interface
    input [31:0] rs1_i,
    input [31:0] rs2_i,
    input [31:0] vector_instr_i,
    output 	 vector_stall_o
    //data interface    
    );

   
endmodule

