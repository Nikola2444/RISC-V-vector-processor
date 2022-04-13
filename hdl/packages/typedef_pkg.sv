`ifndef ENUM_PKG
`define ENUM_PKG

typedef enum logic [6:0] {// add sub
			  add_op=7'b000000, sub_op=7'b000011,
			  // logic operations
			  xor_op=7'b0000100,xnor_op=7'b0000101, and_op=7'b0001100, nand_op=7'b0001110, 
			  or_op=7'b0011100, nor_op=7'b0011110,
			  // Compare operations
			  slt_op=7'b0100000, sgt_op=7'b0100001, seq_op=7'b0100010, sltu_op=7'b0100011,
			  sgtu_op=7'b0100100,
			  // Multiply operations
			  mul_op=7'b1000000, mulhu_op=7'b1000001, mulhsu_op=7'b1000010, mulh_op=7'b1000011,
			  // Widening multiply
			  wmul_op=7'b1001000, wmulu_op=7'b1001001, wmulsu_op=7'b1001010,
			  // Shifts 
			  sll_op=7'b1100000, srl_op=7'b1100001, sra_op=7'b1100010, nsrl_op=7'b1100011, 
			  nsra_op=7'b1100100
			  } alu_op;


 

`endif
