module Partial_sublane_driver
#(
    parameter MEM_DEPTH = 514,
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
    input logic [1 : 0] vsew_i,
    output logic [1 : 0] vsew_o,
    output logic [1 : 0] wdata_width_o,
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
    input logic vrf_ren_i,                                                      // unknown behaviour 
    input logic vrf_oreg_ren_i,                                                 // unknown behaviour
    input logic [8 * $clog2(MEM_DEPTH) - 1 : 0] vrf_starting_waddr_i,
    input logic [2 : 0][8 * $clog2(MEM_DEPTH) - 1 : 0] vrf_starting_raddr_i,    // UPDATED
    input logic [1 : 0] wdata_width_i,                                          // 1 - byte, 2 - halfword, 3 - word
    output logic vrf_ren_o,
    output logic vrf_oreg_ren_o,
    output logic [$clog2(MEM_DEPTH) - 1 : 0] vrf_waddr_o,
    output logic [2 : 0][$clog2(MEM_DEPTH) - 1 : 0] vrf_raddr_o,                // UPDATED, 0 - vs1, 1 - vs2, 2 - vs3(only for three operands)
    output logic [VLANE_NUM - 1 : 0][3 : 0] vrf_bwen_o,                                            // Very important
    
    // VMRF
    output logic [$clog2(MAX_VL_PER_LANE) - 1 : 0] vmrf_addr_o,   
    output logic vmrf_wen_o,                                                    // Very important
    
    // Load and Store
    //input logic load_valid_i,                                                   // NEW SIGNAL
    input logic load_last_i,                                                    // NEW SIGNAL
    output logic ready_for_load_o,                                              // NEW SIGNAL
    output logic request_write_control_o,                                       // NEW SIGNAL, 0 - ALU generates valid signal, 1 - only bwen is important
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
    input logic [ALU_OPMODE - 1 : 0] ALU_opmode_i,                              // Not yet finished
    input logic                      reduction_op_i,                              // Not yet finished
    output logic [1 : 0] op2_sel_o,
    output logic [$clog2(R_PORTS_NUM) - 1 : 0] op3_sel_o,
    output logic [31 : 0] ALU_x_data_o,
    output logic [4 : 0] ALU_imm_o,
    output logic [31 : 0] ALU_reduction_data_o,
    output logic [ALU_OPMODE - 1 : 0] ALU_ctrl_o,                                   // Not yet finished
    output logic                      reduction_op_o,                              // Not yet finished

    // Misc signals
    input vector_mask_i,
    output logic[1 : 0] el_extractor_o,
    output logic vector_mask_o,
    output logic [1 : 0] write_data_sel_o
);

/////////////////////////////////////////////////////////////////////////////////
// Useful parameters //
localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] NORMAL = 0;
localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] REDUCTION = 1;
localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] STORE = 2;
localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] INDEXED_STORE = 3;
localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] LOAD = 4;
localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] INDEXED_LOAD = 5;
localparam logic [$clog2(INST_TYPE_NUM) - 1 : 0] SLIDE = 6;
/////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////
// FSM - declaration //
localparam STATES_NUM = 6;
typedef enum logic [$clog2(STATES_NUM) - 1 : 0] {IDLE, NORMAL_MODE, READ_MODE, LOAD_MODE, REDUCTION_MODE, REDUCTION_WRITE_MODE} fsm_state;
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
   logic  [1:0] sew;
    logic [1 : 0] write_data_sel;
    logic [8 * $clog2(MEM_DEPTH) - 1 : 0] vrf_starting_waddr;
    logic [2 : 0][8 * $clog2(MEM_DEPTH) - 1 : 0] vrf_starting_raddr;
    logic [ALU_OPMODE - 1 : 0] ALU_opmode;
   logic 		       reduction_op;
    
} dataPacket0;

dataPacket0 dp0_reg, dp0_next;
// bwen //
logic [VLANE_NUM - 1 : 0][3 : 0] bwen;
logic [3 : 0] shift4_reg, shift4_next;
logic [1 : 0] shift2_reg, shift2_next;
// main counter //
logic [$clog2(MAX_VL_PER_LANE) : 0] main_cnt;
logic main_cnt_en;
logic rst_main_cnt;
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
logic [VLANE_NUM - 1 : 0] read_data_valid;
logic partial_results_valid;
logic shift_partial;

