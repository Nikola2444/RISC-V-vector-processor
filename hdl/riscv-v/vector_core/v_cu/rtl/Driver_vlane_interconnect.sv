module Driver_vlane_interconnect
#(
    parameter W_PORTS_NUM = 4,
    parameter R_PORTS_NUM = 8,
    parameter VLANE_NUM = 4,
    parameter MEM_DEPTH = 512,
    parameter ALU_OPMODE = 6,
    parameter MAX_VL_PER_LANE = 4 * 8 * 8
)
(
    input clk_i,
    input rst_i,
    
    // Config signals
    input logic [W_PORTS_NUM - 1 : 0][1 : 0] vsew_i,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][1 : 0] vsew_o,
    input logic [W_PORTS_NUM - 1 : 0][1 : 0] wdata_width_i,
    output logic [VLANE_NUM-1:0][W_PORTS_NUM - 1 : 0][1 : 0] wdata_width_o,
    
    // Read data valid for ALU
    input logic [W_PORTS_NUM - 1 : 0][VLANE_NUM - 1 : 0] read_data_valid_i,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] read_data_valid_o,
    
    // VRF signals
    input logic [W_PORTS_NUM - 1 : 0] vrf_ren_i,                                                                        // READ RELATED SIGNAL
    input logic [W_PORTS_NUM - 1 : 0] vrf_oreg_ren_i,                                                                   // READ RELATED SIGNAL
    input logic [W_PORTS_NUM - 2 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_waddr_partial_i,                                   // Write address for the N - 1 out of N instructions  
    input logic [VLANE_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_waddr_complete_i,                                    // Just for the complete sublane driver
    input logic [W_PORTS_NUM - 1 : 0][2 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_raddr_i,                                    // READ RELATED SIGNAL, UPDATED
    input logic [W_PORTS_NUM - 2 : 0][VLANE_NUM - 1 : 0][3 : 0] vrf_bwen_partial_i,                                     // Byte write enable for the N - 1 out of N instructions
    input logic [VLANE_NUM - 1 : 0][3 : 0] vrf_bwen_complete_i,                                                         // Just for the complete sublane driver
    output logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0] vrf_ren_o,                                                    // HAS TO BE DONE
    output logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0] vrf_oreg_ren_o,                                               // HAS TO BE DONE
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_waddr_o,
    output logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_raddr_o,                       // HAS TO BE DONE
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][3 : 0] vrf_bwen_o,
    
    // VMRF
    input logic [W_PORTS_NUM - 1 : 0][$clog2(MAX_VL_PER_LANE) - 1 : 0] vmrf_addr_i,   
    input logic [W_PORTS_NUM - 1 : 0] vmrf_wen_i,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][$clog2(MAX_VL_PER_LANE) - 1 : 0] vmrf_addr_o,   
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] vmrf_wen_o,
    
    // Load and Store
    input logic [VLANE_NUM - 1 : 0][31 : 0] load_data_i,                                                                // UPDATED
    output logic [VLANE_NUM - 1 : 0][31 : 0] load_data_o,                                                               // UPDATED
    
    input logic [W_PORTS_NUM - 1 : 0] store_data_valid_i,
    input logic [W_PORTS_NUM - 1 : 0] store_load_index_valid_i,
    input logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] store_data_mux_sel_i,
    input logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] store_load_index_mux_sel_i,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] store_data_valid_o,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] store_load_index_valid_o,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] store_data_mux_sel_o,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] store_load_index_mux_sel_o,
    
    // ALU
    input logic [W_PORTS_NUM - 1 : 0][1 : 0] op2_sel_i,
    input logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] op3_sel_i,
    input logic [W_PORTS_NUM - 1 : 0][31 : 0] ALU_x_data_i,
    input logic [W_PORTS_NUM - 1 : 0][4 : 0] ALU_imm_i,
    input logic [W_PORTS_NUM - 1 : 0][31 : 0] ALU_reduction_data_i,
    input logic [W_PORTS_NUM - 1 : 0][ALU_OPMODE - 1 : 0] ALU_ctrl_i,
    input logic [W_PORTS_NUM - 1 : 0] reduction_op_i,
    input logic alu_en_32bit_mul_i,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][1 : 0] op2_sel_o,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] op3_sel_o,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][31 : 0] ALU_x_data_o,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][4 : 0] ALU_imm_o,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][31 : 0] ALU_reduction_data_o,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][ALU_OPMODE - 1 : 0] ALU_ctrl_o,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0]                     reduction_op_o,
    output logic [VLANE_NUM - 1 : 0] alu_en_32bit_mul_o,
    
    // Slide signals - THIS SIGNALS ARE COMING FROM ONLY ONE DRIVER
    input logic up_down_slide_i,
    input logic [W_PORTS_NUM - 1 : 0] request_write_control_i,
    output logic [VLANE_NUM - 1 : 0] up_down_slide_o,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] request_write_control_o,                                      // UPDATED
    
    // Misc signals
    input logic [W_PORTS_NUM - 1 : 0][1 : 0] el_extractor_i,                                                            // READ RELATED SIGNAL
    input logic [W_PORTS_NUM - 1 : 0] vector_mask_i,
    input logic [W_PORTS_NUM - 1 : 0][1 : 0] write_data_sel_i,
    output logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0][1 : 0] el_extractor_o,                                        // HAS TO BE DONE
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0] vector_mask_o,
    output logic [VLANE_NUM - 1 : 0][W_PORTS_NUM - 1 : 0][1 : 0] write_data_sel_o,
    
    // A group signals determining where to route read related signals
    input logic [R_PORTS_NUM - 1 : 0][$clog2(W_PORTS_NUM) - 1 : 0] read_port_allocation_i,                              // 0 - RP0, 1 RP1, ...
    input logic [R_PORTS_NUM - 1 : 0] primary_read_data_i 
    
);

logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0] primary_vrf_ren;
logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0] primary_vrf_oreg_ren;
logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] primary_vrf_raddr;
logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0][1 : 0] primary_el_extractor;

logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0] secondary_vrf_ren;
logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0] secondary_vrf_oreg_ren;
logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] secondary_vrf_raddr;
logic [VLANE_NUM - 1 : 0][R_PORTS_NUM - 1 : 0][1 : 0] secondary_el_extractor;

// Registers for inputs
typedef struct packed
{
    // Config signals
    logic [W_PORTS_NUM - 1 : 0][1 : 0] vsew;
    logic [W_PORTS_NUM - 1 : 0][1 : 0] wdata_width;

    // Read data valid for ALU
    logic [W_PORTS_NUM - 1 : 0][VLANE_NUM - 1 : 0] read_data_valid;

    // VRF signals
    logic [W_PORTS_NUM - 1 : 0] vrf_ren;
    logic [W_PORTS_NUM - 1 : 0] vrf_oreg_ren;
    logic [W_PORTS_NUM - 2 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_waddr_partial;
    logic [VLANE_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_waddr_complete;
    logic [W_PORTS_NUM - 1 : 0][2 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_raddr;
    logic [W_PORTS_NUM - 2 : 0][VLANE_NUM - 1 : 0][3 : 0] vrf_bwen_partial;
    logic [VLANE_NUM - 1 : 0][3 : 0] vrf_bwen_complete;
    
    // VMRF
    logic [W_PORTS_NUM - 1 : 0][$clog2(MAX_VL_PER_LANE) - 1 : 0] vmrf_addr;
    logic [W_PORTS_NUM - 1 : 0] vmrf_wen;
    
    // Load and Store signals
    logic [VLANE_NUM - 1 : 0][31 : 0] load_data;
    logic [W_PORTS_NUM - 1 : 0] store_data_valid;
    logic [W_PORTS_NUM - 1 : 0] store_load_index_valid;
    logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] store_data_mux_sel;
    logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] store_load_index_mux_sel;   
    
    // ALU
    logic [W_PORTS_NUM - 1 : 0][1 : 0] op2_sel;
    logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] op3_sel;
    logic [W_PORTS_NUM - 1 : 0][31 : 0] ALU_x_data;
    logic [W_PORTS_NUM - 1 : 0][4 : 0] ALU_imm;
    logic [W_PORTS_NUM - 1 : 0][31 : 0] ALU_reduction_data;
    logic [W_PORTS_NUM - 1 : 0][ALU_OPMODE - 1 : 0] ALU_ctrl;
    logic [W_PORTS_NUM - 1 : 0]                     reduction_op;
    logic alu_en_32bit_mul;
    
    // Slide signals - THIS SIGNALS ARE COMING FROM ONLY ONE DRIVER
    logic up_down_slide;
    logic [W_PORTS_NUM - 1 : 0] request_write_control; 
    
    // Misc signals
    logic [W_PORTS_NUM - 1 : 0][1 : 0] el_extractor;
    logic [W_PORTS_NUM - 1 : 0] vector_mask;
    logic [W_PORTS_NUM - 1 : 0][1 : 0] write_data_sel;
    
}input_layer;

