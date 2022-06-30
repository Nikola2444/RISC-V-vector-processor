`ifndef TYPEDEF_ENUM_PKG
 `define TYPEDEF_ENUM_PKG

// 8 bits for alu mode, MSB bit says if operations is signed or not
package typedef_pkg;
   typedef enum logic [8:0] {// add sub
			     add_op=9'b110000000, sub_op=9'b110000011,
			     addu_op=9'b000000000, subu_op=9'b000000011,
			     // logic operations
			     xor_op=9'b000000100,xnor_op=9'b000000101, and_op=9'b000001100, nand_op=9'b000001110, 
			     or_op=9'b000011100, nor_op=9'b000011110, andnot_op=9'b000001111, ornot_op=9'b000011111,
			     // Compare operations, output is one bit LSB
  			     slt_op=9'b110100000, sgt_op=9'b110100001, seq_op=9'b110100010, sle_op=9'b110100101,
			     sltu_op=9'b000100011, sgtu_op=9'b000100100, sleu_op=9'b000100101, sneq_op=9'b000100110, 
   
			     // Multiply operations
			     mul_op=9'b111010000, mulhu_op=9'b001011000, mulu_op=9'b001010000, mulh_op=9'b111011000, mulhsu_op=9'b101011000,  mulsu_op=9'b101010000,
			     mul_add_op=9'b111000000, mul_acc_op=9'b111000100, mul_subacc_op=9'b111000111, mulu_add_op=9'b001000000,
			     mulus_add_op=9'b011000000, mulsu_add_op=9'b101000000, mul_sub_op=9'b111000011,
   
			     // Shifts 
			     sll_op=9'b01100000, srl_op=9'b01100001, sra_op=9'b11100010, nsrl_op=9'b01100011,
			     nsra_op=9'b11100100
			     } alu_op;

   /* -----\/----- EXCLUDED -----\/-----
    typedef enum logic [11:0] {OPMVV_101xxx_rdy=0, OPMVX_101xxx_rdy=1,
    STORE_IDX_rdy=2,STORE_rdy=3, LOAD_IDX_rdy=4,
    LOAD_rdy=5, OPMVV_rdy=6, OPMVX_rdy=7,
    OPIVV_rdy=8, OPIVI_rdy=9, OPIVX_rdy=10} instruction_rdy;
    -----/\----- EXCLUDED -----/\----- */

   typedef enum logic [12:0] {OPMVV_101xxx_vld=13'b0000000000001, OPMVX_101xxx_vld=13'b0000000000010,
			      STORE_IDX_vld=13'b0000000000100,STORE_vld=13'b0000000001000, LOAD_IDX_vld=13'b0000000010000,
			      LOAD_vld=13'b0000000100000, OPMVV_vld=13'b0000001000000, OPMVX_vld=13'b0000010000000,
			      OPIVV_vld=13'b0000100000000, OPIVI_vld=13'b0001000000000, OPIVX_vld=13'b0010000000000, OPCFG_vld= 13'b1000000000000, SLIDE_vld= 13'b0100000000000} instruction_vld;
   typedef enum logic [12:0] {OPMVV_101xxx_rdy=13'b0000000000001, OPMVX_101xxx_rdy=13'b0000000000010,
			      STORE_IDX_rdy=13'b0000000000100,STORE_rdy=13'b0000000001000, LOAD_IDX_rdy=13'b0000000010000,
			      LOAD_rdy=13'b0000000100000, OPMVV_rdy=13'b0000001000000, OPMVX_rdy=13'b0000010000000,
			      OPIVV_rdy=13'b0000100000000, OPIVI_rdy=13'b0001000000000, OPIVX_rdy=13'b0010000000000, OPCFG_rdy= 13'b1000000000000, SLIDE_rdy= 13'b0100000000000} instruction_rdy;

   typedef enum logic [6:0] {v_st_opcode=7'b0100111, v_ld_opcode=7'b0000111,
			     v_arith_opcode=7'b1010111} opcode;

   typedef enum logic [2:0] {OPIVV=3'b000, OPFVV=3'b001, OPMVV=3'b010, OPIVI=3'b011,
			     OPIVX=3'b100, OPFVF=3'b101, OPMVX=3'b110, OPCFG=3'b111} arith_funct3;

   typedef enum logic [1:0] {unit_stride=2'b00, idx_unordered=2'b01,
			     strided=2'b10, idx_ordered=2'b11} v_mop;

endpackage : typedef_pkg


   

`endif
