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
  parameter integer C_XFER_SIZE_WIDTH        = 32
)
(
  // System Signals
  input  wire                                   clk                ,
  input  wire                                   rstn               ,
  // Current vector config
  input  wire [2:0]                             cfg_lmul           ,
  input  wire [2:0]                             cfg_sew            ,
  // M_CU interface
  // TODO DEFINE
  input  wire                                   sew_changed        ,
  input  wire                                   sbuff_rsel_cntr_en,
  // V_LANE interface
  input  wire                                   vlane_store_valid  ,
  input  wire [31:0]                            vlane_store_data [0:V_LANE_NUM-1],
  input  wire [31:0]                            vlane_store_ptr  [0:V_LANE_NUM-1],
  output wire [31:0]                            vlane_load_data  [0:V_LANE_NUM-1],
  input  wire  [31:0]                           vlane_load_ptr   [0:V_LANE_NUM-1],
  // AXIM_CTRL interface
  output wire                                   axi_rd_tvalid          ,
  input  wire                                   axi_rd_tready          ,
  output wire                                   axi_rd_tlast           ,
  output wire [C_M_AXI_DATA_WIDTH-1:0]          axi_rd_tdata           ,
  input  wire                                   axi_wr_tvalid          ,
  output wire                                   axi_wr_tready          ,
  input  wire [C_M_AXI_DATA_WIDTH-1:0]          axi_wr_tdata
);
  ///////////////////////////////////////////////////////////////////////////////
  // Local Parameters
  ///////////////////////////////////////////////////////////////////////////////
  //
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

  ///////////////////////////////////////////////////////////////////////////////
  // Variables
  ///////////////////////////////////////////////////////////////////////////////

  logic [$clog2(V_LANE_NUM)-1:0]            sbuff_rsel_cntr;

  logic [31:0]                              sbuff_wdata [0:V_LANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            sbuff_waddr;
  logic [3:0]                               sbuff_wen;
  logic [31:0]                              sbuff_wptr  [0:V_LANE_NUM-1];
  logic [31:0]                              sbuff_rdata [0:V_LANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            sbuff_raddr;
  logic [31:0]                              sbuff_rptr  [0:V_LANE_NUM-1];
  logic                                     sbuff_roen;
  logic                                     sbuff_rocl;

  logic                                     sbuff_whs;//write handshake

  logic [31:0]                              lbuff_wdata [0:V_LANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            lbuff_waddr;
  logic [3:0]                               lbuff_wen;
  logic [31:0]                              lbuff_wptr  [0:V_LANE_NUM-1];
  logic [31:0]                              lbuff_rdata [0:V_LANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            lbuff_raddr;
  logic [31:0]                              lbuff_rptr  [0:V_LANE_NUM-1];
  logic                                     lbuff_roen;
  logic                                     lbuff_rocl;

  ///////////////////////////////////////////////////////////////////////////////
  // Begin RTL
  ///////////////////////////////////////////////////////////////////////////////
  
  assign sbuff_whs = vlane_store_valid;

  // Counter selects data from one store buffer to forward to axi
  always_ff @(posedge clk) begin
    if (!rstn) begin
      sbuff_rsel_cntr <= 0;
    end
    else if(sbuff_rsel_cntr_en) begin
      sbuff_rsel_cntr <= sbuff_rsel_cntr + 1;
    end
  end

  // Multiplex selecting one of buffers to output to axi
  always_comb begin
    axi_wr_tdata = sbuff_rdata[sbuff_rsel_cntr];
  end


  // Changing write enable signals so data coming
  always_ff @(posedge clk) begin
    if (!rstn) begin
      sbuff_wen <= 4'b1111;
    end
    case(cfg_sew[1:0])
      2: begin      // FOR SEW = 32
        sbuff_wen <= 4'b1111;
      end
      1: begin      // FOR SEW = 16
      if(sew_changed)
        sbuff_wen <= 4'b0011;
      else if (sbuff_whs)
        sbuff_wen <= {sbuff_wen[1:0],sbuff_wen[3:2]};
      end
      default: begin // FOR SEW = 8
      if(sew_changed)
        sbuff_wen <= 4'b0001;
      else if (sbuff_whs)
        sbuff_wen <= {sbuff_wen[2:0],sbuff_wen[3]};
      end
    endcase
  end


  genvar vlane;
  generate 
    for (vlane=0; vlane<V_LANE_NUM; vlane++) begin: vlane_iterator

      // Multiplex narrower data in so writes are in the correct position for byte-write enable
      always_comb begin
        case(cfg_sew[1:0])
          2: begin       // FOR SEW = 32
            sbuff_wdata[vlane] = vlane_store_data[vlane];
            sbuff_wptr[vlane]  = vlane_store_ptr[vlane];
          end
          1: begin       // FOR SEW = 16
            sbuff_wdata[vlane] = {2{vlane_store_data[vlane][15:0]}};
            sbuff_wptr [vlane] = {2{vlane_store_ptr [vlane][15:0]}};
          end
          default: begin // FOR SEW = 8
            sbuff_wdata[vlane] = {4{vlane_store_data[vlane][7:0]}};
            sbuff_wptr [vlane] = {4{vlane_store_ptr [vlane][7:0]}};
          end
        endcase
      end

      // VFR -> DDR Buffer (STORE)
      // Xilinx Simple Dual Port Single Clock RAM with Byte-write
      sdp_bwe_bram #(
        .NB_COL(8),                           // Specify number of columns (number of bytes)
        .COL_WIDTH(8),                        // Specify column width (byte width, typically 8 or 9)
        .RAM_DEPTH(BUFF_DEPTH),               // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
      ) store_buffer (
        .clk      (clk),
        .addra    (sbuff_waddr),
        .addrb    (sbuff_raddr),
        .dina     ({sbuff_wdata[vlane], sbuff_wptr[vlane]}),
        .wea      ({sbuff_wen, sbuff_wen}),
        .enb      (sbuff_ren),
        .rstb     (sbuff_ocl),
        .regceb   (sbuff_oen),
        .doutb    ({sbuff_rdata[vlane], sbuff_rptr[vlane]})
      );

      assign sbuff_wdata[vlane] = vlane_store_data[vlane];

      // DDR -> VFR Buffer (LOAD)
      //  Xilinx Simple Dual Port Single Clock RAM with Byte-write
      /*
      sdp_bwe_bram #(
        .NB_COL(8),                           // Specify number of columns (number of bytes)
        .COL_WIDTH(8),                        // Specify column width (byte width, typically 8 or 9)
        .RAM_DEPTH(BUFF_DEPTH),               // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
      ) load_buffer (
        .clk      (clk),
        .addra    (lbuff_waddr),
        .addrb    (lbuff_raddr),
        .dina     (lbuff_wdata[vlane]),
        .wea      (lbuff_wen),
        .enb      (lbuff_ren),
        .rstb     (lbuff_ocl),
        .regceb   (lbuff_oen),
        .doutb    (lbuff_rdata[vlane])
      );
      */


    end
  endgenerate


 endmodule : buff_array
`default_nettype wire
