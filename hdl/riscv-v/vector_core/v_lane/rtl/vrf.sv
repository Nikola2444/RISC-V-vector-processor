module vrf #
  (parameter R_PORTS_NUM = 8,
   parameter W_PORTS_NUM = 4,
   parameter MULTIPUMP_WRITE = 2,
   parameter MULTIPUMP_READ = 2,
   parameter RAM_TYPE = "BRAM",
   parameter RAM_PERFORMANCE = "HIGH_PERFORMANCE", // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
   // 
   parameter MEM_DEPTH = 512,
   parameter MEM_WIDTH = 32,
   parameter NUM_OF_BYTES = MEM_WIDTH < 8 ? 1 : MEM_WIDTH/8)
   (
    input 					   clk,
    input 					   clk2,
    input 					   rstn,

   
    // read IF
    input [R_PORTS_NUM-1:0][$clog2(MEM_DEPTH)-1:0] raddr_i,
    input [R_PORTS_NUM-1:0] 			   ren_i,
    input [R_PORTS_NUM-1:0] 			   oreg_en_i, 
    output [R_PORTS_NUM-1:0] [MEM_WIDTH-1:0] 	   dout_o,
   
    // write IF
    input [W_PORTS_NUM-1:0][$clog2(MEM_DEPTH)-1:0] waddr_i,
    input [W_PORTS_NUM-1:0][NUM_OF_BYTES-1:0] 	   bwe_i,
    //input [W_PORTS_NUM-1:0] 			   wen_i,
    input [W_PORTS_NUM-1:0] [MEM_WIDTH-1:0] 	   din_i
    );
   
   localparam LP_BANK_NUM           = W_PORTS_NUM/MULTIPUMP_WRITE;
   localparam LP_LVT_BRAM_PER_BANK  = W_PORTS_NUM/MULTIPUMP_WRITE-1;
   localparam LP_READ_BRAM_PER_BANK = R_PORTS_NUM/MULTIPUMP_READ;
   localparam LP_INPUT_REG_NUM      = RAM_PERFORMANCE == "HIGH_PERFORMANCE" && MULTIPUMP_WRITE==1 ? 2 : 1;
   //localparam LP_INPUT_REG_NUM      = RAM_PERFORMANCE == "HIGH_PERFORMANCE" ? 2 : 1;
   typedef int 					   lvt_raddr_type[LP_BANK_NUM][LP_LVT_BRAM_PER_BANK];
   localparam lvt_raddr_type lvt_raddr_array=lvt_raddr_set();

   

   function lvt_raddr_type lvt_raddr_set();
      automatic int k=0;   
      lvt_raddr_type  lvt_raddr_array;
      for (int i=0; i<LP_BANK_NUM;i++)
      begin
	 k=0;
	 for (int j=0; j<W_PORTS_NUM;j+=MULTIPUMP_WRITE)
	 begin
	    if (j!=i*MULTIPUMP_WRITE)
	    begin
	       lvt_raddr_array[i][k]=j;		 
	       k++;
	    end
	 end
      end
      return lvt_raddr_array;
   endfunction // 0


   
   //localparam int [LP_BANK_NUM][LP_LVT_BRAM_PER_BANK] LP_LVT_RAM_WADDR_ARRAY = lvt_r_addr_array();

   logic [LP_BANK_NUM-1:0][LP_LVT_BRAM_PER_BANK-1:0][$clog2(MEM_DEPTH)-1:0] lvt_ram_raddr;
   logic [LP_BANK_NUM-1:0][LP_LVT_BRAM_PER_BANK-1:0] 			    lvt_ram_ren;
   logic [LP_BANK_NUM-1:0][LP_LVT_BRAM_PER_BANK-1:0] 			    lvt_ram_oreg_en; 
   logic [LP_BANK_NUM-1:0][LP_LVT_BRAM_PER_BANK-1:0] [MEM_WIDTH-1:0] 	    lvt_ram_dout;
   
   // LVT BRAMs IF
   logic [LP_BANK_NUM-1:0][LP_LVT_BRAM_PER_BANK-1:0][$clog2(MEM_DEPTH)-1:0] lvt_ram_waddr;
   logic [LP_BANK_NUM-1:0][LP_LVT_BRAM_PER_BANK-1:0][NUM_OF_BYTES-1:0] 	    lvt_ram_bwe;
   logic [LP_BANK_NUM-1:0][LP_LVT_BRAM_PER_BANK-1:0] 			    lvt_ram_wen;
   logic [LP_BANK_NUM-1:0][LP_LVT_BRAM_PER_BANK-1:0][MEM_WIDTH-1:0] 	    lvt_ram_din;

   logic [LP_BANK_NUM-1:0][LP_READ_BRAM_PER_BANK-1:0][$clog2(MEM_DEPTH)-1:0] read_ram_raddr;
   logic [LP_BANK_NUM-1:0][LP_READ_BRAM_PER_BANK-1:0] 			     read_ram_ren;
   logic [LP_BANK_NUM-1:0][LP_READ_BRAM_PER_BANK-1:0] 			     read_ram_oreg_en; 
   logic [LP_BANK_NUM-1:0][LP_READ_BRAM_PER_BANK-1:0] [MEM_WIDTH-1:0] 	     read_ram_dout;
   
   // READ BRAMs IF
   logic [LP_BANK_NUM-1:0][LP_READ_BRAM_PER_BANK-1:0][$clog2(MEM_DEPTH)-1:0] read_ram_waddr;
   logic [LP_BANK_NUM-1:0][LP_READ_BRAM_PER_BANK-1:0][NUM_OF_BYTES-1:0] 	     read_ram_bwe;
   logic [LP_BANK_NUM-1:0][LP_READ_BRAM_PER_BANK-1:0][MEM_WIDTH-1:0] 	     read_ram_din;

   //input registers

   //logic [R_PORTS_NUM-1:0][$clog2(MEM_DEPTH)-1:0] 			     raddr_reg;
   //logic [R_PORTS_NUM-1:0] 						     ren_reg;
   //logic [R_PORTS_NUM-1:0] 						     oreg_en_reg; 
   //logic [R_PORTS_NUM-1:0] [MEM_WIDTH-1:0] 				     data_reg;
   
   // write IF
   logic [W_PORTS_NUM-1:0][LP_INPUT_REG_NUM-1:0][$clog2(MEM_DEPTH)-1:0]      waddr_reg;
   logic [W_PORTS_NUM-1:0][LP_INPUT_REG_NUM-1:0][NUM_OF_BYTES-1:0] 	     bwe_reg;
   //logic [W_PORTS_NUM-1:0][LP_INPUT_REG_NUM-1:0] 			     wen_reg;
   logic [W_PORTS_NUM-1:0][LP_INPUT_REG_NUM-1:0][MEM_WIDTH-1:0] 	     din_reg;


   logic [$clog2(MULTIPUMP_WRITE)-1:0] 					     multipump_sel_reg;
   logic [LP_BANK_NUM-1:0][LP_BANK_NUM-1:0][MEM_WIDTH-1:0] 		     lvt_write_xor_in;
   logic [LP_BANK_NUM-1:0][MEM_WIDTH-1:0] 				     lvt_write_xor_out;
   logic [LP_READ_BRAM_PER_BANK-1:0][LP_BANK_NUM-1:0][MEM_WIDTH-1:0] 	     lvt_read_xor;

   logic 								     read_clk;
   
   
   always @(posedge clk)
   begin
      if (!rstn)
      begin
	 waddr_reg <= '{default:'0};
	 bwe_reg   <= '{default:'0};
	 //wen_reg   <= '{default:'0};
	 din_reg   <= '{default:'0};
      end
      else
	if (LP_INPUT_REG_NUM > 1)
	begin
	   for (int i = 0; i<W_PORTS_NUM; i++)
	   begin
	      waddr_reg[i] <= {waddr_reg[i][LP_INPUT_REG_NUM-2:0],waddr_i[i]};
	      bwe_reg[i] <= {bwe_reg[i][LP_INPUT_REG_NUM-2:0],bwe_i[i]};
              //wen_reg[i] <= {wen_reg[i][LP_INPUT_REG_NUM-2:0],wen_i[i]};
              din_reg[i] <= {din_reg[i][LP_INPUT_REG_NUM-2:0],din_i[i]};	      
	   end
	end
	else
	begin
	   for (int i = 0; i<W_PORTS_NUM; i++)
	   begin
	      waddr_reg[i][0] <= waddr_i[i];
              bwe_reg[i][0] <= bwe_i[i];
              //wen_reg[i][0] <= wen_i[i];
	      din_reg[i][0] <= din_i[i];
	   end
	end	
   end
   
   assign multipump_sel_reg = ~clk;
   

