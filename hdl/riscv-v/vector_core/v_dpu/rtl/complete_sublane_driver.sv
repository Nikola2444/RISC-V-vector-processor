module complete_sublane_driver
  #(
    parameter MEM_DEPTH = 512,
    parameter MAX_VL_PER_LANE = 4 * 8 * 8,                                      // The biggest number of elements in one lane
    parameter VREG_LOC_PER_LANE = 8,                                            // The number of memory locations reserved for one vector register
    parameter R_PORTS_NUM = 8,
    parameter INST_TYPE_NUM = 7,
    parameter VLANE_NUM = 8,
    parameter ALU_OPMODE = 6
    )
   (
    // Clock and Reset
    input 							clk_i,
    input 							rst_i,
   
    // General signals
    input logic [$clog2(VLANE_NUM * MAX_VL_PER_LANE) - 1 : 0] 	vl_i, // per lane: vl_i / 8 + !(vl_i % 8 == 0)
    input logic [1 : 0] 					vsew_i,
    output logic [1 : 0] 					vsew_o,//reg
    output logic [1 : 0] 					vrf_write_sew_o,//reg
    input logic [2 : 0] 					vlmul_i, // NEW SIGNAL
   
    // Control Flow signals
    input logic [$clog2(INST_TYPE_NUM) - 1 : 0] 		inst_type_i, // 0 - normal, 1 - reduction, 2 - load, ...
   
    // Handshaking
    input 							start_i,
    output logic 						ready_o,//reg
   
    // Inst timing signals
    input logic [$clog2(MAX_VL_PER_LANE) - 1 : 0] 		inst_delay_i,
   
    // Signals for read data valid logic
    output logic [VLANE_NUM - 1 : 0] 				read_data_valid_o,//reg
   
    // VRF
    input logic 						vrf_ren_i, // unknown behaviour 
    input logic 						vrf_oreg_ren_i, // unknown behaviour
    input logic [8 * $clog2(MEM_DEPTH) - 1 : 0] 		vrf_starting_waddr_i,
    input logic [2 : 0][8 * $clog2(MEM_DEPTH) - 1 : 0] 		vrf_starting_raddr_i, // UPDATED
    input logic [1 : 0] 					vrf_write_sew_i, // 1 - byte, 2 - halfword, 3 - word
    output logic 						vrf_ren_o,//reg
    output logic 						vrf_oreg_ren_o,//reg
    output logic [VLANE_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_waddr_o,//reg
    output logic [2 : 0][$clog2(MEM_DEPTH) - 1 : 0] 		vrf_raddr_o, //reg UPDATED, 0 - vs1, 1 - vs2, 2 - vs3(only for three operands)  
    output logic [VLANE_NUM - 1 : 0][3 : 0] 			vrf_bwen_o,//not reg but ok
   
    // VMRF
    output logic [$clog2(MAX_VL_PER_LANE) - 1 : 0] 		vmrf_addr_o, //reg
    output logic 						vmrf_wen_o,//not reg
   
    // Load and Store
    input logic 						load_valid_i, 
    input logic 						load_last_i, 
    output logic 						ready_for_load_o, // not reg
    input logic [VLANE_NUM - 1 : 0][3 : 0] 			load_bwen_i, 
   
    input logic [$clog2(R_PORTS_NUM) - 1 : 0] 			store_data_mux_sel_i,
    input logic [$clog2(R_PORTS_NUM) - 1 : 0] 			store_load_index_mux_sel_i,
    output logic 						store_data_valid_o,//reg
    output logic 						store_load_index_valid_o,//reg
    output logic [$clog2(R_PORTS_NUM) - 1 : 0] 			store_data_mux_sel_o,//reg
    output logic [$clog2(R_PORTS_NUM) - 1 : 0] 			store_load_index_mux_sel_o,//reg
   
    // Signals for reductions
    input logic [VLANE_NUM - 2 : 0][31 : 0] 			lane_result_i,
   
    // ALU
    input logic [1 : 0] 					op2_sel_i,
    input logic [$clog2(R_PORTS_NUM) - 1 : 0] 			op3_sel_i, // Determined by port allocation
    input logic [31 : 0] 					ALU_x_data_i,
    input logic [4 : 0] 					ALU_imm_i,
    input logic [ALU_OPMODE - 1 : 0] 				ALU_opmode_i,
    input logic 						reduction_op_i,
    output logic [1 : 0] 					op2_sel_o,// not reg but seems ok
    output logic [$clog2(R_PORTS_NUM) - 1 : 0] 			op3_sel_o,//reg
    output logic [31 : 0] 					ALU_x_data_o,//reg
    output logic [4 : 0] 					ALU_imm_o,//reg
    output logic [31 : 0] 					ALU_reduction_data_o,//not reg but ok
    output logic [ALU_OPMODE - 1 : 0] 				ALU_ctrl_o,//reg
    output logic 						reduction_op_o, // reg
    input logic 						alu_en_32bit_mul_i, // NEW SIGNAL
    output logic 						alu_en_32bit_mul_o, 
   
    // Slides
    //input logic slide_type_i,
    input logic 						up_down_slide_i, // 0 for down, 1 for up
    input logic [31 : 0] 					slide_amount_i,
    output logic [$clog2(VLANE_NUM)-1:0] 			slide_data_mux_sel_o,//reg
    output logic 						up_down_slide_o,//reg
    output logic [1:0] 						vrf_read_sew_o,//reg
    output logic 						request_write_control_o, //not_reg but ok- 0 - ALU generates valid signal, 1 - only bwen_reg is important 
    // Misc signals
    input 							vector_mask_i,
    output logic [1:0][1:0] 					vrf_read_byte_sel_o,//not reg
    output logic 						vector_mask_o,//reg
    output logic [1 : 0] 					vrf_write_mux_sel_o//reg
   
    );

   ////////////////////////////LOCAL PARAMETERS///////////////////////////////////
     // Useful parameters //
   localparam LP_FAST_SLIDE = 1;
   localparam LP_SLOW_SLIDE = 1;
   localparam LP_SKIP_NONE = 0;
   localparam LP_SKIP_1 = 1;
   localparam LP_SKIP_2 = 2;
   localparam LP_SKIP_3 = 3;
   localparam LP_SKIP_ALL = 4;
   localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] 		NORMAL = 0;
   localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] 		REDUCTION = 1;
   localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] 		STORE = 2;
   localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] 		INDEXED_STORE = 3;
   localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] 		LOAD = 4;
   localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] 		INDEXED_LOAD = 5;
   //localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] SLIDE_CHECK = 6;
   localparam logic [$clog2(MAX_VL_PER_LANE) : 0] 		REDUCTION_MODE_LIMIT = VLANE_NUM - 2;
   localparam VECTOR_LENGTH = VLANE_NUM * MAX_VL_PER_LANE; 
   localparam VRF_DELAY = 4;
   localparam SLIDE_BUFFER_DELAY = VRF_DELAY - 1;
   /////////////////////////////////////////////////////////////////////////////////

   /////////////////////////////////////////////////////////////////////////////////
   // FSM - declaration //
   localparam STATES_NUM = 8;

   ////////////////////////////SIGNAL DECLARATIONS///////////////////////////////////
   typedef enum logic [$clog2(STATES_NUM) - 1 : 0] {IDLE, NORMAL_MODE, READ_MODE, LOAD_MODE, REDUCTION_MODE, REDUCTION_WRITE_MODE,
						    SLIDE_OFFLANE_MOVE, SLIDE} fsm_state;
   fsm_state current_state, next_state;
   /////////////////////////////////////////////////////////////////////////////////

   /////////////////////////////////////////////////////////////////////////////////
   // Registers - declaration //
   typedef struct packed { 
      logic [$clog2(MAX_VL_PER_LANE) - 1 : 0] 	inst_delay;
      logic 					vrf_ren;
      logic 					vrf_oreg_ren;
      logic [1 : 0] 				vrf_write_sew;
      logic [$clog2(INST_TYPE_NUM) - 1 : 0] 	inst_type; 
      logic 					vmrf_wen;
      logic 					en_write;
      logic 					waddr_cnt_en;
      logic 					vmrf_cnt_en;
      logic 					bwen_en;
      logic 					start;
      logic [$clog2(R_PORTS_NUM) - 1 : 0] 	store_data_mux_sel;
      logic [$clog2(R_PORTS_NUM) - 1 : 0] 	store_load_index_mux_sel;
      logic 					store_data_valid;
      logic 					store_load_index_valid;
      logic [$clog2(MAX_VL_PER_LANE) - 1 : 0] 	read_limit;
      logic [1 : 0] 				op2_sel;
      logic [$clog2(R_PORTS_NUM) - 1 : 0] 		op3_sel;
      logic [31 : 0] 				ALU_x_data;
      logic [4 : 0] 				ALU_imm;
      logic 					vector_mask;
      logic [1 : 0] 				vrf_write_mux_sel;
      logic [8 * $clog2(MEM_DEPTH) - 1 : 0] 	vrf_starting_waddr;
      logic [2 : 0][8 * $clog2(MEM_DEPTH) - 1 : 0] vrf_starting_raddr;
      logic [ALU_OPMODE - 1 : 0] 		ALU_opmode;
      logic 					up_down_slide;
      logic [31 : 0] 				slide_amount;



      logic [1 : 0] 				input_sel;
      logic [1 : 0] 				adder_input_sel; 
      logic 					en_comp;
      logic 					delay_addr;
      logic 					reverse_bwen;
      logic 					slide_enable_buffering; // 1 - buffering enabled, 0 - for disabled
      logic 					start_decrementor;
      logic 					reduction_op;
      logic [31-$clog2(VLANE_NUM):0] 		slide_waddr_offset; 
      
      // 1-cycle delayed data for slides

      logic [1:0]        			vrf_read_sew;
      // 32-bit multiply
      logic 					alu_en_32bit_mul;
      logic [1 : 0] 				sew;
      logic [2 : 0] 				lmul;
      logic [31 : 0] 				vl;
      
   } dataPacket0;

   dataPacket0 dp0_reg, dp0_next;
   logic 					       waddr_cnt_en;
   logic 					       waddr_out_reg_en;
   // bwen_reg //
   logic [3 : 0] 				       shift4_reg, shift4_next;
   logic [1 : 0] 				       shift2_reg, shift2_next;
   // main counter //
   logic [$clog2(MAX_VL_PER_LANE) : 0] 		       main_cnt;
   logic 					       main_cnt_en;
   logic 					       rst_main_cnt;
   logic [$clog2(MAX_VL_PER_LANE) : 0] 		       main_cnt_limit;
   // Write address generation //


   // VMRF //
   logic [$clog2(MAX_VL_PER_LANE) - 1 : 0] 	       vmrf_cnt;
   logic 					       rst_vmrf_cnt;
   // logic for read_limit //
   logic [$clog2(VLANE_NUM * MAX_VL_PER_LANE) - 1 : 0] read_limit_add;
   logic 					       read_limit_carry;
   logic 					       read_limit_comp;
   // signals for reductions //
   logic [31 : 0] 				       reduction_mux;
   // signals for read data validation //
   logic 					       load_data_validation;
   logic 					       shift_data_validation;
   logic [VLANE_NUM - 1 : 0] 			       read_data_valid, read_data_valid_slide, read_data_valid_dv;
   logic 					       partial_results_valid;
   logic [VLANE_NUM-1:0][2:0] 			       first_elements_to_skip; 
   logic 					       shift_partial;
   logic [31-$clog2(VLANE_NUM*4):0] 		       slide_waddr_offset; 
   // signals for slides //
   logic [VLANE_NUM - 1 : 0] 			       valid_data;
   logic [VLANE_NUM - 1 : 0] 			       slide_write_data_pattern;
   logic 					       enable_write_slide;

   /////////////////////////////////////////////////////////////////////////////////

   /////////////////////////////////////////////////////////////////////////////////
   // Additional signals - declaration //
   // bwen_reg //
   logic [3:0] slide_bwen_skip1_reg;
   logic [3:0] slide_bwen_skip2_reg;
   logic [3:0] slide_bwen_skip3_reg;
   logic [VLANE_NUM - 1 : 0][3 : 0] 			bwen_reg;
   logic [3 : 0] 					bwen_mux;
   logic [VLANE_NUM - 1 : 0][3 : 0] 			slide_bwen, normal_bwen;
   logic 						secondary_bwen_en;

   // address counter //
   logic 						waddr_load;
   logic 						waddr_cnt_rst;
   logic 						raddr_cnt_en;
   logic 						raddr_load;
   logic 						raddr_cnt_rst;
   logic [$clog2(MEM_DEPTH) - 1 : 0] 			waddr;
   logic [2 : 0][$clog2(MEM_DEPTH) - 1 : 0] 		raddr;
   logic 						wsecondary_en;
   logic [VLANE_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] slide_waddr, normal_waddr, slide_down_waddr;

   // comparators
   logic [6 : 0] 					inst_type_comp;


   ////////////////////////////END OF DECLARATIONS///////////////////////////////////

   /////////////////////////////////////////////////////////////////////////////////
   
   assign read_limit_carry = (dp0_reg.vl[$clog2(VLANE_NUM) - 1 : 0] == 0);
   assign read_limit_add = dp0_reg.inst_type == 6 ? ((dp0_reg.vl << dp0_reg.sew) >> $clog2(VLANE_NUM)) + !read_limit_carry : (dp0_reg.vl >> $clog2(VLANE_NUM)) + !read_limit_carry;
   assign read_limit_comp = (main_cnt == dp0_reg.read_limit - 1);
   
   assign read_data_valid[VLANE_NUM - 1 : 1] = read_data_valid_dv[VLANE_NUM - 1 : 1];//valid for all lanes except lane 0
   assign read_data_valid_slide = valid_data;

   assign main_cnt_limit = dp0_reg.inst_delay + dp0_reg.read_limit;

   ////////////////////////////SLIDE LOGIC///////////////////////////////////
   // For some instruction, like slide, depending on the slide amount lanes should skip some of the elements
   always@(posedge clk_i)
   begin
      if (!rst_i)
      begin
	 first_elements_to_skip <= '{default:'0};
      end
      else
      begin
	 for (int lane=0; lane<VLANE_NUM; lane++)
	 begin
	    if (dp0_reg.up_down_slide)
	      first_elements_to_skip[lane] <= dp0_reg.slide_amount[$clog2(VLANE_NUM*4)-1:0] <= lane ? LP_SKIP_NONE:
					      dp0_reg.slide_amount[$clog2(VLANE_NUM*4)-1:0] <= VLANE_NUM+lane ? LP_SKIP_1 :
					      dp0_reg.slide_amount[$clog2(VLANE_NUM*4)-1:0] <= 2*VLANE_NUM+lane ? LP_SKIP_2 :
					      dp0_reg.slide_amount[$clog2(VLANE_NUM*4)-1:0] <= 3*VLANE_NUM+lane ? LP_SKIP_3 : LP_SKIP_ALL;
	    else
	      first_elements_to_skip[lane] <= dp0_reg.slide_amount[$clog2(VLANE_NUM*4)-1:0] <= VLANE_NUM-1-lane ? LP_SKIP_NONE:
					      dp0_reg.slide_amount[$clog2(VLANE_NUM*4)-1:0] <= 2*VLANE_NUM-1-lane ? LP_SKIP_1 :
					      dp0_reg.slide_amount[$clog2(VLANE_NUM*4)-1:0] <= 3*VLANE_NUM-1-lane ? LP_SKIP_2 :
					      dp0_reg.slide_amount[$clog2(VLANE_NUM*4)-1:0] <= 4*VLANE_NUM-1-lane ? LP_SKIP_3 : LP_SKIP_ALL;
	    
	 end
      end
   end
   
   ////////////////////BWEN and WADDRESS GENERATION////////////////////////////////////////////

   always_ff@(posedge clk_i) begin
      if(!rst_i) begin
         shift4_reg <= 4'b0001;
         shift2_reg <= 2'b01;
      end
      else begin
         if(dp0_next.bwen_en) begin
            shift4_reg <= {shift4_reg[2 : 0], shift4_reg[3]};
            shift2_reg <= {shift2_reg[0], shift2_reg[1]};
         end
         else begin
            shift4_reg <= 4'b0001;
            shift2_reg <= 2'b01;
         end 
      end
   end

   logic [3 : 0] wen_byte_select;
   always_comb begin       
      shift4_next = 4'b0001;
      shift2_next = 2'b01;
      case(dp0_reg.vrf_write_sew)
	 2'b00: wen_byte_select = shift4_reg;
	 2'b01: wen_byte_select = {{2{shift2_reg[1]}}, {2{shift2_reg[0]}}};
	 2'b10: wen_byte_select = {{4{1'b1}}};
	 default: wen_byte_select = {{4{1'b0}}};
      endcase // case (dp0_reg.vrf_write_sew+1)
   end

   /////////////////////////////////////////////////////////////////////////////////
   // slide_bwen assigment //
   always_ff@(posedge clk_i) begin
      if(!rst_i) begin
	 slide_bwen_skip1_reg <= 4'b0010;
	 slide_bwen_skip2_reg <= 4'b0100;
	 slide_bwen_skip3_reg <= 4'b1000;
      end
      else begin
         if(dp0_next.bwen_en) begin	   
            slide_bwen_skip1_reg <= {slide_bwen_skip1_reg[2 : 0], slide_bwen_skip1_reg[3]};
            slide_bwen_skip2_reg <= {slide_bwen_skip2_reg[2 : 0], slide_bwen_skip2_reg[3]};
            slide_bwen_skip3_reg <= {slide_bwen_skip3_reg[2 : 0], slide_bwen_skip3_reg[3]};
         end
         else 
	 begin
	    slide_bwen_skip1_reg <= 4'b0010;
	    slide_bwen_skip2_reg <= 4'b0100;
	    slide_bwen_skip3_reg <= 4'b1000;
	 end	
	 if (main_cnt >= dp0_reg.read_limit)
	 begin
	    slide_bwen_skip1_reg[0] <= 1'b0;
	    slide_bwen_skip2_reg[1:0] <= 2'b00;
	    slide_bwen_skip3_reg[2:0] <= 3'b000;
	 end
      end
   end

   logic [$clog2(MEM_DEPTH) - 1 : 0] incr_decr;
   assign incr_decr = dp0_reg.up_down_slide ? 1 : -1;
   generate
      for(genvar i = 0; i < VLANE_NUM; i++) begin
         assign slide_bwen[i] = (first_elements_to_skip[i] == 1) ? (slide_bwen_skip1_reg & {4{dp0_next.bwen_en}}):
				(first_elements_to_skip[i] == 2) ? (slide_bwen_skip2_reg & {4{dp0_next.bwen_en}}):
				(first_elements_to_skip[i] == 3) ? (slide_bwen_skip3_reg & {4{dp0_next.bwen_en}}) : wen_byte_select;


         assign slide_waddr[i] = (first_elements_to_skip[i]==1 && slide_bwen_skip1_reg[0]) ? waddr+incr_decr : 
				 (first_elements_to_skip[i]==2 && (slide_bwen_skip2_reg[0] || slide_bwen_skip2_reg[1])) ? waddr+incr_decr : 
				 (first_elements_to_skip[i]==3 && (slide_bwen_skip3_reg[0] || slide_bwen_skip3_reg[1] || slide_bwen_skip3_reg[2])) ? waddr+incr_decr :
				 (first_elements_to_skip[i]==4) ? waddr+incr_decr : waddr;
         
         assign normal_waddr[i] = waddr; 
      end
   endgenerate;

   //bwen register  
   always@(posedge clk_i) begin
      if (!rst_i || !dp0_next.en_write)
      begin
	 bwen_reg <= '{default:'0};
      end
      else
      begin
	 if(current_state == REDUCTION_WRITE_MODE) 
	 begin
            for(int i = 4; i < VLANE_NUM; i++) begin
               bwen_reg[i] <= 0;
            end       
	    bwen_reg[1] <= 0;
	    bwen_reg[2] <= 0;
	    bwen_reg[3] <= 0;
	    bwen_reg[0] <= {3'b0, wen_byte_select[0]};
	    if (dp0_reg.sew==2'b01)
	      bwen_reg[1] <= {3'b0, wen_byte_select[0]};
	    else if (dp0_reg.sew==2'b10)
	    begin
	       bwen_reg[1] <= {3'b0, wen_byte_select[0]};
	       bwen_reg[2] <= {3'b0, wen_byte_select[0]};
	       bwen_reg[3] <= {3'b0, wen_byte_select[0]};
	    end
	 end
	 else if (current_state == SLIDE)
	 begin
	    for (int i=0; i<VLANE_NUM;i++)
	    begin
	       if (dp0_reg.up_down_slide)
		 bwen_reg[i] = slide_bwen[i];
	       else
		 bwen_reg[i] = {slide_bwen[i][0], slide_bwen[i][1], slide_bwen[i][2], slide_bwen[i][3]};
	    end
	 end
	 else
	 begin
            for(int i = 0; i < VLANE_NUM; i++) begin
	       bwen_reg[i] <= wen_byte_select;
            end
	 end
      end
   end
   /////////////////////////////////////////////////////////////////////////////////

   /////////////////////////////////////////////////////////////////////////////////
   // Main counter and vmrf counter //
   assign  rst_main_cnt = (next_state==IDLE && current_state!=IDLE) || 
			  (current_state==READ_MODE && next_state==REDUCTION_MODE) ||
			  (current_state==REDUCTION_MODE && next_state==REDUCTION_WRITE_MODE);
   assign  rst_vmrf_cnt = next_state==IDLE && current_state!=IDLE;
   always_ff@(posedge clk_i) begin
      if(!rst_i) begin
         main_cnt <= 0;
         vmrf_cnt <= 0;
      end
      else begin
         if(rst_main_cnt) begin
            main_cnt <= 0;
         end
         else begin
            if(main_cnt_en) begin
               main_cnt <= main_cnt + 1;
            end;
         end
         if(rst_vmrf_cnt) begin
            vmrf_cnt <= 0;
         end
         else begin
            if(dp0_reg.vmrf_cnt_en) begin
               vmrf_cnt <= vmrf_cnt + 1;
            end;
         end
      end
   end

   /////////////////////////////////////////////////////////////////////////////////
   // Signal selection for reductions - implementation ///
   
   /////////////////////////////////////////////////////////////////////////////////


   /////////////////////////////////////////////////////////////////////////////////
   // General registers - implementation //
   always_ff@(posedge clk_i) begin
      if(!rst_i) begin
         dp0_reg <= 0;
         dp0_reg.vrf_write_sew <= 2'b11;
      end
      else begin
         dp0_reg <= dp0_next;         
      end      
   end
   /////////////////////////////////////////////////////////////////////////////////
	// Address counters - instantiation //
	 
   //If slide offset waddt
   assign slide_waddr_offset = dp0_reg.up_down_slide && dp0_reg.inst_type == 6 ? dp0_reg.slide_amount[31 : $clog2(VLANE_NUM*4)] :
			       !dp0_reg.up_down_slide && dp0_reg.inst_type == 6 ? dp0_reg.slide_amount[31 : $clog2(VLANE_NUM*4)] : 'h0;

   assign raddr_cnt_rst = next_state==IDLE && current_state!=IDLE;
   assign waddr_cnt_rst = next_state==IDLE && current_state!=IDLE;

   address_counter
     #(
       .MEM_DEPTH(MEM_DEPTH),
       .VREG_LOC_PER_LANE(VREG_LOC_PER_LANE),
       .VLANE_NUM(VLANE_NUM),
       .STRIDE_ENABLE("YES")
       )
   waddr_cnt
     (
      .clk_i(clk_i),
      .rst_i(rst_i),
      .slide_offset_i(slide_waddr_offset),
      .start_addr_i(vrf_starting_waddr_i),
      .load_i(waddr_load),
      .up_down_i(dp0_reg.up_down_slide),
      .element_width_i(dp0_reg.vrf_write_sew),
      .rst_cnt_i(waddr_cnt_rst),
      .en_i(waddr_cnt_en),
      .secondary_en_i(1'b1),
      .addr_o(waddr)
      );

   generate
      for(genvar i = 0; i < 3; i++) begin
         address_counter
		     #(
		       .MEM_DEPTH(MEM_DEPTH),
		       .VREG_LOC_PER_LANE(VREG_LOC_PER_LANE),
		       .VLANE_NUM(VLANE_NUM),
		       .STRIDE_ENABLE("YES")
		       )
         raddr_cnt
		     (
		      .clk_i(clk_i),
		      .rst_i(rst_i),
		      .slide_offset_i('h0),
		      .start_addr_i(vrf_starting_raddr_i[i]),
		      .load_i(raddr_load),
		      .up_down_i(dp0_reg.up_down_slide),
		      .element_width_i(2'(dp0_reg.vrf_read_sew)),
		      .rst_cnt_i(raddr_cnt_rst),
		      .en_i(raddr_cnt_en),
		      .secondary_en_i(1'b1),
		      .addr_o(raddr[i])
		      );
      end
   endgenerate;
   /////////////////////////////////////////////////////////////////////////////////

   /////////////////////////////////////////////////////////////////////////////////
   data_validation
     #(
       .MAX_VL_PER_LANE(MAX_VL_PER_LANE),
       .VLANE_NUM(VLANE_NUM)
       )
   data_validation_inst
     (
      .clk_i(clk_i),
      .rst_i(rst_i),
      
      .vl_i(dp0_next.vl),
      .shift_en_i(shift_data_validation),
      .shift_partial_i(shift_partial),
      .load_i(load_data_validation),
      
      .valid_o(read_data_valid_dv),
      .partial_results_valid_o(partial_results_valid)
      );
   /////////////////////////////////////////////////////////////////////////////////

   /////////////////////////////////////////////////////////////////////////////////
   // Comparators - implementations //
   generate
      for(genvar i = 0; i < INST_TYPE_NUM; i++) begin
         assign inst_type_comp[i] = (dp0_reg.inst_type == i) ? 1 : 0;
      end
   endgenerate;
   /////////////////////////////////////////////////////////////////////////////////

   /////////////////////////////////////////////////////////////////////////////////
   // FSM //
   always_ff@(posedge clk_i) begin
      if(!rst_i) begin
         current_state <= IDLE;
      end
      else begin
         current_state <= next_state;
      end
   end

   

   always_comb begin
      // main counter control signals

      main_cnt_en 	      = 0;
      // VMRF counter control signals
      
      // write address generator control signals
      waddr_load 	      = 0;
      wsecondary_en 	      = 1;
      waddr_out_reg_en 	      = 0;
      // read address generator control signals
      raddr_load 	      = 0;      
      raddr_cnt_en 	      = 0;
      // handshaking signals
      //ready_o = 0;
      // read data validation
      shift_data_validation   = 0;
      load_data_validation    = 0; 
      shift_partial 	      = 0;
      read_data_valid[0]      = read_data_valid_dv[0];
      request_write_control_o = 1'b0;
      ready_for_load_o 	      = 0;
      waddr_cnt_en 	      = 0;
      dp0_next 		      = dp0_reg;
      dp0_next.store_data_valid = 0;
      next_state 	      = current_state;

      case(current_state)
         IDLE : begin
            
            dp0_next.read_limit  = read_limit_add;
            
            if (start_i)
	    begin
	       //load start addresses into read and write counters
	       load_data_validation = 1;
	       raddr_load 			 = 1;
	       waddr_load 			 = 1;
	       //register other input signals
               dp0_next.inst_delay 		 = inst_delay_i;
	       dp0_next.slide_waddr_offset 	 = slide_waddr_offset;
               dp0_next.vrf_write_sew 		 = vrf_write_sew_i;
	       dp0_next.vrf_ren 		 = vrf_ren_i;
	       dp0_next.vrf_oreg_ren 		 = vrf_ren_i;	       
               dp0_next.inst_type 		 = inst_type_i;
               dp0_next.en_write 		 = 0;

               dp0_next.vmrf_cnt_en 		 = 0;
               dp0_next.bwen_en 		 = 0;
               dp0_next.op2_sel 		 = op2_sel_i;
               dp0_next.op3_sel 		 = op3_sel_i;
               dp0_next.ALU_x_data 		 = ALU_x_data_i;
               dp0_next.ALU_imm 		 = ALU_imm_i;
               dp0_next.start 			 = start_i;
               dp0_next.store_load_index_mux_sel = store_load_index_mux_sel_i;
               dp0_next.store_data_mux_sel 	 = store_data_mux_sel_i;

               dp0_next.vrf_write_mux_sel 	 = 0;
               dp0_next.vector_mask 		 = vector_mask_i;
               dp0_next.ALU_opmode 		 = ALU_opmode_i;
               dp0_next.reduction_op 		 = reduction_op_i;
               dp0_next.vmrf_wen 		 = 0;
               dp0_next.alu_en_32bit_mul 	 = alu_en_32bit_mul_i;
               dp0_next.sew 			 = vsew_i[1 : 0];
	       dp0_next.vrf_read_sew 		 = vsew_i[1:0];
               dp0_next.lmul 			 = vlmul_i[2 : 0];
               dp0_next.vl 			 = vl_i;
               // slides
               dp0_next.up_down_slide 		 = up_down_slide_i;
               dp0_next.slide_amount 		 = slide_amount_i;

               dp0_next.adder_input_sel 	 = (up_down_slide_i == 1) ? 2'b01 : 2'b00;
               dp0_next.en_comp 		 = 0;
               dp0_next.delay_addr 		 = 0;
               dp0_next.input_sel 		 = 2'b11;
               dp0_next.reverse_bwen 		 = !up_down_slide_i;
               dp0_next.slide_enable_buffering 	 = 0;
               dp0_next.start_decrementor 	 = 0;
	    end
            
            
            if(dp0_reg.start) begin
               dp0_next.start = 0;
	       main_cnt_en    = 1;

               case(inst_type_comp[6 : 0])
                  7'b0000001 : begin          // NORMAL
                     shift_data_validation = 1;
                     next_state 	   = NORMAL_MODE;
		     raddr_cnt_en 	   = 1;
                  end
                  7'b0000010 : begin                                            // REDUCTION
                     next_state 	   = READ_MODE;
                     shift_data_validation = 1;
		     raddr_cnt_en 	   = 1;
                  end
                  7'b0000100 : begin                                            // STORE
		     if (main_cnt == dp0_next.read_limit-1)
		     begin
			main_cnt_en = 0;
			next_state  = IDLE;
		     end
		     else
		       next_state 	       = READ_MODE;
       		     dp0_next.vrf_read_sew     = 2'b10;
                     dp0_next.store_data_valid = 1;
                  end
                  7'b0001000 : begin                                            // INDEXED_STORE
                     dp0_next.store_data_valid 	     = 1;
                     dp0_next.store_load_index_valid = 1;
		     dp0_next.vrf_read_sew 	     = 2'b10;
                     next_state 		     = READ_MODE;
		     if (main_cnt == dp0_next.read_limit)
		     begin
		       main_cnt_en    = 0;
                       next_state 	       = IDLE;
		     end
		     else
		     begin
		       next_state 	       = READ_MODE;
		     end
                  end
                  7'b0010000 : begin                                            // LOAD
		     dp0_next.vrf_write_sew  = 2'b10;
		     request_write_control_o = 1'b1;
		     waddr_cnt_en 	     = 1;
		     waddr_out_reg_en 	     = 1;
       		     ready_for_load_o 	     = 1'b1;
                     next_state 	     = LOAD_MODE;                     
                  end
                  7'b0100000 : begin                                            // INDEXED_LOAD
                     dp0_next.store_load_index_valid = 1;
		     dp0_next.vrf_read_sew 	     = 2'b10; //
                     next_state 		     = READ_MODE;
                  end
                  7'b1000000 : begin                                            // SLIDE
		     raddr_cnt_en 		= 1;
		     dp0_next.vrf_write_sew 	= 2'b00;
		     dp0_next.vrf_read_sew 	= 2'b00;
                     dp0_next.en_write 		= 1;
		     waddr_out_reg_en 		= 1;
		     next_state 		= SLIDE;                            
                     dp0_next.vrf_write_mux_sel = 2'b10;
                  end
                  
                  default : begin                                             // An assert should be put here
                     next_state = IDLE;
                  end
               endcase
            end
         end
         NORMAL_MODE : begin
            main_cnt_en 	  = 1;            
            shift_data_validation = 1;
            raddr_cnt_en 	  = 1;
            if(main_cnt >= dp0_reg.inst_delay) begin
               dp0_next.en_write    = 1;
	       waddr_out_reg_en     = 1;
	       waddr_cnt_en 	    = 1;
               dp0_next.vmrf_wen    = 1;
               dp0_next.vmrf_cnt_en = 1;
               dp0_next.bwen_en     = 1;
            end
            
            if(main_cnt == main_cnt_limit+1) begin
               next_state 	 = IDLE;
               dp0_next.en_write = 0;
               dp0_next.vmrf_wen = 0;
            end
         end
         READ_MODE : begin
            main_cnt_en 	  = 1;            
            shift_data_validation = 1;            
            raddr_cnt_en 	  = 1;
            
            case({inst_type_comp[5], inst_type_comp[3 : 1]})
               4'b0001 : begin                                            // REDUCTION
                  if(main_cnt == (dp0_reg.read_limit + dp0_reg.inst_delay - 1)) begin                               // Not yet specified                  
                     next_state       = REDUCTION_MODE;
		     shift_partial    = 1;
		     waddr_out_reg_en = 1;
		     read_data_valid[0] = partial_results_valid;
                  end                                   
               end
               4'b0010 : begin                                            // STORE		  
                  if(read_limit_comp) begin		     
                     next_state 	       = IDLE;
                     dp0_next.store_data_valid = 0;
                  end
               end
               4'b0100 : begin                                            // INDEXED_STORE
                  if(read_limit_comp) begin                               
                     next_state 		     = IDLE;
                     dp0_next.store_data_valid 	     = 0;
                     dp0_next.store_load_index_valid = 0;
                  end
               end
               4'b1000 : begin                                            // INDEXED_LOAD
                  if(read_limit_comp) begin
                     dp0_next.store_load_index_valid = 0;
                     next_state 		     = IDLE;
                  end
               end
               default : begin                                             // An assert should be put here
                  next_state = IDLE;
               end
            endcase
            
         end 
         LOAD_MODE : begin            
            dp0_next.vrf_write_mux_sel = 1;
	    request_write_control_o    = 1'b1;
       	    ready_for_load_o 	       = 1'b1;
	    waddr_cnt_en 	       = load_valid_i;
	    waddr_out_reg_en 	       = load_valid_i;
            if(load_last_i) begin
               next_state 		  = IDLE;
               dp0_next.vrf_write_mux_sel = 0;
            end 
         end
         REDUCTION_MODE : begin
            
            main_cnt_en        = 1;            
            shift_partial      = 1;
            read_data_valid[0] = partial_results_valid;
            
            if(main_cnt == REDUCTION_MODE_LIMIT) begin
               next_state   = REDUCTION_WRITE_MODE;
	       read_data_valid[0] = 0;
	       //shift_partial = 0;
            end
         end
         REDUCTION_WRITE_MODE : begin            
            request_write_control_o = 1'b1; 
            main_cnt_en 	    = 1;
            
            if(main_cnt == dp0_reg.inst_delay+1) begin
               dp0_next.en_write = 1;
               dp0_next.vmrf_wen = 1;
            end
            
            if(dp0_reg.en_write) begin
               next_state 	     = IDLE;
               dp0_next.reduction_op = 0;
               dp0_next.en_write     = 0;
               dp0_next.vmrf_wen     = 0;
            end
            
         end        
         SLIDE : begin            
            dp0_next.read_limit = read_limit_add - dp0_reg.slide_amount[$clog2(VLANE_NUM) +: 32-($clog2(VLANE_NUM))];
            main_cnt_en 	= 1;            
            raddr_cnt_en 	= 1;
	    if(main_cnt >= dp0_reg.inst_delay) begin
	       waddr_cnt_en 	 = 1;
	       waddr_out_reg_en  = 1;
	       dp0_next.bwen_en  = 1;
	       dp0_next.en_write = 1;

	    end
	    if(main_cnt >= dp0_reg.inst_delay+1)
	       request_write_control_o = 1'b1;
	    if(main_cnt > main_cnt_limit)
	      request_write_control_o = 0;
            if(main_cnt > main_cnt_limit) begin
               next_state 	       = IDLE;	       
               dp0_next.vmrf_wen       = 0;
               dp0_next.en_comp        = 0;
 	       waddr_cnt_en 	       = 0;// Starting from the next cycle write addres counter is enabled
	       dp0_next.bwen_en        = 0;
	       dp0_next.en_write       = 0;
            end 
         end
         default : begin
            next_state = IDLE;
         end
      endcase
   end
   /////////////////////////////////////////////////////////////////////////////////
   ////////////////////////GENERATING OUTPUTS///////////////////////////////////////
   //generating ready signal
   always_ff@(posedge clk_i)
   begin
      if (!rst_i)
	ready_o <= 1'b1;
      else if (start_i && ready_o)
	ready_o <= 1'b0;
      else if (next_state == IDLE && !ready_o)
	ready_o <= 1'b1;    
   end
   //VRF write logic
   assign vrf_write_sew_o = dp0_reg.vrf_write_sew;
   //assign vmrf_wen_o = dp0_reg.vmrf_wen & dp0_reg.vector_mask;
   assign vrf_bwen_o = (current_state == LOAD_MODE) ? load_bwen_i : bwen_reg;
   assign vrf_write_mux_sel_o = dp0_reg.vrf_write_mux_sel;
   always@(posedge clk_i)
   begin
      if (!rst_i)
      begin
	 vrf_waddr_o <= '{default:'0};
      end
      else if (waddr_out_reg_en)
	vrf_waddr_o <= (current_state == SLIDE) ? slide_waddr : normal_waddr;
   end

   
   //VRF read logic

   always@(posedge clk_i)
   begin
      if (!rst_i)
      begin
	 vrf_raddr_o 		<= 0;
	 vrf_read_byte_sel_o[0] <= 0;
	 vrf_read_byte_sel_o[1] <= 0;
	 read_data_valid_o 	<= 0;
	 vmrf_addr_o 		<= 0;
	 vmrf_wen_o 		<= 0;
      end
      else
      begin
	 vmrf_addr_o 		<= vmrf_cnt;
	 vmrf_wen_o 		<= dp0_reg.vmrf_wen & dp0_reg.vector_mask;
	 vrf_raddr_o 		<= raddr;
	 vrf_read_byte_sel_o[0] <= dp0_reg.up_down_slide ? main_cnt[1 : 0] : ~main_cnt[1 : 0];
	 vrf_read_byte_sel_o[1] <= dp0_reg.up_down_slide ? main_cnt[1 : 0] : ~main_cnt[1 : 0];
	 read_data_valid_o 	<= read_data_valid;
      end
   end


   //assign vrf_raddr_o = raddr;
   //assign vmrf_addr_o = vmrf_cnt;      
   assign vrf_ren_o = dp0_reg.vrf_ren;
   assign vrf_oreg_ren_o = dp0_reg.vrf_oreg_ren;
   //assign vrf_read_byte_sel_o[0] = dp0_reg.up_down_slide ? main_cnt[1 : 0] : ~main_cnt[1 : 0];
   //assign vrf_read_byte_sel_o[1] = dp0_reg.up_down_slide ? main_cnt[1 : 0] : ~main_cnt[1 : 0];
   //assign read_data_valid_o = read_data_valid;
   assign vrf_read_sew_o = dp0_reg.vrf_read_sew;
   //VRF store port sel logic
   assign store_data_mux_sel_o = dp0_reg.store_data_mux_sel;
   assign store_load_index_mux_sel_o = dp0_reg.store_load_index_mux_sel;

   assign store_load_index_valid_o = dp0_reg.store_load_index_valid;
   assign store_data_valid_o = dp0_reg.store_data_valid;
   // Selecting ALU operands and ALU control
   assign op2_sel_o = (current_state == REDUCTION_MODE) ? 2'b11 : dp0_reg.op2_sel;
   assign op3_sel_o = dp0_reg.op3_sel;
   assign ALU_x_data_o = dp0_reg.ALU_x_data;
   assign ALU_imm_o = dp0_reg.ALU_imm;   
   assign vector_mask_o = dp0_reg.vector_mask;      
   assign ALU_ctrl_o = dp0_reg.ALU_opmode;
   //assign reduction_op_o = dp0_reg.reduction_op;
   assign reduction_op_o = dp0_reg.reduction_op;
   assign alu_en_32bit_mul_o = dp0_reg.alu_en_32bit_mul;
   //slide logic
   assign up_down_slide_o = dp0_reg.up_down_slide;
   assign slide_data_mux_sel_o = dp0_reg.slide_amount[$clog2(VLANE_NUM)-1:0];

   //configuration registers
   assign vsew_o = dp0_reg.sew;

   //reduction output
   assign ALU_reduction_data_o = lane_result_i[main_cnt[$clog2(VLANE_NUM - 1) - 1 : 0]];   
   
endmodule
