`timescale 1ns/1ps
module vrf_tb ();

   localparam R_PORTS_NUM = 8;
   localparam W_PORTS_NUM = 4;
   localparam MULTIPUMP_WRITE = 2;
   localparam MULTIPUMP_READ = 2;
   localparam MEM_DEPTH = 512;
   localparam MEM_WIDTH = 32;
   localparam NUM_OF_BYTES = MEM_WIDTH < 8 ? 1 : MEM_WIDTH/8;
   logic 					   clk=1;
   logic 					   clk2=1;
   logic 					   rstn;

   
   // read IF
   logic [R_PORTS_NUM-1:0][$clog2(MEM_DEPTH)-1:0]  raddr_i='{default:'0};;
   logic [R_PORTS_NUM-1:0] 			   ren_i='{default:'0};
   logic [R_PORTS_NUM-1:0] 			   oreg_en_i='{default:'0}; 
   logic [R_PORTS_NUM-1:0] [MEM_WIDTH-1:0] 	   dout_o;
   
   // write IF
   logic [W_PORTS_NUM-1:0][$clog2(MEM_DEPTH)-1:0]  waddr_i='{default:'0};;
   logic [W_PORTS_NUM-1:0][NUM_OF_BYTES-1:0] 	   bwe_i='{default:'0};
   logic [W_PORTS_NUM-1:0] 			   wen_i='{default:'0};
   logic [W_PORTS_NUM-1:0] [MEM_WIDTH-1:0] 	   din_i='{default:'0};;

   
   vrf dut_vrf(/*AUTOINST*/
	       // Outputs
	       .dout_o			(dout_o/*[R_PORTS_NUM-1:0][MEM_WIDTH-1:0]*/),
	       // Inputs
	       .clk			(clk),
	       .clk2			(clk2),
	       .rstn			(rstn),
	       .raddr_i			(raddr_i/*[R_PORTS_NUM-1:0][$clog2(MEM_DEPTH)-1:0]*/),
	       .ren_i			(ren_i[R_PORTS_NUM-1:0]),
	       .oreg_en_i		(oreg_en_i[R_PORTS_NUM-1:0]),
	       .waddr_i			(waddr_i/*[W_PORTS_NUM-1:0][$clog2(MEM_DEPTH)-1:0]*/),
	       .bwe_i			(bwe_i/*[W_PORTS_NUM-1:0][MEM_WIDTH/8-1:0]*/),
	       //.wen_i			(wen_i[W_PORTS_NUM-1:0]),
	       .din_i			(din_i/*[W_PORTS_NUM-1:0][MEM_WIDTH-1:0]*/));


   always #100 clk = ~clk;
   always #50 clk2 = ~clk2;




   initial
   begin
      rstn <= 0;
      #190;
      rstn <= 1;
      
      
      @(negedge clk);
      @(negedge clk);
      @(negedge clk);
      @(negedge clk);

      for (logic[$clog2(MEM_DEPTH)-1:0] i=0; i<R_PORTS_NUM;i++)
      begin
	 @(negedge clk);
	 raddr_i[0]   <= i%4;
	 ren_i[0]     <= 1'b1;
	 oreg_en_i[0] <= 1'b1;
      end
      
      /* -----\/----- EXCLUDED -----\/-----
      ren_i     = '{default:'0};
      for (logic[$clog2(MEM_DEPTH)-1:0] i=0; i<W_PORTS_NUM;i++)
      begin
	 waddr_i[W_PORTS_NUM-i-1] = i;
	 bwe_i[i]   = '{default:'1};
	 din_i[W_PORTS_NUM-i-1]   = (i+5)*10;
      end
      @(negedge clk);
      @(negedge clk);
      bwe_i   = '{default:'0};
      for (logic[$clog2(MEM_DEPTH)-1:0] i=0; i<R_PORTS_NUM;i++)
      begin
	 raddr_i[i]   = i%4;
	 ren_i[i]     = 1'b1;
	 oreg_en_i[i] = 1'b1;
      end                      
 -----/\----- EXCLUDED -----/\----- */
      
      @(negedge clk);
      @(negedge clk);
      $finish;

   end


   initial 
   begin
      #10;
      @(rstn);
      #1;
      for (logic[$clog2(MEM_DEPTH)-1:0] i=0; i<W_PORTS_NUM;i++)
      begin
	 @(negedge clk);	 
	 waddr_i[0] <= i;
	 bwe_i[0]   <= '{default:'1};
	 din_i[0]   <= i[7:0];
      end
      @(negedge clk);
      bwe_i[0]   <= '{default:'0};
   end
      
endmodule
// Local Variables:
// verilog-library-extensions:(".v" ".sv" "_stub.v" "_bb.v")
// verilog-library-directories:("." "../rtl/")
// End:
