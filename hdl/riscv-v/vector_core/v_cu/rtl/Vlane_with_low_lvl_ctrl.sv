module Vlane_with_low_lvl_ctrl
#(
    parameter MEM_DEPTH = 512,
    parameter MAX_VL_PER_LANE = 4 * 8 * 8,
    parameter VREG_LOC_PER_LANE = 8,
    parameter W_PORTS_NUM = 4,
    parameter R_PORTS_NUM = 8,
    parameter INST_TYPE_NUM = 7,
    parameter VLANE_NUM = 8,
    parameter ALU_OPMODE = 6,
    parameter MULTIPUMP_WRITE = 2,
    parameter MULTIPUMP_READ = 2,
    parameter RAM_PERFORMANCE = "HIGH_PERFORMANCE", // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    parameter MEM_WIDTH = 32
)
(
    input clk_i,
    input clk2_i,
    input rst_i,
    
    // General signals
    input logic [$clog2(VLANE_NUM * MAX_VL_PER_LANE) - 1 : 0] vl_i,
    input logic [2 : 0] vsew_i,
    input logic [2 : 0] vlmul_i,                                                                                        // NEW SIGNAL
    
    // Control Flow signals
    input logic [$clog2(INST_TYPE_NUM) - 1 : 0] inst_type_i,
    
    // Handshaking
    input [W_PORTS_NUM - 1 : 0] start_i,
    output logic [W_PORTS_NUM - 1 : 0] ready_o,
    
    // Inst timing signals
    input logic [$clog2(MAX_VL_PER_LANE) - 1 : 0] inst_delay_i,
    
    // VRF signals
    input logic  vrf_ren_i,                                                
    input logic  vrf_oreg_ren_i,
    input logic [8 * $clog2(MEM_DEPTH) - 1 : 0] vrf_starting_waddr_i,
    input logic [2 : 0][8 * $clog2(MEM_DEPTH) - 1 : 0] vrf_starting_raddr_i,                       // UPDATED
    input logic [1 : 0] wdata_width_i,    
    
    // Load and Store signals
    input logic load_valid_i,                                                                                           // UPDATED
    input logic load_last_i,                                                                                            // UPDATED
    output logic ready_for_load_o,                                                                                      // UPDATED
    input logic [VLANE_NUM - 1 : 0][31 : 0] load_data_i,
    input logic [VLANE_NUM - 1 : 0][3 : 0] load_bwen_i,
    input logic [$clog2(R_PORTS_NUM) - 1 : 0] store_data_mux_sel_i,
    input logic [$clog2(R_PORTS_NUM) - 1 : 0] store_load_index_mux_sel_i,
    
    // ALU
    input logic [1 : 0] op2_sel_i,
    input logic [$clog2(R_PORTS_NUM) - 1 : 0] op3_sel_i,
    input logic [31 : 0] ALU_x_data_i,
    input logic [4 : 0] ALU_imm_i,
    input logic [ALU_OPMODE - 1 : 0] ALU_opmode_i,
    input logic reduction_op_i,
    input logic alu_en_32bit_mul_i,                                                               // UPDATED
    
    // Slide signals - THIS SIGNALS ARE COMING FROM ONLY ONE DRIVER
    input logic up_down_slide_i,
    input logic slide_type_i,
    input logic [31 : 0] slide_amount_i,
    
    // Misc signals
    input logic vector_mask_i,
    
    // A group signals determining where to route read related signals
    input logic [R_PORTS_NUM - 1 : 0][$clog2(W_PORTS_NUM) - 1 : 0] read_port_allocation_i,                              // UPDATED, 0 - RP0, 1 RP1, ...
    input logic [R_PORTS_NUM - 1 : 0] primary_read_data_i,                                                              // UPDATED 
    
    // Vlane outputs
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][31 : 0] store_data_o,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][31 : 0] store_load_index_o,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] store_data_valid_o,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] store_load_index_valid_o
    
);

