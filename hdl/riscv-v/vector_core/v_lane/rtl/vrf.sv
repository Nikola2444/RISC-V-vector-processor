module vrf #
  (parameter R_PORTS_NUM = 8,
   parameter W_PORTS_NUM = 4,
   parameter MEM_DEPTH = 1024,
   parameter MEM_WIDTH = 32)
   (
    input 					   clk,
    input 					   rstn,

    
    // read IF
    input [R_PORTS_NUM-1:0][$clog2(MEM_DEPTH)-1:0] raddr,
    input [R_PORTS_NUM-1:0] 			   ren,
    input [R_PORTS_NUM-1:0] 			   oreg_ren, 
    output [R_PORTS_NUM-1:0] [MEM_WIDTH-1:0] 	   data_o,
   
    // write IF
    input [W_PORTS_NUM-1:0][$clog2(MEM_DEPTH)-1:0] waddr,
    input [W_PORTS_NUM-1:0][MEM_WIDTH/8-1:0] 	   bwen,
    output [W_PORTS_NUM-1:0] [MEM_WIDTH-1:0] 	   data_i
    );
   
endmodule
