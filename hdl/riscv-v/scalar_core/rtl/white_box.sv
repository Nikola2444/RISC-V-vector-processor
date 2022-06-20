//This module enables viewing scalar signals from the outside (Testbench)

module white_box(
   input 	  rd_we_i,
   input [4:0 ]	  rs1_address_i,
   input [4:0]	  rs2_address_i,
   input [31:0]	  rs1_data_o,
   input [31:0]	  rs2_data_o,   
   input [4:0]	  rd_address_i, 
   input [31:0]	  rd_data_i,
   input [0:31][31:0] scalar_reg_bank
);

endmodule