function logic orTree(input logic [W_PORTS_NUM - 1 : 0] vector);
    
    localparam R = $clog2(W_PORTS_NUM);                           // 2
    localparam TREE_WIDTH = ((R ** (R + 1)) - 1) / (R - 1);     // 7
    logic [TREE_WIDTH - 1 : 0] localVector;
    
    localVector = {{(TREE_WIDTH - W_PORTS_NUM){1'b0}}, vector};   // 000 & vector
    
    for(int i = R; i >= 1; i--) begin                           
        for(int j = 0; j < i; j++) begin                        
            localVector[2 ** i + j] = localVector[2 * j] | localVector[2 * j + 1];
        end
        localVector = localVector >> (W_PORTS_NUM >> (R - i));
    end
    
    return localVector[0];
    
endfunction

////////////////////////////////////////////////////////////////////////////////////
// Connecting signals

// Special load signals
logic [W_PORTS_NUM - 1 : 0] ready_for_load;

// Off lane signals for slides and reductions
logic [VLANE_NUM - 1 : 0][31 : 0] slide_data_input, slide_data_output;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][31 : 0] ALU_output;
logic [W_PORTS_NUM - 1 : 0][VLANE_NUM - 2 : 0][31 : 0] lane_result;

// Driver - Interconnect signals
logic [W_PORTS_NUM - 1 : 0][1 : 0] vsew_di;
logic [W_PORTS_NUM - 1 : 0][1 : 0] wdata_width_di;
logic [W_PORTS_NUM - 1 : 0][VLANE_NUM - 1 : 0] read_data_valid_di;                              // TO BE CHECKED
logic [W_PORTS_NUM - 1 : 0] vrf_ren_di;
logic [W_PORTS_NUM - 1 : 0] vrf_oreg_ren_di;
logic [W_PORTS_NUM - 2 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_waddr_partial_di;
logic [VLANE_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_waddr_complete_di;
logic [W_PORTS_NUM - 1 : 0][2 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_raddr_di;
logic [W_PORTS_NUM - 2 : 0][VLANE_NUM - 1 : 0][3 : 0] vrf_bwen_partial_di;
logic [VLANE_NUM - 1 : 0][3 : 0] vrf_bwen_complete_di;
logic [W_PORTS_NUM - 1 : 0][$clog2(MAX_VL_PER_LANE) - 1 : 0] vmrf_addr_di;   
logic [W_PORTS_NUM - 1 : 0] vmrf_wen_di;
logic [W_PORTS_NUM - 1 : 0] store_data_valid_di;
logic [W_PORTS_NUM - 1 : 0] store_load_index_valid_di;
logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] store_data_mux_sel_di;
logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] store_load_index_mux_sel_di;
logic [W_PORTS_NUM - 1 : 0][1 : 0] op2_sel_di;
logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] op3_sel_di;
logic [W_PORTS_NUM - 1 : 0][31 : 0] ALU_x_data_di;
logic [W_PORTS_NUM - 1 : 0][4 : 0] ALU_imm_di;
logic [W_PORTS_NUM - 1 : 0][31 : 0] ALU_reduction_data_di;
logic [W_PORTS_NUM - 1 : 0][ALU_OPMODE - 1 : 0] ALU_ctrl_di;
logic [W_PORTS_NUM - 1 : 0] reduction_op_di;
logic alu_en_32bit_mul_di;                                                                      // UPDATED
logic up_down_slide_di;
logic slide_op;
logic [$clog2(VLANE_NUM)-1:0] slide_data_mux_sel;

logic [W_PORTS_NUM - 1 : 0] request_write_control_di;                                           // UPDATED
logic [W_PORTS_NUM - 1 : 0][1 : 0] el_extractor_di;
logic [W_PORTS_NUM - 1 : 0] vector_mask_di;
logic [W_PORTS_NUM - 1 : 0][1 : 0] write_data_sel_di;

// Interconnect - Vector lane signals
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][1 : 0] vsew_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][1 : 0] wdata_width_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] read_data_valid_il;
logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0] vrf_ren_il;
logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0] vrf_oreg_ren_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_waddr_il;
logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_raddr_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][3 : 0] vrf_bwen_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][$clog2(MAX_VL_PER_LANE) - 1 : 0] vmrf_addr_il;   
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] vmrf_wen_il;
logic [VLANE_NUM - 1 : 0][31 : 0] load_data_il;                                                 // UPDATED
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] store_data_valid_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] store_load_index_valid_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] store_data_mux_sel_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] store_load_index_mux_sel_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][1 : 0] op2_sel_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] op3_sel_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][31 : 0] ALU_x_data_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][4 : 0] ALU_imm_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][31 : 0] ALU_reduction_data_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][ALU_OPMODE - 1 : 0] ALU_ctrl_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0]                     reduction_op_il;
logic [VLANE_NUM - 1 : 0] alu_en_32bit_mul_il;                                                  // UPDATED
logic [VLANE_NUM - 1 : 0] up_down_slide_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] request_write_control_il;                        // UPDATED
logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0][1 : 0] el_extractor_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] vector_mask_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][1 : 0] write_data_sel_il;
////////////////////////////////////////////////////////////////////////////////////

// VLANE-ALU signals
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0][ALU_OPMODE-1:0] alu_opmode;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0][31:0] 	  vs1_data;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0][31:0] 	  vs2_data;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0][31:0] 	  vs3_data;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0][31:0] 	  alu_a;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0][31:0] 	  alu_b;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0][31:0] 	  alu_c;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0][31:0] 	  alu_res;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0][1 : 0] 	  alu_read_sew;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0][1 : 0] 	  alu_write_sew;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0] 		  alu_in_vld;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0][1:0] 		  alu_op2_sel;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0] 		  alu_reduction;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0] 		  alu_out_vld;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0] 		  alu_mask_vector;

