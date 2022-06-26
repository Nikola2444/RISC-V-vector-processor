`ifndef RISCV_V_IF_SV
 `define RISCV_V_IF_SV

interface axi4_if (input clk, logic rstn, output reg [31:0] ddr_mem[`DDR_DEPTH], input logic[31:0] burst_len);
   // AXI FULL VECTOR CORE IF
   parameter integer C_M_AXI_ADDR_WIDTH = 32;
   parameter integer C_M_AXI_DATA_WIDTH = 32;
   parameter integer C_XFER_SIZE_WIDTH = 32;
   parameter integer VLEN = 4096;
   parameter integer V_LANES = 16;
   parameter integer CHAINING = 4;


   logic 			    m_axi_awvalid ;
   logic 			    m_axi_awready ;
   logic [C_M_AXI_ADDR_WIDTH-1:0]   m_axi_awaddr ;
   logic [8-1:0] 		    m_axi_awlen ;
   logic 			    m_axi_wvalid ;
   logic 			    m_axi_wready ;
   logic [C_M_AXI_DATA_WIDTH-1:0]   m_axi_wdata ;
   logic [C_M_AXI_DATA_WIDTH/8-1:0] m_axi_wstrb ;
   logic 			    m_axi_wlast ;
   logic 			    m_axi_arvalid ;
   logic 			    m_axi_arready ;
   logic [C_M_AXI_ADDR_WIDTH-1:0]   m_axi_araddr ;
   logic [8-1:0] 		    m_axi_arlen ;
   logic 			    m_axi_rvalid ;
   logic 			    m_axi_rready ;
   logic [C_M_AXI_DATA_WIDTH-1:0]   m_axi_rdata ;
   logic 			    m_axi_rlast ;
   logic 			    m_axi_bvalid ;
   logic 			    m_axi_bready;

endinterface : axi4_if

`endif
