//------------------------------------------------------------------------------
// Copyright (c) 2021 Neuronix AI Labs; All rights reserved.
//------------------------------------------------------------------------------
// File name   : xilinx_uram_tdp_ram.sv
// Author      : Nikola Kovacevic NikolaKo@VeriestS.com
// Created     : 3-Aug-2021
// Description : True Dual Port Block RAM
// Notes       : 
//------------------------------------------------------------------------------ 


module xilinx_bram_sdp_ram #(
  parameter WIDTH = 72,                       // Specify RAM data width  
  parameter DEPTH = 2048,                     // Specify RAM depth (number of entries)
  parameter RAM_PERFORMANCE = "HIGH_PERFORMANCE", // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
  parameter CASCADE_HEIGHT = 0, 
  parameter INIT_FILE = ""                        // Specify name/location of RAM initialization file if using one (leave blank if not)
) (/*AUTOARG*/
   // Outputs
   doutb,
   // Inputs
   addra, addrb, dina, clka, wea, ena, enb, clkb, rstb, oreg_enb
   );

  input [clogb2(DEPTH-1)-1:0] addra;  // Port A address bus, width determined from RAM_DEPTH
  input [clogb2(DEPTH-1)-1:0] addrb;  // Port B address bus, width determined from RAM_DEPTH
  input [WIDTH-1:0] dina;           // Port A RAM input data
  input clka;                           // Clock
  input wea;                            // Port A write enable
  input ena;                            // Port A RAM Enable, for additional power savings, disable port when not in use
  input enb;                            // Port B RAM Enable, for additional power savings, disable port when not in use
  input clkb;                           // Clock
  input rstb;                           // Port B output reset (does not affect ram contents)
  input oreg_enb;                         // Port B output register enable
  output [WIDTH-1:0] doutb;         // Port B RAM output data

  (* cascade_height = CASCADE_HEIGHT *)(* ram_style = "block" *) reg [WIDTH-1:0] ram[DEPTH];

  reg [WIDTH-1:0] ram_data_b = {WIDTH{1'b0}};

    
  // The following code either initializes the ram values to a specified file or to all zeros to match hardware
  generate
    if (INIT_FILE != "") begin: use_init_file
      initial
        $readmemh(INIT_FILE, ram, 0, DEPTH-1);
    end else begin: init_memory_to_zero
      integer ram_index;
      initial
        for (ram_index = 0; ram_index < DEPTH; ram_index = ram_index + 1)
          ram[ram_index] = {WIDTH{1'b0}};
    end
  endgenerate
  // PORT A
  always @(posedge clka) begin    
    if (ena)
      if (wea)
        ram[addra] <= dina;
  end

  // PORT B
  always @(posedge clkb) begin
    if (enb)
        ram_data_b <= ram[addrb];
  end

  //  The following code generates HIGH_PERFORMANCE (use output register) or LOW_LATENCY (no output register)
  generate
    if (RAM_PERFORMANCE == "LOW_LATENCY") begin: no_output_register

      // The following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing
      
      assign doutb = ram_data_b;

    end else begin: output_register

      // The following is a 2 clock cycle read latency with improve clock-to-out timing

      reg [WIDTH-1:0] doutb_reg = {WIDTH{1'b0}};

      always @(posedge clkb)
        if (rstb)
          doutb_reg <= {WIDTH{1'b0}};
        else if (oreg_enb)
          doutb_reg <= ram_data_b;

      assign doutb = doutb_reg;

    end
  endgenerate

  //  The following function calculates the address width based on specified RAM depth
  function integer clogb2;
    input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
  endfunction

endmodule

                                                        