input_layer input_reg, input_next;

/////////////////////////////////////////////////////////////
// Assigments

// Config signals
assign input_next.vsew = vsew_i;
assign input_next.wdata_width = wdata_width_i;

// Read data valid for ALU
assign input_next.read_data_valid = read_data_valid_i;

// VRF signals
assign input_next.vrf_ren = vrf_ren_i;
assign input_next.vrf_oreg_ren = vrf_oreg_ren_i;
assign input_next.vrf_waddr_partial = vrf_waddr_partial_i;
assign input_next.vrf_waddr_complete = vrf_waddr_complete_i;
assign input_next.vrf_raddr = vrf_raddr_i;
assign input_next.vrf_bwen_partial = vrf_bwen_partial_i;
assign input_next.vrf_bwen_complete = vrf_bwen_complete_i;

// VMRF
assign input_next.vmrf_addr = vmrf_addr_i;
assign input_next.vmrf_wen = vmrf_wen_i;

// Load and Store signals
assign input_next.load_data = load_data_i;
assign input_next.store_data_valid = store_data_valid_i;
assign input_next.store_load_index_valid = store_load_index_valid_i;
assign input_next.store_data_mux_sel = store_data_mux_sel_i;
assign input_next.store_load_index_mux_sel = store_load_index_mux_sel_i;   

// ALU
assign input_next.op2_sel = op2_sel_i;
assign input_next.op3_sel = op3_sel_i;
assign input_next.ALU_x_data = ALU_x_data_i;
assign input_next.ALU_imm = ALU_imm_i;
assign input_next.ALU_reduction_data = ALU_reduction_data_i;
assign input_next.ALU_ctrl = ALU_ctrl_i;
assign input_next.reduction_op = reduction_op_i;
assign input_next.alu_en_32bit_mul = alu_en_32bit_mul_i;

// Slide signals - THIS SIGNALS ARE COMING FROM ONLY ONE DRIVER
assign input_next.up_down_slide = up_down_slide_i;
assign input_next.request_write_control = request_write_control_i; 

// Misc signals
assign input_next.el_extractor = el_extractor_i;
assign input_next.vector_mask = vector_mask_i;
assign input_next.write_data_sel = write_data_sel_i;
/////////////////////////////////////////////////////////////

