/*
    How is load implented?
*/

`timescale 1ns / 1ps

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
    
    // Control Flow signals
    input logic [W_PORTS_NUM - 1 : 0][$clog2(INST_TYPE_NUM) - 1 : 0] inst_type_i,
    
    // Handshaking
    input [W_PORTS_NUM - 1 : 0] start_i,
    output logic [W_PORTS_NUM - 1 : 0] ready_o,
    
    // Inst timing signals
    input logic [W_PORTS_NUM - 1 : 0][$clog2(MAX_VL_PER_LANE) - 1 : 0] inst_delay_i,
    
    // VRF signals
    input logic [W_PORTS_NUM - 1 : 0] vrf_ren_i,                                                
    input logic [W_PORTS_NUM - 1 : 0] vrf_oreg_ren_i,
    input logic [W_PORTS_NUM - 1 : 0][8 * $clog2(MEM_DEPTH) - 1 : 0] vrf_starting_waddr_i,
    input logic [W_PORTS_NUM - 1 : 0][8 * $clog2(MEM_DEPTH) - 1 : 0] vrf_starting_raddr_i,
    input logic [W_PORTS_NUM - 1 : 0][1 : 0] wdata_width_i,    
    
    // Load and Store signals
    input logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][31 : 0] load_data_i,
    input logic [W_PORTS_NUM - 1 : 0] load_ready_i,
    input logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] store_data_mux_sel_i,
    input logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] store_load_index_mux_sel_i,
    
    // ALU
    input logic [W_PORTS_NUM - 1 : 0][1 : 0] op2_sel_i,
    input logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] op3_sel_i,
    input logic [W_PORTS_NUM - 1 : 0][31 : 0] ALU_x_data_i,
    input logic [W_PORTS_NUM - 1 : 0][4 : 0] ALU_imm_i,
    input logic [W_PORTS_NUM - 1 : 0][ALU_OPMODE - 1 : 0] ALU_opmode_i,
    
    // Slide signals - THIS SIGNALS ARE COMING FROM ONLY ONE DRIVER
    input logic up_down_slide_i,
    input logic [31 : 0] slide_amount_i,
    
    // Misc signals
    input logic [W_PORTS_NUM - 1 : 0] vector_mask_i,
    // input logic [W_PORTS_NUM - 1 : 0] rdata_sign_i,
    // input logic [W_PORTS_NUM - 1 : 0] imm_sign_i,
    
    // A group signals determining where to route read related signals
    input logic [R_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] read_port_allocation_i,                               // 0 - RP0, 1 RP1, ... 
    
    // Vlane outputs
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][31 : 0] store_data_o,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][31 : 0] store_load_index_o,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] store_data_valid_o,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] store_load_index_valid_o
    
);

////////////////////////////////////////////////////////////////////////////////////
// Connecting signals

// Off lane signals for slides and reductions
logic [VLANE_NUM - 1 : 0][31 : 0] slide_data_input, slide_data_output;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][31 : 0] ALU_output;
logic [W_PORTS_NUM - 1 : 0][VLANE_NUM - 2 : 0][31 : 0] lane_result;

// Driver - Interconnect signals
logic [W_PORTS_NUM - 1 : 0][VLANE_NUM - 1 : 0] read_data_valid_di;
logic [W_PORTS_NUM - 1 : 0] vrf_ren_di;
logic [W_PORTS_NUM - 1 : 0] vrf_oreg_ren_di;
logic [W_PORTS_NUM - 2 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_waddr_partial_di;
logic [VLANE_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_waddr_complete_di;
logic [W_PORTS_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_raddr_di;
logic [W_PORTS_NUM - 2 : 0][3 : 0] vrf_bwen_partial_di;
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
logic up_down_slide_di;
logic request_write_control_di;
logic [W_PORTS_NUM - 1 : 0][1 : 0] el_extractor_di;
logic [W_PORTS_NUM - 1 : 0] vector_mask_di;
logic [W_PORTS_NUM - 1 : 0][1 : 0] write_data_sel_di;
// logic [W_PORTS_NUM - 1 : 0] rdata_sign_di;
// logic [W_PORTS_NUM - 1 : 0] imm_sign_di;

// Interconnect - Vector lane signals
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] read_data_valid_il;
logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0] vrf_ren_il;
logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0] vrf_oreg_ren_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_waddr_il;
logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_raddr_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][3 : 0] vrf_bwen_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][$clog2(MAX_VL_PER_LANE) - 1 : 0] vmrf_addr_il;   
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] vmrf_wen_il;
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
logic [VLANE_NUM - 1 : 0] up_down_slide_il;
logic [VLANE_NUM - 1 : 0] request_write_control_il;
logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0][1 : 0] el_extractor_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] vector_mask_il;
logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][1 : 0] write_data_sel_il;
// logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0] rdata_sign_il;
// logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] imm_sign_il;
////////////////////////////////////////////////////////////////////////////////////

generate
    for(genvar i = 0; i < W_PORTS_NUM; i++) begin
        if(i == 0) begin
            Complete_sublane_driver
            #(
                .MEM_DEPTH(MEM_DEPTH),
                .MAX_VL_PER_LANE(MAX_VL_PER_LANE),
                .VREG_LOC_PER_LANE(VREG_LOC_PER_LANE),
                .R_PORTS_NUM(R_PORTS_NUM),
                .INST_TYPE_NUM(INST_TYPE_NUM),
                .VLANE_NUM(VLANE_NUM),
                .ALU_OPMODE(ALU_OPMODE),
                .STRIDE_ENABLE("YES")
            )
            Complete_sublane_driver_inst
            (
                .clk_i(clk_i),
                .rst_i(rst_i),
                .vl_i(vl_i),
                .vsew_i(vsew_i),
                .inst_type_i(inst_type_i[0]),
                .start_i(start_i[0]),
                .ready_o(ready_o[0]),
                .inst_delay_i(inst_delay_i[0]),
                .read_data_valid_o(read_data_valid_di[0]),
                .vrf_ren_i(vrf_ren_i[0]),
                .vrf_oreg_ren_i(vrf_oreg_ren_i[0]),
                .vrf_starting_waddr_i(vrf_starting_waddr_i[0]),
                .vrf_starting_raddr_i(vrf_starting_raddr_i[0]),
                .wdata_width_i(wdata_width_i[0]),
                .vrf_ren_o(vrf_ren_di[0]),
                .vrf_oreg_ren_o(vrf_oreg_ren_di[0]),
                .vrf_waddr_o(vrf_waddr_complete_di),
                .vrf_raddr_o(vrf_raddr_di[0]),
                .vrf_bwen_o(vrf_bwen_complete_di),
                .vmrf_addr_o(vmrf_addr_di[0]),   
                .vmrf_wen_o(vmrf_wen_di[0]),
                .load_ready_i(load_ready_i[0]),
                .store_data_mux_sel_i(store_data_mux_sel_i[0]),
                .store_load_index_mux_sel_i(store_load_index_mux_sel_i[0]),
                .store_data_valid_o(store_data_valid_di[0]),
                .store_load_index_valid_o(store_load_index_valid_di[0]),
                .store_data_mux_sel_o(store_data_mux_sel_di[0]),
                .store_load_index_mux_sel_o(store_load_index_mux_sel_di[0]),
                .lane_result_i(lane_result[0]),
                .op2_sel_i(op2_sel_i[0]),
                .op3_sel_i(op3_sel_i[0]),
                .ALU_x_data_i(ALU_x_data_i[0]),
                .ALU_imm_i(ALU_imm_i[0]),
                .ALU_opmode_i(ALU_opmode_i[0]),
                .op2_sel_o(op2_sel_di[0]),
                .op3_sel_o(op3_sel_di[0]),
                .ALU_x_data_o(ALU_x_data_di[0]),
                .ALU_imm_o(ALU_imm_di[0]),
                .ALU_reduction_data_o(ALU_reduction_data_di[0]),
                .ALU_ctrl_o(ALU_ctrl_di[0]),                               
                .up_down_slide_i(up_down_slide_i),
                .slide_amount_i(slide_amount_i),
                .up_down_slide_o(up_down_slide_di),                                         // 1 for left and 0 for right
                .request_write_control_o(request_write_control_di),
                .vector_mask_i(vector_mask_i[0]),
                // .rdata_sign_i(rdata_sign_i[0]),
                // .imm_sign_i(imm_sign_i[0]),
                .el_extractor_o(el_extractor_di[0]),
                .vector_mask_o(vector_mask_di[0]),
                .write_data_sel_o(write_data_sel_di[0])
                // .rdata_sign_o(rdata_sign_di[0]),
                // .imm_sign_o(imm_sign_di[0]) 
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
                .ALU_OPMODE(ALU_OPMODE),
                .STRIDE_ENABLE("NO")
            )
            Partial_sublane_driver_inst
            (
                .clk_i(clk_i),
                .rst_i(rst_i),
                .vl_i(vl_i),
                .vsew_i(vsew_i),
                .inst_type_i(inst_type_i[i]),
                .start_i(start_i[i]),
                .ready_o(ready_o[i]),
                .inst_delay_i(inst_delay_i[i]),
                .read_data_valid_o(read_data_valid_di[i]),
                .vrf_ren_i(vrf_ren_i[i]),
                .vrf_oreg_ren_i(vrf_oreg_ren_i[i]),
                .vrf_starting_waddr_i(vrf_starting_waddr_i[i]),
                .vrf_starting_raddr_i(vrf_starting_raddr_i[i]),
                .wdata_width_i(wdata_width_i[i]),
                .vrf_ren_o(vrf_ren_di[i]),
                .vrf_oreg_ren_o(vrf_oreg_ren_di[i]),
                .vrf_waddr_o(vrf_waddr_partial_di[i - 1]),
                .vrf_raddr_o(vrf_raddr_di[i]),
                .vrf_bwen_o(vrf_bwen_partial_di[i - 1]),
                .vmrf_addr_o(vmrf_addr_di[i]),   
                .vmrf_wen_o(vmrf_wen_di[i]),
                .load_ready_i(load_ready_i[i]),
                .store_data_mux_sel_i(store_data_mux_sel_i[i]),
                .store_load_index_mux_sel_i(store_load_index_mux_sel_i[i]),
                .store_data_valid_o(store_data_valid_di[i]),
                .store_load_index_valid_o(store_load_index_valid_di[i]),
                .store_data_mux_sel_o(store_data_mux_sel_di[i]),
                .store_load_index_mux_sel_o(store_load_index_mux_sel_di[i]),
                .lane_result_i(lane_result[i]),
                .op2_sel_i(op2_sel_i[i]),
                .op3_sel_i(op3_sel_i[i]),
                .ALU_x_data_i(ALU_x_data_i[i]),
                .ALU_imm_i(ALU_imm_i[i]),
                .ALU_opmode_i(ALU_opmode_i[i]),
                .op2_sel_o(op2_sel_di[i]),
                .op3_sel_o(op3_sel_di[i]),
                .ALU_x_data_o(ALU_x_data_di[i]),
                .ALU_imm_o(ALU_imm_di[i]),
                .ALU_reduction_data_o(ALU_reduction_data_di[i]),
                .ALU_ctrl_o(ALU_ctrl_di[i]),                               
                .vector_mask_i(vector_mask_i[i]),
                // .rdata_sign_i(rdata_sign_i[i]),
                // .imm_sign_i(imm_sign_i[i]),
                .el_extractor_o(el_extractor_di[i]),
                .vector_mask_o(vector_mask_di[i]),
                .write_data_sel_o(write_data_sel_di[i])
                // .rdata_sign_o(rdata_sign_di[i]),
                // .imm_sign_o(imm_sign_di[i]) 
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
    .op2_sel_o(op2_sel_il),
    .op3_sel_o(op3_sel_il),
    .ALU_x_data_o(ALU_x_data_il),
    .ALU_imm_o(ALU_imm_il),
    .ALU_reduction_data_o(ALU_reduction_data_il),
    .ALU_ctrl_o(ALU_ctrl_il),
    .up_down_slide_i(up_down_slide_di),
    .request_write_control_i(request_write_control_di),
    .up_down_slide_o(up_down_slide_il),
    .request_write_control_o(request_write_control_il),
    .el_extractor_i(el_extractor_di),
    .vector_mask_i(vector_mask_di),
    .write_data_sel_i(write_data_sel_di),
    // .rdata_sign_i(rdata_sign_di),
    // .imm_sign_i(imm_sign_di),
    .el_extractor_o(el_extractor_il),
    .vector_mask_o(vector_mask_il),
    .write_data_sel_o(write_data_sel_il),
    // .rdata_sign_o(rdata_sign_il),
    // .imm_sign_o(imm_sign_il),
    .read_port_allocation_i(read_port_allocation_i)
    
);

generate
    for(genvar i = 0; i < VLANE_NUM; i++) begin
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
            .MEM_WIDTH(MEM_WIDTH)
        )
        Vector_Lane_inst
        (
            .clk_i(clk_i),
            .clk2_i(clk2_i),
            .rst_i(rst_i),
            .vsew_i(vsew_i[1 : 0]),
            .vrf_ren_i(vrf_ren_il[i]),
            .vrf_oreg_ren_i(vrf_oreg_ren_il[i]),
            .vrf_raddr_i(vrf_raddr_il[i]),
            .vrf_waddr_i(vrf_waddr_il[i]), 
            .vrf_bwen_i(vrf_bwen_il[i]),
            .load_data_i(load_data_i[i]),
            .slide_data_i(slide_data_input[i]),
            .slide_data_o(slide_data_output[i]),
            .vmrf_addr_i(vmrf_addr_il[i]),
            .vmrf_wen_i(vmrf_wen_il[i]),
            .el_extractor_i(el_extractor_il[i]),
            .vector_mask_i(vector_mask_il[i]),
            .write_data_sel_i(write_data_sel_il[i]),
            // .rdata_sign_i(rdata_sign_il[i]),
            .request_control_i(request_write_control_il[i]),
            .store_data_valid_o(store_data_valid_o[i]),
            .store_data_valid_i(store_data_valid_il[i]),
            .store_load_index_valid_o(store_load_index_valid_o[i]),
            .store_load_index_valid_i(store_load_index_valid_il[i]),
            .store_data_o(store_data_o[i]),
            .store_load_index_o(store_load_index_o[i]),
            .store_data_mux_sel_i(store_data_mux_sel_il[i]),
            .store_load_index_mux_sel_i(store_load_index_mux_sel_il[i]),
            .op2_sel_i(op2_sel_il[i]),
            .op3_sel_i(op3_sel_il[i]),
            .ALU_x_data_i(ALU_x_data_il[i]),
            .ALU_imm_i(ALU_imm_il[i]),
            // .imm_sign_i(imm_sign_il[i]),
            .ALU_reduction_data_i(ALU_reduction_data_il[i]),
            .ALU_ctrl_i(ALU_ctrl_il[i]),
            .read_data_valid_i(read_data_valid_il[i]),
            .ALU_output_o(ALU_output[i])
        );
    end
endgenerate;

always_comb begin
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
    
    for(int i = 0; i < W_PORTS_NUM; i++) begin
        for(int j = 1; j < VLANE_NUM; j++) begin
            lane_result[i][j - 1] = ALU_output[j][i];
        end
    end
end

endmodule
