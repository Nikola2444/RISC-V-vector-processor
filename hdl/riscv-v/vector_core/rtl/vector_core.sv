module vector_core #
  (parameter VLEN=1024,
   parameter VLANE_NUM=4,
   parameter R_PORTS_NUM = 8,
   parameter W_PORTS_NUM = 4,
   parameter MULTIPUMP_WRITE = 2,
   parameter MULTIPUMP_READ  = 2,
   parameter MEM_WIDTH =32,
   parameter C_M_AXI_ADDR_WIDTH       = 32,
   parameter C_M_AXI_DATA_WIDTH       = 32,
   parameter C_XFER_SIZE_WIDTH        = 32
   )
   (/*AUTOARG*/
   // Outputs
   vector_stall_o, ctrl_raddr_offset_o, ctrl_rxfer_size_o,
   ctrl_rstart_o, rd_tready_o, ctrl_waddr_offset_o, ctrl_wxfer_size_o,
   ctrl_wstart_o, wr_tdata_o, wr_tvalid_o,ctrl_wstrb_msk_en_o, wr_tstrb_msk_o,
   // Inputs
   clk, clk2, rstn, rs1_i, rs2_i, vector_instr_i, ctrl_rdone_i,
   rd_tdata_i, rd_tvalid_i, rd_tlast_i, ctrl_wdone_i, wr_tready_i
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
   input 	 clk2;
   input 	 rstn;

   //scalar core interface
   input [31:0]  rs1_i;
   input [31:0]  rs2_i;
   input [31:0]  vector_instr_i;
   output 	 vector_stall_o;
   //data interface    
   // MCU <=> AXIM CONTROL IF [read channel]
   output logic [C_M_AXI_ADDR_WIDTH-1:0] ctrl_raddr_offset_o     ;
   output logic [C_XFER_SIZE_WIDTH-1:0]  ctrl_rxfer_size_o       ;
   output logic 			 ctrl_rstart_o           ;
   input  logic 			 ctrl_rdone_i            ;
   input  logic [C_M_AXI_DATA_WIDTH-1:0] rd_tdata_i              ;
   input  logic 			 rd_tvalid_i             ;
   output logic 			 rd_tready_o             ;
   input  logic 			 rd_tlast_i              ;
   // MCU <=> AXIM CONTROL IF [write channel]
   output logic [C_M_AXI_ADDR_WIDTH-1:0] ctrl_waddr_offset_o     ;
   output logic [C_XFER_SIZE_WIDTH-1:0]  ctrl_wxfer_size_o       ;
   output logic 			 ctrl_wstart_o           ;
   input  logic 			 ctrl_wdone_i            ;
   output logic 			 ctrl_wstrb_msk_en_o     ;
   output logic [3 : 0] 		 wr_tstrb_msk_o          ;
   output logic [C_M_AXI_DATA_WIDTH-1:0] wr_tdata_o              ;
   output logic 			 wr_tvalid_o             ;
   input  logic 			 wr_tready_i             ;


   // Scheduler-M_CU interconnections
   logic [31:0] 			 mcu_base_addr;	// From scheduler_inst of scheduler.v
   logic [2:0] 				 mcu_data_width;	// From scheduler_inst of scheduler.v
   logic 				 mcu_idx_ld_st;	// From scheduler_inst of scheduler.v
   logic 				 mcu_ld_vld;		// From scheduler_inst of scheduler.v
   logic 				 mcu_st_vld;		// From scheduler_inst of scheduler.v
   logic [31:0] 			 mcu_stride;		// From scheduler_inst of scheduler.v
   logic 				 mcu_strided_ld_st;	// From scheduler_inst of scheduler.v
   logic 				 mcu_unit_ld_st;	// From scheduler_inst of scheduler.v
   
   // logic 				 mcu_ld_rdy=1'b1;       // ALEKSA HAS CHANGED THIS
   // logic 				 mcu_ld_buffered=1'b1;  // ALEKSA HAS CHANGED THIS
   // logic 				 mcu_st_rdy=1'b1;       // ALEKSA HAS CHANGED THIS

   //Scheduler-V_CU interconnections
   logic [12:0] 			 instr_vld;		// From scheduler_inst of scheduler.v
   logic [31:0] 			 vector_instr;		// From scheduler_inst of scheduler.v
   logic [2:0] 				 sew;
   logic [2:0] 				 lmul;
   logic [12:0] 			 instr_rdy;
   logic [31:0] 			 scalar_rs1;
   logic [31:0] 			 scalar_rs2;

   //renaming_unit-vcu
   logic 				 ru_vrf_starting_addr_vld;
   logic [8*$clog2( MEM_DEPTH)-1:0] 	 ru_vrf_starting_waddr;
   logic [8*$clog2( MEM_DEPTH)-1:0] 	 ru_vrf_starting_raddr0;
   logic [8*$clog2( MEM_DEPTH)-1:0] 	 ru_vrf_starting_raddr1;
   

   // V_CU-Vector_lanes interconnections
   logic [2:0] 				 inst_type;
   logic [W_PORTS_NUM-1:0] 		 start;
   logic [4:0] 				 alu_imm;	// From v_cu_inst of v_cu.v
   logic [ALU_OPMODE_WIDTH-1:0] 	 alu_opmode;// From v_cu_inst of v_cu.v
   logic 				 reduction_op;// From v_cu_inst of v_cu.v
   logic [31:0] 			 alu_x_data;	// From v_cu_inst of v_cu.v
   logic [$clog2(LP_MAX_VL_PER_LANE)-1:0] inst_delay;// From v_cu_inst of v_cu.v
   logic [31:0] 			  vl;
   logic [1:0] 				  op2_sel;	// From v_cu_inst of v_cu.v
   logic [$clog2(R_PORTS_NUM)-1:0] 	  op3_sel;// From v_cu_inst of v_cu.v
   logic [31:0] 			  rs1_o;			// From scheduler_inst of scheduler.v
   logic [2:0] 				  sew_o;			// From v_cu_inst of v_cu.v
   logic [31:0] 			  slide_amount;		// From v_cu_inst of v_cu.v
   logic 				  slide_type;		// From v_cu_inst of v_cu.v

   logic [$clog2(R_PORTS_NUM)-1:0] 	  store_data_mux_sel_i;// From v_cu_inst of v_cu.v
   logic [$clog2(R_PORTS_NUM)-1:0] 	  store_load_index_mux_sel_i;// From v_cu_inst of v_cu.v
   logic 				  up_down_slide;	// From v_cu_inst of v_cu.v
   logic 				  vector_mask;	// From v_cu_inst of v_cu.v
   logic [31:0] 			  vl_o;			// From v_cu_inst of v_cu.v
   logic 				  vrf_oreg_ren;		// From v_cu_inst of v_cu.v
   logic 				  vrf_ren;		// From v_cu_inst of v_cu.v
   logic [8*$clog2( MEM_DEPTH)-1:0] 	  vrf_starting_raddr_vs1;// From v_cu_inst of v_cu.v
   logic [8*$clog2( MEM_DEPTH)-1:0] 	  vrf_starting_raddr_vs2;// From v_cu_inst of v_cu.v
   logic [8*$clog2( MEM_DEPTH)-1:0] 	  vrf_starting_waddr;// From v_cu_inst of v_cu.v
   logic [1:0] 				  wdata_width;		// From v_cu_inst of v_cu.v
   logic [W_PORTS_NUM-1:0] 		  port_group_ready;
   logic [$clog2(R_PORTS_NUM)-1:0] 	  store_data_mux_sel;
   logic [$clog2(R_PORTS_NUM)-1:0] 	  store_load_idx_mux_sel;

   // SHEDULER-MEM_SUBSYS interconnections
   logic [31:0] 			  mcu_store_data[0:VLANE_NUM-1];
   logic [31:0] 			  mcu_store_load_idx  [0:VLANE_NUM-1];
   logic [31:0]	        mcu_load_data[0:VLANE_NUM-1];
   logic [3:0] 				  mcu_load_bwe[0:VLANE_NUM-1];
   // V_LANE-MEM_SUBSYS interconnections

   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0][31:0] vlane_store_data;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0][31:0]	vlane_store_load_idx;
   logic 					vlane_store_rdy; 
   logic [VLANE_NUM-1:0][31:0] 			vlane_load_data;
   
   logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] vlane_store_load_ivalid;
   logic [0:VLANE_NUM-1][3:0] 			vlane_load_bwen;
   logic 					vlane_load_rdy       ;
   logic 					vlane_load_last      ;
   logic 					vlane_load_dvalid    ;
   logic [1:0] 					vlane_store_driver;
   logic [1:0] 					vlane_store_driver_reg;
   logic [1:0] 					vlane_idx_driver_reg;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0] 	vlane_store_dvalid;
   logic 	              			vlane_mcu_store_dvalid;
   logic 	              			vlane_mcu_idx_ivalid;
   
   // End of automatics
   /*INSTANTIATE SCHEDULER*/
   scheduler scheduler_inst
     (/*AUTO_INST*/
      // Outputs
      .vector_stall_o			(vector_stall_o),
      .instr_vld_o			(instr_vld[12:0]),
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
      .instr_vld_i	(instr_vld),
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
	     .store_driver_o            (vlane_store_driver),
	     .inst_type_o		(inst_type[2:0]),
	     .start_o			(start[W_PORTS_NUM-1:0]),
	     .inst_delay_o		(inst_delay/*[W_PORTS_NUM-1:0][$clog2(LP_MAX_VL_PER_LANE)-1:0]*/),
	     .vrf_ren_o			(vrf_ren),
	     .vrf_oreg_ren_o		(vrf_oreg_ren),
	     .vrf_starting_waddr_o	(vrf_starting_waddr[8*$clog2( MEM_DEPTH)-1:0]),
	     .vrf_starting_raddr_vs1_o	(vrf_starting_raddr_vs1[8*$clog2( MEM_DEPTH)-1:0]),
	     .vrf_starting_raddr_vs2_o	(vrf_starting_raddr_vs2[8*$clog2( MEM_DEPTH)-1:0]),
	     .wdata_width_o		(wdata_width[1:0]),
	     .store_data_mux_sel_o	(store_data_mux_sel[$clog2(R_PORTS_NUM)-1:0]),
	     .store_load_index_mux_sel_o(store_load_idx_mux_sel[$clog2(R_PORTS_NUM)-1:0]),
	     .op2_sel_o			(op2_sel/*[W_PORTS_NUM-1:0][1:0]*/),
	     .op3_sel_o			(op3_sel/*[W_PORTS_NUM-1:0][$clog2(R_PORTS_NUM)-1:0]*/),
	     .alu_x_data_o		(alu_x_data/*[W_PORTS_NUM-1:0][31:0]*/),
	     .alu_imm_o			(alu_imm/*[W_PORTS_NUM-1:0][4:0]*/),
	     .alu_opmode_o		(alu_opmode/*[W_PORTS_NUM-1:0][ALU_OPMODE_WIDTH-1:0]*/),
	     .reduction_op_o            (reduction_op),
	     .up_down_slide_o		(up_down_slide),
	     .slide_amount_o		(slide_amount[31:0]),
	     .slide_type_o              (slide_type),
	     .vector_mask_o		(vector_mask),
	     
	     // Inputs
	     .clk			(clk),
	     .rstn			(rstn),
	     .instr_vld_i		(instr_vld[12:0]),
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
      . MEM_DEPTH			( MEM_DEPTH),
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
      .ready_for_load_o			    (vlane_load_rdy),
      .store_data_o			        (vlane_store_data),
      .store_load_index_o		    (vlane_store_load_idx),
      .store_data_valid_o		    (vlane_store_dvalid),
      // TODO: rename store_load_index_valid to load index valid - as store_data_valid should be for both index and data
      .store_load_index_valid_o	(vlane_store_load_ivalid),
      .load_valid_i			        (vlane_load_dvalid),
      .load_last_i			        (vlane_load_last),
      .load_data_i			        (vlane_load_data),
      // TODO: MISSING byte-write_enable signal for loads
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
      .load_bwen_i                      (vlane_load_bwen),
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
      .slide_type_i			(slide_type),
      .slide_amount_i			(slide_amount[31:0]),
      .vector_mask_i			(vector_mask),
      .read_port_allocation_i		(read_port_allocation/*[R_PORTS_NUM-1:0][$clog2(W_PORTS_NUM)-1:0]*/), // TODO: what is this
      .primary_read_data_i		(8'hff));//TODO: what is this


   always @(posedge clk)
   begin
      if (!rstn)
      begin
	 vlane_store_driver_reg <= 'h0;
	 vlane_idx_driver_reg <= 'h0;
      end
      else
      begin
      
	 if (!vlane_mcu_store_dvalid)
	   vlane_store_driver_reg <= vlane_store_driver;
	 
	 if(!vlane_mcu_idx_ivalid)
	   vlane_idx_driver_reg <= vlane_store_driver;
      end
   end
   
   always_comb
   begin
      for (int i=0; i<VLANE_NUM; i++)
      begin
	 mcu_store_data[i] = vlane_store_data[i][vlane_store_driver_reg];
	 mcu_store_load_idx[i] = vlane_store_load_idx[i][vlane_idx_driver_reg];
	 vlane_load_data[i] = mcu_load_data[i];
	 vlane_load_bwen[i] = mcu_load_bwe[i];
      end       
   end

   always_comb
   begin
      for (int i=0;i<VLANE_NUM;i++)
      begin
	 if (vlane_store_dvalid[i][vlane_store_driver_reg] == 1'b0)
	   vlane_mcu_store_dvalid = 1'b0;
	 else
	   vlane_mcu_store_dvalid = 1'b1;
      end
   end
   
   // For indices of indexed loads and stores
   always_comb
   begin
      for(int i=0;i<VLANE_NUM;i++) begin
         if (vlane_store_load_ivalid[i][vlane_idx_driver_reg] == 1'b0)
           vlane_mcu_idx_ivalid = 1'b0;
         else
           vlane_mcu_idx_ivalid = 1'b1;
      end
   end

   // Instantiate MEM_SUBSYS
   mem_subsys #(
		.VLEN               (VLEN                 ),
		.VLANE_NUM         (VLANE_NUM            ),
		.MAX_VECTORS_BUFFD  (1), // FIXED, not implemented yet
		.C_M_AXI_ADDR_WIDTH (C_M_AXI_ADDR_WIDTH   ),
		.C_M_AXI_DATA_WIDTH (C_M_AXI_DATA_WIDTH   ),
		.C_XFER_SIZE_WIDTH  (C_XFER_SIZE_WIDTH    )
		)mem_subsys_inst
     (
      .clk                  (clk                 ),
      .rstn                 (rstn                ),
      .mcu_sew_i            (sew                 ),
      .mcu_lmul_i           (lmul                ),
      .mcu_vl_i             (vl                  ),
      .mcu_base_addr_i      (mcu_base_addr       ),
      .mcu_stride_i         (mcu_stride          ),
      .mcu_data_width_i     (mcu_data_width      ),
      .mcu_idx_ld_st_i      (mcu_idx_ld_st       ),
      .mcu_strided_ld_st_i  (mcu_strided_ld_st   ),
      .mcu_unit_ld_st_i     (mcu_unit_ld_st      ),
      .mcu_st_rdy_o         (mcu_st_rdy          ),
      .mcu_st_vld_i         (mcu_st_vld          ),
      .mcu_ld_rdy_o         (mcu_ld_rdy          ),
      .mcu_ld_buffered_o    (mcu_ld_buffered     ),
      .mcu_ld_vld_i         (mcu_ld_vld          ),
      .ctrl_raddr_offset_o  (ctrl_raddr_offset_o ),
      .ctrl_rxfer_size_o    (ctrl_rxfer_size_o   ),
      .ctrl_rstart_o        (ctrl_rstart_o       ),
      .ctrl_rdone_i         (ctrl_rdone_i        ),
      .rd_tdata_i           (rd_tdata_i          ),
      .rd_tvalid_i          (rd_tvalid_i         ),
      .rd_tready_o          (rd_tready_o         ),
      .rd_tlast_i           (rd_tlast_i          ),
      .ctrl_waddr_offset_o  (ctrl_waddr_offset_o ),
      .ctrl_wxfer_size_o    (ctrl_wxfer_size_o   ),
      .ctrl_wstart_o        (ctrl_wstart_o       ),
      .ctrl_wdone_i         (ctrl_wdone_i        ),
      .ctrl_wstrb_msk_en_o  (ctrl_wstrb_msk_en_o ),
      .wr_tdata_o           (wr_tdata_o          ),
      .wr_tvalid_o          (wr_tvalid_o         ),
      .wr_tready_i          (wr_tready_i         ),
      .wr_tstrb_msk_o       (wr_tstrb_msk_o),
      .vlane_store_data_i   (mcu_store_data      ),
      .vlane_store_idx_i    (mcu_store_load_idx  ),
      .vlane_store_dvalid_i (vlane_mcu_store_dvalid),
      .vlane_store_ivalid_i (vlane_mcu_idx_ivalid),
      .vlane_store_rdy_o    (vlane_store_rdy     ),
      .vlane_load_data_o    (mcu_load_data     ),
      .vlane_load_bwe_o     (mcu_load_bwe      ),
      .vlane_load_idx_i     (mcu_store_load_idx),
      .vlane_load_rdy_i     (vlane_load_rdy      ),
      .vlane_load_ivalid_i  (vlane_mcu_idx_ivalid),
      .vlane_load_dvalid_o  (vlane_load_dvalid   ),
      .vlane_load_last_o    (vlane_load_last     )
      );

   //
endmodule

// Local Variables:
// verilog-library-extensions:(".v" ".sv" "_stub.v" "_bb.v")
// verilog-library-directories:("." "../../common/" "../scheduler/rtl/" "../v_cu/rtl/")
// End:
