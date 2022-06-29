module Address_counter
#(
    parameter MEM_DEPTH = 512,
    parameter VREG_LOC_PER_LANE = 8,
    parameter VLANE_NUM = 8,
    parameter STRIDE_ENABLE = "YES"
)
(
    input clk_i,
    input rst_i,
    
    input logic [8 * $clog2(MEM_DEPTH) - 1 : 0] start_addr_i,
    input logic [$clog2(MEM_DEPTH)-1:0]                          slide_offset_i,
    input logic load_i,
    input logic rst_cnt_i,
    input logic up_down_i,                                          // UP for 1, DOWN for 0
    input logic [1 : 0] element_width_i,
    input logic en_i,
    input logic secondary_en_i,
    output logic [$clog2(MEM_DEPTH) - 1 : 0] addr_o
);

localparam MIN_SEW = 8;

logic [7 : 0][$clog2(MEM_DEPTH) - 1 : 0] shift_reg;
logic shift;
logic [$clog2(VREG_LOC_PER_LANE * (32 / MIN_SEW)) - 1 : 0] counter;
logic [$clog2(VREG_LOC_PER_LANE * (32 / MIN_SEW)) - 1 : 0] counter_limit;
logic counter_limit_comp;
logic [$clog2(VREG_LOC_PER_LANE * (32 / MIN_SEW)) - 1 : 0] counter_mux;
logic [$clog2(MEM_DEPTH) - 1 : 0] adder;
// Signals for slides //
logic [$clog2(VREG_LOC_PER_LANE * (32 / MIN_SEW)) - 1 : 0] counter_rst_value, addsub, cnt_op;
logic [8 * $clog2(MEM_DEPTH) - 1 : 0] start_value;

localparam CNT_LIMIT_BYTE = (VREG_LOC_PER_LANE << 2) - 1;
localparam CNT_LIMIT_HALFWORD = (VREG_LOC_PER_LANE << 1) - 1;
localparam CNT_LIMIT_WORD = VREG_LOC_PER_LANE - 1;

// Functions //
function logic [8 * $clog2(MEM_DEPTH) - 1 : 0] reverseElements(input logic [8 * $clog2(MEM_DEPTH) - 1 : 0] vector);
    localparam EL_WIDTH = $clog2(MEM_DEPTH);
    logic [8 * EL_WIDTH - 1 : 0] returnVector;
    for(int i = 0; i < 8; i++) begin
        returnVector[i * EL_WIDTH +: EL_WIDTH] = vector[(8 - i) * EL_WIDTH - 1 -: EL_WIDTH];
    end
    return returnVector;
endfunction

assign adder = shift_reg[0] + counter_mux;

generate    
    
    if(STRIDE_ENABLE == "YES") begin
        assign counter_limit_comp = (up_down_i == 1'b1) ? (counter == counter_limit) : (counter == 0);
        assign counter_rst_value = (up_down_i == 1'b1) ? 0 : counter_limit;
        assign addsub = counter + cnt_op;
        assign cnt_op = (up_down_i == 1'b1) ? 1 : -1; 
        assign start_value = (up_down_i == 1'b1) ? start_addr_i : reverseElements(start_addr_i);
        
        always_comb begin
            case(element_width_i)
                2'b00 : begin
                    counter_limit = CNT_LIMIT_BYTE;
                    counter_mux = {2'b00, counter[$clog2(VREG_LOC_PER_LANE * (32 / MIN_SEW)) - 1 : 2]};
                end
                2'b01 : begin
                    counter_limit = CNT_LIMIT_HALFWORD;
                    counter_mux = {1'b0, counter[$clog2(VREG_LOC_PER_LANE * (32 / MIN_SEW)) - 1 : 1]};
                end
                2'b10 : begin
                    counter_limit = CNT_LIMIT_WORD;
                    counter_mux = counter;
                end
                default : begin
                    counter_limit = 0;
                    counter_mux = 0;
                end
            endcase
        end
        
        always_ff@(posedge clk_i) begin
            if(!rst_i) begin
                shift_reg <= 0;
            end
            else begin
                if(load_i) begin
                    for(int i = 0; i < 8; i++)
                      if (i == 0)
			if (up_down_i)
                          shift_reg[i] <= start_addr_i[i * $clog2(MEM_DEPTH) +: $clog2(MEM_DEPTH)] + slide_offset_i[$clog2(MEM_DEPTH)-1:0];
		        else
			  shift_reg[i] <= start_addr_i[i * $clog2(MEM_DEPTH) +: $clog2(MEM_DEPTH)] - slide_offset_i[$clog2(MEM_DEPTH)-1:0];
		      else
                        shift_reg[i] <= start_addr_i[i * $clog2(MEM_DEPTH) +: $clog2(MEM_DEPTH)];
                end
                else begin
                    if(shift) begin
                        for(int i = 1; i < 8; i++)
                            shift_reg[i - 1] <= shift_reg[i];
                        shift_reg[7] <= 0;    
                    end
                end 
            end
        end
        
        always_ff@(posedge clk_i) begin
            if(!rst_i) begin
                counter <= 0;
            end
            else begin
                
                if(rst_cnt_i) begin
                    counter <= counter_rst_value;
                end
                else begin
                    if(en_i & secondary_en_i) begin
                        if(counter_limit_comp)
                            counter <= counter_rst_value;
                        else
                            counter <= addsub;
                    end
                end
     
            end
        end
        
        assign addr_o = adder;
        assign shift = counter_limit_comp;
    end
    
    // end of the if part
    
    else begin
        assign counter_limit_comp = (counter == counter_limit);
        
        always_comb begin
            case(element_width_i)
                2'b00 : begin
                    counter_limit = CNT_LIMIT_BYTE;
                    counter_mux = {2'b00, counter[$clog2(VREG_LOC_PER_LANE * (32 / MIN_SEW)) - 1 : 2]};
                end
                2'b01 : begin
                    counter_limit = CNT_LIMIT_HALFWORD;
                    counter_mux = {1'b0, counter[$clog2(VREG_LOC_PER_LANE * (32 / MIN_SEW)) - 1 : 1]};
                end
                2'b10 : begin
                    counter_limit = CNT_LIMIT_WORD;
                    counter_mux = counter;
                end
                default : begin
                    counter_limit = 0;
                    counter_mux = 0;
                end
            endcase
        end
        
        always_ff@(posedge clk_i) begin
            if(!rst_i) begin
                shift_reg <= 0;
            end
            else begin
                if(load_i) begin
                    for(int i = 0; i < 8; i++)
		      if (i == 0)
                        shift_reg[i] <= start_addr_i[i * $clog2(MEM_DEPTH) +: $clog2(MEM_DEPTH)] + slide_offset_i[$clog2(MEM_DEPTH)-1:0];
		      else
                        shift_reg[i] <= start_addr_i[i * $clog2(MEM_DEPTH) +: $clog2(MEM_DEPTH)];
                end
                else begin
                    if(shift) begin
                        for(int i = 1; i < 8; i++)
                            shift_reg[i - 1] <= shift_reg[i];
                        shift_reg[7] <= 0;    
                    end
                end 
            end
        end
        
        always_ff@(posedge clk_i) begin
            if(!rst_i) begin
                counter <= 0;
            end
            else begin
            
                if(rst_cnt_i) begin
                    counter <= 0;
                end
                else begin
                    if(en_i & secondary_en_i) begin
                        if(counter_limit_comp)
                            counter <= 0;
                        else
                            counter <= counter + 1;
                    end
                end 
            end
        end
        
        assign addr_o = adder;
        assign shift = counter_limit_comp;
    end

endgenerate;
    
endmodule
