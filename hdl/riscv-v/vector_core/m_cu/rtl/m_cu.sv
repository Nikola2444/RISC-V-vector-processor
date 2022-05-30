// Coded by Djordje Miseljic | e-mail: djordjemiseljic@uns.ac.rs //////////////////////////////////////////////////////////////////////////////// // default_nettype of none prevents implicit wire declaration.
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
  output logic 	                                mcu_st_rdy_o            ,
  input  logic                                  mcu_st_vld_i            ,
  input  logic [ 2:0]                           mcu_sew_i               ,
  input  logic [ 2:0]                           mcu_lmul_i              ,
  input  logic [31:0]                           mcu_base_addr_i         ,
  input  logic [31:0]                           mcu_stride_i            ,
  input  logic [ 2:0]                           mcu_data_width_i        ,
  input  logic                                  mcu_idx_ld_st_i         ,
  input  logic                                  mcu_strided_ld_st_i     ,
  input  logic                                  mcu_unit_ld_st_i        ,
  // Send config to buff array
  output wire [2:0]                             cfg_data_lmul_o         ,
  output wire [2:0]                             cfg_data_sew_o          ,
  output wire [2:0]                             cfg_idx_sew_o           ,
  output wire [2:0]                             cfg_idx_lmul_o          ,
  //
  output wire                                   cfg_store_update_o      ,
  output wire                                   cfg_store_cntr_rst_o    ,
  output wire                                   cfg_load_cntr_rst_o     ,
  output wire                                   sbuff_read_en_o         ,
  output wire [2:0]                             store_type_o            ,
  output wire [31:0]                            store_stride_o          ,
  output wire [31:0]                            store_baseaddr_o        ,
  output wire                                   store_baseaddr_update_o ,
  output wire                                   store_baseaddr_reset_o  ,
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
  output wire                                   wr_tvalid_o             ,
  input  wire                                   wr_tready_i             
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
  logic       save_store_type;
  logic [2:0] store_type_reg;

  logic [2:0] data_lmul_reg,data_lmul_next;
  logic [2:0] idx_lmul_reg, idx_lmul_next;
  logic [2:0] data_sew_reg, data_sew_next;
  logic [2:0] idx_sew_reg,  idx_sew_next;
  logic       mcu_st_vld_reg;
  logic       wr_tvalid;
  logic [1:0] wr_tvalid_d;
  logic       sbuff_read_invalidate;

  typedef enum {idle, unit_store_prep, unit_tx, strided_store_prep, strided_tx_prep, strided_tx, indexed_store_prep, indexed_tx_init, indexed_tx_prep, indexed_tx} store_fsm;
  store_fsm store_state_reg, store_state_next;


  ///////////////////////////////////////////////////////////////////////////////
  // Begin RTL
  ///////////////////////////////////////////////////////////////////////////////

  assign emul_addr = {mcu_data_width_i[1:0], mcu_lmul_i[2:0], mcu_sew_i[1:0]};
  assign emul = emul_calc[emul_addr][2:0];
  assign emul_valid = emul_calc[emul_addr][3];

  // MAIN STORE FSM M_CU STATE
  always_ff @(posedge clk, negedge rstn)
  begin
    if(!rstn)
      store_state_reg <= idle;
    else
      store_state_reg <= store_state_next;
  end

  always_ff @(posedge clk, negedge rstn)
  begin
    if(!rstn)
      mcu_st_vld_reg      <= 0;
    else
      mcu_st_vld_reg      <= mcu_st_vld_i;
  end

  always_ff @(posedge clk, negedge rstn)
  begin
    if(!rstn) begin
      wr_tvalid_d      <= 0;
    end
    else if (!sbuff_read_stall_o) begin
      wr_tvalid_d      <= {wr_tvalid_d[0], wr_tvalid};
    end
  end

  assign wr_tvalid_o = !sbuff_read_invalidate ? wr_tvalid_d[1] : 1'b0;

  always_ff @(posedge clk, negedge rstn)
  begin
    if(!rstn)begin
      store_type_reg      <= 0;
      data_sew_reg        <= 0;
      data_lmul_reg       <= 0;
      idx_sew_reg         <= 0;
      idx_lmul_reg        <= 0;
    end
    else if (save_store_type) begin
      store_type_reg      <= {mcu_unit_ld_st_i,mcu_strided_ld_st_i,mcu_idx_ld_st_i};
      data_lmul_reg       <= data_lmul_next;
      data_sew_reg        <= data_sew_next;
      idx_lmul_reg        <= idx_lmul_next;
      idx_sew_reg         <= idx_sew_next;
    end
  end

  assign store_type_o     = store_type_reg;
  assign cfg_data_lmul_o  = data_lmul_reg;
  assign cfg_data_sew_o   = data_sew_reg;
  assign cfg_idx_lmul_o   = idx_lmul_reg;
  assign cfg_idx_sew_o    = idx_sew_reg;

  // MAIN STORE FSM M_CU NEXTSTATE & CONTROL
  always_comb begin
    // default values for output signals
    store_state_next        = store_state_reg;
    mcu_st_rdy_o            = 1'b0;
    data_lmul_next          = 0;
    data_sew_next           = 0;
    idx_lmul_next           = 0;
    idx_sew_next            = 0;
    store_baseaddr_o        = mcu_base_addr_i;
    store_baseaddr_update_o = 1'b0;
    store_baseaddr_reset_o  = 1'b0;
    save_store_type         = 0;
    sbuff_read_stall_o      = 1'b0;
    sbuff_read_invalidate   = 1'b0;
    sbuff_read_flush_o      = 1'b0;
    sbuff_wen_o             = 1'b0;
    sbuff_ren_o             = 1'b0;
    cfg_cntr_rst_o          = 1'b0;
    ctrl_wstart_o           = 1'b0;
    wr_tvalid               = 1'b0;

    case (store_state_reg)
      // IDLE
      idle: begin
        mcu_st_rdy_o = 1'b1;
        if(mcu_st_vld_reg)
        begin
          save_store_type = 1'b1;
          cfg_store_update_o    = 1'b1;
          cfg_cntr_rst_o  = 1'b1;
          store_baseaddr_reset_o = 1'b1;
          wr_tvalid              = 1'b1;
          if(mcu_unit_ld_st_i)begin
            //unit
            store_state_next        = unit_store_prep;
            data_sew_next           = mcu_data_width_i;
            data_lmul_next          = emul;
            idx_sew_next            = mcu_data_width_i;  // Not used in this context
            idx_lmul_next           = emul;              // Not used in this context
          end
          else if (mcu_strided_ld_st_i)begin
            //strided
            store_state_next        = strided_store_prep;
            data_sew_next           = mcu_data_width_i;
            data_lmul_next          = emul;
            idx_sew_next            = mcu_data_width_i;  // Not used in this context
            idx_lmul_next           = emul;              // Not used in this context
          end
          else if (mcu_idx_ld_st_i)begin
            //indexed
            store_state_next        = indexed_store_prep;
            data_sew_next           = mcu_sew_i;
            data_lmul_next          = mcu_lmul_i;
            idx_sew_next            = mcu_data_width_i;
            idx_lmul_next           = emul;
          end
        end
      end

      // UNIT STORE STATES
      // UNIT_PREP
      unit_store_prep: begin
        sbuff_wen_o = vlane_store_valid_i;
        if(sbuff_write_done_i) begin
          store_state_next = unit_tx;
          sbuff_wen_o           = 1'b0;
          ctrl_wstart_o         = 1'b1;
          wr_tvalid             = 1'b1;
          sbuff_ren_o           = 1'b1;
        end
      end
      // UNIT_STORE
      unit_tx: begin
        if(sbuff_read_done_i) begin
          sbuff_ren_o           = 1'b0;
          if(ctrl_wdone_i)
            store_state_next = idle;
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
        sbuff_wen_o = vlane_store_valid_i;
        if(sbuff_write_done_i) begin
          store_state_next      = strided_tx_prep;
          sbuff_wen_o           = 1'b0;
          store_baseaddr_reset_o= 1'b1;
          sbuff_ren_o           = 1'b1;
          wr_tvalid             = 1'b1;
        end
      end
      // STRIDED_TX_PREP
      strided_tx_prep: begin
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
        store_state_next = strided_tx;
      end
      // STRIDED_TX
      strided_tx: begin
        sbuff_read_stall_o      = 1'b1;
        sbuff_ren_o             = 1'b0;
        if (!wr_tready_i)
          sbuff_read_invalidate = 1'b1;
        if (ctrl_wdone_i) begin
          store_baseaddr_update_o = 1'b1;
          if(sbuff_read_done_i && (wr_tvalid_d[1:0]==0))
            store_state_next = idle;
          else
            store_state_next = strided_tx_prep;
        end
      end

      // INDEXED STORE STATES
      // INDEXED_STORE_PREP
      indexed_store_prep: begin
        sbuff_wen_o = vlane_store_valid_i;
        if(sbuff_write_done_i) begin
          sbuff_wen_o             = 1'b0;
          store_baseaddr_reset_o  = 1'b1;
          store_baseaddr_update_o = 1'b0;
          sbuff_ren_o             = 1'b1;
          wr_tvalid               = 1'b1;
          if(wr_tvalid_d[1]==1'b1) begin // index is @ output register
            store_state_next        = indexed_tx_prep;
            store_baseaddr_reset_o  = 1'b0;
            store_baseaddr_update_o = 1'b1;
          end
        end
      end
      // INDEXED_TX_INIT
      indexed_tx_init: begin
        sbuff_read_stall_o      = 1'b1;
        sbuff_ren_o             = 1'b0;
        ctrl_wstart_o           = 1'b1;
        sbuff_read_invalidate   = 1'b1;
        store_state_next        = indexed_tx;
      end
      // INDEXED_TX_PREP
      indexed_tx_prep: begin
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
        store_state_next        = indexed_tx;
      end
      // INDEXED_TX
      indexed_tx: begin
        sbuff_read_stall_o      = 1'b1;
        sbuff_ren_o             = 1'b0;
        if (!wr_tready_i)
          sbuff_read_invalidate = 1'b1;
        if (ctrl_wdone_i) begin
          store_baseaddr_update_o = 1'b1;
          if(sbuff_read_done_i && (wr_tvalid_d[1:0]==0))
            store_state_next = idle;
          else
            store_state_next = indexed_tx_prep;
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
