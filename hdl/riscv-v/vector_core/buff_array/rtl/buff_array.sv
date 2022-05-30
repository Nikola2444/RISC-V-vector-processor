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
  input  wire                                   clk                     ,
  input  wire                                   rstn                    ,
  // Current vector config
  input  wire [2:0]                             cfg_data_lmul           ,
  input  wire [2:0]                             cfg_idx_lmul            ,
  input  wire [2:0]                             cfg_data_sew_i          ,
  input  wire [2:0]                             cfg_idx_sew_i           ,
  input  wire [$clog2(VLEN)-1:0]                cfg_vlenb_i             ,
  // M_CU Interface
  input  wire                                   cfg_store_update_i      ,
  input  wire                                   cfg_store_cntr_rst_i    ,
  input  wire [2:0]                             store_type_i            ,
  input  wire                                   cfg_load_update_i       ,
  input  wire                                   cfg_load_cntr_rst_i     ,
  input  wire [2:0]                             load_type_i             ,
  // M_CU IF [stores]
  input  wire [31:0]                            store_stride_i          ,
  input  wire [31:0]                            store_baseaddr_i        ,
  input  wire                                   store_baseaddr_reset_i ,
  input  wire                                   store_baseaddr_update_i ,
  input  wire                                   sbuff_read_stall_i      ,
  input  wire                                   sbuff_read_flush_i      ,
  input  wire                                   sbuff_wen_i             ,
  input  wire                                   sbuff_ren_i             ,
  output wire                                   sbuff_not_empty_o       ,
  output wire                                   sbuff_write_done_o      ,
  output wire                                   sbuff_read_done_o       ,
  // M_CU IF [loads]
  input  wire [31:0]                            load_stride_i           ,
  input  wire [31:0]                            load_baseaddr_i         ,
  input  wire                                   load_baseaddr_reset_i   ,
  input  wire                                   load_baseaddr_update_i  ,
  input  wire                                   ldbuff_read_stall_i     ,
  input  wire                                   ldbuff_read_flush_i     ,
  input  wire                                   libuff_read_stall_i     ,
  input  wire                                   libuff_read_flush_i     ,
  input  wire                                   ldbuff_wen_i            ,
  input  wire                                   ldbuff_ren_i            ,
  input  wire                                   libuff_wen_i            ,
  input  wire                                   libuff_ren_i            ,
  output wire                                   ldbuff_not_empty_o      ,
  output wire                                   ldbuff_write_done_o     ,
  output wire                                   ldbuff_read_done_o      ,
  output wire                                   libuff_not_empty_o      ,
  output wire                                   libuff_write_done_o     ,
  output wire                                   libuff_read_done_o      ,
  // V_LANE interface
  input  wire [31:0]                            vlane_store_data_i [0:V_LANE_NUM-1],
  input  wire [31:0]                            vlane_store_ptr_i  [0:V_LANE_NUM-1],
  output wire [31:0]                            vlane_load_data_o  [0:V_LANE_NUM-1],
  input  wire [31:0]                            vlane_load_ptr_i   [0:V_LANE_NUM-1],
  // AXIM_CTRL interface
  // read channel
  output wire [C_M_AXI_ADDR_WIDTH-1:0]          ctrl_raddr_offset_o     ,
  output wire [C_XFER_SIZE_WIDTH-1:0]           ctrl_rxfer_size_o       ,
  input  wire [C_M_AXI_DATA_WIDTH-1:0]          rd_tdata_i              ,
  // write channel
  output wire [C_M_AXI_ADDR_WIDTH-1:0]          ctrl_waddr_offset_o     ,
  output wire [C_XFER_SIZE_WIDTH-1:0]           ctrl_wxfer_size_o       ,
  input  wire [C_M_AXI_DATA_WIDTH-1:0]          wr_tdata_o              ,
  input  wire                                   cfg_data_lmul_pn_i      ,
  input  wire [1:0]                             cfg_data_lmul_amt_i       
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
  logic [$clog2(VLMAX)-1:0]                 sbuff_read_cntr;
  logic [BATCH_CNTR_WIDTH-1:0]              sbuff_write_cntr; 
  logic [BATCH_CNTR_WIDTH-1:0]              sbuff_word_batch_cnt; 
  logic [$clog2(VLMAX)-1:0]                 sbuff_word_cnt; 
  logic [$clog2(VLMAX)-1:0]                 sbuff_byte_cnt; 

  logic [31:0]                              sbuff_rdata_mux;
  logic [31:0]                              sbuff_rptr_mux;
  logic [31:0]                              sbuff_rdata_rol;
  logic [31:0]                              sbuff_rptr_rol;
  logic [31:0]                              sbuff_rptr_ext;


  logic [1:0]                               lbuff_rptr_rol_amt;
  logic [31:0]                              lbuff_rptr_rol;
  logic [31:0]                              lbuff_rptr_mux;
  logic [31:0]                              lbuff_rptr_ext;
  logic [31:0]                              load_baseaddr_reg;
  logic [BATCH_CNTR_WIDTH-1:0]              lbuff_word_batch_cnt; 
  logic [$clog2(VLMAX)-1:0]                 lbuff_word_cnt; 
  logic [$clog2(VLMAX)-1:0]                 lbuff_byte_cnt; 
  logic [$clog2(VLMAX)-1:0]                 libuff_read_cntr;
  logic [BATCH_CNTR_WIDTH-1:0]              libuff_write_cntr; 
  // Store Data Buffer Signals
  logic [31:0]                              sdbuff_wdata [0:V_LANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            sdbuff_waddr;
  logic [V_LANE_NUM-1:0]                    sdbuff_wen;
  logic [31:0]                              sdbuff_rdata [0:V_LANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            sdbuff_raddr;
  logic [31:0]                              sdbuff_rptr  [0:V_LANE_NUM-1];
  logic                                     sdbuff_ren;
  logic                                     sdbuff_roen;
  logic                                     sdbuff_rocl;
  // Store Index Buffer Signals
  logic [31:0]                              sibuff_wdata [0:V_LANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            sibuff_waddr;
  logic [V_LANE_NUM-1:0]                    sibuff_wen;
  logic [31:0]                              sibuff_rdata [0:V_LANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            sibuff_raddr;
  logic [31:0]                              sibuff_rptr  [0:V_LANE_NUM-1];
  logic                                     sibuff_ren;
  logic                                     sibuff_roen;
  logic                                     sibuff_rocl;
  // Load Data Buffer Signals
  logic [31:0]                              ldbuff_wdata [0:V_LANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            ldbuff_waddr;
  logic [3:0]                               ldbuff_wen;
  logic [31:0]                              ldbuff_wptr  [0:V_LANE_NUM-1];
  logic [31:0]                              ldbuff_rdata [0:V_LANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            ldbuff_raddr;
  logic [31:0]                              ldbuff_rptr  [0:V_LANE_NUM-1];
  logic                                     ldbuff_roen;
  logic                                     ldbuff_ren;
  logic                                     ldbuff_rocl;
  // Load Index Buffer Signals
  logic [31:0]                              libuff_wdata [0:V_LANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            libuff_waddr;
  logic [3:0]                               libuff_wen;
  logic [31:0]                              libuff_wptr  [0:V_LANE_NUM-1];
  logic [31:0]                              libuff_rdata [0:V_LANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            libuff_raddr;
  logic [31:0]                              libuff_rptr  [0:V_LANE_NUM-1];
  logic                                     libuff_roen;
  logic                                     libuff_ren;
  logic                                     libuff_rocl;
  ///////////////////////////////////////////////////////////////////////////////
  // Begin RTL
  ///////////////////////////////////////////////////////////////////////////////
  
  // For indexed and strided operations, we need a counter saving current baseaddr
  always_ff @(posedge clk) begin
    if (!rstn) begin
      store_baseaddr_reg <= 0;
    end
    else if(store_baseaddr_reset_i) begin
      store_baseaddr_reg <= store_baseaddr_i;
    end
    else if(store_baseaddr_update_i)begin
      case(store_type_i[1:0])
      1:      // indexed
        store_baseaddr_reg <= store_baseaddr_reg + sbuff_rptr_ext - (1<<cfg_idx_sew_i[0]); // TODO double-check this
      2:      // strided
        store_baseaddr_reg <= store_baseaddr_reg + store_stride_i - (1<<cfg_idx_sew_i[0]); // TODO double-check this
      default:// unit_stride
        store_baseaddr_reg <= store_baseaddr_i;
      endcase
    end
  end

  assign ctrl_waddr_offset_o = store_baseaddr_reg;
  assign ctrl_wxfer_size_o   = store_type_i[1:0]==0 ? (sbuff_word_cnt<<2) : 4; // maybe sbuff_byte_cnt

  // Counter selects data from one store buffer to forward to axi
  always_ff @(posedge clk) begin
    if (!rstn || cfg_store_cntr_rst_i) begin
      sbuff_read_cntr <= 0;
    end
    else if(sbuff_ren_i) begin
      sbuff_read_cntr <= sbuff_read_cntr + 1;
    end
  end
  assign sbuff_read_done_o = (sbuff_read_cntr == sbuff_word_cnt);


  // Write counter addresses write ports of all store buffers
  // Each store buffer is then selected with sbuff_wen_i
  // Write counter finishes writing to same address of sbuff:
  // For SEW=32, every single write
  // For SEW=16, every second write
  // For SEW=8,  every fourth write
  always_ff @(posedge clk) begin
    if (!rstn || cfg_store_cntr_rst_i)
      sbuff_write_cntr <= 0;
    else if (sbuff_wen_i) begin
      sbuff_write_cntr <= sbuff_write_cntr + 1;
      if (sbuff_write_cntr >= sbuff_word_batch_cnt)
        sbuff_write_done_o <= 1'b1;
    end
  end
  assign sbuff_not_empty_o = (sbuff_write_cntr != 0);


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
    case(cfg_idx_sew_i[1:0])
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
        sbuff_rptr_ext = {24'b0, sbuff_rptr_rol[7:0]};
      end
    endcase
  end

  // Number of expected stores
  always_ff @(posedge clk) begin
    if (!rstn) begin
       sbuff_word_cnt <= 0;
       sbuff_byte_cnt <= 0;
    end
    else if(cfg_store_update_i) begin
      if(cfg_data_lmul_pn_i) // 
        sbuff_byte_cnt <= ((cfg_vlenb_i)<<cfg_data_lmul_amt_i);
      else
        sbuff_byte_cnt <= ((cfg_vlenb_i)>>cfg_data_lmul_amt_i);
      case(cfg_data_sew_i[1:0])
        2: begin // FOR SEW = 32
          if(cfg_data_lmul_pn_i)
            sbuff_word_cnt <= ((cfg_vlenb_i>>2)<<cfg_data_lmul_amt_i);
          else
            sbuff_word_cnt <= ((cfg_vlenb_i>>2)>>cfg_data_lmul_amt_i);
        end
        1: // FOR SEW = 16
        begin
          if(cfg_data_lmul_pn_i)
            sbuff_word_cnt <= ((cfg_vlenb_i>>1)<<cfg_data_lmul_amt_i);
          else
            sbuff_word_cnt <= ((cfg_vlenb_i>>1)>>cfg_data_lmul_amt_i);
        end
        default: // FOR SEW = 8
        begin
          if(cfg_data_lmul_pn_i)
          sbuff_word_cnt <= ((cfg_vlenb_i)<<cfg_data_lmul_amt_i);
          else
          sbuff_word_cnt <= ((cfg_vlenb_i)>>cfg_data_lmul_amt_i);
        end
      endcase
    end
  end
  assign sbuff_word_cnt = sbuff_word_cnt >> $clog2(V_LANE_NUM);

  // Selecting current addresses for sdbuff
  // Multiplex selecting data from one of V_LANE_NUM buffers to output 
  always_comb  begin
    case(cfg_data_sew_i[1:0])
      2: // FOR SEW = 32
      begin
        sdbuff_waddr = sbuff_write_cntr;
        sdbuff_raddr = (sbuff_read_cntr[WORD_CNTR_WIDTH-1:$clog2(V_LANE_NUM)]);
        sbuff_rdata_mux = sdbuff_rdata[sbuff_read_cntr[0+:$clog2(V_LANE_NUM)]];
      end
      1: // FOR SEW = 16
      begin
        sdbuff_waddr = sbuff_write_cntr>>1;
        sdbuff_raddr = (sbuff_read_cntr[WORD_CNTR_WIDTH-1:$clog2(V_LANE_NUM)+1]);
        sbuff_rdata_mux = sdbuff_rdata[sbuff_read_cntr[1+:$clog2(V_LANE_NUM)]];
      end
      default: // FOR SEW = 8
      begin
        sdbuff_waddr = sbuff_write_cntr>>2;
        sdbuff_raddr = (sbuff_read_cntr[WORD_CNTR_WIDTH-1:$clog2(V_LANE_NUM)+2]);
        sbuff_rdata_mux = sdbuff_rdata[sbuff_read_cntr[2+:$clog2(V_LANE_NUM)]];
      end
    endcase
  end

  // Selecting current addresses for sibuff
  // Multiplex selecting index from one of V_LANE_NUM buffers to output 
  always_comb  begin
    case(cfg_idx_sew_i[1:0])
      2: // FOR SEW = 32
      begin
        sibuff_waddr = sbuff_write_cntr;
        sibuff_raddr = (sbuff_read_cntr[WORD_CNTR_WIDTH-1:$clog2(V_LANE_NUM)]);
        sbuff_rptr_mux  = sibuff_rdata[sbuff_read_cntr[0+:$clog2(V_LANE_NUM)]];
      end
      1: // FOR SEW = 16
      begin
        sibuff_waddr = sbuff_write_cntr>>1;
        sibuff_raddr = (sbuff_read_cntr[WORD_CNTR_WIDTH-1:$clog2(V_LANE_NUM)+1]);
        sbuff_rptr_mux  = sibuff_rdata[sbuff_read_cntr[1+:$clog2(V_LANE_NUM)]];
      end
      default: // FOR SEW = 8
      begin
        sibuff_waddr = sbuff_write_cntr>>2;
        sibuff_raddr = (sbuff_read_cntr[WORD_CNTR_WIDTH-1:$clog2(V_LANE_NUM)+2]);
        sbuff_rptr_mux  = sibuff_rdata[sbuff_read_cntr[2+:$clog2(V_LANE_NUM)]];
      end
    endcase
  end


  // Changing write enable signals for narrow writes [store data buffer]
  // Narrower data is packed into 32-bit buffer
  always_ff @(posedge clk) begin
    if (!rstn) begin
      sdbuff_wen <= 0;
    end
    case(cfg_data_sew_i[1:0])
      2: begin      // FOR SEW = 32
        for(int vlane=0; vlane<V_LANE_NUM; vlane++)
          sdbuff_wen[vlane] = 1'b1;
      end
      1: begin      // FOR SEW = 16
        if(cfg_update_i)
          for(int vlane=0; vlane<V_LANE_NUM; vlane++)
            sdbuff_wen[vlane] = (vlane<V_LANE_NUM/2) ? 1'b1 : 1'b0;
        else if (sbuff_wen_i)
          sdbuff_wen <= (sdbuff_wen<<(V_LANE_NUM/2)) | (sdbuff_wen>>(V_LANE_NUM-V_LANE_NUM/2));
          //sdbuff_wen <= {sdbuff_wen[(V_LANE_NUM/2-1):0],sdbuff_wen[(V_LANE_NUM-1):(V_LANE_NUM/2-1)]};
      end
      default: begin // FOR SEW = 8
        if(cfg_update_i)
          for(int vlane=0; vlane<V_LANE_NUM; vlane++)
            sdbuff_wen[vlane] = (vlane<V_LANE_NUM/2) ? 1'b1 : 1'b0;
        else if (sbuff_wen_i)
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
    case(cfg_data_sew_i[1:0])
      2: begin      // FOR SEW = 32
        for(int vlane=0; vlane<V_LANE_NUM; vlane++)
          sibuff_wen[vlane] = 1'b1;
      end
      1: begin      // FOR SEW = 16
      if(cfg_update_i)
        for(int vlane=0; vlane<V_LANE_NUM; vlane++)
          sibuff_wen[vlane] = (vlane<V_LANE_NUM/2) ? 1'b1 : 1'b0;
      else if (sbuff_wen_i)
        sibuff_wen <= (sibuff_wen<<(V_LANE_NUM/2)) | (sibuff_wen>>(V_LANE_NUM-V_LANE_NUM/2));
        //sibuff_wen <= {sibuff_wen[(V_LANE_NUM/2-1):0],sibuff_wen[(V_LANE_NUM-1):(V_LANE_NUM/2-1)]};
      end
      default: begin // FOR SEW = 8
      if(cfg_update_i)
        for(int vlane=0; vlane<V_LANE_NUM; vlane++)
          sibuff_wen[vlane] = (vlane<V_LANE_NUM/2) ? 1'b1 : 1'b0;
      else if (sbuff_wen_i)
        sibuff_wen <= (sibuff_wen<<(V_LANE_NUM/4)) | (sibuff_wen>>(V_LANE_NUM-V_LANE_NUM/4));
        //sibuff_wen <= {sibuff_wen[(V_LANE_NUM/4-1):0],sibuff_wen[(V_LANE_NUM-1):(V_LANE_NUM/4-1)]};
      end
    endcase
  end


  // MAIN ITERATOR OVER V_LANE BUFFERS
  genvar vlane;
  generate 
    for (vlane=0; vlane<V_LANE_NUM; vlane++) begin: sbuff_vlane_iterator // MAIN V_LANE ITERATOR

      // Multiplex narrower data in so writes are in the correct position for byte-write enable
      always_comb begin
        case(cfg_data_sew_i[1:0])
          2: begin       // FOR SEW = 32
            sdbuff_wdata[vlane] = vlane_store_data_i[vlane];
            sibuff_wdata[vlane] = vlane_store_ptr_i [vlane];
          end
          1: begin       // FOR SEW = 16
            sdbuff_wdata[vlane] = {vlane_store_data_i[(vlane*2)%V_LANE_NUM+1][15:0], vlane_store_data_i[(vlane*2)%V_LANE_NUM][15:0]};
            sibuff_wdata[vlane] = {vlane_store_ptr_i [(vlane*2)%V_LANE_NUM+1][15:0], vlane_store_ptr_i [(vlane*2)%V_LANE_NUM][15:0]};
          end
          default: begin // FOR SEW = 8
            sdbuff_wdata[vlane] = {vlane_store_data_i[(vlane*4)%V_LANE_NUM+3][7:0], vlane_store_data_i[(vlane*4)%V_LANE_NUM+2][7:0],
                                   vlane_store_data_i[(vlane*4)%V_LANE_NUM+1][7:0], vlane_store_data_i[(vlane*4)%V_LANE_NUM  ][7:0]};
            sibuff_wdata[vlane] = {vlane_store_ptr_i [(vlane*4)%V_LANE_NUM+3][7:0], vlane_store_ptr_i [(vlane*4)%V_LANE_NUM+2][7:0],
                                   vlane_store_ptr_i [(vlane*4)%V_LANE_NUM+1][7:0], vlane_store_ptr_i [(vlane*4)%V_LANE_NUM  ][7:0]};
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
        .wea      (sbuff_wen_i && {4{sdbuff_wen[vlane]}}),
        .enb      (sdbuff_ren),
        .rstb     (sdbuff_rocl),
        .regceb   (sdbuff_roen),
        .doutb    (sdbuff_rdata[vlane])
      );

      assign sdbuff_wdata[vlane] = vlane_store_data_i[vlane];
      assign sdbuff_ren  = !sbuff_read_stall_i;
      assign sdbuff_roen = !sbuff_read_stall_i;
      assign sdbuff_rocl = sbuff_read_flush_i;

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
        .wea      (sbuff_wen_i && {4{sibuff_wen[vlane]}}),
        .enb      (sibuff_ren),
        .rstb     (sibuff_rocl),
        .regceb   (sibuff_roen),
        .doutb    (sibuff_rdata[vlane])
      );

      assign sibuff_wdata[vlane] = vlane_store_ptr_i[vlane];
      assign sibuff_ren  = !sbuff_read_stall_i;
      assign sibuff_roen = !sbuff_read_stall_i;
      assign sibuff_rocl = sbuff_read_flush_i;


    end
  endgenerate

  // **************************************** STORE BUFFER OUTPUT LOGIC *****************************************************************

  // Changing axi strobe signals for narrower data
  // Storbing necessasry to write narrower data to 32-bit axi bus
  always_ff @(posedge clk) begin
    if (!rstn) begin
      sbuff_strobe_reg <= 4'b0000;
    end
    case(cfg_data_sew_i[1:0])
      2: begin      // FOR SEW = 32
        sbuff_strobe_reg <= 4'b1111;
      end
      1: begin      // FOR SEW = 16
      if(cfg_update_i)
        sbuff_strobe_reg <= 4'b0011;
      else if (sbuff_ren_i)
        sbuff_strobe_reg <= sbuff_strobe_next;
      end
      default: begin // FOR SEW = 8
      if(cfg_update_i)
        sbuff_strobe_reg <= 4'b0001;
      else if (sbuff_ren_i)
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
  // ***************************************************************************************************************************************
  // ***********************************************       LOAD BUFFER LOGIC        ********************************************************
  // ***************************************************************************************************************************************
  
  // Number of expected loads
  always_ff @(posedge clk) begin
    if (!rstn) begin
       lbuff_word_cnt <= 0;
       lbuff_byte_cnt <= 0;
    end
    else if(cfg_load_update_i) begin
      if(cfg_data_lmul_pn_i) // 
        lbuff_byte_cnt <= ((cfg_vlenb_i)<<cfg_data_lmul_amt_i);
      else
        lbuff_byte_cnt <= ((cfg_vlenb_i)>>cfg_data_lmul_amt_i);
      case(cfg_data_sew_i[1:0])
        2: begin // FOR SEW = 32
          if(cfg_data_lmul_pn_i)
            lbuff_word_cnt <= ((cfg_vlenb_i>>2)<<cfg_data_lmul_amt_i);
          else
            lbuff_word_cnt <= ((cfg_vlenb_i>>2)>>cfg_data_lmul_amt_i);
        end
        1: // FOR SEW = 16
        begin
          if(cfg_data_lmul_pn_i)
            lbuff_word_cnt <= ((cfg_vlenb_i>>1)<<cfg_data_lmul_amt_i);
          else
            lbuff_word_cnt <= ((cfg_vlenb_i>>1)>>cfg_data_lmul_amt_i);
        end
        default: // FOR SEW = 8
        begin
          if(cfg_data_lmul_pn_i)
            lbuff_word_cnt <= ((cfg_vlenb_i)<<cfg_data_lmul_amt_i);
          else
            lbuff_word_cnt <= ((cfg_vlenb_i)>>cfg_data_lmul_amt_i);
        end
      endcase
    end
  end
  assign lbuff_word_cnt = lbuff_word_cnt >> $clog2(V_LANE_NUM);
  // For indexed and strided operations, we need a counter saving current baseaddr
  always_ff @(posedge clk) begin
    if (!rstn) begin
      load_baseaddr_reg <= 0;
    end
    else if(load_baseaddr_reset_i) begin
      load_baseaddr_reg <= load_baseaddr_i;
    end
    else if(load_baseaddr_update_i)begin
      case(load_type_i[1:0])
      1:      // indexed
        load_baseaddr_reg <= load_baseaddr_reg + lbuff_rptr_ext - (1<<cfg_idx_sew_i[0]); // TODO double-check this
      2:      // strided
        load_baseaddr_reg <= load_baseaddr_reg + load_stride_i - (1<<cfg_idx_sew_i[0]); // TODO double-check this
      default:// unit_stride
        load_baseaddr_reg <= load_baseaddr_i;
      endcase
    end
  end

  assign ctrl_raddr_offset_o = load_baseaddr_reg;
  assign ctrl_rxfer_size_o   = load_type_i[1:0]==0 ? (lbuff_word_cnt<<2) : 4; // maybe lbuff_byte_cnt

  // Counter selects data from one load buffer to forward to axi
  always_ff @(posedge clk) begin
    if (!rstn || cfg_load_cntr_rst_i) begin
      libuff_read_cntr <= 0;
    end
    else if(libuff_ren_i) begin
      libuff_read_cntr <= libuff_read_cntr + 1;
    end
  end
  assign libuff_read_done_o = (libuff_read_cntr == lbuff_word_cnt);

  // Output barrel shifter after selecting pointer
  // Narrower data needs to be barrel shifted and extended to fit the position
  assign lbuff_rptr_rol_amt = load_baseaddr_reg[1:0];
  always_comb begin
    case (lbuff_rptr_rol_amt)
      3:
        lbuff_rptr_rol = {lbuff_rptr_mux[7:0],lbuff_rptr_mux[31:8]};
      2:
        lbuff_rptr_rol = {lbuff_rptr_mux[15:0],lbuff_rptr_mux[31:16]};
      1:
        lbuff_rptr_rol = {lbuff_rptr_mux[23:0],lbuff_rptr_mux[31:24]};
      default:
        lbuff_rptr_rol = lbuff_rptr_mux;
    endcase
  end

  always_comb begin
    case(cfg_idx_sew_i[1:0])
      2: // FOR SEW = 32
      begin
        lbuff_rptr_ext = lbuff_rptr_rol;
      end
      1: // FOR SEW = 16
      begin
        lbuff_rptr_ext = {16'b0, lbuff_rptr_rol[15:0]};
      end
      default: // FOR SEW = 8
      begin
        lbuff_rptr_ext = {24'b0, lbuff_rptr_rol[7:0]};
      end
    endcase
  end

  // Write counter addresses write ports of index load buffers
  // Each load buffer is then selected with libuff_wen_i
  // Write counter finishes writing to same address of libuff:
  // For SEW=32, every single write
  // For SEW=16, every second write
  // For SEW=8,  every fourth write
  always_ff @(posedge clk) begin
    if (!rstn || cfg_load_cntr_rst_i)
      libuff_write_cntr <= 0;
    else if (libuff_wen_i) begin
      libuff_write_cntr <= libuff_write_cntr + 1;
      if (libuff_write_cntr >= lbuff_word_batch_cnt)
        libuff_write_done_o <= 1'b1;
    end
  end
  assign libuff_not_empty_o = (libuff_write_cntr != 0);
  
  // Selecting current addresses for libuff
  // Multiplex selecting index from one of V_LANE_NUM buffers to output 
  always_comb  begin
    case(cfg_idx_sew_i[1:0])
      2: // FOR SEW = 32
      begin
        libuff_waddr = libuff_write_cntr;
        libuff_raddr = (libuff_read_cntr[WORD_CNTR_WIDTH-1:$clog2(V_LANE_NUM)]);
        lbuff_rptr_mux  = libuff_rdata[libuff_read_cntr[0+:$clog2(V_LANE_NUM)]];
      end
      1: // FOR SEW = 16
      begin
        libuff_waddr = libuff_write_cntr>>1;
        libuff_raddr = (libuff_read_cntr[WORD_CNTR_WIDTH-1:$clog2(V_LANE_NUM)+1]);
        lbuff_rptr_mux  = libuff_rdata[libuff_read_cntr[1+:$clog2(V_LANE_NUM)]];
      end
      default: // FOR SEW = 8
      begin
        libuff_waddr = libuff_write_cntr>>2;
        libuff_raddr = (libuff_read_cntr[WORD_CNTR_WIDTH-1:$clog2(V_LANE_NUM)+2]);
        lbuff_rptr_mux  = libuff_rdata[libuff_read_cntr[2+:$clog2(V_LANE_NUM)]];
      end
    endcase
  end

  // Changing write enable signals for narrow writes [load index buffer]
  // Narrower data is packed into 32-bit buffer
  always_ff @(posedge clk) begin
    if (!rstn) begin
      libuff_wen <= 0;
    end
    case(cfg_data_sew_i[1:0])
      2: begin      // FOR SEW = 32
        for(int vlane=0; vlane<V_LANE_NUM; vlane++)
          libuff_wen[vlane] = 1'b1;
      end
      1: begin      // FOR SEW = 16
      if(cfg_update_i)
        for(int vlane=0; vlane<V_LANE_NUM; vlane++)
          libuff_wen[vlane] = (vlane<V_LANE_NUM/2) ? 1'b1 : 1'b0;
      else if (libuff_wen_i)
        libuff_wen <= (libuff_wen<<(V_LANE_NUM/2)) | (libuff_wen>>(V_LANE_NUM-V_LANE_NUM/2));
        //libuff_wen <= {libuff_wen[(V_LANE_NUM/2-1):0],libuff_wen[(V_LANE_NUM-1):(V_LANE_NUM/2-1)]};
      end
      default: begin // FOR SEW = 8
      if(cfg_update_i)
        for(int vlane=0; vlane<V_LANE_NUM; vlane++)
          libuff_wen[vlane] = (vlane<V_LANE_NUM/2) ? 1'b1 : 1'b0;
      else if (libuff_wen_i)
        libuff_wen <= (libuff_wen<<(V_LANE_NUM/4)) | (libuff_wen>>(V_LANE_NUM-V_LANE_NUM/4));
        //libuff_wen <= {libuff_wen[(V_LANE_NUM/4-1):0],libuff_wen[(V_LANE_NUM-1):(V_LANE_NUM/4-1)]};
      end
    endcase
  end

  generate 
    for (vlane=0; vlane<V_LANE_NUM; vlane++) begin: load_vlane_iterator // MAIN V_LANE ITERATOR

      // Multiplex narrower data in so writes are in the correct position for byte-write enable
      always_comb begin
        case(cfg_data_sew_i[1:0])
          2: begin       // FOR SEW = 32
            libuff_wdata[vlane] = vlane_load_ptr_i [vlane];
          end
          1: begin       // FOR SEW = 16
            libuff_wdata[vlane] = {vlane_load_ptr_i [(vlane*2)%V_LANE_NUM+1][15:0], vlane_load_ptr_i [(vlane*2)%V_LANE_NUM][15:0]};
          end
          default: begin // FOR SEW = 8
            libuff_wdata[vlane] = {vlane_load_ptr_i [(vlane*4)%V_LANE_NUM+3][7:0], vlane_load_ptr_i [(vlane*4)%V_LANE_NUM+2][7:0],
                                   vlane_load_ptr_i [(vlane*4)%V_LANE_NUM+1][7:0], vlane_load_ptr_i [(vlane*4)%V_LANE_NUM  ][7:0]};
          end
        endcase
      end

      // DDR Buffer -> VRF (LOAD) | Data Buffer
      // Xilinx Simple Dual Port Single Clock RAM with Byte-write
      sdp_bwe_bram #(
        .NB_COL(4),                           // Specify number of columns (number of bytes)
        .COL_WIDTH(8),                        // Specify column width (byte width, typically 8 or 9)
        .RAM_DEPTH(BUFF_DEPTH),               // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
      ) load_data_buffer (
        .clk      (clk),
        .addra    (ldbuff_waddr),
        .addrb    (ldbuff_raddr),
        .dina     (ldbuff_wdata[vlane]),
        .wea      (lbuff_wen_i && {4{ldbuff_wen[vlane]}}),
        .enb      (ldbuff_ren),
        .rstb     (ldbuff_rocl),
        .regceb   (ldbuff_roen),
        .doutb    (ldbuff_rdata[vlane])
      );

      assign vlane_load_data_o[vlane] = ldbuff_rdata[vlane];
      assign ldbuff_ren  = !ldbuff_read_stall_i;
      assign ldbuff_roen = !ldbuff_read_stall_i;
      assign ldbuff_rocl = ldbuff_read_flush_i;

      // DDR Buffer -> VRF (LOAD) | Index Buffer
      // Xilinx Simple Dual Port Single Clock RAM with Byte-write
      sdp_bwe_bram #(
        .NB_COL(4),                           // Specify number of columns (number of bytes)
        .COL_WIDTH(8),                        // Specify column width (byte width, typically 8 or 9)
        .RAM_DEPTH(BUFF_DEPTH),               // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
      ) load_index_buffer (
        .clk      (clk),
        .addra    (libuff_waddr),
        .addrb    (libuff_raddr),
        .dina     (libuff_wdata[vlane]),
        .wea      (lbuff_wen_i && {4{libuff_wen[vlane]}}),
        .enb      (libuff_ren),
        .rstb     (libuff_rocl),
        .regceb   (libuff_roen),
        .doutb    (libuff_rdata[vlane])
      );

      assign libuff_wdata[vlane] = vlane_load_ptr_i[vlane];
      assign libuff_ren  = !libuff_read_stall_i;
      assign libuff_roen = !libuff_read_stall_i;
      assign libuff_rocl = libuff_read_flush_i;

    end
  endgenerate
 endmodule : buff_array
`default_nettype wire