/////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////
// Additional signals - declaration //
// bwen //
logic [3 : 0] bwen_mux;

// address counter //
logic waddr_load;
logic waddr_cnt_rst;
logic raddr_cnt_en;
logic raddr_load;
logic raddr_cnt_rst;
logic [$clog2(MEM_DEPTH) - 1 : 0] waddr;
logic [2 : 0][$clog2(MEM_DEPTH) - 1 : 0] raddr;

// comparators
logic [5 : 0] inst_type_comp;
/////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////
// Assigments //
assign vsew_o = dp0_reg.sew;
assign wdata_width_o = element_width_write;
assign vrf_waddr_o = waddr;
assign vrf_raddr_o = raddr;
assign vmrf_addr_o = vmrf_cnt;
assign vmrf_wen_o = dp0_reg.vmrf_wen & dp0_reg.vector_mask;
assign vrf_bwen_o = ((current_state == LOAD_MODE) & (dp0_reg.waddr_cnt_en == 1)) ? load_bwen_i : bwen;
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
assign read_data_valid_o[VLANE_NUM - 1 : 1] = read_data_valid[VLANE_NUM - 1 : 1];
assign ALU_ctrl_o = dp0_reg.ALU_opmode;
assign reduction_op_o = dp0_reg.reduction_op;
assign waddr_cnt_en = dp0_reg.waddr_cnt_en;
assign request_write_control_o = (current_state == LOAD_MODE) | (current_state == REDUCTION_WRITE_MODE);
// Write address generation //
assign element_width_write = (current_state == LOAD_MODE) ? 2'b10 : 2'(dp0_reg.wdata_width - 1);

