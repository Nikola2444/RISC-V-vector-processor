//`define INCLUDE_AXIL_IF
//`define INCLUDE_DBG_SIGNALS

module riscv_v_w_mem_subsystem #
  (  
     parameter integer VLEN = 4096,
     parameter integer V_LANES = 4,
     parameter integer CHAINING = 4,
     parameter integer C_BLOCK_SIZE = 64,
     parameter integer C_LVL1_CACHE_SIZE = (1024*1),
     parameter integer C_LVL2_CACHE_SIZE = (1024*4),
     parameter integer C_LVL2_CACHE_NWAY = 4
  ) (
  `ifdef INCLUDE_AXIL_IF
    s_axi_aclk, s_axi_rready, s_axi_aresetn, s_axi_awaddr, s_axi_awprot,
    s_axi_awvalid, s_axi_awready, s_axi_wdata, s_axi_wstrb, s_axi_wvalid,
    s_axi_wready, s_axi_bresp, s_axi_bvalid, s_axi_bready, s_axi_araddr,
    s_axi_arprot, s_axi_arvalid, s_axi_arready, s_axi_rdata, s_axi_rresp,
    s_axi_rvalid,
  `else 
    ce, axi_base_address, pc_reg,
  `endif
  `ifdef INCLUDE_DBG_SIGNALS
  lane0_load_dvalid,lane0_load_data,lane0_store_data,lane0_store_dvalid,
  vrf0_wdata0,vrf0_wdata1,vrf0_wdata2,vrf0_wdata3,
  vrf0_waddr0,vrf0_waddr1,vrf0_waddr2,vrf0_waddr3,
  vrf0_bwen0,vrf0_bwen1,vrf0_bwen2,vrf0_bwen3,
  vrf0_rdata0,vrf0_rdata1,vrf0_rdata2,vrf0_rdata3,vrf0_rdata4,vrf0_rdata5,vrf0_rdata6,vrf0_rdata7,
  vrf0_raddr0,vrf0_raddr1,vrf0_raddr2,vrf0_raddr3,vrf0_raddr4,vrf0_raddr5,vrf0_raddr6,vrf0_raddr7,
  vrf0_ren,vrf0_oreg_ren,
  vlane0_st_data0,vlane0_st_data1,vlane0_st_data2,vlane0_st_data3,vlane0_st_drvr,
  vlane0_store_data_out2,sew,lmul,vl,vlane0_store_data_mux2_4,vlane0_store_data_mux_sel2,
  vlane0_read_data_mux4,vlane0_read_data_prep_reg,multipump_sel_reg,
  `endif
  /*AUTOARG*/
	// Outputs
	v_m_axi_awvalid, v_m_axi_awaddr, v_m_axi_awlen, v_m_axi_wvalid,
	v_m_axi_wdata, v_m_axi_wstrb, v_m_axi_wlast, v_m_axi_arvalid,
	v_m_axi_araddr, v_m_axi_arlen, v_m_axi_rready, v_m_axi_bready,
	s_m_axi_awvalid, s_m_axi_awaddr, s_m_axi_awlen, s_m_axi_wvalid,
	s_m_axi_wdata, s_m_axi_wstrb, s_m_axi_wlast, s_m_axi_arvalid,
	s_m_axi_araddr, s_m_axi_arlen, s_m_axi_rready, s_m_axi_bready,
	s_m_axi_awid, s_m_axi_awsize, s_m_axi_awburst, s_m_axi_awlock,
	s_m_axi_awcache, s_m_axi_awprot, s_m_axi_awqos, s_m_axi_awuser,
	s_m_axi_wuser, s_m_axi_arid, s_m_axi_arsize, s_m_axi_arburst,
	s_m_axi_arlock, s_m_axi_arcache, s_m_axi_arprot, s_m_axi_arqos,
	s_m_axi_aruser,
	// Inputs
	clk, clk2, rstn, v_m_axi_awready, v_m_axi_wready, v_m_axi_arready,
	v_m_axi_rvalid, v_m_axi_rdata, v_m_axi_rlast, v_m_axi_bvalid,
	s_m_axi_awready, s_m_axi_wready, s_m_axi_arready, s_m_axi_rvalid,
	s_m_axi_rdata, s_m_axi_rlast, s_m_axi_bvalid, s_m_axi_bid,
	s_m_axi_bresp, s_m_axi_buser, s_m_axi_rid, s_m_axi_rresp,
	s_m_axi_ruser
	);
    localparam C_S_AXI_DATA_WIDTH = 32;
    localparam C_S_AXI_ADDR_WIDTH = 4;
    localparam C_M_AXI_DATA_WIDTH = 32;
    localparam C_M_AXI_ADDR_WIDTH = 32;
    localparam C_M_AXI_ID_WIDTH   = 4;
   localparam C_XFER_SIZE_WIDTH  = 32;
    localparam C_M_AXI_BURST_LEN  = (C_BLOCK_SIZE/4);

    localparam C_PHY_ADDR_WIDTH   = 32;

    localparam C_M_AXI_AWUSER_WIDTH = 4;
    localparam C_M_AXI_ARUSER_WIDTH = 4;
    localparam C_M_AXI_WUSER_WIDTH  = 4;
    localparam C_M_AXI_RUSER_WIDTH  = 4;
    localparam C_M_AXI_BUSER_WIDTH  = 4;

    input 	       clk;
    input 	       clk2;
    input 	       rstn;
    // AXI FULL VECTOR CORE IF
    output logic        v_m_axi_awvalid ;
    input  logic 	       v_m_axi_awready ;
    output logic [C_M_AXI_ADDR_WIDTH-1:0] v_m_axi_awaddr ;
    output logic [8-1:0] 		 v_m_axi_awlen ;
    output logic 			 v_m_axi_wvalid ;
    input  logic 				 v_m_axi_wready ;
    output logic [C_M_AXI_DATA_WIDTH-1:0] v_m_axi_wdata ;
    output logic [C_M_AXI_DATA_WIDTH/8-1:0] v_m_axi_wstrb ;
    output logic 			   v_m_axi_wlast ;
    output logic 			   v_m_axi_arvalid ;
    input  logic 				   v_m_axi_arready ;
    output logic [C_M_AXI_ADDR_WIDTH-1:0]   v_m_axi_araddr ;
    output logic [8-1:0] 		   v_m_axi_arlen ;
    input  logic 				   v_m_axi_rvalid ;
    output logic 			   v_m_axi_rready ;
    input  logic [C_M_AXI_DATA_WIDTH-1:0]    v_m_axi_rdata ;
    input  logic 				   v_m_axi_rlast ;
    input  logic 				   v_m_axi_bvalid ;
    output logic 			   v_m_axi_bready;
    //AXI FULL SCALAR CORE IF
    output logic 			   s_m_axi_awvalid ;
    input  logic 				   s_m_axi_awready ;
    output logic [C_M_AXI_ADDR_WIDTH-1:0]   s_m_axi_awaddr ;
    output logic [8-1:0] 		   s_m_axi_awlen ;
    output logic 			   s_m_axi_wvalid ;
    input  logic 				   s_m_axi_wready ;
    output logic [C_M_AXI_DATA_WIDTH-1:0]   s_m_axi_wdata ;
    output logic [C_M_AXI_DATA_WIDTH/8-1:0] s_m_axi_wstrb ;
    output logic 			   s_m_axi_wlast ;
    output logic 			   s_m_axi_arvalid ;
    input  logic 				   s_m_axi_arready ;
    output logic [C_M_AXI_ADDR_WIDTH-1:0]   s_m_axi_araddr ;
    output logic [8-1:0] 		   s_m_axi_arlen ;
    input  logic 				   s_m_axi_rvalid ;
    output logic 			   s_m_axi_rready ;
    input  logic [C_M_AXI_DATA_WIDTH-1:0]    s_m_axi_rdata ;
    input  logic 				   s_m_axi_rlast ;
    input  logic 				   s_m_axi_bvalid ;
    output logic 			   s_m_axi_bready;
    output logic [C_M_AXI_ID_WIDTH-1 : 0]   s_m_axi_awid;
    output logic [2 : 0] 		   s_m_axi_awsize;
    output logic [1 : 0] 		   s_m_axi_awburst;
    output logic 			   s_m_axi_awlock;
    output logic [3 : 0] 		   s_m_axi_awcache;
    output logic [2 : 0] 		   s_m_axi_awprot;
    output logic [3 : 0] 		   s_m_axi_awqos;
    output logic [C_M_AXI_AWUSER_WIDTH-1 : 0] s_m_axi_awuser;
    output logic [C_M_AXI_WUSER_WIDTH-1 : 0]  s_m_axi_wuser;
    input  logic [C_M_AXI_ID_WIDTH-1 : 0]      s_m_axi_bid ;
    input  logic [1 : 0] 			     s_m_axi_bresp;
    input  logic [C_M_AXI_BUSER_WIDTH-1 : 0]   s_m_axi_buser;
    output logic [C_M_AXI_ID_WIDTH-1 : 0]     s_m_axi_arid;
    output logic [2 : 0] 		     s_m_axi_arsize;
    output logic [1 : 0] 		     s_m_axi_arburst;
    output logic 			     s_m_axi_arlock;
    output logic [3 : 0] 		     s_m_axi_arcache;
    output logic [2 : 0] 		     s_m_axi_arprot;
    output logic [3 : 0] 		     s_m_axi_arqos;
    output logic [C_M_AXI_ARUSER_WIDTH-1 : 0] s_m_axi_aruser;
    input  logic [C_M_AXI_ID_WIDTH-1 : 0]      s_m_axi_rid;
    input  logic [1 : 0] 			     s_m_axi_rresp;
    input  logic [C_M_AXI_RUSER_WIDTH-1 : 0]   s_m_axi_ruser;
// AXI LITE IF; TO BE INSERTED
// THESE WILL BE AXI LITE REGISTERS
    `ifdef INCLUDE_AXIL_IF 
    input  logic s_axi_aclk;
    input  logic s_axi_aresetn;
    input  logic [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_awaddr;
    input  logic s_axi_awprot;
    input  logic s_axi_awvalid;
    output logic s_axi_awready;
    input  logic [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata;
    input  logic [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb;
    input  logic s_axi_wvalid;
    output logic s_axi_wready;
    output logic [1 : 0]s_axi_bresp;
    output logic s_axi_bvalid;
    input  logic s_axi_bready;
    input  logic [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr;
    input  logic [2 : 0] s_axi_arprot;
    input  logic s_axi_arvalid;
    output logic s_axi_arready;
    output logic [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata;
    output logic [1 : 0] s_axi_rresp;
    output logic s_axi_rvalid;
    input  logic s_axi_rready;
    `else
    input  logic 				           ce;               // will be clock enable to start/stop processor
    input  logic [31:0] 			     axi_base_address; // will be the starting address in DDR of machine code 
    output logic [31:0] 			     pc_reg;           // will be just a way to see from sogtware where the PC is currently
    `endif

    `ifdef INCLUDE_DBG_SIGNALS
    output logic [31:0] 			     lane0_store_data; 
    output logic         			     lane0_store_dvalid;
    output logic [31:0] 			     lane0_load_data;  
    output logic         			     lane0_load_dvalid;


    output logic [9:0]	       vrf0_raddr0; 
    output logic [9:0]	       vrf0_raddr1; 
    output logic [9:0]	       vrf0_raddr2; 
    output logic [9:0]	       vrf0_raddr3; 
    output logic [9:0]	       vrf0_raddr4; 
    output logic [9:0]	       vrf0_raddr5; 
    output logic [9:0]	       vrf0_raddr6; 
    output logic [9:0]	       vrf0_raddr7; 
    output logic         			 vrf0_ren;
    output logic         			 vrf0_oreg_ren;
    output logic [31:0]        vrf0_rdata0;  
    output logic [31:0]        vrf0_rdata1;  
    output logic [31:0]        vrf0_rdata2;  
    output logic [31:0]        vrf0_rdata3;  
    output logic [31:0]        vrf0_rdata4;  
    output logic [31:0]        vrf0_rdata5;  
    output logic [31:0]        vrf0_rdata6;  
    output logic [31:0]        vrf0_rdata7;  

    output logic [9:0]        vrf0_waddr0;
    output logic [9:0]        vrf0_waddr1;
    output logic [9:0]        vrf0_waddr2;
    output logic [9:0]        vrf0_waddr3;
    output logic [3:0]        vrf0_bwen0;
    output logic [3:0]        vrf0_bwen1;
    output logic [3:0]        vrf0_bwen2;
    output logic [3:0]        vrf0_bwen3;
    output logic [31:0]       vrf0_wdata0;
    output logic [31:0]       vrf0_wdata1;
    output logic [31:0]       vrf0_wdata2;
    output logic [31:0]       vrf0_wdata3;
    output logic [31:0]       vlane0_st_data0;
    output logic [31:0]       vlane0_st_data1;
    output logic [31:0]       vlane0_st_data2;
    output logic [31:0]       vlane0_st_data3;
    output logic [1:0]        vlane0_st_drvr;
    output logic [31:0]       vlane0_store_data_out2;
    output logic [31:0]       vlane0_store_data_mux2_4;
    output logic [2:0]        vlane0_store_data_mux_sel2;
    output logic [31:0]       vlane0_read_data_mux4;
    output logic [95:0]       vlane0_read_data_prep_reg;

    output logic [2:0]        sew;
    output logic [2:0]        lmul;
    output logic [31:0]       vl;
    output logic              multipump_sel_reg;

    assign lane0_store_data   = riscv_v_inst.vector_core_inst.mcu_store_data[0];
    assign lane0_store_dvalid = riscv_v_inst.vector_core_inst.vlane_mcu_store_dvalid;
    assign lane0_load_data    = riscv_v_inst.vector_core_inst.mcu_load_data[0];
    assign lane0_load_dvalid  = riscv_v_inst.vector_core_inst.vlane_load_dvalid;

    assign vrf0_raddr0     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_raddr_i[0];
    assign vrf0_raddr1     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_raddr_i[1];
    assign vrf0_raddr2     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_raddr_i[2];
    assign vrf0_raddr3     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_raddr_i[3];
    assign vrf0_raddr4     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_raddr_i[4];
    assign vrf0_raddr5     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_raddr_i[5];
    assign vrf0_raddr6     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_raddr_i[6];
    assign vrf0_raddr7     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_raddr_i[7];
    assign vrf0_ren        = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_ren_i;
    assign vrf0_oreg_ren   = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_oreg_ren_i;
    assign vrf0_rdata0     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_rdata[0];
    assign vrf0_rdata1     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_rdata[1];
    assign vrf0_rdata2     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_rdata[2];
    assign vrf0_rdata3     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_rdata[3];
    assign vrf0_rdata4     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_rdata[4];
    assign vrf0_rdata5     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_rdata[5];
    assign vrf0_rdata6     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_rdata[6];
    assign vrf0_rdata7     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_rdata[7];

    assign vrf0_waddr0     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_waddr[0];
    assign vrf0_waddr1     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_waddr[1];
    assign vrf0_waddr2     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_waddr[2];
    assign vrf0_waddr3     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_waddr[3];
    assign vrf0_bwen0      = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_bwen[0];
    assign vrf0_bwen1      = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_bwen[1];
    assign vrf0_bwen2      = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_bwen[2];
    assign vrf0_bwen3      = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_bwen[3];
    assign vrf0_wdata0     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_wdata[0];
    assign vrf0_wdata1     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_wdata[1];
    assign vrf0_wdata2     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_wdata[2];
    assign vrf0_wdata3     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.vrf_wdata[3];

    assign vlane0_st_data0   = riscv_v_inst.vector_core_inst.vlane_store_data[0][0];
    assign vlane0_st_data1   = riscv_v_inst.vector_core_inst.vlane_store_data[0][1];
    assign vlane0_st_data2   = riscv_v_inst.vector_core_inst.vlane_store_data[0][2];
    assign vlane0_st_data3   = riscv_v_inst.vector_core_inst.vlane_store_data[0][3];
    assign vlane0_st_drvr    = riscv_v_inst.vector_core_inst.vlane_store_driver_reg;

    assign vlane0_store_data_out2     = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.store_data_o[2];
    assign vlane0_store_data_mux2_4   = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.store_data_mux[2][4];
    assign vlane0_store_data_mux_sel2 = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.store_data_mux_sel[2];
    assign vlane0_read_data_mux4      = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.read_data_mux[4];
    assign vlane0_read_data_prep_reg  = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.read_data_prep_reg[4];

    assign vl   = riscv_v_inst.vector_core_inst.v_cu_inst.vl_o;
    assign sew  = riscv_v_inst.vector_core_inst.v_cu_inst.sew_o;
    assign lmul = riscv_v_inst.vector_core_inst.v_cu_inst.lmul_o;

    assign multipump_sel_reg = riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.multipump_sel_reg;
   
    `endif

    `ifdef INCLUDE_AXIL_IF 
    logic 				         ce ; // will be clock enable to start/stop processor
    logic [31:0] 			     axi_base_address; // will be the starting address in DDR of machine code 
    logic [31:0] 			     pc_reg; // will be just a way to see from sogtware where the PC is currently

    `endif

   // SCALAR CACHE <=> SCALAR AXI FULL CONTROLLER
   logic [31:0] 			     axi_write_address;
   logic 				     axi_write_init;
   logic [31:0] 			     axi_write_data;
   logic 				     axi_write_next;
   logic 				     axi_write_done;
   logic [31:0] 			     axi_read_address;
   logic 				     axi_read_init;
   logic [31:0] 			     axi_read_data;
   logic 				     axi_read_next;

   // SCALAR CORE <=> CACHE
   logic [31:0] 			     instr_mem_address;
   logic 				     instr_mem_flush; 
   logic 				     instr_mem_en;
   logic [31:0] 			     data_mem_address;
   logic [3:0] 				     data_mem_we;
   logic 				     fencei;
   logic 				     instr_ready;
   logic 				     data_ready;
   logic [31:0] 			     instr_mem_read;
   logic [31:0] 			     data_mem_read;
   logic [31:0] 			     data_mem_write;
   logic 				     data_mem_re;

   // VECTOR CORE <=> AXI FULL CONTROLLER
   logic 				     ctrl_rdone;
   logic 				     rd_tvalid;
   logic 				     rd_tlast;
   logic [C_M_AXI_DATA_WIDTH-1:0] 	     rd_tdata;
   logic 				     ctrl_wdone;
   logic 				     wr_tready;
   logic 				     ctrl_rstart;
   logic [C_M_AXI_ADDR_WIDTH-1:0] 	     ctrl_raddr_offset;
   logic [C_XFER_SIZE_WIDTH-1:0] 	     ctrl_rxfer_size;
   logic 				     rd_tready;
   logic 				     ctrl_wstart;
   logic [C_M_AXI_ADDR_WIDTH-1:0] 	     ctrl_waddr_offset; //=0;   // ALEKSA HAS CHANGED THIS
   logic [C_XFER_SIZE_WIDTH-1:0] 	     ctrl_wxfer_size; //=16;    // ALEKSA HAS CHANGED THIS
   logic 				     wr_tvalid; // =1;                      // ALEKSA HAS CHANGED THIS
   logic [C_M_AXI_DATA_WIDTH-1:0] 	     wr_tdata; // = 10;         // ALEKSA HAS CHANGED THIS
   logic [3 : 0] wr_tstrb_msk;  // ALEKSA HAS CHANGED THIS
   logic 				     ctrl_wstrb_msk_en;
   /*******DEBUG logic*******/
   /* -----\/----- EXCLUDED -----\/-----
    always @(posedge clk)
    begin
    if (!rstn)begin
    ctrl_wstart <=1;
      end
    else if (ctrl_wstart)
    ctrl_wstart <=0;
    else if (v_m_axi_wlast)
    ctrl_wstart <=1;	
   end
    -----/\----- EXCLUDED -----/\----- */
   /*************************/

   
   // VECTOR CORE AXI FULL CONTROLLER
   axim_ctrl #(/*AUTOINST_PARAM*/
	       // Parameters
	       .C_M_AXI_ADDR_WIDTH	(C_M_AXI_ADDR_WIDTH),
	       .C_M_AXI_DATA_WIDTH	(C_M_AXI_DATA_WIDTH),
	       .C_XFER_SIZE_WIDTH	  (C_XFER_SIZE_WIDTH))
   v_axim_ctrl_inst(/*AUTO_INST*/
		    .clk		(clk),
		    .rst		(!rstn),
		    // Outputs
		    .m_axi_awvalid	(v_m_axi_awvalid),
		    .m_axi_awaddr	  (v_m_axi_awaddr[C_M_AXI_ADDR_WIDTH-1:0]),
		    .m_axi_awlen	  (v_m_axi_awlen[8-1:0]),
		    .m_axi_wvalid	  (v_m_axi_wvalid),
		    .m_axi_wdata	  (v_m_axi_wdata[C_M_AXI_DATA_WIDTH-1:0]),
		    .m_axi_wstrb	  (v_m_axi_wstrb[C_M_AXI_DATA_WIDTH/8-1:0]),
		    .m_axi_wlast	  (v_m_axi_wlast),
		    .m_axi_arvalid	(v_m_axi_arvalid),
		    .m_axi_araddr	  (v_m_axi_araddr[C_M_AXI_ADDR_WIDTH-1:0]),
		    .m_axi_arlen	  (v_m_axi_arlen[8-1:0]),
		    .m_axi_rready	  (v_m_axi_rready),
		    .m_axi_bready	  (v_m_axi_bready),
		    //AXIM inputs
		    .m_axi_awready	(v_m_axi_awready),
		    .m_axi_wready 	(v_m_axi_wready),
		    .m_axi_arready	(v_m_axi_arready),
		    .m_axi_rvalid	  (v_m_axi_rvalid),
		    .m_axi_rdata	  (v_m_axi_rdata[C_M_AXI_DATA_WIDTH-1:0]),
		    .m_axi_rlast	  (v_m_axi_rlast),
		    .m_axi_bvalid	  (v_m_axi_bvalid),
		    //Vector core if
		    .ctrl_baseaddr	(axi_base_address),
		    .ctrl_rdone	  	(ctrl_rdone),
		    .rd_tvalid	  	(rd_tvalid),
		    .rd_tlast		    (rd_tlast),
		    .rd_tdata		    (rd_tdata[C_M_AXI_DATA_WIDTH-1:0]),
		    .ctrl_wdone	   	    (ctrl_wdone),
		    .wr_tready	  	    (wr_tready),
		    .ctrl_rstart  	    (ctrl_rstart),
        .ctrl_raddr_offset	(ctrl_raddr_offset[C_M_AXI_ADDR_WIDTH-1:0]),
        .ctrl_rxfer_size	  (ctrl_rxfer_size[C_XFER_SIZE_WIDTH-1:0]),
        .ctrl_wstrb_msk_en	(ctrl_wstrb_msk_en),
		    .rd_tready	  	    (rd_tready),
		    .ctrl_wstart  	    (ctrl_wstart),
		    .ctrl_waddr_offset	(ctrl_waddr_offset[C_M_AXI_ADDR_WIDTH-1:0]),
		    .ctrl_wxfer_size	  (ctrl_wxfer_size[C_XFER_SIZE_WIDTH-1:0]),
		    .wr_tvalid		      (wr_tvalid),
		    .wr_tstrb_msk	      (wr_tstrb_msk),
		    .wr_tdata		        (wr_tdata[C_M_AXI_DATA_WIDTH-1:0]));


   // RISCV SCALAR + VECTOR CORE
   riscv_v
     #(
       .C_M_AXI_ADDR_WIDTH (C_M_AXI_ADDR_WIDTH),
       .C_M_AXI_DATA_WIDTH (C_M_AXI_DATA_WIDTH),
       .C_XFER_SIZE_WIDTH  (C_XFER_SIZE_WIDTH ),
       .VLEN               (VLEN              ),
       .V_LANES            (V_LANES           ),
       .CHAINING           (CHAINING          ))
   riscv_v_inst
     (
      .clk                 (clk                ),
      .clk2                (clk2               ),
      .ce                  (ce                 ),
      .rstn                (rstn               ),
      .fencei_o            (fencei             ),
      .pc_reg_o            (pc_reg             ),
      .instr_ready_i       (instr_ready        ),
      .data_ready_i        (data_ready         ),
      .instr_mem_address_o (instr_mem_address  ),
      .instr_mem_read_i    (instr_mem_read     ),
      .data_mem_address_o  (data_mem_address   ),
      .data_mem_read_i     (data_mem_read      ),
      .data_mem_write_o    (data_mem_write     ),
      .data_mem_we_o       (data_mem_we        ),
      .data_mem_re_o       (data_mem_re        ),
      .ctrl_raddr_offset_o (ctrl_raddr_offset  ),
      .ctrl_rxfer_size_o   (ctrl_rxfer_size    ),
      .ctrl_rstart_o       (ctrl_rstart        ),
      .ctrl_rdone_i        (ctrl_rdone         ),
      .rd_tdata_i          (rd_tdata           ),
      .rd_tvalid_i         (rd_tvalid          ),
      .rd_tready_o         (rd_tready          ),
      .rd_tlast_i          (rd_tlast           ),
      .ctrl_waddr_offset_o (ctrl_waddr_offset  ),
      .ctrl_wxfer_size_o   (ctrl_wxfer_size    ),
      .ctrl_wstart_o       (ctrl_wstart        ),
      .ctrl_wdone_i        (ctrl_wdone         ),
      .wr_tdata_o          (wr_tdata           ),
      .wr_tvalid_o         (wr_tvalid          ),
      .wr_tready_i         (wr_tready          ),
      .ctrl_wstrb_msk_en_o (ctrl_wstrb_msk_en  ),
      .wr_tstrb_msk_o      (wr_tstrb_msk       ));


   // SCALAR CACHE CONTROLLER
   cache_contr_nway_vnv #(
			  .C_PHY_ADDR_WIDTH       (C_PHY_ADDR_WIDTH),
			  .C_TS_BRAM_TYPE         ("HIGH_PERFORMANCE"),
			  .C_BLOCK_SIZE           (C_BLOCK_SIZE),
			  .C_LVL1_CACHE_SIZE      (C_LVL1_CACHE_SIZE),
			  .C_LVL2_CACHE_SIZE      (C_LVL2_CACHE_SIZE),
			  .C_LVL2C_ASSOCIATIVITY  (C_LVL2_CACHE_NWAY)
			  ) cache_inst(
				       .clk(clk),
				       .ce(ce),
				       .reset(rstn),
				       .data_ready_o(data_ready),
				       .instr_ready_o(instr_ready),
				       .fencei_i(fencei),
				       .addr_instr_i(instr_mem_address),
				       .dread_instr_o(instr_mem_read),
				       .addr_data_i(data_mem_address),
				       .dread_data_o(data_mem_read),
				       .dwrite_data_i(data_mem_write),
				       .we_data_i(data_mem_we),
				       .re_data_i(data_mem_re),
				       .axi_write_address_o(axi_write_address),
				       .axi_write_init_o(axi_write_init),
				       .axi_write_data_o(axi_write_data),
				       .axi_write_next_i(axi_write_next),
				       .axi_write_done_i(axi_write_done),
				       .axi_read_address_o(axi_read_address),
				       .axi_read_init_o(axi_read_init),
				       .axi_read_data_i(axi_read_data),
				       .axi_read_next_i(axi_read_next));

   // SCALAR AXI FULL CONTROLLER
   riscv_axif_m_ctrl #(
			.C_M_AXI_BURST_LEN	  (C_M_AXI_BURST_LEN),
			.C_M_AXI_ID_WIDTH	    (C_M_AXI_ID_WIDTH),
			.C_M_AXI_ADDR_WIDTH	  (C_M_AXI_ADDR_WIDTH),
			.C_M_AXI_DATA_WIDTH	  (C_M_AXI_DATA_WIDTH),
			.C_M_AXI_AWUSER_WIDTH	(C_M_AXI_AWUSER_WIDTH),
			.C_M_AXI_ARUSER_WIDTH	(C_M_AXI_ARUSER_WIDTH),
			.C_M_AXI_WUSER_WIDTH	(C_M_AXI_WUSER_WIDTH),
			.C_M_AXI_RUSER_WIDTH	(C_M_AXI_RUSER_WIDTH),
			.C_M_AXI_BUSER_WIDTH	(C_M_AXI_BUSER_WIDTH)
			) 
   scalar_axif_m_ctrl_inst 
     (
      .axi_base_address_i   (axi_base_address),
      .axi_write_address_i  (axi_write_address),
      .axi_write_init_i	    (axi_write_init),
      .axi_write_data_i	    (axi_write_data),
      .axi_write_next_o     (axi_write_next),
      .axi_write_done_o     (axi_write_done),
      .axi_read_address_i   (axi_read_address),
      .axi_read_init_i	    (axi_read_init),
      .axi_read_data_o	    (axi_read_data),
      .axi_read_next_o      (axi_read_next),
      .M_AXI_ACLK	          (clk),
      .M_AXI_ARESETN	      (rstn),
      .M_AXI_AWID	          (s_m_axi_awid),
      .M_AXI_AWADDR	        (s_m_axi_awaddr),
      .M_AXI_AWLEN	        (s_m_axi_awlen),
      .M_AXI_AWSIZE	        (s_m_axi_awsize),
      .M_AXI_AWBURST	      (s_m_axi_awburst),
      .M_AXI_AWLOCK	        (s_m_axi_awlock),
      .M_AXI_AWCACHE	      (s_m_axi_awcache),
      .M_AXI_AWPROT	        (s_m_axi_awprot),
      .M_AXI_AWQOS	        (s_m_axi_awqos),
      .M_AXI_AWUSER	        (s_m_axi_awuser),
      .M_AXI_AWVALID	      (s_m_axi_awvalid),
      .M_AXI_AWREADY	      (s_m_axi_awready),
      .M_AXI_WDATA	        (s_m_axi_wdata),
      .M_AXI_WSTRB	        (s_m_axi_wstrb),
      .M_AXI_WLAST	        (s_m_axi_wlast),
      .M_AXI_WUSER	        (s_m_axi_wuser),
      .M_AXI_WVALID	        (s_m_axi_wvalid),
      .M_AXI_WREADY	        (s_m_axi_wready),
      .M_AXI_BID	          (s_m_axi_bid),
      .M_AXI_BRESP	        (s_m_axi_bresp),
      .M_AXI_BUSER	        (s_m_axi_buser),
      .M_AXI_BVALID	        (s_m_axi_bvalid),
      .M_AXI_BREADY	        (s_m_axi_bready),
      .M_AXI_ARID	          (s_m_axi_arid),
      .M_AXI_ARADDR	        (s_m_axi_araddr),
      .M_AXI_ARLEN	        (s_m_axi_arlen),
      .M_AXI_ARSIZE	        (s_m_axi_arsize),
      .M_AXI_ARBURST	      (s_m_axi_arburst),
      .M_AXI_ARLOCK	        (s_m_axi_arlock),
      .M_AXI_ARCACHE	      (s_m_axi_arcache),
      .M_AXI_ARPROT	        (s_m_axi_arprot),
      .M_AXI_ARQOS	        (s_m_axi_arqos),
      .M_AXI_ARUSER	        (s_m_axi_aruser),
      .M_AXI_ARVALID	      (s_m_axi_arvalid),
      .M_AXI_ARREADY	      (s_m_axi_arready),
      .M_AXI_RID	          (s_m_axi_rid),
      .M_AXI_RDATA	        (s_m_axi_rdata),
      .M_AXI_RRESP	        (s_m_axi_rresp),
      .M_AXI_RLAST	        (s_m_axi_rlast),
      .M_AXI_RUSER	        (s_m_axi_ruser),
      .M_AXI_RVALID	        (s_m_axi_rvalid),
      .M_AXI_RREADY	        (s_m_axi_rready));

// AXI LITE SLAVE CONTROLLER
`ifdef INCLUDE_AXIL_IF
  riscv_axil_s_ctrl #(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	) riscv_axil_s_ctrl_inst (
		.ce_o	              (ce),
		.axi_base_address_o (axi_base_address),
		.pc_reg_i           (pc_reg),
		.S_AXI_ACLK	        (s_axi_aclk),
		.S_AXI_ARESETN	    (s_axi_aresetn),
		.S_AXI_AWADDR	      (s_axi_awaddr),
		.S_AXI_AWPROT	      (s_axi_awprot),
		.S_AXI_AWVALID	    (s_axi_awvalid),
		.S_AXI_AWREADY	    (s_axi_awready),
		.S_AXI_WDATA	      (s_axi_wdata),
		.S_AXI_WSTRB	      (s_axi_wstrb),
		.S_AXI_WVALID	      (s_axi_wvalid),
		.S_AXI_WREADY	      (s_axi_wready),
		.S_AXI_BRESP	      (s_axi_bresp),
		.S_AXI_BVALID	      (s_axi_bvalid),
		.S_AXI_BREADY	      (s_axi_bready),
		.S_AXI_ARADDR	      (s_axi_araddr),
		.S_AXI_ARPROT	      (s_axi_arprot),
		.S_AXI_ARVALID	    (s_axi_arvalid),
		.S_AXI_ARREADY	    (s_axi_arready),
		.S_AXI_RDATA	      (s_axi_rdata),
		.S_AXI_RRESP	      (s_axi_rresp),
		.S_AXI_RVALID	      (s_axi_rvalid),
		.S_AXI_RREADY	      (s_axi_rready)
	);
`endif
endmodule


// Local Variables:
// verilog-library-extensions:(".v" ".sv" "_stub.v" "_bb.v")
// verilog-library-directories:("." "../../../../common/" "../vector_core/rtl" "../axim_ctrl/rtl/" )
// End:
