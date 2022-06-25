module Column_offset_register
#(
    parameter VREG_LOC_PER_LANE = 8,
    parameter VLANE_NUM = 8
)
(
    input clk_i,
    input rst_i,
    
    input logic [1 : 0] input_sel_i,                                            // 00 - NOP, 01 - right shift, 10 - left shift, 11 - parallel input
    input logic [1 : 0] adder_input_sel_i,                                      // 00 - SA + i, 01 - SA + VLANE_NUM - i, 10 - shift_reg - 1, 11 - NOT DEFINED
    input logic en_comp_i,
    input logic start_decrementor_i,                                              // 1 - start decrementing
    input logic [$clog2(VREG_LOC_PER_LANE * 4 * 8 * VLANE_NUM) - 1 : 0] shift_amount_i,
    output logic [VLANE_NUM - 1 : 0] valid_data_o,
    output logic [VLANE_NUM - 1 : 0] slide_write_data_pattern_o,
    output logic enable_write_slide_o
);


function logic orTree(input logic [VLANE_NUM - 1 : 0] vector);
    
    // 4, 6, 7 => 4 + 2 ** (i - 1)
    
    // For VLANE_NUM = 4
    localparam R = $clog2(VLANE_NUM);                           // 2
    localparam TREE_WIDTH = ((R ** (R + 1)) - 1) / (R - 1);     // 7
    logic [TREE_WIDTH - 1 : 0] localVector;
    
    localVector = {{(TREE_WIDTH - VLANE_NUM){1'b0}}, vector};   // 000 & vector
    
    for(int i = R; i >= 1; i--) begin                           
        for(int j = 0; j < i; j++) begin                        
            localVector[2 ** i + j] = localVector[2 * j] | localVector[2 * j + 1];
        end
        localVector = localVector >> (VLANE_NUM >> (R - i));
    end
    
    return localVector[0];
    
endfunction

localparam RIGHT_SHIFT = 2'(1);
localparam LEFT_SHIFT = 2'(2);
localparam PARALLEL_WRITE = 2'(3);

logic [VLANE_NUM - 1 : 0][$clog2(VREG_LOC_PER_LANE * 4 * 8) - 1 : 0] shift_reg, shift_next;
logic [VLANE_NUM - 1 : 0][$clog2(VREG_LOC_PER_LANE * 4 * 8 * VLANE_NUM) : 0] adder;
logic [VLANE_NUM - 1 : 0][$clog2(VREG_LOC_PER_LANE * 4 * 8) - 1 : 0] parallel_input;
logic [VLANE_NUM - 1 : 0][$clog2(VREG_LOC_PER_LANE * 4 * 8 * VLANE_NUM) - 1 : 0] op1;
logic [VLANE_NUM - 1 : 0][$clog2(VREG_LOC_PER_LANE * 4 * 8) - 1 : 0] op2;
logic [VLANE_NUM - 1 : 0] shift_reg_comp;
logic [VLANE_NUM - 1 : 0] valid_data;
logic [VLANE_NUM - 1 : 0] slide_write_data_pattern_reg, slide_write_data_pattern_next;
logic or_tree, or_tree_ff;
// Revised solution
logic [$clog2(VREG_LOC_PER_LANE * 4 * 8) - 1 : 0] decrementor;
logic decrement_comp;

assign valid_data_o = ~valid_data;
assign valid_data = (en_comp_i == 1) ? shift_reg_comp : 0;
assign slide_write_data_pattern_o = slide_write_data_pattern_reg;
assign decrement_comp = (decrementor == 0); 
assign enable_write_slide_o = decrement_comp;
assign or_tree = orTree(~shift_reg_comp);

//////////////////////////////////////////////////////////
// Decrementor for enable signal
always_ff@(posedge clk_i) begin
    if(!rst_i) begin
        decrementor <= 0;
        or_tree_ff <= 0;
    end
    else begin
        if((adder_input_sel_i == 2'b00) | (adder_input_sel_i == 2'b01))
            decrementor <= (shift_amount_i >> $clog2(VLANE_NUM));
        if(start_decrementor_i) begin
            if(!decrement_comp)
                decrementor <= decrementor - 1;
        end
        
        or_tree_ff <= or_tree;
    end
end
//////////////////////////////////////////////////////////

always_comb begin
    for(int i = 0; i < VLANE_NUM; i++) begin
        shift_reg_comp[i] = (shift_reg[i] != 0);
    end   
    
    slide_write_data_pattern_next = slide_write_data_pattern_reg;
    
    if(or_tree & (~or_tree_ff)) begin
        slide_write_data_pattern_next = ~shift_reg_comp;
    end
    
end

always_ff@(posedge clk_i) begin
    if(!rst_i) begin
        shift_reg <= 0;
        slide_write_data_pattern_reg <= 0;
    end
    else begin
        shift_reg <= shift_next;
        slide_write_data_pattern_reg <= slide_write_data_pattern_next;
    end 
end

always_comb begin
    case(input_sel_i)
            RIGHT_SHIFT : begin
                for(int i = VLANE_NUM - 1; i >= 1; i--) begin
                    shift_next[i] = shift_reg[i - 1];
                end
                shift_next[0] = shift_reg[VLANE_NUM - 1];
            end
            LEFT_SHIFT : begin
                for(int i = 0; i < VLANE_NUM - 1; i++) begin
                    shift_next[i] = shift_reg[i + 1];
                end
                shift_next[VLANE_NUM - 1] = shift_reg[0];            
            end
            PARALLEL_WRITE : begin
                for(int i = 0; i < VLANE_NUM; i++) begin
                    shift_next[i] = parallel_input[i]; 
                end
            end
            default : begin
                for(int i = 0; i < VLANE_NUM; i++) begin
                    shift_next[i] = shift_reg[i]; 
                end
            end
        endcase

end

generate
    for(genvar i = 0; i < VLANE_NUM; i++) begin
        always_comb begin
            case(adder_input_sel_i)
                2'b00 : begin                           // SA + i
                    op1[i] = shift_amount_i;
                    op2[i] = $clog2(VREG_LOC_PER_LANE * 4 * 8)'(i);
                end
                2'b01 : begin                           // SA + VLANE_NUM - i
                    op1[i] = shift_amount_i;
                    op2[i] = $clog2(VREG_LOC_PER_LANE * 4 * 8)'(VLANE_NUM - i);
                end
//                2'b10 : begin                           // shift_reg - 1
//                    op1[i] = shift_reg[i];
//                    op2[i] = $clog2(VREG_LOC_PER_LANE * 4 * 8)'(-1);
//                end
                default : begin
                    op1[i] = 0;
                    op2[i] = 0;
                end
            endcase
                        
            adder[i] = op1[1] + op2[i];
        end
        
        always_comb begin
            case(adder_input_sel_i)
                2'b00 : begin
                    parallel_input[i] = adder[i][$clog2(VLANE_NUM) +: $clog2(VREG_LOC_PER_LANE * 4 * 8)];
                end
                2'b01 : begin
                    parallel_input[i] = adder[i][$clog2(VLANE_NUM) +: $clog2(VREG_LOC_PER_LANE * 4 * 8)];
                end
                2'b10 : begin
                    logic sub;
                    sub = shift_reg[i] - 1;
                    parallel_input[i] = (shift_reg_comp[i] == 0) ? 0 : sub;
                end
                default : begin
                    parallel_input[i] = 0;
                end
            endcase
        end
        
    end
endgenerate;

endmodule
