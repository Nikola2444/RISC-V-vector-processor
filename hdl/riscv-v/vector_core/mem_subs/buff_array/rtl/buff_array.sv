// Coded by Djordje Miseljic | e-mail: djordjemiseljic@uns.ac.rs
////////////////////////////////////////////////////////////////////////////////
// default_nettype of none prevents implicit logic declaration.
`default_nettype wire

module buff_array #(
  parameter integer VLEN                     = 8192,
  parameter integer VLANE_NUM                = 8 ,
  parameter integer MAX_VECTORS_BUFFD        = 1 ,
  parameter integer C_M_AXI_ADDR_WIDTH       = 32,
  parameter integer C_M_AXI_DATA_WIDTH       = 32,
  parameter integer C_XFER_SIZE_WIDTH        = 32
)
(
  // System Signals
  input  logic                                   clk                     ,
  input  logic                                   rstn                    ,
  // MCU => BUFF_ARRAY CONFIG IF [general]
  input  logic [$clog2(VLEN)-1:0]                cfg_vl_i             ,
  // MCU => BUFF_ARRAY CONFIG IF [stores]
  input  logic [2:0]                             cfg_store_data_lmul_i   ,
  input  logic [2:0]                             cfg_store_idx_lmul_i    ,
  input  logic [2:0]                             cfg_store_data_sew_i    ,
  input  logic [2:0]                             cfg_store_idx_sew_i     ,
  // MCU => BUFF_ARRAY CONFIG IF [loads]
  input  logic [2:0]                             cfg_load_data_lmul_i    ,
  input  logic [2:0]                             cfg_load_idx_lmul_i     ,
  input  logic [2:0]                             cfg_load_data_sew_i     ,
  input  logic [2:0]                             cfg_load_idx_sew_i      ,
  // M_CU Interface
  // M_CU <=> BUFF_ARR IF [stores]
  input  logic                                   store_cfg_update_i      ,
  input  logic                                   store_cntr_rst_i        ,
  input  logic [2:0]                             store_type_i            ,
  input  logic [31:0]                            store_stride_i          ,
  input  logic [31:0]                            store_baseaddr_i        ,
  input  logic                                   store_baseaddr_set_i    ,
  input  logic                                   store_baseaddr_update_i ,
  input  logic                                   sdbuff_read_stall_i     ,
  input  logic                                   sdbuff_read_flush_i     ,
  input  logic                                   sibuff_read_stall_i     ,
  input  logic                                   sibuff_read_flush_i     ,
  input  logic                                   sbuff_wen_i             ,
  input  logic                                   sdbuff_ren_i            ,
  input  logic                                   sibuff_ren_i            ,
  output logic                                   sibuff_not_empty_o      ,
  output logic                                   sdbuff_write_done_o     ,
  output logic                                   sibuff_write_done_o     ,
  output logic                                   sdbuff_read_done_o      ,
  output logic                                   sibuff_read_done_o      ,
  output logic                                   sdbuff_read_rdy_o       ,
  output logic                                   sibuff_read_rdy_o       ,
  // M_CU <=> BUFF_ARRAY IF [loads]
  input  logic                                   load_cfg_update_i       ,
  input  logic                                   load_cntr_rst_i         ,
  input  logic [2:0]                             load_type_i             ,
  input  logic [31:0]                            load_stride_i           ,
  input  logic [31:0]                            load_baseaddr_i         ,
  input  logic                                   load_baseaddr_set_i   ,
  input  logic                                   load_baseaddr_update_i  ,
  input  logic                                   ldbuff_read_stall_i     ,
  input  logic                                   ldbuff_read_flush_i     ,
  input  logic                                   libuff_read_stall_i     ,
  input  logic                                   libuff_read_flush_i     ,
  input  logic                                   ldbuff_wen_i            ,
  input  logic                                   ldbuff_wlast_i          ,
  input  logic                                   ldbuff_ren_i            ,
  input  logic                                   libuff_wen_i            ,
  input  logic                                   libuff_ren_i            ,
  output logic                                   libuff_read_rdy_o       ,
  output logic                                   ldbuff_not_empty_o      ,
  output logic                                   ldbuff_write_done_o     ,
  output logic                                   ldbuff_read_done_o      ,
  output logic                                   libuff_not_empty_o      ,
  output logic                                   libuff_write_done_o     ,
  output logic                                   libuff_read_done_o      ,
  // V_LANE <=> BUFF_ARRAY IF
  input  logic [31:0]                            vlane_store_data_i [0:VLANE_NUM-1],
  input  logic [31:0]                            vlane_store_idx_i  [0:VLANE_NUM-1],
  output logic [31:0]                            vlane_load_data_o  [0:VLANE_NUM-1],
  output logic [3:0]                             vlane_load_bwe_o   [0:VLANE_NUM-1],
  input  logic [31:0]                            vlane_load_idx_i   [0:VLANE_NUM-1],
  // AXIM_CTRL <=> BUFF_ARRAY IF [write channel]
  output logic [C_M_AXI_ADDR_WIDTH-1:0]          ctrl_raddr_offset_o     ,
  output logic [C_XFER_SIZE_WIDTH-1:0]           ctrl_rxfer_size_o       ,
  input  logic [C_M_AXI_DATA_WIDTH-1:0]          rd_tdata_i              ,
  // AXIM_CTRL <=> BUFF_ARRAY IF [read channel]
  output logic [C_M_AXI_ADDR_WIDTH-1:0]          ctrl_waddr_offset_o     ,
  output logic [C_XFER_SIZE_WIDTH-1:0]           ctrl_wxfer_size_o       ,
  output logic                                   ctrl_wstrb_msk_en_o     ,
  output logic [3:0]                             wr_tstrb_msk_o          ,
  output logic [C_M_AXI_DATA_WIDTH-1:0]          wr_tdata_o              
);
  ///////////////////////////////////////////////////////////////////////////////
  // Local Parameters
  ///////////////////////////////////////////////////////////////////////////////
  //
  // VLMAX: Maximum number of elements in a vector register group.
  //    VLMAX=VLEN*LMUL_MAX/SEW_MIN=VLEN*8/8=VLEN
  localparam integer VLMAX = VLEN; 
  // VLMAX_PVL: Maximum number of elements per vector lane
  localparam integer VLMAX_PVL = VLMAX/VLANE_NUM;
  // VLMAX32: Maximum number of 32-bit vector elements
  //    VLMAX32=VLEN*LMUL_MAX/32=VLEN*8/32=VLEN/4
  localparam integer VLMAX32 = VLEN/4; 
  // VLMAX32_PVL: Maximum number of 32-bit vector elements per vector lane
  localparam integer VLMAX32_PVL = VLMAX32/VLANE_NUM;
  // BUFF_DEPTH: Maximum number of 32-bit vector elements stored in buffer
  localparam integer BUFF_DEPTH = VLMAX32_PVL*MAX_VECTORS_BUFFD;
  // WORD_CNTR_WIDTH: Width of word counter in transaction 
  localparam integer WORD_CNTR_WIDTH  = $clog2(VLMAX32);
  localparam integer BATCH_CNTR_WIDTH = $clog2(VLMAX_PVL);
  ///////////////////////////////////////////////////////////////////////////////
  // Variables
  ///////////////////////////////////////////////////////////////////////////////


  // STORE LOGIC INTERFACE *************
  // Read all VLANE buffers -> select one with mux -> rotate to lsb part -> extend with zeros
  logic [31:0]                              sbuff_rptr_mux;
  logic [1:0]                               sbuff_rptr_rol_amt;
  logic [31:0]                              sbuff_rptr_rol;
  logic [31:0]                              sbuff_rptr_ext;
  // Read all VLANE buffers -> select one with mux -> rotate to fit address position
  logic [31:0]                              sbuff_rdata_mux;
  logic [$clog2(VLANE_NUM)+1:0]             sdbuff_read_cntr_low;
  logic [$clog2(VLANE_NUM)+1:0]             sdbuff_read_cntr_low_d [1:0];
  logic [$clog2(VLANE_NUM)+1:0]             sibuff_read_cntr_low;
  logic [$clog2(VLANE_NUM)+1:0]             sibuff_read_cntr_low_d [1:0];
  logic [1:0]                               sbuff_rdata_rol_amt;
  logic [1:0]                               sbuff_rdata_ror_amt;
  logic [1:0]                               sbuff_rdata_total_rol_amt;
  logic [31:0]                              sbuff_rdata_rol;
  // Strobing to write only SEW bytes via AXI master
  logic [3:0]                               sbuff_strobe_reg,sbuff_strobe_curr; // TODO connect for narrow writes;; Check if AXI mctrl supports it
  logic [1:0]                               sbuff_strobe_rol_amt;
  // Registers for counting data during transactions
  logic [31:0]                              store_baseaddr_reg;
  logic [$clog2(VLMAX):0]                   sdbuff_read_cntr,sdbuff_read_cntr_next, sdbuff_read_cntr_nnext;
  logic [$clog2(VLMAX):0]                   sdbuff_read_cntr_incr,sdbuff_read_cntr_iincr;
  logic [$clog2(VLMAX):0]                   sibuff_read_cntr,sibuff_read_cntr_next, sibuff_read_cntr_nnext;
  logic [$clog2(VLMAX):0]                   sibuff_read_cntr_incr,sibuff_read_cntr_iincr;
  logic [$clog2(VLMAX):0]                   sbuff_write_cntr,sbuff_write_cntr_next; 
  logic [$clog2(VLMAX):0]                   sbuff_word_cnt; 
  logic [$clog2(VLMAX):0]                   sdbuff_byte_cnt; 
  logic [$clog2(VLMAX):0]                   sibuff_byte_cnt; 
  logic [31:0]                              store_stride_reg;
  // LOAD LOGIC INTERFACE ***************
  // Read data from AXI full -> rotate right to LSB -> rotate left to right buffer location
  logic [31:0]                              load_stride_reg;
  logic [1:0]                               lbuff_wdata_rol_amt;
  logic [1:0]                               lbuff_wdata_ror_amt;
  logic [1:0]                               lbuff_wdata_total_rol_amt;
  logic [31:0]                              lbuff_wdata_rol;
  logic [31:0]                              lbuff_wdata_mux[0:VLANE_NUM-1];
  // Read all VLANE buffers -> select one with mux -> rotate to lsb part -> extend with zeros
  logic [1:0]                               lbuff_rptr_rol_amt;
  logic [31:0]                              lbuff_rptr_rol;
  logic [31:0]                              lbuff_rptr_mux;
  logic [31:0]                              lbuff_rptr_ext;
  // Registers for counting data during transactions
  logic [31:0]                              load_baseaddr_reg;
  logic [$clog2(VLMAX):0]                   lbuff_word_cnt; 
  logic [$clog2(VLMAX):0]                   ldbuff_byte_cnt; 
  logic [$clog2(VLANE_NUM)+1:0]             libuff_read_cntr_low;
  logic [$clog2(VLANE_NUM)+1:0]             libuff_read_cntr_low_d [1:0];
  logic [$clog2(VLMAX):0]                   libuff_byte_cnt; 
  logic [$clog2(VLMAX):0]                   libuff_read_cntr,libuff_read_cntr_next, libuff_read_cntr_nnext;
  logic [$clog2(VLMAX):0]                   libuff_read_cntr_incr,libuff_read_cntr_iincr;
  logic [$clog2(VLMAX):0]                   libuff_write_cntr,libuff_write_cntr_next; 
  logic [$clog2(VLMAX):0]                   ldbuff_read_cntr,ldbuff_read_cntr_next; 
  logic [$clog2(VLMAX):0]                   ldbuff_write_cntr,ldbuff_write_cntr_next,ldbuff_write_cntr_incr;

  // STORE BUFFER INTERFACE ************
  // Store Data Buffer Signals
  logic [31:0]                              sdbuff_wdata [0:VLANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            sdbuff_waddr;
  logic [3:0]                               sdbuff_wen;
  logic [31:0]                              sdbuff_rdata [0:VLANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            sdbuff_raddr_curr;
  logic [$clog2(BUFF_DEPTH)-1:0]            sdbuff_raddr_nnext;
  logic [$clog2(BUFF_DEPTH)-1:0]            sdbuff_raddr [0:VLANE_NUM-1];
  logic [31:0]                              sdbuff_rptr  [0:VLANE_NUM-1];
  logic                                     sdbuff_ren;
  logic                                     sdbuff_roen;
  logic                                     sdbuff_rocl;
  // Store Index Buffer Signals
  logic [31:0]                              sibuff_wdata [0:VLANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            sibuff_waddr;
  logic [$clog2(BUFF_DEPTH)-1:0]            sibuff_raddr_curr;
  logic [$clog2(BUFF_DEPTH)-1:0]            sibuff_raddr_nnext;
  logic [3:0]                               sibuff_wen;
  logic [31:0]                              sibuff_rdata [0:VLANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            sibuff_raddr [0:VLANE_NUM-1];
  logic [31:0]                              sibuff_rptr  [0:VLANE_NUM-1];
  logic                                     sibuff_ren;
  logic                                     sibuff_roen;
  logic                                     sibuff_rocl;
  // LOAD BUFFER INTERFACE ************
  // Load Data Buffer Signals
  logic [35:0]                              ldbuff_wdata [0:VLANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            ldbuff_waddr;
  logic [VLANE_NUM-1:0][3:0]                ldbuff_wen_reg;
  logic [VLANE_NUM-1:0][3:0]                ldbuff_nwen;
  logic [VLANE_NUM-1:0][3:0]                ldbuff_pr_wen;
  logic [31:0]                              ldbuff_wptr  [0:VLANE_NUM-1];
  logic [35:0]                              ldbuff_rdata [0:VLANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            ldbuff_raddr;
  logic [31:0]                              ldbuff_rptr  [0:VLANE_NUM-1];
  logic                                     ldbuff_roen;
  logic                                     ldbuff_ren;
  logic                                     ldbuff_rocl;
  // Load Index Buffer Signals
  logic [31:0]                              libuff_wdata [0:VLANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            libuff_waddr;
  logic [$clog2(BUFF_DEPTH)-1:0]            libuff_raddr_curr;
  logic [$clog2(BUFF_DEPTH)-1:0]            libuff_raddr_nnext;
  logic [VLANE_NUM-1:0][3:0]                libuff_wen;
  logic [31:0]                              libuff_wptr  [0:VLANE_NUM-1];
  logic [31:0]                              libuff_rdata [0:VLANE_NUM-1];
  logic [$clog2(BUFF_DEPTH)-1:0]            libuff_raddr [0:VLANE_NUM-1];
  logic [31:0]                              libuff_rptr  [0:VLANE_NUM-1];
  logic                                     libuff_roen;
  logic                                     libuff_ren;
  logic                                     libuff_rocl;
  // Misc
  logic [ 3:0]                              ldbuff_wen_last_mask;
  logic                                     single_word_load;
  logic                                     single_word_store;
  logic [ 3:0]                              ldbuff_wen_narrow_mask;
  logic [ 3:0]                              ldbuff_wen_mux [0:VLANE_NUM-1];
  logic [ 3:0]                              ldbuff_wen_masked [0:VLANE_NUM-1];
  

  ///////////////////////////////////////////////////////////////////////////////
  // Begin RTL
  ///////////////////////////////////////////////////////////////////////////////
  
  
  // For indexed and strided operations, we need a counter saving current baseaddr
  always_ff @(posedge clk) begin
    if (!rstn) begin
      store_baseaddr_reg <= 0;
      store_stride_reg   <= 0;
    end
    else if(store_baseaddr_set_i) begin
      store_baseaddr_reg <= store_baseaddr_i;
      store_stride_reg   <= store_stride_i;
    end
    else if(store_baseaddr_update_i) begin
      case(store_type_i[1:0])
      1:      // indexed
        store_baseaddr_reg <= store_baseaddr_reg + sbuff_rptr_ext;// - (1<<cfg_store_data_sew_i[0]); // TODO double-check this, NOT NEEDED?
      2:      // strided
        store_baseaddr_reg <= store_baseaddr_reg + store_stride_reg;// - (1<<cfg_store_data_sew_i[0]); // TODO double-check this, NOTE NEEDED?
      default:// unit_stride
        store_baseaddr_reg <= store_baseaddr_i;
      endcase
    end
  end
  assign single_word_store   = !store_type_i[2]; // Not unit-stride => an y of other two is sigle word per xfer
  assign ctrl_wstrb_msk_en_o = single_word_store;

  assign ctrl_waddr_offset_o = {store_baseaddr_reg[31:2], 2'b00}; // align per 32-bit TODO: double-check this
  assign ctrl_wxfer_size_o   = store_type_i[2] ? (sdbuff_byte_cnt) : 4;

  // Number of expected stores
  always_ff @(posedge clk) begin
    if (!rstn) begin
      sbuff_word_cnt <= 0;
    end
    else if(store_cfg_update_i) begin
      sbuff_word_cnt <= cfg_vl_i;
    end
  end
  assign sdbuff_byte_cnt = sbuff_word_cnt << cfg_store_data_sew_i[1:0];
  assign sibuff_byte_cnt = sbuff_word_cnt << cfg_store_idx_sew_i[1:0];
  
  // Counter selects data from one store buffer to forward to axi
  always_ff @(posedge clk) begin
    if (!rstn || store_cntr_rst_i) begin
      sdbuff_read_cntr <= 0;
    end
    else if(sdbuff_ren_i) begin
      sdbuff_read_cntr <= sdbuff_read_cntr_next;
    end
  end
  assign sdbuff_read_cntr_incr  = store_type_i[2] ? 4 : (1<<cfg_store_data_sew_i[1:0]);
  assign sdbuff_read_cntr_next  = sdbuff_read_cntr + sdbuff_read_cntr_incr;
  //assign sdbuff_read_cntr_iincr = store_type_i[2] ? 4*(VLANE_NUM/2) : ((VLANE_NUM/2)<<cfg_store_data_sew_i[1:0]);
  assign sdbuff_read_cntr_iincr = 4*(VLANE_NUM/2);
  assign sdbuff_read_cntr_nnext = sdbuff_read_cntr + sdbuff_read_cntr_iincr;
  assign sdbuff_read_done_o     = (sdbuff_read_cntr_next >= sdbuff_byte_cnt);
  assign sdbuff_read_rdy_o      = (sbuff_write_cntr > sdbuff_read_cntr);
  assign sibuff_read_rdy_o      = (sbuff_write_cntr > sibuff_read_cntr);
  // NNEXT: Needed to prepare data on time when addressing high performance BRAMs
  // When read cntr passes the treshold of VLANE_NUM/2 this counter will increment setting the next address for
  // first VLANE/2 BRAMS. Thus, the data will be ready in time

  // Counter selects data from one store buffer to forward to axi
  always_ff @(posedge clk) begin
    if (!rstn || store_cntr_rst_i) begin
      sibuff_read_cntr <= 0;
    end
    else if(sibuff_ren_i) begin
      sibuff_read_cntr <= sibuff_read_cntr_next;
    end
  end
  assign sibuff_read_cntr_incr  = (1<<cfg_store_data_sew_i[1:0]);
  assign sibuff_read_cntr_next  = sibuff_read_cntr + sibuff_read_cntr_incr;
  //assign sibuff_read_cntr_iincr = ((VLANE_NUM/2)<<cfg_store_idx_sew_i[1:0]);
  assign sibuff_read_cntr_iincr = 4*(VLANE_NUM/2);
  assign sibuff_read_cntr_nnext = sibuff_read_cntr + sibuff_read_cntr_iincr;
  assign sibuff_read_done_o     = (sibuff_read_cntr_next >= sibuff_byte_cnt);
  assign sibuff_read_cntr_low = sibuff_read_cntr[0+:$clog2(VLANE_NUM)+2];

  // Write counter addresses write ports of all store buffers
  // All data is from vlane is used, so 32-bits * VLANE_NUM
  always_ff @(posedge clk) begin
    if (!rstn || store_cntr_rst_i)begin
      sbuff_write_cntr <= 0;
    end
    else if (sbuff_wen_i) begin
      sbuff_write_cntr <= sbuff_write_cntr_next;
    end
  end
  assign sbuff_write_cntr_next = sbuff_write_cntr + ((VLANE_NUM)*4); // New addressing all data is
  assign sdbuff_write_done_o   = (sbuff_write_cntr_next >= sdbuff_byte_cnt);
  assign sibuff_write_done_o   = (sbuff_write_cntr_next >= sibuff_byte_cnt);
  assign sibuff_not_empty_o    = (sbuff_write_cntr != 0);

  // Output barrel shifter after selecting data
  // Narrower data needs to be barrel shifted to fit the position
  assign sbuff_rdata_rol_amt = store_baseaddr_reg[1:0];
  assign sbuff_rdata_ror_amt = sdbuff_read_cntr_low_d[1][1:0];
  assign sbuff_rdata_total_rol_amt = sbuff_rdata_rol_amt + sbuff_rdata_ror_amt;// TODO: doublecheck if not needed
  always_comb begin
    case (sbuff_rdata_total_rol_amt)
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
  assign wr_tdata_o = sbuff_rdata_rol;

  // Output barrel shifter after selecting pointer
  // Narrower data needs to be barrel shifted and extended to fit the position
  assign sbuff_rptr_rol_amt = (2'b00-sibuff_read_cntr_low_d[1][1:0]);
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
    case(cfg_store_idx_sew_i[1:0])
      2: // FOR SEW = 32
      begin
        sbuff_rptr_ext = sbuff_rptr_rol;
      end
      1: // FOR SEW = 16
      begin
        sbuff_rptr_ext = {{16{sbuff_rptr_rol[15]}}, sbuff_rptr_rol[15:0]};
      end
      default: // FOR SEW = 8
      begin
        sbuff_rptr_ext = {{24{sbuff_rptr_rol[15]}}, sbuff_rptr_rol[7:0]};
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (!rstn) begin
      sdbuff_read_cntr_low_d[1] <= 0;
      sdbuff_read_cntr_low_d[0] <= 0;
    end
    else if (!sdbuff_read_stall_i) begin
      sdbuff_read_cntr_low_d[1] <= sdbuff_read_cntr_low_d[0];
      sdbuff_read_cntr_low_d[0] <= sdbuff_read_cntr_low;
    end
  end
  assign sbuff_rdata_mux = sdbuff_rdata[(sdbuff_read_cntr_low_d[1][2+:$clog2(VLANE_NUM)])];

  always_ff @(posedge clk) begin
    if (!rstn) begin
      sibuff_read_cntr_low_d[1] <= 0;
      sibuff_read_cntr_low_d[0] <= 0;
    end
    else if (!sibuff_read_stall_i) begin
      sibuff_read_cntr_low_d[1] <= sibuff_read_cntr_low_d[0];
      sibuff_read_cntr_low_d[0] <= sibuff_read_cntr_low;
    end
  end
  assign sbuff_rptr_mux = sibuff_rdata[(sibuff_read_cntr_low_d[1][2+:$clog2(VLANE_NUM)])];

  // Selecting current addresses for sdbuff
  // Multiplex selecting data from one of VLANE_NUM buffers to output 
  // READ ADDRESS SELECT
  assign sdbuff_raddr_curr    = sdbuff_read_cntr         >>($clog2(VLANE_NUM)+2); 
  assign sdbuff_raddr_nnext   = sdbuff_read_cntr_nnext   >>($clog2(VLANE_NUM)+2);
  assign sibuff_raddr_curr    = sibuff_read_cntr         >>($clog2(VLANE_NUM)+2); 
  assign sibuff_raddr_nnext   = sibuff_read_cntr_nnext   >>($clog2(VLANE_NUM)+2);
  assign sdbuff_read_cntr_low = sdbuff_read_cntr[0+:$clog2(VLANE_NUM)+2];
  assign sdbuff_waddr         = sbuff_write_cntr        >> ($clog2(VLANE_NUM)+2);
  assign sibuff_waddr         = sbuff_write_cntr        >> ($clog2(VLANE_NUM)+2);

  assign sdbuff_ren  = !sdbuff_read_stall_i;
  assign sdbuff_roen = !sdbuff_read_stall_i;
  assign sdbuff_rocl =  sdbuff_read_flush_i;
  assign sibuff_ren  = !sibuff_read_stall_i;
  assign sibuff_roen = !sibuff_read_stall_i;
  assign sibuff_rocl =  sibuff_read_flush_i;

  // MAIN ITERATOR OVER V_LANE BUFFERS ********************************************************************
  genvar vlane;
  generate 
    for (vlane=0; vlane<VLANE_NUM; vlane++) begin : sbuff_vlane_iterator // MAIN V_LANE ITERATOR

      // Bytes are always in the same place, just reorder them.
      assign sdbuff_wdata[vlane] = {vlane_store_data_i[(vlane*4)%VLANE_NUM+3][((vlane*4)/VLANE_NUM)*8+:8],
                                    vlane_store_data_i[(vlane*4)%VLANE_NUM+2][((vlane*4)/VLANE_NUM)*8+:8],
                                    vlane_store_data_i[(vlane*4)%VLANE_NUM+1][((vlane*4)/VLANE_NUM)*8+:8],
                                    vlane_store_data_i[(vlane*4)%VLANE_NUM  ][((vlane*4)/VLANE_NUM)*8+:8]};

      assign sibuff_wdata[vlane] = {vlane_store_idx_i [(vlane*4)%VLANE_NUM+3][((vlane*4)/VLANE_NUM)*8+:8],
                                    vlane_store_idx_i [(vlane*4)%VLANE_NUM+2][((vlane*4)/VLANE_NUM)*8+:8],
                                    vlane_store_idx_i [(vlane*4)%VLANE_NUM+1][((vlane*4)/VLANE_NUM)*8+:8],
                                    vlane_store_idx_i [(vlane*4)%VLANE_NUM  ][((vlane*4)/VLANE_NUM)*8+:8]};

      // Lower hald
      assign sdbuff_raddr[vlane] = (vlane<(VLANE_NUM/2)) ? sdbuff_raddr_nnext : sdbuff_raddr_curr;
      assign sibuff_raddr[vlane] = (vlane<(VLANE_NUM/2)) ? sibuff_raddr_nnext : sibuff_raddr_curr;

      assign sdbuff_wen = {4{sbuff_wen_i}};
      assign sibuff_wen = {4{sbuff_wen_i}};
      // VFR -> DDR Buffer (STORE)
      // Xilinx Simple Dual Port Single Clock RAM with Byte-write
      sdp_bwe_bram #(
        .NB_COL(4),                           // Specify number of columns (number of bytes)
        .COL_WIDTH(8),                        // Specify column width (byte width, typically 8 or 9)
        .RAM_DEPTH(BUFF_DEPTH),               // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
      ) store_data_buffer (
        .clka     (clk),
        .clkb     (clk),
        .addra    (sdbuff_waddr),
        .addrb    (sdbuff_raddr[vlane]),
        .dina     (sdbuff_wdata[vlane]),
        .wea      (sdbuff_wen),
        .enb      (sdbuff_ren),
        .rstb     (sdbuff_rocl),
        .regceb   (sdbuff_roen),
        .doutb    (sdbuff_rdata[vlane])
      );

      // VFR -> DDR Buffer (STORE)
      // Xilinx Simple Dual Port Single Clock RAM with Byte-write
      sdp_bwe_bram #(
        .NB_COL(4),                           // Specify number of columns (number of bytes)
        .COL_WIDTH(8),                        // Specify column width (byte width, typically 8 or 9)
        .RAM_DEPTH(BUFF_DEPTH),               // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
      ) store_index_buffer (
        .clka     (clk),
        .clkb     (clk),
        .addra    (sibuff_waddr),
        .addrb    (sibuff_raddr[vlane]),
        .dina     (sibuff_wdata[vlane]),
        .wea      (sibuff_wen),
        .enb      (sibuff_ren),
        .rstb     (sibuff_rocl),
        .regceb   (sibuff_roen),
        .doutb    (sibuff_rdata[vlane])
      );

    end
  endgenerate


  // **************************************** STORE BUFFER OUTPUT LOGIC *****************************************************************
  // Changing axi strobe signals for narrower data
  // Storbing necessasry to write narrower data to 32-bit axi bus
  always_ff @(posedge clk) begin
    if (!rstn) begin
      sbuff_strobe_reg <= 4'b0000;
    end
    case(cfg_store_data_sew_i[1:0])
      2: begin      // FOR SEW = 32
        sbuff_strobe_reg <= 4'b1111;
      end
      1: begin      // FOR SEW = 16
      if(store_cfg_update_i)
        sbuff_strobe_reg <= 4'b0011;
      end
      default: begin // FOR SEW = 8
      if(store_cfg_update_i)
        sbuff_strobe_reg <= 4'b0001;
      end
    endcase
  end
  // Rotate output strobe
  // Rotating strobe signal to fit the position of narrower data in 32-bit word
  always_comb begin
    case(sbuff_strobe_rol_amt)
    3: 
      sbuff_strobe_curr = {sbuff_strobe_reg[0],  sbuff_strobe_reg[3:1]};
    2: 
      sbuff_strobe_curr = {sbuff_strobe_reg[1:0],sbuff_strobe_reg[3:2]};
    1: 
      sbuff_strobe_curr = {sbuff_strobe_reg[2:0],sbuff_strobe_reg[3]};
    default: 
      sbuff_strobe_curr = sbuff_strobe_reg;
    endcase
  end
  assign wr_tstrb_msk_o = sbuff_strobe_curr;

  assign sbuff_strobe_rol_amt = store_baseaddr_reg[1:0];// - sdbuff_read_cntr_low_d[1][1:0];TODO doublecheck if needed
  // ***************************************************************************************************************************************
  // ***********************************************       LOAD BUFFER LOGIC        ********************************************************
  // ***************************************************************************************************************************************
  
  // For indexed and strided operations, we need a counter saving current baseaddr
  always_ff @(posedge clk) begin
    if (!rstn) begin
      load_baseaddr_reg <= 0;
      load_stride_reg   <= 0;
    end
    else if(load_baseaddr_set_i) begin
      load_baseaddr_reg <= load_baseaddr_i;
      load_stride_reg   <= load_stride_i;
    end
    else if(load_baseaddr_update_i)begin
      case(load_type_i[1:0])
      1:      // indexed
        load_baseaddr_reg <= load_baseaddr_reg + lbuff_rptr_ext;// - (1<<cfg_store_data_sew_i[0]); // TODO double-check this (-1)
      2:      // strided
        load_baseaddr_reg <= load_baseaddr_reg + load_stride_reg;// - (1<<cfg_store_data_sew_i[0]); // TODO double-check this (-2)
      default:// unit_stride
        load_baseaddr_reg <= load_baseaddr_i;
      endcase
    end
  end
  assign single_word_load = !load_type_i[2]; // Not unit-stride => an y of other two is sigle word per xfer

  // AXI INTERFACE
  assign ctrl_raddr_offset_o = {load_baseaddr_reg[31:2],2'b00}; // align per 32-bit address space
  assign ctrl_rxfer_size_o   = (load_type_i[1:0]==0) ? (ldbuff_byte_cnt) : 4; 

  // Number of expected loads
  always_ff @(posedge clk) begin
    if (!rstn) begin
      lbuff_word_cnt <= 0;
    end
    else if(load_cfg_update_i) begin
      lbuff_word_cnt <= cfg_vl_i;
    end
  end
  assign ldbuff_byte_cnt     = lbuff_word_cnt << cfg_load_data_sew_i[1:0];
  assign libuff_byte_cnt     = lbuff_word_cnt << cfg_load_idx_sew_i[1:0];

  // Counter for number of data written to ldbuff
  always_ff @(posedge clk) begin
    if (!rstn || load_cntr_rst_i)begin
      ldbuff_write_cntr <= 0;
    end
    else if (ldbuff_wen_i) begin
      ldbuff_write_cntr <= ldbuff_write_cntr_next;
    end
  end
  // COUNTING WORDS
  assign ldbuff_write_cntr_next = ldbuff_write_cntr + ldbuff_write_cntr_incr;
  // If unit, then data comes in 4B words - all valid, if stided/indexed increment by SEW
  assign ldbuff_write_cntr_incr = (load_type_i[2])? 4 : 1<<cfg_load_data_sew_i[1:0];
  assign ldbuff_write_done_o = (ldbuff_write_cntr_next >= ldbuff_byte_cnt);

  // Counter for number of data read from ldbuff
  always_ff @(posedge clk) begin
    if (!rstn || load_cntr_rst_i)
      ldbuff_read_cntr <= 0;
    else if (ldbuff_ren_i) begin
      ldbuff_read_cntr <= ldbuff_read_cntr_next;
    end
  end
  assign ldbuff_read_cntr_next = ldbuff_read_cntr + ((VLANE_NUM)<<2);
  assign ldbuff_read_done_o = (ldbuff_read_cntr_next >= ldbuff_byte_cnt);

  // Write counter addresses write ports of index load buffers
  // Each load buffer is then selected with libuff_wen_i
  always_ff @(posedge clk) begin
    if (!rstn || load_cntr_rst_i)begin
      libuff_write_cntr <= 0;
    end
    else if (libuff_wen_i) begin
      libuff_write_cntr <= libuff_write_cntr_next;
    end
  end
  assign libuff_write_cntr_next = libuff_write_cntr + (VLANE_NUM)*4;
  assign libuff_write_done_o    = (libuff_write_cntr_next >= libuff_byte_cnt);
  assign libuff_not_empty_o     = (libuff_write_cntr != 0);
  assign libuff_read_rdy_o      = (libuff_write_cntr > libuff_read_cntr);
  
  // Counter selects data from one load buffer to forward to axi
  always_ff @(posedge clk) begin
    if (!rstn || load_cntr_rst_i) begin
      libuff_read_cntr <= 0;
    end
    else if(libuff_ren_i) begin
      libuff_read_cntr <= libuff_read_cntr_next;
    end
  end
  assign libuff_read_cntr_next  = libuff_read_cntr + libuff_read_cntr_incr;
  assign libuff_read_cntr_incr  = (1<<cfg_load_idx_sew_i[1:0]);
  assign libuff_read_cntr_nnext = libuff_read_cntr + libuff_read_cntr_iincr;
  assign libuff_read_cntr_low   = libuff_read_cntr[0+:$clog2(VLANE_NUM)+2];
  //assign libuff_read_cntr_iincr = ((VLANE_NUM/2)<<cfg_load_idx_sew_i[1:0]);
  assign libuff_read_cntr_iincr = 4*(VLANE_NUM/2);
  assign libuff_read_done_o     = (libuff_read_cntr >= lbuff_word_cnt);

  always_ff @(posedge clk) begin
    if (!rstn) begin
      libuff_read_cntr_low_d[1] <= 0;
      libuff_read_cntr_low_d[0] <= 0;
    end
    else if (!libuff_read_stall_i) begin
      libuff_read_cntr_low_d[1] <= libuff_read_cntr_low_d[0];
      libuff_read_cntr_low_d[0] <= libuff_read_cntr_low;
    end
  end
  assign lbuff_rptr_mux = libuff_rdata[(libuff_read_cntr_low_d[1][2+:$clog2(VLANE_NUM)])];

  // Data coming in from axi full needs to be rotated right so data word is at LSB position
  // Input barrel shifter
  // Narrower data needs to be barrel shifted to fit the position
  assign lbuff_wdata_rol_amt = ldbuff_write_cntr[1:0];
  assign lbuff_wdata_ror_amt = load_baseaddr_reg[1:0];
  assign lbuff_wdata_total_rol_amt = lbuff_wdata_rol_amt - lbuff_wdata_ror_amt;
  always_comb begin
    case (lbuff_wdata_total_rol_amt)
      3:
        lbuff_wdata_rol = {rd_tdata_i[7:0],rd_tdata_i[31:8]};
      2:
        lbuff_wdata_rol = {rd_tdata_i[15:0],rd_tdata_i[31:16]};
      1:
        lbuff_wdata_rol = {rd_tdata_i[23:0],rd_tdata_i[31:24]};
      default:
        lbuff_wdata_rol = rd_tdata_i;
    endcase
  end
  
  // Output barrel shifter after selecting pointer
  // Narrower data needs to be barrel shifted and extended to fit the position
  assign lbuff_rptr_rol_amt = (2'b00 - libuff_read_cntr_low_d[1][1:0]);
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

  // sign-extend the pointer
  always_comb begin
    case(cfg_load_idx_sew_i[1:0])
      2: // FOR SEW = 32
        lbuff_rptr_ext = lbuff_rptr_rol;
      1: // FOR SEW = 16
        lbuff_rptr_ext = {{16{lbuff_rptr_rol[15]}}, lbuff_rptr_rol[15:0]};
      default: // FOR SEW = 8
        lbuff_rptr_ext = {{24{lbuff_rptr_rol[15]}}, lbuff_rptr_rol[7:0]};
    endcase
  end


  // Changing write enable signals for narrow writes [load index buffer]
  // Narrower data is packed into 32-bit buffer
  always_ff @(posedge clk) begin
    if (!rstn) begin
      libuff_wen <= 0;
    end
    case(cfg_load_idx_sew_i[1:0])
      2: begin      // FOR SEW = 32
        libuff_wen <= {(VLANE_NUM*4){1'b1}};
      end
      1: begin      // FOR SEW = 16
        if(load_cfg_update_i)
          for(int i=0; i<(VLANE_NUM*4); i++)
            libuff_wen[i/4][i%4] <= (i<VLANE_NUM*2) ? 1'b1 : 1'b0;
        else if (libuff_wen_i)
          libuff_wen <= ((libuff_wen<<(VLANE_NUM*2)) | (libuff_wen>>(VLANE_NUM*4-VLANE_NUM*2)));
      end
      default: begin // FOR SEW = 8
        if(load_cfg_update_i)
          for(int i=0; i<(VLANE_NUM*4); i++)
            libuff_wen[i/4][i%4] <= (i<VLANE_NUM*2) ? 1'b1 : 1'b0;
        else if (libuff_wen_i)
          libuff_wen <= ((libuff_wen<<(VLANE_NUM)) | (libuff_wen>>(VLANE_NUM*4-VLANE_NUM)));
      end
    endcase
  end


  // Changing write enable signals for narrow writes [load data buffer]
  // Narrower data is packed into 32-bit buffer
  always_ff @(posedge clk) begin
    if (!rstn || load_cfg_update_i) begin
      for(int ln=0; ln<VLANE_NUM; ln++)
        if(ln==0)
          ldbuff_wen_reg[ln] <= 4'b1111; // word by word
        else
          ldbuff_wen_reg[ln] <= 4'b0000; // word by word
    end
    else if(ldbuff_wen_i && ldbuff_wen_narrow_mask[3]) begin // ROTATE
      for(int ln=0; ln<(VLANE_NUM); ln++)
        ldbuff_wen_reg[(ln+1)%VLANE_NUM] <= ldbuff_wen_reg[ln];
    end
  end

  always_ff @(posedge clk) begin
    if (!rstn || load_cfg_update_i) begin
      if(single_word_load)
        case(cfg_load_data_sew_i[1:0])
          2:      ldbuff_wen_narrow_mask <= 4'b1111;
          1:      ldbuff_wen_narrow_mask <= 4'b0011;
          default:ldbuff_wen_narrow_mask <= 4'b0001;
        endcase
      else
        ldbuff_wen_narrow_mask <= 4'b1111;
    end
    else if(ldbuff_wen_i) begin // ROTATE
        case(cfg_load_data_sew_i[1:0])
          2:      ldbuff_wen_narrow_mask <= ldbuff_wen_narrow_mask;
          1:      ldbuff_wen_narrow_mask <= ldbuff_wen_narrow_mask<<2 | ldbuff_wen_narrow_mask>>2;
          default:ldbuff_wen_narrow_mask <= ldbuff_wen_narrow_mask<<1 | ldbuff_wen_narrow_mask>>3;
        endcase
    end
  end

  // When last needs to write less bytes than 4
  always_comb begin
    ldbuff_wen_last_mask = {4{ldbuff_wen_i}};
    if(ldbuff_write_done_o && (ldbuff_byte_cnt[1:0]!=2'b00))begin
      for(int i=0; i<4; i++)begin
        if(i<ldbuff_byte_cnt[1:0])
          ldbuff_wen_last_mask[i] = ldbuff_wen_i;
        else
          ldbuff_wen_last_mask[i] = 1'b0;
      end
    end
  end

  assign ldbuff_waddr        = ldbuff_write_cntr        >>($clog2(VLANE_NUM)+2);
  assign ldbuff_raddr        = ldbuff_read_cntr         >>($clog2(VLANE_NUM)+2);

  assign libuff_waddr        = libuff_write_cntr        >>($clog2(VLANE_NUM)+2);
  assign libuff_raddr_curr   = libuff_read_cntr         >>($clog2(VLANE_NUM)+2); 
  assign libuff_raddr_nnext  = libuff_read_cntr_nnext   >>($clog2(VLANE_NUM)+2);

  assign ldbuff_ren  = !ldbuff_read_stall_i;
  assign ldbuff_roen = !ldbuff_read_stall_i;
  assign ldbuff_rocl = ldbuff_read_flush_i;

  assign libuff_ren  = !libuff_read_stall_i;
  assign libuff_roen = !libuff_read_stall_i;
  assign libuff_rocl = libuff_read_flush_i;

  // MAIN GENERATE OVER VECTOR LANES
  generate 
  for (vlane=0; vlane<VLANE_NUM; vlane++) begin: load_vlane_iterator // MAIN V_LANE ITERATOR

    // Read adress
    assign libuff_raddr[vlane] = (vlane<(VLANE_NUM/2)) ? libuff_raddr_nnext : libuff_raddr_curr;

    // New addressing, register byte positions are fixed, (not actually muxed)
   assign lbuff_wdata_mux[vlane] = {lbuff_wdata_rol[(vlane%4)*8+:8],
                                    lbuff_wdata_rol[(vlane%4)*8+:8],
                                    lbuff_wdata_rol[(vlane%4)*8+:8],
                                    lbuff_wdata_rol[(vlane%4)*8+:8]};
   assign ldbuff_wen_mux[vlane]  = {ldbuff_wen_masked[(3*VLANE_NUM/4)+vlane/4][vlane%4],
                                    ldbuff_wen_masked[(2*VLANE_NUM/4)+vlane/4][vlane%4],
                                    ldbuff_wen_masked[(1*VLANE_NUM/4)+vlane/4][vlane%4],
                                    ldbuff_wen_masked[(0*VLANE_NUM/4)+vlane/4][vlane%4]};

    assign ldbuff_wen_masked[vlane] = ldbuff_wen_reg[vlane] & ldbuff_wen_narrow_mask & ldbuff_wen_last_mask;
    // Priority write enable - when writing first byte in set, update all valid flags of the set (set being : number of lanes * four bytes)
    assign ldbuff_pr_wen[vlane] = (ldbuff_wen_reg[0][0] && ldbuff_wen_narrow_mask[0])? 4'b1111 : ldbuff_wen_mux[vlane];
    // On 9th bit of every word write valid flag
    assign ldbuff_wdata[vlane] = {ldbuff_wen_mux[vlane][3], lbuff_wdata_mux[vlane][31:24],
                                  ldbuff_wen_mux[vlane][2], lbuff_wdata_mux[vlane][23:16],
                                  ldbuff_wen_mux[vlane][1], lbuff_wdata_mux[vlane][15: 8],
                                  ldbuff_wen_mux[vlane][0], lbuff_wdata_mux[vlane][ 7: 0]};

      // Multiplex narrower data in so writes are in the correct position for byte-write enable
      always_comb begin
        case(cfg_store_data_sew_i[1:0])
          2: begin       // FOR SEW = 32
            libuff_wdata[vlane] = vlane_load_idx_i [vlane];
          end
          1: begin       // FOR SEW = 16
            libuff_wdata[vlane] = {vlane_load_idx_i [(vlane*2)%VLANE_NUM+1][15:0], vlane_load_idx_i [(vlane*2)%VLANE_NUM][15:0]};
          end
          default: begin // FOR SEW = 8
            libuff_wdata[vlane] = {vlane_load_idx_i [(vlane*4)%VLANE_NUM+3][7:0], vlane_load_idx_i [(vlane*4)%VLANE_NUM+2][7:0],
                                   vlane_load_idx_i [(vlane*4)%VLANE_NUM+1][7:0], vlane_load_idx_i [(vlane*4)%VLANE_NUM  ][7:0]};
          end
        endcase
      end


      assign vlane_load_data_o[vlane] = {ldbuff_rdata[vlane][34:27],ldbuff_rdata[vlane][25:18],ldbuff_rdata[vlane][16:9],ldbuff_rdata[vlane][7:0]};

      assign vlane_load_bwe_o[vlane] = {ldbuff_rdata[vlane][35],ldbuff_rdata[vlane][26],ldbuff_rdata[vlane][17],ldbuff_rdata[vlane][8]};

      // DDR Buffer -> VRF (LOAD) | Data Buffer
      // Xilinx Simple Dual Port Single Clock RAM with Byte-write
      sdp_bwe_bram #(
        .NB_COL(4),                           // Specify number of columns (number of bytes)
        .COL_WIDTH(9),                        // Specify column width (byte width, typically 8 or 9)
        .RAM_DEPTH(BUFF_DEPTH),               // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
      ) load_data_buffer (
        .clka     (clk),
        .clkb     (clk),
        .addra    (ldbuff_waddr),
        .addrb    (ldbuff_raddr),
        .dina     (ldbuff_wdata[vlane]),
        .wea      (ldbuff_pr_wen[vlane]),
        .enb      (ldbuff_ren),
        .rstb     (ldbuff_rocl),
        .regceb   (ldbuff_roen),
        .doutb    (ldbuff_rdata[vlane])
      );


      // DDR Buffer -> VRF (LOAD) | Index Buffer
      // Xilinx Simple Dual Port Single Clock RAM with Byte-write
      sdp_bwe_bram #(
        .NB_COL(4),                           // Specify number of columns (number of bytes)
        .COL_WIDTH(8),                        // Specify column width (byte width, typically 8 or 9)
        .RAM_DEPTH(BUFF_DEPTH),               // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
      ) load_index_buffer (
        .clka     (clk),
        .clkb     (clk),
        .addra    (libuff_waddr),
        .addrb    (libuff_raddr[vlane]),
        .dina     (libuff_wdata[vlane]),
        .wea      ({4{libuff_wen_i}} & libuff_wen[vlane]),
        .enb      (libuff_ren),
        .rstb     (libuff_rocl),
        .regceb   (libuff_roen),
        .doutb    (libuff_rdata[vlane])
      );


    end
  endgenerate


 endmodule : buff_array
`default_nettype wire
