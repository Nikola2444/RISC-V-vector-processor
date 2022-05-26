`timescale 1ns / 1ps

module Register_File
    #(
        parameter data_width = 1,
        parameter r_ports_num = 4,
        parameter w_ports_num = 4,
        parameter rf_depth = 32
    )
    (
        input clk_i,
        input rst_i,
        
        output logic [r_ports_num - 1 : 0][data_width - 1 : 0] read_data_o,
        input logic [r_ports_num - 1 : 0][$clog2(rf_depth) - 1 : 0] read_addr_i,
        
        input logic [w_ports_num - 1 : 0][data_width - 1 : 0] write_data_i,
        input logic [w_ports_num - 1 : 0][$clog2(rf_depth) - 1 : 0] write_addr_i,
        input logic [w_ports_num - 1 : 0] write_en_i
    );
    

logic [data_width - 1 : 0] rf [rf_depth - 1 : 0];

always_ff@(posedge clk_i) begin
    if(!rst_i) begin
        rf <= '{default : '0};
    end
    else begin
        for(int i = 0; i < w_ports_num; i++) begin
            if(write_en_i[i]) begin
                rf[write_addr_i[i]] <= write_data_i[i];
            end
        end
        
        for(int j = 0; j < r_ports_num; j++) begin
            read_data_o[j] <= rf[read_addr_i[j]];
        end
    end
end

endmodule
