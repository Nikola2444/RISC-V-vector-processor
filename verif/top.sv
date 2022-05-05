module riscv_v_verif_top;

   import uvm_pkg::*;     // import the UVM library
`include "uvm_macros.svh" // Include the UVM macros

   import riscv_v_test_pkg::*;

   logic clk;
   logic rstn;

   // interface
   riscv_v_if riscv_v_vif(clk, rstn);
   backdoor_instr_if backdoor_instr_vif(clk, rstn);
   
   
   // DUT
   riscv_v_w_mem_subsystem DUT
     (
      /*AUTO_INST*/
      // Outputs
      .v_m_axi_awvalid	(riscv_v_vif.v_m_axi_awvalid),
      .v_m_axi_awaddr	(riscv_v_vif.v_m_axi_awaddr[riscv_v_vif.C_M_AXI_ADDR_WIDTH-1:0]),
      .v_m_axi_awlen	(riscv_v_vif.v_m_axi_awlen[8-1:0]),
      .v_m_axi_wvalid	(riscv_v_vif.v_m_axi_wvalid),
      .v_m_axi_wdata	(riscv_v_vif.v_m_axi_wdata[riscv_v_vif.C_M_AXI_DATA_WIDTH-1:0]),
      .v_m_axi_wstrb	(riscv_v_vif.v_m_axi_wstrb[riscv_v_vif.C_M_AXI_DATA_WIDTH/8-1:0]),
      .v_m_axi_wlast	(riscv_v_vif.v_m_axi_wlast),
      .v_m_axi_arvalid	(riscv_v_vif.v_m_axi_arvalid),
      .v_m_axi_araddr	(riscv_v_vif.v_m_axi_araddr[riscv_v_vif.C_M_AXI_ADDR_WIDTH-1:0]),
      .v_m_axi_arlen	(riscv_v_vif.v_m_axi_arlen[8-1:0]),
      .v_m_axi_rready	(riscv_v_vif.v_m_axi_rready),
      .v_m_axi_bready	(riscv_v_vif.v_m_axi_bready),
      // Inputs
      .clk		(riscv_v_vif.clk),
      .rstn		(riscv_v_vif.rstn),
      .v_m_axi_awready	(riscv_v_vif.v_m_axi_awready),
      .v_m_axi_wready	(riscv_v_vif.v_m_axi_wready),
      .v_m_axi_arready	(riscv_v_vif.v_m_axi_arready),
      .v_m_axi_rvalid	(riscv_v_vif.v_m_axi_rvalid),
      .v_m_axi_rdata	(riscv_v_vif.v_m_axi_rdata[riscv_v_vif.C_M_AXI_DATA_WIDTH-1:0]),
      .v_m_axi_rlast	(riscv_v_vif.v_m_axi_rlast),
      .v_m_axi_bvalid	(riscv_v_vif.v_m_axi_bvalid));

   `include "backdoor_connections.sv"

   // run test
   initial begin      
      uvm_config_db#(virtual riscv_v_if)::set(null, "uvm_test_top.env", "riscv_v_if", riscv_v_vif);
      uvm_config_db#(virtual backdoor_instr_if)::set(null, "uvm_test_top.env", "backdoor_instr_if", backdoor_instr_vif);
      run_test();
   end

   // clock and reset init.
   initial begin
      clk <= 0;
      rstn <= 0;
      #1000 rstn <= 1;
   end

   // clock generation
   always #50 clk = ~clk;

endmodule : riscv_v_verif_top
// Local Variables:
// verilog-library-extensions:(".v" ".sv" "_stub.v" "_bb.v")
// verilog-library-directories:("." "../hdl/riscv-v/rtl/")
// End:
