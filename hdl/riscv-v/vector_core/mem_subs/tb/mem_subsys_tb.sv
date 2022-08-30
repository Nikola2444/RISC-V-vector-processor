// Coded by Djordje Miseljic | e-mail: djordjemiseljic@uns.ac.rs //////////////////////////////////////////////////////////////////////////////// // default_nettype of none prevents implicit logic declaration.
////////////////////////////////////////////////////////////////////////////////
// default_nettype of none prevents implicit logic declaration.
`default_nettype wire

// WHATWHAT
module m_cu_tb();

  localparam integer CLK_PERIOD               = 20;
  ///////////////////////////////////////////////////////////////////////////////
  // Local Parameters
  ///////////////////////////////////////////////////////////////////////////////
  localparam integer VLEN                     = 16384;
  localparam integer VLANE_NUM                = 8;
  localparam integer MAX_VECTORS_BUFFD        = 1;
  localparam integer C_M_AXI_ADDR_WIDTH       = 32;
  localparam integer C_M_AXI_DATA_WIDTH       = 32;
  localparam integer C_XFER_SIZE_WIDTH        = 32;

  ///////////////////////////////////////////////////////////////////////////////
  // Local Signals
  ///////////////////////////////////////////////////////////////////////////////
  // System Signals
  logic                                   clk                 =1'b0;
  logic                                   rstn                =1'b0;
  // SHEDULER <=> M_CU CONFIG [general]
  logic [31:0]                            mcu_vl               ;
  logic [ 2:0]                            mcu_sew              ;
  logic [ 2:0]                            mcu_lmul             ;
  logic [31:0]                            mcu_base_addr        ;
  logic [31:0]                            mcu_stride           ;
  logic [ 2:0]                            mcu_data_width       ;
  logic                                   mcu_idx_ld_st        ;
  logic                                   mcu_strided_ld_st    ;
  logic                                   mcu_unit_ld_st       ;
  // SHEDULER <=> M_CU CONFIG HS [stores]
  logic                                   mcu_st_rdy           ;
  logic                                   mcu_st_vld           ;
  // SHEDULER <=> M_CU CONFIG HS [loads]
  logic                                   mcu_ld_rdy           ;
  logic                                   mcu_ld_vld           ;
  logic                                   mcu_ld_buffered      ;

  // V_LANE INTERFACE
  logic                                   vlane_store_rdy      ; 
  logic [VLANE_NUM-1:0][31:0]             vlane_store_data     ;
  logic [VLANE_NUM-1:0][31:0]             vlane_store_idx      ;
  logic [VLANE_NUM-1:0][31:0]             vlane_load_data      ;
  logic [VLANE_NUM-1:0][3:0]              vlane_load_bwe       ;
  logic [VLANE_NUM-1:0][31:0]             vlane_load_idx       ;
  logic                                   vlane_store_dvalid   ; 
  logic                                   vlane_store_ivalid   ; 
  logic                                   vlane_load_rdy       ;
  logic                                   vlane_load_ivalid    ;
  logic                                   vlane_load_dvalid    ;
  logic                                   vlane_load_last      ;
  // AXIM CONTROL IF [read channel]
  logic [C_M_AXI_ADDR_WIDTH-1:0]          ctrl_raddr_offset    ;
  logic [C_XFER_SIZE_WIDTH-1:0]           ctrl_rxfer_size      ;
  logic [C_M_AXI_DATA_WIDTH-1:0]          rd_tdata             ;
  logic                                   ctrl_rstart          ;
  logic                                   ctrl_rdone           ;
  logic                                   rd_tvalid            ;
  logic                                   rd_tready            ;
  logic                                   rd_tlast             ;
  // AXIM CONTROL IF [write channel]
  logic [C_M_AXI_ADDR_WIDTH-1:0]          ctrl_waddr_offset    ;
  logic [C_XFER_SIZE_WIDTH-1:0]           ctrl_wxfer_size      ;
  logic [C_M_AXI_DATA_WIDTH-1:0]          wr_tdata             ;
  logic                                   ctrl_wstart          ;
  logic                                   ctrl_wdone           ;
  logic                                   wr_tvalid            ;
  logic                                   wr_tready            ;
  // AXIM_CTRL <=> BUFF_ARRAY IF [write channel]
  // AXIM_CTRL <=> BUFF_ARRAY IF [read channel]

  ///////////////////////////////////////////////////////////////////////////////
  // Instantiate DUTs
  ///////////////////////////////////////////////////////////////////////////////

mem_subsys #(
  .VLEN               (VLEN              ),
  .VLANE_NUM          (VLANE_NUM        ),
  .MAX_VECTORS_BUFFD  (MAX_VECTORS_BUFFD ),
  .C_M_AXI_ADDR_WIDTH (C_M_AXI_ADDR_WIDTH),
  .C_M_AXI_DATA_WIDTH (C_M_AXI_DATA_WIDTH),
  .C_XFER_SIZE_WIDTH  (C_XFER_SIZE_WIDTH )
)mem_subsys_inst
(
 .clk                  (clk                 ),
 .rstn                 (rstn                ),
 .mcu_sew_i            (mcu_sew             ),
 .mcu_lmul_i           (mcu_lmul            ),
 .mcu_base_addr_i      (mcu_base_addr       ),
 .mcu_stride_i         (mcu_stride          ),
 .mcu_data_width_i     (mcu_data_width      ),
 .mcu_idx_ld_st_i      (mcu_idx_ld_st       ),
 .mcu_strided_ld_st_i  (mcu_strided_ld_st   ),
 .mcu_unit_ld_st_i     (mcu_unit_ld_st      ),
 .mcu_st_rdy_o         (mcu_st_rdy          ),
 .mcu_st_vld_i         (mcu_st_vld          ),
 .mcu_ld_rdy_o         (mcu_ld_rdy          ),
 .mcu_ld_buffered_o    (mcu_ld_buffered     ),
 .mcu_ld_vld_i         (mcu_ld_vld          ),
 .mcu_vl_i             (mcu_vl              ),
 .ctrl_raddr_offset_o  (ctrl_raddr_offset   ),
 .ctrl_rxfer_size_o    (ctrl_rxfer_size     ),
 .ctrl_rstart_o        (ctrl_rstart         ),
 .ctrl_rdone_i         (ctrl_rdone          ),
 .rd_tdata_i           (rd_tdata            ),
 .rd_tvalid_i          (rd_tvalid           ),
 .rd_tready_o          (rd_tready           ),
 .rd_tlast_i           (rd_tlast            ),
 .ctrl_waddr_offset_o  (ctrl_waddr_offset   ),
 .ctrl_wxfer_size_o    (ctrl_wxfer_size     ),
 .ctrl_wstart_o        (ctrl_wstart         ),
 .ctrl_wdone_i         (ctrl_wdone          ),
 .wr_tdata_o           (wr_tdata            ),
 .wr_tvalid_o          (wr_tvalid           ),
 .wr_tready_i          (wr_tready           ),
 .vlane_store_data_i   (vlane_store_data    ),
 .vlane_store_idx_i    (vlane_store_idx     ),
 .vlane_store_dvalid_i (vlane_store_dvalid  ),
 .vlane_store_ivalid_i (vlane_store_ivalid  ),
 .vlane_store_rdy_o    (vlane_store_rdy     ),
 .vlane_load_data_o    (vlane_load_data     ),
 .vlane_load_bwe_o     (vlane_load_bwe      ),
 .vlane_load_idx_i     (vlane_load_idx      ),
 .vlane_load_rdy_i     (vlane_load_rdy      ),
 .vlane_load_ivalid_i  (vlane_load_ivalid   ),
 .vlane_load_dvalid_o  (vlane_load_dvalid   ),
 .vlane_load_last_o    (vlane_load_last     )
);

  //CLOCK DIRVER
  always begin
    clk = #(CLK_PERIOD/2) !clk;
  end

  // RESET DRIVER
  initial
  begin
    rstn <= 0;
    #100;
    rstn <= 1;
  end
   
   // NOTE: CHANGE TIS CONFIGURATION TOO !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  assign mcu_vl = 32;
  int sew_in_bytes = 1;
  int store1_load2 = 1;
  int unit1_stride2_index3 = 1;
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
    if(sew_in_bytes==1)begin
        mcu_sew              <=3'b000;
        mcu_data_width       <=3'b000;
    end
    else if(sew_in_bytes==2) begin
        mcu_sew              <=3'b001;
        mcu_data_width       <=3'b001;
    end
    else begin
        mcu_sew              <=3'b010;
        mcu_data_width       <=3'b010;
    end
    if(store1_load2 == 1)begin
        mcu_st_vld           =1;
        mcu_ld_vld           =0;
    end
    else begin
        mcu_st_vld           =0;
        mcu_ld_vld           =1;
    end
    if (unit1_stride2_index3==1)    begin
        mcu_unit_ld_st       =1'b1;
        mcu_strided_ld_st    =1'b0;
        mcu_idx_ld_st        =1'b0;
    end
    else if (unit1_stride2_index3==2)    begin 
        mcu_unit_ld_st       =1'b0;
        mcu_strided_ld_st    =1'b1;
        mcu_idx_ld_st        =1'b0;
    end
    else begin
        mcu_unit_ld_st       =1'b0;
        mcu_strided_ld_st    =1'b0;
        mcu_idx_ld_st        =1'b1;
    
    end
    mcu_lmul             =3'b000;
    mcu_base_addr        =32'h40000000;
    mcu_stride           =8;


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

   
   // STORE SIGNAL INTERFACE ************************************
  // LANE INTERFACE
  integer iter=0;
  always begin
    for(int i=0; i<VLANE_NUM; i++)begin
      vlane_store_data[i][0+:8]  <= (iter+i);
      vlane_store_data[i][8+:8]  <= (iter+1*VLANE_NUM+i);
      vlane_store_data[i][16+:8] <= (iter+2*VLANE_NUM+i);
      vlane_store_data[i][24+:8] <= (iter+3*VLANE_NUM+i);
      if(i==0)begin
      vlane_store_idx[i][0+:8]  <= (iter*4+4);
      vlane_store_idx[i][8+:8]  <= (iter*4+8);
      vlane_store_idx[i][16+:8] <= (iter*4+12);
      vlane_store_idx[i][24+:8] <= (iter*4+16);
      end
      else
      begin
      vlane_store_idx[i][0+:8]  <= (0);
      vlane_store_idx[i][8+:8]  <= (0);
      vlane_store_idx[i][16+:8] <= (0);
      vlane_store_idx[i][24+:8] <= (0);
      end
    end
    @(negedge clk);
    vlane_store_dvalid <= $urandom_range(0,1);
    vlane_load_rdy     <= $urandom_range(0,1);
    @(posedge clk);
    if(vlane_store_rdy && vlane_store_dvalid)begin
      iter+=4*VLANE_NUM;
    end
  end

 /*  
  // AXIMCTRL WRITE INTERFACE
  int wait_time = 0;
  int write_word_num  = 0;
  always begin
    wr_tready <= 1'b1;
    ctrl_wdone <= 1'b0;
    @(posedge clk);
    if(ctrl_wstart)begin
      while(!ctrl_wdone)begin
        @(negedge clk);
        wr_tready <= $urandom_range(0,1);
        @(posedge clk);
        if(wr_tvalid && wr_tready)begin
          write_word_num+=(4/sew_in_bytes);
        end
        //if(write_word_num==(mcu_vl-(4/sew_in_bytes)))begin
        if(write_word_num==1)begin
          wr_tready <= 1'b0;
          wait_time = $urandom_range(0,10);
          for(int i=0; i<wait_time; i++) @(negedge clk);
          ctrl_wdone <= 1'b1;
        end
      end
      @(negedge clk);
      ctrl_wdone <= 1'b0;
      write_word_num<=0;
    end
  end
*/
  
  // AXIMCTRL WRITE INTERFACE
  int wait_time = 0;
  int write_word_num  = 0;
always begin
    wr_tready <= 1'b0;
    ctrl_wdone <= 1'b0;
    write_word_num = 0;
    @(posedge clk);
    if(ctrl_wstart)begin
    $display("wstart");
      while(!ctrl_wdone)begin
        wr_tready <= $urandom_range(0,1);
        @(posedge clk);
        if(wr_tvalid && wr_tready)begin 
          write_word_num+=(4);     
        end
        //if(write_word_num==(mcu_vl-(4/sew_in_bytes)))begin
        if(write_word_num>=ctrl_wxfer_size)begin
          wr_tready <= #1 1'b0;
          wait_time = $urandom_range(2,10);
          for(int i=0; i<wait_time; i++) @(negedge clk);
          ctrl_wdone <= 1'b1;
           $display("wdone");
          @(posedge ctrl_wdone);
        end
        
      end
      @(negedge clk);
      ctrl_wdone <= 1'b0;
      write_word_num =0;
    end
  end

  // LOAD SIGNAL INTERFACE ************************************
  // LANE INTERFACE
  
  integer iiter=0;
  always begin
    vlane_load_ivalid <= 1'b1;
    for(int i=0; i<VLANE_NUM; i++)begin
      if(i==0)begin
      vlane_load_idx[i][0+:8]  <= (iiter*4+4);
      vlane_load_idx[i][8+:8]  <= (iiter*4+8);
      vlane_load_idx[i][16+:8] <= (iiter*4+12);
      vlane_load_idx[i][24+:8] <= (iiter*4+16);
      end
      else
      begin
      vlane_load_idx[i][0+:8]  <= (0);
      vlane_load_idx[i][8+:8]  <= (0);
      vlane_load_idx[i][16+:8] <= (0);
      vlane_load_idx[i][24+:8] <= (0);
      end
    end
    @(negedge clk);
    @(posedge clk);
    iiter+=4*VLANE_NUM;
  end

  always begin
    vlane_load_rdy    <= 1'b0;
    @(negedge clk);
    @(posedge mcu_ld_buffered);
    vlane_load_rdy <= 1'b1;
  end

   int  iteration = 0;
  // AXIMCTRL READ INTERFACE
  logic [31:0] read_data_word;
  int read_word_num = 0;
  int read_wait_time = 0;
  always begin
    rd_tvalid   <= 1'b0;
    rd_tlast    <= 1'b0;
    ctrl_rdone  <= 1'b0;
    read_word_num <= 1'b0;
    rd_tdata    <= 0;
    @(posedge clk);
    if(ctrl_rstart)begin
      read_wait_time <= $urandom_range(4,10);
      for(int i=0; i<read_wait_time; i++) @(negedge clk);
      while(!ctrl_rdone)begin
        //$display("while");
        @(negedge clk);
        rd_tvalid <= $urandom_range(0,1);
        if((read_word_num+4)>=(ctrl_rxfer_size))
        rd_tlast        <= 1'b1;
        rd_tdata[0+:8]  <= (iteration+0);
        rd_tdata[8+:8]  <= (iteration+1);
        rd_tdata[16+:8] <= (iteration+2);
        rd_tdata[24+:8] <= (iteration+3);
        
        @(posedge clk);
        if(rd_tvalid && rd_tready) begin
           read_word_num+=(4); 
            if(unit1_stride2_index3==1)begin
               //read_word_num+=(4); 
                iteration+=4;
            end
            else begin
                //read_word_num+=(sew_in_bytes);
                iteration+=sew_in_bytes;
            end
        end
        if(read_word_num>=(ctrl_rxfer_size))begin
          rd_tvalid   <= 1'b0;
          rd_tlast    <= 1'b0;
          ctrl_rdone  <= 1'b1;
        end
      end
      @(negedge clk);
      ctrl_rdone <= 1'b0;
      read_word_num <= 0;
    end
  end

 endmodule : m_cu_tb
`default_nettype wire
