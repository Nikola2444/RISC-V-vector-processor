//`include "../../../../packages/typedef_pkg.sv"
module v_cu #
  (parameter VLEN=4096,
   parameter VLANE_NUM=16,
   parameter R_PORTS_NUM = 8,
   parameter W_PORTS_NUM = 4,
   parameter VRF_READ_DELAY=4,
   parameter VRF_WRITE_DELAY=3,
   parameter ALU_DELAY=4)

   (/*AUTOARG*/
   // Outputs
   instr_rdy_o, sew_o, lmul_o, store_driver_o, slide_type_o, vl_o,
   inst_type_o, start_o, inst_delay_o, vrf_ren_o, vrf_oreg_ren_o,
   vrf_starting_waddr_o, vrf_starting_raddr_vs1_o,
   vrf_starting_raddr_vs2_o, vrf_write_sew_o, reduction_op_o,
   store_data_mux_sel_o, store_load_index_mux_sel_o, op2_sel_o,
   op3_sel_o, alu_x_data_o, alu_imm_o, alu_opmode_o, up_down_slide_o,
   slide_amount_o, vector_mask_o,
   // Inputs
   clk, rstn, instr_vld_i, scalar_rs1_i, scalar_rs2_i, vector_instr_i,
   vrf_starting_addr_vld_i, vrf_starting_waddr_i,
   vrf_starting_raddr0_i, vrf_starting_raddr1_i, port_group_ready_i
   );
   import typedef_pkg::*;
   localparam LP_VRF_DELAY=3;
   localparam LP_VECTOR_REGISTER_NUM=32;
   localparam LP_MAX_LMUL=8;
   localparam MEM_DEPTH=VLEN/VLANE_NUM;
   localparam ALU_OPMODE_WIDTH=9;
   localparam LP_FAST_SLIDE = 1;
   localparam LP_SLOW_SLIDE = 1;
   // Number of bytes in VRF
   localparam LP_LANE_VRF_EL_NUM=VLEN*LP_VECTOR_REGISTER_NUM/8/VLANE_NUM;
   localparam LP_MAX_VL_PER_LANE=VLEN/8/VLANE_NUM*LP_MAX_LMUL;
   localparam LP_CLK_TIL_FIRST_WRITE=VRF_READ_DELAY+ALU_DELAY+2;
   // ***********V_CU I/O BEGIN**********************************
   input 					     clk;
   input 					     rstn;

   // interface with scheduler
   input [12:0] 				     instr_vld_i;
   output [12:0] 				     instr_rdy_o;
   input [31:0] 				     scalar_rs1_i;
   input [31:0] 				     scalar_rs2_i;
   input [31:0] 				     vector_instr_i;

   output [2:0] 				     sew_o;
   output [2:0] 				     lmul_o;
   output [1:0] 				     store_driver_o;
   output 					     slide_type_o;
   //interface with renaming unit
   input logic 					     vrf_starting_addr_vld_i;
   (* dont_touch = "yes" *)input logic [8*$clog2(MEM_DEPTH)-1:0] vrf_starting_waddr_i;
   (* dont_touch = "yes" *)input logic [8*$clog2(MEM_DEPTH)-1:0] vrf_starting_raddr0_i;
   (* dont_touch = "yes" *)input logic [8*$clog2(MEM_DEPTH)-1:0] vrf_starting_raddr1_i;
   
   ///*Interface with V_lane_control_units*/
   // General signals
   output logic [31:0] 				     vl_o;
   
   // Control Flow signals
   output logic [2 : 0] 			     inst_type_o; 
   // Handshaking
   output [W_PORTS_NUM - 1 : 0] 		     start_o;
   input logic [W_PORTS_NUM - 1 : 0] 		     port_group_ready_i;
   
   // Inst timing signals
   output logic [$clog2(LP_MAX_VL_PER_LANE) - 1 : 0] inst_delay_o;
   
   // VRF signals
   output logic 				     vrf_ren_o; // TODO drive this
   output logic 				     vrf_oreg_ren_o; // TODO drive this
   output logic [8 * $clog2(MEM_DEPTH) - 1 : 0]      vrf_starting_waddr_o;
   output logic [8 * $clog2(MEM_DEPTH) - 1 : 0]      vrf_starting_raddr_vs1_o;
   output logic [8 * $clog2(MEM_DEPTH) - 1 : 0]      vrf_starting_raddr_vs2_o;
   output logic [1 : 0] 			     vrf_write_sew_o;
   output logic 				     reduction_op_o;
   
   // Load and Store signals

   output logic [2:0] 				     store_data_mux_sel_o; // TODO drive this
   output logic [2:0] 				     store_load_index_mux_sel_o;//TODO drive this
   
   // ALU
   output logic [1 : 0] 			     op2_sel_o;
   output logic [$clog2(R_PORTS_NUM) - 1 : 0] 	     op3_sel_o;
   output logic [31 : 0] 			     alu_x_data_o;
   output logic [4 : 0] 			     alu_imm_o;
   output logic [ALU_OPMODE_WIDTH - 1 : 0] 	     alu_opmode_o;
   
   // Slide signals - THIS SIGNALS ARE COMING FROM ONLY ONE DRIVER
   output logic 				     up_down_slide_o;
   output logic [31 : 0] 			     slide_amount_o;
   
   // Misc signals
   output logic 				     vector_mask_o; 
   // ***********V_CU I/O END**********************************

   // ***********V_CU DECLARATIONS BEGIN***********************



   // Values Extraced from vector instruction
   logic [2:0] 					     v_instr_funct6_upper;
   logic [5:0] 					     v_instr_funct6;
   logic [4:0] 					     v_instr_imm;
   logic [4:0] 					     v_instr_vs1;
   logic [4:0] 					     v_instr_vs2;
   logic [4:0] 					     v_instr_vd;

   //Logic needed for checing instruction type
   logic 					     widening_instr_check;
   logic 					     store_instr_check;
   logic 					     reduction_instr_check;
   logic 					     slide_instr_check;
   logic 					     vector_vector_check;
   logic 					     vector_imm_check;
   logic 					     vector_scalar_check;

   // Configuration registers
   logic [31:0] 				     vtype_reg, vtype_next;
   logic [31:0] 				     vl_reg, vl_next;
   logic [2:0] 					     sew_o;
   logic [$clog2(VLEN)-1:0] 			     vlmax;
   typedef logic [7:0][2:0][$clog2(VLEN)-1:0] 	     vlmax_array_type;
   
   localparam vlmax_array_type vlmax_array=init_vlmax();
   // Depending on sew and lmul maximum vector length changes. Function
   // bellow calculates all the possibilties for vlmax depending on sew 
   // and lmul
   function vlmax_array_type init_vlmax();
      automatic vlmax_array_type vlmax_values = '{default:'0};
      for (int lmul=0; lmul<4; lmul++)	 
	for (int sew=0; sew<3; sew++)
	begin
	   vlmax_values[lmul][sew] = ((VLEN/8)/(2**sew))*(2**lmul);
	end
      for (int lmul=1; lmul<4; lmul++)	 
	for (int sew=0; sew<3; sew++)
	begin
	   vlmax_values[8-lmul][sew] = ((VLEN/8)/(2**sew))/(2**lmul);
	end
      return vlmax_values;
   endfunction // init_base_addr

   // registers for input values
   logic [31:0]						   vector_instr_reg;
   logic [12:0]						   instr_vld_reg;
   logic [12:0]						   instr_rdy_reg;
   logic [31:0]						   scalar_rs1_reg;
   logic [31:0]						   scalar_rs2_reg;

   // Values coming from renaming unit
   logic [8*$clog2(MEM_DEPTH)-1:0]			   vrf_starting_waddr_reg;
   logic [8*$clog2(MEM_DEPTH)-1:0]			   vrf_starting_raddr0_reg;
   logic [8*$clog2(MEM_DEPTH)-1:0]			   vrf_starting_raddr1_reg;
   logic						   vrf_starting_addr_vld_reg;

   
   // Signals needed dependancy checking
   logic [W_PORTS_NUM-1:0][4:0]				   vd_instr_in_progress;
   logic [W_PORTS_NUM-1:0]				   instr_in_progress;
   //logic [W_PORTS_NUM-1:0]				   instr_not_safe_to_start;   
   logic						   slide_in_progress_reg;
   logic [W_PORTS_NUM-1:0]				   reduction_in_progress_reg;
   logic [W_PORTS_NUM-1:0]				   reduction_wait_cnt_en;
   logic [W_PORTS_NUM-1:0][2:0]				   reduction_wait_cnt;
   logic [W_PORTS_NUM-1:0][6:0]				   store_dependencie_cnt;
   logic [W_PORTS_NUM-1:0][$clog2(LP_MAX_VL_PER_LANE)-1:0] dependancy_issue_cnt;
   logic						   dependancy_issue;

   
   logic [W_PORTS_NUM-1:0][$clog2(LP_MAX_VL_PER_LANE)-1:0] instr_exe_time_cnt;
   logic [W_PORTS_NUM-1:0][$clog2(LP_MAX_VL_PER_LANE)-1:0] clocks_to_wait;
   logic [W_PORTS_NUM-1:0]				   instr_dependancy_check;
   logic [W_PORTS_NUM-1:0][1:0]				   instr_in_progr_sew_reg;
   logic [W_PORTS_NUM-1:0][31:0]			   instr_in_progr_vl_reg; 
   logic [W_PORTS_NUM-1:0]				   instr_not_safe_to_start;
   logic [W_PORTS_NUM-1:0]				   sew_check;
   logic [W_PORTS_NUM-1:0][$clog2(LP_MAX_VL_PER_LANE)-1:0] instr_in_progr_vl_half_reg, instr_in_progr_vl_half;
   logic [W_PORTS_NUM-1:0][$clog2(LP_MAX_VL_PER_LANE)-1:0] instr_in_progr_vl_3_quarters_reg, instr_in_progr_vl_3_quarters;
   // ***********V_CU DECLARATIONS END***********************

   /*Registering input values*/
   always@(posedge clk)
   begin
      if (!rstn)
      begin
	 vector_instr_reg 	   <= 'h0;
	 instr_vld_reg 		   <= 'h0;
	 scalar_rs1_reg 	   <= 'h0;
	 scalar_rs2_reg 	   <= 'h0;
	 vtype_reg 		   <= {26'h0, 3'b010, 3'b000};
	 vl_reg 		   <= 4096/32;
	 vrf_starting_waddr_reg    <= 0;
	 vrf_starting_raddr0_reg   <= 0;
	 vrf_starting_raddr1_reg   <= 0;
	 vrf_starting_addr_vld_reg <= 0;
      end
      else
      begin
//	 if (instr_not_safe_to_start==0)
//	 begin
	    if((instr_vld_i[12:0] & instr_rdy_o[12:0]) != 0)// config instruction received
	    begin
	       vector_instr_reg	      <= vector_instr_i;
	       instr_vld_reg 	      <= instr_vld_i;
	       scalar_rs1_reg 	      <= scalar_rs1_i;
	       scalar_rs2_reg 	      <= scalar_rs2_i;
	       instr_rdy_reg 	      <= instr_rdy_o;
	       vrf_starting_waddr_reg    <= vrf_starting_waddr_i;
	       vrf_starting_raddr0_reg   <= vrf_starting_raddr0_i;
	       vrf_starting_raddr1_reg   <= vrf_starting_raddr1_i;
	       vrf_starting_addr_vld_reg <= vrf_starting_addr_vld_i;
	    end
	    else if (start_o!=0)
	    begin
	       instr_vld_reg 	      <= 0;
	       instr_rdy_reg 	      <= 0;
	    end
	 end
	 
	 if(instr_vld_reg[12] && instr_rdy_reg[12]) // config instruction received
	 begin
	    vtype_reg 	     <= vtype_next;	 
	    vl_reg 	     <= vl_next;
	 end
//      end	
   end
   
   //configuring vtype reg
   always_comb
   begin
      vtype_next = 'h0;
      if (vector_instr_reg[31:30] != 2'b10)//not a vsetvl instruction
      begin
	 vtype_next[2:0] = {vector_instr_reg[22:20]}; // LMUL, this is spec 0.9
	 vtype_next[5:3] = vector_instr_reg[25:23]; // SEW
	 vtype_next[6] 	 = vector_instr_reg[26]; // vta
	 vtype_next[7] 	 = vector_instr_reg[27]; // vector mask agnostic
	 vtype_next[31]  = vector_instr_reg[30]; // vector mask agnostica
      end
      else
      begin
	 vtype_next = scalar_rs1_reg;
      end
   end

   //extracting vlmax based on sew and lmul
   assign vlmax=vlmax_array[vtype_next[2:0]][vtype_next[5:3]];
   assign vl_next = v_instr_vs1 != 'h0 ? scalar_rs1_reg :
		    v_instr_vd != 0 ? {{32-$clog2(VLEN){1'b0}},vlmax} : vl_reg;
   
  // assign v_instr_funct3       = vector_instr_reg[14:12];
   
   //extracting information from vector instruction
   assign v_instr_funct6_upper = vector_instr_reg[31:29];
   assign v_instr_funct6       = vector_instr_reg[31:26];
   assign v_instr_imm          = vector_instr_reg[19:15];
   assign v_instr_vs1          = vector_instr_reg[19:15];
   assign v_instr_vs2          = vector_instr_reg[24:20];
   assign v_instr_vd           = vector_instr_reg[11:7];

   
   // Checking instruction type
      // depending on input instruction we are
   assign vector_vector_check   = instr_vld_reg[8]  || instr_vld_reg[6];
   assign vector_scalar_check   = instr_vld_reg[10]  || instr_vld_reg[7];
   assign vector_imm_check      = instr_vld_reg[9];
   assign reduction_instr_check = ((instr_vld_reg[6] || instr_vld_reg[7]) && v_instr_funct6_upper == 3'b000) ||
				  instr_vld_reg[8] && v_instr_funct6_upper == 3'b110;
   assign store_instr_check     = instr_vld_reg[3:2]!=0;
   assign widening_instr_check  = v_instr_funct6_upper == 3'b111 || v_instr_funct6_upper == 3'b110;
   
   assign slide_instr_check     = !instr_vld_reg[12] && (v_instr_funct6 == 6'b001111 || v_instr_funct6 == 6'b001110);

   
   // TODO: insert renaming unit that generates start_o waddr and start_o raddrs
   
   
   // Port resource allocation unit
   port_allocate_unit #
     (/*AUTOINST_PARAM*/
      // Parameters
      .R_PORTS_NUM			(R_PORTS_NUM),
      .W_PORTS_NUM			(W_PORTS_NUM))
   port_allocate_unit_inst     
     (/*AUTO_INST*/
      // Outputs
      .instr_rdy_o	(instr_rdy_o[12:0]),
      .start_o		(start_o),
      .store_driver_o   (store_driver_o),
      .op3_port_sel_o	(op3_sel_o),
      .slide_instr_check_i(slide_instr_check),
      .dependancy_issue_i(dependancy_issue),
      // Inputs
      .clk		(clk),
      .rstn		(rstn),
      .port_rdy_i	(port_group_ready_i),
       
      .vrf_starting_addr_vld_i(vrf_starting_addr_vld_reg),
      .instr_vld_i	(instr_vld_reg[12:0]));

/* -----\/----- EXCLUDED -----\/-----
   always@(posedge clk)
   begin
      if (!rstn)
	slide_in_progress_reg <= 0;
      else if (!slide_in_progress_reg)
	slide_in_progress_reg <= slide_instr_check;
      else if (port_group_ready_i[0])
	slide_in_progress_reg <= 0;
   end
 -----/\----- EXCLUDED -----/\----- */

   
   //logic bellow registers destination registers(vd) of instruction in
   //progress, and if there is currenlty an instruction in progress . 
   //This is needed for dependancy checking.
   always@(posedge clk)
   begin
      if (!rstn)
      begin
	 for (int i=0;i<W_PORTS_NUM;i++)
	 begin
	    vd_instr_in_progress[i] <= 5'b00000;
	    instr_in_progress[i]    <= 1'b0;
	 end
      end
      else
      begin
	 for (int i=0;i<W_PORTS_NUM;i++)
	   if (start_o[i] && port_group_ready_i[i])
	   begin
	      vd_instr_in_progress[i] <= v_instr_vd;
	      instr_in_progress[i] <= 1'b1;
	   end
	   else if (instr_in_progress[i]==1'b1 && port_group_ready_i[i])
	   begin
	      vd_instr_in_progress[i] <= 5'b00000;//no valid instruction
	      instr_in_progress[i] <= 1'b0;
	   end
      end
   end     

   // Maximum amount of elements per lane that need to be processed befor.
   // we can issue safely the next instruction
   // If amount of elements per lane cant be divided with VLANE_NUM,
   // that means at least one lane needs to process one element more than the rest,
   // so in that case we add additonal element.
   localparam LP_CHAINING_DELAY = VRF_READ_DELAY+ALU_DELAY+3;

   
   assign instr_in_progr_vl_half       = vl_o[$clog2(VLANE_NUM)-1:0] == 0 ? ((vl_o >> $clog2(VLANE_NUM)) >> 1) + LP_CHAINING_DELAY : 
					 ((vl_o >> $clog2(VLANE_NUM)) >> 1) + LP_CHAINING_DELAY + 1;
   //We calculate 3 quarters of elements that need to be proccesed.
   assign instr_in_progr_vl_3_quarters = vl_o[$clog2(VLANE_NUM)-1:0] == 0 ? ((vl_o >>$clog2(VLANE_NUM)) >> 1) + ((vl_o >> $clog2(VLANE_NUM)) >> 2) + LP_CHAINING_DELAY :
					 ((vl_o >> $clog2(VLANE_NUM)) >> 1) + ((vl_o >> $clog2(VLANE_NUM)) >> 2) + LP_CHAINING_DELAY + 1;


   //registering if reduction instruction is being executed
   always@(posedge clk)
   begin
      if (!rstn)
	reduction_in_progress_reg <= '{default:'0};
      else
      begin
	 for (int i=0; i<W_PORTS_NUM;i++)
	   if (start_o[i])
	     reduction_in_progress_reg[i] <= reduction_instr_check;
	   else if (port_group_ready_i[i])
	     reduction_in_progress_reg[i] <= 0;
      end
   end


   //registering values needed for dependancy checking. SEW, vl, vl/2, vl*3/4
   // for each instruction being executed.
   always @(posedge clk)
   begin
      if (!rstn)
      begin
	 instr_in_progr_sew_reg 	  <= '{default:'0};
	 instr_in_progr_vl_reg 		  <= '{default:'0};
	 instr_in_progr_vl_half_reg 	  <= '{default:'0};
	 instr_in_progr_vl_3_quarters_reg <= '{default:'0};
      end
      else
      begin
	 for (int i=0; i<W_PORTS_NUM; i++)
	   if (start_o[i] && port_group_ready_i[i])
	   begin
	      instr_in_progr_sew_reg[i] 	  <= slide_instr_check ? 2'b00 : sew_o[1:0];
	      instr_in_progr_vl_reg[i] 		  <= vl_o+LP_CHAINING_DELAY;
	      instr_in_progr_vl_half_reg[i] 	  <= instr_in_progr_vl_half[i];
	      instr_in_progr_vl_3_quarters_reg[i] <= instr_in_progr_vl_3_quarters[i];
	   end 
      end      
   end


   //logic bellow implements counters that count clock
   //cycles so we can know how many clock cycles each
   // chained instruction has been executing.
   always@(posedge clk)
   begin
      if (!rstn)
      begin
	 for (int i=0; i<W_PORTS_NUM; i++) 
	   instr_exe_time_cnt[i] <= 0;
      end
      else
      begin
	 for (int i=0; i<W_PORTS_NUM; i++)
	   if (start_o[i] && port_group_ready_i[i])
	   begin
	      instr_exe_time_cnt[i]<=0;		      
	   end
	   else if (instr_in_progress[i]==1'b1)// valid instruction in progress
	     instr_exe_time_cnt[i] <= instr_exe_time_cnt[i]+1;
      end
   end

   // logic bellow checks whether received instruction is dependant on instructions
   // currently in progress
   always_comb
   begin
      for (int i=0;i<W_PORTS_NUM;i++)
      begin
	 // check if vd_in_progress==vs1, vd_in_progress==vs2, vd_in_progress==vd
	 instr_dependancy_check[i] = (vd_instr_in_progress[i][4:0]==v_instr_vs1 && vector_vector_check) ||
		 (vd_instr_in_progress[i][4:0]==v_instr_vs2) || (vd_instr_in_progress[i][4:0]==v_instr_vd && store_instr_check);

	 //Amount of cycles we need to wait before safely issuing the next instruction 
	 clocks_to_wait[i] = instr_in_progr_sew_reg[i]==2'b00 && sew_o[1:0] == 2'b01 ? (instr_in_progr_vl_half_reg[i]):
			     instr_in_progr_sew_reg[i]==2'b00 && (sew_o[1:0] == 2'b10 || store_instr_check) ? (instr_in_progr_vl_3_quarters_reg[i]):
			     instr_in_progr_sew_reg[i]==2'b01 && (sew_o[1:0] == 2'b10 || store_instr_check) ? (instr_in_progr_vl_half_reg[i]) : LP_CHAINING_DELAY;

	 // Checking all conditions to safely issue the next instruction
//	 instr_not_safe_to_start[i] = (instr_dependancy_check[i] && instr_vld_reg!=0 ) &&
//				      ((instr_exe_time_cnt[i] < clocks_to_wait[i]) || reduction_in_progress_reg[i]) && instr_in_progress != 4'h0;

      end
   end
   
   always @(posedge clk)
   begin
      if (!rstn)
      begin
	 instr_not_safe_to_start <= '{default:'0};
      end
      else
      begin
	 for (int i=0; i<W_PORTS_NUM; i++)
	 begin
	    if (start_o[i] && port_group_ready_i[i])
	      instr_not_safe_to_start[i] <= 1'b1;
	    else if (port_group_ready_i[i])
	      instr_not_safe_to_start[i] <= 1'b0;
	    else if (((instr_exe_time_cnt[i] < clocks_to_wait[i]) || reduction_in_progress_reg[i]) && instr_not_safe_to_start[i])
	      instr_not_safe_to_start[i] <= 1'b1;
	    else
	      instr_not_safe_to_start[i] <= 1'b0;
	 end
      end
   end

   always_comb
   begin
      for (int i=0; i<W_PORTS_NUM; i++)
      begin
	 dependancy_issue = 1'b0;
	 if (instr_not_safe_to_start[i]!=0 & instr_dependancy_check[i] != 0)
	 begin
	    dependancy_issue = 1'b1;
	    break;
	 end
      end
   end

   /***************DEPENDANCY CHECK LOGIC END***********/   
   /***************OUTPUTS*****************************/
   assign lmul_o = vtype_reg[2:0];
   assign sew_o  = vtype_reg[5:3];
   assign vl_o   = vl_reg;

   assign vrf_ren_o                = 1'b1; // TODO drive this
   assign vrf_oreg_ren_o           = 1'b1; // TODO drive thisa	
   assign vrf_starting_waddr_o     = vrf_starting_waddr_reg;
   assign vrf_starting_raddr_vs1_o = vrf_starting_raddr0_reg;
   assign vrf_starting_raddr_vs2_o = vrf_starting_raddr1_reg;
   
   
   assign store_data_mux_sel_o=start_o == 1 ? 0 :
			       start_o == 2 ? 2 :
			       start_o == 4 ? 4 : 6;


   
   assign store_load_index_mux_sel_o=start_o == 1 ? 1 :
				     start_o == 2 ? 3 :
				     start_o == 4 ? 5 : 7;

   assign reduction_op_o  = reduction_instr_check;
   assign slide_type_o    = (sew_o == 3'b000 && (scalar_rs1_reg == VLANE_NUM*4)) || 
			    (sew_o == 3'b001 && (scalar_rs1_reg == VLANE_NUM*2)) || 
			    (sew_o == 3'b010 && (scalar_rs1_reg == VLANE_NUM)) ? LP_FAST_SLIDE : LP_SLOW_SLIDE;
		       
   
   
   
   assign inst_type_o = instr_vld_reg[3] ? 2 : // vector store
			instr_vld_reg[2] ? 3 : // indexed store
			instr_vld_reg[5] ? 4 : // vector load
			instr_vld_reg[4] ? 5 : // indexed load
			reduction_instr_check ? 1 :// reduction instruction
			slide_instr_check ? 6 : //slide instructions
			!instr_vld_reg[12] ? 0 : // Normal instruction
			7; // invalid instrucion

   // this will chenge when renaming is inserted
   //assign start_o = inst_type_o != 1'b1;
   // This tells how much delay ALU+VRF inserts for a particular instruction.
   assign inst_delay_o = slide_instr_check ? VRF_READ_DELAY-1 : VRF_READ_DELAY+ALU_DELAY;
   
   // instructions that dont read from VRF are load and config
   assign vrf_ren      = !instr_vld_reg[12] && !instr_vld_reg[5] && instr_vld_reg != 0;
   assign vrf_oreg_ren = !instr_vld_reg[12] && !instr_vld_reg[5] && instr_vld_reg != 0;
   
   assign vrf_write_sew_o  = slide_instr_check && slide_type_o == LP_SLOW_SLIDE ? 2'b00 :
			   widening_instr_check ? sew_o[1:0] + 1 : sew_o[1:0]; // NOTE: check this. We should check if widening instructions is in play
                                                                       // TODO: take into account narrowing instructions
   
   assign op2_sel_o = vector_vector_check ? 2'b00 :
		      vector_scalar_check ? 2'b01 :
		      vector_imm_check    ? 2'b10 :
		      2'b11;

   // assign op3_sel_o = // TODO: resource available logic needed for this

   assign alu_x_data_o = scalar_rs1_reg;
   assign alu_imm_o = vector_instr_reg[19:15];

   assign up_down_slide_o = !(v_instr_funct6 == 6'b001111);

   
   assign slide_amount_o = instr_vld_reg[9]  ? {{27{1'b0}}, v_instr_imm} << sew_o:
			   instr_vld_reg[10] ? scalar_rs1_reg << sew_o : 32'b1 << sew_o;
   assign vector_mask_o   = ~vector_instr_reg[25];
   
   

   //alu_opmode_o
   // NOTE: we need to somehow provide information about sign, rounding, saturation, width change, mask operation, width of each operand...
   always_comb
   begin
      alu_opmode_o = 'h0;
      if (instr_vld_reg[10:8]!=0) // Check is instr is: OPIVI||OPIVX||OPIVV
	case(v_instr_funct6)
	   6'b000000: alu_opmode_o = add_op;
	   //6'b000001: 
	   6'b000010: alu_opmode_o = sub_op;
	   6'b000011: alu_opmode_o = sub_op;
	   6'b000100: alu_opmode_o = sltu_op;
	   6'b000101: alu_opmode_o = slt_op;
	   6'b000110: alu_opmode_o = sgtu_op;
	   6'b000111: alu_opmode_o = sgt_op;
	   //6'b001000:
	   6'b001001: alu_opmode_o = and_op;
	   6'b001010: alu_opmode_o = or_op;
	   6'b001011: alu_opmode_o = xor_op;
	   //6'b001100: // vrgather funct6
	   //6'b001101: // reserved
	   //6'b001110: // slideup or vrgatherei16
	   //6'b001111: // slidedown
	   6'b010000: alu_opmode_o = add_op; // this is vadc
	   //6'b010001: reserved
	   6'b010001: alu_opmode_o = add_op; // this is vmadc
	   6'b010010: alu_opmode_o = sub_op; // this is vsbc
	   6'b010011: alu_opmode_o = sub_op; // this is vmsbc
	   //6'b010100: reserved
	   //6'b010101: reserved
	   //6'b010110: reserved
	   //6'b010111: vmerge/vmv
	   6'b011000: alu_opmode_o = seq_op; // this is equal
	   6'b011001: alu_opmode_o = sneq_op; // this is not equal
	   6'b011010: alu_opmode_o = sltu_op; 
	   6'b011011: alu_opmode_o = slt_op; 
	   6'b011100: alu_opmode_o = sleu_op;
	   6'b011101: alu_opmode_o = sle_op; 
	   6'b011110: alu_opmode_o = sgtu_op;
	   6'b011111: alu_opmode_o = sgt_op;

	   6'b100000: alu_opmode_o = addu_op; // saturation add
	   6'b100001: alu_opmode_o = add_op; // saturation add unsigned
	   6'b100010: alu_opmode_o = subu_op; // saturation sub
	   6'b100011: alu_opmode_o = sub_op; // saturation sub unsigned
	   //6'b100100: reserved
	   6'b100101: alu_opmode_o = sll_op; // NOTE: this should be unsigned
	   //6'b100110: reserved
	   6'b100111: alu_opmode_o = mul_op; // saturation multiply NOTE: this should be signed
	   6'b101000: alu_opmode_o = srl_op; 
	   6'b101001: alu_opmode_o = sra_op;
	   6'b101010: alu_opmode_o = srl_op; // Round off shift
	   6'b101011: alu_opmode_o = sra_op; // Round off shift	   
	   6'b101100: alu_opmode_o = srl_op; // Narowing shift
	   6'b101101: alu_opmode_o = sra_op; // Narowing arithmetic shift
	   6'b101110: alu_opmode_o = srl_op; // Vnclipu
	   6'b101111: alu_opmode_o = srl_op; // Vnclip
	   
	   //6'b110000: alu_opmode_o = add_op; // Vector widening reduction add
	   6'b110000: alu_opmode_o = add_op; // Vector widening reduction addu
	   6'b110001: alu_opmode_o = add_op; // Vector widening reduction addu
	   default: alu_opmode_o = 'h0;
	endcase // case (funct6)
      else if (instr_vld_reg[7:6]!=0)// Check is instr is: OPMVX||OPMVV
	case(v_instr_funct6)
	   6'b000000: alu_opmode_o = add_op;
	   6'b000001: alu_opmode_o = and_op;
	   6'b000010: alu_opmode_o = or_op;
	   6'b000011: alu_opmode_o = xor_op;
	   6'b000100: alu_opmode_o = sltu_op;
	   6'b000101: alu_opmode_o = slt_op;
	   6'b000110: alu_opmode_o = sgtu_op;
	   6'b000111: alu_opmode_o = sgt_op;
	   
	   6'b001000: alu_opmode_o = addu_op;// vaaddu
	   6'b001001: alu_opmode_o = add_op;// vaadd
	   6'b001010: alu_opmode_o = subu_op;// vasubu
	   6'b001011: alu_opmode_o = sub_op;// vasub
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
	   6'b011000: alu_opmode_o = andnot_op; // this is equal
	   6'b011001: alu_opmode_o = and_op; // this is not equal
	   6'b011010: alu_opmode_o = or_op; 
	   6'b011011: alu_opmode_o = xor_op; 
	   6'b011100: alu_opmode_o = ornot_op;
	   6'b011101: alu_opmode_o = nand_op; 
	   6'b011110: alu_opmode_o = nor_op;
	   6'b011111: alu_opmode_o = xnor_op;

	   //6'b100000: vdivu
	   //6'b100001: vdiv
	   //6'b100010: vremu
	   //6'b100011: vrem
	   6'b100100: alu_opmode_o = mulhu_op; 
	   6'b100101: alu_opmode_o = mul_op; 
	   6'b100110: alu_opmode_o = mulhsu_op;
	   6'b100111: alu_opmode_o = mulh_op; // saturation multiply NOTE: this should be unsigned
	   //6'b101000: 
	   6'b101001: alu_opmode_o = mul_add_op;
	   //6'b101010: 
	   6'b101011: alu_opmode_o = mul_sub_op; //vnmsub
	   //6'b101100:
	   6'b101101: alu_opmode_o = mul_add_op; // 
	   //6'b101110:
	   6'b101111: alu_opmode_o = mul_sub_op; // Vnmsuc
	   
	   6'b110000: alu_opmode_o = addu_op; // Vector widening reduction addu
	   6'b110001: alu_opmode_o = add_op; // Vector widening reduction add
	   6'b110010: alu_opmode_o = subu_op; // Vector widening reduction subu
	   6'b110011: alu_opmode_o = sub_op; // Vector widening reduction sub
	   6'b110100: alu_opmode_o = addu_op; //vwaddu.w
	   6'b110101: alu_opmode_o = add_op; //vwadd.w
	   6'b110110: alu_opmode_o = subu_op; //vwsubu.w
	   6'b110111: alu_opmode_o = sub_op; //vwsub.w	   
	   6'b111000: alu_opmode_o = mulu_op; //vwmulu
	   //6'b111001:
	   6'b111010: alu_opmode_o = mulsu_op; //vwmulu
	   6'b111011: alu_opmode_o = mul_op; //vwmulu
	   6'b111100: alu_opmode_o = mulu_add_op; //vwmaccu
	   6'b111101: alu_opmode_o = mul_add_op; //vwmacc
	   6'b111110: alu_opmode_o = mulus_add_op; //vwmaccus
	   6'b111111: alu_opmode_o = mulsu_add_op; //vwmaccsu
	   default: alu_opmode_o = 'h0;
	endcase // case (funct6)      
   end

endmodule
