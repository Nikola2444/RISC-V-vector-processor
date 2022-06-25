// Coded by Djordje Miseljic | e-mail: djordjemiseljic@uns.ac.rs //////////////////////////////////////////////////////////////////////////////// // default_nettype of none prevents implicit logic declaration.
////////////////////////////////////////////////////////////////////////////////
// default_nettype of none prevents implicit logic declaration.
`default_nettype wire

module mem_subsys #(
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
  output logic 	                                 mcu_ld_buffered_o       ,
  input  logic                                   mcu_ld_vld_i            ,
  // SHEDULER => BUFF_ARRAY CONFIG IF [general]
  input  logic [31:0]                           mcu_vl_i                ,
  // MCU <=> AXIM CONTROL IF [read channel]
  output logic [C_M_AXI_ADDR_WIDTH-1:0]          ctrl_raddr_offset_o     ,
  output logic [C_XFER_SIZE_WIDTH-1:0]           ctrl_rxfer_size_o       ,
  output logic                                   ctrl_rstart_o           ,
  input  logic                                   ctrl_rdone_i            ,
  input  logic [C_M_AXI_DATA_WIDTH-1:0]          rd_tdata_i              ,
  input  logic                                   rd_tvalid_i             ,
  output logic                                   rd_tready_o             ,
  input  logic                                   rd_tlast_i              ,
  // MCU <=> AXIM CONTROL IF [write channel]
  output logic [C_M_AXI_ADDR_WIDTH-1:0]          ctrl_waddr_offset_o     ,
  output logic [C_XFER_SIZE_WIDTH-1:0]           ctrl_wxfer_size_o       ,
  output logic                                   ctrl_wstart_o           ,
  input  logic                                   ctrl_wdone_i            ,
  output logic                                   ctrl_wstrb_msk_en_o  ,
  output logic [C_M_AXI_DATA_WIDTH-1:0]          wr_tdata_o              ,
  output logic                                   wr_tvalid_o             ,
  input  logic                                   wr_tready_i             ,
  output logic [3:0]                             wr_tstrb_msk_o        ,
  // V_LANE <=> BUFF_ARRAY IF [store interface]
  input  logic [31:0]                            vlane_store_data_i [0:VLANE_NUM-1],
  input  logic [31:0]                            vlane_store_idx_i  [0:VLANE_NUM-1],
  input  logic                                   vlane_store_dvalid_i    , 
  input  logic                                   vlane_store_ivalid_i    , 
  output logic                                   vlane_store_rdy_o       , 
  // V_LANE <=> BUFF_ARRAY IF [load interface]
  output logic [31:0]                            vlane_load_data_o  [0:VLANE_NUM-1],
  output logic [3:0]                             vlane_load_bwe_o   [0:VLANE_NUM-1],
  input  logic [31:0]                            vlane_load_idx_i   [0:VLANE_NUM-1],
  input  logic                                   vlane_load_rdy_i        ,
  input  logic                                   vlane_load_ivalid_i     ,
  output logic                                   vlane_load_dvalid_o     ,
  output logic                                   vlane_load_last_o       
);


  ///////////////////////////////////////////////////////////////////////////////
  // Local Signals
  ///////////////////////////////////////////////////////////////////////////////
  // System Signals
  // SHEDULER <=> M_CU CONFIG [general]
  // MCU => BUFF_ARRAY CONFIG IF [stores]
  logic [$clog2(VLEN)-1:0]                cfg_vl            ;
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
  logic                                   sdbuff_read_stall    ;
  logic                                   sdbuff_read_flush    ;
  logic                                   sibuff_read_stall    ;
  logic                                   sibuff_read_flush    ;
  logic                                   sbuff_wen            ;
  logic                                   sdbuff_ren           ;
  logic                                   sibuff_ren           ;
  logic                                   sibuff_not_empty     ;
  logic                                   sdbuff_write_done    ;
  logic                                   sibuff_write_done    ;
  logic                                   sdbuff_read_done     ;
  logic                                   sibuff_read_done     ;
  logic                                   sdbuff_read_rdy      ;
  logic                                   sibuff_read_rdy      ;
  logic                                   libuff_read_rdy      ;
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
  logic                                   ldbuff_wlast         ;
  logic                                   ldbuff_ren           ;
  logic                                   ldbuff_not_empty     ;
  logic                                   ldbuff_write_done    ;
  logic                                   ldbuff_read_done     ;

  ///////////////////////////////////////////////////////////////////////////////
  // Instantiate DUTs
  ///////////////////////////////////////////////////////////////////////////////

  m_cu #(
  .VLEN                (VLEN),
  .VLANE_NUM          (VLANE_NUM),
  .MAX_VECTORS_BUFFD   (MAX_VECTORS_BUFFD),
  .C_M_AXI_ADDR_WIDTH  (C_M_AXI_ADDR_WIDTH),
  .C_M_AXI_DATA_WIDTH  (C_M_AXI_DATA_WIDTH),
  .C_XFER_SIZE_WIDTH   (C_XFER_SIZE_WIDTH)
  ) m_cu_instance (
 .clk                     (clk                    ),
 .rstn                    (rstn                   ),
 .mcu_sew_i               (mcu_sew_i              ),
 .mcu_lmul_i              (mcu_lmul_i             ),
 .mcu_base_addr_i         (mcu_base_addr_i        ),
 .mcu_stride_i            (mcu_stride_i           ),
 .mcu_data_width_i        (mcu_data_width_i       ),
 .mcu_idx_ld_st_i         (mcu_idx_ld_st_i        ),
 .mcu_strided_ld_st_i     (mcu_strided_ld_st_i    ),
 .mcu_unit_ld_st_i        (mcu_unit_ld_st_i       ),
 .mcu_st_rdy_o            (mcu_st_rdy_o           ),
 .mcu_st_vld_i            (mcu_st_vld_i           ),
 .mcu_ld_rdy_o            (mcu_ld_rdy_o           ),
 .mcu_ld_buffered_o       (mcu_ld_buffered_o      ),
 .mcu_ld_vld_i            (mcu_ld_vld_i           ),
 .mcu_vl_i                (mcu_vl_i               ),
 .cfg_vl_o                (cfg_vl                 ),
 .cfg_store_data_lmul_o   (cfg_store_data_lmul    ),
 .cfg_store_data_sew_o    (cfg_store_data_sew     ),
 .cfg_store_idx_sew_o     (cfg_store_idx_sew      ),
 .cfg_store_idx_lmul_o    (cfg_store_idx_lmul     ),
 .cfg_load_data_lmul_o    (cfg_load_data_lmul     ),
 .cfg_load_data_sew_o     (cfg_load_data_sew      ),
 .cfg_load_idx_sew_o      (cfg_load_idx_sew       ),
 .cfg_load_idx_lmul_o     (cfg_load_idx_lmul      ),
 .store_cfg_update_o      (store_cfg_update       ),
 .store_cntr_rst_o        (store_cntr_rst         ),
 .store_type_o            (store_type             ),
 .store_stride_o          (store_stride           ),
 .store_baseaddr_o        (store_baseaddr         ),
 .store_baseaddr_update_o (store_baseaddr_update  ),
 .store_baseaddr_set_o    (store_baseaddr_set     ),
 .sdbuff_read_stall_o     (sdbuff_read_stall      ),
 .sdbuff_read_flush_o     (sdbuff_read_flush      ),
 .sibuff_read_stall_o     (sibuff_read_stall      ),
 .sibuff_read_flush_o     (sibuff_read_flush      ),
 .sbuff_wen_o             (sbuff_wen              ),
 .sdbuff_ren_o            (sdbuff_ren             ),
 .sibuff_ren_o            (sibuff_ren             ),
 .sibuff_not_empty_i      (sibuff_not_empty       ),
 .sdbuff_write_done_i     (sdbuff_write_done      ),
 .sibuff_write_done_i     (sibuff_write_done      ),
 .sdbuff_read_done_i      (sdbuff_read_done       ),
 .sibuff_read_done_i      (sibuff_read_done       ),
 .sdbuff_read_rdy_i       (sdbuff_read_rdy        ),
 .sibuff_read_rdy_i       (sibuff_read_rdy        ),
 .libuff_read_rdy_i       (libuff_read_rdy        ),
 .load_cfg_update_o       (load_cfg_update        ),
 .load_cntr_rst_o         (load_cntr_rst          ),
 .load_type_o             (load_type              ),
 .load_stride_o           (load_stride            ),
 .load_baseaddr_o         (load_baseaddr          ),
 .load_baseaddr_set_o     (load_baseaddr_set      ),
 .load_baseaddr_update_o  (load_baseaddr_update   ),
 .libuff_read_stall_o     (libuff_read_stall      ),
 .libuff_read_flush_o     (libuff_read_flush      ),
 .libuff_wen_o            (libuff_wen             ),
 .libuff_ren_o            (libuff_ren             ),
 .libuff_not_empty_i      (libuff_not_empty       ),
 .libuff_write_done_i     (libuff_write_done      ),
 .libuff_read_done_i      (libuff_read_done       ),
 .ldbuff_read_stall_o     (ldbuff_read_stall      ),
 .ldbuff_read_flush_o     (ldbuff_read_flush      ),
 .ldbuff_wen_o            (ldbuff_wen             ),
 .ldbuff_wlast_o          (ldbuff_wlast           ),
 .ldbuff_ren_o            (ldbuff_ren             ),
 .ldbuff_not_empty_i      (ldbuff_not_empty       ),
 .ldbuff_write_done_i     (ldbuff_write_done      ),
 .ldbuff_read_done_i      (ldbuff_read_done       ),
 .vlane_store_dvalid_i    (vlane_store_dvalid_i   ),
 .vlane_store_ivalid_i    (vlane_store_ivalid_i   ),
 .vlane_store_rdy_o       (vlane_store_rdy_o      ),
 .vlane_load_rdy_i        (vlane_load_rdy_i       ),
 .vlane_load_ivalid_i     (vlane_load_ivalid_i    ),
 .vlane_load_dvalid_o     (vlane_load_dvalid_o    ),
 .vlane_load_last_o       (vlane_load_last_o      ),
 .ctrl_rstart_o           (ctrl_rstart_o          ),
 .ctrl_rdone_i            (ctrl_rdone_i           ),
 .rd_tvalid_i             (rd_tvalid_i            ),
 .rd_tready_o             (rd_tready_o            ),
 .rd_tlast_i              (rd_tlast_i             ),
 .ctrl_wstart_o           (ctrl_wstart_o          ),
 .ctrl_wdone_i            (ctrl_wdone_i           ),
 .wr_tvalid_o             (wr_tvalid_o            ),
 .wr_tready_i             (wr_tready_i            ));







 buff_array #(
  .VLEN               (VLEN              ),
  .VLANE_NUM          (VLANE_NUM         ),
  .MAX_VECTORS_BUFFD  (MAX_VECTORS_BUFFD ),
  .C_M_AXI_ADDR_WIDTH (C_M_AXI_ADDR_WIDTH),
  .C_M_AXI_DATA_WIDTH (C_M_AXI_DATA_WIDTH),
  .C_XFER_SIZE_WIDTH  (C_XFER_SIZE_WIDTH )
) buff_array_instance (
 .clk                     (clk                    ),
 .rstn                    (rstn                   ),
 .cfg_vl_i                (cfg_vl                 ),
 .cfg_store_data_lmul_i   (cfg_store_data_lmul    ),
 .cfg_store_idx_lmul_i    (cfg_store_idx_lmul     ),
 .cfg_store_data_sew_i    (cfg_store_data_sew     ),
 .cfg_store_idx_sew_i     (cfg_store_idx_sew      ),
 .cfg_load_data_lmul_i    (cfg_load_data_lmul     ),
 .cfg_load_idx_lmul_i     (cfg_load_idx_lmul      ),
 .cfg_load_data_sew_i     (cfg_load_data_sew      ),
 .cfg_load_idx_sew_i      (cfg_load_idx_sew       ),
 .store_cfg_update_i      (store_cfg_update       ),
 .store_cntr_rst_i        (store_cntr_rst         ),
 .store_type_i            (store_type             ),
 .store_stride_i          (store_stride           ),
 .store_baseaddr_i        (store_baseaddr         ),
 .store_baseaddr_set_i    (store_baseaddr_set     ),
 .store_baseaddr_update_i (store_baseaddr_update  ),
 .sdbuff_read_stall_i     (sdbuff_read_stall      ),
 .sdbuff_read_flush_i     (sdbuff_read_flush      ),
 .sibuff_read_stall_i     (sibuff_read_stall      ),
 .sibuff_read_flush_i     (sibuff_read_flush      ),
 .sbuff_wen_i             (sbuff_wen              ),
 .sdbuff_ren_i            (sdbuff_ren             ),
 .sibuff_ren_i            (sibuff_ren             ),
 .sibuff_not_empty_o      (sibuff_not_empty       ),
 .sdbuff_write_done_o     (sdbuff_write_done      ),
 .sibuff_write_done_o     (sibuff_write_done      ),
 .sdbuff_read_done_o      (sdbuff_read_done       ),
 .sibuff_read_done_o      (sibuff_read_done       ),
 .sdbuff_read_rdy_o       (sdbuff_read_rdy        ),
 .sibuff_read_rdy_o       (sibuff_read_rdy        ),
 .libuff_read_rdy_o       (libuff_read_rdy        ),
 .load_cfg_update_i       (load_cfg_update        ),
 .load_cntr_rst_i         (load_cntr_rst          ),
 .load_type_i             (load_type              ),
 .load_stride_i           (load_stride            ),
 .load_baseaddr_i         (load_baseaddr          ),
 .load_baseaddr_set_i     (load_baseaddr_set      ),
 .load_baseaddr_update_i  (load_baseaddr_update   ),
 .ldbuff_read_stall_i     (ldbuff_read_stall      ),
 .ldbuff_read_flush_i     (ldbuff_read_flush      ),
 .libuff_read_stall_i     (libuff_read_stall      ),
 .libuff_read_flush_i     (libuff_read_flush      ),
 .ldbuff_wen_i            (ldbuff_wen             ),
 .ldbuff_wlast_i          (ldbuff_wlast           ),
 .ldbuff_ren_i            (ldbuff_ren             ),
 .libuff_wen_i            (libuff_wen             ),
 .libuff_ren_i            (libuff_ren             ),
 .ldbuff_not_empty_o      (ldbuff_not_empty       ),
 .ldbuff_write_done_o     (ldbuff_write_done      ),
 .ldbuff_read_done_o      (ldbuff_read_done       ),
 .libuff_not_empty_o      (libuff_not_empty       ),
 .libuff_write_done_o     (libuff_write_done      ),
 .libuff_read_done_o      (libuff_read_done       ),
 .vlane_store_data_i      (vlane_store_data_i     ),
 .vlane_store_idx_i       (vlane_store_idx_i      ),
 .vlane_load_data_o       (vlane_load_data_o      ),
 .vlane_load_bwe_o        (vlane_load_bwe_o       ),
 .vlane_load_idx_i        (vlane_load_idx_i       ),
 .ctrl_raddr_offset_o     (ctrl_raddr_offset_o    ),
 .ctrl_rxfer_size_o       (ctrl_rxfer_size_o      ),
 .rd_tdata_i              (rd_tdata_i             ),
 .ctrl_waddr_offset_o     (ctrl_waddr_offset_o    ),
 .ctrl_wxfer_size_o       (ctrl_wxfer_size_o      ),
 .ctrl_wstrb_msk_en_o     (ctrl_wstrb_msk_en_o    ),
 .wr_tstrb_msk_o          (wr_tstrb_msk_o         ),
 .wr_tdata_o              (wr_tdata_o             ));


 endmodule : mem_subsys
`default_nettype wire
