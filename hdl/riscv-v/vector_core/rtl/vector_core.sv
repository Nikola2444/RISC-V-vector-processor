module vector_core #
  (parameter VLEN=4096,
   parameter VLANE_NUM=16,
   parameter R_PORTS_NUM = 8,
   parameter W_PORTS_NUM = 4,
   parameter MULTIPUMP_WRITE = 2,
   parameter MULTIPUMP_READ = 2,
   parameter MEM_WIDTH =32
   )
   (/*AUTOARG*/
    // Outputs
    vector_stall_o,
    // Inputs
    clk, clk2, rstn, rs1_i, rs2_i, vector_instr_i
    );
   localparam LP_VECTOR_REGISTER_NUM=32;
   localparam LP_MAX_LMUL=8;
   localparam MEM_DEPTH=VLEN/VLANE_NUM;
   localparam ALU_OPMODE_WIDTH=9;
   // Number of bytes in VRF
   localparam LP_LANE_VRF_EL_NUM=VLEN*LP_VECTOR_REGISTER_NUM/8/VLANE_NUM;
   localparam LP_MAX_VL_PER_LANE=VLEN/8/VLANE_NUM*LP_MAX_LMUL;
   localparam VREG_LOC_PER_LANE = VLEN/VLANE_NUM/32; 

   input 	 clk;
   input         clk2;
   input 	 rstn;

   //scalar core interface
   input [31:0]  rs1_i;
   input [31:0]  rs2_i;
   input [31:0]  vector_instr_i;
   output 	 vector_stall_o;
   //data interface    


   // Scheduler-M_CU interconnections
   logic [31:0]  mcu_base_addr;	// From scheduler_inst of scheduler.v
   logic [2:0] 	 mcu_data_width;	// From scheduler_inst of scheduler.v
   logic 	 mcu_idx_ld_st;	// From scheduler_inst of scheduler.v
   logic 	 mcu_ld_vld;		// From scheduler_inst of scheduler.v
   logic 	 mcu_st_vld;		// From scheduler_inst of scheduler.v
   logic [31:0]  mcu_stride;		// From scheduler_inst of scheduler.v
   logic 	 mcu_strided_ld_st;	// From scheduler_inst of scheduler.v
   logic 	 mcu_unit_ld_st;	// From scheduler_inst of scheduler.v
   
   logic 	 mcu_ld_rdy=1'b1;
   logic 	 mcu_ld_buffered=1'b1;
   logic 	 mcu_st_rdy=1'b1;

   //Scheduler-V_CU interconnections
   logic [11:0]  instr_vld;		// From scheduler_inst of scheduler.v
   logic [31:0]  vector_instr;		// From scheduler_inst of scheduler.v
   logic [2:0] 	 sew;
   logic [2:0] 	 lmul;
   logic [11:0]  instr_rdy;
   logic [31:0]  scalar_rs1;
   logic [31:0]  scalar_rs2;

   //renaming_unit-vcu
   logic 	 ru_vrf_starting_addr_vld;
   logic [8*$clog2(MEM_DEPTH)-1:0] ru_vrf_starting_waddr;
   logic [8*$clog2(MEM_DEPTH)-1:0] ru_vrf_starting_raddr0;
   logic [8*$clog2(MEM_DEPTH)-1:0] ru_vrf_starting_raddr1;
   

   // V_CU-Vector_lanes interconnections
   logic [2:0] 			   inst_type;
   logic [W_PORTS_NUM-1:0] 	   start;
   logic [4:0] 			   alu_imm;	// From v_cu_inst of v_cu.v
   logic [ALU_OPMODE_WIDTH-1:0]    alu_opmode;// From v_cu_inst of v_cu.v
   logic 			   reduction_op;// From v_cu_inst of v_cu.v
   logic [31:0] 		   alu_x_data;	// From v_cu_inst of v_cu.v
   logic [$clog2(LP_MAX_VL_PER_LANE)-1:0] inst_delay;// From v_cu_inst of v_cu.v
   logic [31:0] 			  vl;
   logic [1:0] 				  op2_sel;	// From v_cu_inst of v_cu.v
   logic [$clog2(R_PORTS_NUM)-1:0] 	  op3_sel;// From v_cu_inst of v_cu.v
   logic [31:0] 			  rs1_o;			// From scheduler_inst of scheduler.v
   logic [2:0] 				  sew_o;			// From v_cu_inst of v_cu.v
   logic [31:0] 			  slide_amount;		// From v_cu_inst of v_cu.v

   logic [$clog2(R_PORTS_NUM)-1:0] 	  store_data_mux_sel_i;// From v_cu_inst of v_cu.v
   logic [$clog2(R_PORTS_NUM)-1:0] 	  store_load_index_mux_sel_i;// From v_cu_inst of v_cu.v
   logic 				  up_down_slide;	// From v_cu_inst of v_cu.v
   logic 				  vector_mask;	// From v_cu_inst of v_cu.v
   logic [31:0] 			  vl_o;			// From v_cu_inst of v_cu.v
   logic 				  vrf_oreg_ren;		// From v_cu_inst of v_cu.v
   logic 				  vrf_ren;		// From v_cu_inst of v_cu.v
   logic [8*$clog2(MEM_DEPTH)-1:0] 	  vrf_starting_raddr_vs1;// From v_cu_inst of v_cu.v
   logic [8*$clog2(MEM_DEPTH)-1:0] 	  vrf_starting_raddr_vs2;// From v_cu_inst of v_cu.v
   logic [8*$clog2(MEM_DEPTH)-1:0] 	  vrf_starting_waddr;// From v_cu_inst of v_cu.v
   logic [1:0] 				  wdata_width;		// From v_cu_inst of v_cu.v
   logic [W_PORTS_NUM-1:0] 		  port_group_ready;
   logic [$clog2(R_PORTS_NUM)-1:0] 	  store_data_mux_sel;
   logic [$clog2(R_PORTS_NUM)-1:0] 	  store_load_idx_mux_sel;
   
   // End of automatics
   /*INSTANTIATE SCHEDULER*/
   scheduler scheduler_inst
     (/*AUTO_INST*/
      // Outputs
      .vector_stall_o			(vector_stall_o),
      .instr_vld_o			(instr_vld[11:0]),
      .vector_instr_o			(vector_instr[31:0]),
      .mcu_ld_vld_o			(mcu_ld_vld),
      .mcu_st_vld_o			(mcu_st_vld),
      .mcu_base_addr_o			(mcu_base_addr[31:0]),
      .mcu_stride_o			(mcu_stride[31:0]),
      .mcu_data_width_o			(mcu_data_width[2:0]),
      .mcu_idx_ld_st_o			(mcu_idx_ld_st),
      .mcu_strided_ld_st_o		(mcu_strided_ld_st),
      .mcu_unit_ld_st_o			(mcu_unit_ld_st),

      .scalar_rs1_o			(scalar_rs1[31:0]),
      .scalar_rs2_o			(scalar_rs2[31:0]),
      // Inputs
      .clk				(clk),
      .rstn				(rstn),
      .vector_instr_i			(vector_instr_i[31:0]),
      .rs1_i				(rs1_i[31:0]),
      .rs2_i				(rs2_i[31:0]),
      .sew_i				(sew[1:0]),
      .instr_rdy_i			(instr_rdy),
      .mcu_ld_rdy_i			(mcu_ld_rdy),
      .mcu_ld_buffered_i		(mcu_ld_buffered),
      .mcu_st_rdy_i			(mcu_st_rdy));
   /*INSTANTIATE V_CU*/


   renaming_unit #
     (/*AUTO_INSTPARAM*/
      // Parameters
      .VLEN     		(VLEN),
      .VLANE_NUM		(VLANE_NUM),
      .R_PORTS_NUM		(R_PORTS_NUM),
      .W_PORTS_NUM		(W_PORTS_NUM))
   renaming_unit_inst     
     (/*AUTO_INST*/
      // Outputs      
      .vrf_starting_waddr_o (ru_vrf_starting_waddr),
      .vrf_starting_raddr0_o(ru_vrf_starting_raddr0),
      .vrf_starting_raddr1_o(ru_vrf_starting_raddr1),
      .vrf_starting_addr_vld_o(ru_vrf_starting_addr_vld),
      // Inputs
      .instr_vld_i	(1'b1),
      //.lmul_i		(lmul_i[1:0]),      
      .vector_instr_i(vector_instr));
   

   v_cu #(/*AUTO_INSTPARAM*/
	  // Parameters
	  .VLEN				(VLEN),
	  .VLANE_NUM			(VLANE_NUM),
	  .R_PORTS_NUM			(R_PORTS_NUM),
	  .W_PORTS_NUM			(W_PORTS_NUM))
   v_cu_inst(/*AUTO_INST*/
	     // Outputs
	     .instr_rdy_o		(instr_rdy),
	     .sew_o			(sew[2:0]),
	     .lmul_o			(lmul[2:0]),
	     .vl_o			(vl[31:0]),
	     .inst_type_o		(inst_type[2:0]),
	     .start_o			(start[W_PORTS_NUM-1:0]),
	     .inst_delay_o		(inst_delay/*[W_PORTS_NUM-1:0][$clog2(LP_MAX_VL_PER_LANE)-1:0]*/),
	     .vrf_ren_o			(vrf_ren),
	     .vrf_oreg_ren_o		(vrf_oreg_ren),
	     .vrf_starting_waddr_o	(vrf_starting_waddr[8*$clog2(MEM_DEPTH)-1:0]),
	     .vrf_starting_raddr_vs1_o	(vrf_starting_raddr_vs1[8*$clog2(MEM_DEPTH)-1:0]),
	     .vrf_starting_raddr_vs2_o	(vrf_starting_raddr_vs2[8*$clog2(MEM_DEPTH)-1:0]),
	     .wdata_width_o		(wdata_width[1:0]),
	     .store_data_mux_sel_o	(store_data_mux_sel[$clog2(R_PORTS_NUM)-1:0]),
	     .store_load_index_mux_sel_o(store_load_idx_mux_sel[$clog2(R_PORTS_NUM)-1:0]),
	     .op2_sel_o			(op2_sel/*[W_PORTS_NUM-1:0][1:0]*/),
	     .op3_sel_o			(op3_sel/*[W_PORTS_NUM-1:0][$clog2(R_PORTS_NUM)-1:0]*/),
	     .alu_x_data_o		(alu_x_data/*[W_PORTS_NUM-1:0][31:0]*/),
	     .alu_imm_o			(alu_imm/*[W_PORTS_NUM-1:0][4:0]*/),
	     .alu_opmode_o		(alu_opmode/*[W_PORTS_NUM-1:0][ALU_OPMODE_WIDTH-1:0]*/),
	     .reduction_op_o               (reduction_op),
	     .up_down_slide_o		(up_down_slide),
	     .slide_amount_o		(slide_amount[31:0]),
	     .vector_mask_o		(vector_mask),
	     // Inputs
	     .clk			(clk),
	     .rstn			(rstn),
	     .instr_vld_i		(instr_vld[11:0]),
	     .scalar_rs1_i		(scalar_rs1[31:0]),
	     .scalar_rs2_i		(scalar_rs2[31:0]),
	     .vector_instr_i		(vector_instr[31:0]),
	     .port_group_ready_i	(port_group_ready[W_PORTS_NUM-1:0]),
	     .vrf_starting_waddr_i (ru_vrf_starting_waddr),
	     .vrf_starting_raddr0_i(ru_vrf_starting_raddr0),
	     .vrf_starting_raddr1_i(ru_vrf_starting_raddr1),
	     .vrf_starting_addr_vld_i(ru_vrf_starting_addr_vld));
   /*INSTANTIATE M_CU*/

   /*INSTANTIATE V_LANES*/
   Vlane_with_low_lvl_ctrl # 
     (/*AUTO_INSTPARAM*/
      // Parameters
      .MEM_DEPTH			(MEM_DEPTH),
      .MAX_VL_PER_LANE 		        (LP_MAX_VL_PER_LANE),
      .VREG_LOC_PER_LANE		(VREG_LOC_PER_LANE),
      .W_PORTS_NUM			(W_PORTS_NUM),
      .R_PORTS_NUM			(R_PORTS_NUM),
      .INST_TYPE_NUM			(7),
      .VLANE_NUM			(VLANE_NUM),
      .ALU_OPMODE			(9),
      .MULTIPUMP_WRITE			(MULTIPUMP_WRITE),
      .MULTIPUMP_READ			(MULTIPUMP_READ),
      .MEM_WIDTH			(MEM_WIDTH))
   Vlane_with_low_lvl_ctrl_inst
     (/*AUTO_INST*/
      // Outputs


      .ready_for_load_o			(),
      .store_data_o			(),
      .store_load_index_o		(),
      .store_data_valid_o		(),
      .store_load_index_valid_o		(),

      .load_valid_i			(1'b0),
      .load_last_i			(1'b0),
      .load_data_i			('h0),
      // Inputs
      .clk_i				(clk),
      .clk2_i				(clk2),
      .rst_i				(rstn),
      .vl_i				(vl[$clog2(VLANE_NUM*LP_MAX_VL_PER_LANE)-1:0]), // this should be 31:0
      .vsew_i				(sew[2:0]),
      .vlmul_i				(lmul[2:0]),
      .inst_type_i			(inst_type),
      .start_i				(start[W_PORTS_NUM-1:0]),
      .inst_delay_i			(inst_delay),
      .vrf_ren_i			(vrf_ren),
      .vrf_oreg_ren_i			(vrf_oreg_ren),
      .vrf_starting_waddr_i		(vrf_starting_waddr),
      .vrf_starting_raddr_i		({vrf_starting_waddr, vrf_starting_raddr_vs2, vrf_starting_raddr_vs1}), //TODO: how to orded them ?
      .wdata_width_i			(wdata_width[1:0]),
      .ready_o				(port_group_ready[W_PORTS_NUM-1:0]),

      .store_data_mux_sel_i		(store_data_mux_sel),
      .store_load_index_mux_sel_i	(store_load_idx_mux_sel),
      .op2_sel_i			(op2_sel[1:0]),
      .op3_sel_i			(op3_sel),
      .ALU_x_data_i			(alu_x_data[31:0]),
      .ALU_imm_i			(alu_imm[4:0]),
      .reduction_op_i                   (reduction_op),
      .ALU_opmode_i			(alu_opmode),
      .alu_en_32bit_mul_i		(1'b0),
      .up_down_slide_i			(up_down_slide),
      .slide_amount_i			(slide_amount[31:0]),
      .vector_mask_i			(vector_mask),
      .read_port_allocation_i		(read_port_allocation/*[R_PORTS_NUM-1:0][$clog2(W_PORTS_NUM)-1:0]*/), // TODO: what is this
      .primary_read_data_i		(8'hff));//TODO: what is this


   // Instantiate M_CU

   //
endmodule

// Local Variables:
// verilog-library-extensions:(".v" ".sv" "_stub.v" "_bb.v")
// verilog-library-directories:("." "../../common/" "../scheduler/rtl/" "../v_cu/rtl/")
// End:
