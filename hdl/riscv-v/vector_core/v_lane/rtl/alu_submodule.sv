//`include "typedef_pkg.sv"

module alu_submodule #  
  (parameter V_LANE_NUM=0)
   (/*AUTOARG*/
   // Outputs
   alu_vld_o, result_o,
   // Inputs
   clk, rstn, input_sew_i, output_sew_i, alu_opmode_i, op1_i, op2_i,
   op3_i, alu_vld_i, reduction_op_i
   );
   import typedef_pkg::*;
   localparam LP_MAX_PIPE_STAGES=4;
   //opmode for all operation exept multiply
   localparam logic [6:0] LP_OPMODE_NORMAL=7'b0110011;
   localparam logic [6:0] LP_OPMODE_MUL=7'b0000101;
   localparam logic [6:0] LP_OPMODE_MUL_ACC=7'b0100101;

   localparam logic [2:0] LP_DSP_Z_MUX_NORMAL=3'b011;
   localparam logic [2:0] LP_DSP_Z_MUX_MUL=3'b000;
   localparam logic [2:0] LP_DSP_Z_MUX_MUL_ACC=3'b010;
   localparam logic [2:0] LP_DSP_Z_MUX_REDUCTION=3'b010;

   localparam logic [1:0] LP_DSP_Y_MUX_MUL=2'b01;
   localparam logic [1:0] LP_DSP_Y_MUX_MUL_ACC=2'b01;


   localparam logic [1:0] LP_DSP_X_MUX_NORMAL=2'b11;
   localparam logic [1:0] LP_DSP_X_MUX_MUL=2'b01;
   localparam logic [1:0] LP_DSP_X_MUX_MUL_ACC=2'b01;   

   input clk;
   input rstn;
   input [1:0]  input_sew_i;
   input [1:0]  output_sew_i;
   input [ 8:0] alu_opmode_i;
   input [31:0] op1_i;
   input [31:0] op2_i;
   input [31:0] op3_i;
   input 	alu_vld_i;
   input        reduction_op_i;

   output 	alu_vld_o;
   output [31:0] result_o;


   //DSP signals
   logic [47:0]  dsp_P;
   logic [29:0]  dsp_A;
   logic [17:0]  dsp_B;
   logic [47:0]  dsp_C;
   logic [47:0]  dsp_PCIN;
   logic [6:0] 	 dsp_OPMODE;
   logic [3:0] 	 dsp_ALUMODE;
   logic [4:0] 	 dsp_INMODE;

   logic 	 dsp_CEA1;
   logic 	 dsp_CEA2;
   logic 	 dsp_CEB1;
   logic 	 dsp_CEB2;
   logic 	 dsp_CEC;
   logic 	 dsp_CEP;
   logic 	 dsp_CEM;
   logic 	 dsp_CEALUMODE;
   logic 	 dsp_CEOPMODE;
   logic 	 dsp_CEINMODE;

   logic 	 dsp_RSTA;
   logic 	 dsp_RSTB;
   logic 	 dsp_RSTC;
   logic 	 dsp_RSTP;
   logic 	 dsp_RSTM;
   logic 	 dsp_RSTALUMODE;
   logic 	 dsp_RSTOPMODE;
   logic 	 dsp_RSTINMODE;

   logic [1:0] 	 dsp_x_mux;
   logic [1:0] 	 dsp_y_mux;
   logic [2:0] 	 dsp_z_mux;
   //

   logic [LP_MAX_PIPE_STAGES-1:0] res_vld_reg;
   logic [31:0] 		  op1_reg;
   logic [31:0] 		  op1_reg_sign_ext;
   logic [31:0] 		  op2_reg_sign_ext;
   logic [31:0] 		  op2_reg;
   logic [31:0] 		  op2_reg2;
   logic [1:0][31:0] 		  op3_reg;
   logic [1:0]			  input_sew_reg;
   logic [1:0]			  output_sew_reg;
   logic [2:0][8:0] 		  alu_opmode_reg;
   logic [3:0] 			  reduction_op_reg;                      
   logic [15:0] 		  dsp_A_upper_bits;
   logic [1:0] 			  dsp_B_upper_bits_reg;
   logic [15:0] 		  dsp_C_upper_bits;

   // Comparators signals
   logic [1:0] 			  comp_out_reg;
   logic 			  comp_out_next;

   // output signals
   logic [31:0] 		  result_reg;
   logic                          alu_vld_reg;
   logic 			  reduction_first_operand_reg;
   logic 			  first_element;
   logic 			  last_element;
   // Logic that sends valid signal through the pipeline.
   //assign reduction_first_operand_reg = !res_vld_reg[2] && res_vld_reg[1] && reduction_op_reg[0];

   always @(posedge clk)
   begin
      if (!rstn)
      begin
	 reduction_first_operand_reg <= 1'b0;
      end
      else
      begin
	 if(!reduction_first_operand_reg && reduction_op_reg[1] && !reduction_op_reg[2])
	   reduction_first_operand_reg <= 1'b1;
	 else if (res_vld_reg[1])
	   reduction_first_operand_reg <= 1'b0;
	   
      end
   end



   assign first_element = res_vld_reg[0] && !res_vld_reg[1];
   assign last_element   = !alu_vld_i && alu_vld_reg;

   always @ (posedge clk)
   begin
      if (!rstn)
      begin
	 res_vld_reg <= '{default:'0};
	 alu_vld_reg <= 'h0;
	 op1_reg <= 'h0;
	 op2_reg <= 'h0;
	 op3_reg <= '{default:'0};
	 alu_opmode_reg <='{default:'0};
	 comp_out_reg <= 'h0;
	 input_sew_reg <= 2'b0;
	 output_sew_reg <= 2'b0;
	 reduction_op_reg <= 'h0;
      end
      else
      begin
	 
	 if (V_LANE_NUM!=0)
	 begin	    
	    if (reduction_op_i && alu_opmode_i[6:5]==2'b01)
	    begin
	       res_vld_reg <= {res_vld_reg[LP_MAX_PIPE_STAGES-2:0], (alu_vld_i | last_element)};
	       if ((first_element || !comp_out_next)  && res_vld_reg[0])		 
		 op1_reg <= op2_reg;	       
	    end
	    else
	    begin
	       res_vld_reg <= {res_vld_reg[LP_MAX_PIPE_STAGES-2:0], alu_vld_i};
	       op1_reg <= op1_i;
	    end
	 end	 
	 else
	 begin
	    res_vld_reg <= {res_vld_reg[LP_MAX_PIPE_STAGES-2:0], alu_vld_i};
	    if  (reduction_op_reg[1])
	    begin
	       if (!comp_out_next && res_vld_reg[0])
		 op1_reg <= op2_reg;
	    end
	    else
	      op1_reg <= op1_i;
	 end
	 op2_reg <= op2_i;
	 op3_reg <= {op3_reg[0], op3_i};
	 reduction_op_reg <= {reduction_op_reg[2:0], reduction_op_i};
	 alu_opmode_reg[0] <= alu_opmode_i;
	 alu_vld_reg <= alu_vld_i;
	 if (!reduction_first_operand_reg)
	 begin
	   if (alu_opmode_reg[0][6:5]==2'b10)
	     alu_opmode_reg[1] <= {alu_opmode_reg[0][8:4], 2'b00, alu_opmode_reg[0][1:0]};
	   else if ( alu_opmode_reg[0][6:5]==2'b01)
	     alu_opmode_reg[1] <= {alu_opmode_reg[0][8:4], 4'b0000};
	   else
	     alu_opmode_reg[1] <= alu_opmode_reg[0];
	 end
	 else if (V_LANE_NUM != 0)
	   alu_opmode_reg[1][3:0] <= 0;

	 alu_opmode_reg[2] <= alu_opmode_reg[1];
	 comp_out_reg <= {comp_out_reg[0], comp_out_next};
	 input_sew_reg <= input_sew_i;
	 output_sew_reg <= output_sew_i;
      end
   end


   always_comb
   begin
      op1_reg_sign_ext = op1_reg;
      if (alu_opmode_reg[0][7])
      begin
	 if (input_sew_reg==2'b00)
	   op1_reg_sign_ext = {{24{op1_reg[7]}}, op1_reg[7:0]};
	 if (input_sew_reg==2'b01)
	   op1_reg_sign_ext = {{16{op1_reg[15]}}, op1_reg[15:0]};
      end
      
      op2_reg_sign_ext = op2_reg;
      if (alu_opmode_reg[0][7])
      begin
	 if (input_sew_reg==2'b00)
	   op2_reg_sign_ext = {{24{op2_reg[7]}}, op2_reg[7:0]};
	 if (input_sew_reg==2'b01)
	   op2_reg_sign_ext = {{16{op2_reg[15]}}, op2_reg[15:0]};
      end      
   end
   assign alu_vld_o = res_vld_reg[LP_MAX_PIPE_STAGES-1];


   
   //connecting right values to dsp I/O

   // Control of x, y, z multiplexers inside DSP depending on alu_opmode
   assign dsp_x_mux = alu_opmode_reg[1][6:5] == 2'b00 || alu_opmode_reg[1][6:5] == 2'b01 ? LP_DSP_X_MUX_NORMAL :
		      alu_opmode_reg[1][6:4] == 3'b101 ? LP_DSP_X_MUX_MUL :
		      LP_DSP_X_MUX_MUL_ACC;
   assign dsp_y_mux = alu_opmode_reg[1][6:5] == 2'b00 || alu_opmode_reg[1][6:5] == 2'b01 ? {alu_opmode_reg[1][4], 1'b0} :
		      alu_opmode_reg[1][6:4] == 3'b101 ? LP_DSP_Y_MUX_MUL :
		      LP_DSP_Y_MUX_MUL_ACC;
   generate
      if (V_LANE_NUM !=0)
      begin
	 assign dsp_z_mux = alu_opmode_reg[1][6:5] == 2'b01 ? LP_DSP_Z_MUX_NORMAL :
			    reduction_op_reg[1] == 1'b1 ? LP_DSP_Z_MUX_REDUCTION :
			    alu_opmode_reg[1][6:5] == 2'b00 ? LP_DSP_Z_MUX_NORMAL :
			    alu_opmode_reg[1][6:4] == 3'b101 ? LP_DSP_Z_MUX_MUL :
			    LP_DSP_Z_MUX_MUL_ACC;
      end
      else
      begin
	 assign dsp_z_mux = alu_opmode_reg[1][6:5] == 2'b01 ? LP_DSP_Z_MUX_NORMAL :
			    reduction_op_reg[1] == 1'b1 && reduction_first_operand_reg ? LP_DSP_Z_MUX_NORMAL:
			    reduction_op_reg[1] == 1'b1 ? LP_DSP_Z_MUX_REDUCTION :
			    alu_opmode_reg[1][6:5] == 2'b00 ? LP_DSP_Z_MUX_NORMAL :
			    alu_opmode_reg[1][6:4] == 3'b101 ? LP_DSP_Z_MUX_MUL :
			    LP_DSP_Z_MUX_MUL_ACC;
      end
   endgenerate

   assign dsp_ALUMODE = alu_opmode_reg[1][3:0];
   assign dsp_OPMODE  = {dsp_z_mux, dsp_y_mux, dsp_x_mux};
   assign dsp_INMODE = 5'b00000;
   
   //if non-multoply OP we need only bits [31:18] for port A of dsp, the other bits are sign,
   // else we need bits [15:0] and others are sign.
   assign dsp_A = alu_opmode_reg[0][6:5] == 2'b00 ? {{16{op2_reg_sign_ext[31]}}, op2_reg_sign_ext[31:18]} : 
		  {{14{op1_reg_sign_ext[31]}}, op1_reg_sign_ext[15:0]};
   

   assign dsp_B = alu_opmode_reg[0][6:5] == 2'b00 ? op2_reg_sign_ext[17:0] : op2_reg_sign_ext[17:0];


   assign dsp_C = alu_opmode_reg[0][6:4] == 3'b100 ? {{16{1'b0}}, op3_reg[1]}:
		  {{16{op1_reg_sign_ext[31]}}, op1_reg_sign_ext};

   //output

   always @(posedge clk)
   begin
      if (res_vld_reg[2])begin
	 result_reg <= alu_opmode_reg[2][6:5]==2'b01 && !reduction_op_i ? {dsp_P[31:1], comp_out_reg[1]} : dsp_P;
	 if (output_sew_reg == 2'b00)
	 begin
	    if (alu_opmode_reg[2][6:5]==2'b10) // take the value from dsp
	    begin
	       if (alu_opmode_reg[2][4:3]==2'b11) //switch high bits for low (mulh, mulhu, ...)
		 result_reg[7:0] <= dsp_P[15:8];
	    end	 
	 end
	 if (output_sew_reg == 2'b01)
	 begin	 
	    if (alu_opmode_reg[2][6:5]==2'b10)
	    begin
	       if (alu_opmode_reg[2][4:3]==2'b11) //switch high bits for low (mulh, mulhu, ...)
		 result_reg[15:0] <= dsp_P[31:16];
	    end	 
	 end
      end
   end
   //assign result_o = alu_opmode_reg[6:5]==2'b01 ? {dsp_P[31:1], comp_out_reg} : dsp_P;
   assign result_o = result_reg;
   assign  dsp_CEA1 = 1'b1;
   assign  dsp_CEA2 = 1'b1;
   assign  dsp_CEB1 = 1'b1;
   assign  dsp_CEB2 = 1'b1;
   assign  dsp_CEC = 1'b1;
   assign  dsp_CEP = res_vld_reg[1];
   assign  dsp_CEM = 1'b1;
   assign  dsp_CEALUMODE = 1'b1;
   assign  dsp_CEOPMODE = 1'b1;
   assign  dsp_CEINMODE = 1'b1;

   assign  dsp_RSTA = !rstn || (reduction_op_i && alu_opmode_reg[0][6:5]==2'b01);
   assign  dsp_RSTB = !rstn || (reduction_op_i && alu_opmode_reg[0][6:5]==2'b01);
   assign  dsp_RSTC = !rstn;
   assign  dsp_RSTP = !rstn || (!reduction_op_i && alu_opmode_reg[0][6:5]==2'b01) || (!reduction_op_reg[2] && !res_vld_reg[1]);
   assign  dsp_RSTM = !rstn;
   assign  dsp_RSTALUMODE = !rstn;
   assign  dsp_RSTOPMODE = !rstn;
   assign  dsp_RSTINMODE = !rstn;


      

   always_comb
   begin
      comp_out_next = 1'b0;
      case (alu_opmode_reg[0][8:0])
	 slt_op: comp_out_next = signed'(op1_reg_sign_ext) < signed'(op2_reg_sign_ext);
	 sgt_op: comp_out_next = ~(signed'(op1_reg_sign_ext) < signed'(op2_reg_sign_ext));
	 seq_op: comp_out_next = (op1_reg_sign_ext) == (op2_reg_sign_ext);
	 sle_op: comp_out_next = (signed'(op1_reg_sign_ext) < signed'(op2_reg_sign_ext) || (op1_reg_sign_ext) == (op2_reg_sign_ext));
	 sltu_op: comp_out_next = op1_reg_sign_ext < op2_reg_sign_ext;
	 sgtu_op: comp_out_next = ~(op1_reg_sign_ext < op2_reg_sign_ext);
	 sleu_op: comp_out_next = ((op1_reg_sign_ext < op2_reg_sign_ext) || (op1_reg_sign_ext == op2_reg_sign_ext));
	 sneq_op: comp_out_next = ~(op1_reg_sign_ext == op2_reg_sign_ext);
      endcase
   end
 
   DSP48E1 #(
	     // Feature Control Attributes: Data Path Selection
	     .A_INPUT("DIRECT"),               // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
	     .B_INPUT("DIRECT"),               // Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
	     .USE_DPORT("FALSE"),              // Select D port usage (TRUE or FALSE)
	     .USE_MULT("MULTIPLY"),            // Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
	     .USE_SIMD("ONE48"),               // SIMD selection ("ONE48", "TWO24", "FOUR12")
	     // Pattern Detector Attributes: Pattern Detection Configuration
	     .AUTORESET_PATDET("NO_RESET"),    // "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
	     .MASK(48'h3fffffffffff),          // 48-bit mask value for pattern detect (1=ignore)
	     .PATTERN(48'h000000000000),       // 48-bit pattern match for pattern detect
	     .SEL_MASK("MASK"),                // "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
	     .SEL_PATTERN("PATTERN"),          // Select pattern value ("PATTERN" or "C")
	     .USE_PATTERN_DETECT("NO_PATDET"), // Enable pattern detect ("PATDET" or "NO_PATDET")
	     // Register Control Attributes: Pipeline Register Configuration
	     .ACASCREG(1),                     // Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
	     .ADREG(1),                        // Number of pipeline stages for pre-adder (0 or 1)
	     .ALUMODEREG(0),                   // Number of pipeline stages for ALUMODE (0 or 1)
	     .AREG(1),                         // Number of pipeline stages for A (0, 1 or 2)
	     .BCASCREG(1),                     // Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
	     .BREG(1),                         // Number of pipeline stages for B (0, 1 or 2)
	     .CARRYINREG(1),                   // Number of pipeline stages for CARRYIN (0 or 1)
	     .CARRYINSELREG(1),                // Number of pipeline stages for CARRYINSEL (0 or 1)
	     .CREG(1),                         // Number of pipeline stages for C (0 or 1)
	     .DREG(1),                         // Number of pipeline stages for D (0 or 1)
	     .INMODEREG(0),                    // Number of pipeline stages for INMODE (0 or 1)
	     .MREG(0),                         // Number of multiplier pipeline stages (0 or 1)
	     .OPMODEREG(0),                    // Number of pipeline stages for OPMODE (0 or 1)
	     .PREG(1)                          // Number of pipeline stages for P (0 or 1)
	     )
   DSP48E1_inst (
		 // Cascade: 30-bit (each) output: Cascade Ports
		 .ACOUT(),                   // 30-bit output: A port cascade output
		 .BCOUT(),                   // 18-bit output: B port cascade output
		 .CARRYCASCOUT(),     // 1-bit output: Cascade carry output
		 .MULTSIGNOUT(),       // 1-bit output: Multiplier sign cascade output // TODO: maybe needed
		 .PCOUT(),                   // 48-bit output: Cascade output
		 // Control: 1-bit (each) output: Control Inputs/Status Bits
		 .OVERFLOW(),             // 1-bit output: Overflow in add/acc output //TODO: maybe needed
		 .PATTERNBDETECT(), // 1-bit output: Pattern bar detect output
		 .PATTERNDETECT(),   // 1-bit output: Pattern detect output
		 .UNDERFLOW(),           // 1-bit output: Underflow in add/acc output
		 // Data: 4-bit (each) output: Data Ports
		 .CARRYOUT(),             // 4-bit output: Carry output
		 .P(dsp_P),                           // 48-bit output: Primary data output
		 // Cascade: 30-bit (each) input: Cascade Ports
		 .ACIN('h0),                     // 30-bit input: A cascade data input
		 .BCIN('h0),                     // 18-bit input: B cascade input
		 .CARRYCASCIN(1'b0),       // 1-bit input: Cascade carry input
		 .MULTSIGNIN(1'b0),         // 1-bit input: Multiplier sign input // TODO: needed
		 .PCIN('h0),                     // 48-bit input: P cascade input
		 // Control: 4-bit (each) input: Control Inputs/Status Bits
		 .ALUMODE(dsp_ALUMODE),               // 4-bit input: ALU control input
		 .CARRYINSEL('h0),         // 3-bit input: Carry select input
		 .CLK(clk),                       // 1-bit input: Clock input
		 .INMODE(dsp_INMODE),                 // 5-bit input: INMODE control input
		 .OPMODE(dsp_OPMODE),                 // 7-bit input: Operation mode input
		 // Data: 30-bit (each) input: Data Ports
		 .A(dsp_A),                           // 30-bit input: A data input
		 .B(dsp_B),                           // 18-bit input: B data input
		 .C(dsp_C),                           // 48-bit input: C data input
		 .CARRYIN(1'b0),               // 1-bit input: Carry input signal
		 .D('h0),                           // 25-bit input: D data input
		 // Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
		 .CEA1(dsp_CEA1),                     // 1-bit input: Clock enable input for 1st stage AREG
		 .CEA2(dsp_CEA2),                     // 1-bit input: Clock enable input for 2nd stage AREG
		 .CEAD(1'b0),                     // 1-bit input: Clock enable input for ADREG
		 .CEALUMODE(dsp_CEALUMODE),           // 1-bit input: Clock enable input for ALUMODE
		 .CEB1(dsp_CEB1),                     // 1-bit input: Clock enable input for 1st stage BREG
		 .CEB2(dsp_CEB2),                     // 1-bit input: Clock enable input for 2nd stage BREG
		 .CEC(dsp_CEC),                       // 1-bit input: Clock enable input for CREG
		 .CECARRYIN(1'b1),           // 1-bit input: Clock enable input for CARRYINREG
		 .CECTRL(dsp_CEOPMODE),                 // 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
		 .CED(1'b0),                       // 1-bit input: Clock enable input for DREG
		 .CEINMODE(dsp_CEINMODE),             // 1-bit input: Clock enable input for INMODEREG
		 .CEM(dsp_CEM),                       // 1-bit input: Clock enable input for MREG
		 .CEP(dsp_CEP),                       // 1-bit input: Clock enable input for PREG
		 .RSTA(dsp_RSTA),                     // 1-bit input: Reset input for AREG
		 .RSTALLCARRYIN(1'b1),   // 1-bit input: Reset input for CARRYINREG
		 .RSTALUMODE(dsp_RSTALUMODE),         // 1-bit input: Reset input for ALUMODEREG
		 .RSTB(dsp_RSTB),                     // 1-bit input: Reset input for BREG
		 .RSTC(dsp_RSTC),                     // 1-bit input: Reset input for CREG
		 .RSTCTRL(dsp_RSTOPMODE),               // 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
		 .RSTD(1'b0),                     // 1-bit input: Reset input for DREG and ADREG
		 .RSTINMODE(dsp_RSTINMODE),           // 1-bit input: Reset input for INMODEREG
		 .RSTM(dsp_RSTM),                     // 1-bit input: Reset input for MREG
		 .RSTP(dsp_RSTP)                      // 1-bit input: Reset input for PREG
		 );

endmodule