assign ready_for_load_o = orTree(ready_for_load);

generate
    for(genvar i = 0; i < W_PORTS_NUM; i++) begin
        if(i == 0) begin
            Complete_sublane_driver_new
            #(
                .MEM_DEPTH(MEM_DEPTH),
                .MAX_VL_PER_LANE(MAX_VL_PER_LANE),
                .VREG_LOC_PER_LANE(VREG_LOC_PER_LANE),
                .R_PORTS_NUM(R_PORTS_NUM),
                .INST_TYPE_NUM(INST_TYPE_NUM),
                .VLANE_NUM(VLANE_NUM),
                .ALU_OPMODE(ALU_OPMODE)
            )
            Complete_sublane_driver_inst
            (
                .clk_i(clk_i),
                .rst_i(rst_i),
                .vl_i(vl_i),
                .vsew_i(vsew_i[1 : 0]),
                .vsew_o(vsew_di[0]),
                .wdata_width_o(wdata_width_di[0]),
                .vlmul_i(vlmul_i),
                .inst_type_i(inst_type_i),
                .start_i(start_i[0]),
                .ready_o(ready_o[0]),
                .inst_delay_i(inst_delay_i),
                .read_data_valid_o(read_data_valid_di[0]),
                .vrf_ren_i(vrf_ren_i),
                .vrf_oreg_ren_i(vrf_oreg_ren_i),
                .vrf_starting_waddr_i(vrf_starting_waddr_i),
                .vrf_starting_raddr_i(vrf_starting_raddr_i),
                .wdata_width_i(wdata_width_i),
                .vrf_ren_o(vrf_ren_di[0]),
                .vrf_oreg_ren_o(vrf_oreg_ren_di[0]),
                .vrf_waddr_o(vrf_waddr_complete_di),
                .vrf_raddr_o(vrf_raddr_di[0]),
                .vrf_bwen_o(vrf_bwen_complete_di),
                .vmrf_addr_o(vmrf_addr_di[0]),   
                .vmrf_wen_o(vmrf_wen_di[0]),
                .load_bwen_i(load_bwen_i),
                // .load_valid_i(load_valid_i),
                .load_last_i(load_last_i),
                .ready_for_load_o(ready_for_load[0]),
                .store_data_mux_sel_i(store_data_mux_sel_i),
                .store_load_index_mux_sel_i(store_load_index_mux_sel_i),
                .store_data_valid_o(store_data_valid_di[0]),
                .store_load_index_valid_o(store_load_index_valid_di[0]),
                .store_data_mux_sel_o(store_data_mux_sel_di[0]),
                .store_load_index_mux_sel_o(store_load_index_mux_sel_di[0]),
                .lane_result_i(lane_result[0]),
                .op2_sel_i(op2_sel_i),
                .op3_sel_i(op3_sel_i),
                .ALU_x_data_i(ALU_x_data_i),
                .ALU_imm_i(ALU_imm_i),
                .ALU_opmode_i(ALU_opmode_i),
                .reduction_op_i (reduction_op_i),
                .op2_sel_o(op2_sel_di[0]),
                .op3_sel_o(op3_sel_di[0]),
                .ALU_x_data_o(ALU_x_data_di[0]),
                .ALU_imm_o(ALU_imm_di[0]),
                .ALU_reduction_data_o(ALU_reduction_data_di[0]),
                .ALU_ctrl_o(ALU_ctrl_di[0]),
                .reduction_op_o (reduction_op_di[0]),
                .alu_en_32bit_mul_i(alu_en_32bit_mul_i),
                .alu_en_32bit_mul_o(alu_en_32bit_mul_di),                               
                .up_down_slide_i(up_down_slide_i),
	            .slide_op_o (slide_op),
	            .slide_data_mux_sel_o  (slide_data_mux_sel),
	            // .slide_type_i   (slide_type),
                .slide_amount_i(slide_amount_i),
                .up_down_slide_o(up_down_slide_di),                                         // 1 for left and 0 for right
                .request_write_control_o(request_write_control_di[0]),
                .vector_mask_i(vector_mask_i),
                .el_extractor_o(el_extractor_di[0]),
                .vector_mask_o(vector_mask_di[0]),
                .write_data_sel_o(write_data_sel_di[0])
            );
        end
        else begin
            Partial_sublane_driver
            #(
                .MEM_DEPTH(MEM_DEPTH),
                .MAX_VL_PER_LANE(MAX_VL_PER_LANE),
                .VREG_LOC_PER_LANE(VREG_LOC_PER_LANE),
                .R_PORTS_NUM(R_PORTS_NUM),
                .INST_TYPE_NUM(INST_TYPE_NUM),
                .VLANE_NUM(VLANE_NUM),
                .ALU_OPMODE(ALU_OPMODE)
                //.STRIDE_ENABLE("NO")
            )
            Partial_sublane_driver_inst
            (
                .clk_i(clk_i),
                .rst_i(rst_i),
                .vl_i(vl_i),
                .vsew_o(vsew_di[i]),
                .wdata_width_o(wdata_width_di[i]),
                .vsew_i(vsew_i[1 : 0]),
                //.vlmul_i(vlmul_i),
                .inst_type_i(inst_type_i),
                .start_i(start_i[i]),
                .ready_o(ready_o[i]),
                .inst_delay_i(inst_delay_i),
                .read_data_valid_o(read_data_valid_di[i]),
                .vrf_ren_i(vrf_ren_i),
                .vrf_oreg_ren_i(vrf_oreg_ren_i),
                .vrf_starting_waddr_i(vrf_starting_waddr_i),
                .vrf_starting_raddr_i(vrf_starting_raddr_i),
                .wdata_width_i(wdata_width_i),
                .vrf_ren_o(vrf_ren_di[i]),
                .vrf_oreg_ren_o(vrf_oreg_ren_di[i]),
                .vrf_waddr_o(vrf_waddr_partial_di[i - 1]),
                .vrf_raddr_o(vrf_raddr_di[i]),
                .vrf_bwen_o(vrf_bwen_partial_di[i - 1]),
                .vmrf_addr_o(vmrf_addr_di[i]),   
                .vmrf_wen_o(vmrf_wen_di[i]),
                .load_bwen_i(load_bwen_i),
                // .load_valid_i(load_valid_i),
                .load_last_i(load_last_i),
                .ready_for_load_o(ready_for_load[i]),
                .request_write_control_o(request_write_control_di[i]),
                .store_data_mux_sel_i(store_data_mux_sel_i),
                .store_load_index_mux_sel_i(store_load_index_mux_sel_i),
                .store_data_valid_o(store_data_valid_di[i]),
                .store_load_index_valid_o(store_load_index_valid_di[i]),
                .store_data_mux_sel_o(store_data_mux_sel_di[i]),
                .store_load_index_mux_sel_o(store_load_index_mux_sel_di[i]),
                .lane_result_i(lane_result[i]),
                .op2_sel_i(op2_sel_i),
                .op3_sel_i(op3_sel_i),
                .ALU_x_data_i(ALU_x_data_i),
                .ALU_imm_i(ALU_imm_i),
                .ALU_opmode_i(ALU_opmode_i),
                .reduction_op_i (reduction_op_i),
                .op2_sel_o(op2_sel_di[i]),
                .op3_sel_o(op3_sel_di[i]),
                .ALU_x_data_o(ALU_x_data_di[i]),
                .ALU_imm_o(ALU_imm_di[i]),
                .ALU_reduction_data_o(ALU_reduction_data_di[i]),
                .ALU_ctrl_o(ALU_ctrl_di[i]),
                .reduction_op_o (reduction_op_di[i]),
                .vector_mask_i(vector_mask_i),
                .el_extractor_o(el_extractor_di[i]),
                .vector_mask_o(vector_mask_di[i]),
                .write_data_sel_o(write_data_sel_di[i])
            );        
        end
    end
