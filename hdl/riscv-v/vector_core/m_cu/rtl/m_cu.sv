// Coded by Djordje Miseljic | e-mail: djordjemiseljic@uns.ac.rs
////////////////////////////////////////////////////////////////////////////////
// default_nettype of none prevents implicit wire declaration.
`default_nettype none
timeunit 1ps;
timeprecision 1ps;

module m_cu #(
  parameter integer VLEN                     = 8192,
  parameter integer V_LANE_NUM               = 8 ,
  parameter integer MAX_VECTORS_BUFFD        = 1 ,
  parameter integer C_M_AXI_ADDR_WIDTH       = 32,
  parameter integer C_M_AXI_DATA_WIDTH       = 32,
  parameter integer C_XFER_SIZE_WIDTH        = 32
)
(
  // System Signals
  input  wire                                   clk                     ,
  input  wire                                   rstn                    ,
  // Scheduler interface
  input  logic [ 2:0]                           mcu_sew_i               ,
  input  logic [ 2:0]                           mcu_lmul_i              ,
  output logic 	                                mcu_st_rdy_o            ,
  input  logic                                  mcu_st_vld_i            ,
  input  logic [31:0]                           mcu_base_addr_i         ,
  input  logic [31:0]                           mcu_stride_i            ,
  input  logic [ 2:0]                           mcu_data_width_i        ,
  input  logic                                  mcu_idx_ld_st_i         ,
  input  logic                                  mcu_strided_ld_st_i     ,
  input  logic                                  mcu_unit_ld_st_i        ,
  // Send config to buff array
  output wire [2:0]                             cfg_lmul_o              ,
  output wire [2:0]                             cfg_data_sew_o          ,
  output wire [2:0]                             cfg_idx_sew_o           ,
  //
  output wire                                   cfg_update_o            ,
  output wire                                   cfg_cntr_rst_o          ,
  output wire                                   sbuff_read_en_o         ,
  output wire [1:0]                             store_type_o            ,
  output wire [31:0]                            store_stride_o          ,
  output wire [31:0]                            store_baseaddr_o        ,
  output wire                                   store_baseaddr_update_o ,
  output wire                                   sbuff_read_stall_o      ,
  output wire                                   sbuff_read_flush_o      ,
  output wire                                   sbuff_wen_o             ,
  output wire                                   sbuff_ren_o             ,
  input  wire                                   sbuff_not_empty_i       ,
  input  wire                                   sbuff_write_done_i      ,
  input  wire                                   sbuff_read_done_i       ,
  // V_LANE interface
  input  wire                                   vlane_store_valid_i     , 
  // AXIM_CTRL interface
  // read channel
  output wire                                   ctrl_rstart_o           ,
  input  wire                                   ctrl_rdone_i            ,
  output wire [C_XFER_SIZE_WIDTH-1:0]           ctrl_rxfer_size_o       ,
  input  wire                                   rd_tvalid_i             ,
  output wire                                   rd_tready_o             ,
  input  wire                                   rd_tlast_i              ,
  // write channel
  output wire                                   ctrl_wstart_o           ,
  input  wire                                   ctrl_wdone_i            ,
  output wire [C_XFER_SIZE_WIDTH-1:0]           ctrl_wxfer_size_o       ,
  output wire                                   wr_tvalid_o             ,
  input  wire                                   wr_tready_i             
);

  ///////////////////////////////////////////////////////////////////////////////
  // Local Parameters
  ///////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////
  // Variables
  ///////////////////////////////////////////////////////////////////////////////
  
  ///////////////////////////////////////////////////////////////////////////////
  // Begin RTL
  ///////////////////////////////////////////////////////////////////////////////
 endmodule : m_cu
`default_nettype wire
