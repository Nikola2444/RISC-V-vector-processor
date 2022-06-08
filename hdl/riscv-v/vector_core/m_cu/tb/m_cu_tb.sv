// Coded by Djordje Miseljic | e-mail: djordjemiseljic@uns.ac.rs //////////////////////////////////////////////////////////////////////////////// // default_nettype of none prevents implicit logic declaration.
////////////////////////////////////////////////////////////////////////////////
// default_nettype of none prevents implicit logic declaration.
`default_nettype wire
timeunit 1ps;
timeprecision 1ps;

// WHATWHAT
module m_cu_tb();

  localparam integer CLK_PERIOD               = 20;
  ///////////////////////////////////////////////////////////////////////////////
  // Local Parameters
  ///////////////////////////////////////////////////////////////////////////////
  localparam integer VLEN                     = 8192;
  localparam integer V_LANE_NUM               = 4;
  localparam integer MAX_VECTORS_BUFFD        = 1;
  localparam integer C_M_AXI_ADDR_WIDTH       = 32;
  localparam integer C_M_AXI_DATA_WIDTH       = 32;
  localparam integer C_XFER_SIZE_WIDTH        = 32;

  ///////////////////////////////////////////////////////////////////////////////
  // Local Signals
  ///////////////////////////////////////////////////////////////////////////////
  // System Signals
  logic                                   clk                =1'b0;
  logic                                   rstn               =1'b0;
  // SHEDULER <=> M_CU CONFIG [general]
  logic [ 2:0]                            mcu_sew              ;
  logic [ 2:0]                            mcu_lmul             ;
  logic [31:0]                            mcu_base_addr        ;
  logic [31:0]                            mcu_stride           ;
  logic [ 2:0]                            mcu_data_width       ;
  logic                                   mcu_idx_ld_st        ;
  logic                                   mcu_strided_ld_st    ;
  logic                                   mcu_unit_ld_st       ;
  // SHEDULER <=> M_CU CONFIG IF [stores]
  logic 	                                mcu_st_rdy           ;
  logic                                   mcu_st_vld           ;
  // SHEDULER <=> M_CU CONFIG IF [loads]
  logic 	                                mcu_ld_rdy           ;
  logic                                   mcu_ld_vld           ;
  // MCU => BUFF_ARRAY CONFIG IF [general]
  logic [$clog2(VLEN)-1:0]                cfg_vlenb            ;
  // MCU => BUFF_ARRAY CONFIG IF [stores]
  logic [2:0]                             cfg_store_data_lmul  ;
  logic [2:0]                             cfg_store_data_sew   ;
  logic [2:0]                             cfg_store_idx_sew    ;
  logic [2:0]                             cfg_store_idx_lmul   ;
  // MCU => BUFF_ARRAY CONFIG IF [loads]
  logic [2:0]                             cfg_load_data_lmul   ;
  logic [2:0]                             cfg_load_data_sew    ;
  logic [2:0]                             cfg_load_idx_sew     ;
  logic [2:0]                             cfg_load_idx_lmul    ;
  // MCU <=> BUFF_ARRAY CONTROL IF [stores]
  logic                                   store_cfg_update     ;
  logic                                   store_cntr_rst       ;
  logic [2:0]                             store_type           ;
  logic [31:0]                            store_stride         ;
  logic [31:0]                            store_baseaddr       ;
  logic                                   store_baseaddr_update;
  logic                                   store_baseaddr_set   ;
  logic                                   sbuff_read_stall     ;
  logic                                   sbuff_read_flush     ;
  logic                                   sbuff_wen            ;
  logic                                   sbuff_ren            ;
  logic                                   sbuff_not_empty      ;
  logic                                   sbuff_write_done     ;
  logic                                   sbuff_read_done      ;
  // MCU <=> BUFF_ARRAY CONTROL IF [loads]
  logic                                   load_cfg_update      ;
  logic                                   load_cntr_rst        ;
  logic [2:0]                             load_type            ;
  logic [31:0]                            load_stride          ;
  logic [31:0]                            load_baseaddr        ;
  logic                                   load_baseaddr_set    ;
  logic                                   load_baseaddr_update ;
  logic                                   libuff_read_stall    ;
  logic                                   libuff_read_flush    ;
  logic                                   libuff_wen           ;
  logic                                   libuff_ren           ;
  logic                                   libuff_not_empty     ;
  logic                                   libuff_write_done    ;
  logic                                   libuff_read_done     ;
  logic                                   ldbuff_read_stall    ;
  logic                                   ldbuff_read_flush    ;
  logic                                   ldbuff_wen           ;
  logic                                   ldbuff_ren           ;
  logic                                   ldbuff_not_empty     ;
  logic                                   ldbuff_write_done    ;
  logic                                   ldbuff_read_done     ;
  // V_LANE <=> BUFF_ARRAY IF  
  logic                                   vlane_store_rdy      ; 
  logic [31:0]                            vlane_store_data[0:V_LANE_NUM-1];
  logic [31:0]                            vlane_store_ptr [0:V_LANE_NUM-1];
  logic [31:0]                            vlane_load_data [0:V_LANE_NUM-1];
  logic [3:0]                             vlane_load_valid[0:V_LANE_NUM-1];
  logic [31:0]                            vlane_load_ptr  [0:V_LANE_NUM-1];
  // MCU <=> V_LANE IF
  logic                                   vlane_store_dvalid   ; 
  logic                                   vlane_load_rdy       ;
  logic                                   vlane_load_ivalid    ;
  logic                                   vlane_load_last      ;
  // MCU <=> AXIM CONTROL IF [read channel]
  logic                                   ctrl_rstart          ;
  logic                                   ctrl_rdone           ;
  logic                                   rd_tvalid            ;
  logic                                   rd_tready            ;
  logic                                   rd_tlast             ;
  // MCU <=> AXIM CONTROL IF [write channel]
  logic                                   ctrl_wstart          ;
  logic                                   ctrl_wdone           ;
  logic                                   wr_tvalid            ;
  logic                                   wr_tready            ;
  // AXIM_CTRL <=> BUFF_ARRAY IF [write channel]
  logic [C_M_AXI_ADDR_WIDTH-1:0]          ctrl_raddr_offset    ;
  logic [C_XFER_SIZE_WIDTH-1:0]           ctrl_rxfer_size      ;
  logic [C_M_AXI_DATA_WIDTH-1:0]          rd_tdata             ;
  // AXIM_CTRL <=> BUFF_ARRAY IF [read channel]
  logic [C_M_AXI_ADDR_WIDTH-1:0]          ctrl_waddr_offset    ;
  logic [C_XFER_SIZE_WIDTH-1:0]           ctrl_wxfer_size      ;
  logic [C_M_AXI_DATA_WIDTH-1:0]          wr_tdata             ;

  ///////////////////////////////////////////////////////////////////////////////
  // Instantiate DUTs
  ///////////////////////////////////////////////////////////////////////////////

  m_cu #(
  .VLEN                (VLEN),
  .V_LANE_NUM          (V_LANE_NUM),
  .MAX_VECTORS_BUFFD   (MAX_VECTORS_BUFFD),
  .C_M_AXI_ADDR_WIDTH  (C_M_AXI_ADDR_WIDTH),
  .C_M_AXI_DATA_WIDTH  (C_M_AXI_DATA_WIDTH),
  .C_XFER_SIZE_WIDTH   (C_XFER_SIZE_WIDTH)
  ) m_cu_instance (
 .clk                     (clk                 ),
 .rstn                    (rstn                ),
 .mcu_sew_i               (mcu_sew             ),
 .mcu_lmul_i              (mcu_lmul            ),
 .mcu_base_addr_i         (mcu_base_addr       ),
 .mcu_stride_i            (mcu_stride          ),
 .mcu_data_width_i        (mcu_data_width      ),
 .mcu_idx_ld_st_i         (mcu_idx_ld_st       ),
 .mcu_strided_ld_st_i     (mcu_strided_ld_st   ),
 .mcu_unit_ld_st_i        (mcu_unit_ld_st      ),
 .mcu_st_rdy_o            (mcu_st_rdy          ),
 .mcu_st_vld_i            (mcu_st_vld          ),
 .mcu_ld_rdy_o            (mcu_ld_rdy          ),
 .mcu_ld_vld_i            (mcu_ld_vld          ),
 .cfg_vlenb_i             (cfg_vlenb           ),
 .cfg_store_data_lmul_o   (cfg_store_data_lmul ),
 .cfg_store_data_sew_o    (cfg_store_data_sew  ),
 .cfg_store_idx_sew_o     (cfg_store_idx_sew   ),
 .cfg_store_idx_lmul_o    (cfg_store_idx_lmul  ),
 .cfg_load_data_lmul_o    (cfg_load_data_lmul  ),
 .cfg_load_data_sew_o     (cfg_load_data_sew   ),
 .cfg_load_idx_sew_o      (cfg_load_idx_sew    ),
 .cfg_load_idx_lmul_o     (cfg_load_idx_lmul   ),
 .store_cfg_update_o      (store_cfg_update    ),
 .store_cntr_rst_o        (store_cntr_rst      ),
 .store_type_o            (store_type          ),
 .store_stride_o          (store_stride        ),
 .store_baseaddr_o        (store_baseaddr      ),
 .store_baseaddr_update_o (store_baseaddr_update),
 .store_baseaddr_set_o    (store_baseaddr_set  ),
 .sbuff_read_stall_o      (sbuff_read_stall    ),
 .sbuff_read_flush_o      (sbuff_read_flush    ),
 .sbuff_wen_o             (sbuff_wen           ),
 .sbuff_ren_o             (sbuff_ren           ),
 .sbuff_not_empty_i       (sbuff_not_empty     ),
 .sbuff_write_done_i      (sbuff_write_done    ),
 .sbuff_read_done_i       (sbuff_read_done     ),
 .load_cfg_update_o       (load_cfg_update     ),
 .load_cntr_rst_o         (load_cntr_rst       ),
 .load_type_o             (load_type           ),
 .load_stride_o           (load_stride         ),
 .load_baseaddr_o         (load_baseaddr       ),
 .load_baseaddr_set_o     (load_baseaddr_set   ),
 .load_baseaddr_update_o  (load_baseaddr_update),
 .libuff_read_stall_o     (libuff_read_stall   ),
 .libuff_read_flush_o     (libuff_read_flush   ),
 .libuff_wen_o            (libuff_wen          ),
 .libuff_ren_o            (libuff_ren          ),
 .libuff_not_empty_i      (libuff_not_empty    ),
 .libuff_write_done_i     (libuff_write_done   ),
 .libuff_read_done_i      (libuff_read_done    ),
 .ldbuff_read_stall_o     (ldbuff_read_stall   ),
 .ldbuff_read_flush_o     (ldbuff_read_flush   ),
 .ldbuff_wen_o            (ldbuff_wen          ),
 .ldbuff_ren_o            (ldbuff_ren          ),
 .ldbuff_not_empty_i      (ldbuff_not_empty    ),
 .ldbuff_write_done_i     (ldbuff_write_done   ),
 .ldbuff_read_done_i      (ldbuff_read_done    ),
 .vlane_store_dvalid_i    (vlane_store_dvalid  ),
 .vlane_store_rdy_o       (vlane_store_rdy     ),
 .vlane_load_rdy_i        (vlane_load_rdy      ),
 .vlane_load_ivalid_i     (vlane_load_ivalid   ),
 .vlane_load_last_o       (vlane_load_last     ),
 .ctrl_rstart_o           (ctrl_rstart         ),
 .ctrl_rdone_i            (ctrl_rdone          ),
 .rd_tvalid_i             (rd_tvalid           ),
 .rd_tready_o             (rd_tready           ),
 .rd_tlast_i              (rd_tlast            ),
 .ctrl_wstart_o           (ctrl_wstart         ),
 .ctrl_wdone_i            (ctrl_wdone          ),
 .wr_tvalid_o             (wr_tvalid           ),
 .wr_tready_i             (wr_tready           ));

 buff_array #(
  .VLEN               (VLEN              ),
  .V_LANE_NUM         (V_LANE_NUM        ),
  .MAX_VECTORS_BUFFD  (MAX_VECTORS_BUFFD ),
  .C_M_AXI_ADDR_WIDTH (C_M_AXI_ADDR_WIDTH),
  .C_M_AXI_DATA_WIDTH (C_M_AXI_DATA_WIDTH),
  .C_XFER_SIZE_WIDTH  (C_XFER_SIZE_WIDTH )
) buff_array_instance (
 .clk                     (clk                  ),
 .rstn                    (rstn                 ),
 .cfg_vlenb_i             (cfg_vlenb            ),
 .cfg_store_data_lmul_i   (cfg_store_data_lmul  ),
 .cfg_store_idx_lmul_i    (cfg_store_idx_lmul   ),
 .cfg_store_data_sew_i    (cfg_store_data_sew   ),
 .cfg_store_idx_sew_i     (cfg_store_idx_sew    ),
 .cfg_load_data_lmul_i    (cfg_load_data_lmul   ),
 .cfg_load_idx_lmul_i     (cfg_load_idx_lmul    ),
 .cfg_load_data_sew_i     (cfg_load_data_sew    ),
 .cfg_load_idx_sew_i      (cfg_load_idx_sew     ),
 .store_cfg_update_i      (store_cfg_update     ),
 .store_cntr_rst_i        (store_cntr_rst       ),
 .store_type_i            (store_type           ),
 .store_stride_i          (store_stride         ),
 .store_baseaddr_i        (store_baseaddr       ),
 .store_baseaddr_set_i    (store_baseaddr_set   ),
 .store_baseaddr_update_i (store_baseaddr_update),
 .sbuff_read_stall_i      (sbuff_read_stall     ),
 .sbuff_read_flush_i      (sbuff_read_flush     ),
 .sbuff_wen_i             (sbuff_wen            ),
 .sbuff_ren_i             (sbuff_ren            ),
 .sbuff_not_empty_o       (sbuff_not_empty      ),
 .sbuff_write_done_o      (sbuff_write_done     ),
 .sbuff_read_done_o       (sbuff_read_done      ),
 .load_cfg_update_i       (load_cfg_update      ),
 .load_cntr_rst_i         (load_cntr_rst        ),
 .load_type_i             (load_type            ),
 .load_stride_i           (load_stride          ),
 .load_baseaddr_i         (load_baseaddr        ),
 .load_baseaddr_set_i     (load_baseaddr_set    ),
 .load_baseaddr_update_i  (load_baseaddr_update ),
 .ldbuff_read_stall_i     (ldbuff_read_stall    ),
 .ldbuff_read_flush_i     (ldbuff_read_flush    ),
 .libuff_read_stall_i     (libuff_read_stall    ),
 .libuff_read_flush_i     (libuff_read_flush    ),
 .ldbuff_wen_i            (ldbuff_wen           ),
 .ldbuff_ren_i            (ldbuff_ren           ),
 .libuff_wen_i            (libuff_wen           ),
 .libuff_ren_i            (libuff_ren           ),
 .ldbuff_not_empty_o      (ldbuff_not_empty     ),
 .ldbuff_write_done_o     (ldbuff_write_done    ),
 .ldbuff_read_done_o      (ldbuff_read_done     ),
 .libuff_not_empty_o      (libuff_not_empty     ),
 .libuff_write_done_o     (libuff_write_done    ),
 .libuff_read_done_o      (libuff_read_done     ),
 .vlane_store_data_i      (vlane_store_data     ),
 .vlane_store_ptr_i       (vlane_store_ptr      ),
 .vlane_load_data_o       (vlane_load_data      ),
 .vlane_load_valid_o      (vlane_load_valid     ),
 .vlane_load_ptr_i        (vlane_load_ptr       ),
 .ctrl_raddr_offset_o     (ctrl_raddr_offset    ),
 .ctrl_rxfer_size_o       (ctrl_rxfer_size      ),
 .rd_tdata_i              (rd_tdata             ),
 .ctrl_waddr_offset_o     (ctrl_waddr_offset    ),
 .ctrl_wxfer_size_o       (ctrl_wxfer_size      ),
 .wr_tdata_o              (wr_tdata             ));

class vlane_rand;
  rand bit                              vlane_store_dvalid_r    ; 
  rand bit                              vlane_load_rdy_r       ;
endclass

class aximctrl_rand;
  rand bit                              wr_trdy_r    ; 
  rand bit                              rd_tvalid_r  ;
endclass


  //CLOCK DIRVER
  always begin
    clk = #(CLK_PERIOD/2) !clk;
  end

  // RESET DRIVER
  initial
  begin
    rstn = 0;
    #100;
    rstn = 1;
  end
   
  assign cfg_vlenb = 4096;
  // SCHEDULER DRIVER
  initial
  begin
    //Defaults
    mcu_sew              =0;
    mcu_lmul             =0;
    mcu_base_addr        =0;
    mcu_stride           =0;
    mcu_data_width       =0;
    mcu_idx_ld_st        =0;
    mcu_strided_ld_st    =0;
    mcu_unit_ld_st       =0;
    mcu_st_vld           =0;
    mcu_ld_vld           =0;
    @(negedge clk);
    @(posedge rstn);
    @(negedge clk);
    @(negedge clk);
    @(negedge clk);
    mcu_sew              =3'b000;
    mcu_lmul             =3'b000;
    mcu_base_addr        =32'h40000000;
    mcu_stride           =0;
    mcu_data_width       =3'b000;
    mcu_idx_ld_st        =1'b0;
    mcu_strided_ld_st    =1'b0;
    mcu_unit_ld_st       =1'b1;
    mcu_st_vld           =1;
    @(negedge clk);
    mcu_sew              =0;
    mcu_lmul             =0;
    mcu_base_addr        =0;
    mcu_stride           =0;
    mcu_data_width       =0;
    mcu_idx_ld_st        =0;
    mcu_strided_ld_st    =0;
    mcu_unit_ld_st       =0;
    mcu_st_vld           =0;
    mcu_ld_vld           =0;
  end

   
  // LANE INTERFACE

  integer iter=0;
  always begin
    //vlane_rand vlane_r;
    for(int i=0; i<V_LANE_NUM; i++)begin
      vlane_store_data[i]<=iter+i;
      vlane_store_ptr [i]<=iter+i;
      vlane_load_ptr  [i]<=iter+i;
    end
    @(negedge clk);
    vlane_store_dvalid <= $urandom_range(0,1);
    vlane_load_rdy     <= $urandom_range(0,1);
    @(posedge clk);
    if(vlane_store_rdy && vlane_store_dvalid)begin
      iter+=V_LANE_NUM;
    end
  end

   
  // AXIMCTRL INTERFACE
  int word_num  = 0;
  int wait_time = 0;

  always begin
    //aximctrl_rand aximctrl_r;
    wr_tready <= 1'b1;
    rd_tvalid <= 1'b0;
    ctrl_wdone <= 1'b0;
    @(posedge clk);
    if(ctrl_wstart)begin
      while(!ctrl_wdone)begin
        @(negedge clk);
        wr_tready <= $urandom_range(0,1);
        rd_tvalid <= $urandom_range(0,1);
        @(posedge clk);
        if(wr_tvalid && wr_tready)begin
          word_num++;
        end
        if(word_num==(cfg_vlenb/4))begin
          wr_tready <= 1'b0;
          wait_time = $urandom_range(0,10);
          for(int i=0; i<wait_time; i++)
            @(negedge clk);
            ctrl_wdone <= 1'b1;
            @(negedge clk);
            ctrl_wdone <= 1'b0;
        end
      end
    end
  end




 endmodule : m_cu_tb
`default_nettype wire