endgenerate;

Driver_vlane_interconnect
#(
    .W_PORTS_NUM(W_PORTS_NUM),
    .R_PORTS_NUM(R_PORTS_NUM),
    .VLANE_NUM(VLANE_NUM),
    .MEM_DEPTH(MEM_DEPTH),
    .ALU_OPMODE(ALU_OPMODE),
    .MAX_VL_PER_LANE(MAX_VL_PER_LANE)
)
Driver_vlane_interconnect_inst
(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .vsew_i(vsew_di),
    .wdata_width_i(wdata_width_di),
    .wdata_width_o(wdata_width_il),
    .vsew_o(vsew_il),
    .read_data_valid_i(read_data_valid_di),
    .read_data_valid_o(read_data_valid_il),
    .vrf_ren_i(vrf_ren_di),
    .vrf_oreg_ren_i(vrf_oreg_ren_di),
    .vrf_waddr_partial_i(vrf_waddr_partial_di),
    .vrf_waddr_complete_i(vrf_waddr_complete_di),
    .vrf_raddr_i(vrf_raddr_di),
    .vrf_bwen_partial_i(vrf_bwen_partial_di),
    .vrf_bwen_complete_i(vrf_bwen_complete_di),
    .vrf_ren_o(vrf_ren_il),
    .vrf_oreg_ren_o(vrf_oreg_ren_il),
    .vrf_waddr_o(vrf_waddr_il),
    .vrf_raddr_o(vrf_raddr_il),
    .vrf_bwen_o(vrf_bwen_il),
    .vmrf_addr_i(vmrf_addr_di),   
    .vmrf_wen_i(vmrf_wen_di),
    .vmrf_addr_o(vmrf_addr_il),   
    .vmrf_wen_o(vmrf_wen_il),
    .load_data_i(load_data_i),
    .load_data_o(load_data_il),
    .store_data_valid_i(store_data_valid_di),
    .store_load_index_valid_i(store_load_index_valid_di),
    .store_data_mux_sel_i(store_data_mux_sel_di),
    .store_load_index_mux_sel_i(store_load_index_mux_sel_di),
    .store_data_valid_o(store_data_valid_il),
    .store_load_index_valid_o(store_load_index_valid_il),
    .store_data_mux_sel_o(store_data_mux_sel_il),
    .store_load_index_mux_sel_o(store_load_index_mux_sel_il),
    .op2_sel_i(op2_sel_di),
    .op3_sel_i(op3_sel_di),
    .ALU_x_data_i(ALU_x_data_di),
    .ALU_imm_i(ALU_imm_di),
    .ALU_reduction_data_i(ALU_reduction_data_di),
    .ALU_ctrl_i(ALU_ctrl_di),
    .reduction_op_i (reduction_op_di),
    .alu_en_32bit_mul_i(alu_en_32bit_mul_di),
    .op2_sel_o(op2_sel_il),
    .op3_sel_o(op3_sel_il),
    .ALU_x_data_o(ALU_x_data_il),
    .ALU_imm_o(ALU_imm_il),
    .ALU_reduction_data_o(ALU_reduction_data_il),
    .ALU_ctrl_o(ALU_ctrl_il),
    .reduction_op_o (reduction_op_il),
    .alu_en_32bit_mul_o(alu_en_32bit_mul_il),
    .up_down_slide_i(up_down_slide_di),
    .request_write_control_i(request_write_control_di),
    .up_down_slide_o(up_down_slide_il),
    .request_write_control_o(request_write_control_il),
    .el_extractor_i(el_extractor_di),
    .vector_mask_i(vector_mask_di),
    .write_data_sel_i(write_data_sel_di),
    .el_extractor_o(el_extractor_il),
    .vector_mask_o(vector_mask_il),
    .write_data_sel_o(write_data_sel_il),
    .read_port_allocation_i(read_port_allocation_i),
    .primary_read_data_i(primary_read_data_i) 
    
);

