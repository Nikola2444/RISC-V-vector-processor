module Vector_Lane
  #(
    parameter R_PORTS_NUM = 8,
    parameter W_PORTS_NUM = 4,
    parameter MEM_DEPTH = 512,
    parameter MAX_VL_PER_LANE = 32,
    parameter ALU_CTRL_WIDTH = 6,
    parameter MULTIPUMP_WRITE = 2,
    parameter MULTIPUMP_READ = 2,
    parameter RAM_PERFORMANCE = "HIGH_PERFORMANCE", /* Select "HIGH_PERFORMANCE" or "LOW_LATENCY" */
    parameter MEM_WIDTH = 32,
    parameter V_LANE_NUM = 0
    )
   (
    input 							       clk_i,
    input 							       clk2_i,
    input 							       rst_i,
   
    // Config and status signals
    input logic [W_PORTS_NUM - 1 : 0][1 : 0] 			       vsew_i,
    input logic [W_PORTS_NUM - 1 : 0][1 : 0] 			       wdata_width_i,
   
    // VRF
    input logic [R_PORTS_NUM - 1 : 0] 				       vrf_ren_i,
    input logic [R_PORTS_NUM - 1 : 0] 				       vrf_oreg_ren_i,
    input logic [R_PORTS_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0]       vrf_raddr_i,
    input logic [W_PORTS_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0]       vrf_waddr_i, 
    input logic [W_PORTS_NUM - 1 : 0][3 : 0] 			       vrf_bwen_i,
   
    // Options for write data and slide-related signals
    input logic  [31 : 0] 					       load_data_i, // UPDATED
    input logic  [31 : 0] 					       slide_data_i, // UPDATED
    output logic [31 : 0] 					     slide_data_o,
   
    // Vector mask register file
    input logic [W_PORTS_NUM - 1 : 0][$clog2(MAX_VL_PER_LANE) - 1 : 0] vmrf_addr_i,
    input logic [W_PORTS_NUM - 1 : 0] 				       vmrf_wen_i,
   
    // Other control signals
    input logic [R_PORTS_NUM - 1 : 0][1 : 0] 			       el_extractor_i,
    input logic [W_PORTS_NUM - 1 : 0] 				       vector_mask_i,
    input logic [W_PORTS_NUM - 1 : 0][1 : 0] 			       write_data_sel_i,
    input logic [W_PORTS_NUM - 1 : 0] 				       request_control_i, // NEW SIGNAL
   
    // Store/Load signals
    output logic [W_PORTS_NUM - 1 : 0] 				       store_data_valid_o,
    input logic [W_PORTS_NUM - 1 : 0] 				       store_data_valid_i,
    output logic [W_PORTS_NUM - 1 : 0] 				       store_load_index_valid_o,
    input logic [W_PORTS_NUM - 1 : 0] 				       store_load_index_valid_i,
    output logic [W_PORTS_NUM - 1 : 0][31 : 0] 			       store_data_o,
    output logic [W_PORTS_NUM - 1 : 0][31 : 0] 			       store_load_index_o,
    input logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0]     store_data_mux_sel_i,
    input logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0]     store_load_index_mux_sel_i,
   
    // ALU signals
    // input logic [W_PORTS_NUM - 1 : 0][1 : 0] 			       op2_sel_i,
    input logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0]     op3_sel_i,
    // input logic [W_PORTS_NUM - 1 : 0][31 : 0] 			       ALU_x_data_i,
    // input logic [W_PORTS_NUM - 1 : 0][4 : 0] 			       ALU_imm_i,
    // input logic [W_PORTS_NUM - 1 : 0][31 : 0] 			       ALU_reduction_data_i,
    input logic [W_PORTS_NUM - 1 : 0] 				       reduction_op_i,
    input logic 						       slide_op_i,
    input logic [W_PORTS_NUM - 1 : 0][ALU_CTRL_WIDTH - 1 : 0] 	       ALU_ctrl_i,
    input logic [W_PORTS_NUM - 1 : 0] 				       read_data_valid_i,
    output logic [W_PORTS_NUM - 1 : 0][31 : 0] 			       ALU_output_o,

    // ALU I/O
    output logic [W_PORTS_NUM - 1 : 0][ALU_CTRL_WIDTH - 1 : 0] 	       alu_opmode_o,
    output logic [W_PORTS_NUM - 1 : 0][ 31 : 0] 		       vs1_data_o,
    output logic [W_PORTS_NUM - 1 : 0][ 31 : 0] 		       vs2_data_o,
    output logic [W_PORTS_NUM - 1 : 0][ 31 : 0] 		       vs3_data_o,
    output logic [W_PORTS_NUM - 1 : 0] 				       alu_vld_o,
    output logic [W_PORTS_NUM - 1 : 0] 				       alu_reduction_o,
    // output logic [W_PORTS_NUM - 1 : 0][31 : 0] 			       alu_reduction_data_o,
    output logic [W_PORTS_NUM - 1 : 0][1:0] 			       alu_read_sew_o,
    output logic [W_PORTS_NUM - 1 : 0][1:0] 			       alu_write_sew_o,
    input logic [W_PORTS_NUM - 1 : 0] 				       alu_vld_i,
    input logic [W_PORTS_NUM - 1 : 0][31:0] 			       alu_res_i,
    input logic [W_PORTS_NUM - 1 : 0] 				       ALU_mask_vector_i
    


    );    
   
   // Loacal parameters //
     ////////////////////////////////////////////////
   localparam VRF_DELAY = 3;
   localparam VMRF_DELAY = 2;
   localparam SLIDE_PORT_ID = 1;
   ////////////////////////////////////////////////
    
   // Generate variable    
   ////////////////////////////////////////////////
   genvar 							       i_gen, j_gen;
   ////////////////////////////////////////////////

   // VRF read port signals
   ////////////////////////////////////////////////
   logic [R_PORTS_NUM - 1 : 0][31 : 0] 				       vrf_rdata;
   ////////////////////////////////////////////////

   ////////////////////////////////////////////////
   logic [VMRF_DELAY - 1 : 0][W_PORTS_NUM - 1 : 0] 		       request_control_reg, request_control_next;
   ////////////////////////////////////////////////

   // VRF write port signals
   ////////////////////////////////////////////////
   logic [W_PORTS_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] 	       vrf_waddr;
   logic [W_PORTS_NUM - 1 : 0][31 : 0] 				       vrf_wdata_mux;
   logic [W_PORTS_NUM - 1 : 0][31 : 0] 				       vrf_wdata;
   logic [W_PORTS_NUM - 1 : 0][3 : 0] 				       vrf_bwen;
   ////////////////////////////////////////////////

   // Read data preparation logic 
   ////////////////////////////////////////////////
   logic [R_PORTS_NUM - 1 : 0][7 : 0] 				       read_data_byte_mux;
   logic [R_PORTS_NUM - 1 : 0][1 : 0] 				       read_data_byte_mux_sel;                                          // # Control signal # DONE
   logic [R_PORTS_NUM - 1 : 0][15 : 0] 				       read_data_hw_mux;
   logic [R_PORTS_NUM - 1 : 0] 					       read_data_hw_mux_sel;                                                   // # Control signal # DONE
   logic [R_PORTS_NUM - 1 : 0][31 : 0] 				       read_data_mux;
   logic [R_PORTS_NUM - 1 : 0][1 : 0] 				       read_data_mux_sel;                                               // # Control signal # DONE
   logic [R_PORTS_NUM - 1 : 0][3 * 32 - 1 : 0] 			       read_data_prep_reg, read_data_prep_next;
   ////////////////////////////////////////////////

   // Write address logic
   ////////////////////////////////////////////////
   logic [W_PORTS_NUM - 1 : 0][1 : 0] 				       write_data_mux_sel;                                              // # Control signal # DONE
   ////////////////////////////////////////////////

   // Pipeline registers
   ////////////////////////////////////////////////
   // VRF write pipeline register
   // vrf_waddr | vrf_wdata | bwen
   logic [VMRF_DELAY - 1 : 0][W_PORTS_NUM - 1 : 0][4 + 32 + $clog2(MEM_DEPTH) - 1 : 0] vrf_write_reg, vrf_write_next;      

   // Read data preparation pipeline registers
   logic [R_PORTS_NUM - 1 : 0][VRF_DELAY - 2 : 0][1 : 0] 			       el_extractor_reg, el_extractor_next; 

   // Vector mask pipeline register
   logic [VMRF_DELAY - 1 : 0][W_PORTS_NUM - 1 : 0] 				       vm_reg, vm_next;

   // VMRF write pipeline register
   // vmrf_write_en | vmrf_wdata | vmrf_waddr
   logic [VMRF_DELAY - 1 : 0][W_PORTS_NUM - 1 : 0][$clog2(MAX_VL_PER_LANE) + 1 + 1 - 1 : 0] vmrf_write_reg, vmrf_write_next;

   // Pipeline registers for the signals on the same level as ALU
   typedef struct 									    packed {
      logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] 				    op3_sel;
      // logic [W_PORTS_NUM - 1 : 0][1 : 0] 						    op2_sel;
      // logic [W_PORTS_NUM - 1 : 0][31 : 0] 						    ALU_x_data, ALU_reduction_data;
      // logic [W_PORTS_NUM - 1 : 0][4 : 0] 						    ALU_imm;
      logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] 				    store_data_mux_sel, store_load_index_mux_sel;
      logic [W_PORTS_NUM - 1 : 0][ALU_CTRL_WIDTH - 1 : 0] 				    ALU_ctrl;
      logic [W_PORTS_NUM - 1 : 0] 							    store_data_valid;
      logic [W_PORTS_NUM - 1 : 0] 							    ALU_reduction;
      logic [W_PORTS_NUM - 1 : 0] 							    store_load_index_valid;
      logic [W_PORTS_NUM - 1 : 0] 							    read_data_valid;
      logic [W_PORTS_NUM - 1 : 0][1 : 0] 						    sew;
      logic [W_PORTS_NUM - 1 : 0][1 : 0] 						    wdata_width;
      
   } ALU_packet; 

   ALU_packet [VRF_DELAY - 1 : 0] ALU_signals_reg, ALU_signals_next; 
   ////////////////////////////////////////////////
   
   // Vector mask register file
   ////////////////////////////////////////////////
   logic [W_PORTS_NUM - 1 : 0] 								    vmrf_wdata, vmrf_rdata;    
   logic [W_PORTS_NUM - 1 : 0][3 : 0] 							    bwen_mux;
   logic [W_PORTS_NUM - 1 : 0] 								    bwen_mux_sel;                                                           // # Control signal # DONE
   logic [W_PORTS_NUM - 1 : 0][$clog2(MAX_VL_PER_LANE) - 1 : 0] 			    vmrf_waddr;
   logic [W_PORTS_NUM - 1 : 0] 								    vmrf_wen;
   ////////////////////////////////////////////////

   // ALU
   ////////////////////////////////////////////////
   logic [W_PORTS_NUM - 1 : 0][31 : 0] 							    ALU_out_data;
   logic [W_PORTS_NUM - 1 : 0] 								    ALU_vector_mask;
   logic [W_PORTS_NUM - 1 : 0][31 : 0] 							    vs1_data, vs2_data, op3;
   // logic [W_PORTS_NUM - 1 : 0][1 : 0] 							    op2_sel;
   logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] 				    op3_sel;
   logic [W_PORTS_NUM - 1 : 0][R_PORTS_NUM - 1 : 0][31 : 0] 				    op3_mux;
   // logic [W_PORTS_NUM - 1 : 0][31 : 0] 							    ALU_x_data, ALU_imm, ALU_reduction_data;
   logic [W_PORTS_NUM - 1 : 0][ALU_CTRL_WIDTH - 1 : 0] 					    ALU_ctrl;
   logic [W_PORTS_NUM - 1 : 0] 								    ALU_reduction;
   // logic [W_PORTS_NUM - 1 : 0] imm_sign;
   logic [VMRF_DELAY - 1 : 0][W_PORTS_NUM - 1 : 0] 					    alu_output_valid_reg, alu_output_valid_next;
   ////////////////////////////////////////////////

   // Load and store
   ////////////////////////////////////////////////
   logic [W_PORTS_NUM - 1 : 0][R_PORTS_NUM - 1 : 0][31 : 0] 				    store_data_mux;
   logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] 				    store_data_mux_sel;
   logic [W_PORTS_NUM - 1 : 0][R_PORTS_NUM - 1 : 0][31 : 0] 				    store_load_index_mux;
   logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] 				    store_load_index_mux_sel;
   ////////////////////////////////////////////////

   // slide data
   ////////////////////////////////////////////////
   logic [VMRF_DELAY-1:0][31:0] 							    slide_data_reg;
   ////////////////////////////////////////////////
   
   // Moduls instantiation
   ////////////////////////////////////////////////
   
   vrf 
     #
     (
      .R_PORTS_NUM(R_PORTS_NUM),
      .W_PORTS_NUM(W_PORTS_NUM),
      .MEM_DEPTH(MEM_DEPTH),
      .MEM_WIDTH(MEM_WIDTH),
      .RAM_TYPE ("BRAM"),
      .MULTIPUMP_WRITE(MULTIPUMP_WRITE),
      .MULTIPUMP_READ(MULTIPUMP_READ),
      .RAM_PERFORMANCE(RAM_PERFORMANCE)
      )
   VRF_inst
     (
      .clk(clk_i),
      .clk2(clk2_i),
      .rstn(rst_i),
      
      // Read IF
      .raddr_i(vrf_raddr_i),
      .ren_i(vrf_ren_i),
      .oreg_en_i(vrf_oreg_ren_i), 
      .dout_o(vrf_rdata),
      
      // Write IF
      .waddr_i(vrf_waddr),
      .bwe_i(vrf_bwen),
      //.wen_i({W_PORTS_NUM{1'b0}}),                                   // What is this signal doing?
      .din_i(vrf_wdata)
      );

   vrf
     #(
       .R_PORTS_NUM(W_PORTS_NUM),
       .W_PORTS_NUM(W_PORTS_NUM),
       .RAM_TYPE("DISTRAM"),
       .MEM_DEPTH(MAX_VL_PER_LANE),
       .MEM_WIDTH(1),
       .MULTIPUMP_WRITE(MULTIPUMP_WRITE),
       .MULTIPUMP_READ(MULTIPUMP_READ),
       .RAM_PERFORMANCE(RAM_PERFORMANCE)
       )
   VMRF
     (
      .clk(clk_i),
      .clk2(clk2_i),
      .rstn(rst_i),
      
      .dout_o(vmrf_rdata),
      .raddr_i(vmrf_addr_i),
      .ren_i(4'hf),
      .oreg_en_i(4'hf), 
      .din_i(vmrf_wdata),                  
      .waddr_i(vmrf_waddr),
      .bwe_i(vmrf_wen)
      );

   assign alu_opmode_o = ALU_ctrl;
   assign vs1_data_o = vs1_data;
   assign vs2_data_o = vs2_data;
    
   
   assign alu_reduction_o = ALU_reduction;
   
   generate
      for (genvar i=0; i<W_PORTS_NUM; i++)
	assign alu_read_sew_o[i] = ALU_signals_reg[VRF_DELAY - 1].sew[i];
   endgenerate
   generate
      for (genvar i=0; i<W_PORTS_NUM; i++)
	assign alu_write_sew_o[i] = ALU_signals_reg[VRF_DELAY - 1].wdata_width[i];
   endgenerate
   assign alu_vld_o = ALU_signals_reg[VRF_DELAY-1].read_data_valid;
   
   assign alu_output_valid_next[0] = alu_vld_i;
   assign ALU_out_data[W_PORTS_NUM-1:0]= alu_res_i;
   assign ALU_vector_mask=ALU_mask_vector_i;

   ////////////////////////////////////////////////
       // Choosing slide data
   assign slide_data_o = vrf_rdata[SLIDE_PORT_ID];

   always_ff@(posedge clk_i)
   begin
      if (!rst_i)
	slide_data_reg <= 0;
      else
	slide_data_reg <= {slide_data_reg[VMRF_DELAY-2:0], slide_data_i};
			
   end

   ////////////////////////////////////////////////
   // Pipeline registers for data on the same level as ALU
   always_ff@(posedge clk_i) begin
      for(int i = 0; i < VRF_DELAY; i++) begin
         if(!rst_i) begin
            ALU_signals_reg[i] <= 0;
         end
         else begin
            ALU_signals_reg[i] <= ALU_signals_next[i];
         end
      end
   end

   always_comb begin
      for(int i = 0; i < VRF_DELAY - 1; i++) begin
         ALU_signals_next[i + 1] = ALU_signals_reg[i]; 
      end
      op3_sel = ALU_signals_reg[VRF_DELAY - 1].op3_sel;
      
      store_data_mux_sel = ALU_signals_reg[VRF_DELAY - 1].store_data_mux_sel;
      store_load_index_mux_sel = ALU_signals_reg[VRF_DELAY - 1].store_load_index_mux_sel;
      ALU_ctrl = ALU_signals_reg[VRF_DELAY - 1].ALU_ctrl;
      ALU_reduction = ALU_signals_reg[VRF_DELAY - 1].ALU_reduction;
      store_data_valid_o = ALU_signals_reg[VRF_DELAY - 1].store_data_valid;
      store_load_index_valid_o = ALU_signals_reg[VRF_DELAY - 1].store_load_index_valid;
      
      ALU_signals_next[0].op3_sel = op3_sel_i;
      ALU_signals_next[0].ALU_reduction = reduction_op_i;
      ALU_signals_next[0].store_data_mux_sel = store_data_mux_sel_i;
      ALU_signals_next[0].store_load_index_mux_sel = store_load_index_mux_sel_i;
      ALU_signals_next[0].ALU_ctrl = ALU_ctrl_i;
      ALU_signals_next[0].store_data_valid = store_data_valid_i;
      ALU_signals_next[0].store_load_index_valid = store_load_index_valid_i;
      ALU_signals_next[0].read_data_valid = read_data_valid_i;
      ALU_signals_next[0].sew = vsew_i;
      ALU_signals_next[0].wdata_width = wdata_width_i;
      
   end

   generate

      for(i_gen = 0; i_gen < R_PORTS_NUM; i_gen++) begin
         
         always_comb begin
            // Mux for choosing the right byte
	    read_data_byte_mux[i_gen] = vrf_rdata[i_gen][read_data_byte_mux_sel[i_gen]*8 +: 8];
            // Mux for choosing the right halfword
	    read_data_hw_mux[i_gen] = vrf_rdata[i_gen][read_data_hw_mux_sel[i_gen]*16 +: 16];
            // Mux for choosing the right data
	    read_data_mux[i_gen] = (read_data_mux_sel[i_gen] != 3) ? read_data_prep_reg[i_gen][read_data_mux_sel[i_gen]*32 +: 32] : 0;
            
         end
         
         // Registers
         always_ff@(posedge clk_i) begin
            if(!rst_i) begin
               read_data_prep_reg[i_gen] <= 0; 
               for(int i = 0; i < VRF_DELAY - 1; i++) begin
                  el_extractor_reg[i_gen][i] <= 0;               
               end
            end
            else begin
               read_data_prep_reg[i_gen] <= read_data_prep_next[i_gen];
               
               for(int i = 0; i < VRF_DELAY - 1; i++) begin
                  el_extractor_reg[i_gen][i] <= el_extractor_next[i_gen][i];                  
               end
            end
         end
         
         always_comb begin
            for(int i = 1; i < VRF_DELAY - 1; i++) begin
               el_extractor_next[i_gen][i] = el_extractor_reg[i_gen][i - 1];
            end
            el_extractor_next[i_gen][0] = el_extractor_i[i_gen];
         end
         
         // Generate VRF read assignments
         assign read_data_prep_next[i_gen] = {vrf_rdata[i_gen], {{16{1'b0}}, read_data_hw_mux[i_gen]}, {{24{1'b0}}, read_data_byte_mux[i_gen]}};
         assign read_data_byte_mux_sel[i_gen] = el_extractor_reg[i_gen][VRF_DELAY - 2];
         assign read_data_hw_mux_sel[i_gen] = el_extractor_reg[i_gen][VRF_DELAY - 2][0];
	 
	 if (i_gen == SLIDE_PORT_ID)
           assign read_data_mux_sel[SLIDE_PORT_ID] = slide_op_i ? 2'b10 : ALU_signals_reg[VRF_DELAY - 1].sew[0];
	 else
           assign read_data_mux_sel[i_gen] = ALU_signals_reg[VRF_DELAY - 1].sew[i_gen/2];
      end
      
      for(j_gen = 0; j_gen < W_PORTS_NUM; j_gen++) begin
         
         always_comb begin
            
            bwen_mux[j_gen] = (bwen_mux_sel[j_gen] == 0) ? vrf_write_reg[VMRF_DELAY-1][j_gen][3 : 0] : (vrf_write_reg[VMRF_DELAY-1][j_gen][3 : 0] & {4{vmrf_rdata[j_gen]}}); 
	    
            
            case(write_data_mux_sel[j_gen])
               0: vrf_wdata_mux[j_gen] = ALU_out_data[j_gen];
               1: vrf_wdata_mux[j_gen] = load_data_i;
               //2: vrf_wdata_mux[j_gen] = slide_data_reg[VMRF_DELAY-1];
               2: vrf_wdata_mux[j_gen] = slide_data_i;
               3: vrf_wdata_mux[j_gen] = 0; // Should insert an assert
               default: vrf_wdata_mux[j_gen] = 0;
            endcase
            
            // Extender for immediate
            // ALU_imm[j_gen] = {{27{1'b0}}, ALU_signals_reg[VRF_DELAY - 1].ALU_imm[j_gen]};
            
            // Muxes for ALU operands
            vs1_data[j_gen] = read_data_mux[j_gen << 1];
	        vs2_data[j_gen] = read_data_mux[(j_gen << 1) + 1];
            
            for(int i = 0; i < R_PORTS_NUM; i++) begin
               op3_mux[j_gen][i] = read_data_mux[i]; 
            end
            op3[j_gen] = op3_mux[j_gen][op3_sel[j_gen]];
            
            // Store data mux
            for(int i = 0; i < R_PORTS_NUM; i++) begin
               //store_data_mux[j_gen][i] = read_data_mux[i];
	       store_data_mux[j_gen][i]=read_data_prep_reg[i][95:64]; //take all 32 bits, sew doesnt matter.
            end
            store_data_o[j_gen] = store_data_mux[j_gen][store_data_mux_sel[j_gen]];

            // Store and load index mux
            for(int i = 0; i < R_PORTS_NUM; i++) begin
               store_load_index_mux[j_gen][i] = read_data_mux[i]; 
            end
            store_load_index_o[j_gen] = store_load_index_mux[j_gen][store_load_index_mux_sel[j_gen]];            
            
         end
         
         // Registers
         always_ff@(posedge clk_i) begin
            if(!rst_i) begin
               for(int i = 0; i < VMRF_DELAY; i++) begin
                  vrf_write_reg[i][j_gen] 	 <= 0;
                  vmrf_write_reg[i][j_gen] 	 <= 0;
                  vm_reg[i][j_gen] 		 <= 0;
                  alu_output_valid_reg[i][j_gen] <= 0;
                  request_control_reg[i][j_gen]  <= 0;		 
               end
            end
            else begin
               for(int i = 0; i < VMRF_DELAY; i++) begin
                  vrf_write_reg[i][j_gen] 	 <= vrf_write_next[i][j_gen];
                  vmrf_write_reg[i][j_gen] 	 <= vmrf_write_next[i][j_gen];
                  vm_reg[i][j_gen] 		 <= vm_next[i][j_gen];
                  alu_output_valid_reg[i][j_gen] <= alu_output_valid_next[i][j_gen];
                  request_control_reg[i][j_gen]  <= request_control_next[i][j_gen];
		  
               end
            end
         end
         
         always_comb begin
            for(int i = 0; i < VMRF_DELAY - 1; i++) begin
               vrf_write_next[i + 1][j_gen] 	   = vrf_write_reg[i][j_gen];
               vmrf_write_next[i + 1][j_gen] 	   = vmrf_write_reg[i][j_gen];
               vm_next[i + 1][j_gen] 		   = vm_reg[i][j_gen];
               alu_output_valid_next[i + 1][j_gen] = alu_output_valid_reg[i][j_gen];
               request_control_next[i + 1][j_gen]  = request_control_reg[i][j_gen];
            end
            vrf_write_next[0][j_gen] 	   = {vrf_waddr_i[j_gen] ,vrf_wdata_mux[j_gen], vrf_bwen_i[j_gen]};
            vmrf_write_next[0][j_gen] 	   = {vmrf_wen_i[j_gen], ALU_vector_mask[j_gen], vmrf_addr_i[j_gen]};
            vm_next[0][j_gen] 		   = vector_mask_i[j_gen];
            request_control_next[0][j_gen] = request_control_i[j_gen];
         end
         
         // Generate VRF read assignments

	 assign vrf_bwen[j_gen] = bwen_mux[j_gen] & {4{(alu_output_valid_reg[VMRF_DELAY - 1][j_gen] | request_control_reg[VMRF_DELAY - 1][j_gen])}};
				  
         assign vrf_waddr[j_gen] = vrf_write_reg[VMRF_DELAY - 1][j_gen][4 + 32 +: $clog2(MEM_DEPTH)]; 
         assign vrf_wdata[j_gen] = vrf_write_reg[VMRF_DELAY - 1][j_gen][32 + 4 - 1 : 4];
         assign vmrf_wen[j_gen] = vmrf_write_reg[VMRF_DELAY - 1][j_gen][$clog2(MAX_VL_PER_LANE) + 1 + 1 - 1] & 
                                  (alu_output_valid_reg[VMRF_DELAY - 1][j_gen] | request_control_reg[VMRF_DELAY - 1][j_gen]);
         assign vmrf_wdata[j_gen] = vmrf_write_reg[VMRF_DELAY - 1][j_gen][$clog2(MAX_VL_PER_LANE)];
         assign vmrf_waddr[j_gen] = vmrf_write_reg[VMRF_DELAY - 1][j_gen][$clog2(MAX_VL_PER_LANE) - 1 : 0];
         assign bwen_mux_sel[j_gen] = vm_reg[VMRF_DELAY - 1][j_gen]; // 
         assign write_data_mux_sel[j_gen] = write_data_sel_i[j_gen];
         assign ALU_output_o[j_gen] = ALU_out_data[j_gen];
         assign vs3_data_o[j_gen] = op3[j_gen];

      end
      
   endgenerate;


endmodule
