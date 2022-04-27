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
  input  wire                                   cfg_update        ,
  input  wire                                   cfg_rst           ,
  input  wire                                   sbuff_read_en     ,
  input  wire                                   sbuff_read_stall  ,
  input  wire                                   sbuff_read_flush  ,
  input  wire                                   sbuff_whs         ,
  input  wire                                   sbuff_rhs         ,
  input  wire                                   sbuff_strobe_ren  ,
  output wire                                   sbuff_not_empty   ,
  output wire                                   sbuff_store_done  ,
  // V_LANE interface
  input  wire                                   vlane_store_valid  ,
  input  wire [31:0]                            vlane_store_data [0:V_LANE_NUM-1],
  input  wire [31:0]                            vlane_store_ptr  [0:V_LANE_NUM-1],
  output wire [31:0]                            vlane_load_data  [0:V_LANE_NUM-1],
  input  wire [31:0]                            vlane_load_ptr   [0:V_LANE_NUM-1],
  // AXIM_CTRL interface
  input  wire                                   axi_rd_tvalid          ,
  output wire                                   axi_rd_tready          ,
  output wire                                   axi_rd_tlast           ,
  input  wire [C_M_AXI_DATA_WIDTH-1:0]          axi_rd_tdata           ,
  output wire                                   axi_wr_tvalid          ,
  input  wire                                   axi_wr_tready          ,
  output wire [C_M_AXI_DATA_WIDTH-1:0]          axi_wr_tdata
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
  localparam integer VLMAX32_PVL = VLMAX32/V_LANE_NUM;
  // BUFF_DEPTH: Maximum number of 32-bit vector elements stored in buffer
  localparam integer BUFF_DEPTH = VLMAX32_PVL*MAX_VECTORS_BUFFD;
  // WORD_CNTR_WIDTH: Width of word counter in transaction 
  localparam integer WORD_CNTR_WIDTH = $clog2(VLMAX32_PVL);
  localparam integer BATCH_CNTR_WIDTH = $clog2(VLMAX32_PVL);
  ///////////////////////////////////////////////////////////////////////////////
  // Variables
  ///////////////////////////////////////////////////////////////////////////////

  logic [3:0]                               sbuff_strobe_reg,sbuff_strobe_next;
  logic [1:0]                               sbuff_strobe_rol_amt;
  logic [1:0]                               sbuff_rdata_rol_amt;
  logic                                     sbuff_write_cntr_en; // TODO: CONNECT
  logic                                     sbuff_read_cntr_en; 

  logic [WORD_CNTR_WIDTH-1:0]               sbuff_read_cntr;
  logic [BATCH_CNTR_WIDTH-1:0]              sbuff_write_cntr; 
  logic [BATCH_CNTR_WIDTH-1:0]              sbuff_write_cntr_high; 

  logic [31:0]                              sbuff_wdata [0:V_LANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            sbuff_waddr;
  logic [V_LANE_NUM-1:0]                    sbuff_wen;
  logic [31:0]                              sbuff_wptr  [0:V_LANE_NUM-1];
  logic [31:0]                              sbuff_rdata [0:V_LANE_NUM-1];
  logic [31:0]                              sbuff_rdata_rol;
  logic [31:0]                              sbuff_rdata_mux;
  logic [$clog2(BUFF_DEPTH)-1:0]            sbuff_raddr;
  logic [31:0]                              sbuff_rptr  [0:V_LANE_NUM-1];
  logic                                     sbuff_roen;
  logic                                     sbuff_rocl;


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
  
  // Counter selects data from one store buffer to forward to axi
  always_ff @(posedge clk) begin
    if (!rstn) begin
      sbuff_read_cntr <= 0;
    end
    else if(sbuff_read_cntr_en) begin
      sbuff_read_cntr <= sbuff_read_cntr + 1;
    end
  end

  // Write counter addresses write ports of all store buffers
  // Each store buffer is then selected with sbuff_wen
  // Write counter is incremented:
  // For SEW=32, every single write
  // For SEW=16, every second write
  // For SEW=8,  every fourth write
  always_ff @(posedge clk) begin
    if (!rstn) begin
      sbuff_write_cntr <= 0;
    end
    else if(sbuff_write_cntr_en) begin
      sbuff_write_cntr <= sbuff_write_cntr + 1;
    end
  end

  // To simplify counter combinatorial logic, we increment
  //  only after we write to the last store buffer
  assign sbuff_write_cntr_en = sbuff_wen[V_LANE_NUM-1] && sbuff_whs;

  assign sbuff_not_empty = sbuff_write_cntr != 0;

  always_ff @(posedge clk) begin
    if (!rstn || cfg_rst)
      sbuff_write_cntr <= 0;
    else
      sbuff_store_done <= (sbuff_write_cntr == sbuff_write_cntr_high) && sbuff_whs;
  end

  assign sbuff_waddr = sbuff_write_cntr;

  // Multiplex selecting data from one of V_LANE_NUM buffers to output 
  assign sbuff_rdata_mux = sbuff_rdata[sbuff_read_cntr[0+:$clog2(V_LANE_NUM)]];

  // Output barrel shifter after selecting data
  // Narrower data needs to be barrel shifted to fit the position
  always_comb begin
    case (sbuff_rdata_rol_amt)
      3:
        sbuff_rdata_rol = {sbuff_rdata_mux[7:0],sbuff_rdata_mux[31:8]};
      2:
        sbuff_rdata_rol = {sbuff_rdata_mux[15:0],sbuff_rdata_mux[31:16]};
      1:
        sbuff_rdata_rol = {sbuff_rdata_mux[23:0],sbuff_rdata_mux[31:24]};
      default:
        sbuff_rdata_rol = sbuff_rdata_mux;
    endcase
  end

  // Number of expected stores
  always_ff @(posedge clk) begin
    if (!rstn) begin
       sbuff_write_cntr_high <= 0;
    end
    else if(cfg_update) begin
      case(cfg_sew[1:0])
        2: // FOR SEW = 32
          sbuff_write_cntr_high <= ((VLMAX32>>cfg_lmul)>>4);
        1: // FOR SEW = 16
          sbuff_write_cntr_high <= ((VLMAX32>>cfg_lmul)>>2);
        default:
          sbuff_write_cntr_high <= (VLMAX32>>cfg_lmul);
      endcase
    end
  end

  // Changing write enable signals for narrow writes
  // Narrower data is packed into 32-bit buffer
  always_ff @(posedge clk) begin
    if (!rstn) begin
      sbuff_wen <= 0;
    end
    case(cfg_sew[1:0])
      2: begin      // FOR SEW = 32
        for(int vlane=0; vlane<V_LANE_NUM; vlane++)
          sbuff_wen[vlane] = 1'b1;
      end
      1: begin      // FOR SEW = 16
      if(cfg_update)
        for(int vlane=0; vlane<V_LANE_NUM; vlane++)
          sbuff_wen[vlane] = (vlane<V_LANE_NUM/2) ? 1'b1 : 1'b0;
      else if (sbuff_whs)
        sbuff_wen <= (sbuff_wen<<(V_LANE_NUM/2)) | (sbuff_wen>>(V_LANE_NUM-V_LANE_NUM/2));
        //sbuff_wen <= {sbuff_wen[(V_LANE_NUM/2-1):0],sbuff_wen[(V_LANE_NUM-1):(V_LANE_NUM/2-1)]};
      end
      default: begin // FOR SEW = 8
      if(cfg_update)
        for(int vlane=0; vlane<V_LANE_NUM; vlane++)
          sbuff_wen[vlane] = (vlane<V_LANE_NUM/2) ? 1'b1 : 1'b0;
      else if (sbuff_whs)
        sbuff_wen <= (sbuff_wen<<(V_LANE_NUM/4)) | (sbuff_wen>>(V_LANE_NUM-V_LANE_NUM/4));
        //sbuff_wen <= {sbuff_wen[(V_LANE_NUM/4-1):0],sbuff_wen[(V_LANE_NUM-1):(V_LANE_NUM/4-1)]};
      end
    endcase
  end

  // Changing axi strobe signals for narrower data
  // Storbing necessasry to write narrower data to 32-bit axi bus
  always_ff @(posedge clk) begin
    if (!rstn) begin
      sbuff_strobe_reg <= 4'b0000;
    end
    case(cfg_sew[1:0])
      2: begin      // FOR SEW = 32
        sbuff_strobe_reg <= 4'b1111;
      end
      1: begin      // FOR SEW = 16
      if(cfg_update)
        sbuff_strobe_reg <= 4'b0011;
      else if (sbuff_rhs)
        sbuff_strobe_reg <= sbuff_strobe_next;
      end
      default: begin // FOR SEW = 8
      if(cfg_update)
        sbuff_strobe_reg <= 4'b0001;
      else if (sbuff_rhs)
        sbuff_strobe_reg <= sbuff_strobe_next;
      end
    endcase
  end

  // Rotate output strobe
  // Rotating strobe signal to fit the position of narrower data in 32-bit word
  always_comb begin
    case(sbuff_strobe_rol_amt)
    3: 
      sbuff_strobe_next = {sbuff_strobe_reg[0],  sbuff_strobe_reg[3:1]};
    2: 
      sbuff_strobe_next = {sbuff_strobe_reg[1:0],sbuff_strobe_reg[3:2]};
    1: 
      sbuff_strobe_next = {sbuff_strobe_reg[2:0],sbuff_strobe_reg[3]};
    default: 
      sbuff_strobe_next = sbuff_strobe_reg;
    endcase
  end

  // MAIN ITERATOR OVER V_LANE BUFFERS
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
            sbuff_wdata[vlane] = {vlane_store_data[(vlane*2)%V_LANE_NUM+1][15:0], vlane_store_data[(vlane*2)%V_LANE_NUM][15:0]};
            sbuff_wptr [vlane] = {vlane_store_ptr [(vlane*2)%V_LANE_NUM+1][15:0], vlane_store_ptr [(vlane*2)%V_LANE_NUM][15:0]};
          end
          default: begin // FOR SEW = 8
            sbuff_wdata[vlane] = {vlane_store_data[(vlane*4)%V_LANE_NUM+3][7:0], vlane_store_data[(vlane*4)%V_LANE_NUM+2][7:0],
                                  vlane_store_data[(vlane*4)%V_LANE_NUM+1][7:0], vlane_store_data[(vlane*4)%V_LANE_NUM   ][7:0]};
            sbuff_wptr [vlane] = {vlane_store_ptr [(vlane*4)%V_LANE_NUM+3][7:0], vlane_store_ptr [(vlane*4)%V_LANE_NUM+2][7:0],
                                  vlane_store_ptr [(vlane*4)%V_LANE_NUM+1][7:0], vlane_store_ptr [(vlane*4)%V_LANE_NUM  ][7:0]};
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
        .wea      ({{4{sbuff_wen[vlane]}},{4{sbuff_wen[vlane]}}}),
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
