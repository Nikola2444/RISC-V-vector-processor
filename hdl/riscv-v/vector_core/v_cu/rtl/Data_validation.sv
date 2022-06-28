module Data_validation
#(
    parameter MAX_VL_PER_LANE = 4 * 8 * 8,
    parameter VLANE_NUM = 8
)
(
    input clk_i,
    input rst_i,
    
    input logic [$clog2(VLANE_NUM * MAX_VL_PER_LANE) - 1 : 0] vl_i,
    input logic shift_en_i,
    input logic shift_partial_i,
    input logic load_i,
    
    output logic [VLANE_NUM - 1 : 0] valid_o,
    output logic partial_results_valid_o
    
);

//logic [MAX_VL_PER_LANE - 1 : 0][VLANE_NUM - 1 : 0] valid_struct_reg;
//logic [VLANE_NUM * MAX_VL_PER_LANE - 1 : 0] flattened_struct;
//logic [VLANE_NUM - 2 : 0] partial_results_reg;

//assign valid_o = valid_struct_reg[0];
//assign partial_results_valid_o = partial_results_reg[0];

//always_comb begin
//    flattened_struct = 0;
//    for(int i = 0; i < VLANE_NUM * MAX_VL_PER_LANE; i++) begin
//        if(i < vl_i)
//            flattened_struct[i] = 1;                                            // vl0: 1, vl1: 1, vl2: 1, vl3: 1 | vl0: 1, vl1: 1, vl2: 0, vl3: 0
//    end
//end

//always_ff@(posedge clk_i) begin
//    if(!rst_i) begin
//        valid_struct_reg <= 0;
//        partial_results_reg <= 0;
//    end
//    else begin
//        if(load_i) begin
//                for(int x = 0; x < MAX_VL_PER_LANE; x++) begin
//                    valid_struct_reg[x][0 +: VLANE_NUM] <= flattened_struct[x * VLANE_NUM +: VLANE_NUM];
//                end
//                partial_results_reg <= flattened_struct[1 +: VLANE_NUM];
//        end
//        else if(shift_en_i) begin
//            for(int x = 0; x < MAX_VL_PER_LANE - 1; x++) begin
//                valid_struct_reg[x] <= valid_struct_reg[x + 1];
//            end
//            valid_struct_reg[MAX_VL_PER_LANE - 1] <= 0;
//        end
//        else if(shift_partial_i) begin
//            for(int i = 0; i < VLANE_NUM - 2; i++) begin
//                partial_results_reg[i] <= partial_results_reg[i + 1];
//            end
//            partial_results_reg[VLANE_NUM - 2] <= 0;
//        end
//    end
//end

/////////////////////////////////////////////////////////////////////////////////////////////////
// vl_i % VLANE_NUM, vl_i / VLANE_NUM
logic [$clog2(MAX_VL_PER_LANE) - 1 : 0] base_counter, div;
logic [$clog2(VLANE_NUM) - 1 : 0] mod;
logic [VLANE_NUM - 1 : 0] last_valid, last_valid_comb;
logic [VLANE_NUM - 2 : 0] partial_results_reg;

assign mod = vl_i[$clog2(VLANE_NUM) - 1 : 0];
assign div = vl_i >> $clog2(VLANE_NUM);
assign partial_results_valid_o = partial_results_reg[0];

always_comb begin
    last_valid_comb = 0;
    for(int i = 0; i < 2 ** $clog2(VLANE_NUM); i++) begin
        if(i < mod) begin
            last_valid_comb[i] = 1;
        end
    end
    
    valid_o = ((base_counter == div) ? last_valid : {VLANE_NUM{1'b1}}) & {VLANE_NUM{shift_en_i}};
end

always_ff@(posedge clk_i) begin
    if(!rst_i) begin
        base_counter <= 0;
        last_valid <= 0;
        partial_results_reg <= 0;
    end
    else begin
        if(load_i) begin
            base_counter <= 0;
            last_valid <= last_valid_comb;
            
            partial_results_reg <= {(VLANE_NUM - 1){1'b1}};
            if(div == 0) begin
                partial_results_reg <= last_valid_comb[VLANE_NUM - 1 : 1];              // bit 0 -> LANE 1, bit 1 -> LANE 2, ...
            end
        end
        else if(shift_en_i) begin
            if(base_counter == div) begin
                if(last_valid != 0) begin
                    last_valid <= 0;
                end
            end
            else begin
                base_counter <= base_counter + 1;
            end
        end
        else if(shift_partial_i) begin
            for(int i = 0; i < VLANE_NUM - 2; i++) begin
                partial_results_reg[i] <= partial_results_reg[i + 1];
            end
            partial_results_reg[VLANE_NUM - 2] <= 0;
        end
    end
end


endmodule
