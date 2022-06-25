//------------------------------------------------------------------------------
// Copyright (c) 2021 Neuronix AI Labs; All rights reserved.
//------------------------------------------------------------------------------
// File name   : xilinx_distram_sdp_ram.sv
// Author      : Elchanan Rappaport, elchananr@Veriests.com
// Created     : 31-Jan-2021
// Description : Distributed RAM behavioral model
// Notes       :
//------------------------------------------------------------------------------

module sdp_distram #(
  parameter WIDTH = 1,
  parameter DEPTH = 512,
  parameter OUT_PIPE_STAGES = 0
) (/*AUTOARG*/
   // Outputs
   doutb,
   // Inputs
   clka, clkb, rstb, wea, regceb, addra, dina, enb, addrb
   );

  input                      clka;
  input                      clkb;
  input                      rstb;
  input                      wea;
  input                      regceb;
  input  [$clog2(DEPTH)-1:0] addra;
  input  [WIDTH-1:0]         dina;
  input 		     enb;
  output [WIDTH-1:0]         doutb;
  input  [$clog2(DEPTH)-1:0] addrb;

  (* ram_style = "distributed" *) reg [WIDTH-1:0] ram [DEPTH-1:0] = '{default:0};

  always @(posedge clka)
  begin
    if (wea)
      ram[addra] <= dina;
  end

  generate
    if (OUT_PIPE_STAGES == 0)
    begin
      assign doutb = ram[addrb];
    end
    else
    begin
      reg [OUT_PIPE_STAGES-1:0][WIDTH-1:0] doutb_d_reg;
      always@(posedge clkb)
      begin
        if (rstb)
        begin          
          doutb_d_reg <= 0;
        end
        else
        begin
	  if (enb)
	     doutb_d_reg[0] <= ram[addrb];
          if (regceb)
          begin            
            for (int i=1; i<OUT_PIPE_STAGES;i++)
            begin            
              doutb_d_reg[i] <= doutb_d_reg[i-1];
            end
          end
        end
      end // always@ (posedge clkb)
      assign doutb = doutb_d_reg[OUT_PIPE_STAGES-1];
    end
  endgenerate

endmodule


