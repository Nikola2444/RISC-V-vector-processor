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

   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   logic [10:0]		instr_vld;		// From scheduler_inst of scheduler.v
   logic [31:0]		mcu_base_addr;	// From scheduler_inst of scheduler.v
   logic [2:0]		mcu_data_width;	// From scheduler_inst of scheduler.v
   logic		mcu_idx_ld_st;	// From scheduler_inst of scheduler.v
   logic		mcu_ld_vld;		// From scheduler_inst of scheduler.v
   logic		mcu_st_vld;		// From scheduler_inst of scheduler.v
   logic [31:0]		mcu_stride;		// From scheduler_inst of scheduler.v
   logic		mcu_strided_ld_st;	// From scheduler_inst of scheduler.v
   logic		mcu_unit_ld_st;	// From scheduler_inst of scheduler.v
   logic [31:0]		vector_instr;		// From scheduler_inst of scheduler.v

   //Scheduler inputs
   logic [1:0] 		sew=2'b0;
   logic [10:0] 	instr_rdy='{default:'1};
   logic 		mcu_ld_rdy=1'b1;
   logic 		mcu_ld_buffered=1'b1;
   logic 		mcu_st_rdy=1'b1;
   
   // End of automatics
/*INSTANTIATE SCHEDULER*/
   scheduler scheduler_inst
     (/*AUTOINST*/
      // Outputs
      .vector_stall_o			(vector_stall_o),
      .instr_vld_o			(instr_vld[10:0]),
      .vector_instr_o			(vector_instr[31:0]),
      .mcu_ld_vld_o			(mcu_ld_vld),
      .mcu_st_vld_o			(mcu_st_vld),
      .mcu_base_addr_o			(mcu_base_addr[31:0]),
      .mcu_stride_o			(mcu_stride[31:0]),
      .mcu_data_width_o			(mcu_data_width[2:0]),
      .mcu_idx_ld_st_o			(mcu_idx_ld_st),
      .mcu_strided_ld_st_o		(mcu_strided_ld_st),
      .mcu_unit_ld_st_o			(mcu_unit_ld_st),
      // Inputs
      .clk				(clk),
      .rstn				(rstn),
      .vector_instr_i			(vector_instr_i[31:0]),
      .rs1_i				(rs1_i[31:0]),
      .rs2_i				(rs2_i[31:0]),
      .sew_i				(sew[1:0]),
      .instr_rdy_i			(instr_rdy[10:0]),
      .mcu_ld_rdy_i			(mcu_ld_rdy),
      .mcu_ld_buffered_i		(mcu_ld_buffered),
      .mcu_st_rdy_i			(mcu_st_rdy));
/*INSTANTIATE V_CU*/

/*INSTANTIATE M_CU*/

/*INSTANTIATE V_LANES*/

   
endmodule

// Local Variables:
// verilog-library-extensions:(".v" ".sv" "_stub.v" "_bb.v")
// verilog-library-directories:("." "../../common/" "../scheduler/rtl/")
// End:
