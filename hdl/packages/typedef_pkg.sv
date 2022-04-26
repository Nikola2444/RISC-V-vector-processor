`ifndef TYPEDEF_ENUM_PKG
`define TYPEDEF_ENUM_PKG

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

typedef enum logic [10:0] {OPMVV_101xxx_rdy=0, OPMVX_101xxx_rdy=1,
			   STORE_IDX_rdy=2,STORE_rdy=3, LOAD_IDX_rdy=4,
			   LOAD_rdy=5, OPMVV_rdy=6, OPMVX_rdy=7,
			   OPIVV_rdy=8, OPIVI_rdy=9, OPIVX_rdy=10} instruction_rdy;

typedef enum logic [11:0] {OPMVV_101xxx_vld=12'b000000000001, OPMVX_101xxx_vld=12'b000000000010,
			   STORE_IDX_vld=12'b000000000100,STORE_vld=12'b000000001000, LOAD_IDX_vld=12'b000000010000,
			   LOAD_vld=12'b000000100000, OPMVV_vld=12'b000001000000, OPMVX_vld=12'b000010000000,
			   OPIVV_vld=12'b000100000000, OPIVI_vld=12'b001000000000, OPIVX_vld=12'b010000000000, OPCFG_vld= 12'b100000000000} instruction_vld;

typedef enum logic [6:0] {v_st_opcode=7'b0100111, v_ld_opcode=7'b0000111,
			  v_arith_opcode=7'b1010111} opcode;

typedef enum logic [2:0] {OPIVV=3'b000, OPFVV=3'b001, OPMVV=3'b010, OPIVI=3'b011,
			  OPIVX=3'b100, OPFVF=3'b101, OPMVX=3'b110, OPCFG=3'b111} arith_funct3;

typedef enum logic [1:0] {unit_stride=2'b00, idx_unordered=2'b01,
			  strided=2'b10, idx_ordered=2'b11} v_mop;




 

`endif
