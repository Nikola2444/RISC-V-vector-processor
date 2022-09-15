
//  Xilinx Simple Dual Port Single Clock RAM with Byte-write
//  This code implements a parameterizable SDP single clock memory.
//  If a reset or enable is not necessary, it may be tied off or removed from the code.

module sdp_bwe_bram #(
		      parameter NB_COL    = 8,                        // Specify number of columns (number of bytes)
		      parameter COL_WIDTH = 8,                        // Specify column width (byte width, typically 8 or 9)
		      parameter RAM_DEPTH = 512,                      // Specify RAM depth (number of entries)
		      parameter RAM_PERFORMANCE = "HIGH_PERFORMANCE", // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
		      parameter IN_REG_NUM = 0, // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
		      parameter INIT_FILE = ""                        // Specify name/location of RAM initialization file if using one (leave blank if not)
		      ) (
			 input 			  clka, // Clock
			 input 			  clkb, // Clock
			 input [clogb2(RAM_DEPTH-1)-1:0] addra, // Write address bus, width determined from RAM_DEPTH
			 input [(NB_COL*COL_WIDTH)-1:0]  dina, // RAM input data
			 input [NB_COL-1:0] 		  wea, // Byte-write enable
			 input [clogb2(RAM_DEPTH-1)-1:0] addrb, // Read address bus, width determined from RAM_DEPTH
			 output [(NB_COL*COL_WIDTH)-1:0] doutb, // RAM output data
			 input 			  enb, // Read Enable, for additional power savings, disable when not in use
			 input 			  rstb, // Output reset (does not affect memory contents)
			 input 			  regceb                         // Output register enable
			 );

   reg [(NB_COL*COL_WIDTH)-1:0] BRAM [RAM_DEPTH-1:0]='{default:'0};
   reg [(NB_COL*COL_WIDTH)-1:0] ram_data = {(NB_COL*COL_WIDTH){1'b0}};
   reg [(NB_COL*COL_WIDTH)-1:0] in_data_reg = {(NB_COL*COL_WIDTH){1'b0}};

   // The following code either initializes the memory values to a specified file or to all zeros to match hardware

   /* -----\/----- EXCLUDED -----\/-----
    generate
    if (INIT_FILE != "") begin: use_init_file
    initial
    $readmemh(INIT_FILE, BRAM, 0, RAM_DEPTH-1);
    end else begin: init_bram_to_zero
    integer ram_index;
    initial
    for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
    //BRAM[ram_index] = ram_index%16;	
    BRAM[ram_index] = {(NB_COL*COL_WIDTH){1'b0}};
    end
  endgenerate
    -----/\----- EXCLUDED -----/\----- */

   // Registers
   generate
      if (IN_REG_NUM>0)
      begin
	 logic [IN_REG_NUM-1:0][clogb2(RAM_DEPTH-1)-1:0] addra_reg;
	 logic [IN_REG_NUM-1:0][(NB_COL*COL_WIDTH)-1:0]  dina_reg; 
	 logic [IN_REG_NUM-1:0][NB_COL-1:0]              wea_reg;
	 logic [IN_REG_NUM-1:0][clogb2(RAM_DEPTH-1)-1:0] addrb_reg;

	 
	 always_ff@(posedge clka) begin
	    addra_reg[0] <= addra;
	    dina_reg[0] <= dina;
	    wea_reg[0] <= wea;
	    for (int i=1; i<IN_REG_NUM; i++)
	    begin
	       addra_reg[i] <= addra_reg[i-1];
	       dina_reg[i] <= dina_reg[i-1];
	       wea_reg[i] <= wea_reg[i-1];
	    end
	 end
	 always_ff@(posedge clkb) begin
	    addrb_reg[0] <= addrb;
	    for (int i=1; i<IN_REG_NUM; i++)
	    begin
	       addrb_reg[i] <= addrb_reg[i-1];
	    end
	 end

	 always @(posedge clkb)
	   if (enb)
	     ram_data <= BRAM[addrb_reg[IN_REG_NUM-1]];

	 genvar i;
	 for (i = 0; i < NB_COL; i = i+1) begin: byte_write
	    always @(posedge clka)
              if (wea_reg[IN_REG_NUM-1][i])
		BRAM[addra_reg[IN_REG_NUM-1]][(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= dina_reg[IN_REG_NUM-1][(i+1)*COL_WIDTH-1:i*COL_WIDTH];
	 end
      end//if (IN_REG_NUM==YES)
      else
      begin
	 //read logic
	 always @(posedge clkb)
	   if (enb)
	     ram_data <= BRAM[addrb];
	 //write logic
	 genvar i;
	 for (i = 0; i < NB_COL; i = i+1) begin: byte_write
	    always @(posedge clka)
              if (wea[i])
		BRAM[addra][(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= dina[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
	    //BRAM[addra][(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= in_data_reg[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
	 end
      end
	
   endgenerate


   //  The following code generates HIGH_PERFORMANCE (use output register) or LOW_LATENCY (no output register)
   generate
      if (RAM_PERFORMANCE == "LOW_LATENCY") begin: no_output_register

	 // The following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing
	 assign doutb = ram_data;

      end else begin: output_register

	 // The following is a 2 clock cycle read latency with improve clock-to-out timing

	 reg [(NB_COL*COL_WIDTH)-1:0] doutb_reg = {(NB_COL*COL_WIDTH){1'b0}};

	 always @(posedge clkb)
           if (rstb)
             doutb_reg <= {(NB_COL*COL_WIDTH){1'b0}};
           else if (regceb)
             doutb_reg <= ram_data;

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