generate
    for(genvar i = 0; i < VLANE_NUM; i++) begin
        
        assign up_down_slide_o[i] = input_reg.up_down_slide;
        assign request_write_control_o[i] = input_reg.request_write_control;
        assign alu_en_32bit_mul_o[i] = input_reg.alu_en_32bit_mul;
        assign load_data_o[i] = input_reg.load_data[i];
        assign vsew_o[i] = input_reg.vsew;
        assign wdata_width_o[i] = input_reg.wdata_width;

    
        for(genvar j = 0; j < W_PORTS_NUM; j++) begin
            assign read_data_valid_o[i][j] = input_reg.read_data_valid[j][i];
            assign vmrf_addr_o[i][j] = input_reg.vmrf_addr[j];
            assign vmrf_wen_o[i][j] = input_reg.vmrf_wen[j];
            assign store_data_valid_o[i][j] = input_reg.store_data_valid[j];
            assign store_load_index_valid_o[i][j] = input_reg.store_load_index_valid[j];
            assign store_data_mux_sel_o[i][j] = input_reg.store_data_mux_sel[j];
            assign store_load_index_mux_sel_o[i][j] = input_reg.store_load_index_mux_sel[j];
            assign op2_sel_o[i][j] = input_reg.op2_sel[j];
            assign op3_sel_o[i][j] = input_reg.op3_sel[j];
            assign ALU_x_data_o[i][j] = input_reg.ALU_x_data[j];
            assign ALU_imm_o[i][j] = input_reg.ALU_imm[j];
            assign ALU_reduction_data_o[i][j] = input_reg.ALU_reduction_data[j];
            assign ALU_ctrl_o[i][j] = input_reg.ALU_ctrl[j];
            assign reduction_op_o[i][j] = input_reg.reduction_op[j];
            assign vector_mask_o[i][j] = input_reg.vector_mask[j];
            assign write_data_sel_o[i][j] = input_reg.write_data_sel[j];
            
            // Write address and byte write enable
            if(j == 0) begin
                assign vrf_waddr_o[i][0] = input_reg.vrf_waddr_complete[i];
                assign vrf_bwen_o[i][0] = input_reg.vrf_bwen_complete[i];
            end
            else begin
                assign vrf_waddr_o[i][j] = input_reg.vrf_waddr_partial[j - 1];
                assign vrf_bwen_o[i][j] = input_reg.vrf_bwen_partial[j - 1][i];
            end
            
            assign primary_vrf_raddr[i][2 * j] = input_reg.vrf_raddr[j][0];
            assign primary_vrf_raddr[i][2 * j + 1] = input_reg.vrf_raddr[j][1];
            
        end
        
        for(genvar k = 0; k < R_PORTS_NUM; k++) begin
            
            assign primary_vrf_ren[i][k] = input_reg.vrf_ren[k / 2];              // R0, R1 -> W0, R2, R3 -> W1, R4, R5 -> W3, ... 
            assign primary_vrf_oreg_ren[i][k] = input_reg.vrf_oreg_ren[k / 2];
            assign primary_el_extractor[i][k] = input_reg.el_extractor[k / 2];
            
            assign secondary_vrf_ren[i][k] = input_reg.vrf_ren[read_port_allocation_i[k]];
            assign secondary_vrf_oreg_ren[i][k] = input_reg.vrf_oreg_ren[read_port_allocation_i[k]];
            assign secondary_vrf_raddr[i][k] = input_reg.vrf_raddr[read_port_allocation_i[k]][2];
            assign secondary_el_extractor[i][k] = input_reg.el_extractor[read_port_allocation_i[k]];
            
            assign vrf_ren_o[i][k] = (primary_read_data_i[k] == 1) ? primary_vrf_ren[i][k] : secondary_vrf_ren[i][k];
            assign vrf_oreg_ren_o[i][k] = (primary_read_data_i[k] == 1) ? primary_vrf_oreg_ren[i][k] : secondary_vrf_oreg_ren[i][k];
            assign vrf_raddr_o[i][k] = (primary_read_data_i[k] == 1) ? primary_vrf_raddr[i][k] : secondary_vrf_raddr[i][k];
            assign el_extractor_o[i][k] = (primary_read_data_i[k] == 1) ? primary_el_extractor[i][k] : secondary_el_extractor[i][k];
            
        end
        
    end 
endgenerate;
/////////////////////////////////////////////////////////////

always_ff@(posedge clk_i) begin
    if(!rst_i) begin
        input_reg <= 0;
    end
    else begin
        input_reg <= input_next;
    end
end

endmodule