generate
   for(genvar i = 0; i < VLANE_NUM; i++) begin: VL_instances
      Vector_Lane
		  #(
		    .R_PORTS_NUM(R_PORTS_NUM),
		    .W_PORTS_NUM(W_PORTS_NUM),
		    .MEM_DEPTH(MEM_DEPTH),
		    .MAX_VL_PER_LANE(MAX_VL_PER_LANE),
		    .ALU_CTRL_WIDTH(ALU_OPMODE),
		    .MULTIPUMP_WRITE(MULTIPUMP_WRITE),
		    .MULTIPUMP_READ(MULTIPUMP_READ),
		    .RAM_PERFORMANCE(RAM_PERFORMANCE),
		    .MEM_WIDTH(MEM_WIDTH),
		    .V_LANE_NUM(i)
		    )
      Vector_Lane_inst
		  (
		   .clk_i(clk_i),
		   .clk2_i(clk2_i),
		   .rst_i(rst_i),
		   .vsew_i(vsew_il[i]),
		   .wdata_width_i(wdata_width_il[i]),
		   .vrf_ren_i(vrf_ren_il[i]),
		   .vrf_oreg_ren_i(vrf_oreg_ren_il[i]),
		   .vrf_raddr_i(vrf_raddr_il[i]),
		   .vrf_waddr_i(vrf_waddr_il[i]), 
		   .vrf_bwen_i(vrf_bwen_il[i]),
		   .load_data_i(load_data_il[i]),
		   .slide_op_i (slide_op),
		   .slide_data_i(slide_data_input[i]),
		   .slide_data_o(slide_data_output[i]),
		   .vmrf_addr_i(vmrf_addr_il[i]),
		   .vmrf_wen_i(vmrf_wen_il[i]),
		   .el_extractor_i(el_extractor_il[i]),
		   .vector_mask_i(vector_mask_il[i]),
		   .write_data_sel_i(write_data_sel_il[i]),
		   .request_control_i(request_write_control_il[i]),
		   .store_data_valid_o(store_data_valid_o[i]),
		   .store_data_valid_i(store_data_valid_il[i]),
		   .store_load_index_valid_o(store_load_index_valid_o[i]),
		   .store_load_index_valid_i(store_load_index_valid_il[i]),
		   .store_data_o(store_data_o[i]),
		   .store_load_index_o(store_load_index_o[i]),
		   .store_data_mux_sel_i(store_data_mux_sel_il[i]),
		   .store_load_index_mux_sel_i(store_load_index_mux_sel_il[i]),
		   // .op2_sel_i(op2_sel_il[i]),
		   .op3_sel_i(op3_sel_il[i]),
		   // .ALU_x_data_i(ALU_x_data_il[i]),
		   // .ALU_imm_i(ALU_imm_il[i]),
		   // .ALU_reduction_data_i(ALU_reduction_data_il[i]),
		   .ALU_ctrl_i(ALU_ctrl_il[i]),
		   .reduction_op_i(reduction_op_il[i]),
		   .read_data_valid_i(read_data_valid_il[i]),
		   //.ALU_output_o(ALU_output[i]), // TODO: remove this, taken directly from alu

		   .alu_opmode_o(alu_opmode[i]),
     		   .vs1_data_o(vs1_data[i]),
     		   .vs2_data_o(vs2_data[i]),
    		   .vs3_data_o(vs3_data[i]),
		   .alu_reduction_o(alu_reduction[i]),
     		   .alu_vld_o(alu_in_vld[i]),
     		   .alu_read_sew_o(alu_read_sew[i]),
     		   .alu_write_sew_o(alu_write_sew[i]),
     		   .alu_vld_i(alu_out_vld[i]),
     		   .alu_res_i(alu_res_reordered[i]),
     		   .ALU_mask_vector_i(alu_mask_vector[i])
		   );
   end // block: VL_instances
   //generate ALU units

