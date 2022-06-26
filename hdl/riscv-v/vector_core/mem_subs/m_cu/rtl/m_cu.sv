// Coded by Djordje Miseljic | e-mail: djordjemiseljic@uns.ac.rs //////////////////////////////////////////////////////////////////////////////// // default_nettype of none prevents implicit logic declaration.
////////////////////////////////////////////////////////////////////////////////
// default_nettype of none prevents implicit logic declaration.
`default_nettype wire

module m_cu #(
  parameter integer VLEN                     = 8192,
  parameter integer VLANE_NUM               = 8 ,
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
  output logic                                   mcu_st_rdy_o            ,
  input  logic                                   mcu_st_vld_i            ,
  // SHEDULER <=> M_CU CONFIG IF [loads]
  output logic                                   mcu_ld_rdy_o            ,
  output logic                                   mcu_ld_buffered_o       ,
  input  logic                                   mcu_ld_vld_i            ,
  // MCU => BUFF_ARRAY CONFIG IF [general]
  input  logic [31:0]                           mcu_vl_i                ,
  output logic [$clog2(VLEN)-1:0]                cfg_vl_o                ,
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
  output logic                                   store_baseaddr_set_o    ,
  output logic                                   sdbuff_read_stall_o     ,
  output logic                                   sdbuff_read_flush_o     ,
  output logic                                   sibuff_read_stall_o     ,
  output logic                                   sibuff_read_flush_o     ,
  output logic                                   sbuff_wen_o             ,
  output logic                                   sdbuff_ren_o            ,
  output logic                                   sibuff_ren_o            ,
  input  logic                                   sibuff_not_empty_i      ,
  input  logic                                   sdbuff_write_done_i     ,
  input  logic                                   sibuff_write_done_i     ,
  input  logic                                   sdbuff_read_done_i      ,
  input  logic                                   sibuff_read_done_i      ,
  input  logic                                   sdbuff_read_rdy_i       ,
  input  logic                                   sibuff_read_rdy_i       ,
  input  logic                                   libuff_read_rdy_i       ,
  // MCU <=> BUFF_ARRAY CONTROL IF [loads]
  output logic                                   load_cfg_update_o       ,
  output logic                                   load_cntr_rst_o         ,
  output logic [2:0]                             load_type_o             ,
  output logic [31:0]                            load_stride_o           ,
  output logic [31:0]                            load_baseaddr_o         ,
  output logic                                   load_baseaddr_set_o     ,
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
  output logic                                   ldbuff_wlast_o          ,
  output logic                                   ldbuff_ren_o            ,
  input  logic                                   ldbuff_not_empty_i      ,
  input  logic                                   ldbuff_write_done_i     ,
  input  logic                                   ldbuff_read_done_i      ,
  // MCU <=> V_LANE IF
  input  logic                                   vlane_store_dvalid_i    , 
  input  logic                                   vlane_store_ivalid_i    , 
  output logic                                   vlane_store_rdy_o       , 
  input  logic                                   vlane_load_rdy_i        ,
  input  logic                                   vlane_load_ivalid_i     ,
  output logic                                   vlane_load_dvalid_o     ,
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
  logic       sibuff_rvalid;
  logic       sdbuff_rvalid;
  logic       wr_tvalid_out;
  logic [2:0] sdbuff_rvalid_d;
  logic [2:0] sibuff_rvalid_d;
  logic       ldbuff_rvalid;
  logic       libuff_rvalid;
  logic [2:0] ldbuff_rvalid_d;
  logic [2:0] libuff_rvalid_d;
  logic       sbuff_read_invalidate;
  logic       ctrl_rstart,ctrl_rstart_d;
  logic       ctrl_wstart,ctrl_wstart_d;
  logic       start_store_read_fsm,store_read_fsm_done;
  // Store Signals
  logic       save_store_type;
  logic [2:0] store_type_reg,store_type_next;
  typedef enum logic[3:0] {store_write_idle, store_write_idle_buffed, store_write, store_write_wait} write_store_fsm;
  write_store_fsm store_write_state_reg, store_write_state_next;
  typedef enum logic[3:0] {store_read_idle, store_read_unit, store_read_strided,store_read_strided_2, store_read_indexed, store_read_indexed_2, store_read_indexed_3} read_store_fsm;
  read_store_fsm store_read_state_reg, store_read_state_next;
  // LOAD Signals
  typedef enum logic[3:0] {load_read_idle, load_read_idle_buffed, load_read_wait, load_read} read_load_fsm;
  read_load_fsm load_read_state_reg, load_read_state_next;
  typedef enum logic[3:0] {load_write_idle, load_write_unit, load_write_strided, load_write_strided_2, load_write_indexed, load_write_indexed_2, load_write_indexed_3} write_load_fsm;
  write_load_fsm load_write_state_reg, load_write_state_next;
  logic       save_load_type;
  logic [2:0] load_type_reg,load_type_next;
  logic       start_load_write_fsm;

  ///////////////////////////////////////////////////////////////////////////////
  // Begin RTL
  ///////////////////////////////////////////////////////////////////////////////

  assign store_stride_o = mcu_stride_i;
  assign load_stride_o = mcu_stride_i;
  assign cfg_vl_o = mcu_vl_i[$clog2(VLEN)-1:0];

  assign emul_addr = {mcu_data_width_i[1:0], mcu_lmul_i[2:0], mcu_sew_i[1:0]};
  assign emul = emul_calc[emul_addr][2:0];
  assign emul_valid = emul_calc[emul_addr][3];

  assign ldbuff_wlast_o = rd_tlast_i;

  // STORE FSM M_CU STATE
  always_ff @(posedge clk, negedge rstn)
  begin
    if(!rstn) begin
      store_write_state_reg <= store_write_idle;
      store_read_state_reg  <= store_read_idle;
      load_write_state_reg  <= load_write_idle;
      load_read_state_reg   <= load_read_idle;
    end
    else begin
      store_write_state_reg <= store_write_state_next;
      store_read_state_reg  <= store_read_state_next;
      load_write_state_reg  <= load_write_state_next;
      load_read_state_reg  <= load_read_state_next;
    end
  end

  always_ff @(posedge clk, negedge rstn)
  begin
    if(!rstn)
      sdbuff_rvalid_d      <= 0;
    else if (!sdbuff_read_stall_o)
      sdbuff_rvalid_d      <= {sdbuff_rvalid_d[1:0], sdbuff_rvalid};
  end

  always_ff @(posedge clk, negedge rstn)
  begin
    if(!rstn)
      sibuff_rvalid_d      <= 0;
    else if (!sdbuff_read_stall_o)
      sibuff_rvalid_d      <= {sibuff_rvalid_d[1:0], sibuff_rvalid};
  end

  assign wr_tvalid_o   = !sbuff_read_invalidate ? wr_tvalid_out : 1'b0;
  assign wr_tvalid_out = sdbuff_read_done_i ? sdbuff_rvalid_d[2] : sdbuff_rvalid_d[1];

  always_ff @(posedge clk, negedge rstn)
  begin
    if(!rstn)
      ldbuff_rvalid_d      <= 0;
    else if (!ldbuff_read_stall_o)
      ldbuff_rvalid_d      <= {ldbuff_rvalid_d[1:0], ldbuff_rvalid};
  end

  always_ff @(posedge clk, negedge rstn)
  begin
    if(!rstn)
      libuff_rvalid_d      <= 0;
    else if (!libuff_read_stall_o)
      libuff_rvalid_d      <= {libuff_rvalid_d[1:0], libuff_rvalid};
  end

  assign vlane_load_dvalid_o = ldbuff_read_done_i ? ldbuff_rvalid_d[2] : ldbuff_rvalid_d[1];

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
    else begin
      if (save_store_type) begin
        store_type_reg            <= store_type_next;
        store_data_lmul_reg       <= store_data_lmul_next;
        store_data_sew_reg        <= store_data_sew_next;
        store_idx_lmul_reg        <= store_idx_lmul_next;
        store_idx_sew_reg         <= store_idx_sew_next;
      end
    end
  end
  //assign store_type_next = save_store_type ? {mcu_unit_ld_st_i,mcu_strided_ld_st_i,mcu_idx_ld_st_i} : store_type_reg;
  assign store_type_next = {mcu_unit_ld_st_i,mcu_strided_ld_st_i,mcu_idx_ld_st_i};

  assign store_type_o           = store_type_reg;
  assign cfg_store_data_lmul_o  = store_data_lmul_reg;
  assign cfg_store_data_sew_o   = store_data_sew_reg;
  assign cfg_store_idx_lmul_o   = store_idx_lmul_reg;
  assign cfg_store_idx_sew_o    = store_idx_sew_reg;

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
  //assign load_type_next = save_load_type ? {mcu_unit_ld_st_i,mcu_strided_ld_st_i,mcu_idx_ld_st_i} : load_type_reg;
  assign load_type_next = {mcu_unit_ld_st_i,mcu_strided_ld_st_i,mcu_idx_ld_st_i};

  always_ff @(posedge clk, negedge rstn) begin
    if(!rstn)begin
      ctrl_rstart_d            <= 0;
      ctrl_wstart_d            <= 0;
    end
    else begin
      ctrl_rstart_d            <= ctrl_rstart;
      ctrl_wstart_d            <= ctrl_wstart;
    end
  end
  assign ctrl_rstart_o = (!ctrl_rstart_d && ctrl_rstart);// pulse
  assign ctrl_wstart_o = (!ctrl_wstart_d && ctrl_wstart);// pulse

  assign load_type_o           = load_type_reg;
  assign cfg_load_data_lmul_o  = load_data_lmul_reg;
  assign cfg_load_data_sew_o   = load_data_sew_reg;
  assign cfg_load_idx_lmul_o   = load_idx_lmul_reg;
  assign cfg_load_idx_sew_o    = load_idx_sew_reg;


  assign store_baseaddr_o      = mcu_base_addr_i;

  // WRITE WRITE WRITE WRITE WRITE WRITE WRITE WRITE 
  // MAIN WRITE STORE FSM M_CU NEXTSTATE & CONTROL
  always_comb begin
    // default values for output signals
    store_write_state_next  = store_write_state_reg;
    store_data_lmul_next    = store_data_lmul_reg;
    store_data_sew_next     = store_data_sew_reg;
    store_idx_lmul_next     = store_idx_lmul_reg;
    store_idx_sew_next      = store_idx_sew_reg;
    vlane_store_rdy_o       = 1'b0;
    store_cfg_update_o      = 1'b0;
    mcu_st_rdy_o            = 1'b0;
    store_baseaddr_set_o    = 1'b0;
    save_store_type         = 1'b0;
    sbuff_wen_o             = 1'b0;
    store_cntr_rst_o        = 1'b0;
    start_store_read_fsm    = 1'b0;

    case (store_write_state_reg)
      // IDLE
      store_write_idle: begin
        mcu_st_rdy_o             = 1'b1;
        if(mcu_st_vld_i)begin // Buffer the configuration
          save_store_type        = 1'b1;
          store_baseaddr_set_o   = 1'b1;
          store_write_state_next = store_write_idle_buffed;
          case(store_type_next)
            3'b001:begin
              store_data_sew_next     = mcu_sew_i;
              store_data_lmul_next    = mcu_lmul_i;
              store_idx_sew_next      = mcu_data_width_i;
              store_idx_lmul_next     = emul;
            end
            3'b010:begin
              store_data_sew_next     = mcu_data_width_i;
              store_data_lmul_next    = emul;
              store_idx_sew_next      = mcu_data_width_i;  // Not used in this context
              store_idx_lmul_next     = emul;              // Not used in this context
            end
            default begin
              store_data_sew_next     = mcu_data_width_i;
              store_data_lmul_next    = emul;
              store_idx_sew_next      = mcu_data_width_i;  // Not used in this context
              store_idx_lmul_next     = emul;              // Not used in this context
            end
          endcase
        end
      end
      store_write_idle_buffed:begin
        store_cfg_update_o    = 1'b1;
        store_cntr_rst_o      = 1'b1;
        store_write_state_next= store_write;
        start_store_read_fsm  = 1'b1;
      end

      // UNIVERSAL STORE WRITE
      store_write: begin
        sbuff_wen_o = vlane_store_dvalid_i;
        vlane_store_rdy_o = 1'b1;
        if(sdbuff_write_done_i && vlane_store_dvalid_i) begin
          store_write_state_next = store_write_wait;
        end
      end

      // UNIVERSAL STORE WRITE
      store_write_wait: begin
        if(store_read_fsm_done) begin
          store_write_state_next = store_write_idle;
        end
      end

      default begin
      // SEE TOP OF CASE STATEMENT
      end
    endcase
  end


  // READ READ READ READ READ READ READ READ READ READ READ
  // MAIN STORE READ FSM M_CU NEXTSTATE & CONTROL
  always_comb begin
    // default values for output signals
    store_read_state_next   = store_read_state_reg;
    store_baseaddr_update_o = 1'b0;
    sbuff_read_invalidate   = 1'b0;
    sdbuff_read_stall_o     = 1'b0;
    sdbuff_read_flush_o     = 1'b0;
    sdbuff_ren_o            = 1'b0;
    sibuff_read_stall_o     = 1'b0;
    sibuff_read_flush_o     = 1'b0;
    sibuff_ren_o            = 1'b0;
    sibuff_rvalid           = 1'b0;
    ctrl_wstart             = 1'b0;
    sdbuff_rvalid               = 1'b0;
    store_read_fsm_done     = 1'b0;

    case (store_read_state_reg)
      // IDLE
      store_read_idle: begin
      if(start_store_read_fsm)
        case(store_type_reg)
          3'b001:begin
            store_read_state_next = store_read_indexed;
          end
          3'b010:begin
            store_read_state_next = store_read_strided;
          end
          default begin
            store_read_state_next = store_read_unit;
          end
        endcase
      end
      // UNIT_STORE
      store_read_unit: begin
        ctrl_wstart               = 1'b1;
        if(sdbuff_read_rdy_i)begin
          sdbuff_rvalid               = 1'b1;
          sdbuff_ren_o            = 1'b1;
          if(ctrl_wdone_i)begin
            store_read_state_next = store_read_idle;
            store_read_fsm_done   = 1'b1;
          end
          if(sdbuff_read_done_i && wr_tready_i) begin
            sdbuff_rvalid             = 1'b0;
            sdbuff_ren_o          = 1'b0;
          end
          if(!wr_tready_i && wr_tvalid_o) begin
            sdbuff_read_stall_o   = 1'b1;
            sdbuff_ren_o          = 1'b0;
          end
        end
        else begin //data not ready in buffer
          sdbuff_read_stall_o     = 1'b1;
          sdbuff_ren_o            = 1'b0;
          sbuff_read_invalidate   = 1'b1;
        end
      end

      //STRIDED_STORE
      store_read_strided: begin
        ctrl_wstart = 1'b1;
        if(sdbuff_read_rdy_i)begin
          sdbuff_rvalid               = 1'b1;
          sdbuff_ren_o            = 1'b1;
          if(wr_tvalid_o && wr_tready_i)begin
            store_read_state_next = store_read_strided_2;
            if(sdbuff_read_done_i) begin
              sdbuff_rvalid             = 1'b0;
              sdbuff_ren_o          = 1'b0;
            end
          end
          if(!wr_tready_i && wr_tvalid_o) begin
            sdbuff_read_stall_o   = 1'b1;
            sdbuff_ren_o          = 1'b0;
          end
        end
        else begin //data not ready in buffer
          sdbuff_read_stall_o     = 1'b1;
          sdbuff_ren_o            = 1'b0;
          sbuff_read_invalidate   = 1'b1;
        end
      end

      store_read_strided_2: begin
        sdbuff_read_stall_o     = 1'b1;
        sdbuff_ren_o            = 1'b0;
        if(ctrl_wdone_i)begin
          store_baseaddr_update_o = 1'b1;
          store_read_state_next = store_read_strided;
          if(sdbuff_rvalid_d==3'b000)begin
            store_read_state_next = store_read_idle;
            store_read_fsm_done   = 1'b1;
          end
        end
      end

      //INDEXED_STORE
      store_read_indexed: begin
        if(sibuff_read_rdy_i)begin
          sibuff_rvalid = 1'b1;
          sibuff_ren_o  = 1'b1;
        end
        else begin
          sibuff_ren_o  = 1'b0;
          sibuff_read_stall_o = 1'b1;
        end
        if(sibuff_rvalid_d[1])begin
          // Prepare next index
          sibuff_ren_o            = 1'b1;
          sibuff_rvalid           = 1'b1;
          // Update with current index
          store_baseaddr_update_o = 1'b1;
          store_read_state_next   = store_read_indexed_2;
        end
      end

      store_read_indexed_2: begin
        sibuff_read_stall_o    = 1'b1;
        sibuff_ren_o           = 1'b0;
        ctrl_wstart = 1'b1;
        if(sdbuff_read_rdy_i)begin
          sdbuff_rvalid             = 1'b1;
          sdbuff_ren_o              = 1'b1;
          if(wr_tvalid_o && wr_tready_i)begin
            store_read_state_next = store_read_indexed_3;
            if(sdbuff_read_done_i) begin
              sdbuff_rvalid         = 1'b0;
              sdbuff_ren_o          = 1'b0;
            end
          end
          if(!wr_tready_i && wr_tvalid_o) begin
            sdbuff_read_stall_o   = 1'b1;
            sdbuff_ren_o          = 1'b0;
          end
        end
        else begin //data not ready in buffer
          sdbuff_read_stall_o     = 1'b1;
          sdbuff_ren_o            = 1'b0;
          sbuff_read_invalidate   = 1'b1;
        end
      end

      store_read_indexed_3: begin
        sdbuff_read_stall_o     = 1'b1;
        sdbuff_ren_o            = 1'b0;
        sibuff_read_stall_o     = 1'b1;
        sibuff_ren_o            = 1'b0;
        if(ctrl_wdone_i)begin
          // Prepare next index
          sibuff_rvalid           = 1'b1;
          sibuff_ren_o            = 1'b1;
          sibuff_read_stall_o     = 1'b0;
          // Update with current index
          store_baseaddr_update_o = 1'b1;
          store_read_state_next = store_read_indexed_2;
          if(sdbuff_rvalid_d==3'b000)begin
            store_read_state_next = store_read_idle;
            store_read_fsm_done   = 1'b1;
          end
        end
      end

      default begin
      // SEE TOP OF CASE STATEMENT
      end
    endcase
  end

  assign ldbuff_read_flush_o     = (ldbuff_rvalid_d[2:0]==0);
  assign vlane_load_last_o       = (ldbuff_rvalid_d==3'b100);
  // READ READ READ READ READ READ READ READ READ
  // MAIN LOAD FSM M_CU NEXTSTATE & CONTROL
  always_comb begin
    // default values for output signals
    load_read_state_next    = load_read_state_reg;
    load_data_lmul_next     = load_data_lmul_reg;
    load_data_sew_next      = load_data_sew_reg;
    load_idx_lmul_next      = load_idx_lmul_reg;
    load_idx_sew_next       = load_idx_sew_reg;
    load_baseaddr_o         = mcu_base_addr_i;
    load_cfg_update_o       = 1'b0;
    mcu_ld_rdy_o            = 1'b0;
    load_baseaddr_set_o     = 1'b0;
    load_cntr_rst_o         = 1'b0;
    save_load_type          = 1'b0;
    libuff_wen_o            = 1'b0;
    ldbuff_read_stall_o     = 1'b0;
    ldbuff_ren_o            = 1'b0;
    ldbuff_rvalid           = 1'b0;
    start_load_write_fsm    = 1'b0;

    case (load_read_state_reg)
      // IDLE
      load_read_idle: begin
        mcu_ld_rdy_o = 1'b1;
        if(mcu_ld_vld_i)begin // Buffer the configuration
          save_load_type       = 1'b1;
          load_baseaddr_set_o  = 1'b1;
          load_read_state_next = load_read_idle_buffed;
          case(load_type_next)
            3'b001:begin
              load_data_sew_next     = mcu_sew_i;
              load_data_lmul_next    = mcu_lmul_i;
              load_idx_sew_next      = mcu_data_width_i;
              load_idx_lmul_next     = emul;
            end
            3'b010:begin
              load_data_sew_next     = mcu_data_width_i;
              load_data_lmul_next    = emul;
              load_idx_sew_next      = mcu_data_width_i;  // Not used in this context
              load_idx_lmul_next     = emul;              // Not used in this context
            end
            default begin
              load_data_sew_next     = mcu_data_width_i;
              load_data_lmul_next    = emul;
              load_idx_sew_next      = mcu_data_width_i;  // Not used in this context
              load_idx_lmul_next     = emul;              // Not used in this context
            end
          endcase
        end
      end

      load_read_idle_buffed: begin
        load_cfg_update_o     = 1'b1;
        load_cntr_rst_o       = 1'b1;
        load_read_state_next  = load_read_wait;
        start_load_write_fsm  = 1'b1;
      end

      load_read_wait: begin
        if(mcu_ld_buffered_o)
          load_read_state_next = load_read;
      end

      load_read: begin
        ldbuff_rvalid           = 1'b1;
        ldbuff_ren_o            = 1'b1;
        if(ldbuff_read_done_i && vlane_load_rdy_i) begin
          ldbuff_ren_o          = 1'b0;
          ldbuff_rvalid         = 1'b0;
          if(ldbuff_rvalid_d==3'b100)
            load_read_state_next = load_read_idle;
        end
        if(!vlane_load_rdy_i) begin
          ldbuff_read_stall_o   = 1'b1;
          ldbuff_ren_o          = 1'b0;
        end
  
      end
      // DEFAULT
      default begin
      // SEE TOP OF CASE STATEMENT
      end
    endcase
  end

  // WRITE WRITE WRITE WRITE WRITE WRITE 
  // AXIF -> LOAD BUFFER
  // MAIN LOAD WRITE FSM M_CU NEXTSTATE & CONTROL
  always_comb begin
    // default values for output signals
    load_write_state_next   = load_write_state_reg;
    mcu_ld_buffered_o       = 1'b0;
    load_baseaddr_update_o  = 1'b0;
    libuff_read_stall_o     = 1'b0;
    libuff_read_flush_o     = 1'b0;
    libuff_ren_o            = 1'b0;
    libuff_rvalid           = 1'b1;
    ldbuff_wen_o            = 1'b0;
    ctrl_rstart             = 1'b0;
    rd_tready_o             = 1'b0;

    case (load_write_state_reg)
      load_write_idle:begin
        if(start_load_write_fsm)begin
          case(load_type_reg)
            3'b001:begin
              load_write_state_next        = load_write_indexed;
            end
            3'b010:begin
              load_write_state_next        = load_write_strided;
            end
            default:begin
              load_write_state_next        = load_write_unit;
            end
          endcase
        end
      end

      // UNIT_LOAD
      load_write_unit: begin
        ctrl_rstart   = 1'b1;
        rd_tready_o   = 1'b1;
        ldbuff_wen_o  = rd_tvalid_i;
        if(rd_tlast_i && rd_tvalid_i) begin
          load_write_state_next = load_write_idle;
          mcu_ld_buffered_o     = 1'b1;
        end
      end

      // STRIDED_LOAD
      load_write_strided: begin
        ctrl_rstart   = 1'b1;
        rd_tready_o   = 1'b1;
        ldbuff_wen_o  = rd_tvalid_i;
        if(rd_tlast_i && rd_tvalid_i) begin
          load_write_state_next = load_write_strided_2;
          if(ldbuff_write_done_i)begin
            mcu_ld_buffered_o     = 1'b1;
            load_write_state_next = load_write_idle;
          end
        end
      end
      load_write_strided_2: begin
        load_baseaddr_update_o  = 1'b1;
        load_write_state_next   = load_write_strided;
      end

      //INDEXED_LOAD
      load_write_indexed: begin
        if(libuff_read_rdy_i)begin
          libuff_rvalid = 1'b1;
          libuff_ren_o  = 1'b1;
        end
        else begin
          libuff_ren_o        = 1'b0;
          libuff_read_stall_o = 1'b1;
        end
        if(libuff_rvalid_d[1])begin
          // Prepare next index
          libuff_ren_o            = 1'b1;
          libuff_rvalid           = 1'b1;
          // Update with current index
          load_baseaddr_update_o  = 1'b1;
          load_write_state_next   = load_write_indexed_2;
        end
      end
      load_write_indexed_2: begin
        ctrl_rstart         = 1'b1;
        rd_tready_o         = 1'b1;
        ldbuff_wen_o        = rd_tvalid_i;
        libuff_ren_o        = 1'b0;
        libuff_read_stall_o = 1'b1;
        if(rd_tlast_i && rd_tvalid_i) begin
          load_write_state_next = load_write_indexed_3;
          if(ldbuff_write_done_i)begin
            mcu_ld_buffered_o     = 1'b1;
            load_write_state_next = load_write_idle;
          end
        end
      end
      load_write_indexed_3: begin
        libuff_ren_o            = 1'b1;
        libuff_rvalid           = 1'b1;
        // Update with current index
        load_baseaddr_update_o  = 1'b1;
        load_write_state_next   = load_write_indexed_2;
      end


      // DEFAULT
      default begin
      // SEE TOP OF CASE STATEMENT
      end
    endcase
  end

 endmodule : m_cu
`default_nettype wire
