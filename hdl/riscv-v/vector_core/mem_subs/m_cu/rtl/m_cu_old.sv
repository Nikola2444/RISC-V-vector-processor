
/*
  // MAIN STORE FSM M_CU NEXTSTATE & CONTROL
  always_comb begin
    // default values for output signals
    store_write_state_next        = store_write_state_reg;
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
    ctrl_wstart             = 1'b0;
    wr_tvalid               = 1'b0;
    mcu_st_vld_next         = 1'b0

    case (store_write_state_reg)
      // IDLE
      store_idle: begin
        mcu_st_rdy_o          = 1'b1;
        if(mcu_st_vld_reg) // All buffered update buff array, change state
        begin
          mcu_st_rdy_o          = 1'b0;
          store_cfg_update_o    = 1'b1;
          store_cntr_rst_o      = 1'b1;
          wr_tvalid             = 1'b0;
          case(store_type_reg)
            3'b001:
              store_write_state_next        = indexed_store_prep;
            3'b010:
              store_write_state_next        = strided_store_prep;
            default
              store_write_state_next        = unit_store_prep;
          endcase
        end
        else if(mcu_st_vld_i)begin // Buffer the configuration
          save_store_type       = 1'b1;
          store_baseaddr_set_o  = 1'b1;
          mcu_st_vld_next       = mcu_st_vld_i;
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

      // UNIT STORE STATES
      // UNIT_PREP
      unit_store_prep: begin
        sbuff_wen_o = vlane_store_dvalid_i;
        vlane_store_rdy_o = 1'b1;
        if(sbuff_write_done_i && vlane_store_dvalid_i) begin
          store_write_state_next = unit_store_tx;
          ctrl_wstart           = 1'b1;
          wr_tvalid             = 1'b1; // pre-read 1
          sbuff_ren_o           = 1'b1; // pre-read 1
        end
      end
      // UNIT_STORE
      unit_store_tx: begin
        wr_tvalid               = 1'b1;
        sbuff_ren_o             = 1'b1;
        if(ctrl_wdone_i)
          store_write_state_next = store_idle;
        if(sbuff_read_done_i && wr_tready_i) begin
          wr_tvalid             = 1'b0;
          sbuff_ren_o           = 1'b0;
        end
        if(!wr_tready_i) begin
          sbuff_read_stall_o    = 1'b1;
          sbuff_ren_o           = 1'b0;
        end
      end

      // STRIDED STORE STATES
      // STRIDED_STORE_PREP
      strided_store_prep: begin
        vlane_store_rdy_o = 1'b1;
        sbuff_wen_o = vlane_store_dvalid_i;
        if(sbuff_write_done_i) begin
          store_write_state_next      = strided_store_tx_prep;
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
        ctrl_wstart        = 1'b1;
        sbuff_read_invalidate = 1'b1;
        store_write_state_next = strided_store_tx;
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
            store_write_state_next = store_idle;
          else
            store_write_state_next = strided_store_tx_prep;
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
            store_write_state_next        = indexed_store_tx_prep;
            store_baseaddr_set_o  = 1'b0;
            store_baseaddr_update_o = 1'b1;
          end
        end
      end
      // INDEXED_TX_INIT
      indexed_store_tx_init: begin
        sbuff_read_stall_o      = 1'b1;
        sbuff_ren_o             = 1'b0;
        ctrl_wstart             = 1'b1;
        sbuff_read_invalidate   = 1'b1;
        store_write_state_next        = indexed_store_tx;
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
        ctrl_wstart             = 1'b1;
        sbuff_read_invalidate   = 1'b1;
        store_write_state_next        = indexed_store_tx;
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
            store_write_state_next = store_idle;
          else
            store_write_state_next = indexed_store_tx_prep;
        end
      end
      // DEFAULT
      default begin
      // SEE TOP OF CASE STATEMENT
      end
    endcase
  end
  */

  /*
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
    mcu_ld_buffered_o       = 1'b0;
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
    ldbuff_read_flush_o     = (ldbuff_rvalid_d[2:0]==0);
    ldbuff_wen_o            = 1'b0;
    ldbuff_ren_o            = 1'b0;
    ctrl_rstart             = 1'b0;
    rd_tready_o             = 1'b0;
    ldbuff_rvalid           = 1'b0;
    vlane_load_last_o       = (ldbuff_rvalid_d==3'b100);

    case (load_state_reg)
      // IDLE
      load_idle: begin
        mcu_ld_rdy_o = 1'b1;
        if(mcu_ld_vld_reg)   // Based on buffered data start the execution
        begin
          mcu_ld_rdy_o = 1'b0;
          load_cfg_update_o    = 1'b1;
          load_cntr_rst_o      = 1'b1;
          case(load_type_reg)
            3'b001:
              load_state_next        = indexed_load_prep;
            3'b010:
              load_state_next        = strided_load_prep;
            default
              load_state_next        = unit_load_prep;
          endcase
        end
        else if(mcu_ld_vld_i)begin // Buffer the configuration
          save_load_type       = 1'b1;
          load_baseaddr_set_o  = 1'b1;
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

      // UNIT LOAD STATES
      // UNIT_LOAD_PREP
      unit_load_prep: begin
        ctrl_rstart   = 1'b1;
        rd_tready_o   = 1'b1;
        ldbuff_wen_o  = rd_tvalid_i;
        if(rd_tlast_i && rd_tvalid_i) begin
          load_state_next = unit_load_tx;
          mcu_ld_buffered_o       = 1'b1;
          ldbuff_rvalid         = 1'b1; // pre-read 1
          ldbuff_ren_o          = 1'b1; // pre-read 1
        end
      end
      // UNIT_LOAD
      unit_load_tx: begin
        ldbuff_rvalid           = 1'b1;
        ldbuff_ren_o            = 1'b1;
        if(ldbuff_read_done_i && vlane_load_rdy_i) begin
          ldbuff_ren_o          = 1'b0;
          ldbuff_rvalid         = 1'b0;
          if(ldbuff_rvalid_d==3'b100)
            load_state_next = load_idle;
        end
        if(!vlane_load_rdy_i) begin
          ldbuff_read_stall_o   = 1'b1;
          ldbuff_ren_o          = 1'b0;
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
          ctrl_rstart     = 1'b0;
        end
        else begin
          load_state_next   = strided_load_tx_prep;
          ctrl_rstart     = 1'b1;
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
        if(rd_tvalid_i) begin
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
          ctrl_rstart     = 1'b0;
        end
        else begin
          load_state_next   = indexed_load_tx_prep;
          ctrl_rstart     = 1'b1;
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
        if(rd_tvalid_i) begin
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
  */