/* -----\/----- EXCLUDED -----\/-----
   logic reset_value;
   always @(negedge clk2)
   begin
      reset_value <= clk;
   end
   
   always @(posedge clk2)
   begin
      if(!rstn)
      begin
	 multipump_sel_reg <= reset_value;
      end
      else
	multipump_sel_reg <= ~multipump_sel_reg;
   end	
 -----/\----- EXCLUDED -----/\----- */


/* -----\/----- EXCLUDED -----\/-----
   always @(posedge clk2)
   begin
      if(!rstn)
      begin
	 multipump_sel_reg <=0;
      end
      else
	multipump_sel_reg <= ~multipump_sel_reg;
   end	
 -----/\----- EXCLUDED -----/\----- */
   
   //generating LVT brams per bank
   generate
      for (genvar i=0; i<LP_BANK_NUM;i++ )
      begin: gen_lvt_banks
	 for (genvar j=0; j<LP_LVT_BRAM_PER_BANK;j++)
	 begin: gen_RAMs
	    if (RAM_TYPE=="BRAM")
	    begin: gen_BRAM
	       sdp_bwe_bram #(/*AUTO_INSTPARAM*/
			      // Parameters
			      .NB_COL		(NUM_OF_BYTES),
			      .COL_WIDTH	(8),
			      .RAM_DEPTH	(MEM_DEPTH),
			      .RAM_PERFORMANCE	(RAM_PERFORMANCE),
			      .INIT_FILE		(""))
	       LVT_RAMs(/*AUTO_INST*/
			// Outputs
			.doutb		(lvt_ram_dout[i][j]),
			// Inputs
			.addra		(lvt_ram_waddr[i][j]),
			.addrb		(lvt_ram_raddr[i][j]),
			.dina		(lvt_ram_din[i][j]),
			.clka		(clk2),
			.wea		(lvt_ram_bwe[i][j]),
			.enb		(1'b1),
			.clkb		(clk2),
			.rstb		(1'b0),
			.regceb		(1'b1));
	    end
	    else
	    begin: gen_LUTRAM
	       sdp_distram #(/*AUTOINST_PARAM*/
			     // Parameters
			     .WIDTH		(MEM_WIDTH),
			     .DEPTH		(MEM_DEPTH),
			     .OUT_PIPE_STAGES	(2))
	       LVT_RAMs (/*AUTO_INST*/
			 // Outputs
			 .doutb			(lvt_ram_dout[i][j]),
			 // Inputs
			 .addra			(lvt_ram_waddr[i][j]),
			 .addrb			(lvt_ram_raddr[i][j]),
			 .dina			(lvt_ram_din[i][j]),
			 .clka			(clk2),
			 .wea			(lvt_ram_bwe[i][j]!=0),
			 .enb		        (1'b1),
			 .clkb			(clk2),
			 .rstb			(1'b0),			 
			 .regceb		(1'b1));
	    end
	 end

      end


      
      //connecting write addresses to LVT BRAM read addresses
      for (genvar i=0; i<LP_BANK_NUM;i++ )
      begin
	 for (genvar j=0; j<LP_LVT_BRAM_PER_BANK;j++)
	 begin
	    if (MULTIPUMP_WRITE == 1)
	    begin
	       assign lvt_ram_waddr[i][j] = waddr_reg[i][LP_INPUT_REG_NUM-1];
	       assign lvt_ram_bwe[i][j] = bwe_reg[i][LP_INPUT_REG_NUM-1];
	       
	    end
	    else
	    begin
	       assign lvt_ram_waddr[i][j] = multipump_sel_reg == 0 ? waddr_reg[i*MULTIPUMP_WRITE][LP_INPUT_REG_NUM-1] : waddr_reg[i*MULTIPUMP_WRITE+1][LP_INPUT_REG_NUM-1];
	       assign lvt_ram_bwe[i][j] =  multipump_sel_reg == 0 ? bwe_reg[i*MULTIPUMP_WRITE][LP_INPUT_REG_NUM-1] : bwe_reg[i*MULTIPUMP_WRITE+1][LP_INPUT_REG_NUM-1];
	    end
	 end
      end
      
      for (genvar i=0; i<LP_BANK_NUM;i++)
      begin	 
	 for (genvar k=0; k<LP_LVT_BRAM_PER_BANK;k++)
	 begin
	    if (MULTIPUMP_WRITE == 1)
	      assign lvt_ram_raddr[i][k] = waddr_i[lvt_raddr_array[i][k]];
	    else
	    begin
	       assign lvt_ram_raddr[i][k] = multipump_sel_reg == 0 ? waddr_i[lvt_raddr_array[i][k]] : waddr_i[lvt_raddr_array[i][k]+1];//muxing multiple reads
	       //assign lvt_ram_raddr[i][k*MULTIPUMP_WRITE+1] = //muxing multiple reads
	    end
	 end	 
      end


      //xoring input data with data read from LVT brams
      for (genvar i=0; i<W_PORTS_NUM; i+=MULTIPUMP_WRITE )	 
      begin
	 assign lvt_write_xor_in[i/2][i/2]= multipump_sel_reg == 0 ? din_reg[i][LP_INPUT_REG_NUM-1] : din_reg[i+1][LP_INPUT_REG_NUM-1];
	 for (genvar j=0; j<LP_BANK_NUM;j++)
	 begin
	    for (genvar k = 0;k<LP_LVT_BRAM_PER_BANK;k++)
	      if (j!=(i/MULTIPUMP_WRITE) && i==lvt_raddr_array[j][k])//TODO: enable mulitpumpa
		assign lvt_write_xor_in[i/2][j] = lvt_ram_dout[j][k];
	 end
      end


      for (genvar i=0; i<LP_BANK_NUM;i++ )
      begin
	 for (genvar j=0; j<LP_LVT_BRAM_PER_BANK;j++)
	 begin	   
	    assign lvt_ram_din[i][j] = lvt_write_xor_out[i];
	 end
      end
   endgenerate
   
   always_comb
   begin
      for (int i=0; i<LP_BANK_NUM;i++)
      begin	
	 lvt_write_xor_out[i]=lvt_write_xor_in[i][0];
	 for (int j=0; j<LP_LVT_BRAM_PER_BANK;j++)	   
	   lvt_write_xor_out[i] = lvt_write_xor_out[i] ^ lvt_write_xor_in[i][j+1];
      end
   end
   
   //generating READ brams per bank
   generate

      if (MULTIPUMP_READ > 1)
	assign read_clk = clk2;
      else
	assign read_clk = clk;


      for (genvar i=0; i<LP_BANK_NUM;i++ )
      begin: gen_read_banks
	 for (genvar j=0; j<LP_READ_BRAM_PER_BANK;j++)
	 begin: gen_RAMs
	    if (RAM_TYPE=="BRAM")
	    begin: gen_BRAM
	       sdp_bwe_bram #(/*AUTO_INSTPARAM*/
			      // Parameters
			      .NB_COL		(NUM_OF_BYTES),
			      .COL_WIDTH		(8),
			      .RAM_DEPTH		(MEM_DEPTH),
			      .RAM_PERFORMANCE	(RAM_PERFORMANCE),
			      .INIT_FILE		(""))
	       READ_RAMs(/*AUTO_INST*/
			  // Outputs
			  .doutb		(read_ram_dout[i][j]),
			  // Inputs
			  .addra		(read_ram_waddr[i][j]),
			  .addrb		(read_ram_raddr[i][j]),
			  .dina		(read_ram_din[i][j]),
			  .clka		(clk2),
			  .wea		(read_ram_bwe[i][j]),
		  
			  .enb		(read_ram_ren[i][j]),
			  .clkb		(read_clk),
			  .rstb		(1'b0),
			  .regceb		(read_ram_oreg_en[i][j]));
	    end
	    else
	    begin
	       sdp_distram #(/*AUTO_INSTPARAM*/
			      // Parameters
			     // Parameters
			     .WIDTH		(MEM_WIDTH),
			     .DEPTH		(MEM_DEPTH),
			     .OUT_PIPE_STAGES	(2))
	       READ_RAMs(/*AUTO_INST*/
			  // Outputs
			  .doutb	(read_ram_dout[i][j]),
			  // Inputs
			  .addra	(read_ram_waddr[i][j]),
			  .addrb	(read_ram_raddr[i][j]),
			  .dina		(read_ram_din[i][j]),
			  .clka		(clk2),
			  .wea		(read_ram_bwe[i][j]!=0),
		  
			  .enb		(read_ram_ren[i][j]),
			  .clkb		(read_clk),
			  .rstb		(1'b0),
			  .regceb	(read_ram_oreg_en[i][j]));
	    end

	    assign read_ram_waddr[i][j]	= !multipump_sel_reg ? waddr_reg[i*MULTIPUMP_WRITE][LP_INPUT_REG_NUM-1] : waddr_reg[i*MULTIPUMP_WRITE+1][LP_INPUT_REG_NUM-1];
	    assign read_ram_bwe[i][j]	= !multipump_sel_reg ? bwe_reg[i*MULTIPUMP_WRITE][LP_INPUT_REG_NUM-1] : bwe_reg[i*MULTIPUMP_WRITE+1][LP_INPUT_REG_NUM-1];
	    assign read_ram_din[i][j]	= lvt_write_xor_out[i];
	 end	 
      end
      
      for (genvar i=0; i<LP_READ_BRAM_PER_BANK;i++ )
      begin
	 for (genvar j=0; j<LP_BANK_NUM;j++)
	 begin
	    if (MULTIPUMP_READ > 1)
	    begin
	       assign read_ram_raddr[j][i]   = !multipump_sel_reg ? raddr_i[i*MULTIPUMP_READ] : raddr_i[i*MULTIPUMP_READ+1];
	       assign read_ram_ren[j][i]     = !multipump_sel_reg ? ren_i[i*MULTIPUMP_READ]   : ren_i[i*MULTIPUMP_READ+1] ;
	       assign read_ram_oreg_en[j][i] = !multipump_sel_reg ? oreg_en_i[i*MULTIPUMP_READ]   : oreg_en_i[i*MULTIPUMP_READ+1] ;
	    end
	    else
	    begin
	       assign read_ram_raddr[j][i]   = raddr_i[i];
	       assign read_ram_ren[j][i]     = ren_i[i];
	       assign read_ram_oreg_en[j][i] = oreg_en_i[i];
	    end
	    
	 end
      end
      
      
      //xoring outputs of read BRAMs
      for (genvar i=0; i<LP_READ_BRAM_PER_BANK; i++)
      begin	 
	 begin
	    assign lvt_read_xor[i][0] = read_ram_dout[0][i];
	    for (genvar j=1; j<LP_BANK_NUM; j++)
	    begin
	       assign lvt_read_xor[i][j] = read_ram_dout[j][i] ^ lvt_read_xor[i][j-1];
	    end
	    //assign dout_o[i] = lvt_read_xor[i][LP_BANK_NUM-1];
	 end
      end


      logic [R_PORTS_NUM-1:0] [MEM_WIDTH-1:0] 	   dout_clk_reg;
      logic [LP_READ_BRAM_PER_BANK-1:0] [MEM_WIDTH-1:0] dout_clk2_reg;


      // Synchronization register, needed when MULTIPUMP read > 1.     
      if (MULTIPUMP_READ > 1)
      begin
	 always @(posedge clk)
	 begin
	    if (!rstn)
	    begin
	       dout_clk_reg <= '{default:'0};
	    end
	    else
	    begin
	       for (int i=0; i< R_PORTS_NUM; i+=MULTIPUMP_READ)
	       begin
		  dout_clk_reg[i+1] <= lvt_read_xor[i/2][LP_BANK_NUM-1];
	       end

	       for (int i=0; i<R_PORTS_NUM;i+=MULTIPUMP_READ)
	       begin
		  dout_clk_reg[i] <= dout_clk2_reg[i/2];
	       end
	    end	
	 end

	 always @(posedge clk2)
	 begin
	    if (!rstn)
	    begin
	       dout_clk2_reg <= '{default:'0};
	    end
	    else
	    begin
	       for (int i=0; i<LP_READ_BRAM_PER_BANK;i++)
	       begin
		  dout_clk2_reg[i] <= lvt_read_xor[i][LP_BANK_NUM-1];
	       end
	    end	
	 end
      end

      for (genvar i=0; i<R_PORTS_NUM; i++)
      begin
	 if (LP_BANK_NUM == 1)
	   assign dout_o[i] = read_ram_dout[i][0];
	 else 
	 begin
	    if (MULTIPUMP_READ == 1)
	      assign dout_o[i] = lvt_read_xor[i][LP_BANK_NUM-1]; // read xors directly
	    else
	      assign dout_o[i] = dout_clk_reg[i]; // read buffers that transfer from clk2 to clk domain.
	 end
      end
   endgenerate

   
   
   
   
   
   /***************FUNCTIONS*******************/


   /* -----\/----- EXCLUDED -----\/-----

    function void lvt_r_addr_array(automatic ref int raddr_array [LP_BANK_NUM][LP_LVT_BRAM_PER_BANK]);
    
   endfunction
    -----/\----- EXCLUDED -----/\----- */


endmodule
// Local Variables:
// verilog-library-extensions:(".v" ".sv" "_stub.v" "_bb.v")
// verilog-library-directories:("." "../../../../common/")
// End:
