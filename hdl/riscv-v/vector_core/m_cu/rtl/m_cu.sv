// Coded by Djordje Miseljic | e-mail: djordjemiseljic@uns.ac.rs //////////////////////////////////////////////////////////////////////////////// // default_nettype of none prevents implicit logic declaration.
////////////////////////////////////////////////////////////////////////////////
// default_nettype of none prevents implicit logic declaration.
`default_nettype wire
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
  input  logic                                   clk                     ,
  input  logic                                   rstn                    ,
  // SHEDULER <=> M_CU CONFIG [general]
  input  logic [ 2:0]                            mcu_sew_i               ,
  input  logic [ 2:0]                            mcu_lmul_i              ,
  input  logic [31:0]                            mcu_base_addr_i         ,
  input  logic [31:0]                            mcu_stride_i            ,
  input  logic [ 2:0]                            mcu_data_width_i        ,
  input  logic                                   mcu_idx_ld_st_i         ,
  input  logic                                   mcu_strided_ld_st_i     ,
  input  logic                                   mcu_unit_ld_st_i        ,
  // SHEDULER <=> M_CU CONFIG IF [stores]
  output logic 	                                 mcu_st_rdy_o            ,
  input  logic                                   mcu_st_vld_i            ,
  // SHEDULER <=> M_CU CONFIG IF [loads]
  output logic 	                                 mcu_ld_rdy_o            ,
  input  logic                                   mcu_ld_vld_i            ,
  // MCU => BUFF_ARRAY CONFIG IF [general]
  input  logic [$clog2(VLEN)-1:0]                cfg_vlenb_i             ,
  // MCU => BUFF_ARRAY CONFIG IF [stores]
  output logic [2:0]                             cfg_store_data_lmul_o   ,
  output logic [2:0]                             cfg_store_data_sew_o    ,
  output logic [2:0]                             cfg_store_idx_sew_o     ,
  output logic [2:0]                             cfg_store_idx_lmul_o    ,
  // MCU => BUFF_ARRAY CONFIG IF [loads]
  output logic [2:0]                             cfg_load_data_lmul_o    ,
  output logic [2:0]                             cfg_load_data_sew_o     ,
  output logic [2:0]                             cfg_load_idx_sew_o      ,
  output logic [2:0]                             cfg_load_idx_lmul_o     ,
  // MCU <=> BUFF_ARRAY CONTROL IF [stores]
  output logic                                   store_cfg_update_o      ,
  output logic                                   store_cntr_rst_o        ,
  output logic [2:0]                             store_type_o            ,
  output logic [31:0]                            store_stride_o          ,
  output logic [31:0]                            store_baseaddr_o        ,
  output logic                                   store_baseaddr_update_o ,
  output logic                                   store_baseaddr_set_o  ,
  output logic                                   sbuff_read_stall_o      ,
  output logic                                   sbuff_read_flush_o      ,
  output logic                                   sbuff_wen_o             ,
  output logic                                   sbuff_ren_o             ,
  input  logic                                   sbuff_not_empty_i       ,
  input  logic                                   sbuff_write_done_i      ,
  input  logic                                   sbuff_read_done_i       ,
  // MCU <=> BUFF_ARRAY CONTROL IF [loads]
  output logic                                   load_cfg_update_o       ,
  output logic                                   load_cntr_rst_o         ,
  output logic [2:0]                             load_type_o             ,
  output logic [31:0]                            load_stride_o           ,
  output logic [31:0]                            load_baseaddr_o         ,
  output logic                                   load_baseaddr_set_o   ,
  output logic                                   load_baseaddr_update_o  ,
  output logic                                   libuff_read_stall_o     ,
  output logic                                   libuff_read_flush_o     ,
  output logic                                   libuff_wen_o            ,
  output logic                                   libuff_ren_o            ,
  input  logic                                   libuff_not_empty_i      ,
  input  logic                                   libuff_write_done_i     ,
  input  logic                                   libuff_read_done_i      ,
  output logic                                   ldbuff_read_stall_o     ,
  output logic                                   ldbuff_read_flush_o     ,
  output logic                                   ldbuff_wen_o            ,
  output logic                                   ldbuff_ren_o            ,
  input  logic                                   ldbuff_not_empty_i      ,
  input  logic                                   ldbuff_write_done_i     ,
  input  logic                                   ldbuff_read_done_i      ,
  // MCU <=> V_LANE IF
  input  logic                                   vlane_store_dvalid_i    , 
  output logic                                   vlane_store_rdy_o       , 
  input  logic                                   vlane_load_rdy_i        ,
  input  logic                                   vlane_load_ivalid_i     ,
  output logic                                   vlane_load_last_o       ,
  // MCU <=> AXIM CONTROL IF [read channel]
  output logic                                   ctrl_rstart_o           ,
  input  logic                                   ctrl_rdone_i            ,
  input  logic                                   rd_tvalid_i             ,
  output logic                                   rd_tready_o             ,
  input  logic                                   rd_tlast_i              ,
  // MCU <=> AXIM CONTROL IF [write channel]
  output logic                                   ctrl_wstart_o           ,
  input  logic                                   ctrl_wdone_i            ,
  output logic                                   wr_tvalid_o             ,
  input  logic                                   wr_tready_i             
);

  ///////////////////////////////////////////////////////////////////////////////
  // Local Parameters
  ///////////////////////////////////////////////////////////////////////////////


  ///////////////////////////////////////////////////////////////////////////////
  // Variables
  ///////////////////////////////////////////////////////////////////////////////

  //TODO: CHECK IF SYNTHESIZABLE
  const logic [0:127] [3:0] emul_calc = '{
    4'b0000, 4'b0111, 4'b0110, 4'b1000,
    4'b0001, 4'b0000, 4'b0111, 4'b1000,
    4'b0010, 4'b0001, 4'b0000, 4'b1000,
    4'b0011, 4'b0010, 4'b0001, 4'b1000,
    4'b1000, 4'b1000, 4'b1000, 4'b1000,
    4'b0101, 4'b1000, 4'b1000, 4'b1000,
    4'b0110, 4'b0101, 4'b1000, 4'b1000,
    4'b0111, 4'b0110, 4'b0101, 4'b1000,
    4'b0001, 4'b0000, 4'b0111, 4'b1000,
    4'b0010, 4'b0001, 4'b0000, 4'b1000,
    4'b0011, 4'b0010, 4'b0001, 4'b1000,
    4'b1000, 4'b0011, 4'b0010, 4'b1000,
    4'b1000, 4'b1000, 4'b1000, 4'b1000,
    4'b0110, 4'b0101, 4'b1000, 4'b1000,
    4'b0111, 4'b0110, 4'b0101, 4'b1000,
    4'b0000, 4'b0111, 4'b0110, 4'b1000,
    4'b0010, 4'b0001, 4'b0000, 4'b1000,
    4'b0011, 4'b0010, 4'b0001, 4'b1000,
    4'b1000, 4'b0011, 4'b0010, 4'b1000,
    4'b1000, 4'b1000, 4'b0101, 4'b1000,
    4'b1000, 4'b1000, 4'b1000, 4'b1000,
    4'b0111, 4'b0110, 4'b0101, 4'b1000,
    4'b0000, 4'b0111, 4'b0110, 4'b1000,
    4'b0001, 4'b0000, 4'b0111, 4'b1000,
    4'b1000, 4'b1000, 4'b1000, 4'b1000,
    4'b1000, 4'b1000, 4'b1000, 4'b1000,
    4'b1000, 4'b1000, 4'b1000, 4'b1000,
    4'b1000, 4'b1000, 4'b1000, 4'b1000,
    4'b1000, 4'b1000, 4'b1000, 4'b1000,
    4'b1000, 4'b1000, 4'b1000, 4'b1000,
    4'b1000, 4'b1000, 4'b1000, 4'b1000,
    4'b1000, 4'b1000, 4'b1000, 4'b1000};

  logic [6:0] emul_addr;
  logic       emul_valid;
  logic [2:0] emul;

  logic [2:0] store_data_lmul_reg, store_data_lmul_next;
  logic [2:0] store_idx_lmul_reg,  store_idx_lmul_next;
  logic [2:0] store_data_sew_reg,  store_data_sew_next;
  logic [2:0] store_idx_sew_reg,   store_idx_sew_next;
  logic [2:0] load_data_lmul_reg,  load_data_lmul_next;
  logic [2:0] load_idx_lmul_reg,   load_idx_lmul_next;
  logic [2:0] load_data_sew_reg,   load_data_sew_next;
  logic [2:0] load_idx_sew_reg,    load_idx_sew_next;
  logic       mcu_st_vld_reg;
  logic       mcu_ld_vld_reg;
  logic       wr_tvalid;
  logic [1:0] wr_tvalid_d;
  logic       ldbuff_rvalid;
  logic       libuff_rvalid;
  logic [1:0] ldbuff_rvalid_d;
  logic [1:0] libuff_rvalid_d;
  logic       sbuff_read_invalidate;
  // Store Signals
  logic       save_store_type;
  logic [2:0] store_type_reg,store_type_next;
  typedef enum {store_idle, unit_store_prep, unit_store_tx, strided_store_prep, strided_store_tx_prep, strided_store_tx, indexed_store_prep, indexed_store_tx_init, indexed_store_tx_prep, indexed_store_tx} store_fsm;
  store_fsm store_state_reg, store_state_next;
  // LOAD Signals
  typedef enum {load_idle, unit_load_prep, unit_load_tx, strided_load_prep, strided_load_tx_prep, strided_load_tx, indexed_load_prep, indexed_load_tx_init, indexed_load_tx_prep, indexed_load_tx} load_fsm;
  load_fsm load_state_reg, load_state_next;
  logic       save_load_type;
  logic [2:0] load_type_reg,load_type_next;

  ///////////////////////////////////////////////////////////////////////////////
  // Begin RTL
  ///////////////////////////////////////////////////////////////////////////////

  assign emul_addr = {mcu_data_width_i[1:0], mcu_lmul_i[2:0], mcu_sew_i[1:0]};
  assign emul = emul_calc[emul_addr][2:0];
  assign emul_valid = emul_calc[emul_addr][3];

  // STORE FSM M_CU STATE
  always_ff @(posedge clk, negedge rstn)
  begin
    if(!rstn) begin
      store_state_reg <= store_idle;
      load_state_reg  <= load_idle;
    end
    else begin
      store_state_reg <= store_state_next;
      load_state_reg  <= load_state_next;
    end
  end

  always_ff @(posedge clk, negedge rstn)
  begin
    if(!rstn)begin
      mcu_st_vld_reg      <= 0;
      mcu_ld_vld_reg      <= 0;
    end
    else begin
      mcu_st_vld_reg      <= mcu_st_vld_i;
      mcu_ld_vld_reg      <= mcu_ld_vld_i;
    end
  end

  always_ff @(posedge clk, negedge rstn)
  begin
    if(!rstn)
      wr_tvalid_d      <= 0;
    else if (!sbuff_read_stall_o)
      wr_tvalid_d      <= {wr_tvalid_d[0], wr_tvalid};
  end

  always_ff @(posedge clk, negedge rstn)
  begin
    if(!rstn)
      ldbuff_rvalid_d      <= 0;
    else if (!ldbuff_read_stall_o)
      ldbuff_rvalid_d      <= {ldbuff_rvalid_d[0], ldbuff_rvalid};
  end
  always_ff @(posedge clk, negedge rstn)
  begin
    if(!rstn)
      libuff_rvalid_d      <= 0;
    else if (!libuff_read_stall_o)
      libuff_rvalid_d      <= {libuff_rvalid_d[0], libuff_rvalid};
  end

  assign wr_tvalid_o = !sbuff_read_invalidate ? wr_tvalid_d[1] : 1'b0;

  // save store configuration
  always_ff @(posedge clk, negedge rstn)
  begin
    if(!rstn)begin
      store_type_reg            <= 0;
      store_data_sew_reg        <= 0;
      store_data_lmul_reg       <= 0;
      store_idx_sew_reg         <= 0;
      store_idx_lmul_reg        <= 0;
    end
    else if (save_store_type) begin
      store_type_reg            <= {mcu_unit_ld_st_i,mcu_strided_ld_st_i,mcu_idx_ld_st_i};
      store_data_lmul_reg       <= store_data_lmul_next;
      store_data_sew_reg        <= store_data_sew_next;
      store_idx_lmul_reg        <= store_idx_lmul_next;
      store_idx_sew_reg         <= store_idx_sew_next;
    end
  end
  assign store_type_next = {mcu_unit_ld_st_i,mcu_strided_ld_st_i,mcu_idx_ld_st_i};

  // save load configuration
  always_ff @(posedge clk, negedge rstn)
  begin
    if(!rstn)begin
      load_type_reg            <= 0;
      load_data_sew_reg        <= 0;
      load_data_lmul_reg       <= 0;
      load_idx_sew_reg         <= 0;
      load_idx_lmul_reg        <= 0;
    end
    else if (save_load_type) begin
      load_type_reg            <= load_type_next;
      load_data_lmul_reg       <= load_data_lmul_next;
      load_data_sew_reg        <= load_data_sew_next;
      load_idx_lmul_reg        <= load_idx_lmul_next;
      load_idx_sew_reg         <= load_idx_sew_next;
    end
  end
  assign load_type_next = {mcu_unit_ld_st_i,mcu_strided_ld_st_i,mcu_idx_ld_st_i};

  assign store_type_o           = store_type_next;
  assign cfg_store_data_lmul_o  = store_data_lmul_next;
  assign cfg_store_data_sew_o   = store_data_sew_next;
  assign cfg_store_idx_lmul_o   = store_idx_lmul_next;
  assign cfg_store_idx_sew_o    = store_idx_sew_next;

  // MAIN STORE FSM M_CU NEXTSTATE & CONTROL
  always_comb begin
    // default values for output signals
    store_state_next        = store_state_reg;
    store_data_lmul_next    = store_data_lmul_reg;
    store_data_sew_next     = store_data_sew_reg;
    store_idx_lmul_next     = store_idx_lmul_reg;
    store_idx_sew_next      = store_idx_sew_reg;
    store_baseaddr_o        = mcu_base_addr_i;
    vlane_store_rdy_o       = 1'b0;
    store_cfg_update_o      = 1'b0;
    mcu_st_rdy_o            = 1'b0;
    store_baseaddr_update_o = 1'b0;
    store_baseaddr_set_o    = 1'b0;
    save_store_type         = 1'b0;
    sbuff_read_stall_o      = 1'b0;
    sbuff_read_invalidate   = 1'b0;
    sbuff_read_flush_o      = 1'b0;
    sbuff_wen_o             = 1'b0;
    sbuff_ren_o             = 1'b0;
    store_cntr_rst_o        = 1'b0;
    ctrl_wstart_o           = 1'b0;
    wr_tvalid               = 1'b0;

    case (store_state_reg)
      // IDLE
      store_idle: begin
        mcu_st_rdy_o = 1'b1;
        if(mcu_st_vld_reg)
        begin
          save_store_type       = 1'b1;
          store_cfg_update_o    = 1'b1;
          store_cntr_rst_o      = 1'b1;
          store_baseaddr_set_o  = 1'b1;
          wr_tvalid             = 1'b1;
          if(mcu_unit_ld_st_i)begin
            //unit
            store_state_next        = unit_store_prep;
            store_data_sew_next     = mcu_data_width_i;
            store_data_lmul_next    = emul;
            store_idx_sew_next      = mcu_data_width_i;  // Not used in this context
            store_idx_lmul_next     = emul;              // Not used in this context
          end
          else if (mcu_strided_ld_st_i)begin
            //strided
            store_state_next        = strided_store_prep;
            store_data_sew_next     = mcu_data_width_i;
            store_data_lmul_next    = emul;
            store_idx_sew_next      = mcu_data_width_i;  // Not used in this context
            store_idx_lmul_next     = emul;              // Not used in this context
          end
          else if (mcu_idx_ld_st_i)begin
            //indexed
            store_state_next        = indexed_store_prep;
            store_data_sew_next     = mcu_sew_i;
            store_data_lmul_next    = mcu_lmul_i;
            store_idx_sew_next      = mcu_data_width_i;
            store_idx_lmul_next     = emul;
          end
        end
      end

      // UNIT STORE STATES
      // UNIT_PREP
      unit_store_prep: begin
        sbuff_wen_o = vlane_store_dvalid_i;
        vlane_store_rdy_o = 1'b1;
        if(sbuff_write_done_i) begin
          store_state_next = unit_store_tx;
          sbuff_wen_o           = 1'b0;
          ctrl_wstart_o         = 1'b1;
          wr_tvalid             = 1'b1;
          sbuff_ren_o           = 1'b1;
        end
      end
      // UNIT_STORE
      unit_store_tx: begin
        if(sbuff_read_done_i) begin
          sbuff_ren_o           = 1'b0;
          if(ctrl_wdone_i)
            store_state_next = store_idle;
        end
        if(wr_tready_i) begin
          wr_tvalid             = 1'b1;
          sbuff_ren_o           = 1'b1;
        end
        else begin
          sbuff_read_stall_o    = 1'b1;
          sbuff_read_invalidate = 1'b1;
          wr_tvalid             = 1'b0;
          sbuff_ren_o           = 1'b0;
        end
      end

      // STRIDED STORE STATES
      // STRIDED_STORE_PREP
      strided_store_prep: begin
        vlane_store_rdy_o = 1'b1;
        sbuff_wen_o = vlane_store_dvalid_i;
        if(sbuff_write_done_i) begin
          store_state_next      = strided_store_tx_prep;
          sbuff_wen_o           = 1'b0;
          store_baseaddr_set_o  = 1'b1;
          sbuff_ren_o           = 1'b1;
          wr_tvalid             = 1'b1;
        end
      end
      // STRIDED_TX_PREP
      strided_store_tx_prep: begin
        if (sbuff_read_done_i)begin
          sbuff_ren_o      = 1'b0;
          wr_tvalid        = 1'b0;
        end
        else begin
          sbuff_ren_o      = 1'b1;
          wr_tvalid        = 1'b1;
        end
        ctrl_wstart_o      = 1'b1;
        sbuff_read_invalidate = 1'b1;
        store_state_next = strided_store_tx;
      end
      // STRIDED_TX
      strided_store_tx: begin
        sbuff_read_stall_o        = 1'b1;
        sbuff_ren_o               = 1'b0;
        if (!wr_tready_i)
          sbuff_read_invalidate   = 1'b1;
        if (ctrl_wdone_i) begin
          store_baseaddr_update_o = 1'b1;
          if(sbuff_read_done_i && (wr_tvalid_d[1:0]==0))
            store_state_next = store_idle;
          else
            store_state_next = strided_store_tx_prep;
        end
      end

      // INDEXED STORE STATES
      // INDEXED_STORE_PREP
      indexed_store_prep: begin
        vlane_store_rdy_o = 1'b1;
        sbuff_wen_o = vlane_store_dvalid_i;
        if(sbuff_write_done_i) begin
          sbuff_wen_o             = 1'b0;
          store_baseaddr_set_o    = 1'b1;
          store_baseaddr_update_o = 1'b0;
          sbuff_ren_o             = 1'b1;
          wr_tvalid               = 1'b1;
          if(wr_tvalid_d[1]==1'b1) begin // index is @ output register
            store_state_next        = indexed_store_tx_prep;
            store_baseaddr_set_o  = 1'b0;
            store_baseaddr_update_o = 1'b1;
          end
        end
      end
      // INDEXED_TX_INIT
      indexed_store_tx_init: begin
        sbuff_read_stall_o      = 1'b1;
        sbuff_ren_o             = 1'b0;
        ctrl_wstart_o           = 1'b1;
        sbuff_read_invalidate   = 1'b1;
        store_state_next        = indexed_store_tx;
      end
      // INDEXED_TX_PREP
      indexed_store_tx_prep: begin
        if (sbuff_read_done_i)begin
          sbuff_ren_o           = 1'b0;
          wr_tvalid             = 1'b0;
        end
        else begin
          sbuff_ren_o           = 1'b1;
          wr_tvalid             = 1'b1;
        end
        ctrl_wstart_o           = 1'b1;
        sbuff_read_invalidate   = 1'b1;
        store_state_next        = indexed_store_tx;
      end
      // INDEXED_TX
      indexed_store_tx: begin
        sbuff_read_stall_o      = 1'b1;
        sbuff_ren_o             = 1'b0;
        if (!wr_tready_i)
          sbuff_read_invalidate = 1'b1;
        if (ctrl_wdone_i) begin
          store_baseaddr_update_o = 1'b1;
          if(sbuff_read_done_i && (wr_tvalid_d[1:0]==0))
            store_state_next = store_idle;
          else
            store_state_next = indexed_store_tx_prep;
        end
      end
      // DEFAULT
      default begin
      // SEE TOP OF CASE STATEMENT
      end
    endcase
  end
  
  assign load_type_o           = load_type_next;
  assign cfg_load_data_lmul_o  = load_data_lmul_next;
  assign cfg_load_data_sew_o   = load_data_sew_next;
  assign cfg_load_idx_lmul_o   = load_idx_lmul_next;
  assign cfg_load_idx_sew_o    = load_idx_sew_next;
  // TODO THIS IS A COPY OF A PREVIOUS FSM
  // TODO CONVERTING TO LOAD FSM IN PROGRESS
  // MAIN LOAD FSM M_CU NEXTSTATE & CONTROL
  always_comb begin
    // default values for output signals
    load_state_next         = load_state_reg;
    load_data_lmul_next     = load_data_lmul_reg;
    load_data_sew_next      = load_data_sew_reg;
    load_idx_lmul_next      = load_idx_lmul_reg;
    load_idx_sew_next       = load_idx_sew_reg;
    load_baseaddr_o         = mcu_base_addr_i;
    load_cfg_update_o       = 1'b0;
    mcu_ld_rdy_o            = 1'b0;
    load_baseaddr_update_o  = 1'b0;
    load_baseaddr_set_o     = 1'b0;
    load_cntr_rst_o         = 1'b0;
    save_load_type          = 1'b0;
    libuff_read_stall_o     = 1'b0;
    libuff_read_flush_o     = 1'b0;
    libuff_wen_o            = 1'b0;
    libuff_ren_o            = 1'b0;
    libuff_rvalid           = 1'b1;
    ldbuff_read_stall_o     = 1'b0;
    ldbuff_read_flush_o     = !ldbuff_rvalid_d[0];
    ldbuff_wen_o            = 1'b0;
    ldbuff_ren_o            = 1'b0;
    ctrl_rstart_o           = 1'b0;
    rd_tready_o             = 1'b0;
    ldbuff_rvalid           = 1'b0;
    vlane_load_last_o       = (ldbuff_rvalid_d==2'b10);

    case (load_state_reg)
      // IDLE
      load_idle: begin
        mcu_ld_rdy_o = 1'b1;
        if(mcu_ld_vld_reg)
        begin
          save_load_type        = 1'b1;
          load_cfg_update_o     = 1'b1;
          load_cntr_rst_o       = 1'b1;
          load_baseaddr_set_o   = 1'b1;
          if(mcu_unit_ld_st_i)begin
            //unit
            load_state_next         = unit_load_prep;
            load_data_sew_next      = mcu_data_width_i;
            load_data_lmul_next     = emul;
            load_idx_sew_next       = mcu_data_width_i;  // Not used in this context
            load_idx_lmul_next      = emul;              // Not used in this context
          end
          else if (mcu_strided_ld_st_i)begin
            //strided
            load_state_next         = strided_load_prep;
            load_data_sew_next      = mcu_data_width_i;
            load_data_lmul_next     = emul;
            load_idx_sew_next       = mcu_data_width_i;  // Not used in this context
            load_idx_lmul_next      = emul;              // Not used in this context
          end
          else if (mcu_idx_ld_st_i)begin
            //indexed
            load_state_next        = indexed_load_prep;
            load_data_sew_next     = mcu_sew_i;
            load_data_lmul_next    = mcu_lmul_i;
            load_idx_sew_next      = mcu_data_width_i;
            load_idx_lmul_next     = emul;
          end
        end
      end

      // UNIT LOAD STATES
      // UNIT_LOAD_PREP
      unit_load_prep: begin
        ctrl_rstart_o = 1'b1;
        rd_tready_o   = 1'b1;
        ldbuff_wen_o  = rd_tvalid_i;
        if(rd_tlast_i) begin
          load_state_next = unit_load_tx;
          ctrl_rstart_o         = 1'b0;
          ldbuff_rvalid         = 1'b1;
          ldbuff_ren_o          = 1'b1;
        end
      end
      // UNIT_LOAD
      unit_load_tx: begin
        ldbuff_rvalid           = 1'b1;
        if(wr_tready_i) begin
          ldbuff_ren_o          = 1'b1;
        end
        else begin
          ldbuff_read_stall_o   = 1'b1;
          ldbuff_ren_o          = 1'b0;
        end
        if(ldbuff_read_done_i) begin
          ldbuff_ren_o          = 1'b0;
          ldbuff_rvalid         = 1'b0;
          if(ldbuff_rvalid_d[1]==1'b0)
            load_state_next = load_idle;
        end
      end


      // STRIDED LOAD STATES
      // STRIDED_LOAD_PREP
      strided_load_prep: begin
        rd_tready_o         = 1'b0;
        ldbuff_wen_o        = 1'b0;
        ldbuff_read_flush_o = 1'b1;
        if (ldbuff_write_done_i)begin
          load_state_next   = strided_load_tx;
          ctrl_rstart_o     = 1'b0;
        end
        else begin
          load_state_next   = strided_load_tx_prep;
          ctrl_rstart_o     = 1'b1;
        end
      end
      // STRIDED_LOAD_TX_PREP
      strided_load_tx_prep: begin
        ldbuff_wen_o      = rd_tvalid_i;
        ldbuff_rvalid     = 1'b1;
        rd_tready_o       = 1'b1;
        if (ctrl_rdone_i)begin
          load_baseaddr_update_o  = 1'b1;
          ldbuff_wen_o            = 1'b0;
          ldbuff_rvalid           = 1'b0;
          load_state_next = strided_load_prep;
        end
      end
      // STRIDED_TX
      strided_load_tx: begin
        ldbuff_rvalid           = 1'b1;
        if(wr_tready_i) begin
          ldbuff_ren_o          = 1'b1;
        end
        else begin
          ldbuff_read_stall_o   = 1'b1;
          ldbuff_ren_o          = 1'b0;
        end
        if(ldbuff_read_done_i) begin
          ldbuff_ren_o          = 1'b0;
          ldbuff_rvalid         = 1'b0;
          if(ldbuff_rvalid_d[1]==1'b0)
            load_state_next = load_idle;
        end

      end

      // INDEXED LOAD STATES
      // INDEXED_LOAD_PREP
      indexed_load_prep: begin
        ldbuff_read_flush_o = 1'b1;
        libuff_wen_o = vlane_load_ivalid_i;
        if(libuff_write_done_i) begin
          libuff_wen_o              = 1'b0;
          libuff_ren_o              = 1'b1;
          libuff_rvalid             = 1'b1;
          if(libuff_rvalid_d[1]==1'b1) begin // index is @ output register
            load_state_next         = indexed_load_tx_init;
            load_baseaddr_update_o  = 1'b1;
          end
        end
      end
      // INDEXED LOAD INIT
      indexed_load_tx_init: begin
        rd_tready_o         = 1'b0;
        ldbuff_wen_o        = 1'b0;
        ldbuff_read_flush_o = 1'b1;
        if (ldbuff_write_done_i)begin
          load_state_next   = indexed_load_tx;
          ctrl_rstart_o     = 1'b0;
        end
        else begin
          load_state_next   = indexed_load_tx_prep;
          ctrl_rstart_o     = 1'b1;
        end
      end
      // INDEXED_LOAD_TX_PREP
      indexed_load_tx_prep: begin
        ldbuff_read_flush_o = 1'b1;
        ldbuff_wen_o        = rd_tvalid_i;
        ldbuff_rvalid       = 1'b1;
        rd_tready_o         = 1'b1;
        if (ctrl_rdone_i) begin
          load_baseaddr_update_o  = 1'b1;
          ldbuff_wen_o            = 1'b0;
          ldbuff_rvalid           = 1'b0;
          load_state_next = indexed_load_tx_init;
        end
      end
      // INDEXED_TX
      indexed_load_tx: begin
        ldbuff_rvalid           = 1'b1;
        if(wr_tready_i) begin
          ldbuff_ren_o          = 1'b1;
        end
        else begin
          ldbuff_read_stall_o   = 1'b1;
          ldbuff_ren_o          = 1'b0;
        end
        if(ldbuff_read_done_i) begin
          ldbuff_ren_o          = 1'b0;
          ldbuff_rvalid         = 1'b0;
          if(ldbuff_rvalid_d[1]==1'b0)
            load_state_next = load_idle;
        end
      end
      // DEFAULT
      default begin
      // SEE TOP OF CASE STATEMENT
      end
    endcase
  end

 endmodule : m_cu
`default_nettype wire