/////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////
always_comb begin
   
    if(current_state == REDUCTION_WRITE_MODE) begin
        for(int i = 4; i < VLANE_NUM; i++) begin
            bwen[i] = 0;
        end       
       bwen[1] = 0;
       bwen[2] = 0;
       bwen[3] = 0;
       bwen[0] = {3'b0, bwen_mux[0]};
       if (dp0_reg.sew==2'b01)
	 bwen[1] = {3'b0, bwen_mux[0]};
       else if (dp0_reg.sew==2'b10)
       begin
	  bwen[1] = {3'b0, bwen_mux[0]};
	  bwen[2] = {3'b0, bwen_mux[0]};
	  bwen[3] = {3'b0, bwen_mux[0]};
       end
    end
    else begin
        for(int i = 0; i < VLANE_NUM; i++) begin
            bwen[i] = bwen_mux;
        end
    end
end
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
        if(dp0_reg.bwen_en) begin
            shift4_reg <= {shift4_reg[2 : 0], shift4_reg[3]};
            shift2_reg <= {shift2_reg[0], shift2_reg[1]};
        end
        else begin
            shift4_reg <= 4'b0001;
            shift2_reg <= 2'b01;
        end 
    end
end

always_comb begin

    shift4_next = 4'b0001;
    shift2_next = 2'b01; 

    case(dp0_reg.wdata_width & {2{dp0_reg.en_write}})
        2'b01: bwen_mux = shift4_reg;
        2'b10: bwen_mux = {{2{shift2_reg[1]}}, {2{shift2_reg[0]}}};
        2'b11: bwen_mux = {{4{1'b1}}};
        default: bwen_mux = {{4{1'b0}}};
    endcase
end
/////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////
// Address counters - instantiation // 
Address_counter
#(
    .MEM_DEPTH(MEM_DEPTH),
    .VREG_LOC_PER_LANE(VREG_LOC_PER_LANE),
    .VLANE_NUM(VLANE_NUM),
    .STRIDE_ENABLE("NO")
)
waddr_cnt
(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .slide_offset_i('h0),
    .start_addr_i(dp0_reg.vrf_starting_waddr),
    .load_i(waddr_load),
    .up_down_i(1'b1),
    .element_width_i(element_width_write),
    .rst_cnt_i(waddr_cnt_rst),
    .en_i(waddr_cnt_en),
    .secondary_en_i(1'b1),
    .addr_o(waddr)
);

generate
    for(genvar i = 0; i < 3; i++) begin
        Address_counter
        #(
            .MEM_DEPTH(MEM_DEPTH),
            .VREG_LOC_PER_LANE(VREG_LOC_PER_LANE),
            .VLANE_NUM(VLANE_NUM),
            .STRIDE_ENABLE("NO")
        )
        raddr_cnt
        (
            .clk_i(clk_i),
            .rst_i(rst_i),
	    .slide_offset_i('h0),
            .start_addr_i(dp0_reg.vrf_starting_raddr[i]),
            .load_i(raddr_load),
            .up_down_i(1'b1),
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
    
    .valid_o(read_data_valid),
    .partial_results_valid_o(partial_results_valid)
);
/////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////
// Comparators - implementations //
generate
    for(genvar i = 0; i < INST_TYPE_NUM - 1; i++) begin
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
    read_data_valid_o[0] = read_data_valid[0];
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
    dp0_next.sew = dp0_reg.sew;
    // Loads //
    ready_for_load_o = 0;
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
              dp0_next.inst_delay = inst_delay_i;;
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
	      dp0_next.sew = vsew_i[1 : 0];
              dp0_next.vector_mask = vector_mask_i;
              dp0_next.vrf_starting_raddr = vrf_starting_raddr_i;
              dp0_next.vrf_starting_waddr = vrf_starting_waddr_i;
              dp0_next.ALU_opmode = ALU_opmode_i;
              dp0_next.reduction_op = reduction_op_i;
              dp0_next.vmrf_wen = 0;
           end
            if(dp0_reg.start) begin
                dp0_next.start = 0;
                case(inst_type_comp[5 : 0])
                    6'b000001 : begin                                            // NORMAL
                        next_state = NORMAL_MODE;
                    end
                    6'b000010 : begin                                            // REDUCTION
                        next_state = READ_MODE;                                  
                    end
                    6'b000100 : begin                                            // STORE
                        next_state = READ_MODE;
                        dp0_next.store_data_valid = 1;
                    end
                    6'b001000 : begin                                            // INDEXED_STORE
                        dp0_next.store_data_valid = 1;
                        dp0_next.store_load_index_valid = 1;
                        next_state = READ_MODE;
                    end
                    6'b010000 : begin                                            // LOAD
                        next_state = LOAD_MODE;
         		ready_for_load_o = 1'b1;
    		        
                    end
                    6'b100000 : begin                                            // INDEXED_LOAD
                        dp0_next.store_load_index_valid = 1;
                        next_state = READ_MODE;
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
            
            if(main_cnt == dp0_reg.inst_delay + dp0_reg.read_limit) begin
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
           element_width_read = vsew_i[1:0];
            case({inst_type_comp[5], inst_type_comp[3 : 1]})
                4'b0001 : begin                                            // REDUCTION
                   if(main_cnt == (dp0_reg.read_limit - 1 + dp0_reg.inst_delay)) begin                               // Not yet specified                  
                        next_state = REDUCTION_MODE;
                        rst_main_cnt = 1;
                    end                                   
                end
                4'b0010 : begin                                           // STORE
		    element_width_read = 2'b10; // we read all bytes no matter the sew
                    if(read_limit_comp) begin                               
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
            dp0_next.waddr_cnt_en = 1;
            dp0_next.write_data_sel = 1;
            //if(load_valid_i) begin
              //  dp0_next.waddr_cnt_en = 1;
            //end
            //ready_for_load_o = dp0_reg.waddr_cnt_en;
	    ready_for_load_o = 1'b1;
            
            if(load_last_i) begin
                next_state = IDLE;
	       dp0_next.waddr_cnt_en = 0;
               dp0_next.write_data_sel = 0;
                //ready_for_load_o = 0;
            end 
        end
        REDUCTION_MODE : begin
            // How is ALU going to know when not to accumulate results from other lanes?
            next_state = REDUCTION_MODE;
            
            main_cnt_en = 1;
            
            shift_partial = 1;
            read_data_valid_o[0] = partial_results_valid;
            
            if(main_cnt == VLANE_NUM - 2) begin
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
	        dp0_next.reduction_op=0;
                dp0_next.en_write = 0;
                dp0_next.vmrf_wen = 0;
            end
            
        end
        default : begin
            next_state = IDLE;
        end
    endcase
end
/////////////////////////////////////////////////////////////////////////////////


endmodule
