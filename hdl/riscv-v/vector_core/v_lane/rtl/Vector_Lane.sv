`timescale 1ns / 1ps

module Vector_Lane
    #(
        parameter R_PORTS_NUM = 2,
        parameter W_PORTS_NUM = 1,
        parameter MEM_DEPTH = 1024,
        parameter MAX_VL_PER_LANE = 32,
        parameter ALU_CTRL_WIDTH = 5
    )
    (
        input clk_i,
        input rst_i,
        
        // VRF
        input logic [R_PORTS_NUM - 1 : 0] vrf_ren_i,
        input logic [R_PORTS_NUM - 1 : 0] vrf_oreg_ren_i,
        input logic [R_PORTS_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_raddr_i,
        input logic [W_PORTS_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_waddr_i, 
        input logic [W_PORTS_NUM - 1 : 0][3 : 0] vrf_bwen_i,
        
        // Options for write data
        input logic [W_PORTS_NUM - 1 : 0][31 : 0] load_data_i,
        input logic [W_PORTS_NUM - 1 : 0][31 : 0] slide_data_i,
        
        // Vector mask register file
        input logic [W_PORTS_NUM - 1 : 0][$clog2(MAX_VL_PER_LANE) - 1 : 0] vmrf_addr_i,
        input logic [W_PORTS_NUM - 1 : 0] vmrf_wen_i,
        
        // Other control signals
        input logic [R_PORTS_NUM - 1 : 0][1 : 0] el_extractor_i,
        input logic [1 : 0] vsew_i,
        input logic [W_PORTS_NUM - 1 : 0] vector_mask_i,
        input logic [W_PORTS_NUM - 1 : 0][1 : 0] write_data_sel_i,
        input logic [R_PORTS_NUM - 1 : 0] rdata_sign_i,
        
        // Store/Load signals
        output logic [W_PORTS_NUM - 1 : 0] store_data_valid_o,
        input logic [W_PORTS_NUM - 1 : 0] store_data_valid_i,
        output logic [W_PORTS_NUM - 1 : 0] store_load_index_valid_o,
        input logic [W_PORTS_NUM - 1 : 0] store_load_index_valid_i,
        output logic [W_PORTS_NUM - 1 : 0][31 : 0] store_data_o,
        output logic [W_PORTS_NUM - 1 : 0][31 : 0] store_load_index_o,
        input logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] store_data_mux_sel_i,
        input logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] store_load_index_mux_sel_i,
        
        // ALU signals
        input logic [W_PORTS_NUM - 1 : 0] op1_sel_i,
        input logic [W_PORTS_NUM - 1 : 0][1 : 0] op2_sel_i,
        input logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] op3_sel_i,
        input logic [W_PORTS_NUM - 1 : 0][31 : 0] non_lane_data_i,
        input logic [W_PORTS_NUM - 1 : 0][31 : 0] ALU_x_data_i,
        input logic [W_PORTS_NUM - 1 : 0][4 : 0] ALU_imm_i,
        input logic [W_PORTS_NUM - 1 : 0] imm_sign_i,
        input logic [W_PORTS_NUM - 1 : 0][31 : 0] ALU_reduction_data_i,
        logic [W_PORTS_NUM - 1 : 0][ALU_CTRL_WIDTH - 1 : 0] ALU_ctrl_i

    );    
    
// Generate variable    
// ------------------------------------------ //
genvar i_gen, j_gen;
// ------------------------------------------ //

// VRF read port signals
// ------------------------------------------ //
logic [R_PORTS_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_raddr;
logic [R_PORTS_NUM - 1 : 0][31 : 0] vrf_rdata;
// ------------------------------------------ //

// VRF write port signals
// ------------------------------------------ //
logic [W_PORTS_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_waddr;
logic [W_PORTS_NUM - 1 : 0][31 : 0] vrf_wdata_mux;
logic [W_PORTS_NUM - 1 : 0][31 : 0] vrf_wdata;
logic [W_PORTS_NUM - 1 : 0][3 : 0] vrf_bwen;
// ------------------------------------------ //

// Read data preparation logic 
// ------------------------------------------ //
logic [R_PORTS_NUM - 1 : 0][7 : 0] read_data_byte_mux;
logic [R_PORTS_NUM - 1 : 0][1 : 0] read_data_byte_mux_sel;                                          // # Control signal # DONE
logic [R_PORTS_NUM - 1 : 0][15 : 0] read_data_hw_mux;
logic [R_PORTS_NUM - 1 : 0] read_data_hw_mux_sel;                                                   // # Control signal # DONE
logic [R_PORTS_NUM - 1 : 0][31 : 0] read_data_byte_us_mux;
logic [R_PORTS_NUM - 1 : 0] read_data_byte_us_mux_sel;                                              // # Control signal # DONE
logic [R_PORTS_NUM - 1 : 0][31 : 0] read_data_hw_us_mux;
logic [R_PORTS_NUM - 1 : 0] read_data_hw_us_mux_sel;                                                // # Control signal # DONE
logic [R_PORTS_NUM - 1 : 0][31 : 0] read_data_mux;
logic [R_PORTS_NUM - 1 : 0][1 : 0] read_data_mux_sel;                                               // # Control signal # DONE
logic [R_PORTS_NUM - 1 : 0][3 * 32 - 1 : 0] read_data_prep_reg, read_data_prep_next;
// ------------------------------------------ //

// Read address logic
// ------------------------------------------ //
logic [R_PORTS_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] read_addr_mux;
logic [R_PORTS_NUM - 1 : 0][1 : 0] read_addr_mux_sel;                                               // # Control signal # DONE
// ------------------------------------------ //                                           

// Write address logic
// ------------------------------------------ //
logic [W_PORTS_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] write_addr_mux;
logic [W_PORTS_NUM - 1 : 0][1 : 0] write_addr_mux_sel;                                              // # Control signal # DONE
logic [W_PORTS_NUM - 1 : 0][1 : 0] write_data_mux_sel;                                              // # Control signal # DONE
// ------------------------------------------ //

// Pipeline registers
// ------------------------------------------ //
// VRF write pipeline register
// vrf_waddr | vrf_wdata | bwen
logic [W_PORTS_NUM - 1 : 0][4 + 32 + $clog2(MEM_DEPTH) - 1 : 0] vrf_write_reg, vrf_write_next;      

// Read data preparation pipeline registers
logic [R_PORTS_NUM - 1 : 0][1 : 0][1 : 0] el_extractor_reg, el_extractor_next; 

// Vector mask pipeline register
logic [W_PORTS_NUM - 1 : 0] vm_reg, vm_next;

// Read data sign pipeline register
logic [R_PORTS_NUM - 1 : 0][1 : 0] rdata_sign_reg, rdata_sign_next;

// Store and load pipeline registers
logic [W_PORTS_NUM - 1 : 0][2 : 0] store_data_valid_reg, store_data_valid_next,
                                   store_load_index_valid_reg, store_load_index_valid_next;

// VMRF write pipeline register
// vmrf_write_en | vmrf_wdata | vmrf_waddr
logic [W_PORTS_NUM - 1 : 0][$clog2(MAX_VL_PER_LANE) + 1 + 1 - 1 : 0] vmrf_write_reg, vmrf_write_next;

// Pipeline registers for the signals on the same level as ALU
typedef struct packed
{
    logic [W_PORTS_NUM - 1 : 0] op1_sel;
    logic [W_PORTS_NUM - 1 : 0][1 : 0] op2_sel;
    logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] op3_sel;
    logic [W_PORTS_NUM - 1 : 0][31 : 0] non_lane_data, ALU_x_data, ALU_reduction_data;
    logic [W_PORTS_NUM - 1 : 0][4 : 0] ALU_imm;
    logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] store_data_mux_sel, store_load_index_mux_sel;
    logic [W_PORTS_NUM - 1 : 0][ALU_CTRL_WIDTH - 1 : 0] ALU_ctrl;
    logic [W_PORTS_NUM - 1 : 0] imm_sign;
    logic [W_PORTS_NUM - 1 : 0] store_data_valid;
    logic [W_PORTS_NUM - 1 : 0] store_load_index_valid;
    
} ALU_packet; 

ALU_packet [2 : 0] ALU_signals_reg, ALU_signals_next; 
// ------------------------------------------ //
     
// Vector mask register file
// ------------------------------------------ //
logic [W_PORTS_NUM - 1 : 0] vmrf_wdata, vmrf_rdata;    
logic [W_PORTS_NUM - 1 : 0][3 : 0] bwen_mux;
logic [W_PORTS_NUM - 1 : 0] bwen_mux_sel;                                                           // # Control signal # DONE
logic [W_PORTS_NUM - 1 : 0][$clog2(MAX_VL_PER_LANE) - 1 : 0] vmrf_waddr;
logic [W_PORTS_NUM - 1 : 0] vmrf_wen;
// ------------------------------------------ //

// ALU
// ------------------------------------------ //
logic [W_PORTS_NUM - 1 : 0][31 : 0] ALU_data_o;
logic [W_PORTS_NUM - 1 : 0] ALU_vector_mask_o;
logic [W_PORTS_NUM - 1 : 0][31 : 0] op1, op2, op3;
logic [W_PORTS_NUM - 1 : 0] op1_sel;
logic [W_PORTS_NUM - 1 : 0][1 : 0] op2_sel;
logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] op3_sel;
logic [W_PORTS_NUM - 1 : 0][R_PORTS_NUM - 1 : 0][31 : 0] op3_mux;
logic [W_PORTS_NUM - 1 : 0][31 : 0] non_lane_data, ALU_x_data, ALU_imm, ALU_reduction_data;
logic [W_PORTS_NUM - 1 : 0][ALU_CTRL_WIDTH - 1 : 0] ALU_ctrl;
logic [W_PORTS_NUM - 1 : 0] imm_sign;
logic [W_PORTS_NUM - 1 : 0] alu_output_valid_reg, alu_output_valid_next;
// ------------------------------------------ //

// Load and store
// ------------------------------------------ //
logic [W_PORTS_NUM - 1 : 0][R_PORTS_NUM - 1 : 0][31 : 0] store_data_mux;
logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] store_data_mux_sel;
logic [W_PORTS_NUM - 1 : 0][R_PORTS_NUM - 1 : 0][31 : 0] store_load_index_mux;
logic [W_PORTS_NUM - 1 : 0][$clog2(R_PORTS_NUM) - 1 : 0] store_load_index_mux_sel;
// ------------------------------------------ //
     
// Moduls instantiation
// ------------------------------------------ //
     
vrf 
#
(
    .R_PORTS_NUM(R_PORTS_NUM),
    .W_PORTS_NUM(W_PORTS_NUM),
    .MEM_DEPTH(MEM_DEPTH),
    .MEM_WIDTH(32)
)
VRF_inst
(
    .clk(clk_i),
    .rstn(rst_i),
    
    // Read IF
    .raddr(vrf_raddr),
    .ren(vrf_ren_i),
    .oreg_ren(vrf_oreg_ren_i), 
    .data_o(vrf_rdata),
    
    // Write IF
    .waddr(vrf_waddr),
    .bwen(vrf_bwen),
    .data_i(vrf_wdata)
);

Register_File
#(
    .data_width(1),
    .r_ports_num(W_PORTS_NUM),
    .w_ports_num(W_PORTS_NUM),
    .rf_depth(MAX_VL_PER_LANE)
)
VMRF
(
    .clk_i(clk_i),
    .rst_i(rst_i),
    
    .read_data_o(vmrf_rdata),
    .read_addr_i(vmrf_addr_i),
    
    .write_data_i(vmrf_wdata),                  
    .write_addr_i(vmrf_waddr),
    .write_en_i(vmrf_wen)
);

alu 
#
(
    .OP_WIDTH(32),
    .PARALLEL_IF_NUM(W_PORTS_NUM),
    .CTRL_WIDTH(ALU_CTRL_WIDTH)
)
ALU_inst
(
    .clk(clk_i),
    .rstn(rst_i),
    
    .alu_opmode(ALU_ctrl),
    .alu_a_i(op1),
    .alu_b_i(op2),
    .alu_c_i(op3),
    .alu_o({ALU_vector_mask_o[W_PORTS_NUM - 1 : 0], ALU_data_o[W_PORTS_NUM - 1 : 0]}),
    .alu_output_valid_o(alu_output_valid_next)
    
);

// ------------------------------------------ //     

// Pipeline registers for data on the same level as ALU
always_ff@(posedge clk_i) begin
    for(int i = 0; i < 3; i++) begin
        if(!rst_i) begin
            ALU_signals_reg[i] <= 0;
        end
        else begin
            ALU_signals_reg[i] <= ALU_signals_next[i];
        end
    end
end

always_comb begin
    for(int i = 0; i < 2; i++) begin
        ALU_signals_next[i + 1] = ALU_signals_reg[i]; 
    end
    op1_sel = ALU_signals_reg[2].op1_sel;
    op2_sel = ALU_signals_reg[2].op2_sel;
    op3_sel = ALU_signals_reg[2].op3_sel;
    non_lane_data = ALU_signals_reg[2].non_lane_data;
    ALU_x_data = ALU_signals_reg[2].ALU_x_data;
    imm_sign = ALU_signals_reg[2].imm_sign;
    ALU_reduction_data = ALU_signals_reg[2].ALU_reduction_data;
    store_data_mux_sel = ALU_signals_reg[2].store_data_mux_sel;
    store_load_index_mux_sel = ALU_signals_reg[2].store_load_index_mux_sel;
    ALU_ctrl = ALU_signals_reg[2].ALU_ctrl;
    store_data_valid_o = ALU_signals_reg[2].store_data_valid;
    store_load_index_valid_o = ALU_signals_reg[2].store_load_index_valid;
    
    ALU_signals_next[0].op1_sel = op1_sel_i;
    ALU_signals_next[0].op2_sel = op2_sel_i;
    ALU_signals_next[0].op3_sel = op3_sel_i;
    ALU_signals_next[0].non_lane_data = non_lane_data_i;
    ALU_signals_next[0].ALU_x_data = ALU_x_data_i;
    ALU_signals_next[0].ALU_imm = ALU_imm_i;
    ALU_signals_next[0].imm_sign = imm_sign_i;
    ALU_signals_next[0].ALU_reduction_data = ALU_reduction_data_i;
    ALU_signals_next[0].store_data_mux_sel = store_data_mux_sel_i;
    ALU_signals_next[0].store_load_index_mux_sel = store_load_index_mux_sel_i;
    ALU_signals_next[0].ALU_ctrl = ALU_ctrl_i;
    ALU_signals_next[0].store_data_valid = store_data_valid_i;
    ALU_signals_next[0].store_load_index_valid = store_load_index_valid_i;
end

generate

    for(i_gen = 0; i_gen < R_PORTS_NUM; i_gen++) begin
        
        always_comb begin
            // Mux for choosing the right byte
            read_data_byte_mux[i_gen] = vrf_rdata[i_gen][read_data_byte_mux_sel[i_gen] << 3 +: 8];
            // Unsigned/Signed 8-bit extender
            read_data_byte_us_mux[i_gen] = (read_data_byte_us_mux_sel[i_gen] == 0) ? {{24{1'b0}}, read_data_byte_mux[i_gen]} :
                                           {{24{read_data_byte_mux[i_gen][7]}}, read_data_byte_mux[i_gen]};

            // Mux for choosing the right halfword
            read_data_hw_mux[i_gen] = vrf_rdata[i_gen][read_data_hw_mux_sel[i_gen] << 4 +: 16];
            // Unsigned/Signed 16-bit extender
            read_data_hw_us_mux[i_gen] = (read_data_hw_us_mux_sel[i_gen] == 0) ? {{16{1'b0}}, read_data_hw_mux[i_gen]} :
                                           {{16{read_data_hw_mux[i_gen][15]}}, read_data_hw_mux[i_gen]};
            // Mux for choosing the right data
            read_data_mux[i_gen] = (read_data_mux_sel[i_gen] != 3) ? read_data_prep_reg[i_gen][read_data_mux_sel[i_gen] << 4 +: 32] : 0;
            
            // Read address logic
            case(read_addr_mux_sel[i_gen])
                0: read_addr_mux[i_gen] = {{2{1'b0}}, vrf_raddr_i[i_gen][$clog2(MEM_DEPTH) - 1: 2]};
                1: read_addr_mux[i_gen] = {{1{1'b0}}, vrf_raddr_i[i_gen][$clog2(MEM_DEPTH) - 1: 1]};
                2: read_addr_mux[i_gen] = vrf_raddr_i[i_gen];
                3: read_addr_mux[i_gen] = 0; // An assert should be inserted
                default: read_addr_mux[i_gen] = 0;
            endcase
             
        end
        
        // Registers
        always_ff@(posedge clk_i) begin
            if(!rst_i) begin
                read_data_prep_reg[i_gen] <= 0; 
                for(int i = 0; i < 2; i++) begin
                    el_extractor_reg[i_gen][i] <= 0;
                    rdata_sign_reg[i_gen][i] <= 0;                    
                end
            end
            else begin
                read_data_prep_reg[i_gen] <= read_data_prep_next[i_gen];
                
                for(int i = 0; i < 2; i++) begin
                    el_extractor_reg[i_gen][i] <= el_extractor_next[i_gen][i];
                    rdata_sign_reg[i_gen][i] <= rdata_sign_next[i_gen][i];                    
                end
            end
        end
        
        // Generate VRF read assignments
        assign read_data_prep_next[i_gen] = {vrf_rdata[i_gen], read_data_hw_us_mux[i_gen], read_data_byte_us_mux[i_gen]};
        assign vrf_raddr[i_gen] = read_addr_mux[i_gen];
        assign el_extractor_next[i_gen][0] = el_extractor_i[i_gen];
        assign el_extractor_next[i_gen][1] = el_extractor_reg[i_gen][0];
        assign read_data_byte_mux_sel[i_gen] = el_extractor_reg[i_gen][1];
        assign read_data_hw_mux_sel[i_gen] = el_extractor_reg[i_gen][1][0];
        assign read_data_mux_sel[i_gen] = vsew_i;
        assign read_addr_mux_sel[i_gen] = vsew_i;
        assign rdata_sign_next[i_gen][0] = rdata_sign_i[i_gen];
        assign rdata_sign_next[i_gen][1] = rdata_sign_reg[i_gen][0];
        assign read_data_byte_us_mux_sel[i_gen] = rdata_sign_reg[i_gen][1]; 
        assign read_data_hw_us_mux_sel[i_gen] = rdata_sign_reg[i_gen][1]; 
        
    end
        
    for(j_gen = 0; j_gen < W_PORTS_NUM; j_gen++) begin
        
        always_comb begin
        
            bwen_mux[j_gen] = (bwen_mux_sel[j_gen] == 0) ? vrf_write_reg[j_gen][3 : 0] : (vrf_write_reg[j_gen][3 : 0] & {4{vmrf_rdata}}); 
        
            // Write address logic
            case(write_addr_mux_sel[j_gen])
                0: write_addr_mux[j_gen] = {{2{1'b0}}, vrf_write_reg[j_gen][32 + 4 + 2 +: $clog2(MEM_DEPTH) - 2]};
                1: write_addr_mux[j_gen] = {{1{1'b0}}, vrf_write_reg[j_gen][32 + 4 + 1 +: $clog2(MEM_DEPTH) - 1]};
                2: write_addr_mux[j_gen] = vrf_write_reg[j_gen][32 + 4 +: $clog2(MEM_DEPTH)];
                3: write_addr_mux[j_gen] = 0; // An assert should be inserted
                default: write_addr_mux[j_gen] = 0;
            endcase
            
            case(write_data_mux_sel[j_gen])
                0: vrf_wdata_mux[j_gen] = ALU_data_o[j_gen];
                1: vrf_wdata_mux[j_gen] = load_data_i[j_gen];
                2: vrf_wdata_mux[j_gen] = slide_data_i[j_gen];
                3:  vrf_wdata_mux[j_gen] = 0; // Should insert an assert
                default: vrf_wdata_mux[j_gen] = 0;
            endcase
            
            // Extender for immediate
            case(imm_sign[j_gen])
                0: ALU_imm[j_gen] = {{27{1'b0}}, ALU_signals_reg[2].ALU_imm[j_gen]};
                1: ALU_imm[j_gen] = {{27{ALU_signals_reg[2].ALU_imm[j_gen][4]}}, ALU_signals_reg[2].ALU_imm[j_gen]};
                default: ALU_imm[j_gen] = 0; 
            endcase
            
            // Muxes for ALU operands
            op1[j_gen] = (op1_sel[j_gen] == 0) ? read_data_mux[j_gen << 2] : non_lane_data;
            case(op2_sel[j_gen])
                0: op2[j_gen] = read_data_mux[j_gen << 2 + 1];
                1: op2[j_gen] = ALU_x_data[j_gen];
                2: op2[j_gen] = ALU_imm[j_gen];
                3: op2[j_gen] = ALU_reduction_data[j_gen]; // Should insert an assert
                default: op2[j_gen] = 0;
            endcase
            
            for(int i = 0; i < R_PORTS_NUM; i++) begin
                op3_mux[j_gen][i] = read_data_mux[i]; 
            end
            op3[j_gen] = op3_mux[j_gen][op3_sel[j_gen]];
            
            // Store data mux
            for(int i = 0; i < R_PORTS_NUM; i++) begin
                store_data_mux[j_gen][i] = read_data_mux[i]; 
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
                vrf_write_reg[j_gen] <= 0;
                vmrf_write_reg[j_gen] <= 0;
                vm_reg[j_gen] <= 0;
                alu_output_valid_reg[j_gen] <= 0;
            end
            else begin
                vrf_write_reg[j_gen] <= vrf_write_next[j_gen];
                vmrf_write_reg[j_gen] <= vmrf_write_next[j_gen]; 
                vm_reg[j_gen] <= vm_next[j_gen];
                alu_output_valid_reg[j_gen] <= alu_output_valid_next[j_gen];
            end
        end
        
        // Generate VRF read assignments
        assign vrf_waddr[j_gen] = write_addr_mux[j_gen];
        assign vrf_bwen[j_gen] = bwen_mux[j_gen];
        assign vrf_write_next[j_gen] = {vrf_waddr_i[j_gen] ,vrf_wdata_mux[j_gen], vrf_bwen_i[j_gen]}; 
        assign vrf_wdata[j_gen] = vrf_write_reg[j_gen][32 + 4 - 1 : 4];
        assign vmrf_write_next[j_gen] = {vmrf_wen_i[j_gen], ALU_vector_mask_o[j_gen], vmrf_addr_i[j_gen]};
        assign vmrf_wen[j_gen] = vmrf_write_reg[j_gen][$clog2(MAX_VL_PER_LANE) + 1 + 1 - 1] & {4{alu_output_valid_reg[j_gen]}};
        assign vmrf_wdata[j_gen] = vmrf_write_reg[j_gen][$clog2(MAX_VL_PER_LANE)];
        assign vmrf_waddr[j_gen] = vmrf_write_reg[j_gen][$clog2(MAX_VL_PER_LANE) - 1 : 0];
        assign write_addr_mux_sel[j_gen] = vsew_i;
        assign vm_next[j_gen] = vector_mask_i[j_gen];
        assign bwen_mux_sel[j_gen] = vm_reg[j_gen];
        assign write_data_mux_sel[j_gen] = write_data_sel_i[j_gen];
        assign store_data_valid_o = store_data_valid_reg[j_gen][2];

    end
        
endgenerate;

endmodule
