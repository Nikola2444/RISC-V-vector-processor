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
  input  wire                                   clk                   ,
  input  wire                                   rstn                  ,
  // Current vector config
  input  wire [2:0]                             cfg_lmul              ,
  input  wire [2:0]                             cfg_data_sew          ,
  input  wire [2:0]                             cfg_idx_sew           ,
  // M_CU interface
  // TODO DEFINE
  input  wire                                   cfg_update            ,
  input  wire                                   cfg_rst               ,
  input  wire                                   sbuff_read_en         ,
  input  wire [1:0]                             store_type            ,
  input  wire [31:0]                            store_stride          ,
  input  wire [31:0]                            store_baseaddr        ,
  input  wire                                   store_baseaddr_update ,
  input  wire                                   sbuff_read_stall      ,
  input  wire                                   sbuff_read_flush      ,
  input  wire                                   sbuff_whs             ,
  input  wire                                   sbuff_rhs             ,
  input  wire                                   sbuff_strobe_ren      ,
  output wire                                   sbuff_not_empty       ,
  output wire                                   sbuff_store_done      ,
  // V_LANE interface
  input  wire                                   vlane_store_valid     , 
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
  // BUFF_DEPTH: Maximum number of 32-bit vector elements stored in buffer
  localparam integer BUFF_DEPTH = VLMAX32_PVL*MAX_VECTORS_BUFFD;
  // WORD_CNTR_WIDTH: Width of word counter in transaction 
  localparam integer WORD_CNTR_WIDTH  = $clog2(VLMAX32);
  localparam integer BATCH_CNTR_WIDTH = $clog2(VLMAX32_PVL);
  ///////////////////////////////////////////////////////////////////////////////
  // Variables
  ///////////////////////////////////////////////////////////////////////////////

  logic [3:0]                               sbuff_strobe_reg,sbuff_strobe_next;
  logic [1:0]                               sbuff_strobe_rol_amt;
  logic [1:0]                               sbuff_rdata_rol_amt;
  logic [1:0]                               sbuff_rptr_rol_amt;

  logic [31:0]                              store_baseaddr_reg;
  logic [WORD_CNTR_WIDTH-1:0]               sbuff_read_cntr;
  logic [BATCH_CNTR_WIDTH-1:0]              sbuff_write_cntr; 
  logic [BATCH_CNTR_WIDTH-1:0]              sbuff_word_cnt; 

  logic [31:0]                              sbuff_rdata_mux;
  logic [31:0]                              sbuff_rptr_mux;
  logic [31:0]                              sbuff_rdata_rol;
  logic [31:0]                              sbuff_rptr_rol;
  logic [31:0]                              sbuff_rptr_ext;

  logic [31:0]                              sdbuff_wdata [0:V_LANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            sdbuff_waddr;
  logic [V_LANE_NUM-1:0]                    sdbuff_wen;
  logic [31:0]                              sdbuff_rdata [0:V_LANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            sdbuff_raddr;
  logic [31:0]                              sdbuff_rptr  [0:V_LANE_NUM-1];
  logic                                     sdbuff_roen;
  logic                                     sdbuff_rocl;

  logic [31:0]                              sibuff_wdata [0:V_LANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            sibuff_waddr;
  logic [V_LANE_NUM-1:0]                    sibuff_wen;
  logic [31:0]                              sibuff_rdata [0:V_LANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            sibuff_raddr;
  logic [31:0]                              sibuff_rptr  [0:V_LANE_NUM-1];
  logic                                     sibuff_roen;
  logic                                     sibuff_rocl;

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
  
  // For indexed and strided operations, we need a counter saving current baseaddr
  always_ff @(posedge clk) begin
    if (!rstn) begin
      store_baseaddr_reg <= 0;
    end
    else if(store_baseaddr_update) begin
      case(store_type)
      2:      // indexed
        store_baseaddr_reg <= store_baseaddr_reg + sbuff_rptr_ext - (1<<cfg_idx_sew[0]); // TODO doublecheck this
      1:      // strided
        store_baseaddr_reg <= store_baseaddr_reg + store_stride - (1<<cfg_idx_sew[0]); // TODO doublecheck this
      default:// unit_stride
        store_baseaddr_reg <= store_baseaddr;
      endcase
    end
  end


  // Counter selects data from one store buffer to forward to axi
  always_ff @(posedge clk) begin
    if (!rstn) begin
      sbuff_read_cntr <= 0;
    end
    else if(sbuff_rhs) begin
      sbuff_read_cntr <= sbuff_read_cntr + 1;
    end
  end

  // Write counter addresses write ports of all store buffers
  // Each store buffer is then selected with sbuff_wen
  // Write counter is incremented:
  // For SEW=32, every single write
  // For SEW=16, every second write
  // For SEW=8,  every fourth write

  // To simplify counter combinatorial logic, we increment
  //  only after we write to the last store buffer

  assign sbuff_not_empty = (sbuff_write_cntr != 0);

  always_ff @(posedge clk) begin
    if (!rstn || cfg_rst)
      sbuff_write_cntr <= 0;
    else if (sbuff_whs) begin
      sbuff_write_cntr <= sbuff_write_cntr + 1;
      if (sbuff_write_cntr >= sbuff_word_cnt)
        sbuff_store_done <= 1'b1;
    end
  end

  // Output barrel shifter after selecting data
  // Narrower data needs to be barrel shifted to fit the position
  assign sbuff_rdata_rol_amt = store_baseaddr_reg[1:0];
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

  // Output barrel shifter after selecting pointer
  // Narrower data needs to be barrel shifted and extended to fit the position
  assign sbuff_rptr_rol_amt = store_baseaddr_reg[1:0];
  always_comb begin
    case (sbuff_rptr_rol_amt)
      3:
        sbuff_rptr_rol = {sbuff_rptr_mux[7:0],sbuff_rptr_mux[31:8]};
      2:
        sbuff_rptr_rol = {sbuff_rptr_mux[15:0],sbuff_rptr_mux[31:16]};
      1:
        sbuff_rptr_rol = {sbuff_rptr_mux[23:0],sbuff_rptr_mux[31:24]};
      default:
        sbuff_rptr_rol = sbuff_rptr_mux;
    endcase
  end

  always_comb begin
    case(cfg_idx_sew[1:0])
      2: // FOR SEW = 32
      begin
        sbuff_rptr_ext = sbuff_rptr_rol;
      end
      1: // FOR SEW = 16
      begin
        sbuff_rptr_ext = {16'b0, sbuff_rptr_rol[15:0]};
      end
      default: // FOR SEW = 8
      begin
        sbuff_rptr_ext = {28'b0, sbuff_rptr_rol[7:0]};
      end
    endcase
  end

  // Number of expected stores
  always_ff @(posedge clk) begin
    if (!rstn) begin
       sbuff_word_cnt <= 0;
    end
    else if(cfg_update) begin
      case(cfg_data_sew[1:0])
        2: // FOR SEW = 32
          sbuff_word_cnt <= ((VLEN)<<cfg_lmul);
        1: // FOR SEW = 16
          sbuff_word_cnt <= ((VLEN<<2)<<cfg_lmul);
        default: // FOR SEW = 8
          sbuff_word_cnt <= ((VLEN<<4)<<cfg_lmul);
      endcase
    end
  end

  // Selecting current addresses for sdbuff
  // Multiplex selecting data from one of V_LANE_NUM buffers to output 
  always_comb  begin
    case(cfg_data_sew[1:0])
      2: // FOR SEW = 32
      begin
        sdbuff_waddr = sbuff_write_cntr;
        sdbuff_raddr = (sbuff_read_cntr>>$clog2(V_LANE_NUM));
        sbuff_rdata_mux = sbuff_rdata[sbuff_read_cntr[0+:$clog2(V_LANE_NUM)]];
      end
      1: // FOR SEW = 16
      begin
        sdbuff_waddr = sbuff_write_cntr>>2;
        sdbuff_raddr = (sbuff_read_cntr>>$clog2(V_LANE_NUM))>>2;
        sbuff_rdata_mux = sbuff_rdata[sbuff_read_cntr[2+:$clog2(V_LANE_NUM)]];
      end
      default: // FOR SEW = 8
      begin
        sdbuff_waddr = sbuff_write_cntr>>4;
        sdbuff_raddr = (sbuff_read_cntr>>$clog2(V_LANE_NUM))>>4;
        sbuff_rdata_mux = sbuff_rdata[sbuff_read_cntr[4+:$clog2(V_LANE_NUM)]];
      end
    endcase
  end

  // Selecting current addresses for sibuff
  // Multiplex selecting index from one of V_LANE_NUM buffers to output 
  always_comb  begin
    case(cfg_idx_sew[1:0])
      2: // FOR SEW = 32
      begin
        sibuff_waddr = sbuff_write_cntr;
        sibuff_raddr = (sbuff_read_cntr>>$clog2(V_LANE_NUM));
        sbuff_rptr_mux  = sibuff_rdata[sbuff_read_cntr[0+:$clog2(V_LANE_NUM)]];
      end
      1: // FOR SEW = 16
      begin
        sibuff_waddr = sbuff_write_cntr>>2;
        sibuff_raddr = (sbuff_read_cntr>>$clog2(V_LANE_NUM))>>2;
        sbuff_rptr_mux  = sibuff_rdata[sbuff_read_cntr[2+:$clog2(V_LANE_NUM)]];
      end
      default: // FOR SEW = 8
      begin
        sibuff_waddr = sbuff_write_cntr>>4;
        sibuff_raddr = (sbuff_read_cntr>>$clog2(V_LANE_NUM))>>4;
        sbuff_rptr_mux  = sibuff_rdata[sbuff_read_cntr[4+:$clog2(V_LANE_NUM)]];
      end
    endcase
  end


  // Changing write enable signals for narrow writes [store data buffer]
  // Narrower data is packed into 32-bit buffer
  always_ff @(posedge clk) begin
    if (!rstn) begin
      sdbuff_wen <= 0;
    end
    case(cfg_data_sew[1:0])
      2: begin      // FOR SEW = 32
        for(int vlane=0; vlane<V_LANE_NUM; vlane++)
          sdbuff_wen[vlane] = 1'b1;
      end
      1: begin      // FOR SEW = 16
        if(cfg_update)
          for(int vlane=0; vlane<V_LANE_NUM; vlane++)
            sdbuff_wen[vlane] = (vlane<V_LANE_NUM/2) ? 1'b1 : 1'b0;
        else if (sbuff_whs)
          sdbuff_wen <= (sdbuff_wen<<(V_LANE_NUM/2)) | (sdbuff_wen>>(V_LANE_NUM-V_LANE_NUM/2));
          //sdbuff_wen <= {sdbuff_wen[(V_LANE_NUM/2-1):0],sdbuff_wen[(V_LANE_NUM-1):(V_LANE_NUM/2-1)]};
      end
      default: begin // FOR SEW = 8
        if(cfg_update)
          for(int vlane=0; vlane<V_LANE_NUM; vlane++)
            sdbuff_wen[vlane] = (vlane<V_LANE_NUM/2) ? 1'b1 : 1'b0;
        else if (sbuff_whs)
          sdbuff_wen <= (sdbuff_wen<<(V_LANE_NUM/4)) | (sdbuff_wen>>(V_LANE_NUM-V_LANE_NUM/4));
          //sdbuff_wen <= {sdbuff_wen[(V_LANE_NUM/4-1):0],sdbuff_wen[(V_LANE_NUM-1):(V_LANE_NUM/4-1)]};
      end
    endcase
  end

  // Changing write enable signals for narrow writes [store index buffer]
  // Narrower data is packed into 32-bit buffer
  always_ff @(posedge clk) begin
    if (!rstn) begin
      sibuff_wen <= 0;
    end
    case(cfg_data_sew[1:0])
      2: begin      // FOR SEW = 32
        for(int vlane=0; vlane<V_LANE_NUM; vlane++)
          sibuff_wen[vlane] = 1'b1;
      end
      1: begin      // FOR SEW = 16
      if(cfg_update)
        for(int vlane=0; vlane<V_LANE_NUM; vlane++)
          sibuff_wen[vlane] = (vlane<V_LANE_NUM/2) ? 1'b1 : 1'b0;
      else if (sbuff_whs)
        sibuff_wen <= (sibuff_wen<<(V_LANE_NUM/2)) | (sibuff_wen>>(V_LANE_NUM-V_LANE_NUM/2));
        //sibuff_wen <= {sibuff_wen[(V_LANE_NUM/2-1):0],sibuff_wen[(V_LANE_NUM-1):(V_LANE_NUM/2-1)]};
      end
      default: begin // FOR SEW = 8
      if(cfg_update)
        for(int vlane=0; vlane<V_LANE_NUM; vlane++)
          sibuff_wen[vlane] = (vlane<V_LANE_NUM/2) ? 1'b1 : 1'b0;
      else if (sbuff_whs)
        sibuff_wen <= (sibuff_wen<<(V_LANE_NUM/4)) | (sibuff_wen>>(V_LANE_NUM-V_LANE_NUM/4));
        //sibuff_wen <= {sibuff_wen[(V_LANE_NUM/4-1):0],sibuff_wen[(V_LANE_NUM-1):(V_LANE_NUM/4-1)]};
      end
    endcase
  end


  // MAIN ITERATOR OVER V_LANE BUFFERS
  genvar vlane;
  generate 
    for (vlane=0; vlane<V_LANE_NUM; vlane++) begin: vlane_iterator // MAIN V_LANE ITERATOR

      // Multiplex narrower data in so writes are in the correct position for byte-write enable
      always_comb begin
        case(cfg_data_sew[1:0])
          2: begin       // FOR SEW = 32
            sdbuff_wdata[vlane] = vlane_store_data[vlane];
            sibuff_wdata[vlane] = vlane_store_ptr [vlane];
          end
          1: begin       // FOR SEW = 16
            sdbuff_wdata[vlane] = {vlane_store_data[(vlane*2)%V_LANE_NUM+1][15:0], vlane_store_data[(vlane*2)%V_LANE_NUM][15:0]};
            sibuff_wdata[vlane] = {vlane_store_ptr [(vlane*2)%V_LANE_NUM+1][15:0], vlane_store_ptr [(vlane*2)%V_LANE_NUM][15:0]};
          end
          default: begin // FOR SEW = 8
            sdbuff_wdata[vlane] = {vlane_store_data[(vlane*4)%V_LANE_NUM+3][7:0], vlane_store_data[(vlane*4)%V_LANE_NUM+2][7:0],
                                   vlane_store_data[(vlane*4)%V_LANE_NUM+1][7:0], vlane_store_data[(vlane*4)%V_LANE_NUM  ][7:0]};
            sibuff_wdata[vlane] = {vlane_store_ptr [(vlane*4)%V_LANE_NUM+3][7:0], vlane_store_ptr [(vlane*4)%V_LANE_NUM+2][7:0],
                                   vlane_store_ptr [(vlane*4)%V_LANE_NUM+1][7:0], vlane_store_ptr [(vlane*4)%V_LANE_NUM  ][7:0]};
          end
        endcase
      end

      // VFR -> DDR Buffer (STORE)
      // Xilinx Simple Dual Port Single Clock RAM with Byte-write
      sdp_bwe_bram #(
        .NB_COL(4),                           // Specify number of columns (number of bytes)
        .COL_WIDTH(8),                        // Specify column width (byte width, typically 8 or 9)
        .RAM_DEPTH(BUFF_DEPTH),               // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
      ) store_data_buffer (
        .clk      (clk),
        .addra    (sdbuff_waddr),
        .addrb    (sdbuff_raddr),
        .dina     (sdbuff_wdata[vlane]),
        .wea      ({4{sdbuff_wen[vlane]}}),
        .enb      (sdbuff_ren),
        .rstb     (sdbuff_ocl),
        .regceb   (sdbuff_oen),
        .doutb    (sdbuff_rdata[vlane])
      );

      assign sdbuff_wdata[vlane] = vlane_store_data[vlane];

      // VFR -> DDR Buffer (STORE)
      // Xilinx Simple Dual Port Single Clock RAM with Byte-write
      sdp_bwe_bram #(
        .NB_COL(4),                           // Specify number of columns (number of bytes)
        .COL_WIDTH(8),                        // Specify column width (byte width, typically 8 or 9)
        .RAM_DEPTH(BUFF_DEPTH),               // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
      ) store_index_buffer (
        .clk      (clk),
        .addra    (sibuff_waddr),
        .addrb    (sibuff_raddr),
        .dina     (sibuff_wdata[vlane]),
        .wea      ({4{sibuff_wen[vlane]}}),
        .enb      (sibuff_ren),
        .rstb     (sibuff_ocl),
        .regceb   (sibuff_oen),
        .doutb    (sibuff_rdata[vlane])
      );

      assign sibuff_wdata[vlane] = vlane_store_ptr[vlane];

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

  // **************************************** STORE BUFFER OUTPUT LOGIC *****************************************************************

  // Changing axi strobe signals for narrower data
  // Storbing necessasry to write narrower data to 32-bit axi bus
  always_ff @(posedge clk) begin
    if (!rstn) begin
      sbuff_strobe_reg <= 4'b0000;
    end
    case(cfg_data_sew[1:0])
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


  assign sdbuff_rdata_mux = sdbuff_rdata[];
  assign sibuff_rdata_mux = sibuff_rdata[];


 endmodule : buff_array
`default_nettype wire
