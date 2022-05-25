`include "../../../../packages/typedef_pkg.sv"
module v_cu #
  (parameter VLEN=4096,
   parameter V_LANES=16,
   parameter R_PORTS_NUM = 8,
   parameter W_PORTS_NUM = 4)

   (input clk,
    input rstn,
    input [11:0] 	       instr_vld_i,
    output [11:0] 	       instr_rdy_o,
    input [31:0] 	       scalar_i,
    input [31:0] 	       vector_instr_i,
    input [2:0] 	       sew_i,
    input [$clog2(VLEN/8)-1:0] vector_length_i,
    input [2:0] 	       lmul_i

    //output control signals towards vector lanes shoudl be declared here
    );

   localparam LP_VECTOR_REGISTER_NUM=32;
   // Number of bytes in VRF
   localparam LP_LANE_VRF_EL_NUM=VLEN*LP_VECTOR_REGISTER_NUM/8/V_LANES;

   
   logic [2:0] 		       inst_type;
   logic 		       start;
   logic [2:0] 		       inst_delay;
   logic 		       vrf_ren;
   logic 		       vrf_oreg_ren;
   logic [$clog2(LP_LANE_VRF_EL_NUM)-1:0] vrf_starting_waddr;
   logic [$clog2(LP_LANE_VRF_EL_NUM)-1:0] vrf_starting_raddr0;
   logic [$clog2(LP_LANE_VRF_EL_NUM)-1:0] vrf_starting_raddr1;
   logic [1:0] 				  wdata_width;
   logic [1:0] 				  st_data_mux_sel;
   logic [1:0] 				  st_ld_index_mux_sel;
   
   logic [1:0] 				  op2_sel;
   logic [1:0] 				  op3_sel;

   logic [31:0] 			  alu_scalar_data;
   logic [4:0] 				  alu_imm;
   logic [4:0] 				  alu_opmode;
   logic  				  up_down_slide;
   logic [31 : 0] 			  slide_ammount;
   logic 				  vector_mask;
   logic 				  rdata_sign;
   logic 				  imm_sign_i;

   logic [6:0] 				  v_instr_opcode;
   logic [2:0] 				  v_instr_funct6_upper;
   logic [2:0] 				  v_instr_funct6;
   logic [2:0] 				  v_instr_funct3;
   logic [4:0] 				  v_instr_imm;
   logic [1:0] 				  v_instr_mop;
   logic 				  widening_instr_check;
   logic 				  reduction_instr_check;
   logic 				  slide_instr_check;
   logic 				  vector_vector_check;
   logic 				  vector_imm_check;
   logic 				  vector_scalar_check;


   //renaming unit
   logic [31:0] 			  vector_instr_reg;
   logic [11:0] 			  instr_vld_reg;
   logic [31:0] 			  scalar_reg;
   logic [4:0] 				  v_instr_vs1;
   logic [4:0] 				  v_instr_vs2;
   logic [4:0] 				  v_instr_vd;
   logic                                  renaming_unit_rdy;
   

   always@(posedge clk)
   begin
      if (!rstn)
      begin
	 vector_instr_reg <= 'h0;
	 instr_vld_reg <='h0;
	 scalar_reg <= 'h0;
      end
      else // TODO: insert an enable signal
      begin
	 vector_instr_reg <= vector_instr_i;
	 instr_vld_reg <= instr_vld_i;
	 scalar_reg <= scalar_i;
      end	
   end

   
   assign v_instr_opcode       = vector_instr_reg[6:0];
   //assign v_instr_funct3       = vector_instr_reg[14:12];
   //assign v_instr_mop          = vector_instr_reg[27:26];
   assign v_instr_funct6_upper = vector_instr_reg[31:29];
   assign v_instr_funct6 = vector_instr_reg[31:26];
   assign v_instr_imm    = vector_instr_reg[19:15];
   assign v_instr_vs1    = vector_instr_reg[19:15];
   assign v_instr_vs2    = vector_instr_reg[24:20];
   assign v_instr_vd    = vector_instr_reg[11:7];

   

   assign reduction_instr_check = ((instr_vld_reg[6] || instr_vld_reg[7]) && v_instr_funct6_upper == 3'b000) ||
				  instr_vld_reg[8] && v_instr_funct6_upper == 3'b110;
   assign slide_instr_check     = !instr_vld_reg[11] && (v_instr_funct6 == 6'b001111 || v_instr_funct6 == 6'b001110);
   assign widening_instr_check  = v_instr_funct6_upper == 3'b111 || v_instr_funct6_upper == 3'b110;
   
   
   assign inst_type = instr_vld_reg[3] ? 2 : // vector store
		      instr_vld_reg[2] ? 3 : // indexed store
		      instr_vld_reg[5] ? 4 : // vector load
		      instr_vld_reg[4] ? 5 : // indexed load
		      reduction_instr_check ? 2 :// reduction instruction
		      slide_instr_check ? 6 : //slide instructions
		      !instr_vld_reg[11] ? 0 : // Normal instruction
		      7; // invalid instrucion

   // this will chenge when renaming is inserted
   assign start = inst_type != 1'b1;
   
   // instructions that dont read from VRF are load and config
   assign vrf_ren      = !instr_vld_reg[11] && !instr_vld_reg[5] && instr_vld_reg != 0;
   assign vrf_oreg_ren = !instr_vld_reg[11] && !instr_vld_reg[5] && instr_vld_reg != 0;
   
   assign wdata_width  = widening_instr_check ? sew_i << 2 : sew_i; // NOTE: check this. We should check if widening instructions is in play

   //assign store_data_mux_sel_i =  ;TODO : after implementing resource available logic
   //assign store_data_mux_sel_i =  ;TODO : after implementing resource available logic

   // depending on input instruction we are
   assign vector_vector_check = instr_vld_reg[8]  || instr_vld_reg[6];
   assign vector_scalar_check = instr_vld_reg[10]  || instr_vld_reg[7];
   assign vector_imm_check = instr_vld_reg[9];
   
   assign op2_sel = vector_vector_check ? 2'b00 :
		    vector_scalar_check ? 2'b01 :
		    vector_imm_check    ? 2'b10 :
		    2'b11;

   // assign op3_sel = // TODO: resource available logic needed for this

   assign alu_scalar_data = scalar_reg;
   assign alu_imm = vector_instr_reg[19:15];

   assign up_down_slide = v_instr_funct6 == 6'b001110;
   assign slide_ammount = instr_vld_reg[9]  ? {{27{1'b0}}, v_instr_imm} :
			  instr_vld_reg[10] ? scalar_reg : 32'b1;
   assign vector_mask   = vector_instr_reg[25];
   
   

   //alu_opmode
   // NOTE: we need to somehow provide information about sign, rounding, saturation, width change, mask operation, width of each operand...
   always_comb
   begin
      alu_opmode = 6'b000000;
      if (instr_vld_reg[10:8]) // Check is instr is: OPIVI||OPIVX||OPIVV
	case(v_instr_funct6)
	   6'b000000: alu_opmode = add_op;
	   //6'b000001: 
	   6'b000010: alu_opmode = sub_op;
	   6'b000011: alu_opmode = sub_op;
	   6'b000100: alu_opmode = sltu_op;
	   6'b000101: alu_opmode = slt_op;
	   6'b000110: alu_opmode = sgtu_op;
	   6'b000111: alu_opmode = sgt_op;
	   //6'b001000:
	   6'b001001: alu_opmode = and_op;
	   6'b001010: alu_opmode = or_op;
	   6'b001011: alu_opmode = xor_op;
	   //6'b001100: // vrgather funct6
	   //6'b001101: // reserved
	   //6'b001110: // slideup or vrgatherei16
	   //6'b001111: // slidedown
	   6'b010000: alu_opmode = add_op; // this is vadc
	   //6'b010001: reserved
	   6'b010001: alu_opmode = add_op; // this is vmadc
	   6'b010010: alu_opmode = sub_op; // this is vsbc
	   6'b010011: alu_opmode = sub_op; // this is vmsbc
	   //6'b010100: reserved
	   //6'b010101: reserved
	   //6'b010110: reserved
	   //6'b010111: vmerge/vmv
	   6'b011000: alu_opmode = seq_op; // this is equal
	   6'b011001: alu_opmode = sneq_op; // this is not equal
	   6'b011010: alu_opmode = sltu_op; 
	   6'b011011: alu_opmode = slt_op; 
	   6'b011100: alu_opmode = sleu_op;
	   6'b011101: alu_opmode = sle_op; 
	   6'b011110: alu_opmode = sgtu_op;
	   6'b011111: alu_opmode = sgt_op;

	   6'b100000: alu_opmode = addu_op; // saturation add
	   6'b100001: alu_opmode = add_op; // saturation add unsigned
	   6'b100010: alu_opmode = subu_op; // saturation sub
	   6'b100011: alu_opmode = sub_op; // saturation sub unsigned
	   //6'b100100: reserved
	   6'b100101: alu_opmode = sll_op; // NOTE: this should be unsigned
	   //6'b100110: reserved
	   6'b100111: alu_opmode = mul_op; // saturation multiply NOTE: this should be signed
	   6'b101000: alu_opmode = srl_op; 
	   6'b101001: alu_opmode = sra_op;
	   6'b101010: alu_opmode = srl_op; // Round off shift
	   6'b101011: alu_opmode = sra_op; // Round off shift	   
	   6'b101100: alu_opmode = srl_op; // Narowing shift
	   6'b101101: alu_opmode = sra_op; // Narowing arithmetic shift
	   6'b101110: alu_opmode = srl_op; // Vnclipu
	   6'b101111: alu_opmode = srl_op; // Vnclip
	   
	   6'b110000: alu_opmode = add_op; // Vector widening reduction add
	   6'b110000: alu_opmode = add_op; // Vector widening reduction addu
	   6'b110001: alu_opmode = add_op; // Vector widening reduction addu
	   
	endcase // case (funct6)
      else if (instr_vld_reg[7:6])// Check is instr is: OPMVX||OPMVV
	case(v_instr_funct6)
	   6'b000000: alu_opmode = add_op;
	   6'b000001: alu_opmode = and_op;
	   6'b000010: alu_opmode = or_op;
	   6'b000011: alu_opmode = xor_op;
	   6'b000100: alu_opmode = sltu_op;
	   6'b000101: alu_opmode = slt_op;
	   6'b000110: alu_opmode = sgtu_op;
	   6'b000111: alu_opmode = sgt_op;
	   
	   6'b001000: alu_opmode = addu_op;// vaaddu
	   6'b001001: alu_opmode = add_op;// vaadd
	   6'b001010: alu_opmode = subu_op;// vasubu
	   6'b001011: alu_opmode = sub_op;// vasub
	   //6'b001100: // vrgather funct6
	   //6'b001101: // reserved
	   //6'b001110: // slide1up
	   //6'b001111: // slide1down
	   /*UNARY INSTR OPCODES*/
	   //6'b010000: 
	   //6'b010001: 
	   //6'b010001: 
	   //6'b010010: 
	   //6'b010011: 
	   //6'b010100: 
	   //6'b010101: 
	   //6'b010110: 
	   //6'b010111: compress
	   /***********************/
	   6'b011000: alu_opmode = andnot_op; // this is equal
	   6'b011001: alu_opmode = and_op; // this is not equal
	   6'b011010: alu_opmode = or_op; 
	   6'b011011: alu_opmode = xor_op; 
	   6'b011100: alu_opmode = ornot_op;
	   6'b011101: alu_opmode = nand_op; 
	   6'b011110: alu_opmode = nor_op;
	   6'b011111: alu_opmode = xnor_op;

	   //6'b100000: vdivu
	   //6'b100001: vdiv
	   //6'b100010: vremu
	   //6'b100011: vrem
	   6'b100100: alu_opmode = mulhu_op; 
	   6'b100101: alu_opmode = mul_op; 
	   6'b100110: alu_opmode = mulhsu_op;
	   6'b100111: alu_opmode = mulh_op; // saturation multiply NOTE: this should be unsigned
	   //6'b101000: 
	   6'b101001: alu_opmode = mul_add_op;
	   //6'b101010: 
	   6'b101011: alu_opmode = mul_sub_op; //vnmsub
	   //6'b101100:
	   6'b101101: alu_opmode = mul_add_op; // 
	   //6'b101110:
	   6'b101111: alu_opmode = mul_sub_op; // Vnmsuc
	   
	   6'b110000: alu_opmode = addu_op; // Vector widening reduction addu
	   6'b110001: alu_opmode = add_op; // Vector widening reduction add
	   6'b110010: alu_opmode = subu_op; // Vector widening reduction subu
	   6'b110011: alu_opmode = sub_op; // Vector widening reduction sub
	   6'b110100: alu_opmode = addu_op; //vwaddu.w
	   6'b110101: alu_opmode = add_op; //vwadd.w
	   6'b110110: alu_opmode = subu_op; //vwsubu.w
	   6'b110111: alu_opmode = sub_op; //vwsub.w	   
	   6'b111000: alu_opmode = mulu_op; //vwmulu
	   //6'b111001:
	   6'b111010: alu_opmode = mulsu_op; //vwmulu
	   6'b111011: alu_opmode = mul_op; //vwmulu
	   6'b111100: alu_opmode = mulu_add_op; //vwmaccu
	   6'b111101: alu_opmode = mul_add_op; //vwmacc
	   6'b111110: alu_opmode = mulus_add_op; //vwmaccus
	   6'b111111: alu_opmode = mulsu_add_op; //vwmaccsu	   
	endcase // case (funct6)      
   end
   

   
   
   
   
   // TODO: insert renaming unit that generates start waddr and start raddrs
   renaming_unit renaming_unit_inst
     (/*AUTOINST*/
      // Outputs
      .instr_rdy_o	(renaming_unit_rdy),
      .vrf_starting_waddr_o(vrf_starting_waddr),
      .vrf_starting_raddr0_o(vrf_starting_raddr0),
      .vrf_starting_raddr1_o(vrf_starting_raddr1),
      // Inputs
      .instr_vld_i	(1'b1),
      //.lmul_i		(lmul_i[1:0]),
      .lmul_i		(lmul_i[1:0]),
      .vs1_i		(v_instr_vs1),
      .vs2_i		(v_instr_vs2),
      .vd_i		(v_instr_vd));
     
   
   // Here we need to insert component which uses generated control signals to
   // Control the lanes.
endmodule
