// Coded by Djordje Miseljic | e-mail: djordjemiseljic@uns.ac.rs
////////////////////////////////////////////////////////////////////////////////
// default_nettype of none prevents implicit wire declaration.
`default_nettype none
timeunit 1ps;
timeprecision 1ps;

module buff_array #(
  parameter integer VLEN                     = 8192,
  parameter integer V_LANE_NUM               = 8 ,
  parameter integer MAX_VECTORS_BUFFD        = 1 ,
  parameter integer C_M_AXI_ADDR_WIDTH       = 32,
  parameter integer C_M_AXI_DATA_WIDTH       = 32,
  parameter integer C_XFER_SIZE_WIDTH        = 32,
)
(
  // System Signals
  input  wire                                   clk                ,
  input  wire                                   rst                ,
  // Current vector config
  input  wire [2:0]                            cfg_l_mul          ,
  input  wire [2:0]                            cfg_l_sew          ,
  // M_CU interface
  // TODO: specify
  // V_LANE interface
  input  wire [31:0]                            vlane_store_data [0:V_LANE_NUM-1],
  output wire [31:0]                            vlane_load_data  [0:V_LANE_NUM-1],
  // AXIM_CTRL interface
  output wire                                   rd_tvalid          ,
  input  wire                                   rd_tready          ,
  output wire                                   rd_tlast           ,
  output wire [C_M_AXI_DATA_WIDTH-1:0]          rd_tdata           ,
  input  wire                                   wr_tvalid          ,
  output wire                                   wr_tready          ,
  input  wire [C_M_AXI_DATA_WIDTH-1:0]          wr_tdata
);
  ///////////////////////////////////////////////////////////////////////////////
  // Local Parameters
  ///////////////////////////////////////////////////////////////////////////////

  // VLMAX: Maximum number of elements in a vector register group.
  //    VLMAX=VLEN*LMUL_MAX/SEW_MIN=VLEN*8/8=VLEN
  localparam integer VLMAX = VLEN; 

  // VLMAX32: Maximum number of 32-bit vector elements
  //    VLMAX32=VLEN*LMUL_MAX/32=VLEN*8/32=VLEN/4
  localparam integer VLMAX32 = VLEN/4; 

  // VLMAX32_PVL: Maximum number of 32-bit vector elements per vector lane
  //   VLMAX32_PVL=VLMAX/V_LANE_NUM
  localparam integer VLMAX32_PVL = VLMAX32/V_LANE_NUM;

  // BUFF_DEPTH: Maximum number of 32-bit vector elements stored in buffer
  //   BUFF_DEPTH=VLMAX32_PVL*MAX_VECTORS_BUFFD
  localparam integer BUFF_DEPTH = VLMAX32_PVL*MAX_VECTORS_BUFFD;




  genvar vlane;
  generate 
    for (vlane=0; vlane<V_LANE_NUM; vlane++) begin: vlane_iterator

      // VFR -> DDR Buffer (STORE)
      // Xilinx Simple Dual Port Single Clock RAM with Byte-write
      sdp_bwe_bram #(
        .NB_COL(4),                           // Specify number of columns (number of bytes)
        .COL_WIDTH(8),                        // Specify column width (byte width, typically 8 or 9)
        .RAM_DEPTH(BUFF_DEPTH),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
      ) store_buffer (
        .clk(clk),     // Clock
        .addra(addra),   // Write address bus, width determined from RAM_DEPTH
        .addrb(addrb),   // Read address bus, width determined from RAM_DEPTH
        .dina(dina),     // RAM input data, width determined from NB_COL*COL_WIDTH
        .wea(wea),       // Byte-write enable, width determined from NB_COL
        .enb(enb),       // Read Enable, for additional power savings, disable when not in use
        .rstb(rst),     // Output reset (does not affect memory contents)
        .regceb(regceb), // Output register enable
        .doutb(doutb)    // RAM output data, width determined from NB_COL*COL_WIDTH
      );

      // DDR -> VFR Buffer (LOAD)
      //  Xilinx Simple Dual Port Single Clock RAM with Byte-write
      sdp_bwe_bram #(
        .NB_COL(4),                           // Specify number of columns (number of bytes)
        .COL_WIDTH(8),                        // Specify column width (byte width, typically 8 or 9)
        .RAM_DEPTH(BUFF_DEPTH),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
      ) load_buffer (
        .clk(clk),     // Clock
        .addra(addra),   // Write address bus, width determined from RAM_DEPTH
        .addrb(addrb),   // Read address bus, width determined from RAM_DEPTH
        .dina(dina),     // RAM input data, width determined from NB_COL*COL_WIDTH
        .wea(wea),       // Byte-write enable, width determined from NB_COL
        .enb(enb),       // Read Enable, for additional power savings, disable when not in use
        .rstb(rst),     // Output reset (does not affect memory contents)
        .regceb(regceb), // Output register enable
        .doutb(doutb)    // RAM output data, width determined from NB_COL*COL_WIDTH
      );
    end
  endgenerate


 endmodule : buff_array
`default_nettype wire
