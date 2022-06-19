// This is a generated file. Use and modify at your own risk.
// Modified by Djordje Miseljic | e-mail: djordjemiseljic@uns.ac.rs
////////////////////////////////////////////////////////////////////////////////
// default_nettype of none prevents implicit wire declaration.
`default_nettype none

module axim_ctrl #(

  parameter integer C_M_AXI_ADDR_WIDTH       = 32,
  parameter integer C_M_AXI_DATA_WIDTH       = 32,
  parameter integer C_XFER_SIZE_WIDTH        = 32
)
(
  // System Signals
  input  wire                                   clk                ,
  input  wire                                   rst                ,
  // AXI4 master interface
  output wire                                   m_axi_awvalid      ,
  input  wire                                   m_axi_awready      ,
  output wire [C_M_AXI_ADDR_WIDTH-1:0]          m_axi_awaddr       ,
  output wire [8-1:0]                           m_axi_awlen        ,
  output wire                                   m_axi_wvalid       ,
  input  wire                                   m_axi_wready       ,
  output wire [C_M_AXI_DATA_WIDTH-1:0]          m_axi_wdata        ,
  output wire [C_M_AXI_DATA_WIDTH/8-1:0]        m_axi_wstrb        ,
  output wire                                   m_axi_wlast        ,
  output wire                                   m_axi_arvalid      ,
  input  wire                                   m_axi_arready      ,
  output wire [C_M_AXI_ADDR_WIDTH-1:0]          m_axi_araddr       ,
  output wire [8-1:0]                           m_axi_arlen        ,
  input  wire                                   m_axi_rvalid       ,
  output wire                                   m_axi_rready       ,
  input  wire [C_M_AXI_DATA_WIDTH-1:0]          m_axi_rdata        ,
  input  wire                                   m_axi_rlast        ,
  input  wire                                   m_axi_bvalid       ,
  output wire                                   m_axi_bready       ,
  input  wire [C_M_AXI_ADDR_WIDTH-1:0]          ctrl_baseaddr      ,
  input  wire                                   ctrl_rstart        ,
  output wire                                   ctrl_rdone         ,
  input  wire [C_M_AXI_ADDR_WIDTH-1:0]          ctrl_raddr_offset  ,
  input  wire [C_XFER_SIZE_WIDTH-1:0]           ctrl_rxfer_size    ,
  output wire                                   rd_tvalid          ,
  input  wire                                   rd_tready          ,
  output wire                                   rd_tlast           ,
  output wire [C_M_AXI_DATA_WIDTH-1:0]          rd_tdata           ,
  input  wire                                   ctrl_wstart        ,
  output wire                                   ctrl_wdone         ,
  input  wire [C_M_AXI_ADDR_WIDTH-1:0]          ctrl_waddr_offset  ,
  input  wire [C_XFER_SIZE_WIDTH-1:0]           ctrl_wxfer_size    ,
  input  wire                                   ctrl_wstrb_msk_en  ,
  input  wire                                   wr_tvalid          ,
  output wire                                   wr_tready          ,
  input  wire [C_M_AXI_DATA_WIDTH/8-1:0]        wr_tstrb_msk       ,
  input  wire [C_M_AXI_DATA_WIDTH-1:0]          wr_tdata
);


///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
localparam integer LP_DW_BYTES             = C_M_AXI_DATA_WIDTH/8;
localparam integer LP_AXI_BURST_LEN        = 4096/LP_DW_BYTES < 256 ? 4096/LP_DW_BYTES : 256;
localparam integer LP_LOG_BURST_LEN        = $clog2(LP_AXI_BURST_LEN);
localparam integer LP_BRAM_DEPTH           = 512;
localparam integer LP_RD_MAX_OUTSTANDING   = LP_BRAM_DEPTH / LP_AXI_BURST_LEN;
localparam integer LP_WR_MAX_OUTSTANDING   = 32;

wire [C_M_AXI_DATA_WIDTH/8-1:0]       m_axi_wstrb_s;
wire [C_M_AXI_ADDR_WIDTH-1:0]         ctrl_waddr;
wire [C_M_AXI_ADDR_WIDTH-1:0]         ctrl_raddr;
assign m_axi_wstrb = (ctrl_wstrb_msk_en) ? (m_axi_wstrb_s & wr_tstrb_msk) : (m_axi_wstrb_s);


assign ctrl_waddr = (ctrl_baseaddr + ctrl_waddr_offset);
assign ctrl_raddr = (ctrl_baseaddr + ctrl_raddr_offset);

///////////////////////////////////////////////////////////////////////////////
// Begin RTL
///////////////////////////////////////////////////////////////////////////////

// AXI4 Read Master, output format is an AXI4-Stream master, one stream per thread.
axim_ctrl_axi_read_master #(
  .C_M_AXI_ADDR_WIDTH  ( C_M_AXI_ADDR_WIDTH    ) ,
  .C_M_AXI_DATA_WIDTH  ( C_M_AXI_DATA_WIDTH    ) ,
  .C_XFER_SIZE_WIDTH   ( C_XFER_SIZE_WIDTH     ) ,
  .C_MAX_OUTSTANDING   ( LP_RD_MAX_OUTSTANDING ) ,
  .C_INCLUDE_DATA_FIFO ( 0                     )
)
inst_axi_read_master (
  .aclk                    ( clk                     ) ,
  .areset                  ( rst                     ) ,
  .ctrl_start              ( ctrl_rstart         		 ) ,
  .ctrl_done               ( ctrl_rdone              ) ,
  .ctrl_addr_offset        ( ctrl_raddr              ) ,
  .ctrl_xfer_size_in_bytes ( ctrl_rxfer_size 		     ) ,
  .m_axi_arvalid           ( m_axi_arvalid           ) ,
  .m_axi_arready           ( m_axi_arready           ) ,
  .m_axi_araddr            ( m_axi_araddr            ) ,
  .m_axi_arlen             ( m_axi_arlen             ) ,
  .m_axi_rvalid            ( m_axi_rvalid            ) ,
  .m_axi_rready            ( m_axi_rready            ) ,
  .m_axi_rdata             ( m_axi_rdata             ) ,
  .m_axi_rlast             ( m_axi_rlast             ) ,
  .m_axis_aclk             ( clk                     ) ,
  .m_axis_areset           ( rst                     ) ,
  .m_axis_tvalid           ( rd_tvalid               ) ,
  .m_axis_tready           ( rd_tready               ) ,
  .m_axis_tlast            ( rd_tlast                ) ,
  .m_axis_tdata            ( rd_tdata                )
);

// AXI4 Write Master
axim_ctrl_axi_write_master #(
  .C_M_AXI_ADDR_WIDTH  ( C_M_AXI_ADDR_WIDTH    ) ,
  .C_M_AXI_DATA_WIDTH  ( C_M_AXI_DATA_WIDTH    ) ,
  .C_XFER_SIZE_WIDTH   ( C_XFER_SIZE_WIDTH     ) ,
  .C_MAX_OUTSTANDING   ( LP_WR_MAX_OUTSTANDING ) ,
  .C_INCLUDE_DATA_FIFO ( 0                     )
)
inst_axi_write_master (
  .aclk                    ( clk                     ) ,
  .areset                  ( rst                     ) ,
  .ctrl_start              ( ctrl_wstart             ) ,
  .ctrl_done               ( ctrl_wdone              ) ,
  .ctrl_addr_offset        ( ctrl_waddr              ) ,
  .ctrl_xfer_size_in_bytes ( ctrl_wxfer_size         ) ,
  .m_axi_awvalid           ( m_axi_awvalid           ) ,
  .m_axi_awready           ( m_axi_awready           ) ,
  .m_axi_awaddr            ( m_axi_awaddr            ) ,
  .m_axi_awlen             ( m_axi_awlen             ) ,
  .m_axi_wvalid            ( m_axi_wvalid            ) ,
  .m_axi_wready            ( m_axi_wready            ) ,
  .m_axi_wdata             ( m_axi_wdata             ) ,
  .m_axi_wstrb             ( m_axi_wstrb_s           ) ,
  .m_axi_wlast             ( m_axi_wlast             ) ,
  .m_axi_bvalid            ( m_axi_bvalid            ) ,
  .m_axi_bready            ( m_axi_bready            ) ,
  .s_axis_aclk             ( clk                     ) ,
  .s_axis_areset           ( rst                     ) ,
  .s_axis_tvalid           ( wr_tvalid               ) ,
  .s_axis_tready           ( wr_tready               ) ,
  .s_axis_tdata            ( wr_tdata                )
);


 endmodule : axim_ctrl
`default_nettype wire