endgenerate;
   localparam VRF_DELAY = 3;
   localparam VMRF_DELAY = 2;

   logic [W_PORTS_NUM - 1 : 0][VRF_DELAY-1:0][31 : 0] ALU_x_data, ALU_imm_data, ALU_reduction_data;
   logic [W_PORTS_NUM - 1 : 0][VRF_DELAY-1:0][1 : 0] op2_sel;
   logic [VRF_DELAY-1:0][1:0] 			     slide_read_byte_sel_reg;
   always@(posedge clk_i)
   begin
      if (!rst_i)
      begin
	 ALU_imm_data 	    <= 'h0;
	 ALU_x_data 	    <= 'h0;
	 ALU_reduction_data <= 'h0;
      end
      else
      begin
	 for (int i=0; i<W_PORTS_NUM; i++)
	 begin
	    ALU_imm_data[i] 	  <= {ALU_imm_data[i][VRF_DELAY-2:0],ALU_imm_il[0][i]};
	    ALU_x_data[i] 	  <= {ALU_x_data[i][VRF_DELAY-2:0],ALU_x_data_il[0][i]};
	    ALU_reduction_data[i] <= {ALU_reduction_data[i][VRF_DELAY-2:0],ALU_reduction_data_il[0][i]};
	    op2_sel[i] <= {op2_sel[i][VRF_DELAY-2:0],op2_sel_il[0][i]};
	    slide_read_byte_sel_reg <= {slide_read_byte_sel_reg[VRF_DELAY-2:0], el_extractor_il[0][1]};//Lane0 R_port1
	    
	 end
      end      
   end

   //alu_b reordered
   localparam LP_32bit_ALU_GROUPS = VLANE_NUM/4;
   localparam LP_16bit_ALU_GROUPS = VLANE_NUM/2;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0][31:0] alu_a_16bit;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0][31:0] alu_a_32bit;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0][31:0] alu_b_16bit;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0][31:0] alu_b_32bit;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0][31:0] alu_c_16bit;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0][31:0] alu_c_32bit;
   logic [VLANE_NUM-1:0][W_PORTS_NUM-1:0][31:0] alu_res_reordered;
   always_comb
   begin
      
      for (int lane=0; lane<VLANE_NUM; lane+=2)
	for(int byte_sel=0; byte_sel < 16/8; byte_sel++)
	begin
	   for (int port=0; port<W_PORTS_NUM; port++)
	   begin
	      /* -----\/----- EXCLUDED -----\/-----
	       alu_b_16bit[byte_sel*LP_16bit_ALU_GROUPS+lane/2][port] = {16'b0, vs2_data[lane+1][port][byte_sel*8 +:8], vs2_data[lane][port][byte_sel*8 +:8]};
	       alu_a_16bit[byte_sel*LP_16bit_ALU_GROUPS+lane/2][port] = {16'b0, vs1_data[lane+1][port][byte_sel*8 +:8], vs1_data[lane][port][byte_sel*8 +:8]};
	       alu_c_16bit[byte_sel*LP_16bit_ALU_GROUPS+lane/2][port] = {16'b0, vs3_data[lane+1][port][byte_sel*8 +:8], vs3_data[lane][port][byte_sel*8 +:8]};
	       -----/\----- EXCLUDED -----/\----- */
	      alu_b_16bit[byte_sel+lane][port] = {16'b0, vs2_data[lane+1][port][byte_sel*8 +:8], vs2_data[lane][port][byte_sel*8 +:8]};
	      alu_a_16bit[byte_sel+lane][port] = {16'b0, vs1_data[lane+1][port][byte_sel*8 +:8], vs1_data[lane][port][byte_sel*8 +:8]};
	      alu_c_16bit[byte_sel+lane][port] = {16'b0, vs3_data[lane+1][port][byte_sel*8 +:8], vs3_data[lane][port][byte_sel*8 +:8]};
	   end
	end


      for (int lane=0; lane<VLANE_NUM; lane+=4)
	for(int byte_sel=0; byte_sel < 32/8; byte_sel++)
	begin
	   for (int port=0; port<W_PORTS_NUM; port++)
	   begin
	      alu_b_32bit[byte_sel + lane][port] = {vs2_data[lane+3][port][byte_sel*8 +:8], vs2_data[lane+2][port][byte_sel*8 +:8],
									  vs2_data[lane+1][port][byte_sel*8 +:8], vs2_data[lane][port][byte_sel*8 +:8]};
	      alu_a_32bit[byte_sel + lane][port] = {vs1_data[lane+3][port][byte_sel*8 +:8], vs1_data[lane+2][port][byte_sel*8 +:8],
									  vs1_data[lane+1][port][byte_sel*8 +:8], vs1_data[lane][port][byte_sel*8 +:8]};
	      alu_c_32bit[byte_sel + lane][port] = {vs3_data[lane+3][port][byte_sel*8 +:8], vs3_data[lane+2][port][byte_sel*8 +:8],
									  vs3_data[lane+1][port][byte_sel*8 +:8], vs3_data[lane][port][byte_sel*8 +:8]};
	   end 
	end            
   end

   
   always_comb
   begin
      for (int lane=0; lane<VLANE_NUM; lane++)
	for (int i=0;i<W_PORTS_NUM;i++)
	begin
	   case(op2_sel[i][VRF_DELAY-1])
	      0:begin
		 case (alu_read_sew[lane][i])
		    0: alu_b[lane][i] = vs2_data[lane][i];
		    1: alu_b[lane][i] = alu_b_16bit[lane][i];
		    2: alu_b[lane][i] = alu_b_32bit[lane][i];
		    default: alu_b[lane][i] = 0;
		 endcase
	      end
	      
              1: alu_b[lane][i] = ALU_x_data[i][VRF_DELAY-1];
              2: alu_b[lane][i] = ALU_imm_data[i][VRF_DELAY-1];
              3: alu_b[lane][i] = ALU_reduction_data[i][VRF_DELAY-1]; // Should insert an assert
              default: alu_b[lane][i] = vs2_data[lane][i];
           endcase // case (op2_sel[i][VRF_DELAY-1])
	   alu_a[lane][i] = alu_read_sew[lane][i] == 2'b00 ? vs1_data[lane][i] :
			    alu_read_sew[lane][i] == 2'b01 ? alu_a_16bit[lane][i] : alu_a_32bit[lane][i];
	   alu_c[lane][i] = alu_read_sew[lane][i] == 2'b00 ? vs1_data[lane][i] :
			    alu_read_sew[lane][i] == 2'b01 ? alu_c_16bit[lane][i] : alu_c_32bit[lane][i];
      end
   end

   

   
   generate
      for (genvar i=0;i<VLANE_NUM;i++)
      begin: gen_ALU
	 alu#(
	      .OP_WIDTH(32),
	      .PARALLEL_IF_NUM(W_PORTS_NUM),
	      .V_LANE_NUM(i)
	      )
	 ALU_inst(
		  .clk(clk_i),
		  .rstn(rst_i),
	    
		  .alu_opmode_i(alu_opmode[i]),
		  .alu_reduction_i(alu_reduction[i]),
		  .alu_a_i(alu_a[i]),
		  .alu_b_i(alu_b[i]),
		  .alu_c_i(alu_c[i]),
		  .input_sew_i(alu_read_sew[i]),
		  .output_sew_i(alu_write_sew[i]),
		  .alu_vld_i(alu_in_vld[i]),
		  .alu_vld_o(alu_out_vld[i]),
		  .alu_o(alu_res[i]),
		  .alu_mask_vector_o(alu_mask_vector[i])
		  //.alu_en_32bit_mul_i(1'b0),// Need more details
		  // .alu_stall_i(1'b0) // Need more details
	    
		  );
	 // ALU output needed for reduction
	 assign ALU_output[i] = alu_res[i];
      end      
   endgenerate

   always_comb
   begin



      for (int lane=0; lane<VLANE_NUM; lane+=4)
      begin
	   for (int port=0; port<W_PORTS_NUM; port++)
	   begin
	      if (alu_write_sew[lane+0][port]==2'b10)
		alu_res_reordered[lane+0][port] = {alu_res[lane+3][port][7:0], alu_res[lane+2][port][7:0],
						   alu_res[lane+1][port][7:0], alu_res[lane+0][port][7:0]}; // take byte 0, from ALU0,1,2,3
	      else if (alu_write_sew[lane+0][port]==2'b01)
		alu_res_reordered[lane+0][port] = {2{alu_res[lane+1][port][7:0], alu_res[lane+0][port][7:0]}}; // take byte 0, from ALU0,1
	      else
		alu_res_reordered[lane+0][port] = {4{alu_res[lane+0][port][7:0]}}; //take byte 0 FROM ALU0

	      if (alu_write_sew[lane+1][port]==2'b10)
		alu_res_reordered[lane+1][port] = {alu_res[lane+3][port][15:8], alu_res[lane+2][port][15:8], //take byte 1, from ALU0,1,2,3
						   alu_res[lane+1][port][15:8], alu_res[lane+0][port][15:8]};
	      else if (alu_write_sew[lane+1][port]==2'b01)
		alu_res_reordered[lane+1][port] = {2{alu_res[lane+1][port][15:8], alu_res[lane+0][port][15:8]}}; //take byte 1, from ALU0,1
	      else
		alu_res_reordered[lane+1][port] = {4{alu_res[lane+1][port][7:0]}}; //take byte 0 FROM ALU1

	      if (alu_write_sew[lane+2][port]==2'b10)
		alu_res_reordered[lane+2][port] = {alu_res[lane+3][port][23:16], alu_res[lane+2][port][23:16],//take byte 2, from ALU0,1,2,3
						   alu_res[lane+1][port][23:16], alu_res[lane+0][port][23:16]};
	      else if (alu_write_sew[lane+2][port]==2'b01)
		alu_res_reordered[lane+2][port] = {2{alu_res[lane+3][port][7:0], alu_res[lane+2][port][7:0]}};//take byte 0, from ALU2,3
	      else
		alu_res_reordered[lane+2][port] = {4{alu_res[lane+2][port][7:0]}}; //take byte 0 FROM ALU2

	      if (alu_write_sew[lane+3][port]==2'b10)
		alu_res_reordered[lane+3][port] = {alu_res[lane+3][port][31:24], alu_res[lane+2][port][31:24],//take byte 3, from ALU0,1,2,3
					   alu_res[lane+1][port][31:24], alu_res[lane+0][port][31:24]};
	      else if (alu_write_sew[lane+3][port]==2'b01)
		alu_res_reordered[lane+3][port] = {2{alu_res[lane+3][port][15:8], alu_res[lane+2][port][15:8]}}; //take byte 1, from ALU2,3
	      else
		alu_res_reordered[lane+3][port] = {4{alu_res[lane+3][port][7:0]}}; //take byte 0 FROM ALU3
	   end 
      end            
   end
   


   
   logic [VLANE_NUM-1:0][$clog2(VLANE_NUM)-1:0] lane_sel;
   // each lane has mux8_1 for slide_data_input. We replicate byte to be shifted 4 times and with bwe we chose
   // where to write it.
   always_comb
   begin            
      for (int lane=0; lane<VLANE_NUM; lane++)
      begin
	 if(up_down_slide_il)
	   lane_sel[lane] = ~slide_data_mux_sel+lane+1;
	 else
	   lane_sel[lane] = slide_data_mux_sel+lane;

	 slide_data_input[lane] = {4{slide_data_output[lane_sel[lane]][slide_read_byte_sel_reg[VRF_DELAY-2]*8 +: 8]}};  
      end      
   end

always_comb begin
/* -----\/----- EXCLUDED -----\/-----

    // Left shift : 1 -> 0
    if(up_down_slide_il) begin                  
        for(int i = 0; i < VLANE_NUM - 1; i++) begin
            slide_data_input[i] = slide_data_output[i + 1];    
        end
        slide_data_input[VLANE_NUM - 1] = slide_data_output[0];
    end
    // Right shift : 0 -> 1
    else begin
        for(int i = 1; i < VLANE_NUM; i++) begin
            slide_data_input[i] = slide_data_output[i - 1];   
        end
        slide_data_input[0] = slide_data_output[VLANE_NUM - 1];
    end
 -----/\----- EXCLUDED -----/\----- */

    for(int i = 0; i < W_PORTS_NUM; i++) begin
        for(int j = 1; j < VLANE_NUM; j++) begin
            lane_result[i][j - 1] = ALU_output[j][i];
        end
    end
end


endmodule
