`ifndef RISCV_V_IF_SV
 `define RISCV_V_IF_SV

interface riscv_v_if (input clk, logic rstn);
   // AXI FULL VECTOR CORE IF
   parameter integer C_M_AXI_ADDR_WIDTH = 32;
   parameter integer C_M_AXI_DATA_WIDTH = 32;
   parameter integer C_XFER_SIZE_WIDTH = 32;
   parameter integer VLEN = 4096;
   parameter integer V_LANES = 16;
   parameter integer CHAINING = 4;
   logic 			    v_m_axi_awvalid ;
   logic 			    v_m_axi_awready ;
   logic [C_M_AXI_ADDR_WIDTH-1:0]   v_m_axi_awaddr ;
   logic [8-1:0] 		    v_m_axi_awlen ;
   logic 			    v_m_axi_wvalid ;
   logic 			    v_m_axi_wready ;
   logic [C_M_AXI_DATA_WIDTH-1:0]   v_m_axi_wdata ;
   logic [C_M_AXI_DATA_WIDTH/8-1:0] v_m_axi_wstrb ;
   logic 			    v_m_axi_wlast ;
   logic 			    v_m_axi_arvalid ;
   logic 			    v_m_axi_arready ;
   logic [C_M_AXI_ADDR_WIDTH-1:0]   v_m_axi_araddr ;
   logic [8-1:0] 		    v_m_axi_arlen ;
   logic 			    v_m_axi_rvalid ;
   logic 			    v_m_axi_rready ;
   logic [C_M_AXI_DATA_WIDTH-1:0]   v_m_axi_rdata ;
   logic 			    v_m_axi_rlast ;
   logic 			    v_m_axi_bvalid ;
   logic 			    v_m_axi_bready;

endinterface : riscv_v_if

`endif
