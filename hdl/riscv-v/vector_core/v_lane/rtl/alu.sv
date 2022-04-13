`include "../../../../packages/typedef_pkg.sv"

module alu #
  (
   parameter OP_WIDTH = 32,
   parameter PARALLEL_IF_NUM=4)
   (
    input 				       clk,
    input 				       rstn,

    // Interfaces towards DSPs in ALU. If alu_en_32bit_mul==1
    // then only [0] interface is used
    input [PARALLEL_IF_NUM-1:0][6:0] 	       alu_opmode,
    input [PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0]  alu_a_i,
    input [PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0]  alu_b_i,
    input [PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0]  alu_c_i,
    input [1:0] 			       sew,
    output [PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0] alu_o,

    // Enables 32 bit multiply, but takes a bit longer to
    // execute.
    input 				       alu_en_32bit_mul,
    // stalls all registers in ALU
    input 				       alu_stall
    );
   
   logic [PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0]   dsp_a_reg;
   logic [PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0]   dsp_b_reg;
   logic [PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0]   dsp_c_reg;
   logic [PARALLEL_IF_NUM-1:0][2*OP_WIDTH-1:0] dsp_m_reg;
   logic [PARALLEL_IF_NUM-1:0][2*OP_WIDTH-1:0] dspu_m_reg;
   logic [PARALLEL_IF_NUM-1:0][2*OP_WIDTH-1:0] dspsu_m_reg;
   logic [PARALLEL_IF_NUM-1:0][OP_WIDTH-1:0]   dsp_p_reg;


   always_ff@(posedge clk)
   begin
      if (!rstn)
      begin
	 dsp_a_reg <= '{default:'0};
	 dsp_b_reg <= '{default:'0};
	 dsp_c_reg <= '{default:'0};
	 dsp_m_reg <= '{default:'0};
	 dsp_p_reg <= '{default:'0};
      end
      else
      begin
	 if (!alu_stall)
	   for (int i=0; i<PARALLEL_IF_NUM; i++)
	   begin
	      dsp_a_reg[i] <= alu_a_i;
	      dsp_b_reg[i] <= alu_b_i;
	      dsp_c_reg[i] <= alu_c_i[i];
	      dsp_m_reg[i] <= signed'(dsp_a_reg) * signed'(dsp_b_reg);
	      dspu_m_reg[i] <= unsigned'(dsp_a_reg) * unsigned'(dsp_b_reg);
	      dspsu_m_reg[i] <= signed'(dsp_a_reg) * unsigned'(dsp_b_reg);
	      case (alu_opmode[i])
		 add_op: dsp_p_reg[i] 	 <= dsp_a_reg[i] + dsp_b_reg[i];
		 sub_op: dsp_p_reg[i] 	 <= dsp_a_reg[i] - dsp_b_reg[i];
		 xor_op: dsp_p_reg[i] 	 <= dsp_a_reg[i] ^ dsp_b_reg[i];
		 xnor_op: dsp_p_reg[i] 	 <= !(dsp_a_reg[i] ^ dsp_b_reg[i]);
		 and_op: dsp_p_reg[i] 	 <= dsp_a_reg[i] & dsp_b_reg[i];
		 nand_op: dsp_p_reg[i] 	 <= !(dsp_a_reg[i] & dsp_b_reg[i]);
		 or_op: dsp_p_reg[i] 	 <= dsp_a_reg[i] | dsp_b_reg[i];
		 nor_op: dsp_p_reg[i] 	 <= !(dsp_a_reg[i] | dsp_b_reg[i]);
		 slt_op: dsp_p_reg[i] 	 <= signed'(dsp_a_reg[i]) < signed'(dsp_b_reg[i]) ? 32'b1 : 32'b0;
		 sgt_op: dsp_p_reg[i] 	 <= signed'(dsp_a_reg[i]) > signed'(dsp_b_reg[i]) ? 32'b1 : 32'b0;
		 seq_op: dsp_p_reg[i] 	 <= signed'(dsp_a_reg[i]) == signed'(dsp_b_reg[i]) ? 32'b1 : 32'b0;
		 sltu_op: dsp_p_reg[i] 	 <= unsigned'(dsp_a_reg[i]) < unsigned'(dsp_b_reg[i]) ? 32'b1 : 32'b0;
		 sgtu_op: dsp_p_reg[i] 	 <= unsigned'(dsp_a_reg[i]) > unsigned'(dsp_b_reg[i]) ? 32'b1 : 32'b0;
		 mul_op: dsp_p_reg[i] 	 <= dsp_m_reg[i][31:0];
		 mulhu_op: dsp_p_reg[i]  <= sew == 2'b00 ? dspu_m_reg[i][7:0]:
					    sew == 2'b01 ? dspu_m_reg[i][15:0]:
					    dspu_m_reg[i][63:32];
		 mulhsu_op: dsp_p_reg[i] <= sew == 2'b00 ? dspsu_m_reg[i][7:0]:
					    sew  == 2'b01 ? dspsu_m_reg[i][15:0]:
					    dspsu_m_reg[i][63:32];
		 mulh_op: dsp_p_reg[i] 	 <= dsp_m_reg[i][31:0];

		 wmul_op: dsp_p_reg[i] 	 <= dsp_m_reg[i][31:0];
		 wmulu_op: dsp_p_reg[i]  <= dspu_m_reg[i][31:0];
		 wmulsu_op: dsp_p_reg[i] <= dspsu_m_reg[i][31:0];

		 //Finish shifting
		 
	      endcase
	   end
      end
   end

   generate
      for (genvar i=0; i<PARALLEL_IF_NUM;i++)
      begin
	 assign alu_o[i] = dsp_p_reg[i];
      end
   endgenerate
   
   
   



endmodule
