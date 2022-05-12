module riscv_v_w_mem_subsystem #
  (  parameter integer C_M_AXI_ADDR_WIDTH = 32,
     parameter integer C_M_AXI_DATA_WIDTH = 32,
     parameter integer C_XFER_SIZE_WIDTH = 32,
     parameter integer VLEN = 4096,
     parameter integer V_LANES = 16,
     parameter integer CHAINING = 4)
   (input clk,
    
    input 				    rstn,
    // AXI FULL VECTOR CORE IF
    output logic 			    v_m_axi_awvalid ,
    input logic 			    v_m_axi_awready ,
    output logic [C_M_AXI_ADDR_WIDTH-1:0]   v_m_axi_awaddr ,
    output logic [8-1:0] 		    v_m_axi_awlen ,
    output logic 			    v_m_axi_wvalid ,
    input logic 			    v_m_axi_wready ,
    output logic [C_M_AXI_DATA_WIDTH-1:0]   v_m_axi_wdata ,
    output logic [C_M_AXI_DATA_WIDTH/8-1:0] v_m_axi_wstrb ,
    output logic 			    v_m_axi_wlast ,
    output logic 			    v_m_axi_arvalid ,
    input logic 			    v_m_axi_arready ,
    output logic [C_M_AXI_ADDR_WIDTH-1:0]   v_m_axi_araddr ,
    output logic [8-1:0] 		    v_m_axi_arlen ,
    input logic 			    v_m_axi_rvalid ,
    output logic 			    v_m_axi_rready ,
    input logic [C_M_AXI_DATA_WIDTH-1:0]    v_m_axi_rdata ,
    input logic 			    v_m_axi_rlast ,
    input logic 			    v_m_axi_bvalid ,
    output logic 			    v_m_axi_bready
    // AXI LITE IF
   
    );

   logic [31:0] 			    instr_mem_address;
   logic 				    instr_mem_flush; 
   logic 				    instr_mem_en;
   logic [31:0] 			    data_mem_address;
   logic [3:0] 				    data_mem_we;
   // Inputs		
   logic 				    instr_ready;
   logic 				    data_ready;
   logic [31:0] 			    instr_mem_read;
   logic [31:0] 			    data_mem_read;
   logic [31:0] 			    data_mem_write;
   logic 				    data_mem_re;


   logic 				    ctrl_rdone;
   logic 				    rd_tvalid;
   logic 				    rd_tlast;
   logic [C_M_AXI_DATA_WIDTH-1:0] 	    rd_tdata;
   logic 				    ctrl_wdone;
   logic 				    wr_tready;
   // Vector core outputs		    
   logic 				    ctrl_rstart;
   logic [C_M_AXI_ADDR_WIDTH-1:0] 	    ctrl_raddr_offset;
   logic [C_XFER_SIZE_WIDTH-1:0] 	    ctrl_rxfer_size;
   logic 				    rd_tready;
   logic 				    ctrl_wstart;
   logic [C_M_AXI_ADDR_WIDTH-1:0] 	    ctrl_waddr_offset;
   logic [C_XFER_SIZE_WIDTH-1:0] 	    ctrl_wxfer_size;
   logic 				    wr_tvalid;
   logic [C_M_AXI_DATA_WIDTH-1:0] 	    wr_tdata;

   
   axim_ctrl #(/*AUTOINST_PARAM*/
	       // Parameters
	       .C_M_AXI_ADDR_WIDTH	(C_M_AXI_ADDR_WIDTH),
	       .C_M_AXI_DATA_WIDTH	(C_M_AXI_DATA_WIDTH),
	       .C_XFER_SIZE_WIDTH	(C_XFER_SIZE_WIDTH))
   v_axim_ctrl_inst(/*AUTO_INST*/
		    .clk		(clk),
		    .rst		(!rstn),
		    // Outputs
		    .m_axi_awvalid	(v_m_axi_awvalid),
		    .m_axi_awaddr	(v_m_axi_awaddr[C_M_AXI_ADDR_WIDTH-1:0]),
		    .m_axi_awlen	(v_m_axi_awlen[8-1:0]),
		    .m_axi_wvalid	(v_m_axi_wvalid),
		    .m_axi_wdata	(v_m_axi_wdata[C_M_AXI_DATA_WIDTH-1:0]),
		    .m_axi_wstrb	(v_m_axi_wstrb[C_M_AXI_DATA_WIDTH/8-1:0]),
		    .m_axi_wlast	(v_m_axi_wlast),
		    .m_axi_arvalid	(v_m_axi_arvalid),
		    .m_axi_araddr	(v_m_axi_araddr[C_M_AXI_ADDR_WIDTH-1:0]),
		    .m_axi_arlen	(v_m_axi_arlen[8-1:0]),
		    .m_axi_rready	(v_m_axi_rready),
		    .m_axi_bready	(v_m_axi_bready),
		    //AXIM inputs
		    .m_axi_awready	(v_m_axi_awready),
		    .m_axi_wready	(v_m_axi_wready),
		    .m_axi_arready	(v_m_axi_arready),
		    .m_axi_rvalid	(v_m_axi_rvalid),
		    .m_axi_rdata	(v_m_axi_rdata[C_M_AXI_DATA_WIDTH-1:0]),
		    .m_axi_rlast	(v_m_axi_rlast),
		    .m_axi_bvalid	(v_m_axi_bvalid),
		    //Vector core if
		    .ctrl_rdone		(ctrl_rdone),
		    .rd_tvalid		(rd_tvalid),
		    .rd_tlast		(rd_tlast),
		    .rd_tdata		(rd_tdata[C_M_AXI_DATA_WIDTH-1:0]),
		    .ctrl_wdone		(ctrl_wdone),
		    .wr_tready		(wr_tready),
		    // Vector core outputs		    
		    .ctrl_rstart	(ctrl_rstart),
		    .ctrl_raddr_offset	(ctrl_raddr_offset[C_M_AXI_ADDR_WIDTH-1:0]),
		    .ctrl_rxfer_size	(ctrl_rxfer_size[C_XFER_SIZE_WIDTH-1:0]),
		    .rd_tready		(rd_tready),
		    .ctrl_wstart	(ctrl_wstart),
		    .ctrl_waddr_offset	(ctrl_waddr_offset[C_M_AXI_ADDR_WIDTH-1:0]),
		    .ctrl_wxfer_size	(ctrl_wxfer_size[C_XFER_SIZE_WIDTH-1:0]),
		    .wr_tvalid		(wr_tvalid),
		    .wr_tdata		(wr_tdata[C_M_AXI_DATA_WIDTH-1:0]));

   riscv_v #(/*AUTOINST_PARAM*/
	     // Parameters
	     .VLEN			(VLEN),
	     .V_LANES			(V_LANES),
	     .CHAINING			(CHAINING))
   riscv_v_inst(/*AUTO_INST*/
		// Outputs
		.instr_mem_address_o	(instr_mem_address[31:0]),
		//.instr_mem_flush_o	(instr_mem_flush),
		.instr_mem_en_o		(instr_mem_en),
		.data_mem_address_o	(data_mem_address[31:0]),
		.data_mem_we_o		(data_mem_we[3:0]),
		// Inputs
		.clk			(clk),
		.ce			(1'b1),
		.fencei_o		(),
		.rstn			(rstn),
		.instr_ready_i		(instr_ready),
		.data_ready_i		(data_ready),
		.instr_mem_read_i	(instr_mem_read[31:0]),
		.data_mem_read_i	(data_mem_read[31:0]),
		.data_mem_write_o	(data_mem_write[31:0]),
		.data_mem_re_o		(data_mem_re));
endmodule

// Local Variables:
// verilog-library-extensions:(".v" ".sv" "_stub.v" "_bb.v")
// verilog-library-directories:("." "../../../../common/" "../vector_core/rtl" "../axim_ctrl/rtl/")
// End:
