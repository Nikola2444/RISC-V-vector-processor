/*
    Kada se koriste redukcije, onda se upisuje u svakom lejnu u njegov prvi element podatak, a treba samo za prvi lejn
*/

`timescale 1ns / 1ps

module Complete_sublane_driver
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
    input clk_i,
    input rst_i,
    
    // General signals
    input logic [$clog2(VLANE_NUM * MAX_VL_PER_LANE) - 1 : 0] vl_i,             // per lane: vl_i / 8 + !(vl_i % 8 == 0)
    input logic [2 : 0] vsew_i,
    output logic [1 : 0] vsew_o,
    input logic [2 : 0] vlmul_i,                                                // NEW SIGNAL
    
    // Control Flow signals
    input logic [$clog2(INST_TYPE_NUM) - 1 : 0] inst_type_i,                    // 0 - normal, 1 - reduction, 2 - load, ...
    
    // Handshaking
    input start_i,
    output logic ready_o,
    
    // Inst timing signals
    input logic [$clog2(MAX_VL_PER_LANE) - 1 : 0] inst_delay_i,
    
    // Signals for read data valid logic
    output logic [VLANE_NUM - 1 : 0] read_data_valid_o,
    
    // VRF
    input logic vrf_ren_i,                                                     // unknown behaviour 
    input logic vrf_oreg_ren_i,                                                // unknown behaviour
    input logic [8 * $clog2(MEM_DEPTH) - 1 : 0] vrf_starting_waddr_i,
    input logic [2 : 0][8 * $clog2(MEM_DEPTH) - 1 : 0] vrf_starting_raddr_i,   // UPDATED
    input logic [1 : 0] wdata_width_i,                                         // 1 - byte, 2 - halfword, 3 - word
    output logic vrf_ren_o,
    output logic vrf_oreg_ren_o,
    output logic [VLANE_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_waddr_o,
    output logic [2 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_raddr_o,               // UPDATED, 0 - vs1, 1 - vs2, 2 - vs3(only for three operands)  
    output logic [VLANE_NUM - 1 : 0][3 : 0] vrf_bwen_o,
    
    // VMRF
    output logic [$clog2(MAX_VL_PER_LANE) - 1 : 0] vmrf_addr_o,   
    output logic vmrf_wen_o,
    
    // Load and Store
    input logic load_valid_i,                                                   // NEW SIGNAL
    input logic load_last_i,                                                    // NEW SIGNAL
    output logic ready_for_load_o,                                              // NEW SIGNAL
    input logic [VLANE_NUM - 1 : 0][3 : 0] load_bwen_i,    
         
    input logic [$clog2(R_PORTS_NUM) - 1 : 0] store_data_mux_sel_i,
    input logic [$clog2(R_PORTS_NUM) - 1 : 0] store_load_index_mux_sel_i,
    output logic store_data_valid_o,
    output logic store_load_index_valid_o,
    output logic [$clog2(R_PORTS_NUM) - 1 : 0] store_data_mux_sel_o,
    output logic [$clog2(R_PORTS_NUM) - 1 : 0] store_load_index_mux_sel_o,
    
    // Signals for reductions
    input logic [VLANE_NUM - 2 : 0][31 : 0] lane_result_i,
    
    // ALU
    input logic [1 : 0] op2_sel_i,
    input logic [$clog2(R_PORTS_NUM) - 1 : 0] op3_sel_i,                        // Determined by port allocation
    input logic [31 : 0] ALU_x_data_i,
    input logic [4 : 0] ALU_imm_i,
    input logic [ALU_OPMODE - 1 : 0] ALU_opmode_i,
    input logic                      reduction_op_i,
    output logic [1 : 0] op2_sel_o,
    output logic [$clog2(R_PORTS_NUM) - 1 : 0] op3_sel_o,
    output logic [31 : 0] ALU_x_data_o,
    output logic [4 : 0] ALU_imm_o,
    output logic [31 : 0] ALU_reduction_data_o,
    output logic [ALU_OPMODE - 1 : 0] ALU_ctrl_o,
    output logic                      reduction_op_o,                              // Not yet finished
    input logic alu_en_32bit_mul_i,                                            // NEW SIGNAL
    output logic alu_en_32bit_mul_o,                               
    
    // Slides
    input logic slide_type_i,
    input logic up_down_slide_i,                                                // 0 for down, 1 for up
    input logic [31 : 0] slide_amount_i,
    output logic up_down_slide_o,
    output logic request_write_control_o,                                       // 0 - ALU generates valid signal, 1 - only bwen is important 
      
    // Misc signals
    input vector_mask_i,
    output logic [1 : 0] el_extractor_o,
    output logic vector_mask_o,
    output logic [1 : 0] write_data_sel_o
    
);

/////////////////////////////////////////////////////////////////////////////////
// Useful parameters //
localparam LP_FAST_SLIDE = 1;
localparam LP_SLOW_SLIDE = 1;
localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] NORMAL = 0;
localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] REDUCTION = 1;
localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] STORE = 2;
localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] INDEXED_STORE = 3;
localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] LOAD = 4;
localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] INDEXED_LOAD = 5;
localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] SLIDE = 6;
localparam logic [$clog2(MAX_VL_PER_LANE) : 0] REDUCTION_MODE_LIMIT = VLANE_NUM - 2;
localparam VECTOR_LENGTH = VLANE_NUM * MAX_VL_PER_LANE; 
localparam VRF_DELAY = 4;
localparam SLIDE_BUFFER_DELAY = VRF_DELAY - 1;
/////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////
// FSM - declaration //
localparam STATES_NUM = 8;
typedef enum logic [$clog2(STATES_NUM) - 1 : 0] {IDLE, NORMAL_MODE, READ_MODE, LOAD_MODE, REDUCTION_MODE, REDUCTION_WRITE_MODE,
                                                 SLIDE_OFFLANE_MOVE, SLIDE_INTRALANE_SHIFT} fsm_state;
fsm_state current_state, next_state;
/////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////
// Registers - declaration //
typedef struct packed
{ 
    logic [$clog2(MAX_VL_PER_LANE) - 1 : 0] inst_delay;
    logic vrf_ren;
    logic vrf_oreg_ren;
    logic [1 : 0] wdata_width;
    logic [$clog2(INST_TYPE_NUM) - 1 : 0] inst_type;   
    logic vmrf_wen;
    logic en_write;
    logic waddr_cnt_en;
    logic vmrf_cnt_en;
    logic bwen_en;
    logic start;
    logic [$clog2(R_PORTS_NUM) - 1 : 0] store_data_mux_sel;
    logic [$clog2(R_PORTS_NUM) - 1 : 0] store_load_index_mux_sel;
    logic store_data_valid;
    logic store_load_index_valid;
    logic [$clog2(MAX_VL_PER_LANE) - 1 : 0] read_limit;
    logic [1 : 0] op2_sel;
    logic [$clog2(R_PORTS_NUM) - 1 : 0] op3_sel;
    logic [31 : 0] ALU_x_data;
    logic [4 : 0] ALU_imm;
    logic vector_mask;
    logic [1 : 0] write_data_sel;
    logic [8 * $clog2(MEM_DEPTH) - 1 : 0] vrf_starting_waddr;
    logic [2 : 0][8 * $clog2(MEM_DEPTH) - 1 : 0] vrf_starting_raddr;
    logic [ALU_OPMODE - 1 : 0] ALU_opmode;
    logic up_down_slide;
    logic [31 : 0] slide_amount;
    logic [$clog2(VLANE_NUM) - 1 : 0] slide_amount_complete_lane;
    logic slide_complete_lane_up;
    logic [1 : 0] input_sel;
    logic [1 : 0] adder_input_sel;                                     
    logic en_comp;
    logic delay_addr;
    logic reverse_bwen;
    logic slide_enable_buffering;                                       // 1 - buffering enabled, 0 - for disabled
    logic start_decrementor;
    logic reduction_op;
    
    // 1-cycle delayed data for slides
    logic [$clog2(MEM_DEPTH) - 1 : 0] waddr_ff;
    logic [3 : 0] bwen_ff;
    
    // 32-bit multiply
    logic alu_en_32bit_mul;
    logic [1 : 0] sew;
    
} dataPacket0;

dataPacket0 dp0_reg, dp0_next;
// bwen //
logic [3 : 0] shift4_reg, shift4_next;
logic [1 : 0] shift2_reg, shift2_next;
// main counter //
logic [$clog2(MAX_VL_PER_LANE) : 0] main_cnt;
logic main_cnt_en;
logic rst_main_cnt;
logic [$clog2(MAX_VL_PER_LANE) : 0] limit_adder;
// Write address generation //
logic [1 : 0] element_width_write;
logic [1 : 0] element_width_read;
// VMRF //
logic [$clog2(MAX_VL_PER_LANE) - 1 : 0] vmrf_cnt;
logic rst_vmrf_cnt;
// logic for read_limit //
logic [$clog2(VLANE_NUM * MAX_VL_PER_LANE) - 1 : 0] read_limit_add;
logic read_limit_carry;
logic read_limit_comp;
// signals for reductions //
logic [31 : 0] reduction_mux;
// signals for read data validation //
logic load_data_validation;
logic shift_data_validation;
logic [VLANE_NUM - 1 : 0] read_data_valid, read_data_valid_slide, read_data_valid_dv;
logic partial_results_valid;
logic shift_partial;
// signals for slides //
logic [$clog2(VLANE_NUM) - 1 : 0] slide_complete_lane_adder;
logic [$clog2(VLANE_NUM) - 1 : 0] SA_complete_lane;
logic [VLANE_NUM - 1 : 0] valid_data;
logic [VLANE_NUM - 1 : 0] slide_write_data_pattern;
logic enable_write_slide;
logic [$clog2(MAX_VL_PER_LANE) : 0] per_lane_words;
typedef struct packed
{
    logic [$clog2(MEM_DEPTH) - 1 : 0] waddr;
    logic [3 : 0] vrf_bwen;
} dataPacket1;

dataPacket1 [VRF_DELAY - 1 : 0] dp1_reg, dp1_next;
/////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////
// Additional signals - declaration //
// bwen //
logic [VLANE_NUM - 1 : 0][3 : 0] bwen;
logic [3 : 0] bwen_mux;
logic [VLANE_NUM - 1 : 0][3 : 0] slide_bwen, normal_bwen;
logic secondary_bwen_en;

// address counter //
logic waddr_load;
logic waddr_cnt_rst;
logic raddr_cnt_en;
logic raddr_load;
logic raddr_cnt_rst;
logic [$clog2(MEM_DEPTH) - 1 : 0] waddr;
logic [2 : 0][$clog2(MEM_DEPTH) - 1 : 0] raddr;
logic wsecondary_en;
logic [VLANE_NUM - 1 : 0][$clog2(MEM_DEPTH) - 1 : 0] slide_waddr, normal_waddr;

// comparators
logic [6 : 0] inst_type_comp;
/////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////
// Assigments //
assign vrf_waddr_o = (current_state == SLIDE_INTRALANE_SHIFT) ? slide_waddr :
                                                                normal_waddr;
assign vrf_raddr_o = raddr;
assign vmrf_addr_o = vmrf_cnt;
assign vmrf_wen_o = dp0_reg.vmrf_wen & dp0_reg.vector_mask;
assign vrf_bwen_o = (current_state == SLIDE_INTRALANE_SHIFT) ? slide_bwen :
                                                               normal_bwen;
assign vrf_ren_o = dp0_reg.vrf_ren;
assign vrf_oreg_ren_o = dp0_reg.vrf_oreg_ren;
assign dp0_next.vrf_ren = vrf_ren_i;
assign dp0_next.vrf_oreg_ren = vrf_oreg_ren_i;
assign store_data_mux_sel_o = dp0_reg.store_data_mux_sel;
assign store_load_index_mux_sel_o = dp0_reg.store_load_index_mux_sel; 
assign read_limit_carry = (vl_i[$clog2(VLANE_NUM) - 1 : 0] == 0);
assign read_limit_add = (vl_i >> $clog2(VLANE_NUM)) + !read_limit_carry;
assign read_limit_comp = (main_cnt == dp0_reg.read_limit - 1);

assign store_load_index_valid_o = dp0_reg.store_load_index_valid;
assign store_data_valid_o = dp0_reg.store_data_valid;
assign op2_sel_o = (current_state == REDUCTION_MODE) ? 2'b11 : dp0_reg.op2_sel;
assign op3_sel_o = dp0_reg.op3_sel;
assign ALU_x_data_o = dp0_reg.ALU_x_data;
assign ALU_imm_o = dp0_reg.ALU_imm;
assign el_extractor_o = main_cnt[1 : 0];
assign vector_mask_o = dp0_reg.vector_mask;
assign write_data_sel_o = dp0_reg.write_data_sel;
assign read_data_valid_o = (dp0_reg.delay_addr == 1) ? read_data_valid_slide : read_data_valid;
assign read_data_valid[VLANE_NUM - 1 : 1] = read_data_valid_dv[VLANE_NUM - 1 : 1];
assign ALU_ctrl_o = dp0_reg.ALU_opmode;
assign reduction_op_o = dp0_reg.reduction_op;
assign waddr_cnt_en = dp0_reg.waddr_cnt_en;
// Slides //
//assign SA_complete_lane = slide_amount_i[$clog2(VLANE_NUM) - 1 : 0];
assign SA_complete_lane = dp0_reg.slide_amount[$clog2(VLANE_NUM) - 1 : 0];
   assign slide_complete_lane_adder = ~SA_complete_lane + 1;
assign dp1_next[VRF_DELAY - 1].waddr = waddr;
assign dp0_next.bwen_ff = bwen_mux;
assign dp0_next.waddr_ff = waddr;
assign dp1_next[VRF_DELAY - 1].vrf_bwen = (current_state == SLIDE_OFFLANE_MOVE) ? {4{1'b1}} : 0;
assign up_down_slide_o = dp0_reg.slide_complete_lane_up;
assign request_write_control_o = (current_state == SLIDE_OFFLANE_MOVE) | (current_state == LOAD_MODE) | (current_state == REDUCTION_WRITE_MODE);
assign read_data_valid_slide = valid_data;
assign secondary_bwen_en = wsecondary_en;
assign limit_adder = dp0_reg.inst_delay + dp0_reg.read_limit;;
// 32-bit multiply //
assign alu_en_32bit_mul_o = dp0_reg.alu_en_32bit_mul;
// Write address generation //
assign element_width_write = ((current_state == LOAD_MODE) | (current_state == SLIDE_OFFLANE_MOVE)) ? 2'b10 : 2'(dp0_reg.wdata_width - 1);
assign vsew_o = dp0_reg.sew;
/////////////////////////////////////////////////////////////////////////////////
// Per lane lenght in words //
always_comb begin
    case(vlmul_i)
        3'b101: per_lane_words = (VREG_LOC_PER_LANE >> 3);
        3'b110: per_lane_words = (VREG_LOC_PER_LANE >> 2);
        3'b111: per_lane_words = (VREG_LOC_PER_LANE >> 1);
        3'b000: per_lane_words = VREG_LOC_PER_LANE;
        3'b001: per_lane_words = (VREG_LOC_PER_LANE << 1);
        3'b010: per_lane_words = (VREG_LOC_PER_LANE << 2);
        3'b011: per_lane_words = (VREG_LOC_PER_LANE << 3);
        default: per_lane_words = VREG_LOC_PER_LANE;
    endcase
end



/////////////////////////////////////////////////////////////////////////////////
always_comb begin
    if(current_state == REDUCTION_WRITE_MODE) begin
        for(int i = 0; i < VLANE_NUM; i++) begin
            bwen[i] = 0;
        end
        bwen[0] = bwen_mux;
    end
    else begin
        for(int i = 0; i < VLANE_NUM; i++) begin
            bwen[i] = bwen_mux;
        end
    end
end
/////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////
// slide_bwen assigment //
generate
    for(genvar i = 0; i < VLANE_NUM; i++) begin
        assign slide_bwen[i] = (slide_write_data_pattern[i] == 0) ? dp0_reg.bwen_ff : bwen_mux;
        assign slide_waddr[i] = (slide_write_data_pattern[i] == 0) ? dp0_reg.waddr_ff : waddr;
        
        assign normal_waddr[i] = (dp0_reg.delay_addr == 1) ? dp1_reg[0].waddr : waddr; 
        assign normal_bwen[i] = ((current_state == LOAD_MODE) & (dp0_reg.waddr_cnt_en == 1)) ? load_bwen_i[i] : 
                                ((dp0_reg.delay_addr == 1) ? dp1_reg[0].vrf_bwen : bwen[i]);
    end
endgenerate;
/////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////
// Main counter and vmrf counter //
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

/////////////////////////////////////////////////////////////////////////////////
// Signal selection for reductions - implementation ///
always_comb begin
    if(main_cnt < VLANE_NUM - 1) begin
        ALU_reduction_data_o = lane_result_i[main_cnt[$clog2(VLANE_NUM - 1) - 1 : 0]];
    end
    else
        ALU_reduction_data_o = 0;
end
/////////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////////////
// General registers - implementation //
always_ff@(posedge clk_i) begin
    if(!rst_i) begin
        dp0_reg <= 0;
    end
    else begin
        dp0_reg <= dp0_next;
    end
    
    for(int i = 0; i < VRF_DELAY; i++) begin
        if(!rst_i) begin
            dp1_reg[i] <= 0;
        end
        else begin
            dp1_reg[i] <= dp1_next[i];
        end
    end
end
/////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////
// Delay registers for slides //
always_comb begin
    for(int i = 0; i < VRF_DELAY - 1; i++) begin
        dp1_next[i] = dp1_reg[i + 1];
    end
end
/////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////
// bwen generation - implementation //
always_ff@(posedge clk_i) begin
    if(!rst_i) begin
        shift4_reg <= 4'b0001;
        shift2_reg <= 2'b01;
    end
    else begin
        if(dp0_reg.bwen_en & secondary_bwen_en) begin
            shift4_reg <= {shift4_reg[2 : 0], shift4_reg[3]};
            shift2_reg <= {shift2_reg[0], shift2_reg[1]};
        end
        else begin
            shift4_reg <= 4'b0001;
            shift2_reg <= 2'b01;
        end 
    end
end
logic [3 : 0] bwen_selcetion;
always_comb begin
    
    

    shift4_next = 4'b0001;
    shift2_next = 2'b01; 

    case(dp0_reg.wdata_width & {2{dp0_reg.en_write}})
        2'b01: bwen_selcetion = shift4_reg;
        2'b10: bwen_selcetion = {{2{shift2_reg[1]}}, {2{shift2_reg[0]}}};
        2'b11: bwen_selcetion = {{4{1'b1}}};
        default: bwen_selcetion = {{4{1'b0}}};
    endcase
    
    bwen_mux = (dp0_reg.reverse_bwen == 1) ? {bwen_selcetion[0], bwen_selcetion[1], bwen_selcetion[2], bwen_selcetion[3]} : 
                                              bwen_selcetion;
end
/////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////
// Address counters - instantiation // 
Address_counter
#(
    .MEM_DEPTH(MEM_DEPTH),
    .VREG_LOC_PER_LANE(VREG_LOC_PER_LANE),
    .STRIDE_ENABLE("YES")
)
waddr_cnt
(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .start_addr_i(dp0_reg.vrf_starting_waddr),
    .load_i(waddr_load),
    .up_down_i(dp0_reg.up_down_slide),
    .element_width_i(element_width_write),
    .rst_cnt_i(waddr_cnt_rst),
    .en_i(waddr_cnt_en),
    .secondary_en_i(wsecondary_en),
    .addr_o(waddr)
);

generate
    for(genvar i = 0; i < 3; i++) begin
        Address_counter
        #(
            .MEM_DEPTH(MEM_DEPTH),
            .VREG_LOC_PER_LANE(VREG_LOC_PER_LANE),
            .STRIDE_ENABLE("YES")
        )
        raddr_cnt
        (
            .clk_i(clk_i),
            .rst_i(rst_i),
            .start_addr_i(dp0_reg.vrf_starting_raddr[i]),
            .load_i(raddr_load),
            .up_down_i(dp0_reg.up_down_slide),
            .element_width_i(2'(element_width_read)),
            .rst_cnt_i(raddr_cnt_rst),
            .en_i(raddr_cnt_en),
            .secondary_en_i(1'b1),
            .addr_o(raddr[i])
        );
    end
endgenerate;
/////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////
Data_validation
#(
    .MAX_VL_PER_LANE(MAX_VL_PER_LANE),
    .VLANE_NUM(VLANE_NUM)
)
data_validation_inst
(
    .clk_i(clk_i),
    .rst_i(rst_i),
    
    .vl_i(vl_i),
    .shift_en_i(shift_data_validation),
    .shift_partial_i(shift_partial),
    .load_i(load_data_validation),
    
    .valid_o(read_data_valid_dv),
    .partial_results_valid_o(partial_results_valid)
);
/////////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////////////
Column_offset_register
#(
    .VREG_LOC_PER_LANE(VREG_LOC_PER_LANE),
    .VLANE_NUM(VLANE_NUM)
)
Column_offset_register_inst
(
    .clk_i(clk_i),
    .rst_i(rst_i),
    
    .input_sel_i(dp0_reg.input_sel),                                                                // 00 - NOP, 01 - right shift, 10 - left shift, 11 - parallel input
    .adder_input_sel_i(dp0_reg.adder_input_sel),                                                    // 00 - SA + i, 01 - SA + VLANE_NUM - i, 10 - shift_reg - 1, 11 - NOT DEFINED
    .en_comp_i(dp0_reg.en_comp),
    .start_decrementor_i(dp0_reg.start_decrementor),
    .shift_amount_i(dp0_reg.slide_amount[$clog2(VREG_LOC_PER_LANE * 4 * 8 * VLANE_NUM) - 1 : 0]),
    .valid_data_o(valid_data),
    .slide_write_data_pattern_o(slide_write_data_pattern),
    .enable_write_slide_o(enable_write_slide)
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

   always_ff@(posedge clk_i)
   begin
      if (!rst_i)
	ready_o <= 1'b1;
                                                                                                                                                               else if (start_i && ready_o)
	ready_o <= 1'b0;
      else if (next_state == IDLE && !ready_o)
	ready_o <= 1'b1;    
   end

always_comb begin
    // main counter control signals
    rst_main_cnt = 0;
    main_cnt_en = 0;
    // VMRF counter control signals
    rst_vmrf_cnt = 0;
    // write address generator control signals
    waddr_load = 0;
    waddr_cnt_rst = 0;
    wsecondary_en = 1;
    // read address generator control signals
    raddr_load = 0;
    raddr_cnt_rst = 0;
    raddr_cnt_en = 0;
    // handshaking signals
   //ready_o = 0;
    // read data validation
    shift_data_validation = 0;
    load_data_validation = 0; 
    shift_partial = 0;
    read_data_valid[0] = read_data_valid_dv[0];
    // registers
    dp0_next.inst_delay = dp0_reg.inst_delay;
    dp0_next.wdata_width = dp0_reg.wdata_width;
    dp0_next.inst_type = dp0_reg.inst_type;
    dp0_next.vmrf_wen = dp0_reg.vmrf_wen;
    dp0_next.en_write = dp0_reg.en_write;
    dp0_next.waddr_cnt_en = dp0_reg.waddr_cnt_en;
    dp0_next.vmrf_cnt_en = dp0_reg.vmrf_cnt_en;
    dp0_next.bwen_en = dp0_reg.bwen_en;
    dp0_next.start = dp0_reg.start;
    dp0_next.read_limit = dp0_reg.read_limit;
    dp0_next.store_load_index_mux_sel = dp0_reg.store_load_index_mux_sel;
    dp0_next.store_data_mux_sel = dp0_reg.store_data_mux_sel;
    dp0_next.store_data_valid = dp0_reg.store_data_valid;
    dp0_next.store_load_index_valid = dp0_reg.store_load_index_valid;
    dp0_next.op2_sel = dp0_reg.op2_sel;
    dp0_next.op3_sel = dp0_reg.op3_sel;
    dp0_next.ALU_x_data = dp0_reg.ALU_x_data;
    dp0_next.ALU_imm = dp0_reg.ALU_imm;
    dp0_next.vector_mask = dp0_reg.vector_mask;
    dp0_next.write_data_sel = dp0_reg.write_data_sel;
    dp0_next.vrf_starting_raddr = dp0_reg.vrf_starting_raddr;
    dp0_next.vrf_starting_waddr = dp0_reg.vrf_starting_waddr;
    dp0_next.ALU_opmode = dp0_reg.ALU_opmode;
    dp0_next.reduction_op = dp0_reg.reduction_op;
    // Slides
    dp0_next.up_down_slide = dp0_reg.up_down_slide;
    dp0_next.slide_amount = dp0_reg.slide_amount;
    dp0_next.slide_amount_complete_lane = dp0_reg.slide_amount_complete_lane;
    dp0_next.slide_complete_lane_up = dp0_reg.slide_complete_lane_up;
    dp0_next.input_sel = dp0_reg.input_sel;                                                         // 00 - NOP, 01 - right shift, 10 - left shift, 11 - parallel input
    dp0_next.adder_input_sel = dp0_reg.adder_input_sel;                                 // 00 - SA + i, 01 - SA + VLANE_NUM - i, 10 - shift_reg - 1, 11 - NOT DEFINED
    dp0_next.en_comp = dp0_reg.en_comp;
    dp0_next.delay_addr = dp0_reg.delay_addr;
    dp0_next.reverse_bwen = dp0_reg.reverse_bwen;
    dp0_next.start_decrementor = dp0_reg.start_decrementor;
    dp0_next.sew = dp0_reg.sew;
    // Loads
    ready_for_load_o = 0;
    // Buffering for slides
    dp0_next.slide_enable_buffering = dp0_reg.slide_enable_buffering;
    // 32-bit multiply
    dp0_next.alu_en_32bit_mul = dp0_reg.alu_en_32bit_mul;
   element_width_read = vsew_i;
   
    
    case(current_state)
        IDLE : begin
            next_state = IDLE;
            //ready_o = 1;
            
            rst_main_cnt = 1;
            rst_vmrf_cnt = 1;
            
            waddr_load = 1;
            raddr_load = 1;
            waddr_cnt_rst = 1;
            raddr_cnt_rst = 1;
            
            load_data_validation = 1;
           if (start_i)
	   begin
              dp0_next.inst_delay = inst_delay_i;
              dp0_next.wdata_width = wdata_width_i;
              dp0_next.inst_type = inst_type_i;
              dp0_next.en_write = 0;
              dp0_next.waddr_cnt_en = 0;
              dp0_next.vmrf_cnt_en = 0;
              dp0_next.bwen_en = 0;
              dp0_next.op2_sel = op2_sel_i;
              dp0_next.op3_sel = op3_sel_i;
              dp0_next.ALU_x_data = ALU_x_data_i;
              dp0_next.ALU_imm = ALU_imm_i;
              dp0_next.start = start_i;
              dp0_next.store_load_index_mux_sel = store_load_index_mux_sel_i;
              dp0_next.store_data_mux_sel = store_data_mux_sel_i;
              dp0_next.read_limit = read_limit_add;
              dp0_next.write_data_sel = 0;
              dp0_next.vector_mask = vector_mask_i;
              dp0_next.vrf_starting_raddr = vrf_starting_raddr_i;
              dp0_next.vrf_starting_waddr = vrf_starting_waddr_i;
              dp0_next.ALU_opmode = ALU_opmode_i;
              dp0_next.reduction_op = reduction_op_i;
              dp0_next.vmrf_wen = 0;
              dp0_next.alu_en_32bit_mul = alu_en_32bit_mul_i;
              dp0_next.sew = vsew_i[1 : 0];
              // slides
              dp0_next.up_down_slide = up_down_slide_i;
              dp0_next.slide_amount = slide_amount_i;
              dp0_next.slide_amount_complete_lane = (slide_complete_lane_adder > SA_complete_lane) ? SA_complete_lane : slide_complete_lane_adder;
              dp0_next.slide_complete_lane_up = (slide_complete_lane_adder > SA_complete_lane) ? up_down_slide_i : !up_down_slide_i;
              dp0_next.adder_input_sel = (up_down_slide_i == 1) ? 2'b01 : 2'b00;
              dp0_next.en_comp = 0;
              dp0_next.delay_addr = 0;
              dp0_next.input_sel = 2'b11;
              dp0_next.reverse_bwen = 0;
              dp0_next.slide_enable_buffering = 0;
              dp0_next.start_decrementor = 0;
	   end
             
            
            if(dp0_reg.start) begin
                dp0_next.start = 0;
                case(inst_type_comp[6 : 0])
                    7'b0000001 : begin                                            // NORMAL
                        next_state = NORMAL_MODE;
                    end
                    7'b0000010 : begin                                            // REDUCTION
                        next_state = READ_MODE;                                  
                    end
                    7'b0000100 : begin                                            // STORE
                        next_state = READ_MODE;
                        dp0_next.store_data_valid = 1;
                    end
                    7'b0001000 : begin                                            // INDEXED_STORE
                        dp0_next.store_data_valid = 1;
                        dp0_next.store_load_index_valid = 1;
                        next_state = READ_MODE;
                    end
                    7'b0010000 : begin                                            // LOAD
                        next_state = LOAD_MODE;
		        ready_for_load_o = 1'b1;
                        dp0_next.waddr_cnt_en = 1;
                        dp0_next.write_data_sel = 1;
                    end
                    7'b0100000 : begin                                            // INDEXED_LOAD
                        dp0_next.store_load_index_valid = 1;
                        next_state = READ_MODE;
                    end
                    7'b1000000 : begin                                            // SLIDE
                        
                        dp0_next.delay_addr = 1;                                  // Starting from the next cycle bwen is 1111
                        dp0_next.waddr_cnt_en = 1;                                // Starting from the next cycle write addres counter is enabled
                        dp0_next.reverse_bwen = !up_down_slide_i;
                        
                        if(dp0_reg.slide_amount_complete_lane == 0) begin
                            next_state = SLIDE_INTRALANE_SHIFT;
                            dp0_next.write_data_sel = 0;
                            dp0_next.adder_input_sel = 2'b10;
                            dp0_next.en_comp = 1;
                            // dp0_next.en_write = 1;                               // Should be zero                                  
                            dp0_next.bwen_en = 1;
                        end
                        else begin
                            next_state = SLIDE_OFFLANE_MOVE;
                            dp0_next.input_sel = 2'b00;
                            dp0_next.write_data_sel = 2;
                            dp0_next.vmrf_cnt_en = 1;                             // This means that this counter starts from 1 and additional decrementer is not needed
                        end
                        
                    end
                    
                    default : begin                                             // An assert should be put here
                        next_state = IDLE;
                    end
                endcase
            end
        end
        NORMAL_MODE : begin
            next_state = NORMAL_MODE;
            
            main_cnt_en = 1;
            
            shift_data_validation = 1;
            
            raddr_cnt_en = 1;
            if(main_cnt == dp0_reg.inst_delay-1) begin
                dp0_next.en_write = 1;
                dp0_next.waddr_cnt_en = 1;
                dp0_next.vmrf_wen = 1;
                dp0_next.vmrf_cnt_en = 1;
                dp0_next.bwen_en = 1;
            end
            
            if(main_cnt == limit_adder) begin
                next_state = IDLE;
                dp0_next.en_write = 0;
                dp0_next.vmrf_wen = 0;
            end
        end
        READ_MODE : begin
            next_state = READ_MODE;
            
            main_cnt_en = 1;
            
            shift_data_validation = 1;
            
            raddr_cnt_en = 1;
            
            case({inst_type_comp[5], inst_type_comp[3 : 1]})
                4'b0001 : begin                                            // REDUCTION
                    if(main_cnt == (dp0_reg.read_limit - 1 + dp0_reg.inst_delay)) begin                               // Not yet specified                  
                        next_state = REDUCTION_MODE;
                        rst_main_cnt = 1;
                    end                                   
                end
                4'b0010 : begin                                            // STORE
                    if(read_limit_comp) begin
                       element_width_read=2'b10; // 
                        next_state = IDLE;
                        dp0_next.store_data_valid = 0;
                    end
                end
                4'b0100 : begin                                            // INDEXED_STORE
                    if(read_limit_comp) begin                               
                        next_state = IDLE;
                        dp0_next.store_data_valid = 0;
                        dp0_next.store_load_index_valid = 0;
                    end
                end
                4'b1000 : begin                                            // INDEXED_LOAD
                    if(read_limit_comp) begin
                        dp0_next.store_load_index_valid = 0;
                        next_state = IDLE;
                    end
                end
                default : begin                                             // An assert should be put here
                    next_state = IDLE;
                end
            endcase
            
        end 
        LOAD_MODE : begin
            next_state = LOAD_MODE;            
            //if(load_valid_i) begin            
       	    ready_for_load_o = 1'b1;
            //end
            //ready_for_load_o = dp0_reg.waddr_cnt_en;            
            if(load_last_i) begin
                next_state = IDLE;
                //ready_for_load_o = 0;
            end 
        end
        REDUCTION_MODE : begin
            next_state = REDUCTION_MODE;
            
            main_cnt_en = 1;
            
            shift_partial = 1;
            read_data_valid[0] = partial_results_valid;
            
            if(main_cnt == REDUCTION_MODE_LIMIT) begin
                next_state = REDUCTION_WRITE_MODE;
                rst_main_cnt = 1;
            end
        end
        REDUCTION_WRITE_MODE : begin
            next_state = REDUCTION_WRITE_MODE;
        
            main_cnt_en = 1;
            
            if(main_cnt == dp0_reg.inst_delay) begin
                dp0_next.en_write = 1;
                dp0_next.vmrf_wen = 1;
            end
            
            if(dp0_reg.en_write) begin
                next_state = IDLE;
                dp0_next.en_write = 0;
                dp0_next.vmrf_wen = 0;
            end
            
        end
        SLIDE_OFFLANE_MOVE : begin        
            next_state = SLIDE_OFFLANE_MOVE;
            
            // Main counter
            main_cnt_en = 1;
            
            // Counter for counting the number of complete lane shifts
            dp0_next.vmrf_cnt_en = 0;
            
            // Address counters
            raddr_cnt_en = 1;
            
            dp0_next.input_sel = 2'b00;
            
            if((main_cnt == per_lane_words - 1) & !dp0_reg.slide_enable_buffering) begin
                rst_main_cnt = 1;
                dp0_next.vmrf_cnt_en = 1;
                
                // Reloading address counters
                waddr_cnt_rst = 1;
                raddr_cnt_rst = 1;
                waddr_load = 1;
                raddr_load = 1;
                
                // Shifting data Column_offset_register
                dp0_next.input_sel = (dp0_reg.slide_complete_lane_up == 1) ? 2'b10  : 2'b01;
                
                if(vmrf_cnt == dp0_reg.slide_amount_complete_lane) begin
                    dp0_next.slide_enable_buffering = 1;
                    dp0_next.vmrf_cnt_en = 1;
                    rst_vmrf_cnt = 1;
                end
            end
            
            if(dp0_reg.slide_enable_buffering) begin
                
                dp0_next.vmrf_cnt_en = 1;
                raddr_cnt_rst = 1;
                raddr_load = 1;
                
                if(vmrf_cnt == SLIDE_BUFFER_DELAY) begin
                    next_state = SLIDE_INTRALANE_SHIFT;
                    dp0_next.vmrf_cnt_en = 0;
                    dp0_next.adder_input_sel = 2'b10;
                    dp0_next.en_comp = 1;
                    dp0_next.write_data_sel = 0;
                    dp0_next.bwen_en = 1;
                    dp0_next.slide_enable_buffering = 0;
                    rst_vmrf_cnt = 1;
                    dp0_next.input_sel = 2'b11;
                    
                    waddr_cnt_rst = 1;
                    waddr_load = 1;
                    
                    rst_main_cnt = 1;
                end
            end
        
        end
        SLIDE_INTRALANE_SHIFT : begin
            next_state = SLIDE_INTRALANE_SHIFT;
            
            // starting the main counter
            main_cnt_en = 1;
            
            // read address generator
            raddr_cnt_en = 1;
            
            // Determines when write address can be inceremented
            wsecondary_en = enable_write_slide;
            
            if(main_cnt == dp0_reg.inst_delay) begin
                dp0_next.en_write = 1;
                dp0_next.waddr_cnt_en = 1;
                dp0_next.start_decrementor = 1;
                dp0_next.bwen_en = 1;
            end
            
            if(main_cnt == limit_adder) begin
                next_state = IDLE;
                dp0_next.en_write = 0;
                dp0_next.vmrf_wen = 0;
                dp0_next.en_comp = 0;
            end 
        end
        default : begin
            next_state = IDLE;
        end
    endcase
end
/////////////////////////////////////////////////////////////////////////////////

endmodule
